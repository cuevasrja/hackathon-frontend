import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/meal_details_screen.dart';
import 'package:hackathon_frontend/models/meal_model.dart';

class MealListItem extends StatelessWidget {
  final Meal meal;

  const MealListItem({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealDetailsScreen(meal: meal),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListTile(
          leading: Image.asset(
            meal.imagePath,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
          title: Text(meal.name),
          subtitle: Text(meal.description),
          trailing: const Icon(Icons.favorite_border),
        ),
      ),
    );
  }
}
