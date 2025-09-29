import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_post_model.dart';
import '../models/user_profile.dart';
import 'ai_intent_engine.dart';
import 'profile_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'debug_service.dart';

/// AI-powered matching service that finds the best people based on intent
class AIMatchingService {
  static final AIMatchingService _instance = AIMatchingService._internal();
  factory AIMatchingService() => _instance;
  AIMatchingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AIIntentEngine _intentEngine = AIIntentEngine();
  final ProfileService _profileService = ProfileService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription? _postListener;
  final Map<String, Timer> _matchingTimers = {};

  /// Initialize the service
  Future<void> initialize() async {
    await _intentEngine.initialize();
    _startRealtimeListening();
  }

  /// Start listening for new posts in real-time
  void _startRealtimeListening() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _postListener?.cancel();
    _postListener = _firestore
        .collection('ai_posts')
        .where('userId', isNotEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _processNewPost(change.doc);
        }
      }
    });
  }

  /// Process a new post and find matches
  Future<void> _processNewPost(DocumentSnapshot doc) async {
    try {
      final newPost = AIPostModel.fromFirestore(doc);
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Get current user's active posts
      final userPosts = await _firestore
          .collection('ai_posts')
          .where('userId', isEqualTo: currentUserId)
          .where('isActive', isEqualTo: true)
          .get();

      for (var userDoc in userPosts.docs) {
        final userPost = AIPostModel.fromFirestore(userDoc);
        
        // Check compatibility using AI
        final compatibility = await _checkCompatibility(userPost, newPost);
        
        // LOWERED THRESHOLD FOR TESTING - was 0.7, now 0.2
        if (compatibility.score > 0.2) {
          DebugService.log('MATCHING', 'processNewPost',
              'Match found with score ${compatibility.score}');
          await _notifyMatch(userPost, newPost, compatibility);
        }
      }
    } catch (e) {
      debugPrint('Error processing new post: $e');
    }
  }

  /// Create a new post with AI intent understanding
  Future<String?> createPost(String userPrompt) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Analyze intent with AI
      final intentAnalysis = await _intentEngine.analyzeIntent(userPrompt);
      
      // Generate embedding for semantic search
      final embedding = await _intentEngine.generateEmbedding(
        '${intentAnalysis.primaryIntent} ${intentAnalysis.searchKeywords.join(' ')}'
      );

      // Get user location if available
      final position = await _locationService.getCurrentLocation();
      
      // Create the post
      final post = AIPostModel(
        id: '',
        userId: userId,
        originalPrompt: userPrompt,
        intentAnalysis: intentAnalysis.toJson(),
        clarificationAnswers: {},
        embedding: embedding,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        location: null, // Position doesn't have address property
        latitude: position?.latitude,
        longitude: position?.longitude,
        metadata: {
          'created_via': 'ai_engine',
          'version': '2.0',
        },
      );

      // Save to Firestore
      final docRef = await _firestore.collection('ai_posts').add(post.toFirestore());
      
      // Find immediate matches
      await _findAndNotifyMatches(post.copyWith(id: docRef.id));
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  /// Find the best matching people for a post
  Future<List<MatchedUser>> findBestPeople(AIPostModel userPost) async {
    try {
      // Get all active posts from other users
      final snapshot = await _firestore
          .collection('ai_posts')
          .where('userId', isNotEqualTo: userPost.userId)
          .where('isActive', isEqualTo: true)
          .get();

      List<MatchedUser> matches = [];

      for (var doc in snapshot.docs) {
        final otherPost = AIPostModel.fromFirestore(doc);
        
        // Calculate match score using multiple factors
        final matchScore = await _calculateMatchScore(userPost, otherPost);
        
        // LOWERED THRESHOLD FOR TESTING - was 0.5, now 0.2
        if (matchScore.totalScore > 0.2) {
          // Get user profile
          final userProfileData = await _profileService.getUserProfile(otherPost.userId);
          if (userProfileData != null) {
            // Convert Map to UserProfile
            final userProfile = UserProfile(
              uid: otherPost.userId,
              name: userProfileData['name'] ?? 'User',
              email: userProfileData['email'] ?? '',
              profileImageUrl: userProfileData['profileImageUrl'] ?? userProfileData['photoUrl'],
              createdAt: DateTime.now(),
              lastSeen: DateTime.now(),
              fcmToken: userProfileData['fcmToken'],
              bio: userProfileData['bio'] ?? '',
              interests: List<String>.from(userProfileData['interests'] ?? []),
              isVerified: userProfileData['isVerified'] ?? false,
            );
            matches.add(MatchedUser(
              profile: userProfile,
              post: otherPost,
              matchScore: matchScore,
            ));
          }
        }
      }

      // Sort by score (best matches first)
      matches.sort((a, b) => b.matchScore.totalScore.compareTo(a.matchScore.totalScore));
      
      return matches.take(20).toList();
    } catch (e) {
      debugPrint('Error finding best people: $e');
      return [];
    }
  }

  /// Calculate comprehensive match score
  Future<MatchScore> _calculateMatchScore(AIPostModel post1, AIPostModel post2) async {
    // 1. AI Compatibility Score (40% weight)
    final compatibility = await _checkCompatibility(post1, post2);
    final aiScore = compatibility.score * 0.4;

    // 2. Semantic Similarity Score (30% weight)
    double semanticScore = 0;
    if (post1.embedding.isNotEmpty && post2.embedding.isNotEmpty) {
      semanticScore = _cosineSimilarity(post1.embedding, post2.embedding) * 0.3;
    }

    // 3. Location Score (15% weight)
    double locationScore = 0;
    if (post1.latitude != null && post2.latitude != null) {
      final distance = _calculateDistance(
        post1.latitude!, post1.longitude!,
        post2.latitude!, post2.longitude!,
      );
      // Score based on proximity (closer = higher score)
      if (distance < 5) locationScore = 0.15;
      else if (distance < 10) locationScore = 0.12;
      else if (distance < 25) locationScore = 0.08;
      else if (distance < 50) locationScore = 0.04;
    }

    // 4. Timing Score (10% weight)
    final timeDiff = post1.createdAt.difference(post2.createdAt).inHours.abs();
    double timingScore = 0;
    if (timeDiff < 1) timingScore = 0.10;
    else if (timeDiff < 24) timingScore = 0.08;
    else if (timeDiff < 72) timingScore = 0.05;
    else if (timeDiff < 168) timingScore = 0.02;

    // 5. Keyword Match Score (5% weight)
    final keywordScore = _calculateKeywordMatch(post1, post2) * 0.05;

    final totalScore = aiScore + semanticScore + locationScore + timingScore + keywordScore;

    return MatchScore(
      totalScore: totalScore.clamp(0.0, 1.0),
      aiCompatibility: compatibility.score,
      semanticSimilarity: semanticScore / 0.3,
      locationProximity: locationScore / 0.15,
      timingAlignment: timingScore / 0.10,
      keywordMatch: keywordScore / 0.05,
      reasons: compatibility.reasons,
      concerns: compatibility.concerns,
    );
  }

  /// Check compatibility between two posts using AI
  Future<CompatibilityAnalysis> _checkCompatibility(AIPostModel post1, AIPostModel post2) async {
    final intent1 = IntentAnalysis.fromJson(post1.intentAnalysis);
    final intent2 = IntentAnalysis.fromJson(post2.intentAnalysis);
    
    return await _intentEngine.analyzeCompatibility(
      intent1,
      intent2,
      post1.clarificationAnswers,
      post2.clarificationAnswers,
    );
  }

  /// Calculate cosine similarity between embeddings
  double _cosineSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length || vec1.isEmpty) return 0.0;
    
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (int i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
      norm1 += vec1[i] * vec1[i];
      norm2 += vec2[i] * vec2[i];
    }
    
    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  /// Calculate distance between two coordinates
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Calculate keyword match between posts
  double _calculateKeywordMatch(AIPostModel post1, AIPostModel post2) {
    final keywords1 = post1.searchKeywords.toSet();
    final keywords2 = post2.searchKeywords.toSet();
    
    if (keywords1.isEmpty || keywords2.isEmpty) return 0.0;
    
    final intersection = keywords1.intersection(keywords2);
    final union = keywords1.union(keywords2);
    
    return intersection.length / union.length;
  }

  /// Find and notify about matches
  Future<void> _findAndNotifyMatches(AIPostModel newPost) async {
    try {
      final matches = await findBestPeople(newPost);
      
      // Notify about top matches
      for (var match in matches.take(3)) {
        // LOWERED THRESHOLD FOR TESTING - was 0.8, now 0.3
        if (match.matchScore.totalScore > 0.3) {
          await _notifyMatch(newPost, match.post, 
              CompatibilityAnalysis(
                score: match.matchScore.aiCompatibility,
                isMatch: true,
                reasons: match.matchScore.reasons,
                concerns: match.matchScore.concerns,
              ));
        }
      }
    } catch (e) {
      debugPrint('Error finding matches: $e');
    }
  }

  /// Send notification about a match
  Future<void> _notifyMatch(
    AIPostModel userPost,
    AIPostModel matchedPost,
    CompatibilityAnalysis compatibility,
  ) async {
    try {
      final matchedUserData = await _profileService.getUserProfile(matchedPost.userId);
      if (matchedUserData == null || matchedUserData['fcmToken'] == null) return;

      // Generate a friendly match summary
      final summary = await _intentEngine.generateMatchSummary(
        IntentAnalysis.fromJson(userPost.intentAnalysis),
        IntentAnalysis.fromJson(matchedPost.intentAnalysis),
        compatibility,
      );

      await _notificationService.sendPushNotification(
        recipientToken: matchedUserData['fcmToken']!,
        title: 'Perfect Match Found! 🎯',
        body: summary,
        data: {
          'type': 'ai_match',
          'postId': userPost.id,
          'matchedPostId': matchedPost.id,
          'score': compatibility.score.toString(),
        },
      );

      // Store match in database
      await _storeMatch(userPost, matchedPost, compatibility);
    } catch (e) {
      debugPrint('Error sending match notification: $e');
    }
  }

  /// Store match relationship
  Future<void> _storeMatch(
    AIPostModel post1,
    AIPostModel post2,
    CompatibilityAnalysis compatibility,
  ) async {
    try {
      await _firestore.collection('ai_matches').add({
        'post1Id': post1.id,
        'post2Id': post2.id,
        'user1Id': post1.userId,
        'user2Id': post2.userId,
        'score': compatibility.score,
        'matchType': compatibility.matchType,
        'reasons': compatibility.reasons,
        'concerns': compatibility.concerns,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Error storing match: $e');
    }
  }

  /// Get match suggestions with explanations
  Future<List<MatchSuggestion>> getMatchSuggestions(String userId) async {
    try {
      // Get user's recent posts
      final userPosts = await _firestore
          .collection('ai_posts')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (userPosts.docs.isEmpty) return [];

      List<MatchSuggestion> allSuggestions = [];

      for (var doc in userPosts.docs) {
        final post = AIPostModel.fromFirestore(doc);
        final matches = await findBestPeople(post);
        
        for (var match in matches.take(3)) {
          // Generate explanation for why this is a good match
          final explanation = await _intentEngine.generateMatchSummary(
            IntentAnalysis.fromJson(post.intentAnalysis),
            IntentAnalysis.fromJson(match.post.intentAnalysis),
            CompatibilityAnalysis(
              score: match.matchScore.aiCompatibility,
              isMatch: true,
              reasons: match.matchScore.reasons,
            ),
          );

          allSuggestions.add(MatchSuggestion(
            userPost: post,
            matchedUser: match,
            explanation: explanation,
            conversationStarter: await _intentEngine.generateConversationStarter(
              IntentAnalysis.fromJson(post.intentAnalysis),
              IntentAnalysis.fromJson(match.post.intentAnalysis),
            ),
          ));
        }
      }

      // Sort by score and return top suggestions
      allSuggestions.sort((a, b) => 
          b.matchedUser.matchScore.totalScore.compareTo(a.matchedUser.matchScore.totalScore));
      
      return allSuggestions.take(10).toList();
    } catch (e) {
      debugPrint('Error getting match suggestions: $e');
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _postListener?.cancel();
    for (var timer in _matchingTimers.values) {
      timer.cancel();
    }
    _matchingTimers.clear();
  }
}

/// Matched user with profile and score
class MatchedUser {
  final UserProfile profile;
  final AIPostModel post;
  final MatchScore matchScore;

  MatchedUser({
    required this.profile,
    required this.post,
    required this.matchScore,
  });
}

/// Comprehensive match score breakdown
class MatchScore {
  final double totalScore;
  final double aiCompatibility;
  final double semanticSimilarity;
  final double locationProximity;
  final double timingAlignment;
  final double keywordMatch;
  final List<String> reasons;
  final List<String> concerns;

  MatchScore({
    required this.totalScore,
    required this.aiCompatibility,
    required this.semanticSimilarity,
    required this.locationProximity,
    required this.timingAlignment,
    required this.keywordMatch,
    required this.reasons,
    required this.concerns,
  });
}

/// Match suggestion with explanation
class MatchSuggestion {
  final AIPostModel userPost;
  final MatchedUser matchedUser;
  final String explanation;
  final String conversationStarter;

  MatchSuggestion({
    required this.userPost,
    required this.matchedUser,
    required this.explanation,
    required this.conversationStarter,
  });
}