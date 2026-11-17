import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../models/event_model.dart';

/// Cloud repository for DearCocoa virtual events.
class EventsRepository {
  SupabaseClient get _client {
    final client = supabase;
    if (client == null) {
      throw StateError('Supabase not configured');
    }
    return client;
  }

  /// Upcoming events (starts from now), earliest first, with RSVP info.
  Future<List<CocoaEventModel>> fetchUpcoming() async {
    final viewerId = currentUserId;
    final rows = await _client
        .from('events')
        .select('*, spaces(name), event_rsvps(user_id, status)')
        .gte('starts_at', DateTime.now().toIso8601String())
        .order('starts_at', ascending: true)
        .limit(50);
    final list = rows as List<dynamic>;
    return list
        .map((e) => CocoaEventModel.fromJson(
              e as Map<String, dynamic>,
              viewerId: viewerId,
            ))
        .toList();
  }

  /// Creates an event.
  Future<void> createEvent({
    required String title,
    required DateTime startsAt,
    String? description,
    String? spaceId,
    String? joinUrl,
  }) async {
    await _client.from('events').insert({
      'title': title,
      'starts_at': startsAt.toIso8601String(),
      if (description != null && description.isNotEmpty)
        'description': description,
      if (spaceId != null) 'space_id': spaceId,
      if (joinUrl != null && joinUrl.isNotEmpty) 'join_url': joinUrl,
      'created_by': currentUserId,
    });
  }

  /// Sets (or updates) the viewer's RSVP for an event.
  Future<void> setRsvp(String eventId, String status) async {
    await _client.from('event_rsvps').upsert({
      'event_id': eventId,
      'user_id': currentUserId,
      'status': status,
    });
  }

  /// Removes the viewer's RSVP.
  Future<void> clearRsvp(String eventId) async {
    await _client
        .from('event_rsvps')
        .delete()
        .eq('event_id', eventId)
        .eq('user_id', currentUserId!);
  }

  /// Space options for the create-event dialog.
  Future<List<Map<String, dynamic>>> fetchSpaceOptions() async {
    final rows = await _client
        .from('spaces')
        .select('id, name')
        .order('created_at', ascending: true);
    final list = rows as List<dynamic>;
    return list.cast<Map<String, dynamic>>().toList();
  }
}
