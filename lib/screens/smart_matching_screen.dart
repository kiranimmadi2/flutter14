import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/smart_intent_matcher.dart';
import '../models/user_profile.dart';
import 'enhanced_chat_screen.dart';

class SmartMatchingScreen extends StatefulWidget {
  const SmartMatchingScreen({Key? key}) : super(key: key);

  @override
  State<SmartMatchingScreen> createState() => _SmartMatchingScreenState();
}

class _SmartMatchingScreenState extends State<SmartMatchingScreen> {
  final SmartIntentMatcher _matcher = SmartIntentMatcher();
  final TextEditingController _intentController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _matchResult;
  List<Map<String, dynamic>> _matches = [];
  String _userIntent = '';
  String _lookingFor = '';

  @override
  void dispose() {
    _intentController.dispose();
    super.dispose();
  }

  Future<void> _findMatches() async {
    if (_intentController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _matches = [];
    });
    
    HapticFeedback.mediumImpact();
    
    try {
      final result = await _matcher.matchIntent(_intentController.text);
      
      if (result['success'] == true) {
        setState(() {
          _matchResult = result;
          _userIntent = result['userIntent']?['searchText'] ?? _intentController.text;
          _lookingFor = result['lookingFor']?['searchText'] ?? '';
          _matches = List<Map<String, dynamic>>.from(result['matches'] ?? []);
        });
      } else {
        _showError('Unable to process your request. Please try again.');
      }
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openChat(Map<String, dynamic> match) {
    final user = UserProfile(
      uid: match['userId'],
      name: match['user']['name'] ?? 'User',
      email: '',
      photoUrl: match['user']['photoUrl'] ?? '',
      location: match['user']['city'] ?? '',
      isVerified: match['user']['verified'] ?? false,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedChatScreen(
          otherUser: user,
          initialMessage: 'Hi! I saw your post about: ${match['searchText']}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Smart Matching',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What are you looking for?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Just tell us in your own words - no categories needed!',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _intentController,
                        maxLines: 2,
                        minLines: 1,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _findMatches(),
                        decoration: InputDecoration(
                          hintText: 'e.g., "Selling iPhone 13", "Need a plumber", '
                                   '"Looking for tennis partner", "Want to learn Spanish"...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.black : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        onPressed: _isLoading ? null : _findMatches,
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Icon(Icons.search, color: Colors.white),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
                
                // Example prompts
                if (_matches.isEmpty && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Selling my car',
                        'Need a babysitter',
                        'Looking for gym buddy',
                        'Have extra concert tickets',
                      ].map((example) => InkWell(
                        onTap: () {
                          _intentController.text = example;
                          _findMatches();
                        },
                        child: Chip(
                          label: Text(
                            example,
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: isDark 
                              ? Colors.grey[800] 
                              : Colors.blue.withValues(alpha: 0.1),
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
          
          // Understanding Display
          if (_userIntent.isNotEmpty && _lookingFor.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'I understand!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You want to: $_userIntent',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Finding people who: $_lookingFor',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          
          // Matches List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Finding perfect matches...'),
                      ],
                    ),
                  )
                : _matches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _intentController.text.isEmpty
                                  ? 'Tell us what you need'
                                  : 'No matches found yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_intentController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Check back later or try different keywords',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _matches.length,
                        itemBuilder: (context, index) {
                          final match = _matches[index];
                          final similarity = (match['similarity'] * 100).toInt();
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: isDark ? Colors.grey[900] : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark 
                                    ? Colors.grey[800]! 
                                    : Colors.grey[200]!,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _openChat(match),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // User Avatar
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: match['user']['photoUrl'] != null
                                          ? NetworkImage(match['user']['photoUrl'])
                                          : null,
                                      child: match['user']['photoUrl'] == null
                                          ? Icon(Icons.person, size: 30)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    // Match Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                match['user']['name'] ?? 'User',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (match['user']['verified'] == true)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 4),
                                                  child: Icon(
                                                    Icons.verified,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            match['searchText'] ?? '',
                                            style: TextStyle(
                                              color: isDark 
                                                  ? Colors.grey[400] 
                                                  : Colors.grey[700],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '$similarity% match',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (match['user']['city'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 8),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.location_on,
                                                        size: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        match['user']['city'],
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Chat Button
                                    IconButton(
                                      onPressed: () => _openChat(match),
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.blue, Colors.purple],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.chat,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}