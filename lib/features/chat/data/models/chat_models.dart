import 'package:equatable/equatable.dart';

/// A group conversation room.
class ChatRoomModel extends Equatable {
  const ChatRoomModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, description, createdAt];
}

/// A message inside a room, enriched with the author display name.
class ChatMessageModel extends Equatable {
  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName = 'Member',
  });

  final String id;
  final String roomId;
  final String userId;
  final String content;
  final String authorName;
  final DateTime createdAt;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ChatMessageModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: profile?['display_name'] as String? ?? 'Member',
    );
  }

  /// Message built from a Realtime INSERT payload (no joined profile).
  factory ChatMessageModel.fromRealtimeRow(
    Map<String, dynamic> row, {
    String? authorName,
  }) {
    return ChatMessageModel(
      id: row['id'] as String,
      roomId: row['room_id'] as String,
      userId: row['user_id'] as String,
      content: row['content'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      authorName: authorName ?? 'Member',
    );
  }

  @override
  List<Object?> get props => [id, roomId, userId, content, authorName, createdAt];
}
