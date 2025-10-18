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
  final int? placeId;
  final int? organizerId;
  final int? communityId;
  final int? minAge;
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
    this.minAge,
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
    final placeJson = json['place'];
    final organizerJson = json['organizer'];
    final communityJson = json['community'];
    final countJson = json['_count'];

    return Event(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      timeBegin: DateTime.parse(json['timeBegin'] as String),
      timeEnd: json['timeEnd'] != null ? DateTime.parse(json['timeEnd'] as String) : DateTime.now(),
      placeId: json['placeId'] as int? ?? 0,
      organizerId: json['organizerId'] as int?,
      communityId: json['communityId'] as int?,
      minAge: json['minAge'] as int? ?? 0,
      status: json['status'] as String,
      visibility: json['visibility'] as String? ?? 'PRIVATE',
      createdAt: DateTime.parse(json['createdAt'] as String),
      externalUrl: json['externalUrl'] as String?,
      place: placeJson is Map<String, dynamic> ? Place.fromJson(placeJson) : null,
      organizer: organizerJson is Map<String, dynamic> ? User.fromJson(organizerJson) : null,
      community: communityJson is Map<String, dynamic> ? Community.fromJson(communityJson) : null,
      ticketCount: countJson is Map<String, dynamic> ? TicketCount.fromJson(countJson) : null,
    );
  }
}
