import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/home/meal_details_screen.dart';
import 'package:hackathon_frontend/models/meal_model.dart';

class SmallEventCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onTap;

  const SmallEventCard({super.key, required this.meal, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MealDetailsScreen(meal: meal),
              ),
            );
          },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _MealImage(imagePath: meal.imagePath),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        meal.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                        meal.description,
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

class _MealImage extends StatelessWidget {
  const _MealImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return _placeholder();
    }

    final isNetworkImage = imagePath.startsWith('http');

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        height: 120,
        width: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return Image.asset(
      imagePath,
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
