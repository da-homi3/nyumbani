class UnlockState {
  const UnlockState({
    required this.listingId,
    required this.unlocked,
    required this.fee,
    required this.isPlus,
    required this.trialActive,
    required this.trialUnlocksRemaining,
    required this.monthlyUnlockSpend,
    this.method,
    this.contactPhone,
    this.contactPhones = const [],
    this.trialEndsAt,
    this.plusContactCredits = 0,
    this.creditsRequired = 1,
    this.plusCanCover = false,
  });

  final String listingId;
  final bool unlocked;
  final int fee;
  final bool isPlus;
  final bool trialActive;
  final int trialUnlocksRemaining;
  final int monthlyUnlockSpend;
  final String? method;
  final String? contactPhone;
  final List<String> contactPhones;
  final String? trialEndsAt;
  final int plusContactCredits;
  final int creditsRequired;
  final bool plusCanCover;

  List<String> get phones {
    if (contactPhones.isNotEmpty) return contactPhones;
    final p = contactPhone?.trim();
    return p == null || p.isEmpty ? const [] : [p];
  }

  bool get canUnlockFree =>
      !unlocked && (plusCanCover || (trialActive && trialUnlocksRemaining > 0));

  factory UnlockState.fromJson(Map<String, dynamic> json, {String? listingId}) {
    final phonesRaw = json['contactPhones'];
    return UnlockState(
      listingId: listingId ?? (json['listingId'] as String? ?? ''),
      unlocked: json['unlocked'] == true,
      fee: (json['fee'] as num?)?.toInt() ?? 0,
      isPlus: json['isPlus'] == true,
      trialActive: json['trialActive'] == true,
      trialUnlocksRemaining: (json['trialUnlocksRemaining'] as num?)?.toInt() ?? 0,
      monthlyUnlockSpend: (json['monthlyUnlockSpend'] as num?)?.toInt() ?? 0,
      method: json['method'] as String?,
      contactPhone: json['contactPhone'] as String?,
      contactPhones: phonesRaw is List
          ? phonesRaw.whereType<String>().where((p) => p.trim().isNotEmpty).toList()
          : const [],
      trialEndsAt: json['trialEndsAt'] as String?,
      plusContactCredits: (json['plusContactCredits'] as num?)?.toInt() ?? 0,
      creditsRequired: (json['creditsRequired'] as num?)?.toInt() ?? 1,
      plusCanCover: json['plusCanCover'] == true,
    );
  }
}

class UnlockActionResult {
  const UnlockActionResult({
    required this.unlocked,
    this.method,
    this.status,
    this.paymentId,
    this.fee,
    this.contactPhone,
    this.contactPhones = const [],
    this.message,
    this.error,
    this.paymentType,
    this.trialUnlocksRemaining,
    this.redirectUrl,
  });

  final bool unlocked;
  final String? method;
  final String? status;
  final String? paymentId;
  final int? fee;
  final String? contactPhone;
  final List<String> contactPhones;
  final String? message;
  final String? error;
  final String? paymentType;
  final int? trialUnlocksRemaining;
  final String? redirectUrl;

  bool get needsPayment => !unlocked && status == 'payment_required';
  bool get paymentPending =>
      !unlocked && paymentId != null && (status == 'pending' || status == 'processing');
  bool get hasCardRedirect =>
      redirectUrl != null && redirectUrl!.trim().isNotEmpty;

  factory UnlockActionResult.fromJson(Map<String, dynamic> json) {
    final phonesRaw = json['contactPhones'];
    return UnlockActionResult(
      unlocked: json['unlocked'] == true,
      method: json['method'] as String?,
      status: json['status'] as String?,
      paymentId: json['paymentId'] as String?,
      fee: (json['fee'] as num?)?.toInt(),
      contactPhone: json['contactPhone'] as String?,
      contactPhones: phonesRaw is List
          ? phonesRaw.whereType<String>().where((p) => p.trim().isNotEmpty).toList()
          : const [],
      message: json['message'] as String?,
      error: json['error'] as String?,
      paymentType: json['paymentType'] as String?,
      trialUnlocksRemaining: (json['trialUnlocksRemaining'] as num?)?.toInt(),
      redirectUrl: (json['redirectUrl'] as String?) ??
          (json['checkoutUrl'] as String?) ??
          (json['authorizationUrl'] as String?),
    );
  }
}

class PaymentPollStatus {
  const PaymentPollStatus({
    required this.status,
    required this.paymentId,
    required this.message,
    this.method,
    this.purpose,
    this.receipt,
  });

  final String status;
  final String paymentId;
  final String message;
  final String? method;
  final String? purpose;
  final String? receipt;

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed' || status == 'cancelled';
  bool get isPending => status == 'pending' || status == 'processing';

  factory PaymentPollStatus.fromJson(Map<String, dynamic> json) {
    return PaymentPollStatus(
      status: (json['status'] as String?) ?? 'pending',
      paymentId: (json['paymentId'] as String?) ?? '',
      message: (json['message'] as String?) ?? 'Waiting for payment confirmation',
      method: json['method'] as String?,
      purpose: json['purpose'] as String?,
      receipt: json['receipt'] as String?,
    );
  }
}
