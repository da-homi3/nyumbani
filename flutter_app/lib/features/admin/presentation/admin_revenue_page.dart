import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class AdminRevenuePage extends ConsumerWidget {
  const AdminRevenuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminRevenueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Revenue')),
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(adminRevenueProvider),
        builder: (data) {
          final latest = Map<String, dynamic>.from((data['latest'] as Map?) ?? {});
          final chartRaw = (data['chart'] as List?) ?? const [];
          final chart = chartRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final theme = Theme.of(context);

          return ListView(
            padding: const EdgeInsets.all(NyumbaTokens.space6),
            children: [
              Text(
                'Live data from completed payments',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: 'MRR (month)',
                    value: _kes(latest['mrr'] ?? data['mrrKes'] ?? 0),
                    accent: theme.colorScheme.primary,
                  ),
                  _StatCard(
                    label: 'Verification',
                    value: _kes(latest['verification'] ?? 0),
                    accent: const Color(0xFF1EB88A),
                  ),
                  _StatCard(
                    label: 'Lead packs',
                    value: _kes(latest['leads'] ?? 0),
                    accent: NyumbaTokens.gold,
                  ),
                  _StatCard(
                    label: 'Plus members',
                    value: '${data['plusMembers'] ?? 0}',
                    accent: theme.colorScheme.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Last 6 months', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Stacked: MRR · boosts · verification · leads · plus',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (chart.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No payment history yet.')),
                )
              else ...[
                SizedBox(
                  height: 220,
                  child: _RevenueBarChart(rows: chart),
                ),
                const SizedBox(height: 16),
                const _ChartLegend(),
                const SizedBox(height: 8),
                for (final row in chart)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        '${row['month']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'MRR ${_kes(row['mrr'])} · boosts ${_kes(row['boosts'])} · '
                        'verify ${_kes(row['verification'])} · leads ${_kes(row['leads'])} · '
                        'plus ${_kes(row['plus'])}',
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _kes(Object? v) {
  final n = (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
  if (n >= 1000000) return 'KES ${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return 'KES ${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
  return 'KES $n';
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
  });
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 168,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: NyumbaTokens.borderRadius,
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.35)),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    const items = <(Color, String)>[
      (NyumbaTokens.primaryDark, 'MRR'),
      (Color(0xFF3B82F6), 'Boosts'),
      (Color(0xFF1EB88A), 'Verify'),
      (Color(0xFFF6AD55), 'Leads'),
      (Color(0xFFA78BFA), 'Plus'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final (c, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, color: c),
              const SizedBox(width: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
      ],
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RevenueChartPainter(
        rows: rows,
        labelStyle: Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
        axisColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  _RevenueChartPainter({
    required this.rows,
    required this.labelStyle,
    required this.axisColor,
  });

  final List<Map<String, dynamic>> rows;
  final TextStyle labelStyle;
  final Color axisColor;

  static const _stack = <(String, Color)>[
    ('mrr', NyumbaTokens.primaryDark),
    ('boosts', Color(0xFF3B82F6)),
    ('verification', Color(0xFF1EB88A)),
    ('leads', Color(0xFFF6AD55)),
    ('plus', Color(0xFFA78BFA)),
  ];

  double _num(Map<String, dynamic> row, String key) {
    final v = row[key];
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty) return;
    const left = 8.0;
    const bottom = 28.0;
    const top = 8.0;
    final chartH = size.height - bottom - top;
    final chartW = size.width - left - 8;
    final totals = rows
        .map(
          (r) => _stack.fold<double>(0, (s, e) => s + _num(r, e.$1)),
        )
        .toList();
    final maxY = math.max(1.0, totals.fold<double>(0, math.max));
    final barW = chartW / rows.length * 0.55;
    final gap = chartW / rows.length;

    final grid = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + chartH * (1 - i / 3);
      canvas.drawLine(Offset(left, y), Offset(size.width - 8, y), grid);
    }

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final x0 = left + gap * i + (gap - barW) / 2;
      var y = top + chartH;
      for (final (key, color) in _stack) {
        final v = _num(row, key);
        if (v <= 0) continue;
        final h = (v / maxY) * chartH;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x0, y - h, barW, h),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, Paint()..color = color);
        y -= h;
      }
      final label = '${row['month'] ?? ''}';
      final short = label.length > 7 ? label.substring(5) : label;
      final tp = TextPainter(
        text: TextSpan(text: short, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: gap);
      tp.paint(
        canvas,
        Offset(left + gap * i + (gap - tp.width) / 2, size.height - bottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) =>
      oldDelegate.rows != rows;
}

final adminRevenueProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(mobileApiRepositoryProvider).adminRevenue();
});
