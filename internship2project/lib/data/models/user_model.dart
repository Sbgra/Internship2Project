import 'package:intl/intl.dart';

class UserPublicModel {
  final int id;
  final String username;
  final String? bio;
  final String? profilePicture;
  final String? profileColor;
  final String? emotes;
  final DateTime createdAt;

  const UserPublicModel({
    required this.id,
    required this.username,
    this.bio,
    this.profilePicture,
    this.profileColor,
    this.emotes,
    required this.createdAt,
  });

  factory UserPublicModel.fromJson(Map<String, dynamic> json) {
    return UserPublicModel(
      id: json['id'] as int,
      username: json['username'] as String,
      bio: json['bio'] as String?,
      profilePicture: json['profile_picture'] as String?,
      profileColor: json['profile_color'] as String?,
      emotes: json['emotes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// "Ocak 2024" formatında katılım tarihi
  String get joinedFormatted =>
      DateFormat.yMMMM('tr_TR').format(createdAt);
}

class UserProfileModel {
  final int id;
  final String username;
  final String email;
  final String? bio;
  final String? profilePicture;
  final String? profileColor;
  final String? emotes;
  final DateTime createdAt;
  final int articleCount;

  const UserProfileModel({
    required this.id,
    required this.username,
    required this.email,
    this.bio,
    this.profilePicture,
    this.profileColor,
    this.emotes,
    required this.createdAt,
    required this.articleCount,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String?,
      profilePicture: json['profile_picture'] as String?,
      profileColor: json['profile_color'] as String?,
      emotes: json['emotes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      articleCount: json['article_count'] as int? ?? 0,
    );
  }

  String get joinedFormatted =>
      DateFormat.yMMMM('tr_TR').format(createdAt);

  /// Avatar için kullanıcı adının baş harfleri
  String get initials {
    final parts = username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase();
  }
}
