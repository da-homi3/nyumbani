import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/properties/data/listings_providers.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

final savedSearchesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final json = await ref.watch(mobileApiRepositoryProvider).listSavedSearches();
  final raw = json['searches'] ?? json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

Map<String, dynamic> _filtersPayload(SearchFilters f) {
  final out = <String, dynamic>{
    'source': 'mobile',
    'frequency': 'instant',
  };
  if (f.neighborhood != null && f.neighborhood!.trim().isNotEmpty) {
    out['neighborhood'] = f.neighborhood!.trim();
  }
  if (f.locationId != null && f.locationId!.isNotEmpty) {
    out['locationId'] = f.locationId;
  }
  if (f.type != null && f.type!.isNotEmpty && f.type != 'any') {
    out['propertyType'] = f.type;
    out['types'] = [f.type];
  }
  if (f.maxRent != null) {
    out['maxRent'] = f.maxRent;
    out['maxBudget'] = f.maxRent;
  }
  if (f.minRent != null) {
    out['minRent'] = f.minRent;
  }
  if (f.minBedrooms != null) {
    out['bedrooms'] = f.minBedrooms;
  }
  if (f.pricingMode == 'rent' || f.pricingMode == 'sale') {
    out['listingPurpose'] = f.pricingMode;
  }
  if (f.verifiedOnly) {
    out['verifiedLevel2Plus'] = true;
  }
  if (f.requireWater) {
    out['waterGoodOnly'] = true;
  }
  if (f.requireParking) {
    out['parking'] = true;
  }
  if (f.requirePetFriendly) {
    out['petFriendly'] = true;
  }
  if (f.q.trim().isNotEmpty) {
    out['q'] = f.q.trim();
  }
  return out;
}

String _defaultAlertName(SearchFilters f) {
  final parts = <String>[];
  if (f.neighborhood != null && f.neighborhood!.trim().isNotEmpty) {
    parts.add(f.neighborhood!.trim());
  }
  if (f.type != null && f.type!.isNotEmpty && f.type != 'any') {
    parts.add(f.type!.replaceAll('_', ' '));
  }
  if (f.maxRent != null) {
    parts.add('≤ ${f.maxRent}');
  }
  if (parts.isEmpty) return 'My search alert';
  return parts.join(' · ');
}

class SavedSearchesPage extends ConsumerWidget {
  const SavedSearchesPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final current = ref.read(searchFiltersProvider);
    final nameCtrl = TextEditingController(text: _defaultAlertName(current));
    var alert = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Save search alert'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uses your current Search filters (area, type, budget).',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable alerts'),
                    value: alert,
                    onChanged: (v) => setLocal(() => alert = v),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !context.mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await ref.read(mobileApiRepositoryProvider).createSavedSearch({
        'name': name,
        'filters': _filtersPayload(current),
        'alertEnabled': alert,
      });
      ref.invalidate(savedSearchesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search saved.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Search alerts')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () =>
                context.push(loginLocation(from: '/saved-searches')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(savedSearchesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _create(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savedSearchesProvider);
          await ref.read(savedSearchesProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(savedSearchesProvider),
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const Text('No saved searches yet.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _create(context, ref),
                    child: const Text('Create alert'),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = items[i];
                final id = s['id']?.toString() ?? '';
                final name = (s['name'] as String?) ?? 'Search';
                final alert = s['alert_enabled'] == true || s['alertEnabled'] == true;
                return ListTile(
                  leading: Icon(alert ? Icons.notifications_active : Icons.notifications_off),
                  title: Text(name),
                  subtitle: Text(alert ? 'Alerts on' : 'Alerts off'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: id.isEmpty
                        ? null
                        : () async {
                            await ref
                                .read(mobileApiRepositoryProvider)
                                .deleteSavedSearch(id);
                            ref.invalidate(savedSearchesProvider);
                          },
                  ),
                  onTap: id.isEmpty
                      ? null
                      : () async {
                          await ref.read(mobileApiRepositoryProvider).patchSavedSearch(
                                id,
                                {'alertEnabled': !alert},
                              );
                          ref.invalidate(savedSearchesProvider);
                        },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
