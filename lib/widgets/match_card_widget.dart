import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ai_post_model.dart';
import '../models/user_profile.dart';
import '../services/ai_matching_service.dart';
import 'connection_dialog.dart';

/// Reusable widget for displaying individual matches
/// Handles all match card UI states and interactions
class MatchCardWidget extends StatefulWidget {
  final MatchedUser match;
  final VoidCallback? onViewProfile;
  final VoidCallback? onConnect;
  final bool isConnected;
  final bool isPending;
  final bool showDebugInfo;

  const MatchCardWidget({
    Key? key,
    required this.match,
    this.onViewProfile,
    this.onConnect,
    this.isConnected = false,
    this.isPending = false,
    this.showDebugInfo = false,
  }) : super(key: key);

  @override
  State<MatchCardWidget> createState() => _MatchCardWidgetState();
}

class _MatchCardWidgetState extends State<MatchCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity >= 0.8) return Colors.green;
    if (similarity >= 0.6) return Colors.blue;
    if (similarity >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getSimilarityLabel(double similarity) {
    if (similarity >= 0.8) return 'Excellent';
    if (similarity >= 0.6) return 'Good';
    if (similarity >= 0.4) return 'Fair';
    return 'Low';
  }

  Widget _buildProfileImage() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _getSimilarityColor(widget.match.matchScore.totalScore),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey[200],
        child: widget.match.profile.profileImageUrl != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.match.profile.profileImageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, size: 30),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: Text(
                      widget.match.profile.name.isNotEmpty
                          ? widget.match.profile.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )
            : Text(
                widget.match.profile.name.isNotEmpty
                    ? widget.match.profile.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSimilarityBadge() {
    final score = widget.match.matchScore.totalScore;
    final percentage = (score * 100).round();
    final color = _getSimilarityColor(score);
    final label = _getSimilarityLabel(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage% $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionButton() {
    if (widget.isConnected) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 16),
        label: const Text('Connected'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    if (widget.isPending) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        label: const Text('Pending'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _handleConnect(context),
      icon: const Icon(Icons.chat, size: 16),
      label: const Text('Connect'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleConnect(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConnectionDialog(
        matchedUser: widget.match,
        onConnect: widget.onConnect,
      ),
    );
  }

  Widget _buildDebugInfo() {
    if (!widget.showDebugInfo) return const SizedBox.shrink();

    final score = widget.match.matchScore;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Info',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          _buildDebugRow('AI Compatibility', score.aiCompatibility),
          _buildDebugRow('Semantic Similarity', score.semanticSimilarity),
          _buildDebugRow('Location Proximity', score.locationProximity),
          _buildDebugRow('Timing Alignment', score.timingAlignment),
          _buildDebugRow('Keyword Match', score.keywordMatch),
          if (score.reasons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Reasons: ${score.reasons.join(", ")}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, double value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getSimilarityColor(value),
            ),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      onTap: widget.onViewProfile,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isPressed ? 0.1 : 0.05),
                    blurRadius: _isPressed ? 8 : 4,
                    offset: Offset(0, _isPressed ? 4 : 2),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with profile and similarity
                      Row(
                        children: [
                          _buildProfileImage(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.match.profile.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _buildSimilarityBadge(),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (widget.match.profile.bio.isNotEmpty)
                                  Text(
                                    widget.match.profile.bio,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Original post preview
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.match.post.displayTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.match.post.originalPrompt,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onViewProfile,
                              icon: const Icon(Icons.person, size: 16),
                              label: const Text('Profile'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildConnectionButton(),
                          ),
                        ],
                      ),

                      // Debug information (only shown if enabled)
                      _buildDebugInfo(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}