import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/event_model.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:hackathon_frontend/utils/colors.dart';

class WeeklyCalendar extends StatefulWidget {
  final List<Event> events;
  const WeeklyCalendar({super.key, required this.events});

  @override
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  late DateTime _selectedDay;
  late LinkedHashMap<DateTime, List<Event>> _eventsByDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _eventsByDay = _groupEventsByDay(widget.events);
  }

  @override
  void didUpdateWidget(covariant WeeklyCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events != oldWidget.events) {
      _eventsByDay = _groupEventsByDay(widget.events);
    }
  }

  List<DateTime> _getWeekDays(DateTime date) {
    // Assuming Monday is the first day of the week
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  LinkedHashMap<DateTime, List<Event>> _groupEventsByDay(List<Event> events) {
    final map = LinkedHashMap<DateTime, List<Event>>(
      equals: (a, b) => a.year == b.year && a.month == b.month && a.day == b.day,
      hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
    );

    for (final event in events) {
      final localTime = tz.TZDateTime.from(event.timeBegin, tz.local);
      final dateOnly = DateTime(localTime.year, localTime.month, localTime.day);
      if (map[dateOnly] == null) {
        map[dateOnly] = [];
      }
      map[dateOnly]!.add(event);
    }
    return map;
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
    final events = _eventsByDay[day] ?? [];
    if (events.isNotEmpty) {
      _showEventsBottomSheet(context, day, events);
    }
  }

  void _showEventsBottomSheet(BuildContext context, DateTime day, List<Event> events) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Eventos para el ${day.day}/${day.month}/${day.year}',
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
    final weekDays = _getWeekDays(DateTime.now());
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final day = weekDays[index];
          final dayEvents = _eventsByDay[day] ?? [];
          final isSelected = day.year == _selectedDay.year && day.month == _selectedDay.month && day.day == _selectedDay.day;

          return GestureDetector(
            onTap: () => _onDaySelected(day),
            child: Card(
              color: isSelected ? kPrimaryColor : Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              child: SizedBox(
                width: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          DateFormat('EEE', 'es').format(day).toUpperCase(),
                          style: TextStyle(color: isSelected ? Colors.white : null),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.day.toString(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                    if (dayEvents.isNotEmpty)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: kSecondaryColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            dayEvents.length.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
