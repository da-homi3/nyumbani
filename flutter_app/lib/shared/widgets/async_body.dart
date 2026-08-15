import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';

class AsyncSliverBody<T> extends StatelessWidget {
  const AsyncSliverBody({
    super.key,
    required this.async,
    required this.data,
    required this.onRetry,
    this.compact = false,
  });

  final AsyncValue<T> async;
  final Widget Function(T value) data;
  final VoidCallback onRetry;
  /// When true, loading/error stay inline (home featured) instead of filling the viewport.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return async.when(
      data: data,
      loading: () => compact
          ? const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          : const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
      error: (err, _) {
        final message = _friendlyErrorMessage(err);
        final body = Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        );
        return compact
            ? SliverToBoxAdapter(child: body)
            : SliverFillRemaining(hasScrollBody: false, child: body);
      },
    );
  }
}

String _friendlyErrorMessage(Object err) {
  if (err is AppFailure) return err.message;
  final raw = err.toString().toLowerCase();
  if (raw.contains('failed host lookup') ||
      raw.contains('socketexception') ||
      raw.contains('connection errored')) {
    return 'Can’t reach NyumbaSearch right now (DNS / no internet). '
        'On an emulator, check Wi‑Fi or restart with DNS 8.8.8.8, then tap Retry.';
  }
  return 'Something went wrong. Please try again.';
}

class AsyncScaffoldBody<T> extends StatelessWidget {
  const AsyncScaffoldBody({
    super.key,
    required this.async,
    required this.builder,
    required this.onRetry,
  });

  final AsyncValue<T> async;
  final Widget Function(T value) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return async.when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) {
        return Center(
          child: EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Couldn’t load this screen',
            subtitle: _friendlyErrorMessage(err),
            actionLabel: 'Retry',
            onAction: onRetry,
          ),
        );
      },
    );
  }
}
