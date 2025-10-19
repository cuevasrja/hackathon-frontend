import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/event_model.dart';

class SmallEventCard extends StatefulWidget {
  const SmallEventCard({super.key, required this.event, this.onTap});

  final Event event;
  final VoidCallback? onTap;

  @override
  State<SmallEventCard> createState() => _SmallEventCardState();
}

class _SmallEventCardState extends State<SmallEventCard>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final event = widget.event;

    return InkWell(
      onTap: widget.onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _EventImage(image: event.image),
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

  @override
  bool get wantKeepAlive => true;
}

class _EventImage extends StatefulWidget {
  const _EventImage({this.image});

  final String? image;

  @override
  State<_EventImage> createState() => _EventImageState();
}

class _EventImageState extends State<_EventImage>
    with AutomaticKeepAliveClientMixin {
  CachedNetworkImageProvider? _provider;

  @override
  void initState() {
    super.initState();
    _updateProvider();
  }

  @override
  void didUpdateWidget(covariant _EventImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _updateProvider();
    }
  }

  void _updateProvider() {
    final url = widget.image;
    if (url != null && url.isNotEmpty) {
      _provider = CachedNetworkImageProvider(url);
    } else {
      _provider = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_provider == null) {
      return _defaultImage();
    }

    return Image(
      image: _provider!,
      height: 120,
      width: 150,
      fit: BoxFit.cover,
      gaplessPlayback: true,
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

  @override
  bool get wantKeepAlive => true;
}
