import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _kLastReadTimeKey = 'last_read_notification_time';
  static const String _kReadIdsKey = 'read_notification_ids';

  final NotificationRepository _repository;
  final SharedPreferences _prefs;

  NotificationProvider({
    required NotificationRepository repository,
    required SharedPreferences prefs,
  })  : _repository = repository,
        _prefs = prefs {
    _loadReadState();
  }

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  int _unreadCount = 0;
  int _firestoreTotalCount = 0;

  String? _lastReadTime;
  Set<String> _readIds = {};
  String? _activeUserId;

  void setActiveUserId(String? uid) {
    if (_activeUserId != uid) {
      _activeUserId = uid;
      _calculateUnreadCount();
      notifyListeners();
    }
  }

  /// Returns notifications filtered specifically for the current user:
  /// - General announcements (targetUserId is null or 'all')
  /// - Targeted notifications where targetUserId == currentUserId
  /// - Deduplicates legacy approval notifications so users don't see 5 duplicate "Registration Approved" alerts
  List<NotificationModel> get notificationsList => getNotificationsForUser(_activeUserId);

  List<NotificationModel> getNotificationsForUser(String? currentUserId) {
    if (_notifications.isEmpty) return [];

    final list = <NotificationModel>[];
    bool hasSeenLegacyApproval = false;

    for (final n in _notifications) {
      final isApproval = n.title.toLowerCase().contains('registration approved') ||
          n.title.toLowerCase().contains('account approved') ||
          n.body.toLowerCase().contains('account registration has been approved');

      if (n.targetUserId != null && n.targetUserId!.isNotEmpty && n.targetUserId != 'all') {
        // Targeted notification: only show if matching current user
        if (currentUserId != null && n.targetUserId == currentUserId) {
          list.add(n);
        }
      } else {
        // Broadcast notification (or legacy without targetUserId)
        if (isApproval) {
          // If legacy approval notification without targetUserId, only show once to avoid repeating 5 times
          if (!hasSeenLegacyApproval) {
            hasSeenLegacyApproval = true;
            list.add(n);
          }
        } else {
          list.add(n);
        }
      }
    }
    return list;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  /// Returns unread notifications count for badge display.
  int get unreadCount => _unreadCount;

  /// Backward-compatible alias for badge consumers (e.g. HomeScreen, MainNav)
  int get totalCount => _unreadCount;

  /// Total notification count in database
  int get totalFirestoreCount => _firestoreTotalCount;

  void _loadReadState() {
    _lastReadTime = _prefs.getString(_kLastReadTimeKey);
    final list = _prefs.getStringList(_kReadIdsKey) ?? [];
    _readIds = list.toSet();
  }

  void _saveReadState() {
    if (_lastReadTime != null) {
      _prefs.setString(_kLastReadTimeKey, _lastReadTime!);
    }
    final list = _readIds.toList();
    if (list.length > 100) {
      _readIds = list.sublist(list.length - 100).toSet();
    }
    _prefs.setStringList(_kReadIdsKey, _readIds.toList());
  }

  void _calculateUnreadCount() {
    final list = notificationsList;
    if (list.isEmpty) {
      _unreadCount = 0;
      return;
    }
    int count = 0;
    for (final n in list) {
      if (_isUnread(n)) {
        count++;
      }
    }
    _unreadCount = count;
  }

  bool _isUnread(NotificationModel n) {
    if (_readIds.contains(n.id)) return false;
    if (_lastReadTime != null) {
      if (n.createdAt.isEmpty) return false;
      final notifTime = DateTime.tryParse(n.createdAt);
      final lastRead = DateTime.tryParse(_lastReadTime!);
      if (notifTime != null && lastRead != null) {
        return notifTime.isAfter(lastRead);
      }
      return false;
    }
    return true;
  }

  bool isNotificationRead(NotificationModel n) {
    return !_isUnread(n);
  }

  void markAllAsRead() {
    _lastReadTime = DateTime.now().toIso8601String();
    for (final n in _notifications) {
      _readIds.add(n.id);
    }
    _saveReadState();
    _unreadCount = 0;
    notifyListeners();
  }

  void markAsRead(String id) {
    if (!_readIds.contains(id)) {
      _readIds.add(id);
      _saveReadState();
      _calculateUnreadCount();
      notifyListeners();
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? val) {
    _error = val;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _setLoading(true);
    _setError(null);
    _hasMore = true;
    try {
      final results = await Future.wait([
        _repository.getNotificationsPaged(limit: 15),
        _repository.getNotificationsCount(),
      ]);
      _notifications = results[0] as List<NotificationModel>;
      _firestoreTotalCount = results[1] as int;
      if (_notifications.length < 15) {
        _hasMore = false;
      }
      _calculateUnreadCount();
    } catch (e) {
      _setError('Failed to fetch notifications: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMoreNotifications() async {
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    _setError(null);
    notifyListeners();

    try {
      final lastCreatedAt = _notifications.isNotEmpty ? _notifications.last.createdAt : null;
      final moreNotifications = await _repository.getNotificationsPaged(
        limit: 15,
        startAfterCreatedAt: lastCreatedAt,
      );

      if (moreNotifications.isEmpty || moreNotifications.length < 15) {
        _hasMore = false;
      }

      _notifications.addAll(moreNotifications);
      _calculateUnreadCount();
    } catch (e) {
      _setError('Failed to fetch more notifications: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<bool> addNotification(NotificationModel notification) async {
    _setError(null);
    try {
      await _repository.saveNotification(notification);
      await fetchNotifications();
      return true;
    } catch (e) {
      _setError('Failed to add notification: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    _setError(null);
    try {
      await _repository.deleteNotification(id);
      _notifications.removeWhere((n) => n.id == id);
      _readIds.remove(id);
      _saveReadState();
      _calculateUnreadCount();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete notification: ${e.toString()}');
      return false;
    }
  }

  /// Automatically generates and saves a notification to Firestore.
  /// If targetUserId is null or 'all', also broadcasts FCM push alert to all members.
  Future<bool> sendSystemNotification({
    required String title,
    required String body,
    required String routingPath,
    String? targetUserId,
  }) async {
    print('🔔 [NotificationProvider] sendSystemNotification: "$title" (target: $targetUserId)');
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      routingPath: routingPath,
      createdAt: DateTime.now().toIso8601String(),
      targetUserId: targetUserId,
    );
    // Only broadcast push notification if this is a general announcement for all members
    if (targetUserId == null || targetUserId.isEmpty || targetUserId == 'all') {
      try {
        await PushNotificationService.instance.sendBroadcastNotification(
          title: title,
          body: body,
          routingPath: routingPath,
        );
      } catch (e) {
        print('❌ Error triggering FCM broadcast push notification: $e');
      }
    }
    return await addNotification(notification);
  }
}
