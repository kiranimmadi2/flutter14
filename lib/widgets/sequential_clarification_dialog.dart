import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/sequential_clarification_service.dart';

class SequentialClarificationDialog extends StatefulWidget {
  final String originalInput;
  final Map<String, dynamic> extractedData;

  const SequentialClarificationDialog({
    Key? key,
    required this.originalInput,
    required this.extractedData,
  }) : super(key: key);

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String originalInput,
    required Map<String, dynamic> extractedData,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SequentialClarificationDialog(
        originalInput: originalInput,
        extractedData: extractedData,
      ),
    );
  }

  @override
  State<SequentialClarificationDialog> createState() => _SequentialClarificationDialogState();
}

class _SequentialClarificationDialogState extends State<SequentialClarificationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final SequentialClarificationService _clarificationService = SequentialClarificationService();
  final TextEditingController _customController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _askedQuestions = [];
  Map<String, dynamic> _collectedAnswers = {};
  Map<String, dynamic>? _currentQuestion;
  bool _showCustomInput = false;
  bool _isComplete = false;
  bool _finishingTriggered = false;
  int _questionNumber = 1;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNextQuestion();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  void _loadNextQuestion() async {
    print('DEBUG: _loadNextQuestion called');
    print('DEBUG: Current _askedQuestions: $_askedQuestions');

    try {
      final nextQuestion = await _clarificationService.getNextQuestion(
        widget.extractedData,
        _askedQuestions,
        _collectedAnswers,
        widget.originalInput,
      );

      print('DEBUG: Next question returned: ${nextQuestion?['type']}');

      setState(() {
        _currentQuestion = nextQuestion;
        _showCustomInput = false;
        _isComplete = nextQuestion == null;
      });

      if (_isComplete) {
        print('DEBUG: Questions complete, calling _finishClarification');
        _finishClarification();
      }
    } catch (e) {
      print('ERROR: Failed to load next question: $e');
      setState(() {
        _isComplete = true;
      });
      _finishClarification();
    }
  }

  void _handleAnswer(String answer) {
    if (_currentQuestion != null) {
      final questionType = _currentQuestion!['type'];

      print('DEBUG: Handling answer "$answer" for question type: $questionType');

      // Store the answer
      final parsedAnswer = _parseAnswer(questionType, answer);
      _collectedAnswers[questionType] = parsedAnswer;
      _askedQuestions.add(questionType);
      _questionNumber++;

      // Store the question-answer pair in database
      _storeQuestionAnswerInDatabase(questionType, answer, parsedAnswer);

      print('DEBUG: Updated _askedQuestions: $_askedQuestions');
      print('DEBUG: Updated _collectedAnswers: $_collectedAnswers');

      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Small delay for better UX
      Future.delayed(Duration(milliseconds: 300), () {
        _loadNextQuestion();
      });
    }
  }

  dynamic _parseAnswer(String questionType, String answer) {
    // Parse budget answers to extract numbers
    if (questionType == 'budget') {
      if (answer.contains('\$')) {
        final numberMatch = RegExp(r'\$(\d+)').firstMatch(answer);
        if (numberMatch != null) {
          return int.tryParse(numberMatch.group(1)!) ?? answer;
        }
      }
    }
    return answer;
  }

  // Store question-answer pair in database for analytics
  void _storeQuestionAnswerInDatabase(String questionType, String rawAnswer, dynamic parsedAnswer) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('clarification_answers').add({
        'userId': userId,
        'originalInput': widget.originalInput,
        'questionType': questionType,
        'question': _currentQuestion?['question'],
        'rawAnswer': rawAnswer,
        'parsedAnswer': parsedAnswer,
        'questionNumber': _questionNumber,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('DEBUG: Stored question-answer pair in database');
    } catch (e) {
      print('Error storing answer in database: $e');
      // Don't throw error - this shouldn't break the user experience
    }
  }

  void _finishClarification() {
    print('DEBUG: _finishClarification called');
    print('DEBUG: _collectedAnswers: $_collectedAnswers');

    final finalIntent = _clarificationService.buildFinalIntent(
      widget.originalInput,
      widget.extractedData,
      _collectedAnswers,
    );

    print('DEBUG: _finishClarification finalIntent: $finalIntent');

    // Immediately close the dialog and return the result
    if (mounted) {
      print('DEBUG: About to pop with finalIntent');
      Navigator.of(context).pop(finalIntent);
    } else {
      print('DEBUG: Widget not mounted, cannot pop');
    }
  }

  void _skipQuestion() {
    if (_currentQuestion != null) {
      _askedQuestions.add(_currentQuestion!['type']);
      HapticFeedback.lightImpact();
      _loadNextQuestion();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isComplete) {
      // Trigger finish immediately (only once)
      if (!_finishingTriggered) {
        _finishingTriggered = true;
        print('DEBUG: _isComplete = true, calling _finishClarification with delay');
        // Short delay to show completion message, then close
        Future.delayed(Duration(milliseconds: 500), () {
          print('DEBUG: Future.delayed callback executing, mounted: $mounted');
          if (mounted) {
            _finishClarification();
          }
        });

        // Emergency fallback - force close after 2 seconds
        Future.delayed(Duration(milliseconds: 2000), () {
          print('DEBUG: Emergency fallback executing, mounted: $mounted');
          if (mounted) {
            print('DEBUG: Emergency fallback - forcing dialog close');
            Navigator.of(context).pop({'emergency_close': true});
          }
        });
      }
      return _buildCompletionDialog(theme);
    }

    if (_currentQuestion == null) {
      _finishClarification();
      return _buildLoadingDialog(theme);
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 24,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
                decoration: BoxDecoration(
                  color: theme.dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(theme),
                    Flexible(child: _buildContent(theme)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.quiz, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Quick Question',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_questionNumber of 4',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Progress bar
          LinearProgressIndicator(
            value: _questionNumber / 4,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Original input chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.format_quote, size: 16, color: theme.primaryColor),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.originalInput,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Question
          Text(
            _currentQuestion!['question'],
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 20),

          // Options or custom input
          Flexible(
            child: SingleChildScrollView(
              child: _showCustomInput ? _buildCustomInput(theme) : _buildOptions(theme),
            ),
          ),

          SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              TextButton(
                onPressed: _skipQuestion,
                child: Text(
                  'Skip',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              Spacer(),
              if (!_showCustomInput)
                TextButton.icon(
                  onPressed: () => setState(() => _showCustomInput = true),
                  icon: Icon(Icons.edit, size: 16),
                  label: Text('Custom answer'),
                  style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(ThemeData theme) {
    final options = List<String>.from(_currentQuestion!['options']);

    return Column(
      children: options.map((option) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleAnswer(option),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.transparent,
                foregroundColor: theme.primaryColor,
                side: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                elevation: 0,
              ),
              child: Text(
                option,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomInput(ThemeData theme) {
    return Column(
      children: [
        TextField(
          controller: _customController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor, width: 2),
            ),
            prefixIcon: Icon(Icons.edit),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _handleAnswer(value);
            }
          },
        ),
        SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() {
                _showCustomInput = false;
                _customController.clear();
              }),
              child: Text('Back to options'),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                if (_customController.text.isNotEmpty) {
                  _handleAnswer(_customController.text);
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingDialog(ThemeData theme) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Processing your request...',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionDialog(ThemeData theme) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            SizedBox(height: 20),
            Text(
              'Got it! Searching for matches...',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}