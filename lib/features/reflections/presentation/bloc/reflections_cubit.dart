import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/reflection_models.dart';
import '../../data/repositories/reflections_repository.dart';

/// Cubit for the AI reflections conversation page.
class ReflectionsCubit extends Cubit<ReflectionsState> {
  ReflectionsCubit(this._repository) : super(const ReflectionsIdle());

  final ReflectionsRepository _repository;
  String? _sessionId;

  String? get sessionId => _sessionId;

  /// Opens (or restores) a conversation.
  Future<void> openSession([String? sessionId]) async {
    emit(const ReflectionsLoading());
    try {
      if (sessionId != null) {
        _sessionId = sessionId;
        final history = await _repository.loadHistory(sessionId);
        emit(ReflectionsReady(messages: history, sending: false));
      } else {
        _sessionId = null;
        emit(const ReflectionsReady(messages: [], sending: false));
      }
    } catch (e) {
      emit(ReflectionsError(message: e.toString()));
    }
  }

  /// Sends a message and appends user + assistant messages optimistically.
  Future<void> send(String message, {List<String>? entryIds}) async {
    final current = state is ReflectionsReady
        ? state as ReflectionsReady
        : const ReflectionsReady(messages: [], sending: false);
    final updated = List<ReflectionMessageModel>.from(current.messages)
      ..add(ReflectionMessageModel.local(
        'local-${DateTime.now().microsecondsSinceEpoch}',
        'user',
        message,
      ));
    emit(ReflectionsReady(messages: updated, sending: true));
    try {
      final reply =
          await _repository.send(_sessionId, message, entryIds: entryIds);
      _sessionId = reply.sessionId ?? _sessionId;
      final afterReply = List<ReflectionMessageModel>.from(updated)
        ..add(ReflectionMessageModel.local(
          'local-${DateTime.now().microsecondsSinceEpoch}',
          'assistant',
          reply.reply,
        ));
      emit(ReflectionsReady(messages: afterReply, sending: false));
    } catch (e) {
      emit(ReflectionsReady(messages: updated, sending: false, lastError: e.toString()));
    }
  }
}

/// Base state for [ReflectionsCubit].
abstract class ReflectionsState extends Equatable {
  const ReflectionsState();

  @override
  List<Object?> get props => const [];
}

class ReflectionsIdle extends ReflectionsState {
  const ReflectionsIdle();
}

class ReflectionsLoading extends ReflectionsState {
  const ReflectionsLoading();
}

class ReflectionsReady extends ReflectionsState {
  const ReflectionsReady({
    required this.messages,
    required this.sending,
    this.lastError,
  });

  final List<ReflectionMessageModel> messages;
  final bool sending;
  final String? lastError;

  @override
  List<Object?> get props => [messages, sending, lastError];
}

class ReflectionsError extends ReflectionsState {
  const ReflectionsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
