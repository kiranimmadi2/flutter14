import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gemini_service.dart';
import 'dart:convert';

class SequentialClarificationService {
  static final SequentialClarificationService _instance = SequentialClarificationService._internal();
  factory SequentialClarificationService() => _instance;
  SequentialClarificationService._internal();

  final GeminiService _geminiService = GeminiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // AI will determine what questions to ask dynamically

  // Extract entities from user input
  Future<Map<String, dynamic>> extractEntities(String userInput) async {
    try {
      final prompt = '''
Extract specific entities from this user input and categorize the request:
"$userInput"

Return ONLY valid JSON with this structure:
{
  "domain": "product|service|social|job|housing|other",
  "intent_type": "buying|selling|looking_for|offering|hiring|job_seeking|dating|friendship|other",
  "extracted_entities": {
    "product_type": "phone|car|laptop|etc",
    "brand": "specific brand if mentioned",
    "budget_min": number_or_null,
    "budget_max": number_or_null,
    "condition": "new|used|refurbished|any|null",
    "specific_model": "exact model if mentioned",
    "key_features": ["feature1", "feature2"],
    "location": "city/area if mentioned",
    "gender_preference": "male|female|any|null",
    "age_range": "18-25|26-35|etc|null",
    "urgency": "low|medium|high|null",
    "experience_level": "beginner|intermediate|expert|null"
  },
  "clarity_score": 0.0_to_1.0,
  "missing_critical": ["list", "of", "missing", "essential", "info"]
}

Examples:
"looking for motorola phone" → domain: "product", intent_type: "buying", product_type: "phone", brand: "motorola", missing_critical: ["budget", "condition"]
"selling used iPhone 12 for \$300" → domain: "product", intent_type: "selling", product_type: "phone", brand: "iPhone", specific_model: "iPhone 12", budget_max: 300, condition: "used", missing_critical: []
''';

      final response = await _geminiService.generateContent(prompt);
      if (response != null && response.isNotEmpty) {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          return _parseJson(jsonStr);
        }
      }
    } catch (e) {
      debugPrint('Error extracting entities: $e');
    }

    // Fallback basic analysis
    return {
      'domain': 'other',
      'intent_type': 'other',
      'extracted_entities': {},
      'clarity_score': 0.3,
      'missing_critical': ['intent_clarification'],
    };
  }

  // Get the next most important question to ask using AI
  Future<Map<String, dynamic>?> getNextQuestion(
    Map<String, dynamic> extractedData,
    List<String> alreadyAsked,
    Map<String, dynamic> collectedAnswers,
    String originalInput,
  ) async {
    // Don't ask more than 4 questions to avoid fatigue
    if (alreadyAsked.length >= 4) {
      return null;
    }

    print('DEBUG: Getting next AI-generated question');
    print('DEBUG: Original input: $originalInput');
    print('DEBUG: Already asked questions: $alreadyAsked');
    print('DEBUG: Collected answers: $collectedAnswers');

    try {
      final prompt = '''
Analyze this user request and generate the most important clarifying question:

Original Input: "$originalInput"
Domain: ${extractedData['domain']}
Intent: ${extractedData['intent_type']}
Already Extracted: ${extractedData['extracted_entities']}
Previous Questions Asked: $alreadyAsked
Previous Answers: $collectedAnswers

RULES:
1. Generate ONLY ONE question that's most critical for understanding the request
2. Don't ask about information already clearly provided in the original input
3. Don't repeat questions from "Previous Questions Asked"
4. Focus on the most essential missing information for matching
5. Provide 4-6 specific, relevant options
6. Keep it conversational and natural

Return ONLY valid JSON:
{
  "question": "What specific question to ask?",
  "options": ["Option 1", "Option 2", "Option 3", "Option 4", "Option 5"],
  "question_type": "budget|condition|model|features|location|other",
  "importance": 0.0_to_1.0
}

If NO question is needed (all essential info is available), return: {"question": null}
''';

      final response = await _geminiService.generateContent(prompt);
      if (response != null && response.isNotEmpty) {
        final question = _parseQuestionResponse(response);

        // Store the AI-generated question in database
        if (question != null) {
          await _storeQuestionInDatabase(question, originalInput, extractedData);
        }

        return question;
      }
    } catch (e) {
      print('Error generating question: $e');
    }

    return null; // No more questions needed
  }

  // Parse AI response for question generation
  Map<String, dynamic>? _parseQuestionResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = json.decode(jsonStr);

        // Check if AI says no question is needed
        if (parsed['question'] == null) {
          return null;
        }

        // Validate required fields
        if (parsed['question'] != null && parsed['options'] != null) {
          return {
            'type': parsed['question_type'] ?? 'general',
            'question': parsed['question'],
            'options': List<String>.from(parsed['options']),
            'importance': parsed['importance'] ?? 0.8,
          };
        }
      }
    } catch (e) {
      print('Error parsing question response: $e');
    }

    return null;
  }

  // Store AI-generated question in database for analytics and improvement
  Future<void> _storeQuestionInDatabase(
    Map<String, dynamic> question,
    String originalInput,
    Map<String, dynamic> extractedData,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('ai_generated_questions').add({
        'userId': userId,
        'originalInput': originalInput,
        'extractedData': extractedData,
        'generatedQuestion': question,
        'timestamp': FieldValue.serverTimestamp(),
        'questionType': question['type'],
        'importance': question['importance'] ?? 0.8,
      });

      print('DEBUG: Stored AI-generated question in database');
    } catch (e) {
      print('Error storing question in database: $e');
      // Don't throw error - this shouldn't break the user experience
    }
  }


  // Build final consolidated intent from all collected information
  Map<String, dynamic> buildFinalIntent(
    String originalInput,
    Map<String, dynamic> extractedData,
    Map<String, dynamic> collectedAnswers,
  ) {
    final entities = Map<String, dynamic>.from(extractedData['extracted_entities'] ?? {});

    // Merge collected answers into entities
    entities.addAll(collectedAnswers);

    // Generate synthetic description
    final description = _generateSyntheticDescription(originalInput, entities, extractedData);

    return {
      'original_input': originalInput,
      'domain': extractedData['domain'],
      'intent_type': extractedData['intent_type'],
      'entities': entities,
      'synthetic_description': description,
      'final_search_query': description,
    };
  }

  String _generateSyntheticDescription(
    String originalInput,
    Map<String, dynamic> entities,
    Map<String, dynamic> extractedData,
  ) {
    final intentType = (extractedData['intent_type']?.toString() ?? 'looking_for');
    final productType = (entities['product_type']?.toString() ?? 'item');
    final brand = (entities['brand']?.toString() ?? '');
    final condition = (entities['condition']?.toString() ?? '');
    final budgetMax = entities['budget_max'];
    final specificModel = (entities['specific_model']?.toString() ?? '');
    final keyFeatures = (entities['key_features'] as List?)?.cast<String>() ?? <String>[];

    List<String> parts = [];

    // Add intent
    if (intentType == 'buying') {
      parts.add('Looking for');
    } else if (intentType == 'selling') {
      parts.add('Selling');
    } else {
      parts.add('Need');
    }

    // Add condition
    if (condition.isNotEmpty && condition != 'null') {
      parts.add(condition);
    }

    // Add brand and model
    if (brand.isNotEmpty) {
      if (specificModel.isNotEmpty && specificModel != 'Any ${brand} model') {
        parts.add(specificModel);
      } else {
        parts.add('$brand $productType');
      }
    } else {
      parts.add(productType);
    }

    // Add budget
    if (budgetMax != null && budgetMax > 0) {
      parts.add('under \$${budgetMax}');
    }

    // Add key features
    if (keyFeatures.isNotEmpty) {
      final filteredFeatures = keyFeatures.where((f) => f != 'No specific preference').toList();
      if (filteredFeatures.isNotEmpty) {
        parts.add('with ${filteredFeatures.join(' and ')}');
      }
    }

    return parts.join(' ');
  }

  Map<String, dynamic> _parseJson(String jsonStr) {
    try {
      return json.decode(jsonStr);
    } catch (e) {
      debugPrint('JSON parsing failed: $e');
      // Fallback parsing
      return {
        'domain': 'other',
        'intent_type': 'other',
        'extracted_entities': {},
        'clarity_score': 0.3,
        'missing_critical': ['clarification_needed'],
      };
    }
  }
}