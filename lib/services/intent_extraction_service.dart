import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'gemini_service.dart';

class IntentExtractionService {
  static final IntentExtractionService _instance = IntentExtractionService._internal();
  factory IntentExtractionService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GeminiService _geminiService = GeminiService();
  late final GenerativeModel _model;

  IntentExtractionService._internal() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: GeminiService.apiKey,
    );
  }

  // Extract intent and target_intent from user text
  Future<Map<String, dynamic>> extractIntentAndTarget(String userText) async {
    try {
      final prompt = '''
Analyze this user text and extract the intent and target_intent for matching:
"$userText"

RULES:
1. intent = what the USER wants to do
2. target_intent = the COMPLEMENTARY intent they want to connect with
3. Be smart about context - understand the real meaning
4. Use specific, clear intent names

Examples:
"I want to buy iPhone" → intent: "buy", target_intent: "sell"
"Selling my car" → intent: "sell", target_intent: "buy"
"Lost my dog in Central Park" → intent: "lost", target_intent: "found"
"Found a wallet on Main Street" → intent: "found", target_intent: "lost"
"Looking for guitar lessons" → intent: "learn", target_intent: "teach"
"I can teach piano" → intent: "teach", target_intent: "learn"
"Looking for female hiking buddy" → intent: "looking_for_female", target_intent: "looking_for_male"
"Male seeking female for dating" → intent: "male_seeking_female", target_intent: "female_seeking_male"
"Need a plumber" → intent: "need_service", target_intent: "offer_service"
"I fix plumbing" → intent: "offer_service", target_intent: "need_service"
"Job seeker - software engineer" → intent: "job_seeking", target_intent: "hiring"
"Hiring software engineers" → intent: "hiring", target_intent: "job_seeking"

Return ONLY valid JSON:
{
  "intent": "specific_intent_name",
  "target_intent": "complementary_intent_name",
  "category": "marketplace|social|services|jobs|lost_found|learning|other",
  "description": "clean description of what user wants",
  "confidence": 0.0_to_1.0
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final geminiResponse = response.text ?? '';

      return _parseIntentResponse(geminiResponse, userText);
    } catch (e) {
      print('Error extracting intent: $e');
      return _getFallbackIntent(userText);
    }
  }

  Map<String, dynamic> _parseIntentResponse(String response, String originalText) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = json.decode(jsonStr);

        // Validate required fields
        if (parsed['intent'] != null && parsed['target_intent'] != null) {
          return {
            'intent': parsed['intent'],
            'target_intent': parsed['target_intent'],
            'category': parsed['category'] ?? 'other',
            'description': parsed['description'] ?? originalText,
            'confidence': (parsed['confidence'] ?? 0.8).toDouble(),
          };
        }
      }
    } catch (e) {
      print('Error parsing intent response: $e');
    }

    return _getFallbackIntent(originalText);
  }

  Map<String, dynamic> _getFallbackIntent(String text) {
    final lowerText = text.toLowerCase();

    // Simple fallback logic based on keywords
    if (lowerText.contains('buy') || lowerText.contains('looking for') || lowerText.contains('need')) {
      return {
        'intent': 'buy',
        'target_intent': 'sell',
        'category': 'marketplace',
        'description': text,
        'confidence': 0.6,
      };
    } else if (lowerText.contains('sell') || lowerText.contains('selling')) {
      return {
        'intent': 'sell',
        'target_intent': 'buy',
        'category': 'marketplace',
        'description': text,
        'confidence': 0.6,
      };
    } else if (lowerText.contains('lost')) {
      return {
        'intent': 'lost',
        'target_intent': 'found',
        'category': 'lost_found',
        'description': text,
        'confidence': 0.6,
      };
    } else if (lowerText.contains('found')) {
      return {
        'intent': 'found',
        'target_intent': 'lost',
        'category': 'lost_found',
        'description': text,
        'confidence': 0.6,
      };
    }

    // Default fallback
    return {
      'intent': 'general',
      'target_intent': 'general',
      'category': 'other',
      'description': text,
      'confidence': 0.5,
    };
  }

  // Store user post/query with intent data
  Future<Map<String, dynamic>> storeUserIntent(
    String userText,
    Map<String, dynamic> intentData,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('ERROR: User not authenticated - cannot store intent');
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      // Get user profile for additional context
      DocumentSnapshot userDoc;
      try {
        userDoc = await _firestore.collection('users').doc(userId).get();
      } catch (e) {
        print('ERROR: Failed to get user profile: $e');
        return {
          'success': false,
          'error': 'Failed to get user profile: $e',
        };
      }

      final userProfile = userDoc.data() as Map<String, dynamic>? ?? {};

      // Generate embedding for similarity search
      final embedding = await _generateEmbedding(userText + ' ' + intentData['description']);

      if (embedding.isEmpty) {
        print('ERROR: Cannot store intent without valid embedding');
        return {
          'success': false,
          'error': 'Failed to generate embedding for intent processing',
        };
      }

      // Prepare the document for storage
      final intentDocument = {
        'userId': userId,
        'originalText': userText,
        'intent': intentData['intent'],
        'target_intent': intentData['target_intent'],
        'category': intentData['category'],
        'description': intentData['description'],
        'confidence': intentData['confidence'],
        'embedding': embedding,
        'userLocation': {
          'city': userProfile['city'],
          'latitude': userProfile['latitude'],
          'longitude': userProfile['longitude'],
        },
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30))
        ),
        // Fields for History screen compatibility
        'title': intentData['description'] ?? userText,
        'userRole': intentData['intent']?.toString().toUpperCase() ?? 'USER',
        'embeddingText': userText,
      };

      // Store in Firestore with detailed error handling
      DocumentReference docRef;
      try {
        docRef = await _firestore.collection('user_intents').add(intentDocument);
        print('SUCCESS: Intent stored with ID: ${docRef.id}');
      } catch (e) {
        print('ERROR: Failed to write to Firestore: $e');
        return {
          'success': false,
          'error': 'Failed to store intent in database: $e',
        };
      }

      intentDocument['id'] = docRef.id;

      return {
        'success': true,
        'intent_id': docRef.id,
        'intent_data': intentDocument,
      };
    } catch (e) {
      print('ERROR: Unexpected error storing user intent: $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  // Find matches based on intent filtering + similarity search
  Future<List<Map<String, dynamic>>> findMatches(
    Map<String, dynamic> userIntentData,
  ) async {
    try {
      final userTargetIntent = userIntentData['target_intent'];
      final userEmbedding = List<double>.from(userIntentData['embedding'] ?? []);
      final currentUserId = _auth.currentUser?.uid;

      // Validate required data
      if (userEmbedding.isEmpty || userTargetIntent == null || currentUserId == null) {
        print('DEBUG: Missing required data for matching - embedding: ${userEmbedding.length}, target: $userTargetIntent, userId: $currentUserId');
        return [];
      }

      print('DEBUG: Finding matches for target_intent: $userTargetIntent');

      // Step 1: Filter posts where intent == user's target_intent
      QuerySnapshot query;
      try {
        query = await _firestore
            .collection('user_intents')
            .where('intent', isEqualTo: userTargetIntent)
            .where('status', isEqualTo: 'active')
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .limit(100)
            .get();
      } catch (e) {
        print('ERROR: Firebase query failed: $e');
        return []; // Return empty list on Firebase errors
      }

      print('DEBUG: Found ${query.docs.length} posts with matching intent');

      List<Map<String, dynamic>> matches = [];

      // Step 2: Calculate similarity scores for filtered posts
      for (var doc in query.docs) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);

        // Skip own posts
        if (data['userId'] == currentUserId) continue;

        final matchEmbedding = List<double>.from(data['embedding'] ?? []);

        if (matchEmbedding.isNotEmpty) {
          // Calculate cosine similarity
          final similarity = _calculateCosineSimilarity(userEmbedding, matchEmbedding);

          if (similarity > 0.5) { // Minimum similarity threshold
            data['id'] = doc.id;
            data['similarity'] = similarity;
            matches.add(data);
          }
        }
      }

      // Step 3: Sort by similarity (highest first)
      matches.sort((a, b) => (b['similarity'] ?? 0).compareTo(a['similarity'] ?? 0));

      // Step 4: Attach user profiles for top matches
      final topMatches = matches.take(10).toList();
      for (var match in topMatches) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(match['userId'])
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            match['userProfile'] = userDoc.data();

            // Calculate distance if location data exists
            _addDistanceInfo(match, userIntentData);
          } else {
            print('WARNING: User profile not found for userId: ${match['userId']}');
          }
        } catch (e) {
          print('ERROR: Failed to fetch user profile for ${match['userId']}: $e');
          // Continue with other matches even if one fails
        }
      }

      print('DEBUG: Returning ${topMatches.length} high-similarity matches');
      return topMatches;

    } catch (e) {
      print('Error finding matches: $e');
      return [];
    }
  }

  // Calculate cosine similarity between two embedding vectors
  double _calculateCosineSimilarity(List<double> a, List<double> b) {
    // Validate input vectors
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a.length != b.length) {
      print('WARNING: Embedding vector length mismatch: ${a.length} vs ${b.length}');
      return 0.0;
    }

    try {
      double dotProduct = 0.0;
      double normA = 0.0;
      double normB = 0.0;

      for (int i = 0; i < a.length; i++) {
        final aVal = a[i];
        final bVal = b[i];

        // Check for invalid values
        if (!aVal.isFinite || !bVal.isFinite) {
          print('WARNING: Invalid embedding values detected at index $i');
          return 0.0;
        }

        dotProduct += aVal * bVal;
        normA += aVal * aVal;
        normB += bVal * bVal;
      }

      if (normA == 0.0 || normB == 0.0) return 0.0;

      final similarity = dotProduct / (math.sqrt(normA) * math.sqrt(normB));

      // Ensure result is valid (cosine similarity should be between -1 and 1)
      if (!similarity.isFinite || similarity < -1.0 || similarity > 1.0) {
        print('WARNING: Invalid similarity result: $similarity');
        return 0.0;
      }

      return similarity;
    } catch (e) {
      print('ERROR: Cosine similarity calculation failed: $e');
      return 0.0;
    }
  }

  // Generate embedding using Gemini
  Future<List<double>> _generateEmbedding(String text) async {
    try {
      final embedding = await _geminiService.generateEmbedding(text);
      if (embedding.isEmpty) {
        print('WARNING: Generated embedding is empty for text: $text');
        return [];
      }
      print('SUCCESS: Generated embedding of length ${embedding.length} for text: $text');
      return embedding;
    } catch (e) {
      print('ERROR: Failed to generate embedding for text "$text": $e');
      // DO NOT use random embeddings - return empty list to indicate failure
      return [];
    }
  }

  // Add distance information if location data is available
  void _addDistanceInfo(Map<String, dynamic> match, Map<String, dynamic> userIntentData) {
    try {
      final userLat = userIntentData['userLocation']?['latitude']?.toDouble();
      final userLon = userIntentData['userLocation']?['longitude']?.toDouble();
      final matchLat = match['userLocation']?['latitude']?.toDouble();
      final matchLon = match['userLocation']?['longitude']?.toDouble();

      // Validate all coordinates are present and valid
      if (userLat != null && userLon != null && matchLat != null && matchLon != null &&
          userLat >= -90 && userLat <= 90 && userLon >= -180 && userLon <= 180 &&
          matchLat >= -90 && matchLat <= 90 && matchLon >= -180 && matchLon <= 180) {
        final distance = _calculateDistance(userLat, userLon, matchLat, matchLon);
        if (distance >= 0 && distance < 20000) { // Sanity check: max ~20000km (half earth circumference)
          match['distance'] = distance;
        }
      }
    } catch (e) {
      print('WARNING: Distance calculation failed: $e');
      // Continue without distance info
    }
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  // Process user input: extract intent + store + find matches
  Future<Map<String, dynamic>> processUserInput(String userText) async {
    print('🚀 PROCESSING USER INPUT: "$userText"');

    try {
      // Step 1: Extract intent and target_intent
      print('📝 Step 1: Extracting intent from user text...');
      final intentData = await extractIntentAndTarget(userText);
      print('✅ Step 1 Complete: Intent extracted - ${intentData['intent']} → ${intentData['target_intent']}');

      // Step 2: Store the user intent
      print('💾 Step 2: Storing user intent in Firebase...');
      final storeResult = await storeUserIntent(userText, intentData);

      if (!storeResult['success']) {
        print('❌ Step 2 FAILED: ${storeResult['error']}');
        return storeResult;
      }
      print('✅ Step 2 Complete: Intent stored with ID ${storeResult['intent_id']}');

      // Step 3: Find matches
      print('🔍 Step 3: Finding matches for stored intent...');
      final matches = await findMatches(storeResult['intent_data']);
      print('✅ Step 3 Complete: Found ${matches.length} matches');

      print('🎉 PROCESSING COMPLETE: User input successfully processed');
      return {
        'success': true,
        'intent': storeResult['intent_data'],
        'matches': matches,
        'intent_extracted': intentData,
      };

    } catch (e) {
      print('💥 PROCESSING FAILED: Unexpected error - $e');
      return {
        'success': false,
        'error': 'Processing failed: $e',
      };
    }
  }
}