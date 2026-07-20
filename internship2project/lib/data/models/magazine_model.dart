import 'article_model.dart';

/// Dergi modelleri — backend MagazineResponse / MagazineDetailResponse ile uyumlu.

class MagazineModel {
  final int id;
  final String title;
  final String? description;
  final int ownerId;
  final int articleCount;
  final String createdAt;

  const MagazineModel({
    required this.id,
    required this.title,
    this.description,
    required this.ownerId,
    required this.articleCount,
    required this.createdAt,
  });

  factory MagazineModel.fromJson(Map<String, dynamic> json) {
    return MagazineModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      ownerId: json['owner_id'] as int,
      articleCount: json['article_count'] as int,
      createdAt: json['created_at'] as String,
    );
  }
}

class MagazineDetailModel extends MagazineModel {
  final List<ArticleModel> articles;

  const MagazineDetailModel({
    required super.id,
    required super.title,
    super.description,
    required super.ownerId,
    required super.articleCount,
    required super.createdAt,
    required this.articles,
  });

  factory MagazineDetailModel.fromJson(Map<String, dynamic> json) {
    return MagazineDetailModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      ownerId: json['owner_id'] as int,
      articleCount: json['article_count'] as int,
      createdAt: json['created_at'] as String,
      articles: (json['articles'] as List<dynamic>)
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
