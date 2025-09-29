import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SimpleIntentDialog extends StatefulWidget {
  final String initialInput;
  final Function(String) onComplete;

  const SimpleIntentDialog({
    Key? key,
    required this.initialInput,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<SimpleIntentDialog> createState() => _SimpleIntentDialogState();
}

class _SimpleIntentDialogState extends State<SimpleIntentDialog> {
  String? _selectedCategory;
  String? _refinedIntent;
  int _currentStep = 0;
  
  // Smart category detection based on input
  Map<String, dynamic> _detectCategory(String input) {
    final lowercaseInput = input.toLowerCase();
    
    // Product/Shopping keywords
    if (lowercaseInput.contains('buy') || lowercaseInput.contains('sell') ||
        lowercaseInput.contains('iphone') || lowercaseInput.contains('phone') ||
        lowercaseInput.contains('laptop') || lowercaseInput.contains('car') ||
        lowercaseInput.contains('bike') || lowercaseInput.contains('product') ||
        lowercaseInput.contains('electronics') || lowercaseInput.contains('gadget')) {
      return {'category': 'product', 'confidence': 0.9};
    }
    
    // Job/Work keywords
    if (lowercaseInput.contains('job') || lowercaseInput.contains('work') ||
        lowercaseInput.contains('hire') || lowercaseInput.contains('employ') ||
        lowercaseInput.contains('freelance') || lowercaseInput.contains('career') ||
        lowercaseInput.contains('vacancy') || lowercaseInput.contains('position')) {
      return {'category': 'job', 'confidence': 0.9};
    }
    
    // Housing/Rental keywords
    if (lowercaseInput.contains('rent') || lowercaseInput.contains('apartment') ||
        lowercaseInput.contains('house') || lowercaseInput.contains('room') ||
        lowercaseInput.contains('flat') || lowercaseInput.contains('accommodation') ||
        lowercaseInput.contains('lease') || lowercaseInput.contains('property')) {
      return {'category': 'housing', 'confidence': 0.9};
    }
    
    // Service keywords
    if (lowercaseInput.contains('service') || lowercaseInput.contains('repair') ||
        lowercaseInput.contains('fix') || lowercaseInput.contains('plumber') ||
        lowercaseInput.contains('electrician') || lowercaseInput.contains('tutor') ||
        lowercaseInput.contains('help') || lowercaseInput.contains('assist')) {
      return {'category': 'service', 'confidence': 0.9};
    }
    
    // If no clear category, ask for clarification
    return {'category': null, 'confidence': 0.0};
  }

  @override
  void initState() {
    super.initState();
    final detection = _detectCategory(widget.initialInput);
    
    if (detection['confidence'] > 0.7) {
      // High confidence - skip to refinement
      _selectedCategory = detection['category'];
      _currentStep = 1;
      _refinedIntent = widget.initialInput;
    }
  }

  Widget _buildCategorySelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'What are you looking for?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildChoiceChip('🛍️ Product', 'product'),
            _buildChoiceChip('💼 Job', 'job'),
            _buildChoiceChip('🏠 Housing', 'housing'),
            _buildChoiceChip('🔧 Service', 'service'),
          ],
        ),
      ],
    );
  }

  Widget _buildRefinement() {
    List<String> quickOptions = [];
    
    switch (_selectedCategory) {
      case 'product':
        quickOptions = ['Buy', 'Sell', 'Exchange'];
        break;
      case 'job':
        quickOptions = ['Find job', 'Hire someone'];
        break;
      case 'housing':
        quickOptions = ['Rent', 'Roommate', 'Short-term'];
        break;
      case 'service':
        quickOptions = ['Need service', 'Offer service'];
        break;
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Almost done! Choose an option or describe what you need:',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (quickOptions.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickOptions.map((option) => 
              OutlinedButton(
                onPressed: () {
                  final refined = '${widget.initialInput} $option';
                  widget.onComplete(refined);
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(option),
              ),
            ).toList(),
          ),
          const SizedBox(height: 16),
        ],
        ElevatedButton.icon(
          onPressed: () {
            widget.onComplete(_refinedIntent ?? widget.initialInput);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.search),
          label: const Text('Search Now'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedCategory = value;
          _currentStep = 1;
          _refinedIntent = '${widget.initialInput} $value';
        });
      },
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1F2C33) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Let me help you',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.initialInput,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentStep == 0 
                  ? _buildCategorySelection()
                  : _buildRefinement(),
            ),
            const SizedBox(height: 16),
            if (_currentStep == 0)
              TextButton(
                onPressed: () {
                  widget.onComplete(widget.initialInput);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: isDarkMode ? Colors.blue[300] : Colors.blue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}