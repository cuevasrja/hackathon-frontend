import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/event_model.dart';
import 'package:hackathon_frontend/models/event_response_model.dart';
import 'package:hackathon_frontend/services/event_service.dart';
import 'package:hackathon_frontend/widgets/weekly_calendar.dart';

class ManageYourEventsSection extends StatefulWidget {
  const ManageYourEventsSection({super.key});

  @override
  State<ManageYourEventsSection> createState() => _ManageYourEventsSectionState();
}

class _ManageYourEventsSectionState extends State<ManageYourEventsSection> {
  final EventService _eventService = EventService();
  List<Event> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final results = await Future.wait([
        _eventService.fetchOrganizedEvents(),
        _eventService.fetchJoinedEvents(),
      ]);
      final organized = results[0] as List<Event>;
      final joined = (results[1] as List<MyEvent>).map((e) => e.event).toList();

      final allEventsById = <int, Event>{};
      for (var event in organized) {
        allEventsById[event.id] = event;
      }
      for (var event in joined) {
        allEventsById.putIfAbsent(event.id, () => event);
      }
      
      if (!mounted) return;

      setState(() {
        _allEvents = allEventsById.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Administra tus eventos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
          else
            WeeklyCalendar(events: _allEvents),
        ],
      ),
    );
  }
}