import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/repositories/chat_repository.dart';
import '../bloc/chat_room_cubit.dart';
import '../bloc/chat_rooms_cubit.dart';
import 'chat_room_page.dart';

/// DearCocoa Group Conversations: list of rooms + create/join.
class ChatRoomsPage extends StatelessWidget {
  static String get route => '/dearcocoa/chat';

  const ChatRoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatRoomsCubit>(
      create: (_) => ChatRoomsCubit(ChatRepository())..load(),
      child: const _ChatRoomsView(),
    );
  }
}

class _ChatRoomsView extends StatelessWidget {
  const _ChatRoomsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!isSupabaseConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Conversations')),
        body: const _NotConfiguredView(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Group Conversations')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat-new-room',
        onPressed: () => _showCreateRoomDialog(context),
        child: const Icon(Icons.add_comment_rounded),
      ),
      body: BlocConsumer<ChatRoomsCubit, ChatRoomsState>(
        listener: (context, state) {
          if (state is ChatRoomsError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is ChatRoomsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ChatRoomsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.read<ChatRoomsCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final rooms = (state as ChatRoomsReady).rooms;
          if (rooms.isEmpty) {
            return Center(
              child: Text(
                'No conversations yet.\nCreate one with the button below!',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.forum_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(room.name, style: theme.textTheme.titleSmall),
                  subtitle: room.description == null
                      ? null
                      : Text(
                          room.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () async {
                    // ensure membership before entering
                    await context.read<ChatRoomsCubit>().joinRoom(room.id);
                    if (!context.mounted) return;
                    await Navigator.of(context).pushNamed(
                      ChatRoomPage.route,
                      arguments: room,
                    );
                    if (context.mounted) {
                      context.read<ChatRoomsCubit>().load();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

void _showCreateRoomDialog(BuildContext context) {
  final cubit = context.read<ChatRoomsCubit>();
  final theme = Theme.of(context);
  final nameController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('New group conversation', style: theme.textTheme.titleLarge),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(
          labelText: 'Room name',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: nameController.text.trim().isEmpty
              ? null
              : () {
                  Navigator.of(dialogContext).pop();
                  cubit.createRoom(nameController.text.trim());
                },
          child: const Text('Create'),
        ),
      ],
    ),
  );
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
