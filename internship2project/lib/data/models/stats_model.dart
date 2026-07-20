/// Makale istatistik modeli — backend ArticleStatsResponse ile uyumlu.
class ArticleStatsModel {
  final int articleId;
  final int viewCount;
  final int clapCount;

  const ArticleStatsModel({
    required this.articleId,
    required this.viewCount,
    required this.clapCount,
  });

  factory ArticleStatsModel.fromJson(Map<String, dynamic> json) {
    return ArticleStatsModel(
      articleId: json['article_id'] as int,
      viewCount: json['view_count'] as int,
      clapCount: json['clap_count'] as int,
    );
  }
}

/// Alkış sonucu modeli — backend ClapResponse ile uyumlu.
class ClapResultModel {
  final int articleId;
  final int totalClaps;
  final int userClaps;
  final int remainingClaps;

  const ClapResultModel({
    required this.articleId,
    required this.totalClaps,
    required this.userClaps,
    required this.remainingClaps,
  });

  factory ClapResultModel.fromJson(Map<String, dynamic> json) {
    return ClapResultModel(
      articleId: json['article_id'] as int,
      totalClaps: json['total_claps'] as int,
      userClaps: json['user_claps'] as int,
      remainingClaps: json['remaining_claps'] as int,
    );
  }
}
