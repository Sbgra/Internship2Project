import 'package:intl/intl.dart';
import 'user_model.dart';

class ArticleModel {
  final int id;
  final String title;
  final String? summary;
  final bool isPublic;
  final int authorId;
  final UserPublicModel author;
  final DateTime createdAt;

  const ArticleModel({
    required this.id,
    required this.title,
    this.summary,
    required this.isPublic,
    required this.authorId,
    required this.author,
    required this.createdAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as int,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      isPublic: json['is_public'] as bool,
      authorId: json['author_id'] as int,
      author: UserPublicModel.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// "14 Temmuz 2024" formatında tarih
  String get formattedDate =>
      DateFormat.yMMMMd('tr_TR').format(createdAt);

  /// Okunma süresi tahmini (200 kelime/dakika)
  String get readTime {
    final wordCount = summary?.split(' ').length ?? 0;
    final minutes = (wordCount / 200).ceil();
    return minutes <= 1 ? '1 dk okuma' : '$minutes dk okuma';
  }
}

class ArticleDetailModel extends ArticleModel {
  final String content;
  final DateTime? updatedAt;

  const ArticleDetailModel({
    required super.id,
    required super.title,
    super.summary,
    required super.isPublic,
    required super.authorId,
    required super.author,
    required super.createdAt,
    required this.content,
    this.updatedAt,
  });

  factory ArticleDetailModel.fromJson(Map<String, dynamic> json) {
    return ArticleDetailModel(
      id: json['id'] as int,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      isPublic: json['is_public'] as bool,
      authorId: json['author_id'] as int,
      author: UserPublicModel.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      content: json['content'] as String,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  String get readTime {
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return minutes <= 1 ? '1 dk okuma' : '$minutes dk okuma';
  }
}
