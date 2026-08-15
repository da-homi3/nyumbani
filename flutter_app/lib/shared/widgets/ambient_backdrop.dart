import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

/// Soft glowing orbs + particle field — closer stand-in for web HeroScene3D (R3F).
///
/// Matches web palette (`#1EB88A` / `#F6AD55` / `#12856B`), ~70 points with slow
/// field rotation, and pointer-linked camera drift (passive; does not steal taps).
class HeroOrbsLayer extends StatefulWidget {
  const HeroOrbsLayer({super.key, this.particleCount = 70});

  final int particleCount;

  @override
  State<HeroOrbsLayer> createState() => _HeroOrbsLayerState();
}

class _HeroOrbsLayerState extends State<HeroOrbsLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  Offset _pointerNorm = Offset.zero; // -1..1
  Offset _camera = Offset.zero;

  // Web GlowOrb colors / relative scales.
  static const _jade = Color(0xFF1EB88A);
  static const _gold = Color(0xFFF6AD55);
  static const _forest = Color(0xFF12856B);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _elapsed = elapsed;
      // Ease camera toward pointer (web CameraRig ~0.02 lerp).
      _camera += (_pointerNorm - _camera) * 0.02;
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _trackPointer(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final nx = ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
    final ny = -((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0);
    _pointerNorm = Offset(nx.toDouble(), ny.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final enabled = TickerMode.valuesOf(context).enabled;
    if (!enabled && _ticker.isActive) {
      _ticker.stop();
    } else if (enabled && !_ticker.isActive) {
      _ticker.start();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerHover: (e) => _trackPointer(e.localPosition, size),
          onPointerMove: (e) => _trackPointer(e.localPosition, size),
          child: IgnorePointer(
            child: CustomPaint(
              size: size,
              painter: _OrbsPainter(
                t: _elapsed.inMilliseconds / 1000.0,
                camera: _camera,
                particleCount: widget.particleCount,
                jade: _jade,
                gold: _gold,
                forest: _forest,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrbsPainter extends CustomPainter {
  _OrbsPainter({
    required this.t,
    required this.camera,
    required this.particleCount,
    required this.jade,
    required this.gold,
    required this.forest,
  });

  final double t;
  final Offset camera;
  final int particleCount;
  final Color jade;
  final Color gold;
  final Color forest;

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle forest → jade → gold wash under orbs.
    final wash = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.1),
        Offset(size.width, size.height * 0.9),
        [
          forest.withValues(alpha: 0.16),
          jade.withValues(alpha: 0.10),
          gold.withValues(alpha: 0.07),
          Colors.transparent,
        ],
        const [0.0, 0.35, 0.65, 1.0],
      );
    canvas.drawRect(Offset.zero & size, wash);

    final cx = size.width * 0.5 + camera.dx * size.width * 0.06;
    final cy = size.height * 0.42 + camera.dy * size.height * 0.04;

    // Orb layout mirrors web: left jade 1.8, right gold 1.2, top forest 2.2.
    final orbs = <({Offset c, double r, Color color, double bob})>[
      (
        c: Offset(
          cx + size.width * -0.28,
          cy + size.height * -0.08 + math.sin(t * 0.5 - 0.9) * size.height * 0.03,
        ),
        r: size.shortestSide * 0.38,
        color: jade,
        bob: 0.06,
      ),
      (
        c: Offset(
          cx + size.width * 0.30,
          cy + size.height * 0.10 + math.sin(t * 0.5 + 0.9) * size.height * 0.028,
        ),
        r: size.shortestSide * 0.26,
        color: gold,
        bob: 0.05,
      ),
      (
        c: Offset(
          cx,
          cy + size.height * -0.22 + math.sin(t * 0.5) * size.height * 0.032,
        ),
        r: size.shortestSide * 0.46,
        color: forest,
        bob: 0.04,
      ),
    ];

    for (final o in orbs) {
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          o.c,
          o.r,
          [
            o.color.withValues(alpha: o.bob),
            o.color.withValues(alpha: 0.0),
          ],
        );
      canvas.drawCircle(o.c, o.r, paint);
    }

    // FloatingParticles: slow field rotation + vertical sin bob.
    final rot = t * 0.02;
    final bobY = math.sin(t * 0.3) * size.height * 0.012;
    final jadeDot = Paint()..color = jade.withValues(alpha: 0.50);
    final goldDot = Paint()..color = gold.withValues(alpha: 0.35);

    for (var i = 0; i < particleCount; i++) {
      final seed = i * 12.9898;
      final px = (math.sin(seed) * 0.5) * size.width * 0.95;
      final py = (math.cos(seed * 1.3) * 0.5) * size.height * 0.7;
      final pz = (math.sin(seed * 0.7) * 0.5) - 0.15;
      final x = px * math.cos(rot) - (pz * size.width * 0.12) * math.sin(rot);
      final z = px * math.sin(rot) + (pz * size.width * 0.12) * math.cos(rot);
      final depth = (0.55 + (z / size.width + 0.5).clamp(0.0, 1.0) * 0.45);
      final c = Offset(cx + x * depth, cy + py * depth + bobY);
      final radius = (1.0 + (i % 4) * 0.4) * depth;
      canvas.drawCircle(c, radius, i % 7 == 0 ? goldDot : jadeDot);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbsPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.camera != camera ||
      oldDelegate.particleCount != particleCount;
}

/// Drifting housing glyphs — Flutter port of web AmbientBackdrop.
class AmbientBackdrop extends StatefulWidget {
  const AmbientBackdrop({
    super.key,
    this.opacity = 0.55,
    this.particleCount = 14,
  });

  final double opacity;
  final int particleCount;

  @override
  State<AmbientBackdrop> createState() => _AmbientBackdropState();
}

class _AmbientBackdropState extends State<AmbientBackdrop>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  Size _size = Size.zero;
  List<_Particle> _particles = const [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _elapsed = elapsed;
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ensureParticles(Size size) {
    if (size == _size && _particles.isNotEmpty) return;
    _size = size;
    final rnd = math.Random(size.width.toInt() ^ size.height.toInt());
    _particles = List.generate(widget.particleCount, (_) {
      final speed = 0.05 + rnd.nextDouble() * 0.14;
      final angle = rnd.nextDouble() * math.pi * 2;
      return _Particle(
        x: rnd.nextDouble() * size.width,
        y: rnd.nextDouble() * size.height,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed * 0.65 - 0.02,
        size: 12 + rnd.nextDouble() * 16,
        rot: rnd.nextDouble() * math.pi * 2,
        vr: (rnd.nextDouble() - 0.5) * 0.008,
        kind: _ParticleKind.values[rnd.nextInt(_ParticleKind.values.length)],
        alpha: 0.16 + rnd.nextDouble() * 0.12,
        phase: rnd.nextDouble() * math.pi * 2,
        phaseSpeed: 0.002 + rnd.nextDouble() * 0.006,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = TickerMode.valuesOf(context).enabled;
    if (!enabled && _ticker.isActive) {
      _ticker.stop();
    } else if (enabled && !_ticker.isActive) {
      _ticker.start();
    }

    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            if (size.width <= 0 || size.height <= 0) {
              return const SizedBox.shrink();
            }
            _ensureParticles(size);
            final t = _elapsed.inMilliseconds / 16.0;
            for (final p in _particles) {
              p.x += p.vx;
              p.y += p.vy + math.sin(p.phase + t * p.phaseSpeed) * 0.15;
              p.rot += p.vr;
              if (p.x < -40) p.x = size.width + 20;
              if (p.x > size.width + 40) p.x = -20;
              if (p.y < -40) p.y = size.height + 20;
              if (p.y > size.height + 40) p.y = -20;
            }
            return CustomPaint(
              size: size,
              painter: _AmbientPainter(
                particles: _particles,
                color: NyumbaTokens.primaryGlowDark,
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _ParticleKind { home, key, wrench, tri, hex }

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rot,
    required this.vr,
    required this.kind,
    required this.alpha,
    required this.phase,
    required this.phaseSpeed,
  });

  double x;
  double y;
  double vx;
  double vy;
  double size;
  double rot;
  double vr;
  _ParticleKind kind;
  double alpha;
  double phase;
  double phaseSpeed;
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({required this.particles, required this.color});

  final List<_Particle> particles;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: p.alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      final s = p.size;
      switch (p.kind) {
        case _ParticleKind.home:
          final path = Path()
            ..moveTo(0, -s * 0.35)
            ..lineTo(s * 0.35, 0)
            ..lineTo(s * 0.22, 0)
            ..lineTo(s * 0.22, s * 0.35)
            ..lineTo(-s * 0.22, s * 0.35)
            ..lineTo(-s * 0.22, 0)
            ..lineTo(-s * 0.35, 0)
            ..close();
          canvas.drawPath(path, paint);
        case _ParticleKind.key:
          canvas.drawCircle(Offset(-s * 0.12, 0), s * 0.14, paint);
          canvas.drawLine(
            Offset(-s * 0.0, 0),
            Offset(s * 0.32, 0),
            paint,
          );
          canvas.drawLine(
            Offset(s * 0.22, 0),
            Offset(s * 0.22, s * 0.12),
            paint,
          );
        case _ParticleKind.wrench:
          final wrench = Path()
            ..moveTo(-s * 0.25, -s * 0.1)
            ..lineTo(s * 0.25, s * 0.1)
            ..moveTo(s * 0.1, -s * 0.2)
            ..lineTo(s * 0.28, -s * 0.05);
          canvas.drawPath(wrench, paint);
        case _ParticleKind.tri:
          final tri = Path()
            ..moveTo(0, -s * 0.3)
            ..lineTo(s * 0.28, s * 0.25)
            ..lineTo(-s * 0.28, s * 0.25)
            ..close();
          canvas.drawPath(tri, paint);
        case _ParticleKind.hex:
          final hex = Path();
          for (var i = 0; i < 6; i++) {
            final a = i * math.pi / 3;
            final x = math.cos(a) * s * 0.3;
            final y = math.sin(a) * s * 0.3;
            if (i == 0) {
              hex.moveTo(x, y);
            } else {
              hex.lineTo(x, y);
            }
          }
          hex.close();
          canvas.drawPath(hex, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => true;
}
