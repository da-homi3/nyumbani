import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/properties/data/unlock_models.dart';

class UserEntitlements {
  const UserEntitlements({
    required this.tenantPlan,
    required this.landlordPlan,
    required this.isPlus,
    required this.trialActive,
    required this.trialUnlocksRemaining,
    this.plusExpiresAt,
    this.trialEndsAt,
    this.portalSubscriptionStatus,
    this.leadPackBalance = 0,
    this.canViewLeadContacts = false,
    this.plusContactCredits = 0,
    this.listingLimit,
  });

  final String tenantPlan;
  final String landlordPlan;
  final bool isPlus;
  final bool trialActive;
  final int trialUnlocksRemaining;
  final String? plusExpiresAt;
  final String? trialEndsAt;
  final String? portalSubscriptionStatus;
  final int leadPackBalance;
  final bool canViewLeadContacts;
  final int plusContactCredits;
  final int? listingLimit;

  factory UserEntitlements.fromJson(Map<String, dynamic> json) {
    final e = json['entitlements'] is Map
        ? Map<String, dynamic>.from(json['entitlements'] as Map)
        : json;
    final plan = (e['tenantPlan'] as String?) ?? 'free';
    return UserEntitlements(
      tenantPlan: plan,
      landlordPlan: (e['landlordPlan'] as String?) ?? 'free',
      isPlus: e['isPlus'] == true || plan == 'plus',
      trialActive: e['trialActive'] == true,
      trialUnlocksRemaining: (e['trialUnlocksRemaining'] as num?)?.toInt() ?? 0,
      plusExpiresAt: e['plusExpiresAt'] as String?,
      trialEndsAt: e['trialEndsAt'] as String?,
      portalSubscriptionStatus: e['portalSubscriptionStatus'] as String?,
      leadPackBalance: (e['leadPackBalance'] as num?)?.toInt() ?? 0,
      canViewLeadContacts: e['canViewLeadContacts'] == true,
      plusContactCredits: (e['plusContactCredits'] as num?)?.toInt() ?? 0,
      listingLimit: (e['listingLimit'] as num?)?.toInt(),
    );
  }
}

class PlusCatalog {
  const PlusCatalog({
    required this.monthlyKes,
    required this.quarterlyKes,
    this.quarterlyRegularKes = 2100,
    this.savingsKes = 300,
    this.effectiveMonthlyKes = 600,
    this.features = const [],
    this.name = 'NyumbaSearch Plus',
  });

  final int monthlyKes;
  final int quarterlyKes;
  final int quarterlyRegularKes;
  final int savingsKes;
  final int effectiveMonthlyKes;
  final List<String> features;
  final String name;

  factory PlusCatalog.fromJson(Map<String, dynamic> json) {
    final plus = _asMap(json['plus']) ??
        _asMap(json['tenantPlus']) ??
        _asMap(json['tenant_plus']) ??
        _asMap(_asMap(json['catalog'])?['plus']) ??
        json;

    final featuresRaw = plus['features'];
    final monthly = (plus['monthlyKes'] as num?)?.toInt() ??
        (plus['monthly_kes'] as num?)?.toInt() ??
        700;
    final quarterly = (plus['quarterlyKes'] as num?)?.toInt() ??
        (plus['quarterly_kes'] as num?)?.toInt() ??
        1800;
    final regular = (plus['quarterlyRegularKes'] as num?)?.toInt() ??
        (plus['quarterly_regular_kes'] as num?)?.toInt() ??
        monthly * 3;
    return PlusCatalog(
      name: (plus['name'] as String?) ?? 'NyumbaSearch Plus',
      monthlyKes: monthly,
      quarterlyKes: quarterly,
      quarterlyRegularKes: regular,
      savingsKes: (plus['savingsKes'] as num?)?.toInt() ??
          (regular > quarterly ? regular - quarterly : 0),
      effectiveMonthlyKes: (plus['effectiveMonthlyKes'] as num?)?.toInt() ??
          (quarterly / 3).round(),
      features: featuresRaw is List
          ? featuresRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [
              '10 contact credits / month',
              'NyumbaSearch AI',
              'Financial planning tools',
              'In-app messaging',
              'Scam-risk scores on listings',
            ],
    );
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }
}

class LandlordPlanOffer {
  const LandlordPlanOffer({
    required this.id,
    required this.name,
    required this.priceKes,
    required this.desc,
    this.features = const [],
    this.highlighted = false,
  });

  final String id;
  final String name;
  final int priceKes;
  final String desc;
  final List<String> features;
  final bool highlighted;

  int amountForCycle(String billingCycle) {
    if (billingCycle == 'quarterly') {
      return (priceKes * 3 * 0.9).round();
    }
    return priceKes;
  }

  factory LandlordPlanOffer.fromJson(Map<String, dynamic> json) {
    final featuresRaw = json['features'];
    return LandlordPlanOffer(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Plan',
      priceKes: (json['priceKes'] as num?)?.toInt() ??
          (json['price_kes'] as num?)?.toInt() ??
          0,
      desc: (json['desc'] as String?) ?? (json['description'] as String?) ?? '',
      highlighted: json['highlighted'] == true,
      features: featuresRaw is List
          ? featuresRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }
}

class BoostPackageOffer {
  const BoostPackageOffer({
    required this.id,
    required this.name,
    required this.priceKes,
    required this.placement,
    required this.durationDays,
  });

  final String id;
  final String name;
  final int priceKes;
  final String placement;
  final int durationDays;

  factory BoostPackageOffer.fromJson(Map<String, dynamic> json) {
    return BoostPackageOffer(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Boost',
      priceKes: (json['priceKes'] as num?)?.toInt() ??
          (json['price_kes'] as num?)?.toInt() ??
          0,
      placement: (json['placement'] as String?) ?? '',
      durationDays: (json['durationDays'] as num?)?.toInt() ??
          (json['duration_days'] as num?)?.toInt() ??
          7,
    );
  }
}

class LeadPackOffer {
  const LeadPackOffer({
    required this.qty,
    required this.priceKes,
    required this.label,
  });

  final int qty;
  final int priceKes;
  final String label;

  factory LeadPackOffer.fromJson(Map<String, dynamic> json) {
    return LeadPackOffer(
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      priceKes: (json['priceKes'] as num?)?.toInt() ??
          (json['price_kes'] as num?)?.toInt() ??
          0,
      label: (json['label'] as String?) ?? 'Lead pack',
    );
  }
}

class RevenueCatalog {
  const RevenueCatalog({
    required this.plus,
    required this.landlordPlans,
    required this.boostPackages,
    this.leadPacks = const [],
  });

  final PlusCatalog plus;
  final List<LandlordPlanOffer> landlordPlans;
  final List<BoostPackageOffer> boostPackages;
  final List<LeadPackOffer> leadPacks;

  factory RevenueCatalog.fromJson(Map<String, dynamic> json) {
    final landlordRaw = json['landlord'];
    final boostRaw = json['boostPackages'] ?? json['boost_packages'];
    final leadRaw = json['leadPacks'] ?? json['lead_packs'];
    return RevenueCatalog(
      plus: PlusCatalog.fromJson(json),
      landlordPlans: landlordRaw is List
          ? landlordRaw
              .whereType<Map>()
              .map((e) => LandlordPlanOffer.fromJson(Map<String, dynamic>.from(e)))
              .where((p) => p.id.isNotEmpty && p.priceKes > 0)
              .toList()
          : const [],
      boostPackages: boostRaw is List
          ? boostRaw
              .whereType<Map>()
              .map((e) => BoostPackageOffer.fromJson(Map<String, dynamic>.from(e)))
              .where((p) => p.id.isNotEmpty && p.priceKes > 0)
              .toList()
          : const [],
      leadPacks: leadRaw is List
          ? leadRaw
              .whereType<Map>()
              .map((e) => LeadPackOffer.fromJson(Map<String, dynamic>.from(e)))
              .where((p) => p.qty > 0 && p.priceKes > 0)
              .toList()
          : const [],
    );
  }
}

class SubscriptionCheckoutResult {
  const SubscriptionCheckoutResult({
    required this.status,
    this.paymentId,
    this.message,
    this.redirectUrl,
  });

  final String status;
  final String? paymentId;
  final String? message;
  final String? redirectUrl;

  bool get isCompleted => status == 'completed';
  bool get hasCardRedirect =>
      redirectUrl != null && redirectUrl!.trim().isNotEmpty;

  factory SubscriptionCheckoutResult.fromJson(Map<String, dynamic> json) {
    return SubscriptionCheckoutResult(
      status: (json['status'] as String?) ?? 'pending',
      paymentId: json['paymentId'] as String? ?? json['payment_id'] as String?,
      message: json['message'] as String?,
      redirectUrl: (json['redirectUrl'] as String?) ??
          (json['checkoutUrl'] as String?) ??
          (json['authorizationUrl'] as String?),
    );
  }
}

class PmModuleSubscribeResult {
  const PmModuleSubscribeResult({
    required this.status,
    this.tier,
    this.priceKes,
    this.subscriptionId,
    this.trialEnd,
  });

  final String status;
  final String? tier;
  final int? priceKes;
  final String? subscriptionId;
  final String? trialEnd;

  bool get alreadyActive => status == 'already_active';
  bool get trialStarted => status == 'trial_started';
  bool get includedWithPlan => status == 'included_with_plan';
  bool get requiresPayment => status == 'requires_payment';

  factory PmModuleSubscribeResult.fromJson(Map<String, dynamic> json) {
    return PmModuleSubscribeResult(
      status: (json['status'] as String?) ?? 'unknown',
      tier: json['tier'] as String?,
      priceKes: (json['priceKes'] as num?)?.toInt() ??
          (json['price_kes'] as num?)?.toInt(),
      subscriptionId: json['subscriptionId'] as String? ??
          json['subscription_id'] as String?,
      trialEnd: json['trialEnd'] as String? ?? json['trial_end'] as String?,
    );
  }
}

class SubscriptionsRepository {
  SubscriptionsRepository(this._api);
  final MobileApiRepository _api;

  Future<PlusCatalog> plusCatalog() async {
    final json = await _api.subscriptionsCatalog();
    return PlusCatalog.fromJson(json);
  }

  Future<RevenueCatalog> revenueCatalog() async {
    final json = await _api.subscriptionsCatalog();
    return RevenueCatalog.fromJson(json);
  }

  Future<UserEntitlements> currentEntitlements() async {
    final json = await _api.subscriptionsCurrent();
    return UserEntitlements.fromJson(json);
  }

  Future<SubscriptionCheckoutResult> checkoutPlus({
    required int amountKes,
    required String billingCycle,
    String paymentMethod = 'mpesa',
    String phoneNumber = '',
    String? email,
    String? idempotencyKey,
  }) async {
    final json = await _api.subscriptionsCheckout(
      paymentType: 'tenant_plus',
      amountKes: amountKes,
      title: 'NyumbaSearch Plus',
      billingCycle: billingCycle,
      plan: 'plus',
      successPath: '/plus',
      phoneNumber: phoneNumber,
      paymentMethod: paymentMethod,
      email: email,
      idempotencyKey: idempotencyKey,
      cancelPath: '/plus',
    );
    return SubscriptionCheckoutResult.fromJson(json);
  }

  Future<SubscriptionCheckoutResult> checkoutLandlordPlan({
    required String planId,
    required String planName,
    required int amountKes,
    required String billingCycle,
    String paymentMethod = 'mpesa',
    String phoneNumber = '',
    String? email,
    String? idempotencyKey,
  }) async {
    final json = await _api.subscriptionsCheckout(
      paymentType: 'landlord_plan',
      amountKes: amountKes,
      title: 'Landlord $planName',
      billingCycle: billingCycle,
      plan: planId,
      successPath: '/landlord/plan',
      phoneNumber: phoneNumber,
      paymentMethod: paymentMethod,
      email: email,
      idempotencyKey: idempotencyKey,
      cancelPath: '/landlord/plan',
    );
    return SubscriptionCheckoutResult.fromJson(json);
  }

  Future<SubscriptionCheckoutResult> checkoutBoost({
    required String propertyId,
    required String boostPackage,
    required String packageName,
    required int amountKes,
    String paymentMethod = 'mpesa',
    String phoneNumber = '',
    String? email,
    String? idempotencyKey,
  }) async {
    final json = await _api.subscriptionsCheckout(
      paymentType: 'property_boost',
      amountKes: amountKes,
      title: '$packageName boost',
      billingCycle: 'monthly',
      plan: boostPackage,
      successPath: '/landlord/boost',
      phoneNumber: phoneNumber,
      paymentMethod: paymentMethod,
      email: email,
      idempotencyKey: idempotencyKey,
      cancelPath: '/landlord/boost',
      propertyId: propertyId,
      boostPackage: boostPackage,
    );
    return SubscriptionCheckoutResult.fromJson(json);
  }

  Future<SubscriptionCheckoutResult> checkoutPmModule({
    required int amountKes,
    required String tier,
    String paymentMethod = 'mpesa',
    String phoneNumber = '',
    String? email,
    String? idempotencyKey,
  }) async {
    final json = await _api.subscriptionsCheckout(
      paymentType: 'pm_module',
      amountKes: amountKes,
      title: 'Property Management',
      billingCycle: 'monthly',
      plan: tier,
      successPath: '/pm',
      phoneNumber: phoneNumber,
      paymentMethod: paymentMethod,
      email: email,
      idempotencyKey: idempotencyKey,
      cancelPath: '/pm',
    );
    return SubscriptionCheckoutResult.fromJson(json);
  }

  Future<SubscriptionCheckoutResult> checkoutLeadPack({
    required int qty,
    required int amountKes,
    required String label,
    String paymentMethod = 'mpesa',
    String phoneNumber = '',
    String? email,
    String? idempotencyKey,
  }) async {
    final json = await _api.subscriptionsCheckout(
      paymentType: 'lead_pack',
      amountKes: amountKes,
      title: label,
      billingCycle: 'monthly',
      plan: 'lead_pack_$qty',
      successPath: '/landlord/leads',
      phoneNumber: phoneNumber,
      paymentMethod: paymentMethod,
      email: email,
      idempotencyKey: idempotencyKey,
      cancelPath: '/landlord/leads',
      qty: qty,
    );
    return SubscriptionCheckoutResult.fromJson(json);
  }

  Future<PmModuleSubscribeResult> subscribePmModule() async {
    final json = await _api.subscribePmModule();
    return PmModuleSubscribeResult.fromJson(json);
  }

  Future<PaymentPollStatus> pollPayment(String paymentId) async {
    final json = await _api.paymentStatus(paymentId);
    return PaymentPollStatus.fromJson(json);
  }

  Future<PaymentPollStatus> waitForPayment(
    String paymentId, {
    Duration timeout = const Duration(minutes: 2),
    Duration interval = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    var last = await pollPayment(paymentId);
    while (DateTime.now().isBefore(deadline)) {
      if (last.isCompleted || last.isFailed) return last;
      await Future<void>.delayed(interval);
      last = await pollPayment(paymentId);
    }
    return last;
  }
}

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) {
  return SubscriptionsRepository(ref.watch(mobileApiRepositoryProvider));
});

final plusCatalogProvider = FutureProvider.autoDispose<PlusCatalog>((ref) {
  return ref.watch(subscriptionsRepositoryProvider).plusCatalog();
});

final revenueCatalogProvider = FutureProvider.autoDispose<RevenueCatalog>((ref) {
  return ref.watch(subscriptionsRepositoryProvider).revenueCatalog();
});

final entitlementsProvider = FutureProvider.autoDispose<UserEntitlements?>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;
  try {
    return await ref.watch(subscriptionsRepositoryProvider).currentEntitlements();
  } on AppFailure {
    rethrow;
  }
});
