import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:hackathon_frontend/screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  try{
    if (kIsWeb) {
      await dotenv.load();
    } else {
      await dotenv.load(fileName: '.env');
    }
  } catch(e){
    debugPrint('Error loading .env file: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _hasSessionFuture;

  @override
  void initState() {
    super.initState();
    _hasSessionFuture = _hasStoredToken();
  }

  Future<bool> _hasStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return token != null && token.isNotEmpty;
  }

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

      home: FutureBuilder<bool>(
        future: _hasSessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final hasToken = snapshot.data ?? false;
          return hasToken ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
