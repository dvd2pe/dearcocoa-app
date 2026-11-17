import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/models/reflection_models.dart';
import '../../data/repositories/reflections_repository.dart';
import '../bloc/reflections_cubit.dart';

/// DearCocoa AI Reflections: chat-like page over the `reflections`
/// Edge Function. The AI sees only the entries the user shares with it,
/// and the conversation history is persisted privately (RLS owner-only).
class ReflectionsPage extends StatelessWidget {
  static String get route => '/dearcocoa/reflections';

  const ReflectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReflectionsCubit>(
      create: (_) => ReflectionsCubit(ReflectionsRepository())..openSession(),
      child: const _ReflectionsView(),
    );
  }
}

class _ReflectionsView extends StatefulWidget {
  const _ReflectionsView();

  @override
  State<_ReflectionsView> createState() => _ReflectionsViewState();
}

class _ReflectionsViewState extends State<_ReflectionsView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _includeJournal = true;

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

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _scrollToBottom();
    context.read<ReflectionsCubit>().send(
          text,
          entryIds: _includeJournal ? null : const [],
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!isSupabaseConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Reflections')),
        body: const _NotConfiguredView(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI Reflections')),
      body: Column(
        children: [
          // ---------------------------------------- journal context toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  selected: _includeJournal,
                  onSelected: (v) => setState(() => _includeJournal = v),
                  avatar: Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: _includeJournal
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: _includeJournal
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  label: const Text('Use my recent entries'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your journal is private: the AI reads only your entries '
                    'and never shares them.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // ------------------------------------------------- conversation
          Expanded(
            child: BlocConsumer<ReflectionsCubit, ReflectionsState>(
              listener: (context, state) => _scrollToBottom(),
              builder: (context, state) {
                if (state is ReflectionsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ReflectionsError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              context.read<ReflectionsCubit>().openSession(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final ready = state as ReflectionsReady;
                final messages = ready.messages;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (ready.sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final msg = messages[index];
                    return _MessageBubble(message: msg);
                  },
                );
              },
            ),
          ),
          // --------------------------------------------------- input bar
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
                        hintText:
                            'Ask for a reflection on your week...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<ReflectionsCubit, ReflectionsState>(
                    builder: (context, state) {
                      final sending =
                          state is ReflectionsReady && state.sending;
                      return IconButton.filled(
                        onPressed: sending ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ReflectionMessageModel message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary.withValues(alpha: 0.92)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUser ? theme.colorScheme.onPrimary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.Hm().format(message.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isUser
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
