import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_intent_engine.dart';
import 'ai_matching_service.dart';
import 'debug_service.dart';
import '../models/ai_post_model.dart';

/// Comprehensive test service to diagnose matching system issues
class MatchingTestService {
  final AIIntentEngine _intentEngine = AIIntentEngine();
  final AIMatchingService _matchingService = AIMatchingService();

  /// Run comprehensive test suite
  Future<TestResults> runFullTest() async {
    final stopwatch = Stopwatch()..start();
    DebugService.log('TEST', 'runFullTest', 'Starting comprehensive matching test suite');

    final results = TestResults();

    try {
      // Test 1: Initialize services
      await _testInitialization(results);

      // Test 2: Test AI intent analysis
      await _testIntentAnalysis(results);

      // Test 3: Test embedding generation
      await _testEmbeddingGeneration(results);

      // Test 4: Test similarity calculations
      await _testSimilarityCalculations(results);

      // Test 5: Test post creation
      await _testPostCreation(results);

      // Test 6: Test matching pipeline
      await _testMatchingPipeline(results);

      // Test 7: Test real-world scenarios
      await _testRealWorldScenarios(results);

      results.totalDurationMs = stopwatch.elapsedMilliseconds;
      results.overallSuccess = results.failedTests.isEmpty;

      DebugService.logTestResult('FULL_TEST_SUITE',
          passed: results.overallSuccess,
          testData: results.toMap(),
          durationMs: results.totalDurationMs);

      return results;
    } catch (e) {
      DebugService.logTestResult('FULL_TEST_SUITE',
          passed: false,
          error: e.toString(),
          durationMs: stopwatch.elapsedMilliseconds);

      results.failedTests.add('FULL_TEST_SUITE: $e');
      results.overallSuccess = false;
      return results;
    } finally {
      stopwatch.stop();
    }
  }

  Future<void> _testInitialization(TestResults results) async {
    final testName = 'SERVICE_INITIALIZATION';
    try {
      DebugService.log('TEST', testName, 'Testing service initialization');

      await _intentEngine.initialize();
      await _matchingService.initialize();

      results.passedTests.add(testName);
      DebugService.logTestResult(testName, passed: true);
    } catch (e) {
      results.failedTests.add('$testName: $e');
      DebugService.logTestResult(testName, passed: false, error: e.toString());
    }
  }

  Future<void> _testIntentAnalysis(TestResults results) async {
    final testCases = [
      'iPhone 14 Pro for sale',
      'Looking for iPhone',
      'Need a plumber',
      'Lost my dog in Central Park',
      'Room for rent',
      'Looking for roommate',
    ];

    for (final testCase in testCases) {
      final testName = 'INTENT_ANALYSIS_$testCase';
      try {
        DebugService.log('TEST', testName, 'Testing intent analysis for: $testCase');

        final analysis = await _intentEngine.analyzeIntent(testCase);

        // Validate analysis
        if (analysis.primaryIntent.isEmpty) {
          throw Exception('Empty primary intent');
        }
        if (analysis.actionType.isEmpty) {
          throw Exception('Empty action type');
        }
        if (analysis.searchKeywords.isEmpty) {
          throw Exception('No search keywords');
        }

        results.passedTests.add(testName);
        results.intentAnalysisResults[testCase] = analysis.toJson();

        DebugService.logTestResult(testName,
            passed: true,
            testData: {
              'input': testCase,
              'primary_intent': analysis.primaryIntent,
              'action_type': analysis.actionType,
              'keywords': analysis.searchKeywords,
            });
      } catch (e) {
        results.failedTests.add('$testName: $e');
        DebugService.logTestResult(testName,
            passed: false,
            error: e.toString(),
            testData: {'input': testCase});
      }
    }
  }

  Future<void> _testEmbeddingGeneration(TestResults results) async {
    final testCases = [
      'iPhone for sale',
      'Looking for iPhone',
      'Plumber available',
      'Need plumber',
      'Lost dog',
      'Found dog',
    ];

    for (final testCase in testCases) {
      final testName = 'EMBEDDING_GENERATION_$testCase';
      try {
        DebugService.log('TEST', testName, 'Testing embedding generation for: $testCase');

        final embedding = await _intentEngine.generateEmbedding(testCase);

        // Validate embedding
        if (embedding.isEmpty) {
          throw Exception('Empty embedding');
        }
        if (embedding.length != 768) {
          throw Exception('Incorrect embedding dimension: ${embedding.length}');
        }

        // Check if embedding is not all zeros
        final sum = embedding.fold(0.0, (sum, val) => sum + val.abs());
        if (sum < 0.001) {
          throw Exception('Embedding appears to be zero vector');
        }

        results.passedTests.add(testName);
        results.embeddingResults[testCase] = {
          'length': embedding.length,
          'magnitude': _calculateMagnitude(embedding),
          'sample': embedding.take(5).toList(),
        };

        DebugService.logTestResult(testName,
            passed: true,
            testData: {
              'input': testCase,
              'embedding_length': embedding.length,
              'magnitude': _calculateMagnitude(embedding),
            });
      } catch (e) {
        results.failedTests.add('$testName: $e');
        DebugService.logTestResult(testName,
            passed: false,
            error: e.toString(),
            testData: {'input': testCase});
      }
    }
  }

  Future<void> _testSimilarityCalculations(TestResults results) async {
    final testName = 'SIMILARITY_CALCULATIONS';
    try {
      DebugService.log('TEST', testName, 'Testing similarity calculations');

      // Test complementary pairs
      final testPairs = [
        ['iPhone for sale', 'Looking for iPhone'],
        ['Need plumber', 'Plumber available'],
        ['Lost dog', 'Found dog'],
        ['Room for rent', 'Looking for room'],
      ];

      for (final pair in testPairs) {
        final embedding1 = await _intentEngine.generateEmbedding(pair[0]);
        final embedding2 = await _intentEngine.generateEmbedding(pair[1]);

        if (embedding1.isEmpty || embedding2.isEmpty) {
          throw Exception('Failed to generate embeddings for pair: $pair');
        }

        final similarity = _calculateCosineSimilarity(embedding1, embedding2);

        results.similarityResults.add({
          'text1': pair[0],
          'text2': pair[1],
          'similarity': similarity,
        });

        DebugService.log('TEST', testName,
            'Similarity between "${pair[0]}" and "${pair[1]}": $similarity');
      }

      results.passedTests.add(testName);
      DebugService.logTestResult(testName,
          passed: true,
          testData: {'similarity_pairs': results.similarityResults.length});
    } catch (e) {
      results.failedTests.add('$testName: $e');
      DebugService.logTestResult(testName, passed: false, error: e.toString());
    }
  }

  Future<void> _testPostCreation(TestResults results) async {
    final testName = 'POST_CREATION';
    try {
      DebugService.log('TEST', testName, 'Testing post creation');

      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated - cannot test post creation');
      }

      final testPrompt = 'Test iPhone for sale - ${DateTime.now().millisecondsSinceEpoch}';
      final postId = await _matchingService.createPost(testPrompt);

      if (postId == null) {
        throw Exception('Failed to create post');
      }

      results.passedTests.add(testName);
      results.createdPostIds.add(postId);

      DebugService.logTestResult(testName,
          passed: true,
          testData: {
            'prompt': testPrompt,
            'post_id': postId,
            'user_id': user.uid,
          });
    } catch (e) {
      results.failedTests.add('$testName: $e');
      DebugService.logTestResult(testName, passed: false, error: e.toString());
    }
  }

  Future<void> _testMatchingPipeline(TestResults results) async {
    final testName = 'MATCHING_PIPELINE';
    try {
      DebugService.log('TEST', testName, 'Testing matching pipeline');

      // Create a test post
      final testPost = AIPostModel(
        id: 'test_post_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test_user_1',
        originalPrompt: 'Looking for iPhone 14',
        intentAnalysis: {
          'primary_intent': 'buy iPhone 14',
          'action_type': 'seeking',
          'search_keywords': ['iPhone', '14', 'buy'],
        },
        clarificationAnswers: {},
        embedding: await _intentEngine.generateEmbedding('Looking for iPhone 14'),
        createdAt: DateTime.now(),
        metadata: {'test': true},
      );

      final matches = await _matchingService.findBestPeople(testPost);

      results.passedTests.add(testName);
      results.matchingResults = {
        'test_post_id': testPost.id,
        'matches_found': matches.length,
        'match_scores': matches.map((m) => m.matchScore.totalScore).toList(),
      };

      DebugService.logTestResult(testName,
          passed: true,
          testData: results.matchingResults);
    } catch (e) {
      results.failedTests.add('$testName: $e');
      DebugService.logTestResult(testName, passed: false, error: e.toString());
    }
  }

  Future<void> _testRealWorldScenarios(TestResults results) async {
    final scenarios = [
      {
        'name': 'MARKETPLACE_SCENARIO',
        'posts': ['iPhone 14 Pro for sale \$800', 'Looking for iPhone under \$900'],
        'expectedMatch': true,
      },
      {
        'name': 'SERVICE_SCENARIO',
        'posts': ['Need plumber urgently', 'Certified plumber available 24/7'],
        'expectedMatch': true,
      },
      {
        'name': 'LOST_FOUND_SCENARIO',
        'posts': ['Lost golden retriever in Central Park', 'Found dog near Central Park'],
        'expectedMatch': true,
      },
    ];

    for (final scenario in scenarios) {
      final testName = scenario['name'] as String;
      try {
        DebugService.log('TEST', testName, 'Testing real-world scenario');

        final posts = scenario['posts'] as List<String>;
        final analysis1 = await _intentEngine.analyzeIntent(posts[0]);
        final analysis2 = await _intentEngine.analyzeIntent(posts[1]);

        final embedding1 = await _intentEngine.generateEmbedding(posts[0]);
        final embedding2 = await _intentEngine.generateEmbedding(posts[1]);

        final similarity = _calculateCosineSimilarity(embedding1, embedding2);

        final compatibility = await _intentEngine.analyzeCompatibility(
          analysis1,
          analysis2,
          {},
          {},
        );

        final shouldMatch = scenario['expectedMatch'] as bool;
        final actuallyMatches = compatibility.score > 0.2; // Using our lowered threshold

        if (shouldMatch && !actuallyMatches) {
          throw Exception('Expected match but got score: ${compatibility.score}');
        }

        results.passedTests.add(testName);
        results.realWorldScenarios[testName] = {
          'posts': posts,
          'similarity': similarity,
          'compatibility_score': compatibility.score,
          'matches': actuallyMatches,
          'reasons': compatibility.reasons,
        };

        DebugService.logTestResult(testName,
            passed: true,
            testData: results.realWorldScenarios[testName]);
      } catch (e) {
        results.failedTests.add('$testName: $e');
        DebugService.logTestResult(testName, passed: false, error: e.toString());
      }
    }
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

  double _calculateMagnitude(List<double> vector) {
    return sqrt(vector.fold(0.0, (sum, value) => sum + value * value));
  }
}

/// Test results container
class TestResults {
  bool overallSuccess = false;
  int totalDurationMs = 0;
  List<String> passedTests = [];
  List<String> failedTests = [];
  Map<String, dynamic> intentAnalysisResults = {};
  Map<String, dynamic> embeddingResults = {};
  List<Map<String, dynamic>> similarityResults = [];
  List<String> createdPostIds = [];
  Map<String, dynamic> matchingResults = {};
  Map<String, dynamic> realWorldScenarios = {};

  Map<String, dynamic> toMap() {
    return {
      'overall_success': overallSuccess,
      'total_duration_ms': totalDurationMs,
      'passed_tests': passedTests,
      'failed_tests': failedTests,
      'tests_passed': passedTests.length,
      'tests_failed': failedTests.length,
      'intent_analysis_results': intentAnalysisResults,
      'embedding_results': embeddingResults,
      'similarity_results': similarityResults,
      'created_post_ids': createdPostIds,
      'matching_results': matchingResults,
      'real_world_scenarios': realWorldScenarios,
    };
  }

  String getSummary() {
    final total = passedTests.length + failedTests.length;
    final successRate = total > 0 ? (passedTests.length / total * 100).toStringAsFixed(1) : '0';

    return '''
=== SUPPER MATCHING SYSTEM TEST RESULTS ===
Overall Success: $overallSuccess
Tests Passed: ${passedTests.length}
Tests Failed: ${failedTests.length}
Success Rate: $successRate%
Total Duration: ${totalDurationMs}ms

${failedTests.isNotEmpty ? 'FAILED TESTS:\n${failedTests.map((t) => '❌ $t').join('\n')}\n' : ''}
PASSED TESTS:
${passedTests.map((t) => '✅ $t').join('\n')}

=== DEBUGGING RECOMMENDATIONS ===
${_getDebuggingRecommendations()}
''';
  }

  String _getDebuggingRecommendations() {
    final recommendations = <String>[];

    if (failedTests.any((t) => t.contains('INTENT_ANALYSIS'))) {
      recommendations.add('🔍 Check Gemini API key and quota');
      recommendations.add('🔍 Verify intent analysis prompts');
    }

    if (failedTests.any((t) => t.contains('EMBEDDING'))) {
      recommendations.add('🔍 Check embedding model configuration');
      recommendations.add('🔍 Verify embedding API responses');
    }

    if (failedTests.any((t) => t.contains('SIMILARITY'))) {
      recommendations.add('🔍 Review cosine similarity calculation');
      recommendations.add('🔍 Check embedding quality and dimensions');
    }

    if (failedTests.any((t) => t.contains('POST_CREATION'))) {
      recommendations.add('🔍 Verify Firebase authentication');
      recommendations.add('🔍 Check Firestore rules and permissions');
    }

    if (failedTests.any((t) => t.contains('MATCHING'))) {
      recommendations.add('🔍 Review matching thresholds (currently 0.2)');
      recommendations.add('🔍 Check multi-factor scoring algorithm');
    }

    if (recommendations.isEmpty) {
      recommendations.add('🎉 All tests passed! System appears to be working correctly.');
    }

    return recommendations.join('\n');
  }
}

/// Extension to run test from any screen
extension TestRunner on BuildContext {
  Future<void> runMatchingTest() async {
    final testService = MatchingTestService();
    final results = await testService.runFullTest();

    // Show results dialog
    showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(results.overallSuccess ? '✅ Tests Passed' : '❌ Tests Failed'),
        content: SingleChildScrollView(
          child: Text(results.getSummary()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}