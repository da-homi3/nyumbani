import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';

List<Map<String, dynamic>> parseViewingsList(Map<String, dynamic> json) {
  final raw = json['viewings'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
}

final tenantViewingsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  try {
    final json = await ref.watch(mobileApiRepositoryProvider).listTenantViewings();
    return parseViewingsList(json);
  } on AppFailure {
    rethrow;
  }
});

final landlordViewingsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  try {
    final json = await ref.watch(mobileApiRepositoryProvider).listLandlordViewings();
    return parseViewingsList(json);
  } on AppFailure {
    rethrow;
  }
});

String formatViewingStatus(String status) => status.replaceAll('_', ' ');

bool isUpcomingViewing(Map<String, dynamic> viewing) {
  final status = viewing['status']?.toString() ?? '';
  return status == 'pending' || status == 'confirmed';
}
