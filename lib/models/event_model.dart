import 'package:hackathon_frontend/models/community_model.dart';
import 'package:hackathon_frontend/models/place_model.dart';
import 'package:hackathon_frontend/models/ticket_count_model.dart';
import 'package:hackathon_frontend/models/user_model.dart';

class Event {
  final int id;
  final String name;
  final String description;
  final DateTime timeBegin;
  final DateTime timeEnd;
  final int placeId;
  final int organizerId;
  final int? communityId;
  final int minAge;
  final String status;
  final String visibility;
  final DateTime createdAt;
  final String? externalUrl;
  final Place? place;
  final User? organizer;
  final Community? community;
  final TicketCount? ticketCount;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.timeBegin,
    required this.timeEnd,
    required this.placeId,
    required this.organizerId,
    this.communityId,
    required this.minAge,
    required this.status,
    required this.visibility,
    required this.createdAt,
    this.externalUrl,
    this.place,
    this.organizer,
    this.community,
    this.ticketCount,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      timeBegin: DateTime.parse(json['timeBegin'] as String),
      timeEnd: json['timeEnd'] != null ? DateTime.parse(json['timeEnd'] as String) : DateTime.now(),
      placeId: json['placeId'] as int,
      organizerId: json['organizerId'] as int,
      communityId: json['communityId'] as int?,
      minAge: json['minAge'] as int,
      status: json['status'] as String,
      visibility: json['visibility'] as String? ?? 'PRIVATE',
      createdAt: DateTime.parse(json['createdAt'] as String),
      externalUrl: json['externalUrl'] as String?,
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      organizer: User.fromJson(json['organizer'] as Map<String, dynamic>),
      community: json['community'] != null ? Community.fromJson(json['community'] as Map<String, dynamic>) : null,
      ticketCount: TicketCount.fromJson(json['_count'] as Map<String, dynamic>),
    );
  }
}
