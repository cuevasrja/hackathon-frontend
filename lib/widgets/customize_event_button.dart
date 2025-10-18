import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/chatai/chatai_screen.dart';

class CustomizeEventButton extends StatelessWidget {
  const CustomizeEventButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIPlannerScreen()),
          );
        },
        child: const Text('Planear evento con PlanIA'),
      ),
    );
  }
}
