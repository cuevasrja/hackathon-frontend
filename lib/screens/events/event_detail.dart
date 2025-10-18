import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/event_model.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatelessWidget {
  const EventDetailsScreen({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final place = event.place;
    final organizer = event.organizer;
    final formattedDate = _formatDate(event.timeBegin);
    final formattedTime = _formatTime(event.timeBegin);
    final imageUrl =
        place?.image ??
        event.externalUrl ??
        'https://via.placeholder.com/500x300/CCCCCC/FFFFFF?text=Sin+imagen';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        elevation: 0,
        title: const Text(
          'Detalle del Plan',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'event-hero-${event.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: double.infinity,
                    height: 220,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.image_not_supported_outlined, size: 40),
                        SizedBox(height: 8),
                        Text('Imagen no disponible'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              event.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.calendar_today_outlined, label: formattedDate),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.access_time_outlined, label: formattedTime),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: place?.direction ?? place?.name ?? 'Sin ubicación',
              trailing: TextButton.icon(
                onPressed: () async {
                  // 1. Define el esquema de URL para la app
                  // (Este es un esquema común, podría ser 'yummy://' o 'yummyrides://')
                  final platform = Theme.of(context).platform;

                  // 2. Define las URL de fallback (la tienda de apps)
                  final String storeUrl;
                  if (platform == TargetPlatform.android) {
                    // ID del paquete de Yummy Rides en Google Play
                    storeUrl =
                        'https://play.google.com/store/apps/details?id=com.yummyrides';
                  } else if (platform == TargetPlatform.iOS) {
                    // ID de la app en la App Store
                    storeUrl = 'https://apps.apple.com/app/id1522818234';
                  } else {
                    // Fallback genérico para otras plataformas (web, etc.)
                    storeUrl = 'https://www.yummysuperapp.com/rides';
                  }
                  final fallbackUri = Uri.parse(storeUrl);

                  // 3. Intenta abrir la app
                  try {
                    bool opened = false;

                    if (platform == TargetPlatform.android) {
                      final appUri = Uri.parse('yummyrides://rides');
                      opened = await launchUrl(
                        appUri,
                        mode: LaunchMode.externalNonBrowserApplication,
                      );

                      if (!opened) {
                        final intentUri = Uri.parse(
                          'intent://rides#Intent;scheme=yummyrides;package=com.yummyrides;end',
                        );
                        opened = await launchUrl(
                          intentUri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    } else if (platform == TargetPlatform.iOS) {
                      final appUri = Uri.parse('yummyrides://rides');
                      opened = await launchUrl(
                        appUri,
                        mode: LaunchMode.externalNonBrowserApplication,
                      );
                    }

                    if (!opened) {
                      opened = await launchUrl(
                        fallbackUri,
                        mode: LaunchMode.externalApplication,
                      );
                    }

                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo abrir el enlace'),
                        ),
                      );
                    }
                  } catch (e) {
                    // Si hay una excepción (raro, pero posible), lanza el fallback
                    final opened = await launchUrl(
                      fallbackUri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo abrir el enlace'),
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
                icon: const Icon(Icons.directions_car_outlined, size: 18),
                label: const Text('Cómo llegar'),
              ),
            ),
            const SizedBox(height: 20),
            if (organizer != null)
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage:
                        organizer.image != null && organizer.image!.isNotEmpty
                        ? NetworkImage(organizer.image!) as ImageProvider
                        : const NetworkImage(
                            'https://i.pravatar.cc/150?img=47',
                          ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organizado por',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '${organizer.name} ${organizer.lastName}'.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 24),
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _CapacitySection(event: event),
          ],
        ),
      ),
      bottomNavigationBar: _ActionSection(event: event),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute hrs';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.trailing});

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _CapacitySection extends StatelessWidget {
  const _CapacitySection({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final totalCapacity =
        event.place?.capacity ?? event.ticketCount?.tickets ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cupo disponible',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Capacidad total: $totalCapacity personas',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            _CapacityBar(
              current: 0,
              max: totalCapacity > 0 ? totalCapacity : 1,
            ),
          ],
        ),
      ],
    );
  }
}

class _CapacityBar extends StatelessWidget {
  const _CapacityBar({required this.current, required this.max});

  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final safeMax = max <= 0 ? 1 : max;
    final ratio = (current / safeMax).clamp(0.0, 1.0);
    const totalWidth = 90.0;

    return SizedBox(
      width: totalWidth,
      child: Stack(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 8,
            width: totalWidth * ratio,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20).copyWith(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad en desarrollo'),
                  backgroundColor: kPrimaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Unirme al plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
