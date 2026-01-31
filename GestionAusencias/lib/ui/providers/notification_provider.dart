import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        title: json['title'],
        message: json['message'],
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'],
      );
}

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // For now, initializing with some dummy data if empty to show it working
    // In a real app, this would come from SharedPreferences or an API
    if (_notifications.isEmpty) {
      _notifications = [
        AppNotification(
          id: '1',
          title: 'Ausencia Registrada',
          message: 'Carlos Ruiz ha registrado una ausencia para mañana.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AppNotification(
          id: '2',
          title: 'Guardia Asignada',
          message: 'Se te ha asignado una guardia en el Aula A10.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    // Logic to clear from SharedPreferences would go here
    notifyListeners();
  }

  void addNotification(String title, String message) {
    final newNotif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, newNotif);
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }
}
