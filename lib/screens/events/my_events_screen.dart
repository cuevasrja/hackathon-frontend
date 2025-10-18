import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/home/calendar_screen.dart';
import 'package:hackathon_frontend/services/event_service.dart';
import 'package:hackathon_frontend/models/event_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login.dart'; // Para usar las constantes de color
import 'create_events.dart';

// --- 2. Pantalla Principal "Mis Eventos" ---
class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final EventService _eventService = EventService();
  final ScrollController _scrollController = ScrollController();

  final List<Event> _organizedEvents = [];
  final List<Event> _attendingEvents = [];
  final List<Event> _pastEvents = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int? _currentUserId;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeUserAndLoadEvents();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserAndLoadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(LoginStorageKeys.userId);

      if (!mounted) return;

      if (userId == null) {
        setState(() {
          _errorMessage = 'No se pudo identificar al usuario autenticado.';
        });
        return;
      }

      setState(() {
        _currentUserId = userId;
      });

      await _loadEvents(reset: true);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error inesperado al cargar tus eventos.';
      });
    }
  }

  Future<void> _loadEvents({required bool reset}) async {
    if (_isLoading || _isLoadingMore || (!_hasMore && !reset)) {
      return;
    }

    setState(() {
      if (reset) {
        _isLoading = true;
        _errorMessage = null;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final pageToLoad = reset ? 1 : _currentPage + 1;
      print(reset ? 'Cargando eventos desde el inicio...' : 'Cargando más eventos, página $pageToLoad...');
      final response = await _eventService.fetchEvents(page: pageToLoad);

      print('Eventos cargados: ${response.events.length}');

      if (!mounted) return;

      print('Usuario actual ID: $_currentUserId');

      final now = DateTime.now();
      final newOrganized = <Event>[];
      final newAttending = <Event>[];
      final newPast = <Event>[];

      for (var event in response.events) {
        if (event.organizerId == _currentUserId) {
          newOrganized.add(event);
        } else if (event.timeBegin.isAfter(now)) {
          // Asumiendo que si no es el dueño y la fecha es futura, asiste
          newAttending.add(event);
        } else {
          newPast.add(event);
        }
      }

      setState(() {
        if (reset) {
          _organizedEvents
            ..clear()
            ..addAll(newOrganized);
          _attendingEvents
            ..clear()
            ..addAll(newAttending);
          _pastEvents
            ..clear()
            ..addAll(newPast);
        } else {
          _organizedEvents.addAll(newOrganized);
          _attendingEvents.addAll(newAttending);
          _pastEvents.addAll(newPast);
        }
        _currentPage = response.page;
        _hasMore = response.page < response.total;
      });
    } on EventException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('Error desconocido al cargar eventos ${e.toString()}');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error inesperado al cargar los eventos.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading &&
        !_isLoadingMore) {
      _loadEvents(reset: false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadEvents(reset: true);
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
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateEventScreen(),
              ),
            );
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
          onPressed: () => _loadEvents(reset: true),
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

  // --- Widget Helper para construir la lista de planes ---
  Widget _buildPlanList(List<Event> events, {bool isPast = false}) {
    if (events.isEmpty && !_isLoading) {
      return _buildEmptyState('Aún no tienes planes en esta sección.');
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: events.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= events.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final event = events[index];
        // Para el historial, aplicamos un filtro grisáceo
        return Opacity(
          opacity: isPast ? 0.7 : 1.0,
          child: _buildPlanCard(event),
        );
      },
    );
  }

  // --- Widget Helper para el diseño de cada tarjeta de plan ---
  Widget _buildPlanCard(Event event) {
    // Lista de meses para formatear la fecha
    const List<String> meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
  // Usar timeBegin del modelo Event (fecha y hora de inicio)
  final date = event.timeBegin;
  String formattedDate =
    '${date.day} de ${meses[date.month - 1]} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias, // Para que la imagen respete los bordes
      child: InkWell(
        onTap: () {
          // TODO: Navegar a la pantalla de detalle del plan
          print('Viendo detalles de: ${event.name}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Imagen del Plan ---
            Hero(
              // Para una animación bonita al abrir el detalle
              tag: event.name, // Un tag único, como el ID del plan
              child: Image.network(
                // Intentar usar la imagen del lugar, luego la URL externa, luego un placeholder
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
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 40,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Imagen no disponible',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // --- Información del Plan ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  // --- Fila de Fecha y Hora ---
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: kPrimaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // --- Fila de Ubicación ---
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: kPrimaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          // Mostrar la dirección del lugar si existe, si no mostrar el nombre del lugar o 'Ubicación no disponible'
                          event.place?.direction ?? event.place?.name ?? 'Ubicación no disponible',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  // --- Fila de Participantes ---
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        color: kPrimaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        '0 / ${event.place?.capacity ?? event.ticketCount?.tickets ?? 0} personas', // Assuming 0 participants for now
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      // Esto es un indicador visual (podría ser un avatar stack)
                      _buildParticipantIndicator(
                        0, // Assuming 0 participants for now
                        // Evitar división por cero: fallback a 1 si capacity es 0
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

  // Helper visual para la barra de participantes
  Widget _buildParticipantIndicator(int current, int max) {
    // Calcular ratio de forma segura para evitar NaN/infinite
    final safeMax = (max <= 0) ? 1 : max;
    double ratio = 0.0;
    try {
      ratio = (current / safeMax).toDouble();
    } catch (_) {
      ratio = 0.0;
    }
    if (!ratio.isFinite) ratio = 0.0;
    ratio = ratio.clamp(0.0, 1.0);
    final fillWidth = 80 * ratio;

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
          width: fillWidth,
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
