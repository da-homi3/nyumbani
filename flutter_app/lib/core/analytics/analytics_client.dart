import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/utils/app_log.dart';

/// Replaceable product analytics (prompt §25). Swap implementation without UI rewrites.
abstract class AnalyticsClient {
  void track(String event, [Map<String, Object?> properties = const {}]);
}

/// Dev / default sink — logs in debug; no PII required.
class LogAnalyticsClient implements AnalyticsClient {
  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {
    if (properties.isEmpty) {
      AppLog.i('analytics $event');
    } else {
      AppLog.i('analytics $event $properties');
    }
  }
}

final analyticsProvider = Provider<AnalyticsClient>((ref) {
  return LogAnalyticsClient();
});

/// Canonical event names from the master build prompt.
abstract final class AnalyticsEvents {
  static const appOpened = 'app_opened';
  static const signupStarted = 'signup_started';
  static const signupCompleted = 'signup_completed';
  static const loginCompleted = 'login_completed';
  static const propertySearch = 'property_search';
  static const propertyViewed = 'property_viewed';
  static const propertySaved = 'property_saved';
  static const propertyShared = 'property_shared';
  static const contactLandlord = 'contact_landlord';
  static const messageSent = 'message_sent';
  static const listingCreated = 'listing_created';
  static const listingPublished = 'listing_published';
}
