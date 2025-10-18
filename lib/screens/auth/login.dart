import 'package:flutter/material.dart';
import 'register.dart';
import 'forgot_password.dart';
import '../home/home_screen.dart';
import 'package:hackathon_frontend/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Definimos tus colores principales para usarlos fácilmente
const Color kPrimaryColor = Color(0xFF4BBAC3);
const Color kBackgroundColor = Color(0xFFF5F4EF);

class LoginStorageKeys {
  static const userId = 'userId';
  static const token = 'authToken';
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Clave para manejar el estado del formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  // Variable para manejar la visibilidad de la contraseña
  bool _isPasswordObscured = true;

  late bool _isLoading;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _isLoading = false;
    _authService = AuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función para el botón de login
  Future<void> _login() async {
    // Primero, valida el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Si es válido, obtén los datos
    String email = _emailController.text;
    String password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final authResponse = await _authService.login(
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(LoginStorageKeys.userId, authResponse.user.id);
      await prefs.setString(LoginStorageKeys.token, authResponse.token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, ${authResponse.user.name}!'),
          backgroundColor: kPrimaryColor,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado al iniciar sesión'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Permite hacer scroll si el teclado cubre los campos
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. Logo ---
                  // Usamos un ícono como placeholder para el logo
                  Image.asset(
                    'lib/assets/plancito_rec-removebg-preview.png',
                    height: 150,
                  ),
                  const SizedBox(height: 48.0),

                  // --- 2. Campo de Email ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(
                      hintText: 'Correo Electrónico',
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu correo';
                      }
                      // Validación simple de email
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return 'Por favor, ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // --- 3. Campo de Contraseña ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscured, // Ocultar contraseña
                    decoration: _buildInputDecoration(
                      hintText: 'Contraseña',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kPrimaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // --- 4. Olvidaste tu contraseña ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Navegamos a la pantalla de recuperar contraseña
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: kPrimaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // --- Botón de Login ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white, // Color del texto
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'INGRESAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16.0),

                  // --- 5. Crear Cuenta ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta?',
                        style: TextStyle(color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navegamos a la pantalla de registro
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Crear',
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Método helper para unificar el estilo de los InputDecoration
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: kPrimaryColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 16.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none, // Sin borde por defecto
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: Colors.grey[300]!, // Borde sutil cuando no está enfocado
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: kPrimaryColor, // Borde de color primario al enfocar
          width: 2.0,
        ),
      ),
    );
  }
}
