import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

/// Floating NyumbaAI FAB with pulse + cycling robot scenes (web AiAssistant).
class NyumbaAiFab extends StatefulWidget {
  const NyumbaAiFab({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<NyumbaAiFab> createState() => _NyumbaAiFabState();
}

class _NyumbaAiFabState extends State<NyumbaAiFab> {
  static const _scenes = <IconData>[
    Icons.smart_toy_outlined,
    Icons.search,
    Icons.key_outlined,
    Icons.directions_car_outlined,
  ];
  var _scene = 0;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 2800));
      if (!mounted) return false;
      setState(() => _scene = (_scene + 1) % _scenes.length);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF22C55E).withValues(alpha: 0.18),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1.12, 1.12),
              duration: 1400.ms,
            )
            .fade(begin: 0.55, end: 0.15, duration: 1400.ms),
        FloatingActionButton(
          heroTag: 'nyumba-ai-fab',
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          onPressed: widget.onPressed ?? () => context.push('/plus'),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Icon(_scenes[_scene], key: ValueKey(_scene)),
          ),
        ),
      ],
    );
  }
}

/// Ask NyumbaAI pill bar.
class AskNyumbaAiBar extends StatelessWidget {
  const AskNyumbaAiBar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap ?? () => context.push('/plus'),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 16, color: NyumbaTokens.gold),
              const SizedBox(width: 8),
              Text(
                'Ask NyumbaAI',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
