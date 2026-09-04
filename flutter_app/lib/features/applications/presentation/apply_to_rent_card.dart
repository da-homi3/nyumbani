import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/applications/data/tenant_applications_providers.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';

/// Apply to rent from a property detail page (mobile BFF wave23).
class ApplyToRentCard extends ConsumerStatefulWidget {
  const ApplyToRentCard({
    super.key,
    required this.listingId,
    required this.listingTitle,
  });

  final String listingId;
  final String listingTitle;

  @override
  ConsumerState<ApplyToRentCard> createState() => _ApplyToRentCardState();
}

class _ApplyToRentCardState extends ConsumerState<ApplyToRentCard> {
  final _messageCtrl = TextEditingController();
  var _shareProfile = true;
  var _busy = false;
  String? _error;
  DateTime? _moveInDate;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMoveInDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _moveInDate = picked);
  }

  Future<void> _submit() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      context.push(loginLocation(from: '/property/${widget.listingId}'));
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(mobileApiRepositoryProvider).submitRentalApplication(
            propertyId: widget.listingId,
            message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
            moveInDate: _moveInDate == null
                ? null
                : '${_moveInDate!.year.toString().padLeft(4, '0')}-'
                    '${_moveInDate!.month.toString().padLeft(2, '0')}-'
                    '${_moveInDate!.day.toString().padLeft(2, '0')}',
            shareProfile: _shareProfile,
          );
      ref.invalidate(tenantApplicationsProvider);
      ref.invalidate(propertyApplicationProvider(widget.listingId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted.')),
      );
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not submit application.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingAsync = ref.watch(propertyApplicationProvider(widget.listingId));

    return existingAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(minHeight: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (existing) {
        if (existing != null) {
          final status = existing['status']?.toString() ?? 'submitted';
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Application sent',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Status: ${formatApplicationStatus(status)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.push('/applications'),
                    child: const Text('View my applications'),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Apply to rent',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Send your tenant profile and a short note to the landlord for ${widget.listingTitle}.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageCtrl,
                  enabled: !_busy,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    hintText: 'Why this home fits you, household size, pets…',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickMoveInDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    _moveInDate == null
                        ? 'Preferred move-in date (optional)'
                        : 'Move-in: ${_moveInDate!.toLocal().toString().split(' ').first}',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _shareProfile,
                  onChanged: _busy ? null : (v) => setState(() => _shareProfile = v),
                  title: const Text('Include tenant profile score'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.description_outlined),
                  label: const Text('Submit application'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TenantApplicationsPage extends ConsumerWidget {
  const TenantApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    final theme = Theme.of(context);

    if (sessionAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = sessionAsync.valueOrNull;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Applications')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to track applications',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(loginLocation(from: '/applications')),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(tenantApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My applications')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(tenantApplicationsProvider),
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(tenantApplicationsProvider),
          builder: (apps) {
            if (apps.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 48),
                  EmptyState(
                    icon: Icons.description_outlined,
                    title: 'No applications yet',
                    subtitle: 'Tap Apply on a listing to send your profile to a landlord.',
                    actionLabel: 'Browse homes',
                    onAction: () => context.go('/search'),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: apps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final app = apps[i];
                final property = app['property'] is Map
                    ? Map<String, dynamic>.from(app['property'] as Map)
                    : const <String, dynamic>{};
                final title = property['title']?.toString() ?? 'Listing';
                final propertyId = property['id']?.toString();
                final status = app['status']?.toString() ?? '';
                final score = app['tenant_score_percent'];
                final message = app['message']?.toString();

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
                              label: Text(formatApplicationStatus(status)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        if (score != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Profile score at submission: $score%',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        if (message != null && message.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(message),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (propertyId != null)
                              OutlinedButton(
                                onPressed: () => context.push('/property/$propertyId'),
                                child: const Text('View listing'),
                              ),
                            if (isActiveApplicationStatus(status))
                              TextButton(
                                onPressed: () async {
                                  final id = app['id']?.toString();
                                  if (id == null) return;
                                  try {
                                    await ref
                                        .read(mobileApiRepositoryProvider)
                                        .withdrawRentalApplication(id);
                                    ref.invalidate(tenantApplicationsProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Application withdrawn.')),
                                      );
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e is AppFailure
                                              ? e.message
                                              : 'Could not withdraw application.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Withdraw'),
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
