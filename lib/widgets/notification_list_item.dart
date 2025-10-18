import 'package:flutter/material.dart' hide Notification;
import 'package:hackathon_frontend/models/notification_model.dart' as model;

class NotificationListItem extends StatelessWidget {
  final model.Notification notification;
  final VoidCallback onTap;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: notification.isRead ? Colors.grey : Theme.of(context).primaryColor,
        child: const Icon(Icons.notifications, color: Colors.white),
      ),
      title: Text(notification.title),
      subtitle: Text(notification.body),
      trailing: Text(
        '${notification.date.day}/${notification.date.month}/${notification.date.year}',
      ),
    );
  }
}