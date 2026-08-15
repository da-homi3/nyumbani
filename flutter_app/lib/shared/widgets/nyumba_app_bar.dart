import 'package:flutter/material.dart';

import 'package:nyumbasearch/shared/widgets/brand_logo.dart';

/// Branded AppBar matching website SiteNav / portal chrome.
class NyumbaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NyumbaAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.showMark = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool showMark;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Row(
        children: [
          if (showMark) ...[
            const BrandLogo(height: 26, markOnly: true),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
