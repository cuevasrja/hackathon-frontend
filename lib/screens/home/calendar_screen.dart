import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/event_model.dart';
import 'package:hackathon_frontend/services/event_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import 'dart:developer' as developer;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  LinkedHashMap<DateTime, List<Event>> _events = LinkedHashMap();
  bool _isLoading = true;
  String? _error;

  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEvents();
  }

  void _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await _eventService.fetchJoinedEvents();

      final eventMap = LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
      );

      for (final event in events) {
        final startDate = event.event.timeBegin;
        final endDate = event.event.timeEnd.isBefore(startDate) ? startDate : event.event.timeEnd;

        var day = startDate;
        while (day.isBefore(endDate) || isSameDay(day, endDate)) {
          final date = DateTime.utc(day.year, day.month, day.day);
          if (eventMap[date] == null) {
            eventMap[date] = [];
          }
          eventMap[date]!.add(event.event);
          day = day.add(const Duration(days: 1));
        }
      }

      setState(() {
        _events = eventMap;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching events: $e', name: 'CalendarScreen');

      setState(() {
        _error = "Error al cargar eventos. Inténtalo de nuevo más tarde.";
        _isLoading = false;
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final events = _events[day] ?? [];
    if (events.isNotEmpty) {
      developer.log('Events for $day: ${events.length}', name: 'CalendarScreen');
    }
    return events;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      final events = _getEventsForDay(selectedDay);
      if (events.isNotEmpty) {
        _showEventsBottomSheet(context, events);
      }
    }
  }

  void _showEventsBottomSheet(BuildContext context, List<Event> events) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Events for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(events[index].name),
                    subtitle: Text(events[index].description),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TableCalendar<Event>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  eventLoader: _getEventsForDay,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  rowHeight: MediaQuery.of(context).size.height / 10,
                  daysOfWeekHeight: MediaQuery.of(context).size.height / 18,
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isNotEmpty) {
                        return Positioned(
                          right: 1,
                          bottom: 1,
                          child: _buildEventsMarker(events),
                        );
                      }
                      return null;
                    },
                  ),
                ),
    );
  }

  Widget _buildEventsMarker(List<dynamic> events) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: events.take(4).map((event) {
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors[(event.id as int) % colors.length],
          ),
        );
      }).toList(),
    );
  }
}