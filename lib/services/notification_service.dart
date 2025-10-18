import 'package:hackathon_frontend/models/notification_model.dart';

class NotificationService {
  static List<Notification> getNotifications() {
    return [
      Notification(
        title: 'New Event',
        body: 'You have been invited to a new event.',
        date: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Notification(
        title: 'Event Reminder',
        body: 'Your event is starting in 1 hour.',
        date: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: true,
      ),
      Notification(
        title: 'New Follower',
        body: 'You have a new follower.',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
