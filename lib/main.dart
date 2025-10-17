import 'package:flutter/material.dart';
import 'screens/auth/login.dart'; // Asegúrate de importar tu archivo login.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Puedes definir un tema global si quieres
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
      ),
      home: const LoginScreen(), // Inicia con tu pantalla de login
    );
  }
}
