import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:nyumbasearch/core/analytics/analytics_client.dart';
import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/compare/data/compare_controller.dart';
import 'package:nyumbasearch/features/favorites/presentation/saved_page.dart';
import 'package:nyumbasearch/features/messages/presentation/message_landlord_card.dart';
import 'package:nyumbasearch/features/applications/presentation/apply_to_rent_card.dart';
import 'package:nyumbasearch/features/viewings/presentation/book_viewing_card.dart';
import 'package:nyumbasearch/features/properties/data/listing.dart';
import 'package:nyumbasearch/features/properties/data/listing_intel.dart';
import 'package:nyumbasearch/features/properties/data/listings_providers.dart';
import 'package:nyumbasearch/features/properties/presentation/contact_unlock_card.dart';
import 'package:nyumbasearch/features/properties/presentation/in_app_media_player.dart';
import 'package:nyumbasearch/features/reviews/presentation/reviews_section.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class PropertyDetailPage extends ConsumerStatefulWidget {
  const PropertyDetailPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends ConsumerState<PropertyDetailPage> {
  var _page = 0;
  var _trackedView = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(listingDetailProvider(widget.propertyId));
    final theme = Theme.of(context);
    final compareIds = ref.watch(compareIdsProvider);

    return Scaffold(
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(listingDetailProvider(widget.propertyId)),
        builder: (listing) {
          if (!_trackedView) {
            _trackedView = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(analyticsProvider).track(
                AnalyticsEvents.propertyViewed,
                {'propertyId': listing.id},
              );
            });
          }
          final inCompare = compareIds.contains(listing.id);
          final intel = ListingIntel.fromAmenities(listing.amenities);
          final images = listing.images;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _GalleryHeader(
                  listing: listing,
                  images: images,
                  page: _page,
                  onPageChanged: (i) => setState(() => _page = i),
                  inCompare: inCompare,
                  onCompare: () async {
                    final ok = await ref
                        .read(compareIdsProvider.notifier)
                        .toggle(listing.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? (inCompare
                                  ? 'Removed from compare'
                                  : 'Added to compare')
                              : 'Compare list is full (max 4)',
                        ),
                      ),
                    );
                  },
                  onShare: () {
                    final url =
                        '${AppConfig.apiBaseUrl}/tenant/property/${listing.id}';
                    ref.read(analyticsProvider).track(
                      AnalyticsEvents.propertyShared,
                      {'propertyId': listing.id},
                    );
                    SharePlus.instance.share(
                      ShareParams(text: '${listing.title}\n$url', subject: listing.title),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.priceLabel,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              listing.neighborhood.isEmpty
                                  ? 'Kenya'
                                  : listing.neighborhood,
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _Stat(label: 'Beds', value: '${listing.bedrooms}')),
                          const SizedBox(width: 8),
                          Expanded(child: _Stat(label: 'Baths', value: '${listing.bathrooms}')),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Stat(
                              label: 'Type',
                              value: listing.propertyType.replaceAll('_', ' '),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Stat(
                              label: 'Status',
                              value: listing.isVacant ? 'Vacant' : 'Listed',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _IntelRow(intel: intel),
                      if (listing.videoUrl != null &&
                          listing.videoUrl!.trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        PropertyMediaSection(
                          title: 'Walkthrough video',
                          icon: Icons.play_circle_outline,
                          child: InAppMediaPlayer(
                            url: listing.videoUrl!.trim(),
                            title: listing.title,
                            kind: InAppMediaKind.video,
                          ),
                        ),
                      ],
                      if (listing.tourUrl != null &&
                          listing.tourUrl!.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        PropertyMediaSection(
                          title: '360° virtual tour',
                          icon: Icons.threed_rotation,
                          hint: 'Drag to look around · plays inside the app',
                          child: InAppMediaPlayer(
                            url: listing.tourUrl!.trim(),
                            title: listing.title,
                            kind: InAppMediaKind.tour,
                          ),
                        ),
                      ],
                      if (listing.description != null &&
                          listing.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Text('About', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          listing.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (listing.amenities.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Text('Amenities', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: listing.amenities
                              .map(
                                (a) => Chip(
                                  label: Text(a.replaceAll('_', ' ')),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ContactUnlockCard(listingId: listing.id),
                      const SizedBox(height: 16),
                      BookViewingCard(
                        listingId: listing.id,
                        listingTitle: listing.title,
                      ),
                      const SizedBox(height: 16),
                      MessageLandlordCard(listingId: listing.id),
                      const SizedBox(height: 16),
                      ApplyToRentCard(
                        listingId: listing.id,
                        listingTitle: listing.title,
                      ),
                      const SizedBox(height: 28),
                      ReviewsSection(listingId: listing.id),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({
    required this.listing,
    required this.images,
    required this.page,
    required this.onPageChanged,
    required this.inCompare,
    required this.onCompare,
    required this.onShare,
  });

  final Listing listing;
  final List<String> images;
  final int page;
  final ValueChanged<int> onPageChanged;
  final bool inCompare;
  final VoidCallback onCompare;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: SizedBox(
        height: 320 + top,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isEmpty)
              ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.home_work_outlined, size: 64)),
              )
            else
              PageView.builder(
                itemCount: images.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, i) => CachedNetworkImage(
                  imageUrl: images[i],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) =>
                      const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66111827), Color(0x00111827), Color(0x99111827)],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            Positioned(
              top: top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  _GlassIconButton(
                    icon: inCompare ? Icons.compare_arrows : Icons.add_to_photos_outlined,
                    onPressed: onCompare,
                  ),
                  const SizedBox(width: 6),
                  _GlassIconButton(icon: Icons.share_outlined, onPressed: onShare),
                  const SizedBox(width: 6),
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
              left: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (listing.isVerified)
                    _OverlayChip(
                      icon: Icons.verified,
                      label: 'Verified',
                      color: theme.colorScheme.primary,
                    ),
                  if (listing.authenticityScore != null) ...[
                    const SizedBox(height: 6),
                    _OverlayChip(
                      icon: Icons.local_fire_department,
                      label: 'Trust ${listing.authenticityScore}',
                      color: Colors.black87,
                    ),
                  ],
                ],
              ),
            ),
            if (images.length > 1)
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${page + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntelRow extends StatelessWidget {
  const _IntelRow({required this.intel});
  final ListingIntel intel;

  Color _color(BuildContext context, String label) {
    final tone = ListingIntel.toneFor(label);
    return switch (tone) {
      ColorTone.good => const Color(0xFF16A34A),
      ColorTone.mid => const Color(0xFFD97706),
      ColorTone.bad => const Color(0xFFDC2626),
      ColorTone.muted => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget chip(IconData icon, String text, String toneKey) {
      final c = _color(context, toneKey);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        chip(Icons.water_drop_outlined, 'Water: ${intel.water}', intel.water),
        chip(Icons.shield_outlined, 'Security: ${intel.security}', intel.security),
        chip(Icons.wifi, intel.internet, intel.internet),
        if (intel.parking)
          chip(Icons.directions_car_outlined, 'Parking', 'Yes'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: NyumbaTokens.borderRadius,
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
