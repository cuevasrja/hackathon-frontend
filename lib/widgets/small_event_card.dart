import 'dart:convert';
import 'dart:typed_data';

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
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _EventImage(image: event.image),
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
    if (image == null || image!.isEmpty) {
      return _placeholder();
    }

    if (image!.startsWith('http')) {
      return Image.network(
        image!,
        height: 120,
        width: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    try {
      final UriData? data = Uri.tryParse(image!)?.data;
      Uint8List? bytes;

      if (data != null) {
        bytes = data.contentAsBytes();
      } else {
        bytes = base64Decode(image!);
      }

      if (bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          height: 120,
          width: 150,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    } catch (e) {
      // Not a valid base64 string or URI
    }

    return Image.asset(
      image!,
      height: 120,
      width: 150,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 120,
      width: 150,
      color: Colors.grey[200],
      child: const Icon(
        Icons.event_outlined,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
}
