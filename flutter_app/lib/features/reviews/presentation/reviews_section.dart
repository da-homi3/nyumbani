import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/features/reviews/data/reviews_repository.dart';

class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingReviewsProvider(listingId));
    final theme = Theme.of(context);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) {
        final msg = err is AppFailure ? err.message : 'Could not load reviews.';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tenant reviews',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(msg),
            TextButton(
              onPressed: () => ref.invalidate(listingReviewsProvider(listingId)),
              child: const Text('Retry'),
            ),
          ],
        );
      },
      data: (reviews) {
        final count = reviews.length;
        double avg(double? Function(PropertyReview r) pick) {
          if (count == 0) return 0;
          var sum = 0.0;
          var n = 0;
          for (final r in reviews) {
            final v = pick(r);
            if (v == null) continue;
            sum += v;
            n++;
          }
          return n == 0 ? 0 : sum / n;
        }

        final overall = avg((r) => r.ratingOverall);
        final water = avg((r) => r.waterReliability);
        final security = avg((r) => r.securityRating);
        final internet = avg((r) => r.internetReliability);
        final cleanliness = avg((r) => r.cleanliness);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tenant reviews ($count)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/property/$listingId/review'),
                  child: const Text('Leave review'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (count == 0)
              Text(
                'No reviews yet for this home.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    _Metric(label: 'Overall', value: overall.toStringAsFixed(1)),
                    if (water > 0) _Metric(label: 'Water', value: '${water.toStringAsFixed(1)} / 5'),
                    if (security > 0)
                      _Metric(label: 'Security', value: '${security.toStringAsFixed(1)} / 5'),
                    if (internet > 0)
                      _Metric(label: 'Internet', value: '${internet.toStringAsFixed(1)} / 5'),
                    if (cleanliness > 0)
                      _Metric(label: 'Clean', value: '${cleanliness.toStringAsFixed(1)} / 5'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final r in reviews.take(8)) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Icon(Icons.star, size: 16, color: theme.colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        r.ratingOverall.toStringAsFixed(1),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.reviewerName?.trim().isNotEmpty == true
                              ? r.reviewerName!
                              : 'Tenant',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: (r.comment != null && r.comment!.trim().isNotEmpty)
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(r.comment!),
                        )
                      : null,
                ),
                const Divider(height: 1),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
