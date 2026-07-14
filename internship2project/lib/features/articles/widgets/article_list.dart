import 'package:flutter/material.dart';
import '../../../data/models/article_model.dart';
import '../../feed/widgets/article_card.dart';

/// Yeniden kullanılabilir makale listesi bileşeni.
/// Feed ve profil ekranlarında kullanılır.
class ArticleList extends StatelessWidget {
  final List<ArticleModel> articles;
  final String emptyMessage;
  final EdgeInsets padding;

  const ArticleList({
    super.key,
    required this.articles,
    this.emptyMessage = 'Makale bulunamadı',
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories_outlined,
                size: 56, color: Color(0xFF55555F)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF8A8A99),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: padding,
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return ArticleCard(
          article: article,
          onTap: () => Navigator.of(context).pushNamed(
            '/article',
            arguments: article.id,
          ),
        );
      },
    );
  }
}
