import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/models/mood_log_model.dart';
import '../bloc/mood_tracker_cubit.dart';

/// DearCocoa Mood Tracker: daily check-in (1..5) + history + simple stats.
/// Styled with the active DiaryVault theme (no hard-coded colors).
class MoodTrackerPage extends StatelessWidget {
  static String get route => '/dearcocoa/mood';

  const MoodTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MoodTrackerCubit>(
      create: (_) => MoodTrackerCubit(MoodRepository())..load(),
      child: const _MoodTrackerView(),
    );
  }
}

class _MoodTrackerView extends StatefulWidget {
  const _MoodTrackerView();

  @override
  State<_MoodTrackerView> createState() => _MoodTrackerViewState();
}

class _MoodTrackerViewState extends State<_MoodTrackerView> {
  int? _selectedMood;
  final TextEditingController _noteController = TextEditingController();

  static const _moodIcons = <int, IconData>{
    1: Icons.sentiment_very_dissatisfied_rounded,
    2: Icons.sentiment_dissatisfied_rounded,
    3: Icons.sentiment_neutral_rounded,
    4: Icons.sentiment_satisfied_alt_rounded,
    5: Icons.sentiment_very_satisfied_rounded,
  };

  static const _moodLabels = <int, String>{
    1: 'Difficult',
    2: 'Low',
    3: 'Okay',
    4: 'Good',
    5: 'Great',
  };

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!isSupabaseConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mood Tracker')),
        body: const _NotConfiguredView(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Tracker')),
      body: BlocConsumer<MoodTrackerCubit, MoodTrackerState>(
        listener: (context, state) {
          if (state is MoodTrackerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is MoodTrackerLoaded) {
            _selectedMood = null;
            _noteController.clear();
          }
        },
        builder: (context, state) {
          if (state is MoodTrackerLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MoodTrackerError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.read<MoodTrackerCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final logs = (state as MoodTrackerLoaded).moodLogs;
          final avg = context.read<MoodTrackerCubit>().averageMood();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // -------------------------------------------- today check-in
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How do you feel right now?',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          for (final score in const [1, 2, 3, 4, 5])
                            InkWell(
                              borderRadius: BorderRadius.circular(40),
                              onTap: () =>
                                  setState(() => _selectedMood = score),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  children: [
                                    Icon(
                                      _moodIcons[score],
                                      size: 36,
                                      color: _selectedMood == score
                                          ? theme.colorScheme.primary
                                          : theme
                                              .colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _moodLabels[score]!,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: _selectedMood == score
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Add a short note (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FilledButton.icon(
                          onPressed: _selectedMood == null
                              ? null
                              : () => context
                                  .read<MoodTrackerCubit>()
                                  .logMood(_selectedMood!,
                                      note: _noteController.text),
                          icon: const Icon(Icons.favorite_rounded),
                          label: const Text('Save check-in'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ---------------------------------------------------- stats
              Row(
                children: [
                  _StatChip(
                    label: 'Entries',
                    value: '${logs.length}',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Average',
                    value: avg == null
                        ? '-'
                        : avg.toStringAsFixed(1),
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Last check-in',
                    value: logs.isEmpty
                        ? '-'
                        : DateFormat.MMMEd().format(logs.first.loggedAt),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // -------------------------------------------------- history
              Text('History', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No check-ins yet. Start with one above!',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                ...logs.map((log) => _MoodLogTile(log: log)),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodLogTile extends StatelessWidget {
  const _MoodLogTile({required this.log});

  final MoodLogModel log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        _iconFor(log.moodScore),
        color: theme.colorScheme.primary,
      ),
      title: Text(
        DateFormat.yMMMMd().add_jm().format(log.loggedAt),
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: log.note == null || log.note!.isEmpty
          ? null
          : Text(log.note!, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text('${log.moodScore}/5', style: theme.textTheme.labelLarge),
    );
  }

  IconData _iconFor(int score) {
    switch (score) {
      case 1:
        return Icons.sentiment_very_dissatisfied_rounded;
      case 2:
        return Icons.sentiment_dissatisfied_rounded;
      case 3:
        return Icons.sentiment_neutral_rounded;
      case 4:
        return Icons.sentiment_satisfied_alt_rounded;
      default:
        return Icons.sentiment_very_satisfied_rounded;
    }
  }
}

class _NotConfiguredView extends StatelessWidget {
  const _NotConfiguredView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text(
              'DearCocoa cloud features are not configured in this build.\n'
              'Add SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
