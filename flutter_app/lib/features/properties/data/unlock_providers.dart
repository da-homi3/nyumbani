import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/properties/data/unlock_models.dart';

final unlockRepositoryProvider = Provider<UnlockRepository>((ref) {
  return UnlockRepository(ref.watch(mobileApiRepositoryProvider));
});

class UnlockRepository {
  UnlockRepository(this._api);
  final MobileApiRepository _api;

  Future<UnlockState> getState(String listingId) async {
    final json = await _api.unlockState(listingId);
    return UnlockState.fromJson(json, listingId: listingId);
  }

  /// Probe unlock path (Plus/trial/free). Without method, paid unlocks return payment_required.
  Future<UnlockActionResult> initiate({
    required String listingId,
    String? method,
    String? phoneNumber,
    String? email,
    String? idempotencyKey,
  }) async {
    final json = await _api.unlockInitiate(
      listingId,
      method: method,
      phoneNumber: phoneNumber,
      email: email,
      idempotencyKey: idempotencyKey,
    );
    return UnlockActionResult.fromJson(json);
  }

  Future<PaymentPollStatus> pollPayment(String paymentId) async {
    final json = await _api.paymentStatus(paymentId);
    return PaymentPollStatus.fromJson(json);
  }

  /// Poll until completed/failed or timeout.
  Future<PaymentPollStatus> waitForPayment(
    String paymentId, {
    Duration timeout = const Duration(minutes: 2),
    Duration interval = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    PaymentPollStatus last = await pollPayment(paymentId);
    while (DateTime.now().isBefore(deadline)) {
      if (last.isCompleted || last.isFailed) return last;
      await Future<void>.delayed(interval);
      last = await pollPayment(paymentId);
    }
    return last;
  }
}

final unlockStateProvider =
    FutureProvider.autoDispose.family<UnlockState, String>((ref, listingId) {
  return ref.watch(unlockRepositoryProvider).getState(listingId);
});
