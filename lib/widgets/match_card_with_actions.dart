import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/enhanced_chat_screen.dart';
import '../screens/profile_view_screen.dart';
import '../models/user_profile.dart';
// Call functionality removed

class MatchCardWithActions extends StatelessWidget {
  final Map<String, dynamic> match;
  final VoidCallback? onTap;

  const MatchCardWithActions({
    Key? key,
    required this.match,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDark ? 8 : 4,
      shadowColor: theme.primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap ?? () => _viewProfile(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      theme.cardColor,
                      theme.cardColor.withOpacity(0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Row
              Row(
                children: [
                  // Avatar with error handling
                  Hero(
                    tag: 'avatar_${match['userId'] ?? 'unknown'}',
                    child: Builder(
                      builder: (context) {
                        final photoUrl = match['userProfile']?['photoUrl']?.toString().trim();
                        final hasValidPhoto = photoUrl != null && photoUrl.isNotEmpty;

                        return CircleAvatar(
                          radius: 28,
                          backgroundImage: hasValidPhoto
                              ? CachedNetworkImageProvider(photoUrl!)
                              : null,
                          onBackgroundImageError: hasValidPhoto
                              ? (exception, stackTrace) {
                                  print('Failed to load avatar image: $exception');
                                }
                              : null,
                          child: !hasValidPhoto
                              ? Icon(Icons.person, size: 28)
                              : null,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  
                  // Name and Location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (match['userName']?.toString().trim().isNotEmpty == true)
                              ? match['userName'].toString().trim()
                              : 'Anonymous User',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Builder(
                          builder: (context) {
                            final location = match['location']?.toString().trim() ?? '';
                            if (location.isEmpty) return SizedBox.shrink();

                            return Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Match Score with null safety
                  if (match['similarity'] != null &&
                      match['similarity'] is num &&
                      (match['similarity'] as num).isFinite)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getScoreColor(match['similarity']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getScoreColor(match['similarity']),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: _getScoreColor(match['similarity']),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${((match['similarity'] as num) * 100).clamp(0, 100).toInt()}%',
                            style: TextStyle(
                              color: _getScoreColor(match['similarity']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              // Intent/Description with better null safety
              Builder(
                builder: (context) {
                  final text = match['text']?.toString().trim() ??
                      match['intent']?.toString().trim() ??
                      match['description']?.toString().trim() ??
                      '';

                  if (text.isEmpty) return SizedBox.shrink();

                  return Container(
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      text,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
              
              // Action Buttons Row
              Container(
                margin: EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    // Chat Button
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        color: theme.primaryColor,
                        onTap: () => _startChat(context),
                      ),
                    ),
                    SizedBox(width: 8),
                    
                    // Call Button
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.call_outlined,
                        label: 'Call',
                        color: Colors.green,
                        onTap: () => _showCallDisabled(context),
                      ),
                    ),
                    SizedBox(width: 8),
                    
                    // View Profile Button
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        color: Colors.orange,
                        onTap: () => _viewProfile(context),
                      ),
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

  Color _getScoreColor(double score) {
    if (score >= 0.9) return Colors.green;
    if (score >= 0.8) return Colors.teal;
    if (score >= 0.7) return Colors.orange;
    return Colors.grey;
  }

  Future<void> _startChat(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Get receiver's full profile
    final receiverDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(match['userId'])
        .get();

    if (!receiverDoc.exists) return;

    final receiver = UserProfile.fromFirestore(receiverDoc);

    // Navigate to chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedChatScreen(
          otherUser: receiver,
        ),
      ),
    );
  }

  void _showCallDisabled(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call feature has been disabled'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _viewProfile(BuildContext context) async {
    // Get full user profile
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(match['userId'])
        .get();

    if (!userDoc.exists) return;

    final profile = UserProfile.fromFirestore(userDoc);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileViewScreen(
          userProfile: profile,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}