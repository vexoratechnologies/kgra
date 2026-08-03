import 'package:flutter/material.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider({required NotificationRepository repository}) : _repository = repository;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  int _totalCount = 0;

  List<NotificationModel> get notificationsList => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;
  int get totalCount => _totalCount;

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
      _totalCount = results[1] as int;
      if (_notifications.length < 15) {
        _hasMore = false;
      }
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
      if (_totalCount > 0) _totalCount--;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete notification: ${e.toString()}');
      return false;
    }
  }

  /// Automatically generates and saves a notification to Firestore and broadcasts FCM push alert.
  Future<bool> sendSystemNotification({
    required String title,
    required String body,
    required String routingPath,
  }) async {
    print('🔔 [NotificationProvider] sendSystemNotification: "$title"');
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      routingPath: routingPath,
      createdAt: DateTime.now().toIso8601String(),
    );
    try {
      await PushNotificationService.instance.sendBroadcastNotification(
        title: title,
        body: body,
        routingPath: routingPath,
      );
    } catch (e) {
      print('❌ Error triggering FCM broadcast push notification: $e');
    }
    return await addNotification(notification);
  }
}
