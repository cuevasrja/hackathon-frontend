import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/event_model.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEE, d MMM · hh:mm a', 'es');
    final dateLabel = formatter.format(event.timeBegin);
    final placeName = event.place?.name ?? 'Lugar por confirmar';

    return Container(
      width: 260,
      margin: const EdgeInsets.only(left: 16.0, right: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EventImage(event: event),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          placeName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (event.community?.name != null &&
                      event.community!.name.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: [
                          const Icon(Icons.groups_outlined, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event.community!.name,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.place?.image;

    return Container(
      height: 140,
      color: Colors.grey[200],
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(),
              errorWidget: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(
        Icons.event_outlined,
        size: 48,
        color: Colors.grey,
      ),
    );
  }
}
