import 'package:equatable/equatable.dart';

/// A community space (DearCocoa "community spaces").
class SpaceModel extends Equatable {
  const SpaceModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.coverUrl,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? coverUrl;

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    return SpaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, slug, description, coverUrl];
}

/// A post inside a space, enriched with author/likes for the feed.
class PostModel extends Equatable {
  const PostModel({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.title,
    this.isAnonymous = false,
    this.authorName = 'Member',
    this.likeCount = 0,
    this.likedByMe = false,
    this.commentCount = 0,
  });

  final String id;
  final String spaceId;
  final String userId;
  final String? title;
  final String body;
  final bool isAnonymous;
  final String authorName;
  final int likeCount;
  final bool likedByMe;
  final int commentCount;
  final DateTime createdAt;

  factory PostModel.fromJson(
    Map<String, dynamic> json, {
    String? viewerId,
  }) {
    final likes = (json['post_likes'] as List<dynamic>?) ?? const [];
    final comments = (json['comments'] as List<dynamic>?) ?? const [];
    final profile = json['profiles'] as Map<String, dynamic>?;
    final userId = json['user_id'] as String;
    return PostModel(
      id: json['id'] as String,
      spaceId: json['space_id'] as String,
      userId: userId,
      title: json['title'] as String?,
      body: json['body'] as String,
      isAnonymous: (json['is_anonymous'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: profile?['display_name'] as String? ?? 'Member',
      likeCount: likes.length,
      likedByMe: likes.any((l) => (l as Map<String, dynamic>)['user_id'] == viewerId),
      commentCount: comments.length,
    );
  }

  @override
  List<Object?> get props => [
        id, spaceId, userId, title, body, isAnonymous,
        authorName, likeCount, likedByMe, commentCount, createdAt,
      ];
}

/// A comment on a post.
class CommentModel extends Equatable {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.authorName = 'Member',
  });

  final String id;
  final String postId;
  final String userId;
  final String body;
  final String authorName;
  final DateTime createdAt;

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: profile?['display_name'] as String? ?? 'Member',
    );
  }

  @override
  List<Object?> get props => [id, postId, userId, body, authorName, createdAt];
}
