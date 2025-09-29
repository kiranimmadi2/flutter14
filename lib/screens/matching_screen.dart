import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/user_profile.dart';
import '../services/matching_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/user_manager.dart';
import '../services/photo_cache_service.dart';
import 'profile_view_screen.dart';
import 'create_post_screen.dart';
import 'profile_edit_screen.dart';
import '../widgets/user_avatar.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final MatchingService _matchingService = MatchingService();
  final UserManager _userManager = UserManager();
  final PhotoCacheService _photoCache = PhotoCacheService();
  final TextEditingController _searchController = TextEditingController();
  
  List<PostModel> _posts = [];
  Map<String, String> _userNames = {}; // Store user names
  Map<String, String?> _userPhotos = {}; // Store user photos
  String? _currentUserPhoto;
  String? _currentUserName;
  bool _isLoading = false;
  bool _useVectorSearch = true; // Toggle for vector search

  @override
  void initState() {
    super.initState();
    
    // Always load current user profile on init
    _loadCurrentUserProfile();
    
    // Listen to profile changes
    _userManager.profileStream.listen((profile) {
      if (mounted && profile != null) {
        print('Profile stream update: ${profile['photoUrl']}');
        setState(() {
          _currentUserPhoto = profile['photoUrl'];
          _currentUserName = profile['name'];
        });
      }
    });
    
    // Load current user profile and initial posts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentUserProfile();
      _loadInitialPosts();
    });
    
    // Listen to search controller changes to update button color
    _searchController.addListener(() {
      setState(() {});
    });
  }
  
  Future<void> _loadCurrentUserProfile() async {
    try {
      final user = _userManager.currentUser;
      print('Loading profile for user: ${user?.email}');
      
      if (user != null) {
        // First try to get from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          print('Found Firestore profile: ${data['photoUrl']}');
          
          String? photoUrl = data['photoUrl'];
          // Fix Google photo URL if needed
          if (photoUrl != null && photoUrl.contains('googleusercontent.com') && !photoUrl.contains('=s400')) {
            final baseUrl = photoUrl.split('=')[0];
            photoUrl = '$baseUrl=s400';
            // Update Firestore with fixed URL
            await doc.reference.update({'photoUrl': photoUrl});
          }
          
          if (mounted) {
            setState(() {
              _currentUserPhoto = photoUrl;
              _currentUserName = data['name'] ?? user.displayName ?? user.email?.split('@')[0];
            });
          }
        } else {
          print('No Firestore profile found, creating from Auth');
          // If no profile, create one with Google data
          await _createProfileFromAuth(user);
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Try to get from Auth as fallback
      final user = _userManager.currentUser;
      if (user != null && mounted) {
        setState(() {
          _currentUserPhoto = user.photoURL;
          _currentUserName = user.displayName ?? user.email?.split('@')[0];
        });
      }
    }
  }
  
  Future<void> _createProfileFromAuth(User user) async {
    try {
      String? photoUrl = user.photoURL;
      // Fix Google photo URL
      if (photoUrl != null && photoUrl.contains('googleusercontent.com')) {
        final baseUrl = photoUrl.split('=')[0];
        photoUrl = '$baseUrl=s400';
      }
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
      }, SetOptions(merge: true));
      
      // Reload profile
      await _loadCurrentUserProfile();
    } catch (e) {
      print('Error creating profile from auth: $e');
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPosts() async {
    setState(() => _isLoading = true);
    try {
      final results = await _matchingService.searchPosts(
        query: '',
      );
      
      // Fetch user names for all posts
      await _fetchUserNames(results);
      
      setState(() {
        _posts = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading initial posts: $e');
      setState(() => _isLoading = false);
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load posts: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _fetchUserNames(List<PostModel> posts) async {
    for (final post in posts) {
      if (!_userNames.containsKey(post.userId)) {
        try {
          // Check cache first
          final cachedPhoto = _photoCache.getCachedPhotoUrl(post.userId);
          if (cachedPhoto != null) {
            _userPhotos[post.userId] = cachedPhoto;
          }
          
          // Use UserManager to get profile (it also handles caching)
          final profileData = await _userManager.getUserProfile(post.userId);
          if (profileData != null) {
            _userNames[post.userId] = profileData['name'] ?? 'Unknown User';
            _userPhotos[post.userId] = profileData['photoUrl'];
            
            // Cache the photo
            if (profileData['photoUrl'] != null) {
              _photoCache.cachePhotoUrl(post.userId, profileData['photoUrl']);
            }
          } else {
            // Try matching service as fallback
            final userProfile = await _matchingService.getUserProfile(post.userId);
            if (userProfile != null) {
              _userNames[post.userId] = userProfile.name;
              _userPhotos[post.userId] = userProfile.photoUrl;
              
              // Cache the photo
              if (userProfile.photoUrl != null) {
                _photoCache.cachePhotoUrl(post.userId, userProfile.photoUrl);
              }
            }
          }
        } catch (e) {
          print('Error fetching user profile for ${post.userId}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supper'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            ).then((_) => _performSearch()),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            ).then((_) => _loadCurrentUserProfile()),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: UserAvatar(
                profileImageUrl: _currentUserPhoto,
                radius: 18,
                fallbackText: _currentUserName,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPostsList(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildSearchBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search in Supper...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _searchController.text.isNotEmpty 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _searchController.text.isNotEmpty ? _performSearch : null,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildPostsList() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentUserName != null && _currentUserName!.isNotEmpty)
              Text(
                'Hello ${_currentUserName!.split(' ')[0]},',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Find Your Need',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showPostDetails(post),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.images != null && post.images!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: post.images!.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // User avatar
                      UserAvatar(
                        profileImageUrl: _userPhotos[post.userId],
                        radius: 16,
                        fallbackText: _userNames[post.userId],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _userNames[post.userId] ?? 'Unknown User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (post.similarityScore != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                '${(post.similarityScore! * 100).toInt()}% match',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      if (post.location != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              post.location!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (post.price != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${post.currency ?? '\$'}${post.price!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      // Load all posts if no search criteria
      _loadInitialPosts();
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      List<PostModel> results;
      
      if (_useVectorSearch && query.isNotEmpty) {
        // Use vector search for non-empty queries
        results = await _matchingService.vectorSearch(
          query: query,
          limit: 20,
          minSimilarity: 0.5,
        );
      } else {
        // Use regular search
        results = await _matchingService.searchPosts(
          query: query.isEmpty ? '*' : query,
          similarityThreshold: 0.5,
        );
      }
      
      // Fetch user names for the search results
      await _fetchUserNames(results);
      
      setState(() {
        _posts = results;
        _isLoading = false;
      });
      
      // Show encouraging message if no results
      if (results.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('We\'ll notify you when someone posts about "$query"'),
            backgroundColor: Colors.blue,
            action: SnackBarAction(
              label: 'Create Post',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPostDetails(PostModel post) async {
    await _matchingService.updatePostView(post.id);
    
    final userProfile = await _matchingService.getUserProfile(post.userId);
    if (userProfile != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileViewScreen(
            post: post,
            userProfile: userProfile,
          ),
        ),
      );
    }
  }

}