import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_post_model.dart';
import '../services/ai_matching_service.dart';
import '../services/conversation_service.dart';
import '../services/notification_service.dart';

/// Confirmation dialog for sending connection requests
/// Handles the entire connection flow with proper error handling
class ConnectionDialog extends StatefulWidget {
  final MatchedUser matchedUser;
  final VoidCallback? onConnect;
  final bool showConversationStarter;

  const ConnectionDialog({
    Key? key,
    required this.matchedUser,
    this.onConnect,
    this.showConversationStarter = true,
  }) : super(key: key);

  @override
  State<ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<ConnectionDialog>
    with SingleTickerProviderStateMixin {
  final ConversationService _conversationService = ConversationService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isConnecting = false;
  bool _connectionSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Please log in to connect with other users');
      }

      // Create or get existing conversation
      final conversationId = await _conversationService.createOrGetConversation(
        currentUser.uid,
        widget.matchedUser.profile.uid,
      );

      // Send push notification to matched user
      if (widget.matchedUser.profile.fcmToken != null) {
        await _notificationService.sendPushNotification(
          recipientToken: widget.matchedUser.profile.fcmToken!,
          title: '🎯 New Connection Request!',
          body: '${currentUser.displayName ?? 'Someone'} wants to connect with you',
          data: {
            'type': 'connection_request',
            'senderId': currentUser.uid,
            'senderName': currentUser.displayName ?? 'Unknown',
            'conversationId': conversationId,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      // Show success state
      setState(() {
        _connectionSuccess = true;
        _isConnecting = false;
      });

      // Call success callback
      widget.onConnect?.call();

      // Auto-close after showing success
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }

    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = e.toString();
      });
    }
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: widget.matchedUser.profile.profileImageUrl != null
              ? NetworkImage(widget.matchedUser.profile.profileImageUrl!)
              : null,
          child: widget.matchedUser.profile.profileImageUrl == null
              ? Text(
                  widget.matchedUser.profile.name.isNotEmpty
                      ? widget.matchedUser.profile.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.matchedUser.profile.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.matchedUser.profile.bio.isNotEmpty)
                Text(
                  widget.matchedUser.profile.bio,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getSimilarityColor(widget.matchedUser.matchScore.totalScore),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${(widget.matchedUser.matchScore.totalScore * 100).toInt()}% Match',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity >= 0.8) return Colors.green;
    if (similarity >= 0.6) return Colors.blue;
    if (similarity >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMatchPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Their Post',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.matchedUser.post.originalPrompt,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue[800],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationStarter() {
    if (!widget.showConversationStarter) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.pink[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 16, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Text(
                'Conversation Starter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hi! I saw your post about "${widget.matchedUser.post.displayTitle}" and I think we might be able to help each other. Let\'s chat!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.purple[800],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_connectionSuccess) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green[700],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Connection Request Sent!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You\'ll be notified when they respond.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[700],
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connection Failed',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleConnect,
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isConnecting ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isConnecting ? null : _handleConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isConnecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Connect'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            Icons.connect_without_contact,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Send Connection Request?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _isConnecting ? null : () => Navigator.of(context).pop(false),
                            icon: const Icon(Icons.close, size: 20),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Profile header
                      _buildProfileHeader(),

                      const SizedBox(height: 16),

                      // Match preview
                      _buildMatchPreview(),

                      const SizedBox(height: 12),

                      // Conversation starter
                      _buildConversationStarter(),

                      const SizedBox(height: 20),

                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}