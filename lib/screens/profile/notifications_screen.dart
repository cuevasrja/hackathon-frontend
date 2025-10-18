import 'package:flutter/material.dart' hide Notification;
import 'package:hackathon_frontend/models/notification_model.dart' as model;
import 'package:hackathon_frontend/services/notification_service.dart';
import 'package:hackathon_frontend/widgets/notification_list_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<model.Notification> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = NotificationService.getNotifications();
    _notifications.sort((a, b) => b.date.compareTo(a.date));
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index].isRead = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return NotificationListItem(
            notification: _notifications[index],
            onTap: () => _markAsRead(index),
          );
        },
      ),
    );
  }
}
