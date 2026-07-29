import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CommentModel {
  final int id;
  final String authorName;
  final String? profilePicture;
  final String content;
  final String createdAt;
  final List<CommentModel> replies;
  final int? parentId;

  CommentModel({
    required this.id,
    required this.authorName,
    this.profilePicture,
    required this.content,
    required this.createdAt,
    this.replies = const [],
    this.parentId,
  });
}

class CommentTreeWidget extends StatelessWidget {
  final List<CommentModel> comments;
  final Function(int? parentId) onReply;

  const CommentTreeWidget({
    super.key,
    required this.comments,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Henüz yorum yapılmamış.', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        return _buildCommentNode(comments[index], 0);
      },
    );
  }

  Widget _buildCommentNode(CommentModel comment, int depth) {
    // Sınırla girintiyi
    final double paddingLeft = (depth > 5 ? 5 : depth) * 16.0;

    return Padding(
      padding: EdgeInsets.only(left: paddingLeft, top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.divider,
                backgroundImage: comment.profilePicture != null && comment.profilePicture!.isNotEmpty
                    ? NetworkImage(comment.profilePicture!)
                    : null,
                child: comment.profilePicture == null || comment.profilePicture!.isEmpty
                    ? const Icon(Icons.person, size: 16, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: depth % 2 == 0 ? AppTheme.surface : AppTheme.background,
                    border: Border.all(color: AppTheme.divider),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            comment.authorName,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                          ),
                          Text(
                            _formatDate(comment.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(comment.content, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => onReply(comment.id),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text('Yanıtla', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            ...comment.replies.map((reply) => _buildCommentNode(reply, depth + 1)).toList(),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}
