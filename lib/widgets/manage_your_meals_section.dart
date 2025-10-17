import 'package:flutter/material.dart';
import 'package:hackathon_frontend/widgets/weekly_calendar.dart';

class ManageYourMealsSection extends StatelessWidget {
  const ManageYourMealsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Manage your meals',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
          const WeeklyCalendar(),
        ],
      ),
    );
  }
}