/// Topluluk modelleri — backend CommunityListItem / CommunityResponse ile uyumlu.

class CommunityListItemModel {
  final int id;
  final String name;
  final String? description;
  final int memberCount;
  final String createdAt;

  const CommunityListItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.memberCount,
    required this.createdAt,
  });

  factory CommunityListItemModel.fromJson(Map<String, dynamic> json) {
    return CommunityListItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      memberCount: json['member_count'] as int,
      createdAt: json['created_at'] as String,
    );
  }
}

class CommunityDetailModel {
  final int id;
  final String name;
  final String? description;
  final int memberCount;
  final int createdBy;
  final String createdAt;
  final bool isMember;

  const CommunityDetailModel({
    required this.id,
    required this.name,
    this.description,
    required this.memberCount,
    required this.createdBy,
    required this.createdAt,
    required this.isMember,
  });

  factory CommunityDetailModel.fromJson(Map<String, dynamic> json) {
    return CommunityDetailModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      memberCount: json['member_count'] as int,
      createdBy: json['created_by'] as int,
      createdAt: json['created_at'] as String,
      isMember: json['is_member'] as bool,
    );
  }
}
