import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/meal_model.dart';
import 'package:hackathon_frontend/services/meal_service.dart';
import 'package:hackathon_frontend/widgets/meal_list_item.dart';

class DailyMealPlan extends StatelessWidget {
  const DailyMealPlan({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Meal> meals = MealService.getMeals();

    return ListView.builder(
      itemCount: meals.length,
      itemBuilder: (context, index) {
        return MealListItem(meal: meals[index]);
      },
    );
  }
}
