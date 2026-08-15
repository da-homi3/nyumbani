import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 28, this.markOnly = false});

  final double height;
  final bool markOnly;

  @override
  Widget build(BuildContext context) {
    final asset = markOnly ? NyumbaTokens.iconAsset : NyumbaTokens.logoAsset;
    final url = markOnly ? NyumbaTokens.iconUrl : NyumbaTokens.logoUrl;
    final radius = markOnly ? height / 2 : 6.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: NyumbaTokens.cocoa,
        child: SizedBox(
          height: height,
          width: markOnly ? height : null,
          child: Image.asset(
            asset,
            height: height,
            width: markOnly ? height : null,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => CachedNetworkImage(
              imageUrl: url,
              height: height,
              width: markOnly ? height : null,
              fit: BoxFit.cover,
              fadeInDuration: NyumbaTokens.durationFast,
              placeholder: (_, _) =>
                  _MarkFallback(height: height, markOnly: markOnly),
              errorWidget: (_, _, _) =>
                  _MarkFallback(height: height, markOnly: markOnly),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkFallback extends StatelessWidget {
  const _MarkFallback({required this.height, required this.markOnly});
  final double height;
  final bool markOnly;

  @override
  Widget build(BuildContext context) {
    if (!markOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: Text(
            'NyumbaSearch',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: height * 0.4,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: height,
      child: Icon(
        Icons.travel_explore,
        color: const Color(0xFFE7D5C4),
        size: height * 0.62,
      ),
    );
  }
}
