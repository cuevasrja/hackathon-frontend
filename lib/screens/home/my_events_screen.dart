import 'package:flutter/material.dart';
import '../auth/login.dart'; // Para usar las constantes de color

// --- 1. Modelo de Datos para un Plan/Evento ---
class Plan {
  final String title;
  final String imageUrl;
  final DateTime date;
  final String location;
  final int participantCount;
  final int maxParticipants;

  Plan({
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.location,
    required this.participantCount,
    required this.maxParticipants,
  });
}

// --- 2. Pantalla Principal "Mis Eventos" ---
class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  // --- Datos de Ejemplo (en un app real vendrían de una base de datos) ---
  final List<Plan> _organizedPlans = [
    Plan(
      title: 'Hiking al Pico Naiguatá',
      imageUrl:
          'https://via.placeholder.com/300x150/2E8B57/FFFFFF?text=El+Avila',
      date: DateTime.now().add(const Duration(days: 3, hours: 2)),
      location: 'Parque Nacional El Ávila',
      participantCount: 8,
      maxParticipants: 10,
    ),
  ];

  final List<Plan> _attendingPlans = [
    Plan(
      title: 'Noche de Cine (Estreno)',
      imageUrl: 'https://via.placeholder.com/300x150/4682B4/FFFFFF?text=Cine',
      date: DateTime.now().add(const Duration(days: 1, hours: 4)),
      location: 'Cines Unidos - Sambil Ccs',
      participantCount: 4,
      maxParticipants: 6,
    ),
    Plan(
      title: 'Brunch y Mimosas',
      imageUrl:
          'https://via.placeholder.com/300x150/FF6347/FFFFFF?text=Restaurante',
      date: DateTime.now().add(const Duration(days: 4, hours: 6)),
      location: 'Rest. Mokambo, Las Mercedes',
      participantCount: 5,
      maxParticipants: 8,
    ),
  ];

  final List<Plan> _pastPlans = [
    Plan(
      title: 'Escape Room "El Secuestro"',
      imageUrl:
          'https://via.placeholder.com/300x150/696969/FFFFFF?text=Escape+Room',
      date: DateTime.now().subtract(const Duration(days: 7)),
      location: 'Escape Room Vzla, CCCT',
      participantCount: 6,
      maxParticipants: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 3 Pestañas
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: kPrimaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Mis Planes',
            style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
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
        body: TabBarView(
          children: [
            // Contenido de "Yo Organizo"
            _buildPlanList(_organizedPlans),
            // Contenido de "Asistiré"
            _buildPlanList(_attendingPlans),
            // Contenido de "Historial"
            _buildPlanList(_pastPlans, isPast: true),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Lógica para navegar a la pantalla de "Crear Plan"
            print('Crear nuevo plan');
          },
          backgroundColor: kPrimaryColor,
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Crear Nuevo Plan',
        ),
      ),
    );
  }

  // --- Widget Helper para construir la lista de planes ---
  Widget _buildPlanList(List<Plan> plans, {bool isPast = false}) {
    if (plans.isEmpty) {
      return Center(
        child: Text(
          'Aún no tienes planes en esta sección.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        // Para el historial, aplicamos un filtro grisáceo
        return Opacity(
          opacity: isPast ? 0.7 : 1.0,
          child: _buildPlanCard(plan),
        );
      },
    );
  }

  // --- Widget Helper para el diseño de cada tarjeta de plan ---
  Widget _buildPlanCard(Plan plan) {
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
    String formattedDate =
        '${plan.date.day} de ${meses[plan.date.month - 1]} - ${plan.date.hour}:${plan.date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias, // Para que la imagen respete los bordes
      child: InkWell(
        onTap: () {
          // TODO: Navegar a la pantalla de detalle del plan
          print('Viendo detalles de: ${plan.title}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Imagen del Plan ---
            Hero(
              // Para una animación bonita al abrir el detalle
              tag: plan.title, // Un tag único, como el ID del plan
              child: Image.network(
                plan.imageUrl,
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
                        Icon(Icons.image_not_supported_outlined,
                            size: 40, color: Colors.grey),
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
                    plan.title,
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
                          plan.location,
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
                        '${plan.participantCount} / ${plan.maxParticipants} personas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      // Esto es un indicador visual (podría ser un avatar stack)
                      _buildParticipantIndicator(
                        plan.participantCount,
                        plan.maxParticipants,
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
        Container(
          width: 80 * (current / max), // Ancho proporcional
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
