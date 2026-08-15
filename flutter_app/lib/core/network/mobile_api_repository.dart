import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_client.dart';

final mobileApiRepositoryProvider = Provider<MobileApiRepository>((ref) {
  return MobileApiRepository(ref.watch(mobileApiClientProvider));
});

/// Thin repository over Mobile BFF v1 contracts (Phase 1).
class MobileApiRepository {
  MobileApiRepository(this._api);

  final MobileApiClient _api;

  Future<Map<String, dynamic>> me() => _api.getJson('/me');

  Future<Map<String, dynamic>> health() => _api.getJson('/health');

  Future<Map<String, dynamic>> searchListings({
    String? q,
    String? neighborhood,
    String? type,
    String? pricingMode,
    int? minRent,
    int? maxRent,
    int? minBedrooms,
    bool verifiedOnly = false,
    String sortBy = 'newest',
    int limit = 20,
    int offset = 0,
    double? originLat,
    double? originLng,
    int? maxImages,
  }) {
    final qTrimmed = q?.trim();
    return _api.getJson(
      '/listings',
      receiveTimeout: const Duration(seconds: 120),
      query: {
        'q': ?(qTrimmed != null && qTrimmed.isNotEmpty ? qTrimmed : null),
        'neighborhood': ?neighborhood,
        'type': ?type,
        'pricingMode': ?pricingMode,
        'minRent': ?minRent,
        'maxRent': ?maxRent,
        'minBedrooms': ?minBedrooms,
        if (verifiedOnly) 'verifiedOnly': '1',
        'sortBy': sortBy,
        'limit': limit,
        'offset': offset,
        'originLat': ?originLat,
        'originLng': ?originLng,
        'maxImages': ?maxImages,
      },
    );
  }

  Future<Map<String, dynamic>> listingDetail(String id) =>
      _api.getJson('/listings/$id');

  Future<Map<String, dynamic>> listSaved() => _api.getJson('/saved');

  Future<Map<String, dynamic>> saveProperty(String propertyId) =>
      _api.putJson('/saved/$propertyId');

  Future<Map<String, dynamic>> unsaveProperty(String propertyId) =>
      _api.deleteJson('/saved/$propertyId');

  Future<Map<String, dynamic>> unlockState(String listingId) =>
      _api.getJson('/unlock/$listingId');

  Future<Map<String, dynamic>> unlockInitiate(
    String listingId, {
    String? method,
    String? phoneNumber,
    String? email,
    String? idempotencyKey,
  }) {
    return _api.postJson('/unlock/$listingId', body: {
      'method': ?method,
      'phoneNumber': ?phoneNumber,
      'email': ?email,
      'idempotencyKey': ?idempotencyKey,
    });
  }

  Future<Map<String, dynamic>> paymentStatus(String paymentId) =>
      _api.getJson('/payments/$paymentId');

  Future<Map<String, dynamic>> registerFcmToken(String token) =>
      _api.postJson('/fcm-token', body: {'token': token});

  // --- Notifications ---

  Future<Map<String, dynamic>> listNotifications({
    int? limit,
    bool unreadOnly = false,
  }) {
    return _api.getJson('/notifications', query: {
      'limit': ?limit,
      if (unreadOnly) 'unreadOnly': '1',
    });
  }

  Future<Map<String, dynamic>> notificationsUnreadCount() =>
      _api.getJson('/notifications/unread-count');

  Future<Map<String, dynamic>> markNotificationsRead(Map<String, dynamic> body) =>
      _api.postJson('/notifications/read', body: body);

  Future<Map<String, dynamic>> notificationPrefs() =>
      _api.getJson('/notifications/prefs');

  Future<Map<String, dynamic>> updateNotificationPrefs(
    Map<String, dynamic> body,
  ) =>
      _api.patchJson('/notifications/prefs', body: body);

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) =>
      _api.patchJson('/me/profile', body: body);

  Future<Map<String, dynamic>> tenantInvitePreview(String token) =>
      _api.getJson('/tenants/invites/$token');

  Future<Map<String, dynamic>> tenantInviteRespond(
    String token, {
    required bool accept,
  }) {
    return _api.postJson('/tenants/invites/$token', body: {'accept': accept});
  }

  // --- Subscriptions / Plus ---

  Future<Map<String, dynamic>> subscriptionsCatalog() =>
      _api.getJson('/subscriptions/catalog');

  Future<Map<String, dynamic>> subscriptionsCurrent() =>
      _api.getJson('/subscriptions/current');

  Future<Map<String, dynamic>> subscriptionsCheckout({
    required String paymentType,
    required int amountKes,
    required String title,
    required String billingCycle,
    required String plan,
    required String successPath,
    String phoneNumber = '',
    String paymentMethod = 'mpesa',
    String? email,
    String? idempotencyKey,
    String? cancelPath,
    String? propertyId,
    String? boostPackage,
    int? qty,
  }) {
    return _api.postJson('/subscriptions/checkout', body: {
      'paymentType': paymentType,
      'amountKes': amountKes,
      'title': title,
      'billingCycle': billingCycle,
      'plan': plan,
      'successPath': successPath,
      'phoneNumber': phoneNumber,
      'paymentMethod': paymentMethod,
      'email': ?email,
      'idempotencyKey': ?idempotencyKey,
      'cancelPath': ?cancelPath,
      'propertyId': ?propertyId,
      'boostPackage': ?boostPackage,
      'qty': ?qty,
    });
  }

  // --- Messages ---

  Future<Map<String, dynamic>> listMessages({
    int? limit,
    int? offset,
  }) {
    return _api.getJson('/messages', query: {
      'limit': ?limit,
      'offset': ?offset,
    });
  }

  Future<Map<String, dynamic>> messageThread(String id) =>
      _api.getJson('/messages/$id');

  Future<Map<String, dynamic>> sendMessage(
    String id, {
    required String body,
  }) {
    return _api.postJson('/messages/$id', body: {'body': body});
  }

  Future<Map<String, dynamic>> createMessage({
    required String propertyId,
    required String message,
  }) {
    return _api.postJson('/messages', body: {
      'propertyId': propertyId,
      'message': message,
    });
  }

  // --- Tenant rent (PM resident) ---

  Future<Map<String, dynamic>> tenantsRentAccess() =>
      _api.getJson('/tenants/rent/access');

  Future<Map<String, dynamic>> tenantsRentInvoices() =>
      _api.getJson('/tenants/rent/invoices');

  Future<Map<String, dynamic>> tenantsRentPay({
    required String invoiceId,
    required String phone,
    int? amountKes,
    String? idempotencyKey,
  }) {
    return _api.postJson('/tenants/rent/pay', body: {
      'invoiceId': invoiceId,
      'phone': phone,
      'amountKes': ?amountKes,
      'idempotencyKey': ?idempotencyKey,
    });
  }

  Future<Map<String, dynamic>> tenantsRentSmsClaim({
    required String invoiceId,
    required String smsText,
    int? amountOverride,
  }) {
    return _api.postJson('/tenants/rent/sms-claim', body: {
      'invoiceId': invoiceId,
      'smsText': smsText,
      'amountOverride': ?amountOverride,
    });
  }

  // --- Portal / me ---

  Future<Map<String, dynamic>> setActivePortal(String portal) =>
      _api.postJson('/me/active-portal', body: {'portal': portal});

  // --- Landlord / owner properties ---

  Future<Map<String, dynamic>> listProperties({
    int? limit,
    int? offset,
  }) {
    return _api.getJson('/properties', query: {
      'limit': ?limit,
      'offset': ?offset,
    });
  }

  Future<Map<String, dynamic>> createProperty(Map<String, dynamic> body) =>
      _api.postJson('/properties', body: body);

  Future<Map<String, dynamic>> getProperty(String id) =>
      _api.getJson('/properties/$id');

  Future<Map<String, dynamic>> patchProperty(
    String id,
    Map<String, dynamic> body,
  ) =>
      _api.patchJson('/properties/$id', body: body);

  Future<Map<String, dynamic>> mediaUploadUrls(
    String propertyId, {
    required List<Map<String, String>> files,
  }) {
    return _api.postJson('/properties/$propertyId/media/upload-urls', body: {
      'files': files,
    });
  }

  Future<Map<String, dynamic>> attachPropertyMedia(
    String propertyId, {
    List<String>? appendImages,
    List<String>? appendPaths,
    List<String>? images,
    String? videoUrl,
    String? tourUrl,
  }) {
    return _api.postJson('/properties/$propertyId/media', body: {
      'appendImages': ?appendImages,
      'appendPaths': ?appendPaths,
      'images': ?images,
      'videoUrl': ?videoUrl,
      'tourUrl': ?tourUrl,
    });
  }

  // --- Reviews ---

  Future<Map<String, dynamic>> listingReviews(String listingId) =>
      _api.getJson('/listings/$listingId/reviews');

  Future<Map<String, dynamic>> createReview(Map<String, dynamic> body) =>
      _api.postJson('/reviews', body: body);

  Future<Map<String, dynamic>> reviewEligibility(String propertyId) =>
      _api.getJson('/listings/$propertyId/reviews/eligibility');

  // --- Tenant maintenance / complaints ---

  Future<Map<String, dynamic>> tenantsMaintenance() =>
      _api.getJson('/tenants/maintenance');

  Future<Map<String, dynamic>> createTenantMaintenance(
    Map<String, dynamic> body,
  ) =>
      _api.postJson('/tenants/maintenance', body: body);

  Future<Map<String, dynamic>> confirmTenantMaintenance(
    String requestId, {
    required bool resolved,
  }) =>
      _api.postJson(
        '/tenants/maintenance/$requestId/confirm',
        body: {'resolved': resolved},
      );

  Future<Map<String, dynamic>> tenantsComplaints() =>
      _api.getJson('/tenants/complaints');

  Future<Map<String, dynamic>> createTenantComplaint(
    Map<String, dynamic> body,
  ) =>
      _api.postJson('/tenants/complaints', body: body);

  // --- Property management ---

  Future<Map<String, dynamic>> listPmProperties({
    int? limit,
    int? offset,
  }) {
    return _api.getJson('/property-management/properties', query: {
      'limit': ?limit,
      'offset': ?offset,
    });
  }

  Future<Map<String, dynamic>> createPmProperty(Map<String, dynamic> body) =>
      _api.postJson('/property-management/properties', body: body);

  Future<Map<String, dynamic>> subscribePmModule() =>
      _api.postJson('/subscriptions/pm-module', body: {});

  Future<Map<String, dynamic>> pmProperty(String id) =>
      _api.getJson('/property-management/properties/$id');

  Future<Map<String, dynamic>> pmPropertyDashboard(String id) =>
      _api.getJson('/property-management/properties/$id/dashboard');

  Future<Map<String, dynamic>> pmUnits(String propertyId) =>
      _api.getJson('/property-management/properties/$propertyId/units');

  Future<Map<String, dynamic>> updatePmUnit(
    String unitId,
    Map<String, dynamic> body,
  ) =>
      _api.patchJson('/property-management/units/$unitId', body: body);

  Future<Map<String, dynamic>> invitePmTenant({
    required String propertyId,
    required String tenantId,
  }) =>
      _api.postJson(
        '/property-management/properties/$propertyId/tenants/$tenantId/invite',
        body: {},
      );

  Future<Map<String, dynamic>> generatePmRentInvoices(String propertyId) =>
      _api.postJson(
        '/property-management/properties/$propertyId/rent/generate',
        body: {},
      );

  Future<Map<String, dynamic>> pmTenants(String propertyId) =>
      _api.getJson('/property-management/properties/$propertyId/tenants');

  Future<Map<String, dynamic>> pmMaintenance(String propertyId) =>
      _api.getJson('/property-management/properties/$propertyId/maintenance');

  Future<Map<String, dynamic>> updatePmMaintenanceStatus(
    String requestId, {
    required String status,
  }) =>
      _api.patchJson(
        '/property-management/maintenance/$requestId',
        body: {'status': status},
      );

  Future<Map<String, dynamic>> assignPmMaintenance(
    String requestId, {
    required String providerId,
  }) =>
      _api.postJson(
        '/property-management/maintenance/$requestId/assign',
        body: {'providerId': providerId},
      );

  Future<Map<String, dynamic>> createPmUnit(
    String propertyId,
    Map<String, dynamic> body,
  ) =>
      _api.postJson('/property-management/properties/$propertyId/units', body: body);

  Future<Map<String, dynamic>> createPmTenant(
    String propertyId,
    Map<String, dynamic> body,
  ) =>
      _api.postJson(
        '/property-management/properties/$propertyId/tenants',
        body: body,
      );

  Future<Map<String, dynamic>> pmLeases(String propertyId) =>
      _api.getJson('/property-management/properties/$propertyId/leases');

  Future<Map<String, dynamic>> createPmLease(
    String propertyId,
    Map<String, dynamic> body,
  ) =>
      _api.postJson(
        '/property-management/properties/$propertyId/leases',
        body: body,
      );

  Future<Map<String, dynamic>> pmRentInvoices(String propertyId) =>
      _api.getJson('/property-management/properties/$propertyId/rent');

  Future<Map<String, dynamic>> updatePmLeaseRent(
    String leaseId, {
    required int monthlyRent,
    bool applyToCurrentInvoice = true,
  }) =>
      _api.patchJson(
        '/property-management/leases/$leaseId/rent',
        body: {
          'monthlyRent': monthlyRent,
          'applyToCurrentInvoice': applyToCurrentInvoice,
        },
      );

  Future<Map<String, dynamic>> updatePmInvoiceAmountDue(
    String invoiceId, {
    required int amountDue,
  }) =>
      _api.patchJson(
        '/property-management/rent/invoices/$invoiceId',
        body: {'amountDue': amountDue},
      );

  Future<Map<String, dynamic>> recordPmPayment(
    String propertyId,
    Map<String, dynamic> body,
  ) =>
      _api.postJson(
        '/property-management/properties/$propertyId/rent/payments',
        body: body,
      );

  Future<Map<String, dynamic>> pmComplaints(String propertyId) =>
      _api.getJson('/property-management/properties/$propertyId/complaints');

  Future<Map<String, dynamic>> replyPmComplaint(
    String complaintId, {
    required String reply,
  }) {
    return _api.postJson(
      '/property-management/complaints/$complaintId/reply',
      body: {'reply': reply},
    );
  }

  Future<Map<String, dynamic>> markPmComplaintSeen(String complaintId) =>
      _api.postJson('/property-management/complaints/$complaintId/seen', body: {});

  Future<Map<String, dynamic>> pmStaff(String propertyId) =>
      _api.getJson('/property-management/properties/$propertyId/staff');

  Future<Map<String, dynamic>> upsertPmStaff(
    String propertyId,
    Map<String, dynamic> body,
  ) =>
      _api.postJson(
        '/property-management/properties/$propertyId/staff',
        body: body,
      );

  Future<Map<String, dynamic>> createVerificationRequest(
    Map<String, dynamic> body,
  ) =>
      _api.postJson('/verification/requests', body: body);

  Future<Map<String, dynamic>> verificationRequest(String id) =>
      _api.getJson('/verification/requests/$id');

  Future<Map<String, dynamic>> payVerificationRequest(
    String id, {
    String paymentMethod = 'mpesa',
    String? phoneNumber,
    String? email,
    String? idempotencyKey,
  }) {
    return _api.postJson('/verification/requests/$id/pay', body: {
      'paymentMethod': paymentMethod,
      'phoneNumber': ?phoneNumber,
      'email': ?email,
      'idempotencyKey': ?idempotencyKey,
    });
  }

  Future<Map<String, dynamic>> listPayments({int? limit}) =>
      _api.getJson('/payments', query: {'limit': ?limit});

  Future<Map<String, dynamic>> initiatePayment(Map<String, dynamic> body) =>
      _api.postJson('/payments/initiate', body: body);

  Future<Map<String, dynamic>> landlordDashboard() =>
      _api.getJson('/landlords/dashboard');

  Future<Map<String, dynamic>> portalStatus() =>
      _api.getJson('/me/portal-status');

  Future<Map<String, dynamic>> portalApply(Map<String, dynamic> body) =>
      _api.postJson('/me/portal-apply', body: body);

  Future<Map<String, dynamic>> adminVerificationRequests() =>
      _api.getJson('/admin/verification-requests');

  Future<Map<String, dynamic>> patchAdminVerificationRequest(
    String id,
    Map<String, dynamic> body,
  ) =>
      _api.patchJson('/admin/verification-requests/$id', body: body);

  Future<Map<String, dynamic>> adminIdentityVerifications() =>
      _api.getJson('/admin/verifications');

  Future<Map<String, dynamic>> patchAdminIdentityVerification(
    String id,
    Map<String, dynamic> body,
  ) =>
      _api.patchJson('/admin/verifications/$id', body: body);

  Future<Map<String, dynamic>> adminPortalApplications() =>
      _api.getJson('/admin/portal-applications');

  Future<Map<String, dynamic>> reviewAdminPortalApplication(
    String id, {
    required String action,
    String? rejectionReason,
  }) {
    return _api.postJson('/admin/portal-applications/$id/review', body: {
      'action': action,
      'rejectionReason': ?rejectionReason,
    });
  }

  Future<Map<String, dynamic>> adminPendingProviders() =>
      _api.getJson('/admin/service-providers');

  Future<Map<String, dynamic>> reviewAdminProvider(
    String id, {
    required String action,
    String? rejectionReason,
  }) {
    return _api.postJson('/admin/service-providers/$id/review', body: {
      'action': action,
      'rejectionReason': ?rejectionReason,
    });
  }

  Future<Map<String, dynamic>> adminScamReports({String? status}) =>
      _api.getJson('/admin/scam-reports', query: {'status': ?status});

  Future<Map<String, dynamic>> patchAdminScamReport(
    String id, {
    required String status,
  }) {
    return _api.patchJson('/admin/scam-reports/$id', body: {'status': status});
  }

  Future<Map<String, dynamic>> adminListProperties({String? q, int? limit}) =>
      _api.getJson('/admin/properties', query: {
        'q': ?q,
        'limit': ?limit,
      });

  Future<Map<String, dynamic>> adminSetPropertyActive(
    String id, {
    required bool isActive,
  }) {
    return _api.postJson('/admin/properties/$id/active', body: {
      'isActive': isActive,
    });
  }

  // --- Service providers ---

  Future<Map<String, dynamic>> listProviders({
    String? category,
    int? limit,
    int? offset,
  }) {
    return _api.getJson('/providers', query: {
      'category': ?category,
      'limit': ?limit,
      'offset': ?offset,
    });
  }

  Future<Map<String, dynamic>> providerDetail(String id) =>
      _api.getJson('/providers/$id');

  Future<Map<String, dynamic>> providerCategories() =>
      _api.getJson('/providers/categories');

  Future<Map<String, dynamic>> providerMe() => _api.getJson('/providers/me');

  Future<Map<String, dynamic>> registerProvider(Map<String, dynamic> body) =>
      _api.postJson('/providers', body: body);

  Future<Map<String, dynamic>> patchProviderMe(Map<String, dynamic> body) =>
      _api.patchJson('/providers/me', body: body);

  // --- Admin ---

  Future<Map<String, dynamic>> adminSummary() =>
      _api.getJson('/admin/summary');

  // --- Caretaker ---

  Future<Map<String, dynamic>> caretakerSession({
    required String phone,
    required String pin,
  }) {
    return _api.postJson('/caretakers/session', body: {
      'phone': phone,
      'pin': pin,
    });
  }

  Future<Map<String, dynamic>> listCaretakers() =>
      _api.getJson('/caretakers');

  Future<Map<String, dynamic>> createCaretaker({
    required String fullName,
    required String phone,
    required List<String> propertyIds,
  }) {
    return _api.postJson('/caretakers', body: {
      'fullName': fullName,
      'phone': phone,
      'propertyIds': propertyIds,
    });
  }

  Future<Map<String, dynamic>> regenerateCaretakerPin(String id) =>
      _api.postJson('/caretakers/$id/regenerate-pin', body: {});

  Future<Map<String, dynamic>> revokeCaretaker(String id) =>
      _api.postJson('/caretakers/$id/revoke', body: {});

  Future<Map<String, dynamic>> caretakerDashboard(String token) {
    return _api.getJson(
      '/caretakers/dashboard',
      headers: {'X-Caretaker-Token': token},
    );
  }

  Future<Map<String, dynamic>> caretakerSetVacancy({
    required String token,
    required String propertyId,
    required bool isVacant,
  }) {
    return _api.patchJson(
      '/caretakers/properties/$propertyId/vacancy',
      body: {'isVacant': isVacant},
      headers: {'X-Caretaker-Token': token},
    );
  }

  Future<Map<String, dynamic>> listPayoutDestinations() =>
      _api.getJson('/landlords/payouts');

  Future<Map<String, dynamic>> listPayoutBatches() =>
      _api.getJson('/landlords/payouts/batches');

  Future<Map<String, dynamic>> createPayoutDestination(
    Map<String, dynamic> body,
  ) =>
      _api.postJson('/landlords/payouts', body: body);

  Future<Map<String, dynamic>> deactivatePayoutDestination(String id) =>
      _api.postJson('/landlords/payouts/$id/deactivate', body: {});

  Future<Map<String, dynamic>> requestPayoutPhoneOtp(String phone) =>
      _api.postJson('/landlords/payouts/otp/request', body: {'phone': phone});

  Future<Map<String, dynamic>> confirmPayoutPhoneOtp({
    required String phone,
    required String code,
  }) {
    return _api.postJson('/landlords/payouts/otp/confirm', body: {
      'phone': phone,
      'code': code,
    });
  }

  Future<Map<String, dynamic>> requestPhoneOtp(String phone) =>
      _api.postJson('/auth/otp/request', body: {'phone': phone});

  Future<Map<String, dynamic>> verifyPhoneOtp({
    required String phone,
    required String code,
  }) {
    return _api.postJson('/auth/otp/verify', body: {
      'phone': phone,
      'code': code,
    });
  }

  Future<Map<String, dynamic>> requestPasswordResetOtp(String email) =>
      _api.postJson('/auth/password-reset/request', body: {'email': email});

  Future<Map<String, dynamic>> verifyPasswordResetOtp({
    required String email,
    required String code,
  }) {
    return _api.postJson('/auth/password-reset/verify', body: {
      'email': email,
      'code': code,
    });
  }

  Future<Map<String, dynamic>> completePasswordResetOtp({
    required String email,
    required String code,
    required String password,
  }) {
    return _api.postJson('/auth/password-reset/complete', body: {
      'email': email,
      'code': code,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> orgMembership() =>
      _api.getJson('/me/org-membership');

  Future<Map<String, dynamic>> listOrgTeam() => _api.getJson('/org/team');

  Future<Map<String, dynamic>> inviteOrgTeamMember({
    required String email,
    String? fullName,
  }) {
    return _api.postJson('/org/team', body: {
      'email': email,
      'fullName': ?fullName,
    });
  }

  Future<Map<String, dynamic>> approveOrgTeamMember(String memberUserId) =>
      _api.postJson('/org/team/approve', body: {'memberUserId': memberUserId});

  Future<Map<String, dynamic>> revokeOrgTeamMember(String memberUserId) =>
      _api.postJson('/org/team/revoke', body: {'memberUserId': memberUserId});

  Future<Map<String, dynamic>> agencyDashboard() =>
      _api.getJson('/agencies/dashboard');

  Future<Map<String, dynamic>> managerDashboard() =>
      _api.getJson('/managers/dashboard');

  Future<Map<String, dynamic>> referralsMe() => _api.getJson('/referrals/me');

  Future<Map<String, dynamic>> resolveReferralCode(String code) =>
      _api.postJson('/referrals/resolve', body: {'code': code});

  Future<Map<String, dynamic>> adminPmOverview() =>
      _api.getJson('/admin/pm/overview');

  Future<Map<String, dynamic>> resolveAdminPmDispute(
    String id, {
    required String outcome,
    required String notes,
  }) {
    return _api.postJson('/admin/pm/disputes/$id/resolve', body: {
      'outcome': outcome,
      'notes': notes,
    });
  }

  Future<Map<String, dynamic>> landlordAnalytics() =>
      _api.getJson('/landlords/analytics');

  Future<Map<String, dynamic>> compareListings(List<String> ids) =>
      _api.postJson('/listings/compare', body: {'ids': ids});

  Future<Map<String, dynamic>> listSavedSearches() =>
      _api.getJson('/saved-searches');

  Future<Map<String, dynamic>> createSavedSearch(Map<String, dynamic> body) =>
      _api.postJson('/saved-searches', body: body);

  Future<Map<String, dynamic>> patchSavedSearch(
    String id,
    Map<String, dynamic> body,
  ) =>
      _api.patchJson('/saved-searches/$id', body: body);

  Future<Map<String, dynamic>> deleteSavedSearch(String id) =>
      _api.deleteJson('/saved-searches/$id');

  Future<Map<String, dynamic>> adminCreateProvider(Map<String, dynamic> body) =>
      _api.postJson('/admin/service-providers/create', body: body);

  Future<Map<String, dynamic>> adminCreateProperty(Map<String, dynamic> body) =>
      _api.postJson('/admin/properties', body: body);

  Future<Map<String, dynamic>> adminSetPropertyVerified(
    String id, {
    required bool isVerified,
  }) {
    return _api.postJson('/admin/properties/$id/verified', body: {
      'isVerified': isVerified,
    });
  }

  Future<Map<String, dynamic>> adminAdjustAuthenticity(
    String id, {
    int? score,
    int? delta,
  }) {
    return _api.patchJson('/admin/properties/$id/authenticity', body: {
      'score': ?score,
      'delta': ?delta,
    });
  }

  Future<Map<String, dynamic>> submitContact({
    required String email,
    required String message,
  }) {
    return _api.postJson('/contact', body: {'email': email, 'message': message});
  }

  Future<Map<String, dynamic>> previewListingImport({
    required String csvText,
    required String filename,
  }) {
    return _api.postJson('/listings/import/preview', body: {
      'csvText': csvText,
      'filename': filename,
    });
  }

  Future<Map<String, dynamic>> executeListingImport({
    required String filename,
    required List<Map<String, dynamic>> rows,
  }) {
    return _api.postJson('/listings/import/execute', body: {
      'filename': filename,
      'rows': rows,
    });
  }

  Future<Map<String, dynamic>> listIntegrationKeys() =>
      _api.getJson('/integrations/keys');

  Future<Map<String, dynamic>> createIntegrationKey({required String name}) {
    return _api.postJson('/integrations/keys', body: {'name': name});
  }

  Future<Map<String, dynamic>> revokeIntegrationKey(String id) {
    return _api.postJson('/integrations/keys/$id/revoke');
  }

  Future<Map<String, dynamic>> adminRevenue() => _api.getJson('/admin/revenue');

  Future<Map<String, dynamic>> advertisePackages() =>
      _api.getJson('/advertise/packages');

  Future<Map<String, dynamic>> submitAdvertiseInquiry({
    required String name,
    String? company,
    required String email,
    String? phone,
    required String packageId,
    required String message,
    String? budget,
  }) {
    return _api.postJson('/advertise/inquiries', body: {
      'name': name,
      'company': ?company,
      'email': email,
      'phone': ?phone,
      'packageId': packageId,
      'message': message,
      'budget': ?budget,
    });
  }

  Future<Map<String, dynamic>> adminSendAnnouncement({
    required String title,
    required String body,
    required String ctaLabel,
    required String ctaUrl,
    required List<String> targetRoles,
  }) {
    return _api.postJson('/admin/announcements', body: {
      'title': title,
      'body': body,
      'ctaLabel': ctaLabel,
      'ctaUrl': ctaUrl,
      'targetRoles': targetRoles,
    });
  }

  Future<Map<String, dynamic>> adminPromo() => _api.getJson('/admin/promo');

  Future<Map<String, dynamic>> adminAdvertiseInquiries() =>
      _api.getJson('/admin/advertise');

  Future<Map<String, dynamic>> adminApproveAdvertise({
    required String inquiryId,
    String? packageId,
    int? amountKes,
    String? notes,
  }) {
    return _api.postJson('/admin/advertise/approve', body: {
      'inquiryId': inquiryId,
      'packageId': ?packageId,
      'amountKes': ?amountKes,
      'notes': ?notes,
    });
  }
}
