import 'package:flutter/material.dart';
import '../models/post_model.dart';

class EnhancedClarificationDialog extends StatefulWidget {
  final String initialPrompt;
  final PostCategory? detectedCategory;
  final PostIntent? detectedIntent;
  final Function(Map<String, dynamic>) onComplete;

  const EnhancedClarificationDialog({
    super.key,
    required this.initialPrompt,
    this.detectedCategory,
    this.detectedIntent,
    required this.onComplete,
  });

  @override
  State<EnhancedClarificationDialog> createState() => _EnhancedClarificationDialogState();
}

class _EnhancedClarificationDialogState extends State<EnhancedClarificationDialog> {
  int _currentStep = 0;
  final Map<String, dynamic> _answers = {};
  List<ClarificationQuestion> _questions = [];
  
  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  void _generateQuestions() {
    _questions = [];
    
    // Generate questions based on detected category and intent
    if (widget.detectedIntent == null) {
      _questions.add(ClarificationQuestion(
        key: 'intent',
        question: 'What would you like to do?',
        type: QuestionType.choice,
        options: _getIntentOptions(),
      ));
    }

    // Add category-specific questions
    switch (widget.detectedCategory) {
      case PostCategory.marketplace:
        _addMarketplaceQuestions();
        break;
      case PostCategory.dating:
      case PostCategory.friendship:
        _addSocialQuestions();
        break;
      case PostCategory.jobs:
        _addJobQuestions();
        break;
      case PostCategory.lostFound:
        _addLostFoundQuestions();
        break;
      case PostCategory.housing:
        _addHousingQuestions();
        break;
      default:
        _addGeneralQuestions();
    }
  }

  List<String> _getIntentOptions() {
    switch (widget.detectedCategory) {
      case PostCategory.marketplace:
        return ['Buy', 'Sell', 'Trade', 'Give Away'];
      case PostCategory.jobs:
        return ['Looking for Job', 'Hiring', 'Offering Service', 'Looking for Service'];
      case PostCategory.lostFound:
        return ['Lost', 'Found'];
      case PostCategory.housing:
        return ['Offering Room/Apartment', 'Looking for Room/Apartment'];
      case PostCategory.dating:
      case PostCategory.friendship:
        return ['Looking for Someone', 'Available to Meet'];
      default:
        return ['Offering', 'Looking For', 'Other'];
    }
  }

  void _addMarketplaceQuestions() {
    // Price question
    if (widget.detectedIntent == PostIntent.selling) {
      _questions.add(ClarificationQuestion(
        key: 'price',
        question: 'What\'s your asking price?',
        type: QuestionType.price,
        hint: 'Enter price or "Free" for giveaway',
      ));
    } else if (widget.detectedIntent == PostIntent.buying) {
      _questions.add(ClarificationQuestion(
        key: 'priceRange',
        question: 'What\'s your budget range?',
        type: QuestionType.priceRange,
        hint: 'Enter min and max price',
      ));
    }

    // Condition question
    _questions.add(ClarificationQuestion(
      key: 'condition',
      question: 'What condition is the item in?',
      type: QuestionType.choice,
      options: ['New', 'Like New', 'Good', 'Fair', 'For Parts'],
    ));

    // Location question
    _questions.add(ClarificationQuestion(
      key: 'location',
      question: 'Where are you located?',
      type: QuestionType.location,
      hint: 'Enter city or neighborhood',
    ));
  }

  void _addSocialQuestions() {
    // Gender preference
    _questions.add(ClarificationQuestion(
      key: 'genderPreference',
      question: 'Who are you looking to meet?',
      type: QuestionType.choice,
      options: ['Male', 'Female', 'Anyone'],
    ));

    // Age range
    _questions.add(ClarificationQuestion(
      key: 'ageRange',
      question: 'What age range are you interested in?',
      type: QuestionType.text,
      hint: 'e.g., 25-35',
    ));

    // Interests
    _questions.add(ClarificationQuestion(
      key: 'interests',
      question: 'What are your interests?',
      type: QuestionType.multiChoice,
      options: ['Sports', 'Music', 'Movies', 'Travel', 'Food', 'Gaming', 'Reading', 'Fitness', 'Art', 'Technology'],
    ));

    // Location
    _questions.add(ClarificationQuestion(
      key: 'location',
      question: 'Where would you like to meet people?',
      type: QuestionType.location,
      hint: 'Enter city or area',
    ));
  }

  void _addJobQuestions() {
    if (widget.detectedIntent == PostIntent.hiring) {
      _questions.add(ClarificationQuestion(
        key: 'jobType',
        question: 'What type of position?',
        type: QuestionType.choice,
        options: ['Full-time', 'Part-time', 'Contract', 'Freelance', 'Internship'],
      ));
      
      _questions.add(ClarificationQuestion(
        key: 'salary',
        question: 'What\'s the salary range?',
        type: QuestionType.priceRange,
        hint: 'Annual or hourly rate',
      ));
    } else {
      _questions.add(ClarificationQuestion(
        key: 'experience',
        question: 'Years of experience?',
        type: QuestionType.text,
        hint: 'e.g., 2-5 years',
      ));
      
      _questions.add(ClarificationQuestion(
        key: 'expectedSalary',
        question: 'Expected salary range?',
        type: QuestionType.priceRange,
        hint: 'Annual or hourly rate',
      ));
    }

    _questions.add(ClarificationQuestion(
      key: 'location',
      question: 'Work location?',
      type: QuestionType.choice,
      options: ['Remote', 'On-site', 'Hybrid', 'Flexible'],
    ));
  }

  void _addLostFoundQuestions() {
    _questions.add(ClarificationQuestion(
      key: 'when',
      question: 'When did this happen?',
      type: QuestionType.choice,
      options: ['Today', 'Yesterday', 'This Week', 'This Month', 'Earlier'],
    ));

    _questions.add(ClarificationQuestion(
      key: 'specificLocation',
      question: 'Where exactly?',
      type: QuestionType.text,
      hint: 'Be as specific as possible',
    ));

    _questions.add(ClarificationQuestion(
      key: 'reward',
      question: widget.detectedIntent == PostIntent.lost 
          ? 'Are you offering a reward?' 
          : 'Are you expecting a reward?',
      type: QuestionType.yesNo,
    ));
  }

  void _addHousingQuestions() {
    _questions.add(ClarificationQuestion(
      key: 'housingType',
      question: 'What type of housing?',
      type: QuestionType.choice,
      options: ['Room', 'Studio', '1 Bedroom', '2 Bedroom', '3+ Bedroom', 'House', 'Shared'],
    ));

    _questions.add(ClarificationQuestion(
      key: 'rent',
      question: widget.detectedIntent == PostIntent.renting 
          ? 'Monthly rent?' 
          : 'Budget range?',
      type: widget.detectedIntent == PostIntent.renting 
          ? QuestionType.price 
          : QuestionType.priceRange,
      hint: 'Monthly amount',
    ));

    _questions.add(ClarificationQuestion(
      key: 'availability',
      question: 'When available?',
      type: QuestionType.choice,
      options: ['Immediately', 'This Month', 'Next Month', 'Flexible'],
    ));

    _questions.add(ClarificationQuestion(
      key: 'pets',
      question: 'Pets allowed?',
      type: QuestionType.yesNo,
    ));
  }

  void _addGeneralQuestions() {
    _questions.add(ClarificationQuestion(
      key: 'location',
      question: 'Where are you located?',
      type: QuestionType.location,
      hint: 'Enter city or area',
    ));
  }

  Widget _buildCurrentQuestion() {
    if (_currentStep >= _questions.length) {
      return _buildSummary();
    }

    final question = _questions[_currentStep];
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (_currentStep + 1) / _questions.length,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 24),
        
        // Question
        Text(
          question.question,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        // Answer input
        _buildAnswerInput(question),
        
        const SizedBox(height: 24),
        
        // Navigation buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                child: const Text('Back'),
              )
            else
              const SizedBox.shrink(),
            
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    // Skip this question
                    setState(() {
                      _currentStep++;
                    });
                  },
                  child: const Text('Skip'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_validateAnswer(question)) {
                      setState(() {
                        _currentStep++;
                      });
                    }
                  },
                  child: Text(_currentStep < _questions.length - 1 ? 'Next' : 'Finish'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerInput(ClarificationQuestion question) {
    switch (question.type) {
      case QuestionType.choice:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: question.options!.map((option) {
            final isSelected = _answers[question.key] == option;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _answers[question.key] = selected ? option : null;
                });
              },
            );
          }).toList(),
        );
        
      case QuestionType.multiChoice:
        final selected = (_answers[question.key] as List<String>?) ?? [];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: question.options!.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selected.add(option);
                  } else {
                    selected.remove(option);
                  }
                  _answers[question.key] = selected;
                });
              },
            );
          }).toList(),
        );
        
      case QuestionType.text:
      case QuestionType.location:
        return TextField(
          decoration: InputDecoration(
            hintText: question.hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            _answers[question.key] = value;
          },
        );
        
      case QuestionType.price:
        return TextField(
          decoration: InputDecoration(
            hintText: question.hint,
            prefixText: '\$',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _answers[question.key] = double.tryParse(value);
          },
        );
        
      case QuestionType.priceRange:
        return Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Min',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final range = _answers[question.key] ?? {};
                  range['min'] = double.tryParse(value);
                  _answers[question.key] = range;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Max',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final range = _answers[question.key] ?? {};
                  range['max'] = double.tryParse(value);
                  _answers[question.key] = range;
                },
              ),
            ),
          ],
        );
        
      case QuestionType.yesNo:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Yes'),
              selected: _answers[question.key] == true,
              onSelected: (selected) {
                setState(() {
                  _answers[question.key] = selected ? true : null;
                });
              },
            ),
            const SizedBox(width: 16),
            ChoiceChip(
              label: const Text('No'),
              selected: _answers[question.key] == false,
              onSelected: (selected) {
                setState(() {
                  _answers[question.key] = selected ? false : null;
                });
              },
            ),
          ],
        );
    }
  }

  bool _validateAnswer(ClarificationQuestion question) {
    // Optional validation logic
    return true;
  }

  Widget _buildSummary() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Great! Here\'s what we\'ve gathered:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${widget.initialPrompt}"',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              ..._answers.entries.map((entry) {
                final question = _questions.firstWhere((q) => q.key == entry.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, size: 16, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${question.question}: ${_formatAnswer(entry.value)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                });
              },
              child: const Text('Edit Answers'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onComplete(_answers);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Post Now'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatAnswer(dynamic value) {
    if (value is List) {
      return value.join(', ');
    } else if (value is Map) {
      if (value.containsKey('min') && value.containsKey('max')) {
        return '\$${value['min']} - \$${value['max']}';
      }
    } else if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: _buildCurrentQuestion(),
        ),
      ),
    );
  }
}

class ClarificationQuestion {
  final String key;
  final String question;
  final QuestionType type;
  final List<String>? options;
  final String? hint;

  ClarificationQuestion({
    required this.key,
    required this.question,
    required this.type,
    this.options,
    this.hint,
  });
}

enum QuestionType {
  choice,
  multiChoice,
  text,
  price,
  priceRange,
  location,
  yesNo,
}