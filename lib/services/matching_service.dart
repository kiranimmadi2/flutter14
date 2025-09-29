import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/post_model.dart';
import '../models/user_profile.dart';
import 'gemini_service.dart';
import 'vector_service.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GeminiService _geminiService = GeminiService();
  final VectorService _vectorService = VectorService();
  
  static final MatchingService _instance = MatchingService._internal();
  factory MatchingService() => _instance;
  MatchingService._internal();

  Future<String> createPost({
    required String title,
    required String description,
    required PostCategory category,
    List<String>? images,
    Map<String, dynamic>? metadata,
    String? location,
    double? latitude,
    double? longitude,
    double? price,
    String? currency,
    DateTime? expiresAt,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Ensure user profile exists
      await _ensureUserProfile(user);

      // Create comprehensive text for embedding
      final fullText = _vectorService.createTextForEmbedding(
        title: title,
        description: description,
        location: location,
        category: category,
      );
      
      // Generate embedding and extract keywords
      final embedding = await _vectorService.generateEmbedding(fullText);
      final keywords = _vectorService.extractKeywords('$title $description');

      final postData = {
        'userId': user.uid,
        'title': title,
        'description': description,
        'category': category.toString().split('.').last,
        'images': images ?? [],
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'embedding': embedding,
        'keywords': keywords,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'price': price,
        'currency': currency,
        'isActive': true,
        'viewCount': 0,
        'matchedUserIds': [],
      };

      final docRef = await _firestore.collection('posts').add(postData);
      
      // Store embedding with vector service for better management
      await _vectorService.storeEmbedding(
        documentId: docRef.id,
        collection: 'embeddings',
        embedding: embedding,
        metadata: {
          'postId': docRef.id,
          'category': category.toString().split('.').last,
          'keywords': keywords,
        },
      );

      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  Future<void> _ensureUserProfile(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
        });
      } else {
        await _firestore.collection('users').doc(user.uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
        });
      }
    } catch (e) {
      print('Error ensuring user profile: $e');
    }
  }

  Future<List<PostModel>> searchPosts({
    required String query,
    PostCategory? category,
    double? maxDistance,
    double? userLat,
    double? userLon,
    double similarityThreshold = 0.7,
  }) async {
    try {
      // If query is empty or wildcard, just get recent posts
      if (query.isEmpty || query == '*') {
        Query<Map<String, dynamic>> postsQuery = _firestore.collection('posts')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true);
        
        if (category != null) {
          postsQuery = postsQuery.where('category', isEqualTo: category.toString().split('.').last);
        }
        
        final querySnapshot = await postsQuery.limit(20).get();
        List<PostModel> posts = querySnapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
        
        // Sort by location if user location is available
        if (userLat != null && userLon != null) {
          posts = _sortPostsByLocation(posts, userLat, userLon, maxDistance);
        }
        
        return posts;
      }
      
      // Enhance query and generate embedding
      final enhancedQuery = await _vectorService.enhanceQuery(
        query,
        category: category,
      );
      
      final queryEmbedding = await _vectorService.generateEmbedding(enhancedQuery);
      
      Query<Map<String, dynamic>> postsQuery = _firestore.collection('posts')
          .where('isActive', isEqualTo: true);
      
      if (category != null) {
        postsQuery = postsQuery.where('category', isEqualTo: category.toString().split('.').last);
      }
      
      final querySnapshot = await postsQuery.limit(100).get();
      
      List<PostModel> posts = [];
      for (var doc in querySnapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        
        if (maxDistance != null && userLat != null && userLon != null) {
          if (post.latitude != null && post.longitude != null) {
            final distance = _calculateDistance(
              userLat, userLon, post.latitude!, post.longitude!
            );
            if (distance > maxDistance) continue;
          }
        }
        
        if (post.embedding != null && post.embedding!.isNotEmpty) {
          final similarity = _vectorService.calculateCosineSimilarity(
            queryEmbedding, post.embedding!
          );
          
          if (similarity >= similarityThreshold) {
            // Create a new post with similarity score
            final postWithScore = PostModel(
              id: post.id,
              userId: post.userId,
              title: post.title,
              description: post.description,
              category: post.category,
              images: post.images,
              metadata: post.metadata,
              createdAt: post.createdAt,
              expiresAt: post.expiresAt,
              isActive: post.isActive,
              embedding: post.embedding,
              keywords: post.keywords,
              similarityScore: similarity,
              location: post.location,
              latitude: post.latitude,
              longitude: post.longitude,
              price: post.price,
              currency: post.currency,
              viewCount: post.viewCount,
              matchedUserIds: post.matchedUserIds,
            );
            posts.add(postWithScore);
          }
        } else {
          // Fallback: Include posts based on keyword matching
          final queryKeywords = _vectorService.extractKeywords(query);
          bool hasKeywordMatch = false;
          
          if (post.keywords != null && post.keywords!.isNotEmpty) {
            for (final keyword in queryKeywords) {
              if (post.keywords!.any((k) => k.contains(keyword))) {
                hasKeywordMatch = true;
                break;
              }
            }
          }
          
          // Also check title and description
          if (!hasKeywordMatch) {
            final lowerQuery = query.toLowerCase();
            hasKeywordMatch = post.title.toLowerCase().contains(lowerQuery) ||
                post.description.toLowerCase().contains(lowerQuery);
          }
          
          if (hasKeywordMatch) {
            posts.add(post);
          }
        }
      }
      
      // Sort by location first if available, then by similarity
      if (userLat != null && userLon != null) {
        posts = _sortPostsByLocation(posts, userLat, userLon, maxDistance);
      } else {
        // Sort by similarity score if available, otherwise by relevance
        posts.sort((a, b) {
          // If both have similarity scores, sort by score
          if (a.similarityScore != null && b.similarityScore != null) {
            return b.similarityScore!.compareTo(a.similarityScore!);
          }
          
          // If one has score and other doesn't, prioritize the one with score
          if (a.similarityScore != null) return -1;
          if (b.similarityScore != null) return 1;
          
          // Otherwise sort by creation date
          return b.createdAt.compareTo(a.createdAt);
        });
      }
      
      return posts.take(20).toList();
    } catch (e) {
      print('Error searching posts: $e');
      // Return empty list instead of throwing
      return [];
    }
  }

  Future<List<PostModel>> findMatches(String postId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) throw Exception('Post not found');
      
      final post = PostModel.fromFirestore(postDoc);
      if (post.embedding == null) throw Exception('Post has no embedding');
      
      Query<Map<String, dynamic>> query = _firestore.collection('posts')
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: post.category.toString().split('.').last)
          .where(FieldPath.documentId, isNotEqualTo: postId);
      
      final querySnapshot = await query.limit(50).get();
      
      List<PostModel> matches = [];
      for (var doc in querySnapshot.docs) {
        final otherPost = PostModel.fromFirestore(doc);
        
        if (otherPost.embedding != null) {
          final similarity = _vectorService.calculateCosineSimilarity(
            post.embedding!, otherPost.embedding!
          );
          
          if (similarity >= 0.75) {
            // Create match with similarity score
            final matchWithScore = PostModel(
              id: otherPost.id,
              userId: otherPost.userId,
              title: otherPost.title,
              description: otherPost.description,
              category: otherPost.category,
              images: otherPost.images,
              metadata: otherPost.metadata,
              createdAt: otherPost.createdAt,
              expiresAt: otherPost.expiresAt,
              isActive: otherPost.isActive,
              embedding: otherPost.embedding,
              keywords: otherPost.keywords,
              similarityScore: similarity,
              location: otherPost.location,
              latitude: otherPost.latitude,
              longitude: otherPost.longitude,
              price: otherPost.price,
              currency: otherPost.currency,
              viewCount: otherPost.viewCount,
              matchedUserIds: otherPost.matchedUserIds,
            );
            matches.add(matchWithScore);
          }
        }
      }
      
      // Sort matches by similarity score
      matches.sort((a, b) {
        if (a.similarityScore != null && b.similarityScore != null) {
          return b.similarityScore!.compareTo(a.similarityScore!);
        }
        return 0;
      });
      
      return matches.take(10).toList();
    } catch (e) {
      throw Exception('Failed to find matches: $e');
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updatePostView(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error updating view count: $e');
    }
  }

  List<PostModel> _sortPostsByLocation(List<PostModel> posts, double userLat, double userLon, double? maxDistance) {
    // Calculate distance for each post and create a list with distances
    List<Map<String, dynamic>> postsWithDistance = [];
    
    for (var post in posts) {
      double? distance;
      if (post.latitude != null && post.longitude != null) {
        distance = _calculateDistance(userLat, userLon, post.latitude!, post.longitude!);
        
        // Skip posts beyond max distance if specified
        if (maxDistance != null && distance > maxDistance) {
          continue;
        }
      }
      
      postsWithDistance.add({
        'post': post,
        'distance': distance,
      });
    }
    
    // Sort by distance (nearest first), with null distances (no location) at the end
    postsWithDistance.sort((a, b) {
      final distA = a['distance'] as double?;
      final distB = b['distance'] as double?;
      
      if (distA == null && distB == null) {
        // Both have no location, sort by similarity or date
        final postA = a['post'] as PostModel;
        final postB = b['post'] as PostModel;
        
        if (postA.similarityScore != null && postB.similarityScore != null) {
          return postB.similarityScore!.compareTo(postA.similarityScore!);
        }
        return postB.createdAt.compareTo(postA.createdAt);
      }
      
      if (distA == null) return 1; // Put posts without location at the end
      if (distB == null) return -1;
      
      // Sort by distance
      return distA.compareTo(distB);
    });
    
    // Extract and return sorted posts
    return postsWithDistance.map((item) => item['post'] as PostModel).toList();
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.14159265359 / 180);
  }

  // New method to perform vector similarity search
  Future<List<PostModel>> vectorSearch({
    required String query,
    PostCategory? category,
    int limit = 20,
    double minSimilarity = 0.6,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      
      // Generate query embedding
      final queryText = _vectorService.createTextForEmbedding(
        title: query,
        description: query,
        category: category,
      );
      final queryEmbedding = await _vectorService.generateEmbedding(queryText);
      
      // Find similar posts using vector service
      final similarPosts = await _vectorService.findSimilarPosts(
        queryEmbedding: queryEmbedding,
        category: category,
        limit: limit,
        minSimilarity: minSimilarity,
        excludePostId: null,
      );
      
      // Convert to PostModel objects
      final posts = <PostModel>[];
      for (final result in similarPosts) {
        final data = result['data'] as Map<String, dynamic>;
        final similarity = result['similarity'] as double;
        
        posts.add(PostModel(
          id: result['id'] as String,
          userId: data['userId'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          category: PostCategory.values.firstWhere(
            (e) => e.toString().split('.').last == data['category'],
            orElse: () => PostCategory.other,
          ),
          images: data['images'] != null ? List<String>.from(data['images']) : null,
          metadata: data['metadata'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          expiresAt: data['expiresAt'] != null 
              ? (data['expiresAt'] as Timestamp).toDate() 
              : null,
          isActive: data['isActive'] ?? true,
          embedding: data['embedding'] != null 
              ? List<double>.from(data['embedding']) 
              : null,
          keywords: data['keywords'] != null
              ? List<String>.from(data['keywords'])
              : null,
          similarityScore: similarity,
          location: data['location'],
          latitude: data['latitude']?.toDouble(),
          longitude: data['longitude']?.toDouble(),
          price: data['price']?.toDouble(),
          currency: data['currency'],
          viewCount: data['viewCount'] ?? 0,
          matchedUserIds: data['matchedUserIds'] != null 
              ? List<String>.from(data['matchedUserIds']) 
              : [],
        ));
      }
      
      return posts;
    } catch (e) {
      print('Error in vector search: $e');
      return [];
    }
  }
}