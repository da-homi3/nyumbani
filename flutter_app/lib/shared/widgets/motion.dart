import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

/// Count-up when first built (web AnimatedStat).
class AnimatedStat extends StatelessWidget {
  const AnimatedStat({
    super.key,
    required this.value,
    required this.label,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1600),
  });

  final num value;
  final String label;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final end = value.toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: end),
      duration: duration,
      curve: NyumbaTokens.easeOutSoft,
      builder: (context, v, _) {
        final display = value is int ? v.round().toString() : v.toStringAsFixed(1);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$display$suffix',
              style: const TextStyle(
                color: NyumbaTokens.primaryGlowDark,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Fade+rise entrance (web ScrollReveal).
class ScrollReveal extends StatelessWidget {
  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 420.ms, curve: NyumbaTokens.easeOutSoft)
        .moveY(begin: 18, end: 0, duration: 420.ms, curve: NyumbaTokens.easeOutExpo);
  }
}

/// Subtle 3D tilt on pointer move (web PropertyCard / NeighborhoodCard3D).
/// Touch: spring press depth (not flat). Pointer devices get hover parallax.
class TiltCard extends StatefulWidget {
  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 0.08,
  });

  final Widget child;
  final double maxTilt;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _dx = 0;
  double _dy = 0;
  double _scale = 1;

  void _reset() {
    setState(() {
      _dx = 0;
      _dy = 0;
      _scale = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) => _reset(),
      child: Listener(
        onPointerHover: (e) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(e.position);
          final nx = (local.dx / box.size.width) * 2 - 1;
          final ny = (local.dy / box.size.height) * 2 - 1;
          setState(() {
            _dx = ny * widget.maxTilt;
            _dy = -nx * widget.maxTilt;
            _scale = 1.035;
          });
        },
        onPointerDown: (_) => setState(() {
          _dx = -widget.maxTilt * 0.4;
          _dy = 0;
          _scale = 0.978;
        }),
        onPointerUp: (_) => _reset(),
        onPointerCancel: (_) => _reset(),
        child: AnimatedContainer(
          duration: NyumbaTokens.durationFast,
          curve: NyumbaTokens.easeSpring,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateX(_dx)
            ..rotateY(_dy)
            ..scaleByDouble(_scale, _scale, _scale, 1),
          transformAlignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Lift card for plan / pricing tiles (web PlanCards hover lift).
class PlanLiftCard extends StatelessWidget {
  const PlanLiftCard({
    super.key,
    required this.child,
    this.highlighted = false,
    this.onTap,
  });

  final Widget child;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TiltCard(
      maxTilt: highlighted ? 0.06 : 0.045,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: NyumbaTokens.borderRadiusLg,
          child: AnimatedContainer(
            duration: NyumbaTokens.durationFast,
            curve: NyumbaTokens.easeOutSoft,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: NyumbaTokens.borderRadiusLg,
              border: Border.all(
                color: highlighted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.45),
                width: highlighted ? 2 : 1,
              ),
              color: highlighted
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              boxShadow: highlighted
                  ? NyumbaTokens.shadowGreen()
                  : NyumbaTokens.shadowSoft(theme.brightness),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
