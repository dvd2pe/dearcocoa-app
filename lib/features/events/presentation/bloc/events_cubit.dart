import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';

/// Cubit for the virtual events page.
class EventsCubit extends Cubit<EventsState> {
  EventsCubit(this._repository) : super(const EventsLoading());

  final EventsRepository _repository;

  Future<void> load() async {
    emit(const EventsLoading());
    try {
      final events = await _repository.fetchUpcoming();
      emit(EventsReady(events: events));
    } catch (e) {
      emit(EventsError(message: e.toString()));
    }
  }

  Future<void> setRsvp(String eventId, String status) async {
    final current = state is EventsReady
        ? state as EventsReady
        : const EventsReady(events: []);
    // optimistic update
    final updated = current.events.map((e) {
      if (e.id != eventId) return e;
      return CocoaEventModel(
        id: e.id,
        title: e.title,
        description: e.description,
        startsAt: e.startsAt,
        endsAt: e.endsAt,
        joinUrl: e.joinUrl,
        coverUrl: e.coverUrl,
        spaceName: e.spaceName,
        goingCount: status == 'going'
            ? (e.myStatus == 'going' ? e.goingCount : e.goingCount + 1)
            : (e.myStatus == 'going' ? e.goingCount - 1 : e.goingCount),
        myStatus: status,
      );
    }).toList();
    emit(EventsReady(events: updated));
    try {
      await _repository.setRsvp(eventId, status);
    } catch (_) {
      await load();
    }
  }

  Future<void> clearRsvp(String eventId) async {
    final current = state is EventsReady
        ? state as EventsReady
        : const EventsReady(events: []);
    final updated = current.events.map((e) {
      if (e.id != eventId) return e;
      return CocoaEventModel(
        id: e.id,
        title: e.title,
        description: e.description,
        startsAt: e.startsAt,
        endsAt: e.endsAt,
        joinUrl: e.joinUrl,
        coverUrl: e.coverUrl,
        spaceName: e.spaceName,
        goingCount:
            e.myStatus == 'going' ? e.goingCount - 1 : e.goingCount,
        myStatus: null,
      );
    }).toList();
    emit(EventsReady(events: updated));
    try {
      await _repository.clearRsvp(eventId);
    } catch (_) {
      await load();
    }
  }

  Future<void> createEvent({
    required String title,
    required DateTime startsAt,
    String? description,
    String? spaceId,
    String? joinUrl,
  }) async {
    await _repository.createEvent(
      title: title,
      startsAt: startsAt,
      description: description,
      spaceId: spaceId,
      joinUrl: joinUrl,
    );
    await load();
  }
}

/// Base state for [EventsCubit].
abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => const [];
}

class EventsLoading extends EventsState {
  const EventsLoading();
}

class EventsError extends EventsState {
  const EventsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class EventsReady extends EventsState {
  const EventsReady({required this.events});

  final List<CocoaEventModel> events;

  @override
  List<Object?> get props => [events];
}
