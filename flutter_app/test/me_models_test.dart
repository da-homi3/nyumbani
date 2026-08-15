import 'package:flutter_test/flutter_test.dart';

import 'package:nyumbasearch/features/profile/data/me_models.dart';

void main() {
  test('MeSnapshot parses BFF /me payload', () {
    final me = MeSnapshot.fromJson({
      'apiVersion': 'v1',
      'user': {'id': 'u1', 'email': 'a@b.co', 'phone': null},
      'profile': {
        'id': 'u1',
        'full_name': 'Amina',
        'phone': '0712345678',
        'active_portal': 'tenant',
        'is_portal_active': true,
        'trial_unlocks_remaining': 2,
        'trial_ends_at': '2026-09-01',
      },
      'roles': ['tenant', 'landlord'],
    });

    expect(me.fullName, 'Amina');
    expect(me.trialUnlocksRemaining, 2);
    expect(me.isTenantOnly, isFalse);
    expect(me.portalRoles, ['landlord']);
  });
}
