import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/notifications/data/notifications_repository.dart';
import 'package:nyumbasearch/shared/widgets/brand_logo.dart';
import 'package:nyumbasearch/shared/widgets/site_menu_sheet.dart';

/// Glass top bar matching mobile web: logo · notifications badge · Menu.
class SiteTopBar extends ConsumerWidget {
  const SiteTopBar({
    super.key,
    this.onLogoTap,
    this.frosted = true,
  });

  final VoidCallback? onLogoTap;
  final bool frosted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsUnreadCountProvider).valueOrNull ?? 0;
    final top = MediaQuery.paddingOf(context).top;

    Widget content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NyumbaTokens.space2 + 2,
        vertical: NyumbaTokens.space2,
      ),
      decoration: NyumbaTokens.glassTopBar(frosted: frosted),
      child: Row(
        children: [
          InkWell(
            onTap: onLogoTap ?? () => context.go('/home'),
            borderRadius: BorderRadius.circular(10),
            child: const BrandLogo(height: 34, markOnly: true),
          ),
          const Spacer(),
          _NotifButton(count: unread),
          const SizedBox(width: NyumbaTokens.space2),
          _MenuButton(onTap: () => showSiteMenuSheet(context)),
        ],
      ),
    );

    if (frosted) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(NyumbaTokens.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: content,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        NyumbaTokens.space4,
        top + NyumbaTokens.space2,
        NyumbaTokens.space4,
        0,
      ),
      child: content,
    );
  }
}

class _NotifButton extends StatelessWidget {
  const _NotifButton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.push('/notifications'),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                  if (count > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: const Text(
            'Menu',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact solid variant for dark scroll pages (Browse body, Rent, Services).
class SiteTopBarSolid extends ConsumerWidget {
  const SiteTopBarSolid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsUnreadCountProvider).valueOrNull ?? 0;
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            InkWell(
              onTap: () => context.go('/home'),
              borderRadius: BorderRadius.circular(10),
              child: const BrandLogo(height: 36, markOnly: true),
            ),
            const Spacer(),
            Material(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.push('/notifications'),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      if (unread > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            height: 16,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => showSiteMenuSheet(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
