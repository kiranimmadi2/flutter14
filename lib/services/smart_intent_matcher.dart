import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'gemini_service.dart';

class SmartIntentMatcher {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GeminiService _geminiService = GeminiService();
  late final GenerativeModel _model;

  SmartIntentMatcher() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: GeminiService.apiKey,
    );
  }

  /// Main function: Understand intent and find matches with minimal questions
  Future<Map<String, dynamic>> matchIntent(String userInput) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Step 1: Understand the user's intent in one shot
      final intent = await _understandIntent(userInput);
      
      // Step 2: Generate complementary intent for matching
      final complementaryIntent = await _generateComplementaryIntent(intent);
      
      // Step 3: Store user's intent with embeddings
      final userIntentId = await _storeIntent(userId, intent);
      
      // Step 4: Find matches using semantic similarity
      final matches = await _findSemanticMatches(complementaryIntent, userId);
      
      return {
        'success': true,
        'userIntent': intent,
        'lookingFor': complementaryIntent,
        'matches': matches,
        'intentId': userIntentId,
      };
    } catch (e) {
      print('Error in smart matching: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Understand user intent without asking questions
  Future<Map<String, dynamic>> _understandIntent(String userInput) async {
    final prompt = '''
    Understand this user's intent in ONE analysis. NO QUESTIONS NEEDED.
    
    User says: "$userInput"
    
    Extract:
    1. action: What they want to do (sell/buy/find/meet/hire/date/exchange/share/etc)
    2. object: What/who they're looking for (item/service/person/skill/etc)
    3. details: Key specifics (price/location/time/preferences)
    4. urgency: how urgent (immediate/flexible/planned)
    5. searchText: Natural description for semantic matching
    
    Return ONLY valid JSON:
    {
      "action": "detected action",
      "object": "main subject",
      "details": {"key": "value"},
      "urgency": "level",
      "searchText": "full natural language description for matching"
    }
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final jsonStr = _extractJson(response.text ?? '{}');
      return json.decode(jsonStr);
    } catch (e) {
      // Fallback: use original input
      return {
        'action': 'find',
        'object': userInput,
        'details': {},
        'urgency': 'flexible',
        'searchText': userInput,
      };
    }
  }

  /// Generate what the complementary person would be looking for
  Future<Map<String, dynamic>> _generateComplementaryIntent(Map<String, dynamic> originalIntent) async {
    final prompt = '''
    Given this person's intent, what would their PERFECT MATCH be looking for?
    Think opposites/complements that complete each other.
    
    Original intent:
    - Action: ${originalIntent['action']}
    - Object: ${originalIntent['object']}
    - Details: ${json.encode(originalIntent['details'])}
    
    Examples:
    - "selling iPhone 13" → matches "buying iPhone 13"
    - "looking for plumber" → matches "plumber available for work"
    - "want to learn guitar" → matches "teaching guitar"
    - "have extra tickets" → matches "need tickets"
    - "seeking roommate" → matches "looking for room"
    
    Return the COMPLEMENTARY intent that would match perfectly.
    
    Return ONLY valid JSON:
    {
      "action": "complementary action",
      "object": "what they need",
      "searchText": "natural language of what the match would say"
    }
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final jsonStr = _extractJson(response.text ?? '{}');
      return json.decode(jsonStr);
    } catch (e) {
      // Smart fallback based on action
      final action = originalIntent['action'] ?? 'find';
      final object = originalIntent['object'] ?? '';
      
      String complementAction = action;
      if (action.contains('sell')) complementAction = 'buy';
      else if (action.contains('buy')) complementAction = 'sell';
      else if (action.contains('teach')) complementAction = 'learn';
      else if (action.contains('learn')) complementAction = 'teach';
      else if (action.contains('offer')) complementAction = 'need';
      else if (action.contains('need')) complementAction = 'offer';
      
      return {
        'action': complementAction,
        'object': object,
        'searchText': '$complementAction $object',
      };
    }
  }

  /// Store intent with embeddings for matching
  Future<String> _storeIntent(String userId, Map<String, dynamic> intent) async {
    // Generate embedding for the search text
    final searchText = intent['searchText'] ?? '${intent['action']} ${intent['object']}';
    final embedding = await _geminiService.generateEmbedding(searchText);
    
    // Get user location
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    
    // Store in Firestore
    final intentDoc = await _firestore.collection('user_intents').add({
      'userId': userId,
      'intent': intent,
      'embedding': embedding,
      'searchText': searchText,
      'city': userData['city'],
      'location': userData['location'],
      'timestamp': FieldValue.serverTimestamp(),
      'active': true,
    });
    
    return intentDoc.id;
  }

  /// Find matches using semantic similarity
  Future<List<Map<String, dynamic>>> _findSemanticMatches(
    Map<String, dynamic> targetIntent,
    String currentUserId,
  ) async {
    try {
      // Generate embedding for what we're looking for
      final searchText = targetIntent['searchText'] ?? '';
      final searchEmbedding = await _geminiService.generateEmbedding(searchText);
      
      // Get user's city for location filtering
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userCity = userDoc.data()?['city'] ?? '';
      
      // Query recent intents (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final intentsQuery = await _firestore
          .collection('user_intents')
          .where('active', isEqualTo: true)
          .where('timestamp', isGreaterThan: thirtyDaysAgo)
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();
      
      // Calculate similarities and filter
      List<Map<String, dynamic>> matches = [];
      
      for (var doc in intentsQuery.docs) {
        final data = doc.data();
        
        // Skip own intents
        if (data['userId'] == currentUserId) continue;
        
        // Calculate semantic similarity
        final storedEmbedding = List<double>.from(data['embedding'] ?? []);
        final similarity = _geminiService.calculateSimilarity(searchEmbedding, storedEmbedding);
        
        // Consider location preference (boost local matches)
        double locationBoost = 0;
        if (userCity.isNotEmpty && data['city'] == userCity) {
          locationBoost = 0.1; // 10% boost for same city
        }
        
        final finalScore = similarity + locationBoost;
        
        // Only include high similarity matches (>0.7)
        if (finalScore > 0.7) {
          // Get user details
          final matchUserDoc = await _firestore
              .collection('users')
              .doc(data['userId'])
              .get();
          
          final matchUser = matchUserDoc.data() ?? {};
          
          matches.add({
            'intentId': doc.id,
            'userId': data['userId'],
            'intent': data['intent'],
            'searchText': data['searchText'],
            'similarity': finalScore,
            'user': {
              'name': matchUser['name'],
              'photoUrl': matchUser['photoUrl'],
              'city': matchUser['city'],
              'verified': matchUser['verified'] ?? false,
            },
            'timestamp': data['timestamp'],
          });
        }
      }
      
      // Sort by similarity score
      matches.sort((a, b) => b['similarity'].compareTo(a['similarity']));
      
      // Return top 20 matches
      return matches.take(20).toList();
    } catch (e) {
      print('Error finding matches: $e');
      return [];
    }
  }

  /// Helper: Extract JSON from Gemini response
  String _extractJson(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) {
        return text.substring(start, end + 1);
      }
      return '{}';
    } catch (e) {
      return '{}';
    }
  }

  /// Quick match without storing (for preview)
  Future<List<String>> quickMatchPreview(String userInput) async {
    try {
      final intent = await _understandIntent(userInput);
      final complementary = await _generateComplementaryIntent(intent);
      
      // Generate sample matches to show what system understands
      final prompt = '''
      Based on this matching:
      User wants: ${intent['searchText']}
      We'll find people who: ${complementary['searchText']}
      
      Generate 3 example matches that would be found:
      Return as JSON array of strings.
      ''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      try {
        final jsonStr = _extractJson(response.text ?? '[]');
        return List<String>.from(json.decode(jsonStr));
      } catch (e) {
        return [
          'People offering ${complementary['object']}',
          'Someone looking to ${complementary['action']} ${complementary['object']}',
          'Match for your ${intent['object']} request',
        ];
      }
    } catch (e) {
      return ['Understanding your request...'];
    }
  }
}