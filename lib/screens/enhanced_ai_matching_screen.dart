import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/ai_matching_service.dart';
import '../services/fixed_ai_matching_service.dart';
import '../services/conversation_service.dart';
import '../models/user_profile.dart';
import '../models/ai_post_model.dart';
import '../widgets/match_card_widget.dart';
import '../screens/profile_view_screen.dart';
import '../screens/chat_screen.dart';
import '../utils/matching_system_tester.dart';
import '../services/debug_service.dart';
import '../widgets/connection_dialog.dart';

/// Enhanced AI-powered matching screen with complete UI flow
/// Displays matches from backend with real-time updates and connection features
class EnhancedAIMatchingScreen extends StatefulWidget {
  final List<MatchedUser>? initialMatches;
  final String? userQuery;
  final AIPostModel? userPost;
  final bool showDebugInfo;

  const EnhancedAIMatchingScreen({
    super.key,
    this.initialMatches,
    this.userQuery,
    this.userPost,
    this.showDebugInfo = false,
  });

  @override
  State<EnhancedAIMatchingScreen> createState() => _EnhancedAIMatchingScreenState();
}

class _EnhancedAIMatchingScreenState extends State<EnhancedAIMatchingScreen>
    with TickerProviderStateMixin {
  final FixedAIMatchingService _matchingService = FixedAIMatchingService();
  final ConversationService _conversationService = ConversationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<MatchedUser> _matches = [];
  List<String> _connectedUserIds = [];
  List<String> _pendingUserIds = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _realtimeSubscription;
  late AnimationController _refreshController;
  late AnimationController _slideController;
  Timer? _refreshTimer;
  int _newMatchesBadge = 0;

  @override
  void initState() {
    super.initState();

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize with provided matches or load new ones
    if (widget.initialMatches != null) {
      _matches = widget.initialMatches!;
      _isLoading = false;
      _slideController.forward();
    } else {
      _loadMatches();
    }

    _setupRealtimeUpdates();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _slideController.dispose();
    _realtimeSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DebugService.log('MATCHING_UI', '_loadMatches', 'Loading matches for user');

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _matchingService.initialize();

      List<MatchedUser> matches = [];

      if (widget.userPost != null) {
        // Find matches for specific post
        matches = await _matchingService.findBestPeople(widget.userPost!);
      } else {
        // Get general match suggestions
        final suggestions = await _matchingService.getMatchSuggestions(userId);
        matches = suggestions.map((s) => s.matchedUser).toList();
      }

      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });

        _slideController.forward();

        DebugService.log('MATCHING_UI', '_loadMatches',
            'Loaded ${matches.length} matches successfully');
      }
    } catch (e) {
      DebugService.log('MATCHING_UI', '_loadMatches',
          'Error loading matches', data: {'error': e.toString()});

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _setupRealtimeUpdates() {
    // Listen for new matches in real-time
    _realtimeSubscription = Stream.periodic(const Duration(seconds: 30))
        .listen((_) => _checkForNewMatches());
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted && !_isLoading) {
        _loadMatches();
      }
    });
  }

  Future<void> _checkForNewMatches() async {
    if (_isLoading) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final suggestions = await _matchingService.getMatchSuggestions(userId);
      final newMatches = suggestions.map((s) => s.matchedUser).toList();

      if (newMatches.length > _matches.length) {
        if (mounted) {
          setState(() {
            _newMatchesBadge = newMatches.length - _matches.length;
            _matches = newMatches;
          });

          // Show notification for new matches
          _showNewMatchesNotification();
        }
      }
    } catch (e) {
      DebugService.log('MATCHING_UI', '_checkForNewMatches',
          'Error checking for new matches', data: {'error': e.toString()});
    }
  }

  void _showNewMatchesNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('$_newMatchesBadge new matches found!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _newMatchesBadge = 0;
            });
          },
        ),
      ),
    );
  }

  Future<void> _startConversation(MatchedUser match) async {
    try {
      setState(() {
        _pendingUserIds.add(match.profile.uid);
      });

      // Create or get existing conversation
      final conversationId = await _conversationService.createOrGetConversation(
        _auth.currentUser!.uid,
        match.profile.uid,
      );

      // Navigate to chat screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherUser: match.profile,
            ),
          ),
        );

        setState(() {
          _connectedUserIds.add(match.profile.uid);
          _pendingUserIds.remove(match.profile.uid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Connected with ${match.profile.name}!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _pendingUserIds.remove(match.profile.uid);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewProfile(MatchedUser match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileViewScreen(
          userProfile: match.profile,
          showConnectButton: true,
          onConnect: () => _startConversation(match),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.userPost != null
                ? 'Finding perfect matches for your post...'
                : 'AI is analyzing your preferences...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This usually takes a few seconds',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No matches found yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userQuery != null
                ? 'Try adjusting your search criteria'
                : 'Create more posts to get better matches!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _loadMatches,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Failed to load matches',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadMatches,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: FadeTransition(
        opacity: _slideController,
        child: RefreshIndicator(
          onRefresh: _loadMatches,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _matches.length,
            itemBuilder: (context, index) {
              final match = _matches[index];
              final isConnected = _connectedUserIds.contains(match.profile.uid);
              final isPending = _pendingUserIds.contains(match.profile.uid);

              return MatchCardWidget(
                match: match,
                isConnected: isConnected,
                isPending: isPending,
                showDebugInfo: widget.showDebugInfo,
                onViewProfile: () => _viewProfile(match),
                onConnect: () => _startConversation(match),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userQuery != null ? 'Search Results' : 'AI Matches',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_matches.isNotEmpty)
              Text(
                '${_matches.length} ${_matches.length == 1 ? 'match' : 'matches'} found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (_newMatchesBadge > 0)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite),
                onPressed: () {
                  setState(() {
                    _newMatchesBadge = 0;
                  });
                  _loadMatches();
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$_newMatchesBadge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        IconButton(
          icon: AnimatedBuilder(
            animation: _refreshController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshController.value * 2 * 3.14159,
                child: const Icon(Icons.refresh),
              );
            },
          ),
          onPressed: () {
            _refreshController.repeat();
            _loadMatches().then((_) {
              _refreshController.stop();
              _refreshController.reset();
            });
          },
        ),
        if (widget.showDebugInfo)
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => context.showQuickMatchingTest(),
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'debug_test':
                context.showQuickMatchingTest();
                break;
              case 'real_world_test':
                context.showRealWorldMatchingTest();
                break;
              case 'full_test':
                context.showFullMatchingTests();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'debug_test',
              child: Row(
                children: [
                  Icon(Icons.bug_report, size: 16),
                  SizedBox(width: 8),
                  Text('Quick Test'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'real_world_test',
              child: Row(
                children: [
                  Icon(Icons.psychology, size: 16),
                  SizedBox(width: 8),
                  Text('Real World Test'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'full_test',
              child: Row(
                children: [
                  Icon(Icons.science, size: 16),
                  SizedBox(width: 8),
                  Text('Full Test Suite'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverFillRemaining(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _matches.isEmpty
                        ? _buildEmptyState()
                        : _buildMatchesList(),
          ),
        ],
      ),
      floatingActionButton: _matches.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context),
              label: const Text('Create New Post'),
              icon: const Icon(Icons.add),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }
}