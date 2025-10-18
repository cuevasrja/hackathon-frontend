import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/event_model.dart';
import 'package:hackathon_frontend/services/event_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import 'dart:developer' as developer;
import 'package:timezone/timezone.dart' as tz;

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
      final joinedEvents = await _eventService.fetchJoinedEvents();
      developer.log('Fetched ${joinedEvents.length} events', name: 'CalendarScreen');

      final eventMap = LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
      );

      for (final joinedEvent in joinedEvents) {
        final event = joinedEvent.event;
        final startDate = tz.TZDateTime.from(event.timeBegin, tz.local);
        final endDate = tz.TZDateTime.from(event.timeEnd, tz.local);

        for (var day = startDate;
            day.isBefore(endDate.add(const Duration(days: 1)));
            day = day.add(const Duration(days: 1))) {
          final dateOnly = DateTime(day.year, day.month, day.day);
          if (eventMap[dateOnly] == null) {
            eventMap[dateOnly] = [];
          }
          eventMap[dateOnly]!.add(event);
        }
      }

      if (!mounted) return;

      setState(() {
        _events = eventMap;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching events: $e', name: 'CalendarScreen');
      if (!mounted) return;
      setState(() {
        _error = "Error al cargar eventos. Inténtalo de nuevo más tarde.";
        _isLoading = false;
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _events[dateOnly] ?? [];
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
                'Eventos para el ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
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
        title: const Text('Calendario de Eventos'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TableCalendar<Event>(
                  locale: 'es_ES',
                  firstDay: DateTime(2020, 1, 1),
                  lastDay: DateTime(2030, 12, 31),
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
                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildEventsMarker(events),
                        );
                      }
                      return null;
                    },
                  ),
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mes',
                    CalendarFormat.twoWeeks: '2 Semanas',
                    CalendarFormat.week: 'Semana',
                  },
                ),
    );
  }

  Widget _buildEventsMarker(List<dynamic> events) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue[400],
      ),
      width: 16,
      height: 16,
      child: Center(
        child: Text(
          '${events.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}