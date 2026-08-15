import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dense, horizontally scrollable DataTable for PM portal tabs.
class PmDenseDataTable extends StatelessWidget {
  const PmDenseDataTable({
    super.key,
    required this.minWidth,
    required this.columns,
    required this.rows,
    this.padding = const EdgeInsets.fromLTRB(8, 4, 8, 28),
  });

  final double minWidth;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : minWidth;
        final showHint = minWidth > width + 8;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHint)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.swipe,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Swipe for more columns',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: showHint,
                thickness: 3,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: math.max(minWidth, width),
                    ),
                    child: Theme(
                      data: theme.copyWith(
                        dataTableTheme: DataTableThemeData(
                          headingRowColor: WidgetStatePropertyAll(
                            theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.55),
                          ),
                          dividerThickness: 0.6,
                        ),
                      ),
                      child: DataTable(
                        columnSpacing: 14,
                        horizontalMargin: 10,
                        headingRowHeight: 36,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 52,
                        headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                        dataTextStyle: theme.textTheme.bodySmall,
                        columns: columns,
                        rows: rows,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
