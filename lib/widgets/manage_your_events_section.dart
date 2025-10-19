import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hackathon_frontend/services/places_service.dart';

class ManageYourEventsSection extends StatefulWidget {
  const ManageYourEventsSection({super.key});

  @override
  State<ManageYourEventsSection> createState() =>
      _ManageYourEventsSectionState();
}

class _ManageYourEventsSectionState extends State<ManageYourEventsSection> {
  final PlacesService _placesService = PlacesService();
  late final Future<List<PlaceSummary>> _placesFuture = _fetchPlaces();

  Future<List<PlaceSummary>> _fetchPlaces() async {
    final response = await _placesService.fetchPlaces(page: 1, limit: 10);
    return response.places;
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
                'Lugares recomendados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: FutureBuilder<List<PlaceSummary>>(
            future: _placesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('No se pudieron cargar los lugares.'),
                );
              }

              final places = snapshot.data ?? const [];

              if (places.isEmpty) {
                return const Center(
                  child: Text('No hay lugares disponibles por ahora.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                scrollDirection: Axis.horizontal,
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return _SmallPlaceCard(place: place);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SmallPlaceCard extends StatelessWidget {
  const _SmallPlaceCard({required this.place});

  final PlaceSummary place;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _PlaceImage(imageUrl: place.imageUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.type.isNotEmpty ? place.type : 'Sin categoría',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${place.city}, ${place.country}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceImage extends StatelessWidget {
  const _PlaceImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.store_mall_directory,
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
        );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        height: 120,
        width: double.infinity,
        color: Colors.grey[200],
      ),
      errorWidget: (_, __, ___) => placeholder(),
    );
  }
}
