import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/profile/data/me_models.dart';

final meProvider = FutureProvider.autoDispose<MeSnapshot?>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;
  try {
    final json = await ref.watch(mobileApiRepositoryProvider).me();
    return MeSnapshot.fromJson(json);
  } on AppFailure {
    rethrow;
  }
});
