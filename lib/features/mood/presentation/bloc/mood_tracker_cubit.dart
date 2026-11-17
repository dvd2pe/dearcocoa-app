import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/mood_log_model.dart';
import '../../data/repositories/mood_repository.dart';

/// Cubit backing the Mood Tracker page.
class MoodTrackerCubit extends Cubit<MoodTrackerState> {
  MoodTrackerCubit(this._repository) : super(const MoodTrackerLoading());

  final MoodRepository _repository;

  Future<void> load() async {
    emit(const MoodTrackerLoading());
    try {
      final logs = await _repository.fetchRecent(limit: 90);
      emit(MoodTrackerLoaded(moodLogs: logs));
    } catch (e) {
      emit(MoodTrackerError(message: e.toString()));
    }
  }

  Future<void> logMood(int moodScore, {String? note}) async {
    try {
      await _repository.logMood(moodScore, note: note);
      await load();
    } catch (e) {
      emit(MoodTrackerError(message: e.toString()));
    }
  }

  /// Average mood score across the loaded logs (null when empty).
  double? averageMood() {
    final state = this.state;
    if (state is! MoodTrackerLoaded || state.moodLogs.isEmpty) return null;
    final sum =
        state.moodLogs.fold<int>(0, (acc, e) => acc + e.moodScore);
    return sum / state.moodLogs.length;
  }
}

/// Base state for [MoodTrackerCubit].
abstract class MoodTrackerState extends Equatable {
  const MoodTrackerState();

  @override
  List<Object?> get props => const [];
}

class MoodTrackerLoading extends MoodTrackerState {
  const MoodTrackerLoading();
}

class MoodTrackerLoaded extends MoodTrackerState {
  const MoodTrackerLoaded({required this.moodLogs});

  final List<MoodLogModel> moodLogs;

  @override
  List<Object?> get props => [moodLogs];
}

class MoodTrackerError extends MoodTrackerState {
  const MoodTrackerError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
