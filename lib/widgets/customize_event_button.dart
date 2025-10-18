import 'package:flutter/material.dart';

class CustomizeEventButton extends StatelessWidget {
  const CustomizeEventButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {},
        child: const Text('Planear evento'),
      ),
    );
  }
}