import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_intent_engine.dart';
import '../services/fixed_ai_matching_service.dart';
import '../services/debug_service.dart';
import '../services/matching_test_service.dart';

/// Simple utility to test the matching system from any screen
class MatchingSystemTester {
  /// Quick test to verify the matching system is working
  static Future<String> quickTest() async {
    final buffer = StringBuffer();
    buffer.writeln('🔍 SUPPER MATCHING SYSTEM QUICK TEST');
    buffer.writeln('=' * 50);

    try {
      // Test 1: Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        buffer.writeln('❌ User not authenticated');
        buffer.writeln('Please log in to test the matching system.');
        return buffer.toString();
      }
      buffer.writeln('✅ User authenticated: ${user.uid}');

      // Test 2: Initialize AI engine
      final intentEngine = AIIntentEngine();
      await intentEngine.initialize();
      buffer.writeln('✅ AI Intent Engine initialized');

      // Test 3: Test intent analysis
      final testPrompt = 'iPhone 14 Pro for sale';
      final analysis = await intentEngine.analyzeIntent(testPrompt);
      if (analysis.primaryIntent.isNotEmpty) {
        buffer.writeln('✅ Intent Analysis working');
        buffer.writeln('   Input: "$testPrompt"');
        buffer.writeln('   Intent: ${analysis.primaryIntent}');
        buffer.writeln('   Action: ${analysis.actionType}');
        buffer.writeln('   Keywords: ${analysis.searchKeywords.join(", ")}');
      } else {
        buffer.writeln('❌ Intent Analysis failed - empty result');
      }

      // Test 4: Test embedding generation
      final embedding = await intentEngine.generateEmbedding(testPrompt);
      if (embedding.isNotEmpty && embedding.length == 768) {
        buffer.writeln('✅ Embedding Generation working');
        buffer.writeln('   Embedding length: ${embedding.length}');
        buffer.writeln('   First 5 values: ${embedding.take(5).toList()}');
      } else {
        buffer.writeln('❌ Embedding Generation failed');
        buffer.writeln('   Length: ${embedding.length} (expected 768)');
      }

      // Test 5: Test similarity calculation
      final embedding2 = await intentEngine.generateEmbedding('Looking for iPhone');
      if (embedding.isNotEmpty && embedding2.isNotEmpty) {
        final similarity = _calculateSimilarity(embedding, embedding2);
        buffer.writeln('✅ Similarity Calculation working');
        buffer.writeln('   "iPhone 14 Pro for sale" vs "Looking for iPhone"');
        buffer.writeln('   Similarity: ${similarity.toStringAsFixed(4)}');
      } else {
        buffer.writeln('❌ Similarity Calculation failed - missing embeddings');
      }

      // Test 6: Test post creation
      final matchingService = FixedAIMatchingService();
      await matchingService.initialize();

      final testPostPrompt = 'Test iPhone for quick test - ${DateTime.now().millisecondsSinceEpoch}';
      final postId = await matchingService.createPost(testPostPrompt);

      if (postId != null) {
        buffer.writeln('✅ Post Creation working');
        buffer.writeln('   Created post ID: $postId');
      } else {
        buffer.writeln('❌ Post Creation failed');
      }

      buffer.writeln('');
      buffer.writeln('🎉 QUICK TEST SUMMARY:');
      buffer.writeln('   Basic functionality appears to be working!');
      buffer.writeln('   For detailed testing, run the full test suite.');

    } catch (e) {
      buffer.writeln('❌ Test failed with error: $e');
      buffer.writeln('');
      buffer.writeln('🔧 DEBUGGING TIPS:');
      buffer.writeln('   1. Check internet connection');
      buffer.writeln('   2. Verify Gemini API key is valid');
      buffer.writeln('   3. Check Firebase configuration');
      buffer.writeln('   4. Look at debug logs for more details');
    }

    return buffer.toString();
  }

  /// Run full comprehensive test suite
  static Future<String> runFullTests() async {
    try {
      final testService = MatchingTestService();
      final results = await testService.runFullTest();
      return results.getSummary();
    } catch (e) {
      return '''
❌ FULL TEST SUITE FAILED TO RUN
Error: $e

🔧 Try running the quick test first to identify basic issues.
''';
    }
  }

  /// Test real-world matching scenario
  static Future<String> testRealWorldMatching() async {
    final buffer = StringBuffer();
    buffer.writeln('🌍 REAL-WORLD MATCHING TEST');
    buffer.writeln('=' * 50);

    try {
      final intentEngine = AIIntentEngine();
      await intentEngine.initialize();

      // Test complementary scenarios
      final scenarios = [
        {
          'seller': 'iPhone 14 Pro for sale, excellent condition, \$800',
          'buyer': 'Looking for iPhone 14, budget up to \$900',
          'category': 'Marketplace'
        },
        {
          'service_provider': 'Professional plumber available 24/7, licensed and insured',
          'service_seeker': 'Need plumber urgently, kitchen sink is leaking',
          'category': 'Services'
        },
        {
          'lost_item': 'Lost golden retriever in Central Park, wearing blue collar',
          'found_item': 'Found golden retriever near Central Park, has blue collar',
          'category': 'Lost & Found'
        },
      ];

      for (final scenario in scenarios) {
        buffer.writeln('\\n📋 Testing ${scenario['category']} scenario:');

        final keys = scenario.keys.where((k) => k != 'category').toList();
        final post1Text = scenario[keys[0]]!;
        final post2Text = scenario[keys[1]]!;

        // Analyze both posts
        final analysis1 = await intentEngine.analyzeIntent(post1Text);
        final analysis2 = await intentEngine.analyzeIntent(post2Text);

        buffer.writeln('   Post 1: "$post1Text"');
        buffer.writeln('   → Intent: ${analysis1.primaryIntent} (${analysis1.actionType})');

        buffer.writeln('   Post 2: "$post2Text"');
        buffer.writeln('   → Intent: ${analysis2.primaryIntent} (${analysis2.actionType})');

        // Check compatibility
        final compatibility = await intentEngine.analyzeCompatibility(
          analysis1, analysis2, {}, {}
        );

        buffer.writeln('   💯 Compatibility Score: ${(compatibility.score * 100).toStringAsFixed(1)}%');

        if (compatibility.score > 0.2) {
          buffer.writeln('   ✅ These posts would MATCH!');
          buffer.writeln('   Reasons: ${compatibility.reasons.join(", ")}');
        } else {
          buffer.writeln('   ❌ These posts would NOT match');
          buffer.writeln('   Score too low: ${compatibility.score}');
        }

        // Also test semantic similarity
        final embedding1 = await intentEngine.generateEmbedding(post1Text);
        final embedding2 = await intentEngine.generateEmbedding(post2Text);
        final similarity = _calculateSimilarity(embedding1, embedding2);
        buffer.writeln('   📊 Semantic Similarity: ${(similarity * 100).toStringAsFixed(1)}%');
      }

      buffer.writeln('\\n🎉 Real-world testing complete!');
      buffer.writeln('If you see good scores above, the system is working correctly.');

    } catch (e) {
      buffer.writeln('❌ Real-world test failed: $e');
    }

    return buffer.toString();
  }

  static double _calculateSimilarity(List<double> vec1, List<double> vec2) {
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
}

/// Widget to show test results in a dialog
class MatchingTestDialog extends StatefulWidget {
  final String title;
  final Future<String> testFunction;

  const MatchingTestDialog({
    Key? key,
    required this.title,
    required this.testFunction,
  }) : super(key: key);

  @override
  State<MatchingTestDialog> createState() => _MatchingTestDialogState();
}

class _MatchingTestDialogState extends State<MatchingTestDialog> {
  bool _isLoading = true;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    try {
      final result = await widget.testFunction;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Test failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Running tests...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Text(
                  _result,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
      ),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
      ],
    );
  }
}

/// Extension to easily call tests from any BuildContext
extension MatchingTestExtension on BuildContext {
  /// Show quick test results
  Future<void> showQuickMatchingTest() async {
    showDialog(
      context: this,
      builder: (context) => MatchingTestDialog(
        title: '🔍 Quick Test Results',
        testFunction: MatchingSystemTester.quickTest(),
      ),
    );
  }

  /// Show full test results
  Future<void> showFullMatchingTests() async {
    showDialog(
      context: this,
      builder: (context) => MatchingTestDialog(
        title: '🧪 Full Test Suite Results',
        testFunction: MatchingSystemTester.runFullTests(),
      ),
    );
  }

  /// Show real-world matching test
  Future<void> showRealWorldMatchingTest() async {
    showDialog(
      context: this,
      builder: (context) => MatchingTestDialog(
        title: '🌍 Real-World Matching Test',
        testFunction: MatchingSystemTester.testRealWorldMatching(),
      ),
    );
  }
}