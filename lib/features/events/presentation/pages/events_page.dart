import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';
import '../bloc/events_cubit.dart';

/// DearCocoa Virtual Events: upcoming events with RSVP + creation.
class EventsPage extends StatelessWidget {
  static String get route => '/dearcocoa/events';

  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EventsCubit>(
      create: (_) => EventsCubit(EventsRepository())..load(),
      child: const _EventsView(),
    );
  }
}

class _EventsView extends StatelessWidget {
  const _EventsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!isSupabaseConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Virtual Events')),
        body: const _NotConfiguredView(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Events')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'events-create',
        onPressed: () => _showCreateEventDialog(context),
        child: const Icon(Icons.event_rounded),
      ),
      body: BlocConsumer<EventsCubit, EventsState>(
        listener: (context, state) {
          if (state is EventsError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is EventsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EventsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.read<EventsCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final events = (state as EventsReady).events;
          if (events.isEmpty) {
            return Center(
              child: Text(
                'No upcoming events.\nHost the first one!',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _EventCard(event: events[index]);
            },
          );
        },
      ),
    );
  }
}

void _showCreateEventDialog(BuildContext context) {
  final cubit = context.read<EventsCubit>();
  final theme = Theme.of(context);
  final repository = EventsRepository();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final joinUrlController = TextEditingController();
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);
  List<Map<String, dynamic>> spaceOptions = [];
  String? selectedSpaceId;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        // load space options once
        if (spaceOptions.isEmpty) {
          repository.fetchSpaceOptions().then((opts) {
            if (sheetContext.mounted) {
              setSheetState(() => spaceOptions = opts);
            }
          }).catchError((_) {});
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New virtual event', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(DateFormat.yMMMd().format(selectedDate)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(selectedTime.format(sheetContext)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: sheetContext,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setSheetState(() => selectedTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (spaceOptions.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedSpaceId,
                  decoration: const InputDecoration(
                    labelText: 'Host space (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: spaceOptions
                      .map((s) => DropdownMenuItem(
                            value: s['id'] as String,
                            child: Text(s['name'] as String),
                          ))
                      .toList(),
                  onChanged: (v) => setSheetState(() => selectedSpaceId = v),
                ),
              if (spaceOptions.isEmpty)
                Text(
                  'No spaces available yet - the event will be standalone.',
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 12),
              TextField(
                controller: joinUrlController,
                decoration: const InputDecoration(
                  labelText: 'Join URL (video call link)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: titleController.text.trim().isEmpty
                      ? null
                      : () {
                          final startsAt = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          Navigator.of(sheetContext).pop();
                          cubit.createEvent(
                            title: titleController.text.trim(),
                            startsAt: startsAt,
                            description: descriptionController.text.trim(),
                            spaceId: selectedSpaceId,
                            joinUrl: joinUrlController.text.trim(),
                          );
                        },
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CocoaEventModel event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<EventsCubit>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(event.title, style: theme.textTheme.titleMedium),
                ),
                if (event.spaceName != null)
                  Text(
                    event.spaceName!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  DateFormat.EEEE().add_yMMMd().add_jm().format(event.startsAt),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 10),
                Icon(Icons.group_rounded,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${event.goingCount} going',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            if (event.description != null &&
                event.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                event.description!,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (event.joinUrl != null)
                  TextButton.icon(
                    onPressed: () async {
                      await _openJoinUrl(context, event.joinUrl!);
                    },
                    icon: const Icon(Icons.videocam_rounded, size: 20),
                    label: const Text('Join'),
                  ),
                const Spacer(),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'going',
                      icon: Icon(Icons.check_rounded, size: 18),
                      label: Text('Going'),
                    ),
                    ButtonSegment(
                      value: 'interested',
                      icon: Icon(Icons.star_rounded, size: 18),
                      label: Text('Maybe'),
                    ),
                  ],
                  selected: {
                    if (event.myStatus != null) event.myStatus!,
                  },
                  emptySelectionAllowed: true,
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) {
                      cubit.clearRsvp(event.id);
                    } else {
                      cubit.setRsvp(event.id, selection.first);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openJoinUrl(BuildContext context, String url) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join this event'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
