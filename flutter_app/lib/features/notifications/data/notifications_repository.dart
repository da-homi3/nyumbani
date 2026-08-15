import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(mobileApiRepositoryProvider));
});

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.href,
    this.entityType,
    this.entityId,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String createdAt;
  final String? href;
  final String? entityType;
  final String? entityId;
  final String? readAt;

  bool get isUnread => readAt == null || readAt!.isEmpty;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: (json['type'] as String?) ?? 'account',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      href: json['href'] as String?,
      entityType: (json['entityType'] as String?) ?? (json['entity_type'] as String?),
      entityId: (json['entityId'] as String?) ?? (json['entity_id'] as String?),
      readAt: (json['readAt'] as String?) ?? (json['read_at'] as String?),
      createdAt: (json['createdAt'] as String?) ?? (json['created_at'] as String?) ?? '',
    );
  }
}

class NotificationsRepository {
  NotificationsRepository(this._api);
  final MobileApiRepository _api;

  Future<List<AppNotification>> list({int limit = 40, bool unreadOnly = false}) async {
    final json = await _api.listNotifications(limit: limit, unreadOnly: unreadOnly);
    final raw = json['notifications'] ?? json['items'] ?? json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .where((n) => n.id.isNotEmpty)
        .toList();
  }

  Future<int> unreadCount() async {
    final json = await _api.notificationsUnreadCount();
    return (json['count'] as num?)?.toInt() ??
        (json['unreadCount'] as num?)?.toInt() ??
        0;
  }

  Future<void> markRead(String id) async {
    await _api.markNotificationsRead({'id': id});
  }

  Future<void> markAllRead() async {
    await _api.markNotificationsRead({'all': true});
  }

  Future<NotificationPrefs> prefs() async {
    final json = await _api.notificationPrefs();
    return NotificationPrefs.fromJson(json);
  }

  Future<NotificationPrefs> updatePrefs(Map<String, dynamic> patch) async {
    final json = await _api.updateNotificationPrefs(patch);
    return NotificationPrefs.fromJson(json);
  }
}

class NotificationPrefs {
  const NotificationPrefs({
    required this.announcements,
    required this.listings,
    required this.messages,
    required this.maintenance,
    required this.payments,
    required this.account,
    required this.pushEnabled,
  });

  final bool announcements;
  final bool listings;
  final bool messages;
  final bool maintenance;
  final bool payments;
  final bool account;
  final bool pushEnabled;

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    final p = json['preferences'] is Map
        ? Map<String, dynamic>.from(json['preferences'] as Map)
        : json;
    return NotificationPrefs(
      announcements: p['announcements'] != false,
      listings: p['listings'] != false,
      messages: p['messages'] != false,
      maintenance: p['maintenance'] != false,
      payments: p['payments'] != false,
      account: p['account'] != false,
      pushEnabled: p['push_enabled'] != false && p['pushEnabled'] != false,
    );
  }
}

final notificationsListProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationsRepositoryProvider).list();
});

final notificationsUnreadCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});

final notificationPrefsProvider =
    FutureProvider.autoDispose<NotificationPrefs>((ref) {
  return ref.watch(notificationsRepositoryProvider).prefs();
});
