import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/user_profile.dart';
import 'profile_service.dart';
import 'location_service.dart';
import 'gemini_service.dart';
import 'notification_service.dart';

class EnhancedMatchingService {
  static final EnhancedMatchingService _instance = EnhancedMatchingService._internal();
  factory EnhancedMatchingService() => _instance;
  EnhancedMatchingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProfileService _profileService = ProfileService();
  final LocationService _locationService = LocationService();
  final GeminiService _geminiService = GeminiService();
  final NotificationService _notificationService = NotificationService();

  // Match posts based on enhanced criteria
  Future<List<PostModel>> findMatches(PostModel userPost) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Start with basic query
      Query query = _firestore.collection('posts')
          .where('userId', isNotEqualTo: currentUser.uid)
          .where('isActive', isEqualTo: true);

      // Add category filter
      query = query.where('category', isEqualTo: userPost.category.toString().split('.').last);

      final snapshot = await query.get();
      
      List<PostModel> matches = [];
      
      for (var doc in snapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        
        // Calculate match score
        final matchScore = await _calculateMatchScore(userPost, post);
        
        if (matchScore > 0.5) {
          matches.add(post);
        }
      }
      
      // Sort by match score
      matches.sort((a, b) {
        final scoreA = a.similarityScore ?? 0;
        final scoreB = b.similarityScore ?? 0;
        return scoreB.compareTo(scoreA);
      });
      
      return matches.take(20).toList();
    } catch (e) {
      debugPrint('Error finding matches: $e');
      return [];
    }
  }

  Future<double> _calculateMatchScore(PostModel userPost, PostModel otherPost) async {
    double score = 0.0;
    int factors = 0;

    // 1. Intent matching (highest weight)
    if (userPost.intent != null && otherPost.intent != null) {
      if (userPost.matchesIntent(otherPost.intent!)) {
        score += 0.4;
      } else {
        // Non-matching intents reduce score significantly
        return 0.0;
      }
    }
    factors++;

    // 2. Price matching
    if (userPost.matchesPrice(otherPost)) {
      score += 0.2;
    } else if (userPost.price != null || otherPost.price != null) {
      // If price doesn't match and it's specified, reduce score
      score -= 0.1;
    }
    factors++;

    // 3. Location proximity
    if (userPost.latitude != null && userPost.longitude != null &&
        otherPost.latitude != null && otherPost.longitude != null) {
      final distance = _calculateDistance(
        userPost.latitude!,
        userPost.longitude!,
        otherPost.latitude!,
        otherPost.longitude!,
      );
      
      // Score based on distance (closer = higher score)
      if (distance < 5) {
        score += 0.2;
      } else if (distance < 10) {
        score += 0.15;
      } else if (distance < 20) {
        score += 0.1;
      } else if (distance < 50) {
        score += 0.05;
      }
    }
    factors++;

    // 4. Semantic similarity using embeddings
    if (userPost.embedding != null && otherPost.embedding != null) {
      final similarity = _calculateCosineSimilarity(
        userPost.embedding!,
        otherPost.embedding!,
      );
      score += similarity * 0.3;
    } else {
      // Use keyword matching as fallback
      final keywordScore = _calculateKeywordMatch(userPost, otherPost);
      score += keywordScore * 0.2;
    }
    factors++;

    // 5. Additional criteria for specific categories
    if (userPost.category == PostCategory.dating || 
        userPost.category == PostCategory.friendship) {
      // Check gender preference
      if (userPost.gender != null && otherPost.gender != null) {
        if (_matchesGenderPreference(userPost, otherPost)) {
          score += 0.1;
        } else {
          score -= 0.2;
        }
      }
      factors++;
    }

    // 6. Condition matching for marketplace
    if (userPost.category == PostCategory.marketplace) {
      if (userPost.condition != null && otherPost.condition != null) {
        if (userPost.condition == otherPost.condition) {
          score += 0.05;
        }
      }
      if (userPost.brand != null && otherPost.brand != null) {
        if (userPost.brand!.toLowerCase() == otherPost.brand!.toLowerCase()) {
          score += 0.05;
        }
      }
      factors++;
    }

    // Normalize score
    return (score / factors).clamp(0.0, 1.0);
  }

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

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  double _calculateCosineSimilarity(List<double> vec1, List<double> vec2) {
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

  double _calculateKeywordMatch(PostModel post1, PostModel post2) {
    if (post1.keywords == null || post2.keywords == null) {
      // Fallback to title/description matching
      return _calculateTextSimilarity(
        '${post1.title} ${post1.description}',
        '${post2.title} ${post2.description}',
      );
    }
    
    final set1 = post1.keywords!.toSet();
    final set2 = post2.keywords!.toSet();
    
    if (set1.isEmpty || set2.isEmpty) return 0.0;
    
    final intersection = set1.intersection(set2);
    final union = set1.union(set2);
    
    return intersection.length / union.length;
  }

  double _calculateTextSimilarity(String text1, String text2) {
    final words1 = text1.toLowerCase().split(RegExp(r'\s+'));
    final words2 = text2.toLowerCase().split(RegExp(r'\s+'));
    
    final set1 = words1.toSet();
    final set2 = words2.toSet();
    
    if (set1.isEmpty || set2.isEmpty) return 0.0;
    
    final intersection = set1.intersection(set2);
    final union = set1.union(set2);
    
    return intersection.length / union.length;
  }

  bool _matchesGenderPreference(PostModel post1, PostModel post2) {
    // Implement gender matching logic
    if (post1.gender == 'any' || post2.gender == 'any') return true;
    
    // For dating/friendship, check if preferences align
    if (post1.clarificationAnswers != null && post2.clarificationAnswers != null) {
      final pref1 = post1.clarificationAnswers!['genderPreference'];
      final pref2 = post2.clarificationAnswers!['genderPreference'];
      
      if (pref1 == 'any' || pref2 == 'any') return true;
      
      // Check if they match each other's preferences
      return (pref1 == post2.gender && pref2 == post1.gender);
    }
    
    return true;
  }

  // Real-time matching for new posts
  Future<void> processNewPost(PostModel post) async {
    try {
      // Find immediate matches
      final matches = await findMatches(post);
      
      // Send notifications for high-quality matches
      for (var match in matches.take(5)) {
        if (match.similarityScore != null && match.similarityScore! > 0.8) {
          await _sendMatchNotification(post, match);
        }
      }
      
      // Store match relationships
      await _storeMatches(post, matches);
    } catch (e) {
      debugPrint('Error processing new post: $e');
    }
  }

  Future<void> _sendMatchNotification(PostModel userPost, PostModel matchedPost) async {
    try {
      final matchedUser = await _profileService.getUserProfile(matchedPost.userId);
      if (matchedUser == null || matchedUser.fcmToken == null) return;
      
      await _notificationService.sendNotification(
        token: matchedUser.fcmToken!,
        title: 'New Match Found!',
        body: 'Someone posted something that matches your "${matchedPost.title}"',
        data: {
          'type': 'match',
          'postId': userPost.id,
          'matchedPostId': matchedPost.id,
        },
      );
    } catch (e) {
      debugPrint('Error sending match notification: $e');
    }
  }

  Future<void> _storeMatches(PostModel post, List<PostModel> matches) async {
    try {
      final batch = _firestore.batch();
      
      // Store match relationships
      for (var match in matches) {
        final matchDoc = _firestore.collection('matches').doc();
        batch.set(matchDoc, {
          'post1Id': post.id,
          'post2Id': match.id,
          'user1Id': post.userId,
          'user2Id': match.userId,
          'matchScore': match.similarityScore ?? 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Update post with matched IDs
      final matchedIds = matches.map((m) => m.userId).toList();
      batch.update(_firestore.collection('posts').doc(post.id), {
        'matchedUserIds': FieldValue.arrayUnion(matchedIds),
      });
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error storing matches: $e');
    }
  }

  // Get match history for a user
  Future<List<Map<String, dynamic>>> getMatchHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final snapshot2 = await _firestore
          .collection('matches')
          .where('user2Id', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final allMatches = [...snapshot.docs, ...snapshot2.docs];
      
      // Sort by timestamp and remove duplicates
      allMatches.sort((a, b) {
        final timeA = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final timeB = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return timeB.compareTo(timeA);
      });
      
      return allMatches.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting match history: $e');
      return [];
    }
  }
}