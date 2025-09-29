import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:math';
import '../models/post_model.dart';

class VectorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GenerativeModel _embeddingModel;
  
  static final VectorService _instance = VectorService._internal();
  factory VectorService() => _instance;
  
  // Using the existing API key from GeminiService
  static const String _apiKey = 'AIzaSyDn_3ra-isJdNy5m7-CzrqpuSv_r8Jok5o';
  
  VectorService._internal() {
    _embeddingModel = GenerativeModel(
      model: 'text-embedding-004',
      apiKey: _apiKey,
    );
  }

  // Generate embedding for text
  Future<List<double>> generateEmbedding(String text) async {
    try {
      // Clean and prepare text
      final cleanedText = _cleanText(text);
      if (cleanedText.isEmpty) {
        return _generateRandomEmbedding();
      }
      
      final content = Content.text(cleanedText);
      final response = await _embeddingModel.embedContent(content);
      return response.embedding.values;
    } catch (e) {
      print('Error generating embedding: $e');
      // Fallback to deterministic embedding based on text
      return _generateDeterministicEmbedding(text);
    }
  }

  // Generate embeddings for multiple texts in batch
  Future<List<List<double>>> generateBatchEmbeddings(List<String> texts) async {
    try {
      final embeddings = <List<double>>[];
      
      // Process in batches of 10 for efficiency
      for (int i = 0; i < texts.length; i += 10) {
        final batch = texts.skip(i).take(10).toList();
        final batchEmbeddings = await Future.wait(
          batch.map((text) => generateEmbedding(text))
        );
        embeddings.addAll(batchEmbeddings);
      }
      
      return embeddings;
    } catch (e) {
      print('Error generating batch embeddings: $e');
      return texts.map((text) => _generateDeterministicEmbedding(text)).toList();
    }
  }

  // Calculate cosine similarity between two embeddings
  double calculateCosineSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.isEmpty || embedding2.isEmpty) return 0.0;
    if (embedding1.length != embedding2.length) {
      print('Warning: Embedding dimensions mismatch');
      return 0.0;
    }
    
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }
    
    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    
    final similarity = dotProduct / (sqrt(norm1) * sqrt(norm2));
    // Ensure similarity is between -1 and 1
    return similarity.clamp(-1.0, 1.0);
  }

  // Find similar posts using vector search
  Future<List<Map<String, dynamic>>> findSimilarPosts({
    required List<double> queryEmbedding,
    PostCategory? category,
    int limit = 20,
    double minSimilarity = 0.5,
    String? excludePostId,
  }) async {
    try {
      // Get candidate posts from Firestore
      Query<Map<String, dynamic>> query = _firestore
          .collection('posts')
          .where('isActive', isEqualTo: true);
      
      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }
      
      // Get more candidates than needed for filtering
      final snapshot = await query.limit(limit * 5).get();
      
      final results = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        // Skip excluded post
        if (excludePostId != null && doc.id == excludePostId) continue;
        
        final data = doc.data();
        final embedding = _parseEmbedding(data['embedding']);
        
        if (embedding.isEmpty) continue;
        
        final similarity = calculateCosineSimilarity(queryEmbedding, embedding);
        
        if (similarity >= minSimilarity) {
          results.add({
            'id': doc.id,
            'data': data,
            'similarity': similarity,
          });
        }
      }
      
      // Sort by similarity (highest first)
      results.sort((a, b) => b['similarity'].compareTo(a['similarity']));
      
      // Return top results
      return results.take(limit).toList();
    } catch (e) {
      print('Error finding similar posts: $e');
      return [];
    }
  }

  // Store embedding in Firestore
  Future<void> storeEmbedding({
    required String documentId,
    required String collection,
    required List<double> embedding,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final data = {
        'embedding': embedding,
        'embeddingDimension': embedding.length,
        'embeddingModel': 'text-embedding-004',
        'updatedAt': FieldValue.serverTimestamp(),
        if (metadata != null) ...metadata,
      };
      
      await _firestore
          .collection(collection)
          .doc(documentId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error storing embedding: $e');
      throw e;
    }
  }

  // Create text representation for embedding
  String createTextForEmbedding({
    required String title,
    required String description,
    String? location,
    PostCategory? category,
    List<String>? keywords,
  }) {
    final parts = <String>[];
    
    // Add main content
    if (title.isNotEmpty) parts.add(title);
    if (description.isNotEmpty) parts.add(description);
    
    // Add location if available
    if (location != null && location.isNotEmpty) {
      parts.add('Location: $location');
    }
    
    // Add category
    if (category != null) {
      parts.add('Category: ${category.toString().split('.').last}');
    }
    
    // Add keywords
    if (keywords != null && keywords.isNotEmpty) {
      parts.add('Keywords: ${keywords.join(', ')}');
    }
    
    return parts.join(' ');
  }

  // Extract keywords from text using simple heuristics
  List<String> extractKeywords(String text) {
    // Remove common stop words
    final stopWords = {
      'the', 'is', 'at', 'which', 'on', 'a', 'an', 'as', 'are', 'was',
      'were', 'been', 'be', 'have', 'has', 'had', 'do', 'does', 'did',
      'will', 'would', 'could', 'should', 'may', 'might', 'must', 'can',
      'could', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'what',
      'where', 'when', 'how', 'if', 'or', 'and', 'but', 'for', 'with',
      'to', 'from', 'of', 'in', 'by', 'up', 'down', 'out'
    };
    
    // Split and clean text
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toList();
    
    // Count word frequency
    final wordCount = <String, int>{};
    for (final word in words) {
      wordCount[word] = (wordCount[word] ?? 0) + 1;
    }
    
    // Sort by frequency and return top keywords
    final sortedWords = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedWords
        .take(10)
        .map((entry) => entry.key)
        .toList();
  }

  // Enhance search query with synonyms and related terms
  Future<String> enhanceQuery(String query, {PostCategory? category}) async {
    // For now, use simple enhancement
    // You can integrate with Gemini for better enhancement
    final keywords = extractKeywords(query);
    
    if (category != null) {
      keywords.add(category.toString().split('.').last.toLowerCase());
    }
    
    return keywords.join(' ');
  }

  // Helper methods
  String _cleanText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .substring(0, text.length > 1000 ? 1000 : text.length);
  }

  List<double> _parseEmbedding(dynamic embeddingData) {
    if (embeddingData == null) return [];
    
    if (embeddingData is List) {
      try {
        return List<double>.from(embeddingData.map((e) => e.toDouble()));
      } catch (e) {
        print('Error parsing embedding: $e');
        return [];
      }
    }
    
    return [];
  }

  List<double> _generateRandomEmbedding() {
    final random = Random();
    return List.generate(768, (_) => random.nextDouble() * 2 - 1);
  }

  List<double> _generateDeterministicEmbedding(String text) {
    // Create a deterministic embedding based on text hash
    final random = Random(text.hashCode);
    return List.generate(768, (_) => random.nextDouble() * 2 - 1);
  }

  // Batch update existing posts with embeddings
  Future<void> updateExistingPostsWithEmbeddings() async {
    try {
      final batch = _firestore.batch();
      int batchCount = 0;
      
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('embedding', isNull: true)
          .limit(50)
          .get();
      
      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        final text = createTextForEmbedding(
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          location: data['location'],
          category: data['category'] != null 
              ? PostCategory.values.firstWhere(
                  (cat) => cat.toString().split('.').last == data['category'],
                  orElse: () => PostCategory.other,
                )
              : null,
        );
        
        final embedding = await generateEmbedding(text);
        
        batch.update(doc.reference, {
          'embedding': embedding,
          'embeddingUpdatedAt': FieldValue.serverTimestamp(),
        });
        
        batchCount++;
        
        // Commit batch every 10 documents
        if (batchCount >= 10) {
          await batch.commit();
          batchCount = 0;
        }
      }
      
      // Commit remaining updates
      if (batchCount > 0) {
        await batch.commit();
      }
      
      print('Updated ${postsSnapshot.docs.length} posts with embeddings');
    } catch (e) {
      print('Error updating posts with embeddings: $e');
    }
  }
}