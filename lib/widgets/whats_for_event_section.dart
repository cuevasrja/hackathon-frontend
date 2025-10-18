import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/meal_model.dart';
import 'package:hackathon_frontend/services/meal_service.dart';
import 'package:hackathon_frontend/widgets/meal_card.dart';

class WhatsForEventSection extends StatelessWidget {
  const WhatsForEventSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Meal> meals = MealService.getMeals();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '¿Qué plancito quieres hoy?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            itemBuilder: (context, index) {
              return MealCard(meal: meals[index]);
            },
          ),
        ),
      ],
    );
  }
}
