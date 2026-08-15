import 'package:flutter/material.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

/// Animated verification progress rail (web VerificationPipeline parity).
class VerificationPipeline extends StatelessWidget {
  const VerificationPipeline({
    super.key,
    required this.activeStep,
    this.steps = const ['Request', 'Pay', 'Check', 'Result'],
  });

  /// 0-based index of the current step (clamped).
  final int activeStep;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = activeStep.clamp(0, steps.length - 1);

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: i <= current ? 1 : 0),
                      duration: NyumbaTokens.durationMedium,
                      curve: NyumbaTokens.easeOutSoft,
                      builder: (context, t, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: t,
                            minHeight: 3,
                            backgroundColor:
                                theme.colorScheme.outline.withValues(alpha: 0.25),
                            color: theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              _StepDot(
                index: i,
                label: steps[i],
                state: i < current
                    ? _StepState.done
                    : i == current
                        ? _StepState.active
                        : _StepState.todo,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                    color: i <= current
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

enum _StepState { todo, active, done }

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.state,
  });

  final int index;
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = state != _StepState.todo;
    final color = switch (state) {
      _StepState.done => theme.colorScheme.primary,
      _StepState.active => theme.colorScheme.primary,
      _StepState.todo => theme.colorScheme.outline.withValues(alpha: 0.45),
    };

    return Semantics(
      label: 'Step ${index + 1}: $label',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: state == _StepState.active ? 1.12 : 1),
        duration: NyumbaTokens.durationFast,
        curve: NyumbaTokens.easeSpring,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? color.withValues(alpha: state == _StepState.active ? 0.2 : 1)
                : Colors.transparent,
            border: Border.all(color: color, width: 2),
            boxShadow: state == _StepState.active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: state == _StepState.done
              ? Icon(Icons.check, size: 14, color: theme.colorScheme.onPrimary)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: state == _StepState.active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Maps verification request status strings onto pipeline step index.
int verificationPipelineStep(String? status, {bool awaitingPayment = false}) {
  if (awaitingPayment) return 1;
  final s = (status ?? '').toLowerCase();
  if (s.contains('complete') ||
      s.contains('verified') ||
      s.contains('pass') ||
      s.contains('fail') ||
      s.contains('reject')) {
    return 3;
  }
  if (s.contains('progress') ||
      s.contains('review') ||
      s.contains('check') ||
      s.contains('inspect') ||
      s.contains('paid')) {
    return 2;
  }
  if (s.contains('pending') || s.contains('unpaid') || s.contains('created')) {
    return 1;
  }
  return 0;
}
