import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/analytics/analytics_client.dart';
import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/maps/data/map_providers.dart';
import 'package:nyumbasearch/features/properties/presentation/property_card.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';

class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);

    if (sessionAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = sessionAsync.valueOrNull;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to save homes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('Favorites sync to your NyumbaSearch account.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(loginLocation(from: '/saved')),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(savedListingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savedListingsProvider);
          await ref.read(savedIdsProvider.notifier).refresh();
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () {
            ref.invalidate(savedListingsProvider);
            ref.read(savedIdsProvider.notifier).refresh();
          },
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 48),
                  EmptyState(
                    icon: Icons.favorite_border,
                    title: 'No saved homes yet',
                    subtitle: 'Tap the heart on a listing to build your shortlist.',
                    actionLabel: 'Browse homes',
                    onAction: () => context.go('/search'),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) => PropertyCard(listing: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class FavoriteButton extends ConsumerStatefulWidget {
  const FavoriteButton({
    super.key,
    required this.propertyId,
    this.color,
    this.activeColor,
  });

  final String propertyId;
  final Color? color;
  final Color? activeColor;

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      final from = GoRouterState.of(context).uri.toString();
      context.push(loginLocation(from: from));
      return;
    }
    final wasSaved =
        ref.read(savedIdsProvider).valueOrNull?.contains(widget.propertyId) ?? false;
    try {
      await ref.read(savedIdsProvider.notifier).toggle(widget.propertyId);
      if (!wasSaved) {
        ref.read(analyticsProvider).track(
          AnalyticsEvents.propertySaved,
          {'propertyId': widget.propertyId},
        );
        await _pop.forward(from: 0);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppFailure ? e.message : 'Could not update saved homes.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedIds = ref.watch(savedIdsProvider).valueOrNull ?? {};
    final isSaved = savedIds.contains(widget.propertyId);
    final savedColor = widget.activeColor ?? Theme.of(context).colorScheme.error;

    return IconButton(
      tooltip: isSaved ? 'Remove from saved' : 'Save home',
      onPressed: _toggle,
      icon: ScaleTransition(
        scale: TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1, end: 1.35), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 0.9, end: 1), weight: 35),
        ]).animate(CurvedAnimation(parent: _pop, curve: NyumbaTokens.easeSpring)),
        child: Icon(
          isSaved ? Icons.favorite : Icons.favorite_border,
          color: isSaved ? savedColor : widget.color,
        ),
      ),
    );
  }
}

