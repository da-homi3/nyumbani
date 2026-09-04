import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';

List<Map<String, dynamic>> _parseApplications(Map<String, dynamic> json) {
  final raw = json['applications'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
}

final tenantApplicationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  try {
    final json = await ref.watch(mobileApiRepositoryProvider).listTenantApplications();
    return _parseApplications(json);
  } on AppFailure {
    rethrow;
  }
});

final propertyApplicationProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, propertyId) async {
  final apps = await ref.watch(tenantApplicationsProvider.future);
  for (final app in apps) {
    if (app['property_id']?.toString() == propertyId) {
      final status = app['status']?.toString() ?? '';
      if (status != 'withdrawn' && status != 'rejected') return app;
    }
  }
  return null;
});

bool isActiveApplicationStatus(String status) {
  return status == 'submitted' || status == 'under_review' || status == 'approved';
}

String formatApplicationStatus(String status) => status.replaceAll('_', ' ');
