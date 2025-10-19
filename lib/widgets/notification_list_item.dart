import 'package:flutter/material.dart' hide Notification;
import 'package:hackathon_frontend/models/notification_model.dart' as model;

class NotificationListItem extends StatelessWidget {
  final model.Notification notification;

  const NotificationListItem({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.read ? Theme.of(context).primaryColor : Colors.grey,
        child: const Icon(Icons.notifications, color: Colors.white),
      ),
      title: Text(notification.title),
      subtitle: Text(notification.message),
      trailing: Text(
        '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}',
      ),
    );
  }
}