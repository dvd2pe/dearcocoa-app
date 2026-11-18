import 'package:dairy_app/app/themes/theme_extensions/home_page_theme_extensions.dart';
import 'package:dairy_app/core/widgets/dashboard_tile.dart';
import 'package:dairy_app/features/chat/presentation/pages/chat_rooms_page.dart';
import 'package:dairy_app/features/community/presentation/pages/community_page.dart';
import 'package:dairy_app/features/events/presentation/pages/events_page.dart';
import 'package:dairy_app/features/hub/presentation/pages/dearcocoa_hub_page.dart';
import 'package:dairy_app/features/reflections/presentation/pages/reflections_page.dart';
import 'package:flutter/material.dart';

/// Fourth dashboard pane: the DearCocoa social wellness layer.
/// Visual language matches the existing dashboard panes.
class DearCocoaPane extends StatelessWidget {
  const DearCocoaPane({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeTheme = theme.extension<HomePageThemeExtensions>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'DearCocoa',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: homeTheme.previewTitleColor,
                  ),
                ),
                const Spacer(),
                Text(
                  'community & wellness',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: homeTheme.dateColor,
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final tileWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: tileWidth,
                    height: 100,
                    child: DashboardTile(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI Reflections',
                      subtitle: 'Reflect on your entries',
                      color: theme.colorScheme.primary,
                      onTap: () => Navigator.of(context)
                          .pushNamed(ReflectionsPage.route),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    height: 100,
                    child: DashboardTile(
                      icon: Icons.diversity_3_rounded,
                      label: 'Community',
                      subtitle: 'Safe spaces to share',
                      color: theme.colorScheme.primary,
                      onTap: () => Navigator.of(context)
                          .pushNamed(CommunityPage.route),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    height: 100,
                    child: DashboardTile(
                      icon: Icons.forum_rounded,
                      label: 'Group Chats',
                      subtitle: 'Realtime conversations',
                      color: theme.colorScheme.primary,
                      onTap: () => Navigator.of(context)
                          .pushNamed(ChatRoomsPage.route),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    height: 100,
                    child: DashboardTile(
                      icon: Icons.event_rounded,
                      label: 'Virtual Events',
                      subtitle: 'Circles & workshops',
                      color: theme.colorScheme.primary,
                      onTap: () => Navigator.of(context)
                          .pushNamed(EventsPage.route),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(DearCocoaHubPage.route),
              icon: const Icon(Icons.spa_rounded, size: 18),
              label: const Text('Open DearCocoa hub'),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
