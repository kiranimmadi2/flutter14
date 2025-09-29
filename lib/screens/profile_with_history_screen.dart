import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import '../services/universal_intent_service.dart';
import '../services/location_service.dart';
import '../widgets/user_avatar.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'profile_edit_screen.dart';
import 'settings_screen.dart';
import 'enhanced_chat_screen.dart';
import '../models/user_profile.dart';

class ProfileWithHistoryScreen extends StatefulWidget {
  const ProfileWithHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ProfileWithHistoryScreen> createState() => _ProfileWithHistoryScreenState();
}

class _ProfileWithHistoryScreenState extends State<ProfileWithHistoryScreen> 
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UniversalIntentService _intentService = UniversalIntentService();
  final LocationService _locationService = LocationService();
  
  late TabController _tabController;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _searchHistory = [];
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _updateLocationIfNeeded();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateLocationIfNeeded() async {
    try {
      print('ProfileScreen: Checking if location needs update...');
      // Check if user's location needs updating
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          print('ProfileScreen: Current location data - displayLocation=${data?['displayLocation']}, city=${data?['city']}, location=${data?['location']}');
          
          // Update location if it's not set or if it says generic location
          if (data?['displayLocation'] == null ||
              data?['displayLocation'] == 'Location detected' ||
              data?['displayLocation'] == 'Location detected (Web)' ||
              (data?['city'] == null || 
               data?['city'] == 'Location not set' ||
               data?['city'] == '' ||
               data?['city'] == 'Location detected' ||
               data?['city'] == 'Location detected (Web)')) {
            print('ProfileScreen: Location needs update, calling updateUserLocation...');
            // Update location in background
            final success = await _locationService.updateUserLocation();
            print('ProfileScreen: Location update result=$success');
            
            if (success) {
              // Reload user data to show updated location
              await Future.delayed(const Duration(seconds: 2)); // Give Firestore time to update
              _loadUserData();
            }
          } else {
            print('ProfileScreen: Location already set: ${data?['displayLocation']}');
          }
        } else {
          // Document doesn't exist, create it with location
          print('ProfileScreen: User document does not exist, creating with location...');
          await _locationService.updateUserLocation();
          await Future.delayed(const Duration(seconds: 2));
          _loadUserData();
        }
      }
    } catch (e) {
      print('ProfileScreen: Error updating location: $e');
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Load user profile
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && mounted) {
        final userData = userDoc.data();
        setState(() {
          _userProfile = userData;
        });
        
        // Debug: Log what we're getting from database
        print('User profile loaded: city=${userData?['city']}, location=${userData?['location']}');
      }

      // Load search history with proper error handling
      try {
        final intentsQuery = _firestore
            .collection('user_intents')
            .where('userId', isEqualTo: userId);
            
        final intents = await intentsQuery.limit(20).get();
        
        if (mounted) {
          setState(() {
            _searchHistory = intents.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
            
            // Sort by createdAt if available
            _searchHistory.sort((a, b) {
              final aTime = a['createdAt'];
              final bTime = b['createdAt'];
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return (bTime as Timestamp).compareTo(aTime as Timestamp);
            });
          });
        }
      } catch (e) {
        print('Error loading search history: $e');
      }

      // Load chat history with proper error handling
      try {
        final conversationsQuery = _firestore
            .collection('conversations')
            .where('participants', arrayContains: userId);
            
        final conversations = await conversationsQuery.limit(20).get();

        List<Map<String, dynamic>> chats = [];
        for (var doc in conversations.docs) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            
            // Get other participant info
            final participants = List<String>.from(data['participants'] ?? []);
            participants.remove(userId);
            
            if (participants.isNotEmpty) {
              final otherUserId = participants.first;
              final otherUserDoc = await _firestore
                  .collection('users')
                  .doc(otherUserId)
                  .get();
              
              if (otherUserDoc.exists) {
                data['otherUser'] = otherUserDoc.data();
                data['otherUserId'] = otherUserId;
                chats.add(data);
              }
            }
          } catch (e) {
            print('Error processing conversation: $e');
          }
        }
        
        if (mounted) {
          setState(() {
            _chatHistory = chats;
            
            // Sort by lastMessageTime if available
            _chatHistory.sort((a, b) {
              final aTime = a['lastMessageTime'];
              final bTime = b['lastMessageTime'];
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return (bTime as Timestamp).compareTo(aTime as Timestamp);
            });
          });
        }
      } catch (e) {
        print('Error loading chat history: $e');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading profile data';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final isGlass = themeProvider.isGlassmorphism;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              elevation: 0,
              backgroundColor: isGlass 
                  ? Colors.white.withValues(alpha: 0.7)
                  : (isDarkMode ? Colors.black.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95)),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Profile',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings, color: isDarkMode ? Colors.white : Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
      ),
    ),
  ),
),
      body: Stack(
  children: [
    // iOS 16 Glassmorphism gradient background
    Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isGlass 
              ? [
                  const Color(0xFFE3F2FD).withValues(alpha: 0.8),
                  const Color(0xFFF3E5F5).withValues(alpha: 0.6),
                  const Color(0xFFE8F5E9).withValues(alpha: 0.4),
                  const Color(0xFFFFF3E0).withValues(alpha: 0.3),
                ]
              : isDarkMode 
                  ? [
                      Colors.black,
                      const Color(0xFF1C1C1E),
                    ]
                  : [
                      const Color(0xFFF5F5F7),
                      Colors.white,
                    ],
        ),
      ),
    ),
    
    // Floating glass circles for depth
    if (isGlass) ...[
      Positioned(
        top: 150,
        right: -100,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                ThemeProvider.iosPurple.withValues(alpha: 0.2),
                ThemeProvider.iosPurple.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 200,
        left: -100,
        child: Container(
          width: 350,
          height: 350,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                ThemeProvider.iosBlue.withValues(alpha: 0.15),
                ThemeProvider.iosBlue.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    ],
    
    _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: kToolbarHeight + 20),
                    // Profile Header
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isGlass
                            ? Colors.white.withValues(alpha: 0.7)
                            : (isDarkMode ? Colors.grey[900] : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isGlass
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                        border: isGlass
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Profile Photo
                              UserAvatar(
                                profileImageUrl: _userProfile?['profileImageUrl'] ?? _userProfile?['photoUrl'],
                                radius: 40,
                                fallbackText: _userProfile?['name'] ?? 'User',
                              ),
                              const SizedBox(width: 20),
                              // User Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userProfile?['name'] ?? 'Unknown User',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 14,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _userProfile?['email'] ?? _auth.currentUser?.email ?? 'No email',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        // Manual location update
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Updating location...')),
                                        );
                                        final success = await _locationService.updateUserLocation();
                                        if (success) {
                                          await Future.delayed(const Duration(seconds: 1));
                                          _loadUserData();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Location updated successfully'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Could not update location'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _userProfile?['displayLocation'] ?? 
                                              _userProfile?['city'] ?? 
                                              _userProfile?['location'] ?? 
                                              'Tap to set location',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: (_userProfile?['displayLocation'] == null && 
                                                        _userProfile?['city'] == null && 
                                                        _userProfile?['location'] == null) 
                                                    ? Theme.of(context).primaryColor
                                                    : isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                decoration: (_userProfile?['displayLocation'] == null && 
                                                            _userProfile?['city'] == null && 
                                                            _userProfile?['location'] == null)
                                                    ? TextDecoration.underline
                                                    : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Tab Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isGlass
                            ? Colors.white.withValues(alpha: 0.7)
                            : (isDarkMode ? Colors.grey[900] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                        border: isGlass
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              )
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: isGlass
                              ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: Theme.of(context).primaryColor,
                            unselectedLabelColor: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                            indicatorColor: Theme.of(context).primaryColor,
                            indicatorWeight: 3,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            ),
                            tabs: const [
                              Tab(text: 'History'),
                              Tab(text: 'Chats'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildHistoryTab(isDarkMode),
                          _buildChatsTab(isDarkMode),
                        ],
                      ),
                    ),
                  ],
                ),
          ],
        ),
    );
  }

  Widget _buildHistoryTab(bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGlass = themeProvider.isGlassmorphism;
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 60,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No search history',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[600] : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your searches will appear here',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchHistory.length,
      itemBuilder: (context, index) {
        final intent = _searchHistory[index];
        final createdAt = intent['createdAt'];
        String timeAgo = 'Recently';
        
        if (createdAt != null && createdAt is Timestamp) {
          timeAgo = timeago.format(createdAt.toDate());
        }

        return Dismissible(
          key: Key(intent['id']),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (direction) async {
            // Show confirmation dialog
            return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Delete Search History'),
                  content: Text(
                    'Are you sure you want to delete "${intent['title'] ?? intent['embeddingText'] ?? 'this search'}"? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) async {
            // Delete from database
            final success = await _intentService.deleteIntent(intent['id']);
            
            if (success) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search history deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              // Reload the data to update UI
              _loadUserData();
            } else {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to delete search history'),
                  backgroundColor: Colors.red,
                ),
              );
              // Reload to restore the item if deletion failed
              _loadUserData();
            }
          },
          child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isGlass
                ? Colors.white.withValues(alpha: 0.5)
                : (isDarkMode ? Colors.grey[850] : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: isGlass
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  )
                : null,
            boxShadow: isGlass
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: isGlass
                  ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
          title: Text(
            intent['title'] ?? intent['embeddingText'] ?? 'Search',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            'Role: ${intent['userRole'] ?? 'Unknown'} • $timeAgo',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildChatsTab(bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGlass = themeProvider.isGlassmorphism;
    if (_chatHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No chat history',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[600] : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your conversations will appear here',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chatHistory.length,
      itemBuilder: (context, index) {
        final chat = _chatHistory[index];
        final otherUser = chat['otherUser'] ?? {};
        final lastMessageTime = chat['lastMessageTime'];
        String timeAgo = 'Recently';
        
        if (lastMessageTime != null && lastMessageTime is Timestamp) {
          timeAgo = timeago.format(lastMessageTime.toDate());
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isGlass
                ? Colors.white.withValues(alpha: 0.5)
                : (isDarkMode ? Colors.grey[850] : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: isGlass
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  )
                : null,
            boxShadow: isGlass
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: isGlass
                  ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: UserAvatar(
            profileImageUrl: otherUser['profileImageUrl'] ?? otherUser['photoUrl'],
            radius: 20,
            fallbackText: otherUser['name'] ?? 'User',
          ),
          title: Text(
            otherUser['name'] ?? 'Unknown User',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            chat['lastMessage'] ?? 'No messages',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            timeAgo,
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
          onTap: () {
            if (chat['otherUserId'] != null) {
              final userProfile = UserProfile.fromMap(
                otherUser,
                chat['otherUserId'],
              );
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EnhancedChatScreen(
                    otherUser: userProfile,
                  ),
                ),
              );
            }
          },
              ),
            ),
          ),
        );
      },
    );
  }
}