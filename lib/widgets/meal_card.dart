import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/home/meal_details_screen.dart';
import 'package:hackathon_frontend/models/meal_model.dart';

class MealCard extends StatelessWidget {
  final Meal meal;

  const MealCard({super.key, required this.meal});

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
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Image.asset(
                meal.imagePath,
                height: 120,
                width: 150,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      meal.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(meal.description),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
