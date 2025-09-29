import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/universal_intent_service.dart';
import '../services/fixed_ai_matching_service.dart';
import '../models/user_profile.dart';
import '../models/ai_post_model.dart';
import 'enhanced_ai_matching_screen.dart';
import '../widgets/user_avatar.dart';
import '../services/debug_service.dart';
import '../utils/matching_system_tester.dart';

/// Enhanced universal matching screen with improved UI flow
/// Integrates posting and matching with the new AI matching display
class EnhancedUniversalMatchingScreen extends StatefulWidget {
  const EnhancedUniversalMatchingScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedUniversalMatchingScreen> createState() => _EnhancedUniversalMatchingScreenState();
}

class _EnhancedUniversalMatchingScreenState extends State<EnhancedUniversalMatchingScreen>
    with TickerProviderStateMixin {
  final UniversalIntentService _intentService = UniversalIntentService();
  final FixedAIMatchingService _matchingService = FixedAIMatchingService();
  final TextEditingController _intentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isProcessing = false;
  List<Map<String, dynamic>> _userPosts = [];
  String? _currentUserName = '';
  late AnimationController _pulseController;
  late AnimationController _slideController;
  String _hintText = 'What are you looking for today?';

  final List<String> _hintTexts = [
    'What are you looking for today?',
    'Tell me what you need...',
    'Describe what you want to buy, sell, or find...',
    'Looking for something? Just ask!',
    'What can I help you find?',
  ];

  int _currentHintIndex = 0;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _loadUserProfile();
    _loadUserPosts();
    _startHintRotation();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _hintTimer?.cancel();
    _intentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startHintRotation() {
    _hintTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && !_focusNode.hasFocus && _intentController.text.isEmpty) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _hintTexts.length;
          _hintText = _hintTexts[_currentHintIndex];
        });
      }
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            _currentUserName = doc.data()?['name'] ?? user.displayName ?? 'User';
          });
        }
      }
    } catch (e) {
      DebugService.log('UNIVERSAL_UI', '_loadUserProfile',
          'Error loading user profile', data: {'error': e.toString()});
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final posts = await _intentService.getUserIntents(userId);
      if (mounted) {
        setState(() {
          _userPosts = posts;
        });
      }
    } catch (e) {
      DebugService.log('UNIVERSAL_UI', '_loadUserPosts',
          'Error loading user posts', data: {'error': e.toString()});
    }
  }

  Future<void> _processIntent() async {
    if (_intentController.text.trim().isEmpty) return;

    final userInput = _intentController.text.trim();

    setState(() {
      _isProcessing = true;
    });

    try {
      DebugService.log('UNIVERSAL_UI', '_processIntent',
          'Processing user intent', data: {'input': userInput});

      // Initialize services
      await _matchingService.initialize();

      // Create post using the new matching service
      final postId = await _matchingService.createPost(userInput);

      if (postId == null) {
        throw Exception('Failed to create post');
      }

      // Get the created post for matching
      final postDoc = await FirebaseFirestore.instance
          .collection('ai_posts')
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        throw Exception('Post not found after creation');
      }

      final createdPost = AIPostModel.fromFirestore(postDoc);

      // Find matches for the new post
      final matches = await _matchingService.findBestPeople(createdPost);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Show success feedback
        _showPostCreatedSuccess();

        // Navigate to matching results
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedAIMatchingScreen(
              initialMatches: matches,
              userQuery: userInput,
              userPost: createdPost,
              showDebugInfo: true,
            ),
          ),
        );

        // Clear input
        _intentController.clear();
        _loadUserPosts(); // Refresh posts list
      }

    } catch (e) {
      DebugService.log('UNIVERSAL_UI', '_processIntent',
          'Error processing intent', data: {'error': e.toString()});

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        _showErrorMessage(e.toString());
      }
    }
  }

  void _showPostCreatedSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Post created successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Error: $error')),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  photoUrl: _auth.currentUser?.photoURL,
                  radius: 25,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $_currentUserName! 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'What would you like to find today?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.showQuickMatchingTest(),
                  icon: const Icon(Icons.bug_report),
                  tooltip: 'Test Matching System',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInterface() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Main input field
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.purple[50]!],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _intentController,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: _hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                  prefixIcon: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.1),
                        child: Icon(
                          Icons.search,
                          color: Colors.purple[400],
                        ),
                      );
                    },
                  ),
                  suffixIcon: _isProcessing
                      ? Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.purple[400]!),
                          ),
                        )
                      : IconButton(
                          onPressed: _intentController.text.isNotEmpty
                              ? _processIntent
                              : null,
                          icon: Icon(
                            Icons.send,
                            color: _intentController.text.isNotEmpty
                                ? Colors.purple[400]
                                : Colors.grey[400],
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontSize: 16),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _processIntent(),
                onChanged: (text) {
                  setState(() {}); // Refresh suffix icon state
                },
              ),
            ),

            const SizedBox(height: 16),

            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Sell Something',
                    Icons.sell,
                    Colors.green,
                    () => _intentController.text = 'I want to sell ',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Buy Something',
                    Icons.shopping_cart,
                    Colors.blue,
                    () => _intentController.text = 'Looking to buy ',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Find Service',
                    Icons.build,
                    Colors.orange,
                    () => _intentController.text = 'Need help with ',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Lost & Found',
                    Icons.search_off,
                    Colors.red,
                    () => _intentController.text = 'Lost my ',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildRecentPosts() {
    if (_userPosts.isEmpty) return const SizedBox.shrink();

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Your Recent Posts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _userPosts.take(10).length,
                itemBuilder: (context, index) {
                  final post = _userPosts[index];
                  return _buildRecentPostCard(post);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPostCard(Map<String, dynamic> post) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _findMatchesForPost(post),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['title'] ?? 'Untitled',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                post['description'] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to find matches',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _findMatchesForPost(Map<String, dynamic> post) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Create AIPostModel from the stored post data
      final aiPost = AIPostModel(
        id: post['id'] ?? '',
        userId: _auth.currentUser!.uid,
        originalPrompt: post['description'] ?? '',
        intentAnalysis: post['intent_analysis'] ?? {},
        clarificationAnswers: {},
        embedding: List<double>.from(post['embeddings'] ?? []),
        createdAt: post['createdAt'] != null
            ? (post['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        metadata: post['metadata'] ?? {},
      );

      // Find matches
      final matches = await _matchingService.findBestPeople(aiPost);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Navigate to matching results
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedAIMatchingScreen(
              initialMatches: matches,
              userQuery: post['description'] ?? '',
              userPost: aiPost,
              showDebugInfo: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorMessage(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supper'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.showQuickMatchingTest(),
            icon: const Icon(Icons.science),
            tooltip: 'Test System',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingHeader(),
            const SizedBox(height: 20),
            _buildSearchInterface(),
            const SizedBox(height: 32),
            _buildRecentPosts(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EnhancedAIMatchingScreen(showDebugInfo: true),
          ),
        ),
        label: const Text('View All Matches'),
        icon: const Icon(Icons.favorite),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}