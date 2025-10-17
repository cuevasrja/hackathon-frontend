import 'package:flutter/material.dart';

class CustomizeDietButton extends StatelessWidget {
  const CustomizeDietButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {},
        child: const Text('Customize diet'),
      ),
    );
  }
}
