import 'package:flutter_test/flutter_test.dart';

import 'package:nyumbasearch/features/properties/data/unlock_models.dart';

void main() {
  test('UnlockState parses BFF unlock payload', () {
    final state = UnlockState.fromJson({
      'listingId': 'abc',
      'unlocked': false,
      'fee': 99,
      'isPlus': false,
      'trialActive': true,
      'trialUnlocksRemaining': 1,
      'monthlyUnlockSpend': 0,
      'contactPhones': <String>[],
    });
    expect(state.canUnlockFree, isTrue);
    expect(state.fee, 99);
  });

  test('Plus with credits can unlock without STK; exhausted Plus cannot', () {
    final withCredits = UnlockState.fromJson({
      'listingId': 'abc',
      'unlocked': false,
      'fee': 200,
      'isPlus': true,
      'trialActive': false,
      'trialUnlocksRemaining': 0,
      'monthlyUnlockSpend': 0,
      'plusContactCredits': 6,
      'creditsRequired': 2,
      'plusCanCover': true,
    });
    expect(withCredits.canUnlockFree, isTrue);
    expect(withCredits.plusContactCredits, 6);

    final exhausted = UnlockState.fromJson({
      'listingId': 'abc',
      'unlocked': false,
      'fee': 200,
      'isPlus': true,
      'trialActive': false,
      'trialUnlocksRemaining': 0,
      'monthlyUnlockSpend': 0,
      'plusContactCredits': 1,
      'creditsRequired': 2,
      'plusCanCover': false,
    });
    expect(exhausted.canUnlockFree, isFalse);
  });

  test('UnlockActionResult detects payment_required and pending STK', () {
    final required = UnlockActionResult.fromJson({
      'unlocked': false,
      'status': 'payment_required',
      'fee': 99,
      'paymentType': 'contact_unlock',
    });
    expect(required.needsPayment, isTrue);

    final pending = UnlockActionResult.fromJson({
      'unlocked': false,
      'status': 'pending',
      'paymentId': '11111111-1111-1111-1111-111111111111',
      'fee': 99,
    });
    expect(pending.paymentPending, isTrue);

    final card = UnlockActionResult.fromJson({
      'unlocked': false,
      'status': 'pending',
      'paymentId': '22222222-2222-2222-2222-222222222222',
      'redirectUrl': 'https://pay.pesapal.com/iframe/PesapalIframe3/Index/?OrderTrackingId=x',
    });
    expect(card.hasCardRedirect, isTrue);
  });

  test('PaymentPollStatus completion flags', () {
    final done = PaymentPollStatus.fromJson({
      'status': 'completed',
      'paymentId': 'p1',
      'message': 'Payment confirmed',
    });
    expect(done.isCompleted, isTrue);
    expect(done.isFailed, isFalse);
  });
}
