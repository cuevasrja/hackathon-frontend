class Notification {
  final String title;
  final String body;
  final DateTime date;
  bool isRead;

  Notification({
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
  });
}
