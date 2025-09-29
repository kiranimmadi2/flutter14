import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/enhanced_ai_matching_screen.dart';
import '../screens/enhanced_universal_matching_screen.dart';
import '../models/ai_post_model.dart';
import '../services/ai_matching_service.dart';
import '../services/fixed_ai_matching_service.dart';
import '../services/debug_service.dart';

/// Helper class to integrate the new UI components with existing app structure
/// Provides easy navigation and state management for the matching system
class UIIntegrationHelper {
  /// Navigate to enhanced matching screen with proper setup
  static Future<void> navigateToMatching(
    BuildContext context, {
    List<MatchedUser>? initialMatches,
    String? userQuery,
    AIPostModel? userPost,
    bool showDebugInfo = false,
  }) async {
    DebugService.log('UI_INTEGRATION', 'navigateToMatching',
        'Navigating to matching screen',
        data: {
          'has_initial_matches': initialMatches != null,
          'user_query': userQuery,
          'has_user_post': userPost != null,
          'debug_enabled': showDebugInfo,
        });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedAIMatchingScreen(
          initialMatches: initialMatches,
          userQuery: userQuery,
          userPost: userPost,
          showDebugInfo: showDebugInfo,
        ),
      ),
    );
  }

  /// Navigate to enhanced universal matching screen
  static Future<void> navigateToUniversalMatching(BuildContext context) async {
    DebugService.log('UI_INTEGRATION', 'navigateToUniversalMatching',
        'Navigating to universal matching screen');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedUniversalMatchingScreen(),
      ),
    );
  }

  /// Create post and automatically navigate to matching results
  static Future<void> createPostAndMatch(
    BuildContext context,
    String userInput, {
    bool showDebugInfo = false,
  }) async {
    if (userInput.trim().isEmpty) {
      _showSnackBar(context, 'Please enter something to search for', Colors.orange);
      return;
    }

    try {
      DebugService.log('UI_INTEGRATION', 'createPostAndMatch',
          'Creating post and finding matches',
          data: {'input': userInput});

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating your post and finding matches...'),
                ],
              ),
            ),
          ),
        ),
      );

      final matchingService = FixedAIMatchingService();
      await matchingService.initialize();

      // Create post
      final postId = await matchingService.createPost(userInput);

      if (postId == null) {
        throw Exception('Failed to create post');
      }

      // Get the created post
      final postDoc = await FirebaseFirestore.instance
          .collection('ai_posts')
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        throw Exception('Post not found after creation');
      }

      final createdPost = AIPostModel.fromFirestore(postDoc);

      // Find matches
      final matches = await matchingService.findBestPeople(createdPost);

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      _showSnackBar(context, 'Post created successfully! Found ${matches.length} matches', Colors.green);

      // Navigate to matching results
      await navigateToMatching(
        context,
        initialMatches: matches,
        userQuery: userInput,
        userPost: createdPost,
        showDebugInfo: showDebugInfo,
      );

    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);

      DebugService.log('UI_INTEGRATION', 'createPostAndMatch',
          'Error creating post and matching',
          data: {'error': e.toString()});

      _showSnackBar(context, 'Error: ${e.toString()}', Colors.red);
    }
  }

  /// Show snack bar with consistent styling
  static void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Get appropriate icon for match score
  static IconData getMatchScoreIcon(double score) {
    if (score >= 0.8) return Icons.favorite;
    if (score >= 0.6) return Icons.star;
    if (score >= 0.4) return Icons.thumb_up;
    return Icons.explore;
  }

  /// Get appropriate color for match score
  static Color getMatchScoreColor(double score) {
    if (score >= 0.8) return Colors.red;
    if (score >= 0.6) return Colors.green;
    if (score >= 0.4) return Colors.blue;
    return Colors.orange;
  }

  /// Get match score label
  static String getMatchScoreLabel(double score) {
    if (score >= 0.8) return 'Perfect Match';
    if (score >= 0.6) return 'Great Match';
    if (score >= 0.4) return 'Good Match';
    return 'Potential Match';
  }

  /// Format match percentage for display
  static String formatMatchPercentage(double score) {
    return '${(score * 100).round()}%';
  }

  /// Create a themed card decoration
  static BoxDecoration createCardDecoration({
    Color? color,
    double elevation = 2,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }

  /// Create a gradient background for special elements
  static BoxDecoration createGradientDecoration({
    List<Color>? colors,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? [Colors.blue[50]!, Colors.purple[50]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
    );
  }

  /// Show confirmation dialog before performing an action
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show info dialog with match details
  static void showMatchInfoDialog(
    BuildContext context,
    MatchedUser match,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: match.profile.profileImageUrl != null
                  ? NetworkImage(match.profile.profileImageUrl!)
                  : null,
              child: match.profile.profileImageUrl == null
                  ? Text(match.profile.name[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                match.profile.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Match Score: ${formatMatchPercentage(match.matchScore.totalScore)}'),
            const SizedBox(height: 8),
            Text('Post: ${match.post.originalPrompt}'),
            if (match.matchScore.reasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Why you match:'),
              ...match.matchScore.reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• $reason', style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Extension methods for easier integration
extension UIIntegrationExtension on BuildContext {
  /// Quick navigation to matching screen
  Future<void> navigateToMatching({
    List<MatchedUser>? matches,
    String? query,
    AIPostModel? post,
    bool debug = false,
  }) async {
    await UIIntegrationHelper.navigateToMatching(
      this,
      initialMatches: matches,
      userQuery: query,
      userPost: post,
      showDebugInfo: debug,
    );
  }

  /// Quick navigation to universal matching
  Future<void> navigateToUniversalMatching() async {
    await UIIntegrationHelper.navigateToUniversalMatching(this);
  }

  /// Quick post creation and matching
  Future<void> createPostAndMatch(String input, {bool debug = false}) async {
    await UIIntegrationHelper.createPostAndMatch(this, input, showDebugInfo: debug);
  }

  /// Show match info dialog
  void showMatchInfo(MatchedUser match) {
    UIIntegrationHelper.showMatchInfoDialog(this, match);
  }
}