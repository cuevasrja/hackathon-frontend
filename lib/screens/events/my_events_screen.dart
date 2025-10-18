import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/event_response_model.dart';
import 'package:hackathon_frontend/screens/home/calendar_screen.dart';
import 'package:hackathon_frontend/services/event_service.dart';
import 'package:hackathon_frontend/models/event_model.dart';
import '../auth/login.dart'; // Para usar las constantes de color
import 'create_events.dart';
import 'event_detail.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final EventService _eventService = EventService();

  final List<Event> _organizedEvents = [];
  final List<Event> _attendingEvents = [];
  final List<Event> _pastEvents = [];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch organized and joined events in parallel for efficiency
      final results = await Future.wait([
        _eventService.fetchOrganizedEvents(),
        _eventService.fetchJoinedEvents(),
      ]);

      final allOrganized = results[0] as List<Event>;
      final allJoined = results[1] as List<MyEvent>;

      if (!mounted) return;

      final now = DateTime.now();
      final newOrganized = <Event>[];
      final newAttending = <Event>[];
      final newPast = <Event>[];

      // Process organized events
      for (final event in allOrganized) {
        if (event.timeEnd.isAfter(now)) {
          newOrganized.add(event);
        } else {
          newPast.add(event);
        }
      }

      // Process joined events
      for (final joined in allJoined) {
        final event = joined.event;

        if (event.timeEnd.isAfter(now)) {
          newAttending.add(event);
        } else {
          // Only add to past if it wasn't already added from the organized list
          if (!newPast.any((e) => e.id == event.id)) {
            newPast.add(event);
          }
        }
      }

      // Sort events within each list by their start time
      newOrganized.sort((a, b) => a.timeBegin.compareTo(b.timeBegin));
      newAttending.sort((a, b) => a.timeBegin.compareTo(b.timeBegin));
      newPast.sort((a, b) => b.timeBegin.compareTo(a.timeBegin)); // Past events ascending

      setState(() {
        _organizedEvents.clear();
        _organizedEvents.addAll(newOrganized);

        _attendingEvents.clear();
        _attendingEvents.addAll(newAttending);

        _pastEvents.clear();
        _pastEvents.addAll(newPast);
      });
    } on EventException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error inesperado al cargar los eventos.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 3 Pestañas
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            'Mis Planes',
            style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today, color: kPrimaryColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarScreen()),
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: kPrimaryColor,
            labelColor: kPrimaryColor,
            unselectedLabelColor: Colors.grey[500],
            tabs: const [
              Tab(text: 'Yo Organizo'),
              Tab(text: 'Asistiré'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: kPrimaryColor,
          child: _buildBody(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final created = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => const CreateEventScreen(),
              ),
            );
            if (created == true) {
              await _loadEvents();
            }
          },
          backgroundColor: kPrimaryColor,
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Crear Nuevo Plan',
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _organizedEvents.isEmpty && _attendingEvents.isEmpty && _pastEvents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _organizedEvents.isEmpty && _attendingEvents.isEmpty && _pastEvents.isEmpty) {
      return _buildErrorState();
    }

    return TabBarView(
      children: [
        _buildPlanList(_organizedEvents),
        _buildPlanList(_attendingEvents),
        _buildPlanList(_pastEvents, isPast: true),
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.redAccent.shade200),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Error al cargar los eventos.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loadEvents,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reintentar'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.sentiment_dissatisfied, size: 48, color: kPrimaryColor),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildPlanList(List<Event> events, {bool isPast = false}) {
    if (events.isEmpty && !_isLoading) {
      return _buildEmptyState('Aún no tienes planes en esta sección.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Opacity(
          opacity: isPast ? 0.7 : 1.0,
          child: _buildPlanCard(event),
        );
      },
    );
  }

  Widget _buildPlanCard(Event event) {
    const List<String> meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    final date = event.timeBegin;
    String formattedDate = '${date.day} de ${meses[date.month - 1]} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(event: event),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'event-hero-${event.id}',
              child: Image.network(
                event.place?.image ?? event.externalUrl ?? 'https://via.placeholder.com/300x150/CCCCCC/FFFFFF?text=No+Image',
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Imagen no disponible', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: kPrimaryColor, size: 16),
                      const SizedBox(width: 8.0),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: kPrimaryColor, size: 16),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          event.place?.direction ?? event.place?.name ?? 'Ubicación no disponible',
                          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      const Icon(Icons.group_outlined, color: kPrimaryColor, size: 20),
                      const SizedBox(width: 8.0),
                      Text(
                        '0 / ${event.place?.capacity ?? event.ticketCount?.tickets ?? 0} personas',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                      ),
                      const Spacer(),
                      _buildParticipantIndicator(
                        0,
                        (event.place?.capacity ?? event.ticketCount?.tickets ?? 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantIndicator(int current, int max) {
    final safeMax = (max <= 0) ? 1 : max;
    double ratio = (current / safeMax).clamp(0.0, 1.0);

    return Stack(
      children: [
        Container(
          width: 80,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80 * ratio,
          height: 8,
          decoration: BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}