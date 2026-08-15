import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:nyumbasearch/core/analytics/analytics_client.dart';
import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/favorites/presentation/saved_page.dart';
import 'package:nyumbasearch/features/properties/data/listing.dart';
import 'package:nyumbasearch/features/properties/data/listing_intel.dart';
import 'package:nyumbasearch/shared/widgets/motion.dart';

/// Listing card styled after website PropertyCard.tsx.
class PropertyCard extends ConsumerWidget {
  const PropertyCard({super.key, required this.listing});

  final Listing listing;

  String get _prettyType {
    final t = listing.propertyType.replaceAll('_', ' ').trim();
    if (t.isEmpty) return 'Home';
    return t
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final score = listing.authenticityScore;
    final intel = ListingIntel.fromAmenities(listing.amenities);

    return TiltCard(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: NyumbaTokens.borderRadiusLg,
          boxShadow: NyumbaTokens.shadowCard(theme.brightness),
        ),
        child: Material(
      color: theme.colorScheme.surface,
      borderRadius: NyumbaTokens.borderRadiusLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/property/${listing.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  listing.primaryImage.isEmpty
                      ? ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.home_work_outlined, size: 40),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: listing.primaryImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x26111827),
                          Color(0x00111827),
                          Color(0xBF111827),
                        ],
                        stops: [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (listing.isVerified)
                          _Badge(
                            icon: Icons.verified,
                            label: 'Verified',
                            background: const Color(0xFF16A34A),
                            foreground: Colors.white,
                          ),
                        if (listing.isVerified) ...[
                          const SizedBox(height: 6),
                          _Badge(
                            icon: Icons.circle,
                            label: 'Business Verified',
                            background: Colors.black.withValues(alpha: 0.55),
                            foreground: const Color(0xFF86EFAC),
                            iconSize: 8,
                          ),
                        ],
                        if (score != null) ...[
                          const SizedBox(height: 6),
                          _Badge(
                            icon: Icons.local_fire_department,
                            label: 'Plus: scam score',
                            background: Colors.black.withValues(alpha: 0.7),
                            foreground: const Color(0xFFFB923C),
                          ),
                          const SizedBox(height: 6),
                          const _Badge(
                            icon: Icons.bolt,
                            label: 'Plus early access',
                            background: Color(0xFF7C3AED),
                            foreground: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        Material(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Share',
                            onPressed: () {
                              final url =
                                  '${AppConfig.apiBaseUrl}/tenant/property/${listing.id}';
                              ref.read(analyticsProvider).track(
                                AnalyticsEvents.propertyShared,
                                {'propertyId': listing.id},
                              );
                              SharePlus.instance.share(
                                ShareParams(
                                  text: '${listing.title}\n$url',
                                  subject: listing.title,
                                ),
                              );
                            },
                            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Material(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: const CircleBorder(),
                          child: FavoriteButton(
                            propertyId: listing.id,
                            color: Colors.white,
                            activeColor: const Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        listing.priceLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _prettyType,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            listing.neighborhood.isEmpty
                                ? 'Kenya'
                                : listing.neighborhood,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _IntelChip(
                        icon: Icons.water_drop_outlined,
                        label: 'Water: ${intel.water}',
                        tone: ListingIntel.toneFor(intel.water),
                      ),
                      _IntelChip(
                        icon: Icons.shield_outlined,
                        label: 'Security: ${intel.security}',
                        tone: ListingIntel.toneFor(intel.security),
                      ),
                      _IntelChip(
                        icon: Icons.wifi,
                        label: intel.internet,
                        tone: ListingIntel.toneFor(intel.internet),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _Meta(icon: Icons.bed_outlined, label: '${listing.bedrooms} bd'),
                      const SizedBox(width: 12),
                      _Meta(icon: Icons.bathtub_outlined, label: '${listing.bathrooms} ba'),
                      if (intel.parking) ...[
                        const SizedBox(width: 12),
                        _Meta(icon: Icons.directions_car_outlined, label: 'Parking'),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: NyumbaTokens.borderRadius,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primaryContainer,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'View details',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.iconSize = 12,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntelChip extends StatelessWidget {
  const _IntelChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final ColorTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      ColorTone.good => const Color(0xFF16A34A),
      ColorTone.mid => const Color(0xFFD97706),
      ColorTone.bad => const Color(0xFFDC2626),
      ColorTone.muted => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
