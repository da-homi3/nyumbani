import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/properties/data/unlock_models.dart';

final tenantsRepositoryProvider = Provider<TenantsRepository>((ref) {
  return TenantsRepository(ref.watch(mobileApiRepositoryProvider));
});

class TenantRentAccess {
  const TenantRentAccess({
    required this.linked,
    required this.hasActiveLease,
    required this.invoiceCount,
    this.leases = const [],
  });

  final bool linked;
  final bool hasActiveLease;
  final int invoiceCount;
  final List<TenantLease> leases;

  factory TenantRentAccess.fromJson(Map<String, dynamic> json) {
    final access = json['access'] is Map
        ? Map<String, dynamic>.from(json['access'] as Map)
        : json;
    final rawLeases = access['leases'];
    final leases = rawLeases is List
        ? rawLeases
            .whereType<Map>()
            .map((e) => TenantLease.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <TenantLease>[];
    return TenantRentAccess(
      linked: access['linked'] == true,
      hasActiveLease: access['hasActiveLease'] == true || access['has_active_lease'] == true,
      invoiceCount: (access['invoiceCount'] as num?)?.toInt() ??
          (access['invoice_count'] as num?)?.toInt() ??
          0,
      leases: leases,
    );
  }
}

class TenantLease {
  const TenantLease({
    required this.id,
    required this.status,
    required this.monthlyRent,
    required this.depositPaid,
    required this.startDate,
    required this.endDate,
    this.unitLabel,
    this.propertyName,
    this.neighborhood,
    this.leaseDocumentUrl,
  });

  final String id;
  final String status;
  final int monthlyRent;
  final int depositPaid;
  final String startDate;
  final String endDate;
  final String? unitLabel;
  final String? propertyName;
  final String? neighborhood;
  final String? leaseDocumentUrl;

  bool get isActive => status == 'active';

  String get placeLabel {
    final parts = [
      if (propertyName != null && propertyName!.trim().isNotEmpty) propertyName!.trim(),
      if (unitLabel != null && unitLabel!.trim().isNotEmpty) 'Unit ${unitLabel!.trim()}',
    ];
    return parts.isEmpty ? 'Your tenancy' : parts.join(' · ');
  }

  factory TenantLease.fromJson(Map<String, dynamic> json) {
    return TenantLease(
      id: json['id']?.toString() ?? '',
      status: (json['status'] as String?) ?? 'active',
      monthlyRent: (json['monthly_rent'] as num?)?.toInt() ??
          (json['monthlyRent'] as num?)?.toInt() ??
          0,
      depositPaid: (json['deposit_paid'] as num?)?.toInt() ??
          (json['depositPaid'] as num?)?.toInt() ??
          0,
      startDate: (json['start_date'] as String?) ?? (json['startDate'] as String?) ?? '',
      endDate: (json['end_date'] as String?) ?? (json['endDate'] as String?) ?? '',
      unitLabel: (json['unit_label'] as String?) ?? json['unitLabel'] as String?,
      propertyName: (json['property_name'] as String?) ?? json['propertyName'] as String?,
      neighborhood: json['neighborhood'] as String?,
      leaseDocumentUrl:
          (json['lease_document_url'] as String?) ?? json['leaseDocumentUrl'] as String?,
    );
  }
}

class RentInvoice {
  const RentInvoice({
    required this.id,
    required this.periodMonth,
    required this.dueDate,
    required this.status,
    required this.amountDue,
    required this.amountPaid,
    required this.lateFee,
    required this.balanceRemaining,
    this.unitLabel,
    this.propertyName,
    this.neighborhood,
    this.defaultMpesaPhone,
  });

  final String id;
  final String periodMonth;
  final String dueDate;
  final String status;
  final int amountDue;
  final int amountPaid;
  final int lateFee;
  final int balanceRemaining;
  final String? unitLabel;
  final String? propertyName;
  final String? neighborhood;
  final String? defaultMpesaPhone;

  bool get isPaid => status == 'paid' || balanceRemaining <= 0;

  String get title {
    final place = [
      if (propertyName != null && propertyName!.trim().isNotEmpty) propertyName,
      if (unitLabel != null && unitLabel!.trim().isNotEmpty) 'Unit $unitLabel',
    ].join(' · ');
    if (place.isNotEmpty) return place;
    return periodMonth.isNotEmpty ? periodMonth : 'Rent invoice';
  }

  factory RentInvoice.fromJson(Map<String, dynamic> json) {
    return RentInvoice(
      id: json['id']?.toString() ?? '',
      periodMonth: (json['period_month'] as String?) ?? (json['periodMonth'] as String?) ?? '',
      dueDate: (json['due_date'] as String?) ?? (json['dueDate'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'open',
      amountDue: (json['amount_due'] as num?)?.toInt() ?? (json['amountDue'] as num?)?.toInt() ?? 0,
      amountPaid:
          (json['amount_paid'] as num?)?.toInt() ?? (json['amountPaid'] as num?)?.toInt() ?? 0,
      lateFee: (json['late_fee'] as num?)?.toInt() ?? (json['lateFee'] as num?)?.toInt() ?? 0,
      balanceRemaining: (json['balance_remaining'] as num?)?.toInt() ??
          (json['balanceRemaining'] as num?)?.toInt() ??
          0,
      unitLabel: (json['unit_label'] as String?) ?? (json['unitLabel'] as String?),
      propertyName: (json['property_name'] as String?) ?? (json['propertyName'] as String?),
      neighborhood: json['neighborhood'] as String?,
      defaultMpesaPhone: (json['default_mpesa_phone'] as String?) ??
          (json['defaultMpesaPhone'] as String?),
    );
  }
}

class RentPayResult {
  const RentPayResult({
    required this.status,
    this.paymentId,
    this.amount,
    this.message,
  });

  final String status;
  final String? paymentId;
  final int? amount;
  final String? message;

  bool get isCompleted => status == 'completed';

  factory RentPayResult.fromJson(Map<String, dynamic> json) {
    return RentPayResult(
      status: (json['status'] as String?) ?? 'pending',
      paymentId: json['paymentId'] as String? ?? json['payment_id'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? (json['amountKes'] as num?)?.toInt(),
      message: json['message'] as String?,
    );
  }
}

class TenantsRepository {
  TenantsRepository(this._api);
  final MobileApiRepository _api;

  Future<TenantRentAccess> rentAccess() async {
    final json = await _api.tenantsRentAccess();
    return TenantRentAccess.fromJson(json);
  }

  Future<List<RentInvoice>> rentInvoices() async {
    final json = await _api.tenantsRentInvoices();
    final raw = json['invoices'] ?? json['items'] ?? json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => RentInvoice.fromJson(Map<String, dynamic>.from(e)))
        .where((i) => i.id.isNotEmpty)
        .toList();
  }

  Future<RentPayResult> payRent({
    required String invoiceId,
    required String phone,
    int? amountKes,
    String? idempotencyKey,
  }) async {
    final json = await _api.tenantsRentPay(
      invoiceId: invoiceId,
      phone: phone,
      amountKes: amountKes,
      idempotencyKey: idempotencyKey,
    );
    return RentPayResult.fromJson(json);
  }

  Future<Map<String, dynamic>> submitRentSmsClaim({
    required String invoiceId,
    required String smsText,
    int? amountOverride,
  }) {
    return _api.tenantsRentSmsClaim(
      invoiceId: invoiceId,
      smsText: smsText,
      amountOverride: amountOverride,
    );
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

final tenantRentAccessProvider = FutureProvider.autoDispose<TenantRentAccess>((ref) {
  return ref.watch(tenantsRepositoryProvider).rentAccess();
});

final tenantRentInvoicesProvider = FutureProvider.autoDispose<List<RentInvoice>>((ref) {
  return ref.watch(tenantsRepositoryProvider).rentInvoices();
});
