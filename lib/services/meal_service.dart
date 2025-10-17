import 'package:hackathon_frontend/models/meal_model.dart';

class MealService {
  static List<Meal> getMeals() {
    return [
      Meal(
        name: 'Carb smart Cobb salad',
        description: 'Cobb salad',
        imagePath: 'lib/assets/plancito.jpg',
      ),
      Meal(
        name: 'Smart Merguez',
        description: 'Inspired Beef Patties',
        imagePath: 'lib/assets/plancito_rec.jpg',
      ),
    ];
  }
}
