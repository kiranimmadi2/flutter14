import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

/// Comprehensive debugging service for the matching system
class DebugService {
  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal();

  static const bool enableDetailedLogs = true;
  static const bool logToFirestore = false; // Set to true in production for remote debugging

  /// Log with structured format for easy debugging
  static void log(String component, String function, String message, {Map<String, dynamic>? data}) {
    if (!enableDetailedLogs) return;

    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[SUPPER-$component][$function] $message';

    if (kDebugMode) {
      debugPrint('🔍 $timestamp: $logEntry');
      if (data != null && data.isNotEmpty) {
        debugPrint('   Data: ${jsonEncode(data)}');
      }
    }

    if (logToFirestore) {
      _logToFirestore(component, function, message, data);
    }
  }

  /// Log API calls with request and response details
  static void logApiCall(String api, String endpoint, {
    Map<String, dynamic>? request,
    Map<String, dynamic>? response,
    String? error,
    int? durationMs,
  }) {
    final logData = <String, dynamic>{};
    if (request != null) logData['request'] = request;
    if (response != null) logData['response'] = response;
    if (error != null) logData['error'] = error;
    if (durationMs != null) logData['duration_ms'] = durationMs;

    log('API', '${api}_$endpoint',
        error != null ? 'FAILED: $error' : 'SUCCESS',
        data: logData);
  }

  /// Log Firestore operations
  static void logFirestore(String operation, String collection, {
    String? docId,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    int? resultCount,
    String? error,
    int? durationMs,
  }) {
    final logData = <String, dynamic>{
      'collection': collection,
    };
    if (docId != null) logData['doc_id'] = docId;
    if (query != null) logData['query'] = query;
    if (data != null) logData['data'] = data;
    if (resultCount != null) logData['result_count'] = resultCount;
    if (error != null) logData['error'] = error;
    if (durationMs != null) logData['duration_ms'] = durationMs;

    log('FIRESTORE', operation,
        error != null ? 'FAILED: $error' : 'SUCCESS',
        data: logData);
  }

  /// Log embedding operations
  static void logEmbedding(String operation, {
    String? text,
    List<double>? embedding,
    double? similarity,
    String? error,
    int? durationMs,
  }) {
    final logData = <String, dynamic>{};
    if (text != null) logData['text'] = text.length > 100 ? '${text.substring(0, 100)}...' : text;
    if (embedding != null) {
      logData['embedding_length'] = embedding.length;
      logData['embedding_sample'] = embedding.take(5).toList();
      logData['embedding_magnitude'] = _calculateMagnitude(embedding);
    }
    if (similarity != null) logData['similarity'] = similarity;
    if (error != null) logData['error'] = error;
    if (durationMs != null) logData['duration_ms'] = durationMs;

    log('EMBEDDING', operation,
        error != null ? 'FAILED: $error' : 'SUCCESS',
        data: logData);
  }

  /// Log matching algorithm steps
  static void logMatching(String step, {
    int? candidateCount,
    int? matchCount,
    double? threshold,
    Map<String, double>? scores,
    String? error,
    int? durationMs,
  }) {
    final logData = <String, dynamic>{};
    if (candidateCount != null) logData['candidate_count'] = candidateCount;
    if (matchCount != null) logData['match_count'] = matchCount;
    if (threshold != null) logData['threshold'] = threshold;
    if (scores != null) logData['scores'] = scores;
    if (error != null) logData['error'] = error;
    if (durationMs != null) logData['duration_ms'] = durationMs;

    log('MATCHING', step,
        error != null ? 'FAILED: $error' : 'SUCCESS',
        data: logData);
  }

  /// Log intent analysis results
  static void logIntentAnalysis(String step, {
    String? originalPrompt,
    Map<String, dynamic>? analysis,
    List<String>? keywords,
    String? error,
    int? durationMs,
  }) {
    final logData = <String, dynamic>{};
    if (originalPrompt != null) logData['original_prompt'] = originalPrompt;
    if (analysis != null) logData['analysis'] = analysis;
    if (keywords != null) logData['keywords'] = keywords;
    if (error != null) logData['error'] = error;
    if (durationMs != null) logData['duration_ms'] = durationMs;

    log('INTENT', step,
        error != null ? 'FAILED: $error' : 'SUCCESS',
        data: logData);
  }

  /// Log performance metrics
  static void logPerformance(String operation, int durationMs, {
    Map<String, dynamic>? metrics,
  }) {
    final logData = <String, dynamic>{
      'duration_ms': durationMs,
      'performance_category': _getPerformanceCategory(durationMs),
    };
    if (metrics != null) logData.addAll(metrics);

    log('PERFORMANCE', operation,
        'Completed in ${durationMs}ms',
        data: logData);
  }

  /// Log user actions for analytics
  static void logUserAction(String action, {
    String? userId,
    String? postId,
    Map<String, dynamic>? context,
  }) {
    final logData = <String, dynamic>{
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    if (userId != null) logData['user_id'] = userId;
    if (postId != null) logData['post_id'] = postId;
    if (context != null) logData['context'] = context;

    log('USER_ACTION', action, 'User performed action', data: logData);
  }

  /// Comprehensive test logging
  static void logTestResult(String testName, {
    bool? passed,
    String? expected,
    String? actual,
    String? error,
    Map<String, dynamic>? testData,
    int? durationMs,
  }) {
    final logData = <String, dynamic>{
      'test_name': testName,
      'status': passed == true ? 'PASSED' : (passed == false ? 'FAILED' : 'ERROR'),
    };
    if (expected != null) logData['expected'] = expected;
    if (actual != null) logData['actual'] = actual;
    if (error != null) logData['error'] = error;
    if (testData != null) logData['test_data'] = testData;
    if (durationMs != null) logData['duration_ms'] = durationMs;

    log('TEST', testName,
        passed == true ? 'PASSED' : (passed == false ? 'FAILED' : 'ERROR'),
        data: logData);
  }

  /// Helper methods
  static double _calculateMagnitude(List<double> vector) {
    return vector.fold(0.0, (sum, value) => sum + value * value);
  }

  static String _getPerformanceCategory(int durationMs) {
    if (durationMs < 100) return 'FAST';
    if (durationMs < 500) return 'NORMAL';
    if (durationMs < 2000) return 'SLOW';
    return 'VERY_SLOW';
  }

  /// Store logs to Firestore for remote debugging
  static Future<void> _logToFirestore(
    String component,
    String function,
    String message,
    Map<String, dynamic>? data
  ) async {
    try {
      await FirebaseFirestore.instance.collection('debug_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'component': component,
        'function': function,
        'message': message,
        'data': data ?? {},
        'device_info': {
          'platform': defaultTargetPlatform.toString(),
          'debug_mode': kDebugMode,
        },
      });
    } catch (e) {
      debugPrint('Failed to store log to Firestore: $e');
    }
  }

  /// Get debug summary for troubleshooting
  static Map<String, dynamic> getDebugSummary() {
    return {
      'debug_enabled': enableDetailedLogs,
      'firestore_logging': logToFirestore,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.toString(),
      'debug_mode': kDebugMode,
    };
  }
}