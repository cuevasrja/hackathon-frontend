import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
//import 'package:hackathon_frontend/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
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
        primaryColor: Color(0xFF4BBAC3),

        scaffoldBackgroundColor: Color(0xFFF5F4EF),

        visualDensity: VisualDensity.adaptivePlatformDensity,

        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF4BBAC3)),
      ),

      home: const LoginScreen(),
    );
  }
}
