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

/// Fixed AI-powered matching service - addresses all identified issues
class FixedAIMatchingService {
  static final FixedAIMatchingService _instance = FixedAIMatchingService._internal();
  factory FixedAIMatchingService() => _instance;
  FixedAIMatchingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AIIntentEngine _intentEngine = AIIntentEngine();
  final ProfileService _profileService = ProfileService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription? _postListener;
  final Map<String, Timer> _matchingTimers = {};
  bool _isInitialized = false;

  /// Initialize the service with proper error handling
  Future<void> initialize() async {
    if (_isInitialized) return;

    final stopwatch = Stopwatch()..start();
    try {
      DebugService.log('MATCHING', 'initialize', 'Starting fixed matching service initialization');

      await _intentEngine.initialize();
      _startRealtimeListening();

      _isInitialized = true;
      DebugService.logPerformance('matching_initialize', stopwatch.elapsedMilliseconds);
      DebugService.log('MATCHING', 'initialize', 'Fixed matching service initialized successfully');
    } catch (e) {
      DebugService.log('MATCHING', 'initialize', 'Failed to initialize matching service',
          data: {'error': e.toString()});
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  /// Start listening for new posts in real-time with proper error handling
  void _startRealtimeListening() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      DebugService.log('MATCHING', '_startRealtimeListening', 'No authenticated user, skipping realtime listener');
      return;
    }

    try {
      _postListener?.cancel();
      _postListener = _firestore
          .collection('ai_posts')
          .where('userId', isNotEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .listen(
            (snapshot) {
              DebugService.log('MATCHING', '_startRealtimeListening',
                  'Received ${snapshot.docChanges.length} document changes');

              for (var change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  _processNewPost(change.doc);
                }
              }
            },
            onError: (error) {
              DebugService.log('MATCHING', '_startRealtimeListening',
                  'Error in realtime listener', data: {'error': error.toString()});
            },
          );

      DebugService.log('MATCHING', '_startRealtimeListening', 'Realtime listener started for user: $userId');
    } catch (e) {
      DebugService.log('MATCHING', '_startRealtimeListening',
          'Failed to start realtime listener', data: {'error': e.toString()});
    }
  }

  /// Process a new post and find matches with comprehensive debugging
  Future<void> _processNewPost(DocumentSnapshot doc) async {
    final stopwatch = Stopwatch()..start();
    try {
      final newPost = AIPostModel.fromFirestore(doc);
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      DebugService.log('MATCHING', '_processNewPost',
          'Processing new post: ${doc.id}',
          data: {
            'post_id': doc.id,
            'user_id': newPost.userId,
            'prompt': newPost.originalPrompt,
          });

      // Get current user's active posts
      final userPosts = await _firestore
          .collection('ai_posts')
          .where('userId', isEqualTo: currentUserId)
          .where('isActive', isEqualTo: true)
          .get();

      DebugService.log('MATCHING', '_processNewPost',
          'Found ${userPosts.docs.length} active posts for current user');

      for (var userDoc in userPosts.docs) {
        try {
          final userPost = AIPostModel.fromFirestore(userDoc);

          // Check compatibility using AI
          final compatibility = await _checkCompatibility(userPost, newPost);

          DebugService.log('MATCHING', '_processNewPost',
              'Compatibility score: ${compatibility.score}',
              data: {
                'user_post_id': userDoc.id,
                'new_post_id': doc.id,
                'score': compatibility.score,
                'reasons': compatibility.reasons,
              });

          // FIXED THRESHOLD: Lowered from 0.7 to 0.2 for better matching
          if (compatibility.score > 0.2) {
            DebugService.log('MATCHING', '_processNewPost',
                'Match found! Sending notification',
                data: {'score': compatibility.score});
            await _notifyMatch(userPost, newPost, compatibility);
          }
        } catch (e) {
          DebugService.log('MATCHING', '_processNewPost',
              'Error processing user post: ${userDoc.id}',
              data: {'error': e.toString()});
        }
      }
    } catch (e) {
      DebugService.log('MATCHING', '_processNewPost',
          'Error processing new post: ${doc.id}',
          data: {'error': e.toString()});
    } finally {
      stopwatch.stop();
    }
  }

  /// Create a new post with comprehensive validation and debugging
  Future<String?> createPost(String userPrompt) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (userPrompt.trim().isEmpty) {
        throw Exception('User prompt cannot be empty');
      }

      DebugService.log('MATCHING', 'createPost', 'Creating post for user: $userId',
          data: {'prompt': userPrompt});

      // Step 1: Analyze intent with AI
      DebugService.log('MATCHING', 'createPost', 'Step 1: Analyzing intent...');
      final intentAnalysis = await _intentEngine.analyzeIntent(userPrompt);

      if (intentAnalysis.primaryIntent.isEmpty) {
        throw Exception('Failed to analyze intent - empty primary intent');
      }

      // Step 2: Generate embedding for semantic search
      DebugService.log('MATCHING', 'createPost', 'Step 2: Generating embedding...');
      final embeddingText = '${intentAnalysis.primaryIntent} ${intentAnalysis.searchKeywords.join(' ')}';
      final embedding = await _intentEngine.generateEmbedding(embeddingText);

      if (embedding.isEmpty) {
        throw Exception('Failed to generate embedding for post');
      }

      if (embedding.length != 768) {
        DebugService.log('MATCHING', 'createPost',
            'Warning: Unexpected embedding dimension: ${embedding.length}');
      }

      // Step 3: Get user location
      DebugService.log('MATCHING', 'createPost', 'Step 3: Getting user location...');
      final position = await _locationService.getCurrentLocation();

      // Step 4: Create the post model
      final post = AIPostModel(
        id: '', // Will be set by Firestore
        userId: userId,
        originalPrompt: userPrompt,
        intentAnalysis: intentAnalysis.toJson(),
        clarificationAnswers: {},
        embedding: embedding,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        location: null,
        latitude: position?.latitude,
        longitude: position?.longitude,
        metadata: {
          'created_via': 'fixed_ai_engine',
          'version': '3.0',
          'created_at': DateTime.now().toIso8601String(),
          'embedding_length': embedding.length,
          'intent_confidence': 1.0, // Could be calculated from AI response
        },
      );

      // Step 5: Save to Firestore
      DebugService.log('MATCHING', 'createPost', 'Step 4: Saving to Firestore...');
      final docRef = await _firestore.collection('ai_posts').add(post.toFirestore());

      DebugService.logFirestore('CREATE', 'ai_posts',
          docId: docRef.id,
          data: {
            'prompt': userPrompt,
            'embedding_length': embedding.length,
            'intent': intentAnalysis.primaryIntent,
            'keywords': intentAnalysis.searchKeywords,
          });

      // Step 6: Find immediate matches
      DebugService.log('MATCHING', 'createPost', 'Step 5: Finding immediate matches...');
      await _findAndNotifyMatches(post.copyWith(id: docRef.id));

      DebugService.logPerformance('createPost', stopwatch.elapsedMilliseconds,
          metrics: {
            'post_id': docRef.id,
            'embedding_length': embedding.length,
            'keywords_count': intentAnalysis.searchKeywords.length,
          });

      DebugService.log('MATCHING', 'createPost', 'Post created successfully',
          data: {'post_id': docRef.id});

      return docRef.id;
    } catch (e) {
      DebugService.log('MATCHING', 'createPost', 'Error creating post',
          data: {
            'error': e.toString(),
            'prompt': userPrompt,
            'stack_trace': StackTrace.current.toString(),
          });
      return null;
    } finally {
      stopwatch.stop();
    }
  }

  /// Find the best matching people with improved algorithm and debugging
  Future<List<MatchedUser>> findBestPeople(AIPostModel userPost) async {
    final stopwatch = Stopwatch()..start();
    try {
      DebugService.log('MATCHING', 'findBestPeople',
          'Finding matches for post: ${userPost.id}',
          data: {
            'user_id': userPost.userId,
            'prompt': userPost.originalPrompt,
            'embedding_available': userPost.embedding.isNotEmpty,
            'embedding_length': userPost.embedding.length,
          });

      // Query all active posts from other users
      final snapshot = await _firestore
          .collection('ai_posts')
          .where('userId', isNotEqualTo: userPost.userId)
          .where('isActive', isEqualTo: true)
          .get();

      DebugService.logFirestore('QUERY', 'ai_posts',
          query: {'userId_not': userPost.userId, 'isActive': true},
          resultCount: snapshot.docs.length);

      if (snapshot.docs.isEmpty) {
        DebugService.log('MATCHING', 'findBestPeople', 'No candidate posts found');
        return [];
      }

      List<MatchedUser> matches = [];
      int processedCount = 0;
      int errorCount = 0;
      Map<String, double> scoreBreakdown = {};

      for (var doc in snapshot.docs) {
        try {
          final otherPost = AIPostModel.fromFirestore(doc);
          processedCount++;

          // Validate the candidate post
          if (otherPost.embedding.isEmpty) {
            DebugService.log('MATCHING', 'findBestPeople',
                'Skipping post with empty embedding: ${doc.id}');
            continue;
          }

          // Calculate comprehensive match score
          final matchScore = await _calculateMatchScore(userPost, otherPost);
          scoreBreakdown['${doc.id}_total'] = matchScore.totalScore;

          // FIXED THRESHOLD: Lowered from 0.5 to 0.2 for testing
          if (matchScore.totalScore > 0.2) {
            DebugService.log('MATCHING', 'findBestPeople',
                'Found potential match with score: ${matchScore.totalScore}',
                data: {
                  'other_post_id': doc.id,
                  'other_user': otherPost.userId,
                  'other_prompt': otherPost.originalPrompt,
                  'score_breakdown': {
                    'total': matchScore.totalScore,
                    'ai_compatibility': matchScore.aiCompatibility,
                    'semantic_similarity': matchScore.semanticSimilarity,
                    'location_proximity': matchScore.locationProximity,
                  }
                });

            // Get user profile
            final userProfileData = await _profileService.getUserProfile(otherPost.userId);
            if (userProfileData != null) {
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
            } else {
              DebugService.log('MATCHING', 'findBestPeople',
                  'Skipping match due to missing user profile: ${otherPost.userId}');
            }
          }
        } catch (e) {
          errorCount++;
          DebugService.log('MATCHING', 'findBestPeople',
              'Error processing candidate post: ${doc.id}',
              data: {'error': e.toString()});
          continue;
        }
      }

      // Sort by score (best matches first)
      matches.sort((a, b) => b.matchScore.totalScore.compareTo(a.matchScore.totalScore));

      DebugService.logMatching('findBestPeople_complete',
          candidateCount: processedCount,
          matchCount: matches.length,
          threshold: 0.2,
          scores: scoreBreakdown,
          durationMs: stopwatch.elapsedMilliseconds);

      final result = matches.take(20).toList();

      DebugService.log('MATCHING', 'findBestPeople',
          'Matching complete',
          data: {
            'candidates_processed': processedCount,
            'errors_encountered': errorCount,
            'matches_found': result.length,
            'top_score': result.isNotEmpty ? result.first.matchScore.totalScore : 0.0,
          });

      return result;
    } catch (e) {
      DebugService.log('MATCHING', 'findBestPeople', 'Critical error in matching',
          data: {
            'error': e.toString(),
            'post_id': userPost.id,
            'stack_trace': StackTrace.current.toString(),
          });
      return [];
    } finally {
      stopwatch.stop();
    }
  }

  /// Enhanced match score calculation with detailed logging
  Future<MatchScore> _calculateMatchScore(AIPostModel post1, AIPostModel post2) async {
    final stopwatch = Stopwatch()..start();
    try {
      // 1. AI Compatibility Score (40% weight)
      final compatibility = await _checkCompatibility(post1, post2);
      final aiScore = compatibility.score * 0.4;

      // 2. Semantic Similarity Score (30% weight)
      double semanticScore = 0;
      double rawSemanticSimilarity = 0;
      if (post1.embedding.isNotEmpty && post2.embedding.isNotEmpty) {
        rawSemanticSimilarity = _cosineSimilarity(post1.embedding, post2.embedding);
        semanticScore = rawSemanticSimilarity * 0.3;
      }

      // 3. Location Score (15% weight)
      double locationScore = 0;
      double? distance;
      if (post1.latitude != null && post2.latitude != null) {
        distance = _calculateDistance(
          post1.latitude!, post1.longitude!,
          post2.latitude!, post2.longitude!,
        );
        // Improved location scoring
        if (distance < 5) locationScore = 0.15;
        else if (distance < 10) locationScore = 0.12;
        else if (distance < 25) locationScore = 0.08;
        else if (distance < 50) locationScore = 0.04;
        else if (distance < 100) locationScore = 0.02;
      }

      // 4. Timing Score (10% weight)
      final timeDiff = post1.createdAt.difference(post2.createdAt).inHours.abs();
      double timingScore = 0;
      if (timeDiff < 1) timingScore = 0.10;
      else if (timeDiff < 24) timingScore = 0.08;
      else if (timeDiff < 72) timingScore = 0.05;
      else if (timeDiff < 168) timingScore = 0.02;

      // 5. Keyword Match Score (5% weight)
      final rawKeywordScore = _calculateKeywordMatch(post1, post2);
      final keywordScore = rawKeywordScore * 0.05;

      final totalScore = aiScore + semanticScore + locationScore + timingScore + keywordScore;

      final result = MatchScore(
        totalScore: totalScore.clamp(0.0, 1.0),
        aiCompatibility: compatibility.score,
        semanticSimilarity: rawSemanticSimilarity,
        locationProximity: distance != null ? 1.0 / (1.0 + distance / 10) : 0.0,
        timingAlignment: timingScore / 0.10,
        keywordMatch: rawKeywordScore,
        reasons: compatibility.reasons,
        concerns: compatibility.concerns,
      );

      DebugService.logMatching('calculateMatchScore',
          scores: {
            'total': result.totalScore,
            'ai_raw': compatibility.score,
            'ai_weighted': aiScore,
            'semantic_raw': rawSemanticSimilarity,
            'semantic_weighted': semanticScore,
            'location_weighted': locationScore,
            'timing_weighted': timingScore,
            'keyword_raw': rawKeywordScore,
            'keyword_weighted': keywordScore,
            'time_diff_hours': timeDiff,
            'distance_km': distance,
          },
          durationMs: stopwatch.elapsedMilliseconds);

      return result;
    } catch (e) {
      DebugService.log('MATCHING', '_calculateMatchScore', 'Error calculating match score',
          data: {'error': e.toString()});

      // Return minimal score on error
      return MatchScore(
        totalScore: 0.0,
        aiCompatibility: 0.0,
        semanticSimilarity: 0.0,
        locationProximity: 0.0,
        timingAlignment: 0.0,
        keywordMatch: 0.0,
        reasons: ['Error in calculation'],
        concerns: ['Calculation failed: $e'],
      );
    } finally {
      stopwatch.stop();
    }
  }

  /// Check compatibility between two posts using AI
  Future<CompatibilityAnalysis> _checkCompatibility(AIPostModel post1, AIPostModel post2) async {
    try {
      final intent1 = IntentAnalysis.fromJson(post1.intentAnalysis);
      final intent2 = IntentAnalysis.fromJson(post2.intentAnalysis);

      return await _intentEngine.analyzeCompatibility(
        intent1,
        intent2,
        post1.clarificationAnswers,
        post2.clarificationAnswers,
      );
    } catch (e) {
      DebugService.log('MATCHING', '_checkCompatibility',
          'Error checking compatibility', data: {'error': e.toString()});

      // Return basic compatibility based on keywords as fallback
      final keywordSimilarity = _calculateKeywordMatch(post1, post2);
      return CompatibilityAnalysis(
        score: keywordSimilarity,
        isMatch: keywordSimilarity > 0.3,
        reasons: ['Keyword-based fallback match'],
        concerns: ['AI compatibility check failed'],
      );
    }
  }

  /// Improved cosine similarity calculation with validation
  double _cosineSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length || vec1.isEmpty) {
      DebugService.log('MATCHING', '_cosineSimilarity',
          'Invalid vectors for cosine similarity',
          data: {'vec1_len': vec1.length, 'vec2_len': vec2.length});
      return 0.0;
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
      norm1 += vec1[i] * vec1[i];
      norm2 += vec2[i] * vec2[i];
    }

    if (norm1 == 0.0 || norm2 == 0.0) {
      DebugService.log('MATCHING', '_cosineSimilarity',
          'Zero norm detected', data: {'norm1': norm1, 'norm2': norm2});
      return 0.0;
    }

    final similarity = dotProduct / (sqrt(norm1) * sqrt(norm2));
    return similarity.clamp(-1.0, 1.0);
  }

  /// Calculate distance between coordinates (Haversine formula)
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

  /// Improved keyword matching
  double _calculateKeywordMatch(AIPostModel post1, AIPostModel post2) {
    final keywords1 = post1.searchKeywords.map((k) => k.toLowerCase()).toSet();
    final keywords2 = post2.searchKeywords.map((k) => k.toLowerCase()).toSet();

    if (keywords1.isEmpty || keywords2.isEmpty) return 0.0;

    final intersection = keywords1.intersection(keywords2);
    final union = keywords1.union(keywords2);

    // Jaccard similarity
    final jaccard = intersection.length / union.length;

    // Also consider partial matches
    double partialMatches = 0;
    for (final k1 in keywords1) {
      for (final k2 in keywords2) {
        if (k1.contains(k2) || k2.contains(k1)) {
          partialMatches += 0.5;
        }
      }
    }

    return (jaccard + (partialMatches / keywords1.length.clamp(1, double.infinity))).clamp(0.0, 1.0);
  }

  /// Find and notify about matches
  Future<void> _findAndNotifyMatches(AIPostModel newPost) async {
    try {
      DebugService.log('MATCHING', '_findAndNotifyMatches',
          'Finding matches for new post: ${newPost.id}');

      final matches = await findBestPeople(newPost);

      // FIXED THRESHOLD: Notify about better matches
      for (var match in matches.take(3)) {
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
      DebugService.log('MATCHING', '_findAndNotifyMatches',
          'Error finding matches', data: {'error': e.toString()});
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
      if (matchedUserData == null) {
        DebugService.log('MATCHING', '_notifyMatch',
            'Cannot notify - user profile not found: ${matchedPost.userId}');
        return;
      }

      // Generate match summary using AI
      final summary = await _intentEngine.generateMatchSummary(
        IntentAnalysis.fromJson(userPost.intentAnalysis),
        IntentAnalysis.fromJson(matchedPost.intentAnalysis),
        compatibility,
      );

      // Send push notification if user has FCM token
      if (matchedUserData['fcmToken'] != null) {
        await _notificationService.sendPushNotification(
          recipientToken: matchedUserData['fcmToken']!,
          title: 'Perfect Match Found! 🎯',
          body: summary,
          data: {
            'type': 'ai_match',
            'postId': userPost.id,
            'matchedPostId': matchedPost.id,
            'score': compatibility.score.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      // Store match relationship in database
      await _storeMatch(userPost, matchedPost, compatibility);

      DebugService.log('MATCHING', '_notifyMatch',
          'Match notification sent successfully',
          data: {
            'user_post_id': userPost.id,
            'matched_post_id': matchedPost.id,
            'score': compatibility.score,
          });
    } catch (e) {
      DebugService.log('MATCHING', '_notifyMatch',
          'Error sending match notification', data: {'error': e.toString()});
    }
  }

  /// Store match relationship with proper error handling
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
        'version': '3.0', // Track fixed version
        'metadata': {
          'post1_prompt': post1.originalPrompt,
          'post2_prompt': post2.originalPrompt,
          'matching_algorithm': 'fixed_ai_matching_v3',
        },
      });

      DebugService.logFirestore('CREATE', 'ai_matches',
          data: {
            'score': compatibility.score,
            'match_type': compatibility.matchType,
          });
    } catch (e) {
      DebugService.log('MATCHING', '_storeMatch',
          'Error storing match', data: {'error': e.toString()});
    }
  }

  /// Dispose resources properly
  void dispose() {
    _postListener?.cancel();
    for (var timer in _matchingTimers.values) {
      timer.cancel();
    }
    _matchingTimers.clear();
    _isInitialized = false;

    DebugService.log('MATCHING', 'dispose', 'Fixed matching service disposed');
  }
}

/// All supporting classes remain the same
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