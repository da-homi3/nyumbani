import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';

final tenantProfileBundleProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;
  try {
    return await ref.watch(mobileApiRepositoryProvider).tenantProfileBundle();
  } on AppFailure {
    rethrow;
  }
});
