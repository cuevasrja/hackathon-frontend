import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/event_model.dart';

class SmallEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const SmallEventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _EventImage(image: event?.image),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          event.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    // Log del valor de image para depuración
    developer.log('Valor de image en _EventImage: '
        '${image?.substring(0, image!.length > 100 ? 100 : image!.length)}',
        name: '_EventImage');
    if (image == null || image!.isEmpty) {
      return _defaultImage();
    }

    return Image.network(
      image!,
      height: 120,
      width: 150,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _defaultImage(),
    );
  }

  Widget _defaultImage() {
    return Image.asset(
      'lib/assets/icon_logo.jpg',
      height: 120,
      width: 150,
      fit: BoxFit.cover,
    );
  }
}
