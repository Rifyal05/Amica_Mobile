import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/authenticated_client.dart';
import '../services/api_config.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final AuthenticatedClient _client = AuthenticatedClient();
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data
            .map((json) => AppNotification.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/read-all'),
      );
      _notifications = _notifications
          .map(
            (n) => AppNotification(
              id: n.id,
              senderId: n.senderId,
              senderName: n.senderName,
              senderAvatar: n.senderAvatar,
              type: n.type,
              referenceId: n.referenceId,
              text: n.text,
              createdAt: n.createdAt,
              isRead: true,
            ),
          )
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
