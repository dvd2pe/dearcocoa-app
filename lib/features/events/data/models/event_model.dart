import 'package:equatable/equatable.dart';

/// A virtual event.
class CocoaEventModel extends Equatable {
  const CocoaEventModel({
    required this.id,
    required this.title,
    required this.startsAt,
    this.description,
    this.endsAt,
    this.joinUrl,
    this.coverUrl,
    this.spaceName,
    this.goingCount = 0,
    this.myStatus,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? joinUrl;
  final String? coverUrl;
  final String? spaceName;
  final int goingCount;
  final String? myStatus; // 'going' | 'interested' | null

  factory CocoaEventModel.fromJson(
    Map<String, dynamic> json, {
    String? viewerId,
  }) {
    final rsvps = (json['event_rsvps'] as List<dynamic>?) ?? const [];
    final space = json['spaces'] as Map<String, dynamic>?;
    return CocoaEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] == null
          ? null
          : DateTime.parse(json['ends_at'] as String),
      joinUrl: json['join_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      spaceName: space?['name'] as String?,
      goingCount: rsvps
          .where((r) => (r as Map<String, dynamic>)['status'] == 'going')
          .length,
      myStatus: rsvps
          .cast<Map<String, dynamic>>()
          .where((r) => r['user_id'] == viewerId)
          .map<String?>((r) => r['status'] as String?)
          .firstOrNull(),
    );
  }

  @override
  List<Object?> get props => [
        id, title, description, startsAt, endsAt,
        joinUrl, coverUrl, spaceName, goingCount, myStatus,
      ];
}

/// Tiny helper because Dart Iterable has no firstOrNull in all SDK versions.
extension _FirstOrNull<T> on Iterable<T> {
  T? firstOrNull() => isEmpty ? null : first;
}
