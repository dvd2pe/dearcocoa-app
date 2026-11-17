import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';

/// Cubit for the rooms list.
class ChatRoomsCubit extends Cubit<ChatRoomsState> {
  ChatRoomsCubit(this._repository) : super(const ChatRoomsLoading());

  final ChatRepository _repository;

  Future<void> load() async {
    emit(const ChatRoomsLoading());
    try {
      final rooms = await _repository.fetchRooms();
      emit(ChatRoomsReady(rooms: rooms));
    } catch (e) {
      emit(ChatRoomsError(message: e.toString()));
    }
  }

  Future<void> createRoom(String name) async {
    await _repository.createGroupRoom(name);
    await load();
  }

  Future<void> joinRoom(String roomId) async {
    await _repository.joinRoom(roomId);
  }
}

/// Base state for [ChatRoomsCubit].
abstract class ChatRoomsState extends Equatable {
  const ChatRoomsState();

  @override
  List<Object?> get props => const [];
}

class ChatRoomsLoading extends ChatRoomsState {
  const ChatRoomsLoading();
}

class ChatRoomsError extends ChatRoomsState {
  const ChatRoomsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class ChatRoomsReady extends ChatRoomsState {
  const ChatRoomsReady({required this.rooms});

  final List<ChatRoomModel> rooms;

  @override
  List<Object?> get props => [rooms];
}
