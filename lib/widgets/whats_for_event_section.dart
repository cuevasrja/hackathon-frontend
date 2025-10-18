import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/event_model.dart';
import 'package:hackathon_frontend/models/event_response_model.dart';
import 'package:hackathon_frontend/models/meal_model.dart';
import 'package:hackathon_frontend/screens/events/event_detail.dart';
import 'package:hackathon_frontend/services/event_service.dart';
import 'package:hackathon_frontend/widgets/small_event_card.dart';

class WhatsForEventSection extends StatefulWidget {
  const WhatsForEventSection({super.key});

  @override
  State<WhatsForEventSection> createState() => _WhatsForEventSectionState();
}

class _WhatsForEventSectionState extends State<WhatsForEventSection> {
  late Future<List<Meal>> _eventMealsFuture;
  final EventService _eventService = EventService();
  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    _eventMealsFuture = _fetchEventMeals();
  }

  Future<List<Meal>> _fetchEventMeals() async {
    final EventResponse response =
        await _eventService.fetchEvents(page: 1, limit: 20);
    final events = response.events;

    if (events.isEmpty) {
      if (mounted) {
        setState(() => _events = []);
      }
      return const [];
    }

    if (mounted) {
      setState(() => _events = events);
    }

    return events.map(_mapEventToMeal).toList();
  }

  Meal _mapEventToMeal(Event event) {
    final placeName = event.place?.name ?? '';
    final subtitle = placeName.isNotEmpty ? placeName : event.description;
    final imagePath = event.place?.image ?? '';
    final truncatedSubtitle = subtitle.length > 60
        ? '${subtitle.substring(0, 57)}...'
        : subtitle;

    return Meal(
      name: event.name,
      description: truncatedSubtitle,
      imagePath: imagePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '¿Qué plancito quieres hoy?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: FutureBuilder<List<Meal>>(
            future: _eventMealsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('No se pudieron cargar los eventos.'),
                );
              }

              final meals = snapshot.data ?? const [];

              if (meals.isEmpty) {
                return const Center(
                  child: Text('No hay eventos disponibles por ahora.'),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  final event = index < _events.length ? _events[index] : null;
                  return SmallEventCard(
                    meal: meals[index],
                    onTap: () {
                      if (event == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventDetailsScreen(event: event),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
