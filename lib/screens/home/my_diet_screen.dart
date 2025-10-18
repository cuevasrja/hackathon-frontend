import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/home/calendar_screen.dart';
import 'package:hackathon_frontend/widgets/daily_meal_plan.dart';

class MyDietScreen extends StatelessWidget {
  const MyDietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monday, May 1'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
          ),
        ],
      ),
      body: const DailyMealPlan(),
    );
  }
}
