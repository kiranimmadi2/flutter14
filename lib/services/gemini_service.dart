import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:math';
import '../models/post_model.dart';
import '../utils/api_error_handler.dart';

class GeminiService {
  static const String apiKey = 'AIzaSyCSShfO46TT8DnYTGKzJ_-M4uQVGPlhscA';
  late final GenerativeModel _model;
  late final GenerativeModel _embeddingModel;
  
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  
  GeminiService._internal() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
    
    _embeddingModel = GenerativeModel(
      model: 'text-embedding-004',
      apiKey: apiKey,
    );
  }

  Future<List<double>> generateEmbedding(String text) async {
    return await ApiErrorHandler.handleApiCall(
      () async {
        final content = Content.text(text);
        final response = await _embeddingModel.embedContent(content);
        return response.embedding.values;
      },
      fallback: () => _generateFallbackEmbedding(text),
      onError: (errorType) {
        if (errorType == ApiErrorType.quotaExceeded) {
          print('⚠️ Gemini API quota exceeded. Using fallback embedding.');
        }
      },
    ) ?? _generateFallbackEmbedding(text);
  }

  List<double> _generateFallbackEmbedding(String text) {
    final random = Random(text.hashCode);
    return List.generate(768, (_) => random.nextDouble() * 2 - 1);
  }

  double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
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
    
    if (norm1 == 0.0 || norm2 == 0.0) {
      return 0.0;
    }
    
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  Future<String?> generateContent(String prompt) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      return response.text;
    } catch (e) {
      print('Error generating content: $e');
      return null;
    }
  }

  Future<List<String>> extractKeywords(String text) async {
    return await ApiErrorHandler.handleApiCall(
      () async {
        final prompt = '''
        Extract the most important keywords from this text for matching purposes.
        Return only a comma-separated list of keywords, nothing else.
        Text: "$text"
        ''';
        
        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content);
        
        if (response.text != null) {
          return response.text!
              .split(',')
              .map((keyword) => keyword.trim().toLowerCase())
              .where((keyword) => keyword.isNotEmpty)
              .toList();
        }
        return _getFallbackKeywords(text);
      },
      fallback: () => _getFallbackKeywords(text),
    ) ?? _getFallbackKeywords(text);
  }
  
  List<String> _getFallbackKeywords(String text) {
    return text.toLowerCase().split(' ')
        .where((word) => word.length > 3)
        .take(5)
        .toList();
  }

  Future<String> enhanceSearchQuery(String query, PostCategory category) async {
    return await ApiErrorHandler.handleApiCall(
      () async {
        final prompt = '''
        Enhance this search query for better matching in the ${category.toString().split('.').last} category.
        Original query: "$query"
        Return only the enhanced query text, nothing else.
        ''';
        
        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content);
        
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
        return query;
      },
      fallback: () => query,
    ) ?? query;
  }
}