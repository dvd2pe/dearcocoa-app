import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';

/// Cubit for a single room conversation with Realtime updates.
class ChatRoomCubit extends Cubit<ChatRoomState> {
  ChatRoomCubit(this._repository, this.roomId) : super(const ChatRoomLoading());

  final ChatRepository _repository;
  final String roomId;
  RealtimeChannel? _channel;
  String _myDisplayName = 'You';

  /// Own display name, used for message alignment.
  String get myDisplayName => _myDisplayName;

  Future<void> load() async {
    emit(const ChatRoomLoading());
    try {
      _myDisplayName = await _repository.fetchMyName();
      final messages = await _repository.fetchMessages(roomId);
      emit(ChatRoomReady(messages: messages));
      _startRealtime();
    } catch (e) {
      emit(ChatRoomError(message: e.toString()));
    }
  }

  void _startRealtime() {
    _channel = _repository.subscribeRoom(roomId, (message) {
      final current = state is ChatRoomReady
          ? state as ChatRoomReady
          : const ChatRoomReady(messages: []);
      final exists = current.messages.any((m) => m.id == message.id);
      if (exists) return;
      emit(ChatRoomReady(messages: [...current.messages, message]));
    });
  }

  Future<void> sendMessage(String content) async {
    await _repository.sendMessage(roomId, content);
    // The Realtime INSERT payload delivers the new message to everyone,
    // including ourselves - no optimistic append needed here.
  }

  @override
  Future<void> close() async {
    final channel = _channel;
    if (channel != null) {
      try {
        await _repository.unsubscribeRoom(channel);
      } catch (_) {
        // channel already removed
      }
    }
    return super.close();
  }
}

/// Base state for [ChatRoomCubit].
abstract class ChatRoomState extends Equatable {
  const ChatRoomState();

  @override
  List<Object?> get props => const [];
}

class ChatRoomLoading extends ChatRoomState {
  const ChatRoomLoading();
}

class ChatRoomError extends ChatRoomState {
  const ChatRoomError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class ChatRoomReady extends ChatRoomState {
  const ChatRoomReady({required this.messages});

  final List<ChatMessageModel> messages;

  @override
  List<Object?> get props => [messages];
}
