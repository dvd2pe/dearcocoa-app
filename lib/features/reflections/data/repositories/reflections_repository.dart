import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../models/reflection_models.dart';

/// Repository for AI reflections: Edge Function call + conversation history.
///
/// Privacy model (see supabase/functions/reflections/index.ts):
/// - the function is called with the user's JWT, reads ONLY the user's own
///   entries via RLS, never uses the service role to access journal data;
/// - conversation history lives in `reflection_messages` (RLS owner-only).
class ReflectionsRepository {
  SupabaseClient get _client {
    final client = supabase;
    if (client == null) {
      throw StateError('Supabase not configured');
    }
    return client;
  }

  /// Sends [message] (with optional journal [entryIds] as AI context) to the
  /// `reflections` Edge Function. Returns the assistant reply; [sessionId]
  /// is updated in place when null (new conversation).
  Future<ReflectionReply> send(
    String? sessionId,
    String message, {
    List<String>? entryIds,
    int maxEntries = 5,
  }) async {
    final response = await _client.functions.invoke(
      'reflections',
      body: {
        if (sessionId != null) 'sessionId': sessionId,
        'message': message,
        if (entryIds != null && entryIds.isNotEmpty) 'entryIds': entryIds,
        'maxEntries': maxEntries,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ReflectionReply(
        sessionId: data['sessionId'] as String?,
        reply: (data['reply'] as String?) ?? '',
      );
    }
    throw StateError('Unexpected reflections response');
  }

  /// Lists the user's reflection conversations, newest first.
  Future<List<ReflectionSessionModel>> listSessions() async {
    final rows = await _client
        .from('reflection_sessions')
        .select()
        .order('created_at', ascending: false)
        .limit(20);
    final list = rows as List<dynamic>;
    return list
        .map((e) =>
            ReflectionSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Loads stored messages of a conversation (newest last).
  Future<List<ReflectionMessageModel>> loadHistory(String sessionId) async {
    final rows = await _client
        .from('reflection_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true)
        .limit(50);
    final list = rows as List<dynamic>;
    return list
        .map((e) =>
            ReflectionMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Result of an Edge Function reflection round.
class ReflectionReply {
  const ReflectionReply({this.sessionId, required this.reply});

  final String? sessionId;
  final String reply;
}
