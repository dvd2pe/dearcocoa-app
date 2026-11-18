import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../models/mood_log_model.dart';

/// Cloud repository for mood logs (Supabase `mood_logs`).
/// All rows are owner-only via RLS; journal mood data never leaves the
/// user's own row space.
class MoodRepository {
  SupabaseClient get _client {
    final client = supabase;
    if (client == null) {
      throw StateError('Supabase not configured');
    }
    return client;
  }

  /// Latest mood logs of the signed-in user, newest first.
  Future<List<MoodLogModel>> fetchRecent({int limit = 60}) async {
    final rows = await _client
        .from('mood_logs')
        .select()
        .order('logged_at', ascending: false)
        .limit(limit);
    final list = rows as List<dynamic>;
    return list
        .map((e) => MoodLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Persists a new mood check-in. Returns the created row id.
  Future<String> logMood(
    int moodScore, {
    String? note,
    String? entryId,
  }) async {
    final data = <String, dynamic>{
      'user_id': currentUserId,
      'mood_score': moodScore,
      if (note != null && note.isNotEmpty) 'note': note,
      if (entryId != null) 'entry_id': entryId,
    };
    final res = await _client.from('mood_logs').insert(data).select('id').single();
    return res['id'] as String;
  }

  /// Deletes a mood log.
  Future<void> deleteMood(String id) async {
    await _client.from('mood_logs').delete().eq('id', id);
  }
}
