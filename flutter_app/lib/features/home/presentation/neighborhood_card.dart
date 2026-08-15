import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/home/data/hood_meta.dart';
import 'package:nyumbasearch/shared/widgets/motion.dart';

/// Image + price card — Flutter port of web `NeighborhoodCard3D` (tilt via [TiltCard]).
class NeighborhoodCard extends StatelessWidget {
  const NeighborhoodCard({
    super.key,
    required this.name,
    required this.onTap,
  });

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = resolveHoodMeta(name);
    final theme = Theme.of(context);
    final price = meta.fromKes.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    return SizedBox(
      width: 148,
      child: TiltCard(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(NyumbaTokens.radiusXl),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NyumbaTokens.radiusXl),
                boxShadow: NyumbaTokens.shadowCard(theme.brightness),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(NyumbaTokens.radiusXl),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: meta.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const ColoredBox(color: Color(0xFF1A2E28)),
                        errorWidget: (_, _, _) => const ColoredBox(
                          color: Color(0xFF0B1220),
                          child: Center(
                            child: Icon(Icons.place_outlined, color: Colors.white54),
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x1A000000),
                              Color(0x59000000),
                              Color(0xE6000000),
                            ],
                            stops: [0, 0.45, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'From KES $price/mo',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore →',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: NyumbaTokens.primaryGlowDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
