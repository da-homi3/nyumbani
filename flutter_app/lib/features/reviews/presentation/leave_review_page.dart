import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/reviews/data/reviews_repository.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';

final reviewEligibilityProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, propertyId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;
  return ref.watch(mobileApiRepositoryProvider).reviewEligibility(propertyId);
});

class LeaveReviewPage extends ConsumerStatefulWidget {
  const LeaveReviewPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<LeaveReviewPage> createState() => _LeaveReviewPageState();
}

class _LeaveReviewPageState extends ConsumerState<LeaveReviewPage> {
  final _commentCtrl = TextEditingController();
  var _overall = 4.0;
  var _water = 4.0;
  var _security = 4.0;
  var _internet = 4.0;
  var _electricity = 4.0;
  var _cleanliness = 4.0;
  var _accessibility = 4.0;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      context.push(loginLocation(from: '/property/${widget.propertyId}/review'));
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(mobileApiRepositoryProvider).createReview({
        'propertyId': widget.propertyId,
        'ratingOverall': _overall.round(),
        'waterReliability': _water.round(),
        'securityRating': _security.round(),
        'internetReliability': _internet.round(),
        'electricityReliability': _electricity.round(),
        'cleanliness': _cleanliness.round(),
        'accessibility': _accessibility.round(),
        'comment': _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      });
      ref.invalidate(listingReviewsProvider(widget.propertyId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted. Thank you!')),
      );
      context.pop();
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not submit review.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openWebViewing() async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/tenant/property/${widget.propertyId}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final eligibilityAsync = session == null
        ? null
        : ref.watch(reviewEligibilityProvider(widget.propertyId));

    final eligible = eligibilityAsync?.maybeWhen(
          data: (m) => m?['eligible'] == true,
          orElse: () => true,
        ) ??
        true;
    final reason = eligibilityAsync?.maybeWhen(
          data: (m) => m?['reason'] as String?,
          orElse: () => null,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Leave a review')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Rate this home',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'You can review after a completed viewing or active tenancy.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (session != null && eligibilityAsync != null) ...[
            const SizedBox(height: 12),
            eligibilityAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (m) {
                if (m == null || m['eligible'] == true) {
                  return const SizedBox.shrink();
                }
                return Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          reason ??
                              'Complete a viewing or tenancy before leaving a review.',
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _openWebViewing,
                          child: const Text('Book a viewing on the website'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 20),
          _RatingSlider(
            label: 'Overall',
            value: _overall,
            onChanged: eligible ? (v) => setState(() => _overall = v) : null,
          ),
          _RatingSlider(
            label: 'Water',
            value: _water,
            onChanged: eligible ? (v) => setState(() => _water = v) : null,
          ),
          _RatingSlider(
            label: 'Security',
            value: _security,
            onChanged: eligible ? (v) => setState(() => _security = v) : null,
          ),
          _RatingSlider(
            label: 'Internet',
            value: _internet,
            onChanged: eligible ? (v) => setState(() => _internet = v) : null,
          ),
          _RatingSlider(
            label: 'Electricity',
            value: _electricity,
            onChanged: eligible ? (v) => setState(() => _electricity = v) : null,
          ),
          _RatingSlider(
            label: 'Cleanliness',
            value: _cleanliness,
            onChanged: eligible ? (v) => setState(() => _cleanliness = v) : null,
          ),
          _RatingSlider(
            label: 'Accessibility',
            value: _accessibility,
            onChanged: eligible ? (v) => setState(() => _accessibility = v) : null,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentCtrl,
            enabled: eligible,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (!eligible || _busy) ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit review'),
          ),
        ],
      ),
    );
  }
}

class _RatingSlider extends StatelessWidget {
  const _RatingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${value.round()} / 5'),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
