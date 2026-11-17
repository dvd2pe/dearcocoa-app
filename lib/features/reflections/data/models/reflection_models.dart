import 'package:equatable/equatable.dart';

/// One message in an AI reflection conversation.
class ReflectionMessageModel extends Equatable {
  const ReflectionMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  factory ReflectionMessageModel.fromJson(Map<String, dynamic> json) {
    return ReflectionMessageModel(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Local (optimistic) message before/without server confirmation.
  factory ReflectionMessageModel.local(
      String id, String role, String content) {
    return ReflectionMessageModel(
      id: id,
      role: role,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, role, content, createdAt];
}

/// A reflection conversation (session).
class ReflectionSessionModel extends Equatable {
  const ReflectionSessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;

  factory ReflectionSessionModel.fromJson(Map<String, dynamic> json) {
    return ReflectionSessionModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? 'New reflection',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, title, createdAt];
}
