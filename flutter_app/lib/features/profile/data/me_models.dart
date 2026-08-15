class MeSnapshot {
  const MeSnapshot({
    required this.userId,
    this.email,
    this.phone,
    this.fullName,
    this.avatarUrl,
    this.activePortal,
    this.isPortalActive,
    this.trialUnlocksRemaining = 0,
    this.trialEndsAt,
    this.roles = const [],
  });

  final String userId;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? avatarUrl;
  final String? activePortal;
  final bool? isPortalActive;
  final int trialUnlocksRemaining;
  final String? trialEndsAt;
  final List<String> roles;

  bool get isTenantOnly =>
      roles.isEmpty || (roles.length == 1 && roles.first.toLowerCase() == 'tenant');

  List<String> get portalRoles => roles
      .where((r) => const {
            'landlord',
            'agency',
            'manager',
            'caretaker',
            'admin',
            'provider',
          }.contains(r.toLowerCase()))
      .toList();

  factory MeSnapshot.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : const <String, dynamic>{};
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : null;
    final rolesRaw = json['roles'];

    return MeSnapshot(
      userId: (user['id'] as String?) ?? (profile?['id'] as String?) ?? '',
      email: user['email'] as String?,
      phone: (profile?['phone'] as String?) ?? (user['phone'] as String?),
      fullName: profile?['full_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      activePortal: profile?['active_portal'] as String?,
      isPortalActive: profile?['is_portal_active'] as bool?,
      trialUnlocksRemaining: (profile?['trial_unlocks_remaining'] as num?)?.toInt() ?? 0,
      trialEndsAt: profile?['trial_ends_at'] as String?,
      roles: rolesRaw is List
          ? rolesRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }
}
