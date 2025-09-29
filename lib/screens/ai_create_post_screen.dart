import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_intent_engine.dart';
import '../services/ai_matching_service.dart';
import '../widgets/ai_clarification_dialog.dart';
import '../models/ai_post_model.dart';

/// AI-powered create post screen without categories
class AICreatePostScreen extends StatefulWidget {
  const AICreatePostScreen({super.key});

  @override
  State<AICreatePostScreen> createState() => _AICreatePostScreenState();
}

class _AICreatePostScreenState extends State<AICreatePostScreen> {
  final TextEditingController _promptController = TextEditingController();
  final AIIntentEngine _intentEngine = AIIntentEngine();
  final AIMatchingService _matchingService = AIMatchingService();
  
  bool _isAnalyzing = false;
  IntentAnalysis? _intentAnalysis;
  List<String> _suggestedPrompts = [
    "iPhone 15 Pro",
    "Looking for a roommate in NYC",
    "Lost golden retriever in Central Park",
    "Need a graphic designer for my startup",
    "Anyone want to play tennis this weekend?",
    "Selling my 2020 Honda Civic",
    "Looking for someone to date",
    "Free couch, must pick up today",
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _intentEngine.initialize();
    await _matchingService.initialize();
  }

  Future<void> _analyzeIntent() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter what you\'re looking for')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Analyze the user's intent
      final analysis = await _intentEngine.analyzeIntent(_promptController.text);
      
      setState(() {
        _intentAnalysis = analysis;
        _isAnalyzing = false;
      });

      // Check if clarification is needed
      if (analysis.clarificationsNeeded.isNotEmpty) {
        // Show AI clarification dialog
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AIClarificationDialog(
              userPrompt: _promptController.text,
              intentAnalysis: analysis,
              onComplete: (answers) {
                _createPost(analysis, answers);
              },
            ),
          );
        }
      } else {
        // Create post directly if no clarification needed
        _createPost(analysis, {});
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _createPost(IntentAnalysis analysis, Map<String, dynamic> answers) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating your post...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Create the post
      final postId = await _matchingService.createPost(_promptController.text);
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (postId != null) {
        // Show success
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Success!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your post has been created and we\'re finding matches for you.'),
                  const SizedBox(height: 16),
                  Text(
                    'AI understood: ${analysis.primaryIntent}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Action type: ${analysis.actionType}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('View Matches'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _promptController.clear();
                    setState(() {
                      _intentAnalysis = null;
                    });
                  },
                  child: const Text('Create Another'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildPromptInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are you looking for?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Just type naturally - our AI will understand',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g., "Looking for a tennis partner this weekend" or "Selling my MacBook Pro"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _promptController.text.trim().isEmpty || _isAnalyzing
                  ? null
                  : _analyzeIntent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try these examples:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedPrompts.map((prompt) {
            return InkWell(
              onTap: () {
                _promptController.text = prompt;
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  prompt,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIntentPreview() {
    if (_intentAnalysis == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Understanding',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Intent: ${_intentAnalysis!.primaryIntent}'),
          Text('Action: ${_intentAnalysis!.actionType}'),
          if (_intentAnalysis!.searchKeywords.isNotEmpty)
            Text('Keywords: ${_intentAnalysis!.searchKeywords.join(', ')}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Post'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.blue[400]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'AI-Powered Matching',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Main input
              _buildPromptInput(),
              
              // Intent preview
              _buildIntentPreview(),
              
              const SizedBox(height: 24),
              
              // Suggested prompts
              _buildSuggestedPrompts(),
              
              const SizedBox(height: 40),
              
              // How it works
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✨ How it works',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHowItWorksItem(
                      '1',
                      'Type what you need',
                      'No categories needed - just describe it naturally',
                    ),
                    _buildHowItWorksItem(
                      '2',
                      'AI understands your intent',
                      'Our AI figures out what you\'re looking for',
                    ),
                    _buildHowItWorksItem(
                      '3',
                      'Get matched instantly',
                      'We find people with complementary needs',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorksItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
}