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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Yazar Bilgisi Satırı
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/profile', arguments: article.authorId),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.divider,
                    child: Text(
                      article.author.username.isNotEmpty ? article.author.username[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    article.author.username,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // İçerik ve Görsel Satırı
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık
                      Text(
                        article.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20, // Medium başlıkları büyüktür
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Özet
                      if (article.summary != null && article.summary!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          article.summary!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Kapak Görseli
                if (article.coverImage != null && article.coverImage!.isNotEmpty) ...[
                  const SizedBox(width: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4), // Hafif kavisli
                    child: Image.network(
                      article.coverImage!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const SizedBox(width: 100, height: 100),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Tarih ve Alt Bilgiler Satırı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  article.formattedDate,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Icon(
                  Icons.bookmark_border_rounded,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppTheme.divider),
          ],
        ),
      ),
    );
  }
}
