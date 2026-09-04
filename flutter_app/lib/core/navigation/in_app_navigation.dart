import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/routing/deep_links.dart';

/// Resolves website / notification hrefs onto in-app GoRouter locations.
class InAppNavigation {
  const InAppNavigation._();

  /// Returns an in-app path when [href] is handled natively, otherwise null.
  static String? resolveHref(String href) {
    final trimmed = href.trim();
    if (trimmed.isEmpty || trimmed == '/') return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    final absolute = uri.hasScheme
        ? uri
        : Uri.parse('${AppConfig.apiBaseUrl}${trimmed.startsWith('/') ? trimmed : '/$trimmed'}');
    final mapped = DeepLinks.toAppLocation(absolute);
    if (mapped != null) return mapped;

    if (trimmed.startsWith('/')) return trimmed;

    if (absolute.path.isNotEmpty && absolute.path != '/') {
      return absolute.path;
    }
    return null;
  }

  /// Navigate in-app when possible; otherwise open externally.
  static Future<void> openHref(GoRouter router, String href) async {
    final location = resolveHref(href);
    if (location != null) {
      router.push(location);
      return;
    }

    final uri = Uri.tryParse(href.trim());
    if (uri == null) return;
    final absolute = uri.hasScheme ? uri : Uri.parse('${AppConfig.apiBaseUrl}$href');
    await launchUrl(absolute, mode: LaunchMode.externalApplication);
  }
}
