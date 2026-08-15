import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

Future<void> showSiteMenuSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      Widget item({
        required IconData icon,
        required String label,
        required String path,
      }) {
        return ListTile(
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(label, style: theme.textTheme.titleSmall),
          onTap: () {
            Navigator.pop(ctx);
            if (path.startsWith('/')) {
              context.push(path);
            }
          },
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Text(
                'Menu',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              item(icon: Icons.search, label: 'Browse homes', path: '/search'),
              item(icon: Icons.map_outlined, label: 'Map', path: '/map'),
              item(icon: Icons.favorite_outline, label: 'Saved', path: '/saved'),
              item(
                icon: Icons.handyman_outlined,
                label: 'Home services',
                path: '/services',
              ),
              item(icon: Icons.workspace_premium_outlined, label: 'Plus', path: '/plus'),
              item(icon: Icons.person_outline, label: 'Account / Settings', path: '/settings'),
              item(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                path: '/notifications',
              ),
              item(
                icon: Icons.dashboard_outlined,
                label: 'Portals',
                path: '/portals',
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'NyumbaSearch',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: NyumbaTokens.primaryGlowDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
