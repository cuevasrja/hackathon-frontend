import 'package:hackathon_frontend/models/event_model.dart';

class EventResponse {
  final List<Event> events;
  final int total;
  final int page;
  final int limit;

  EventResponse({
    required this.events,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    var eventList = json['data'] as List? ?? <dynamic>[];
    List<Event> events = eventList.map((i) => Event.fromJson(i as Map<String, dynamic>)).toList();

    final pagination = json['pagination'] as Map<String, dynamic>?;
    return EventResponse(
      events: events,
      total: pagination != null ? (pagination['total'] as int? ?? 0) : 0,
      page: pagination != null ? (pagination['page'] as int? ?? 0) : 0,
      limit: pagination != null ? (pagination['limit'] as int? ?? 0) : 0,
    );
  }
}

class JoinedEvent {
  final int eventId;
  final int userId;
  final DateTime joinedAt;
  final Event event;

  JoinedEvent({
    required this.eventId,
    required this.userId,
    required this.joinedAt,
    required this.event,
  });

  factory JoinedEvent.fromJson(Map<String, dynamic> json) {
    return JoinedEvent(
      eventId: json['eventId'] as int,
      userId: json['userId'] as int,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
    );
  }
}