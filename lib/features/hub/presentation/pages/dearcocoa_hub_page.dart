import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../community/presentation/pages/community_page.dart';
import '../../../events/presentation/pages/events_page.dart';
import '../../../mood/presentation/pages/mood_tracker_page.dart';
import '../../../reflections/presentation/pages/reflections_page.dart';
import '../pages/chat_rooms_page.dart';
import 'dearcocoa_auth_gate.dart';

/// DearCocoa Hub: the entry point to the social wellness layer, styled
/// with the active DiaryVault theme.
class DearCocoaHubPage extends StatelessWidget {
  static String get route => '/dearcocoa';

  const DearCocoaHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DearCocoaAuthGate(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DearCocoa'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await supabase?.auth.signOut();
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _loadProfile(),
              builder: (context, snapshot) {
                final name =
                    snapshot.data?['display_name'] as String? ?? 'Friend';
                return Text(
                  'Hi $name, welcome back',
                  style: theme.textTheme.titleLarge,
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Your private journal stays on this device. Everything below '
              'is the shared wellness layer.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _HubCard(
              icon: Icons.mood_rounded,
              title: 'Mood Tracker',
              subtitle:
                  'Daily check-ins, history and trends. Synced to your '
                  'private cloud space.',
              onTap: () => Navigator.of(context)
                  .pushNamed(MoodTrackerPage.route),
            ),
            _HubCard(
              icon: Icons.auto_awesome_rounded,
              title: 'AI Reflections',
              subtitle:
                  'Gentle AI guidance on your own entries. Private by '
                  'design: the AI reads only what you share.',
              onTap: () => Navigator.of(context)
                  .pushNamed(ReflectionsPage.route),
            ),
            _HubCard(
              icon: Icons.diversity_3_rounded,
              title: 'Community Spaces',
              subtitle:
                  'Share, like and comment in safe moderated spaces. '
                  'Anonymous posting supported.',
              onTap: () => Navigator.of(context)
                  .pushNamed(CommunityPage.route),
            ),
            _HubCard(
              icon: Icons.forum_rounded,
              title: 'Group Conversations',
              subtitle: 'Realtime group chats with admin and moderator '
                  'roles.',
              onTap: () =>
                  Navigator.of(context).pushNamed(ChatRoomsPage.route),
            ),
            _HubCard(
              icon: Icons.event_rounded,
              title: 'Virtual Events',
              subtitle: 'Journaling circles, workshops and sessions. '
                  'RSVP with one tap.',
              onTap: () => Navigator.of(context).pushNamed(EventsPage.route),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final res = await supabase!
          .from('profiles')
          .select('display_name')
          .eq('id', uid)
          .limit(1);
      final rows = res as List<dynamic>;
      return rows.isEmpty ? null : rows.first as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
