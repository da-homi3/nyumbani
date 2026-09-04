import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/viewings/data/viewings_providers.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';

const _timeSlots = ['09:00', '11:00', '14:00', '16:00'];

class BookViewingCard extends ConsumerStatefulWidget {
  const BookViewingCard({
    super.key,
    required this.listingId,
    required this.listingTitle,
  });

  final String listingId;
  final String listingTitle;

  @override
  ConsumerState<BookViewingCard> createState() => _BookViewingCardState();
}

class _BookViewingCardState extends ConsumerState<BookViewingCard> {
  DateTime? _date;
  String? _time;
  final _notesCtrl = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  List<DateTime> _nextBookableDays() {
    final days = <DateTime>[];
    final now = DateTime.now();
    for (var i = 1; i <= 14; i++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      if (day.weekday != DateTime.sunday) days.add(day);
    }
    return days;
  }

  String _scheduledAtIso(DateTime date, String time) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-${d}T$time:00+03:00';
  }

  Future<void> _book() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      context.push(loginLocation(from: '/property/${widget.listingId}'));
      return;
    }
    if (_date == null || _time == null) {
      setState(() => _error = 'Pick a date and time slot.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(mobileApiRepositoryProvider).bookViewing(
            propertyId: widget.listingId,
            scheduledAt: _scheduledAtIso(_date!, _time!),
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      ref.invalidate(tenantViewingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viewing request sent.')),
      );
      setState(() {
        _date = null;
        _time = null;
        _notesCtrl.clear();
      });
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not book viewing.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _nextBookableDays();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Book a viewing',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a weekday slot for ${widget.listingTitle}. The landlord confirms by message.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text('Date', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final day in days)
                  ChoiceChip(
                    label: Text('${day.day}/${day.month}'),
                    selected: _date?.year == day.year &&
                        _date?.month == day.month &&
                        _date?.day == day.day,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() {
                              _date = day;
                              _time = null;
                            }),
                  ),
              ],
            ),
            if (_date != null) ...[
              const SizedBox(height: 12),
              Text('Time (EAT)', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in _timeSlots)
                    ChoiceChip(
                      label: Text(slot),
                      selected: _time == slot,
                      onSelected: _busy ? null : (_) => setState(() => _time = slot),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              enabled: !_busy,
              maxLines: 2,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Who is coming, access needs, etc.',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _book,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calendar_month_outlined),
              label: const Text('Request viewing'),
            ),
          ],
        ),
      ),
    );
  }
}

class TenantViewingsPage extends ConsumerWidget {
  const TenantViewingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Viewings')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/viewings')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(tenantViewingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My viewings')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(tenantViewingsProvider),
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(tenantViewingsProvider),
          builder: (viewings) {
            final tenantViewings = viewings
                .where((v) => v['tenant_id']?.toString() == session.user.id)
                .toList();

            if (tenantViewings.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 48),
                  EmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'No viewings scheduled',
                    subtitle: 'Book a viewing from any listing detail page.',
                    actionLabel: 'Browse homes',
                    onAction: () => context.go('/search'),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: tenantViewings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final viewing = tenantViewings[i];
                final property = viewing['properties'] is Map
                    ? Map<String, dynamic>.from(viewing['properties'] as Map)
                    : const <String, dynamic>{};
                final title = property['title']?.toString() ?? 'Listing';
                final propertyId = property['id']?.toString();
                final status = viewing['status']?.toString() ?? '';
                final scheduledAt = viewing['scheduled_at']?.toString() ?? '';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(formatViewingStatus(status)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        if (scheduledAt.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(scheduledAt.replaceFirst('T', ' · ').split('.').first),
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (propertyId != null)
                              OutlinedButton(
                                onPressed: () => context.push('/property/$propertyId'),
                                child: const Text('View listing'),
                              ),
                            if (isUpcomingViewing(viewing))
                              TextButton(
                                onPressed: () async {
                                  final id = viewing['id']?.toString();
                                  if (id == null) return;
                                  try {
                                    await ref
                                        .read(mobileApiRepositoryProvider)
                                        .updateViewingStatus(
                                          viewingId: id,
                                          status: 'cancelled',
                                        );
                                    ref.invalidate(tenantViewingsProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Viewing cancelled.')),
                                      );
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e is AppFailure
                                              ? e.message
                                              : 'Could not cancel viewing.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Cancel'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
