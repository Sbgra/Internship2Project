import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/article_model.dart';

/// Basit makale kartı — sadece başlık, özet, yazar ve tarih.
class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback? onTap;

  const ArticleCard({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Yazar
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .pushNamed('/profile', arguments: article.authorId),
              child: Text(
                article.author.username,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Başlık
            Text(
              article.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Özet
            if (article.summary != null && article.summary!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                article.summary!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 8),

            // Tarih
            Text(
              article.formattedDate,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}
