import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/home_screen.dart';

import 'package:hackathon_frontend/utils/colors.dart';

import 'screens/auth/login.dart'; // Asegúrate de importar tu archivo login.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plancito',

      theme: ThemeData(
        primaryColor: kPrimaryColor,

        scaffoldBackgroundColor: kBackgroundColor,

        visualDensity: VisualDensity.adaptivePlatformDensity,

        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
      ),

      home: const HomeScreen(),
    );
  }
}
