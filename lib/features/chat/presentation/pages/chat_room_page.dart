import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';
import '../bloc/chat_room_cubit.dart';

/// A single group conversation with realtime messages.
class ChatRoomPage extends StatelessWidget {
  static String get route => '/dearcocoa/chat/room';

  const ChatRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! ChatRoomModel) {
      // route can rebuild without arguments mid-transition; keep it inert
      return const Scaffold(body: SizedBox.shrink());
    }
    return BlocProvider<ChatRoomCubit>(
      create: (_) => ChatRoomCubit(ChatRepository(), args.id)..load(),
      child: _ChatRoomView(room: args),
    );
  }
}

class _ChatRoomView extends StatefulWidget {
  const _ChatRoomView({required this.room});

  final ChatRoomModel room;

  @override
  State<_ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<_ChatRoomView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!isSupabaseConfigured) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.room.name)),
        body: const _NotConfiguredView(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.room.name)),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatRoomCubit, ChatRoomState>(
              listener: (context, state) => _scrollToBottom(),
              builder: (context, state) {
                if (state is ChatRoomLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ChatRoomError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              context.read<ChatRoomCubit>().load(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final cubit = context.read<ChatRoomCubit>();
                final messages = (state as ChatRoomReady).messages;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = msg.userId == currentUserId ||
                        msg.authorName == cubit.myDisplayName;
                    return Align(
                      alignment: isMine
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: isMine
                              ? theme.colorScheme.primary.withValues(alpha: 0.92)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft:
                                Radius.circular(isMine ? 14 : 4),
                            bottomRight:
                                Radius.circular(isMine ? 4 : 14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMine)
                              Text(
                                msg.authorName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            Text(
                              msg.content,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isMine
                                    ? theme.colorScheme.onPrimary
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat.Hm().format(msg.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isMine
                                    ? theme.colorScheme.onPrimary
                                        .withValues(alpha: 0.7)
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Message the group...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    context.read<ChatRoomCubit>().sendMessage(text);
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
