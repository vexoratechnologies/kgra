import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider({required NotificationRepository repository}) : _repository = repository;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notificationsList => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    try {
      _notifications = await _repository.getNotifications();
    } catch (e) {
      _setError('Failed to fetch notifications: ${e.toString()}');
    } finally {
      _setLoading(false);
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
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete notification: ${e.toString()}');
      return false;
    }
  }

  /// Automatically generates and saves a notification to Firestore.
  /// This is used to create alerts when new content is added by admins.
  Future<bool> sendSystemNotification({
    required String title,
    required String body,
    required String routingPath,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      routingPath: routingPath,
      createdAt: DateTime.now().toIso8601String(),
    );
    return await addNotification(notification);
  }
}
