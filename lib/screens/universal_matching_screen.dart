import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/universal_intent_service.dart';
import '../models/user_profile.dart';
import 'enhanced_chat_screen.dart';
import '../widgets/user_avatar.dart';
import '../widgets/simple_intent_dialog.dart';
import '../widgets/conversational_clarification_dialog.dart';
import '../widgets/sequential_clarification_dialog.dart';
import '../services/sequential_clarification_service.dart';
import '../widgets/match_card_with_actions.dart';
import '../services/unified_intent_processor.dart';
import '../services/realtime_matching_service.dart';
import 'profile_with_history_screen.dart';
import '../services/photo_cache_service.dart';

class UniversalMatchingScreen extends StatefulWidget {
  const UniversalMatchingScreen({Key? key}) : super(key: key);

  @override
  State<UniversalMatchingScreen> createState() => _UniversalMatchingScreenState();
}

class _UniversalMatchingScreenState extends State<UniversalMatchingScreen> {
  final UniversalIntentService _intentService = UniversalIntentService();
  final UnifiedIntentProcessor _unifiedProcessor = UnifiedIntentProcessor();
  final SequentialClarificationService _sequentialClarification = SequentialClarificationService();
  final RealtimeMatchingService _realtimeService = RealtimeMatchingService();
  final TextEditingController _intentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PhotoCacheService _photoCache = PhotoCacheService();
  
  bool _isProcessing = false;
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _userIntents = [];
  Map<String, dynamic>? _currentIntent;
  String? _errorMessage;
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _loadUserIntents();
    _loadUserProfile();
    _realtimeService.initialize();
  }

  @override
  void dispose() {
    _intentController.dispose();
    _realtimeService.dispose();

    // Clear photo cache to prevent memory leaks
    try {
      _photoCache.clearAllCache();
    } catch (e) {
      print('WARNING: Failed to clear photo cache: $e');
    }

    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null || !mounted) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _currentUserName = userDoc.data()?['name'] ?? 'User';
        });
      }
    } catch (e) {
      print('ERROR: Failed to load user profile: $e');
      // Don't update UI on error, keep default name
    }
  }

  Future<void> _loadUserIntents() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null || !mounted) return;

      final intents = await _intentService.getUserIntents(userId);

      if (mounted) {
        setState(() {
          _userIntents = intents;
        });
      }
    } catch (e) {
      print('ERROR: Failed to load user intents: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load history';
        });
      }
    }
  }

  Future<void> _processIntent() async {
    final intent = _intentController.text.trim();
    if (intent.isEmpty) {
      setState(() {
        _errorMessage = 'Please describe what you\'re looking for';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      // Step 1: Extract entities from user input
      final extractedData = await _sequentialClarification.extractEntities(intent);

      final clarityScore = extractedData['clarity_score'] ?? 0.0;
      final missingCritical = List<String>.from(extractedData['missing_critical'] ?? []);

      // Step 2: Check if we need clarification (low clarity score or missing critical info)
      if (clarityScore < 0.8 && missingCritical.isNotEmpty) {
        // Show sequential clarification dialog
        final finalIntent = await SequentialClarificationDialog.show(
          context,
          originalInput: intent,
          extractedData: extractedData,
        );

        if (finalIntent != null) {
          // Use the synthetic description for processing with new intent system
          print('DEBUG: Final intent synthetic description: ${finalIntent['synthetic_description']}');
          print('DEBUG: Final intent full object: $finalIntent');

          // Process directly with the new intent-based system
          await _processWithIntent(finalIntent['synthetic_description']);
        } else {
          print('DEBUG: finalIntent is null - user cancelled clarification');
        }
      } else {
        // Direct processing - sufficient clarity
        await _processWithIntent(intent);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  String _buildClarifiedIntent(String original, String answer, String question) {
    if (question.contains('buy or sell')) {
      if (answer.toLowerCase().contains('buy')) {
        return 'I want to buy $original';
      } else {
        return 'I want to sell $original';
      }
    } else if (question.contains('rent or offering')) {
      if (answer.toLowerCase().contains('looking')) {
        return 'Looking for $original to rent';
      } else {
        return 'Offering $original for rent';
      }
    } else if (question.contains('hiring')) {
      if (answer.toLowerCase().contains('hiring')) {
        return 'Hiring a $original';
      } else {
        return 'Looking for $original job';
      }
    } else if (question.contains('prefer')) {
      return '$original, preference: $answer';
    }
    return '$original - $answer';
  }

  Future<void> _processWithClarifiedIntent(String syntheticDescription, Map<String, dynamic> finalIntent) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _matches.clear();
    });

    try {
      // Process the synthetic description through our intent service
      print('DEBUG: Processing synthetic description: $syntheticDescription');
      final result = await _intentService.processIntentAndMatch(syntheticDescription);

      if (!mounted) return;

      if (result['success'] == true) {
        final matches = List<Map<String, dynamic>>.from(result['matches'] ?? []);

        print('DEBUG: Search completed successfully');
        print('DEBUG: Found ${matches.length} matches');
        print('DEBUG: Result object: $result');

        // Cache user photos (with limits to prevent memory leaks)
        for (final match in matches) {
          try {
            final userProfile = match['userProfile'] ?? {};
            final userId = match['userId'];
            final photoUrl = userProfile['photoUrl'];

            if (userId != null && photoUrl != null && photoUrl.toString().isNotEmpty) {
              _photoCache.cachePhotoUrl(userId, photoUrl);
            }
          } catch (e) {
            print('WARNING: Failed to cache photo: $e');
            // Continue with other photos even if one fails
          }
        }

        setState(() {
          _currentIntent = result['intent'];
          _matches = matches;
          _isProcessing = false;
        });

        print('UniversalMatchingScreen: Found ${matches.length} matches with sequential clarification');
        print('Final intent: ${finalIntent['synthetic_description']}');

        // Reload user intents
        _loadUserIntents();

        // Clear the input after successful search
        _intentController.clear();

        // Show success message if matches found
        if (_matches.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${_matches.length} matches for you!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to process request';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _storeAndMatch(Map<String, dynamic> intentData, String userId) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _matches.clear();
    });

    try {
      final result = await _intentService.storeAndMatch(intentData, userId);

      if (!mounted) return;

      if (result['success'] == true) {
        final matches = List<Map<String, dynamic>>.from(result['matches'] ?? []);

        // Cache user photos (with limits to prevent memory leaks)
        for (final match in matches) {
          try {
            final userProfile = match['userProfile'] ?? {};
            final userId = match['userId'];
            final photoUrl = userProfile['photoUrl'];

            if (userId != null && photoUrl != null && photoUrl.toString().isNotEmpty) {
              _photoCache.cachePhotoUrl(userId, photoUrl);
            }
          } catch (e) {
            print('WARNING: Failed to cache photo: $e');
            // Continue with other photos even if one fails
          }
        }

        setState(() {
          _currentIntent = result['intent'];
          _matches = matches;
          _isProcessing = false;
        });

        print('UniversalMatchingScreen: Found ${matches.length} matches');
        for (var match in matches) {
          print('Match: ${match['userProfile']?['name']} - Score: ${match['matchScore']}');
        }

        // Reload user intents
        _loadUserIntents();

        // Clear the input after successful search
        _intentController.clear();

        // Show success message if matches found
        if (_matches.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${_matches.length} matches for you!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to process request';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processWithIntent(String intent) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _matches.clear();
    });

    try {
      final result = await _intentService.processIntentAndMatch(intent);
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        final matches = List<Map<String, dynamic>>.from(result['matches'] ?? []);
        
        // Cache user photos
        for (final match in matches) {
          final userProfile = match['userProfile'] ?? {};
          final userId = match['userId'];
          final photoUrl = userProfile['photoUrl'];
          
          if (userId != null && photoUrl != null) {
            _photoCache.cachePhotoUrl(userId, photoUrl);
          }
        }
        
        setState(() {
          _currentIntent = result['intent'];
          _matches = matches;
          _isProcessing = false;
        });
        
        print('UniversalMatchingScreen: Found ${matches.length} matches');
        for (var match in matches) {
          print('Match: ${match['userProfile']?['name']} - Score: ${match['matchScore']}');
        }
        
        // Reload user intents
        _loadUserIntents();
        
        // Clear the input after successful search
        _intentController.clear();
        
        // Show success message if matches found
        if (_matches.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${_matches.length} matches for you!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to process request';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }
  

  String _formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)}m away';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)}km away';
    } else {
      return '${distanceInKm.toStringAsFixed(0)}km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        centerTitle: false,
        title: Text(
          'Supper',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileWithHistoryScreen(),
                  ),
                ).then((_) => _loadUserProfile());
              },
              child: UserAvatar(
                profileImageUrl: _auth.currentUser?.photoURL,
                radius: 18,
                fallbackText: _currentUserName,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: _isProcessing
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _matches.isNotEmpty
                    ? _buildMatchesList(isDarkMode)
                    : _buildHomeState(isDarkMode),
          ),
          
          // Search input at bottom
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                // Search input
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _intentController,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Find Anything Supper',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: _isProcessing ? null : _processIntent,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_upward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _processIntent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hello ${_currentUserName.split(' ')[0].toUpperCase()},',
            style: TextStyle(
              fontSize: 20,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Find Your Need',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchesList(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        return _buildMatchCard(_matches[index], isDarkMode);
      },
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, bool isDarkMode) {
    // Format match data for MatchCardWithActions
    final userProfile = match['userProfile'] ?? {};
    final formattedMatch = {
      'userId': match['userId'],
      'userName': userProfile['name'] ?? 'Unknown User',
      'userProfile': userProfile,
      'location': userProfile['city'] ?? userProfile['location'],
      'text': match['title'] ?? match['description'] ?? match['originalText'] ?? 'Looking for match',
      'intent': match['intent'],
      'similarity': (match['matchScore'] ?? match['similarity'] ?? 0.0),
      'distance': match['distance'],
    };

    return MatchCardWithActions(
      match: formattedMatch,
    );
  }
}