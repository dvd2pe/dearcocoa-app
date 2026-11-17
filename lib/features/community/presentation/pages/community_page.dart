import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/models/community_models.dart';
import '../../data/repositories/community_repository.dart';
import '../bloc/community_cubit.dart';

/// DearCocoa Community: spaces + feed of posts with likes and comments.
class CommunityPage extends StatelessWidget {
  static String get route => '/dearcocoa/community';

  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommunityCubit>(
      create: (_) => CommunityCubit(CommunityRepository())..load(),
      child: const _CommunityView(),
    );
  }
}

class _CommunityView extends StatelessWidget {
  const _CommunityView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!isSupabaseConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Community')),
        body: const _NotConfiguredView(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            tooltip: 'New space',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showCreateSpaceDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'community-compose',
        onPressed: () => _showComposerDialog(context),
        child: const Icon(Icons.edit_note_rounded),
      ),
      body: BlocConsumer<CommunityCubit, CommunityState>(
        listener: (context, state) {
          if (state is CommunityError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is CommunityLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CommunityError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.read<CommunityCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final ready = state as CommunityReady;
          return Column(
            children: [
              // ------------------------------------------- space filter
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 6),
                      child: FilterChip(
                        selected: ready.selectedSpaceId == null,
                        selectedColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: ready.selectedSpaceId == null
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        label: const Text('All'),
                        onSelected: (_) =>
                            context.read<CommunityCubit>().selectSpace(null),
                      ),
                    ),
                    for (final space in ready.spaces)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 6),
                        child: FilterChip(
                          selected: ready.selectedSpaceId == space.id,
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: ready.selectedSpaceId == space.id
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          label: Text(space.name),
                          onSelected: (_) => context
                              .read<CommunityCubit>()
                              .selectSpace(space.id),
                        ),
                      ),
                  ],
                ),
              ),
              // ------------------------------------------------- feed
              Expanded(
                child: ready.posts.isEmpty
                    ? Center(
                        child: Text(
                          'No posts yet. Be the first to share!',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: ready.posts.length,
                        itemBuilder: (context, index) {
                          return _PostCard(post: ready.posts[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

void _showComposerDialog(BuildContext context) {
  final cubit = context.read<CommunityCubit>();
  final ready = cubit.state is CommunityReady
      ? cubit.state as CommunityReady
      : const CommunityReady(spaces: [], posts: []);
  final theme = Theme.of(context);
  final spaceOptions = ready.spaces;
  String? selectedSpace =
      ready.selectedSpaceId ?? (spaceOptions.isNotEmpty ? spaceOptions.first.id : null);
  bool anonymous = false;
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New post', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (spaceOptions.isEmpty)
              Text(
                'There are no spaces yet - create one first (top right).',
                style: theme.textTheme.bodyMedium,
              )
            else
              DropdownButtonFormField<String>(
                value: selectedSpace,
                decoration: const InputDecoration(
                  labelText: 'Space',
                  border: OutlineInputBorder(),
                ),
                items: spaceOptions
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedSpace = v),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Share with the community...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: anonymous,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Post anonymously'),
              onChanged: (v) => setSheetState(() => anonymous = v ?? false),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: spaceOptions.isEmpty ||
                        selectedSpace == null ||
                        bodyController.text.trim().isEmpty
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        cubit.createPost(
                          selectedSpace,
                          bodyController.text.trim(),
                          title: titleController.text.trim(),
                          isAnonymous: anonymous,
                        );
                      },
                child: const Text('Publish'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showCreateSpaceDialog(BuildContext context) {
  final cubit = context.read<CommunityCubit>();
  final theme = Theme.of(context);
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('New community space', style: theme.textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
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
        ],
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
                  cubit.createSpace(
                    nameController.text.trim(),
                    descriptionController.text.trim(),
                  );
                },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<CommunityCubit>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    post.isAnonymous
                        ? '?'
                        : post.authorName.isNotEmpty
                            ? post.authorName[0].toUpperCase()
                            : '?',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.isAnonymous ? 'Anonymous' : post.authorName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        DateFormat.yMMMMd().format(post.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (post.title != null && post.title!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(post.title!, style: theme.textTheme.titleMedium),
            ],
            const SizedBox(height: 6),
            Text(post.body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => cubit.toggleLike(post.id),
                  icon: Icon(
                    post.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: post.likedByMe ? theme.colorScheme.primary : null,
                  ),
                  label: Text('${post.likeCount}'),
                ),
                TextButton.icon(
                  onPressed: () => _showCommentsSheet(context, post),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: Text('${post.commentCount}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showCommentsSheet(BuildContext context, PostModel post) async {
  final repository = CommunityRepository();
  final theme = Theme.of(context);
  final commentController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => FutureBuilder<List<CommentModel>>(
        future: repository.fetchComments(post.id),
        builder: (context, snapshot) {
          final comments = snapshot.data ?? const <CommentModel>[];
          return Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Comments', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: comments.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'No comments yet.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final c = comments[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Text(
                                  c.authorName.isNotEmpty
                                      ? c.authorName[0].toUpperCase()
                                      : '?',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(c.authorName,
                                  style: theme.textTheme.titleSmall),
                              subtitle: Text(c.body),
                              trailing: Text(
                                DateFormat.MMMd().format(c.createdAt),
                                style: theme.textTheme.labelSmall,
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () async {
                        final text = commentController.text.trim();
                        if (text.isEmpty) return;
                        await repository.addComment(post.id, text);
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                      },
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
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
