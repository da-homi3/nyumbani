import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/caretaker/data/caretaker_session_store.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class CaretakerProperty {
  const CaretakerProperty({
    required this.id,
    required this.title,
    this.neighborhood,
    this.isVacant,
    this.rentKes,
    this.propertyType,
  });

  final String id;
  final String title;
  final String? neighborhood;
  final bool? isVacant;
  final int? rentKes;
  final String? propertyType;

  factory CaretakerProperty.fromJson(Map<String, dynamic> json) {
    return CaretakerProperty(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String?) ?? 'Property',
      neighborhood: json['neighborhood'] as String?,
      isVacant: json['is_vacant'] as bool? ?? json['isVacant'] as bool?,
      rentKes: (json['rent_kes'] as num?)?.toInt() ??
          (json['rentKes'] as num?)?.toInt(),
      propertyType: (json['property_type'] as String?) ??
          (json['propertyType'] as String?),
    );
  }
}

class CaretakerDashboardData {
  const CaretakerDashboardData({
    required this.caretakerName,
    required this.properties,
  });

  final String caretakerName;
  final List<CaretakerProperty> properties;

  factory CaretakerDashboardData.fromJson(Map<String, dynamic> json) {
    final raw = json['properties'];
    return CaretakerDashboardData(
      caretakerName: (json['caretakerName'] as String?) ??
          (json['caretaker_name'] as String?) ??
          'Caretaker',
      properties: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => CaretakerProperty.fromJson(Map<String, dynamic>.from(e)))
              .where((p) => p.id.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

final caretakerDashboardProvider =
    FutureProvider.autoDispose<CaretakerDashboardData?>((ref) async {
  final token = await caretakerSessionStore.readToken();
  if (token == null || token.isEmpty) return null;
  final json =
      await ref.watch(mobileApiRepositoryProvider).caretakerDashboard(token);
  return CaretakerDashboardData.fromJson(json);
});

class CaretakerDashboardPage extends ConsumerWidget {
  const CaretakerDashboardPage({super.key});

  Future<void> _toggleVacancy(
    WidgetRef ref,
    BuildContext context,
    CaretakerProperty property,
    bool next,
  ) async {
    final token = await caretakerSessionStore.readToken();
    if (token == null) return;
    try {
      await ref.read(mobileApiRepositoryProvider).caretakerSetVacancy(
            token: token,
            propertyId: property.id,
            isVacant: next,
          );
      ref.invalidate(caretakerDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next ? 'Marked vacant' : 'Marked occupied'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppFailure ? e.message : 'Could not update vacancy',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(caretakerDashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caretaker'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await caretakerSessionStore.clear();
              ref.invalidate(caretakerDashboardProvider);
              if (context.mounted) context.go('/caretaker/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(caretakerDashboardProvider),
        builder: (data) {
          if (data == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign in with your caretaker PIN',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/caretaker/login'),
                    child: const Text('Caretaker login'),
                  ),
                ],
              ),
            );
          }

          if (data.properties.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Hi ${data.caretakerName}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No properties assigned yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(caretakerDashboardProvider);
              await ref.read(caretakerDashboardProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
              itemCount: data.properties.length + 1,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return ListTile(
                    title: Text(
                      'Hi ${data.caretakerName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text('${data.properties.length} assigned properties'),
                  );
                }
                final p = data.properties[i - 1];
                final vacant = p.isVacant == true;
                final parts = <String>[
                  if (p.neighborhood != null && p.neighborhood!.isNotEmpty)
                    p.neighborhood!,
                  if (p.rentKes != null) 'KES ${p.rentKes}',
                  vacant ? 'Vacant' : 'Occupied',
                ];
                return SwitchListTile(
                  secondary: const Icon(Icons.home_work_outlined),
                  title: Text(p.title),
                  subtitle: Text(parts.join(' · ')),
                  value: vacant,
                  onChanged: (v) => _toggleVacancy(ref, context, p, v),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
