import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../models/chat_models.dart';

/// Cloud repository for DearCocoa group conversations (Supabase Realtime).
class ChatRepository {
  SupabaseClient get _client {
    final client = supabase;
    if (client == null) {
      throw StateError('Supabase not configured');
    }
    return client;
  }

  /// Lists rooms, newest first.
  Future<List<ChatRoomModel>> fetchRooms() async {
    final rows = await _client
        .from('rooms')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    final list = rows as List<dynamic>;
    return list
        .map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a group room atomically via the `create_group_room` RPC
  /// (creator gets the admin role automatically).
  Future<String> createGroupRoom(String name) async {
    final res = await _client.rpc('create_group_room', params: {'p_name': name});
    return res as String;
  }

  /// Joins an existing room (member).
  Future<void> joinRoom(String roomId) async {
    await _client.rpc('join_room', params: {'p_room_id': roomId});
  }

  /// Loads the latest messages of a room (oldest last for display).
  Future<List<ChatMessageModel>> fetchMessages(String roomId,
      {int limit = 100}) async {
    final rows = await _client
        .from('messages')
        .select('*, profiles(display_name)')
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(limit);
    final list = (rows as List<dynamic>).reversed.toList();
    return list
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Sends a message to a room.
  Future<void> sendMessage(String roomId, String content) async {
    await _client.from('messages').insert({
      'room_id': roomId,
      'content': content,
    });
  }

  /// Subscribes to new messages of a room. Returns the realtime channel:
  /// call [unsubscribeRoom] when leaving the page.
  RealtimeChannel subscribeRoom(
    String roomId,
    void Function(ChatMessageModel message) onInsert,
  ) {
    final channel = _client
        .channel('room-$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (PostgresChangePayload payload) {
            final row = Map<String, dynamic>.from(payload.newRecord);
            onInsert(ChatMessageModel.fromRealtimeRow(row));
          },
        )
        .subscribe();
    return channel;
  }

  /// Unsubscribes a room channel.
  Future<void> unsubscribeRoom(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  /// Display name of the signed-in user (for own-message alignment).
  Future<String> fetchMyName() async {
    final uid = currentUserId;
    if (uid == null) return 'You';
    final res = await _client
        .from('profiles')
        .select('display_name')
        .eq('id', uid)
        .limit(1);
    final rows = res as List<dynamic>;
    if (rows.isEmpty) return 'You';
    return (rows.first as Map<String, dynamic>)['display_name'] as String? ??
        'You';
  }
}
