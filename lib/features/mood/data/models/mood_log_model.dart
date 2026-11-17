import 'package:equatable/equatable.dart';

/// A single mood log entry (DearCocoa mood tracking).
class MoodLogModel extends Equatable {
  const MoodLogModel({
    required this.id,
    required this.userId,
    required this.moodScore,
    required this.loggedAt,
    this.note,
    this.entryId,
  });

  final String id;
  final String userId;
  final int moodScore; // 1..5
  final DateTime loggedAt;
  final String? note;
  final String? entryId;

  factory MoodLogModel.fromJson(Map<String, dynamic> json) {
    return MoodLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      moodScore: (json['mood_score'] as num).toInt(),
      loggedAt: DateTime.parse(json['logged_at'] as String),
      note: json['note'] as String?,
      entryId: json['entry_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'mood_score': moodScore,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (entryId != null) 'entry_id': entryId,
      };

  @override
  List<Object?> get props => [id, userId, moodScore, loggedAt, note, entryId];
}
