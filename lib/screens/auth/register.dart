import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/auth/interests_selector_screen.dart';
import 'package:hackathon_frontend/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importamos el login.dart solo para usar las constantes de color
// (En un proyecto real, las constantes estarían en su propio archivo)
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _birthDateController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // Variables para manejar la visibilidad de las contraseñas
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;
  late AuthService _authService;
  String _selectedGender = 'MAN';
  DateTime? _selectedBirthDate;
  // File? _documentImage;
  // final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _birthDateController = TextEditingController();
    _cityController = TextEditingController();
    _countryController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Función para el botón de registro
  Future<void> _register() async {
    // Valida el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_birthDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona tu fecha de nacimiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.signup(
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        birthDate: _birthDateController.text,
        gender: _selectedGender,
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        //documentFrontImage: null,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(LoginStorageKeys.userId, response.user.id);
      await prefs.setString(LoginStorageKeys.token, response.token);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenido, ${response.user.name}!'),
          backgroundColor: kPrimaryColor,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const InterestSelectionScreen(),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado al registrar la cuenta'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _takeDocumentPhoto() async {
  //   final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
  //   if (picked != null) {
  //     setState(() {
  //       _documentImage = File(picked.path);
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // Usamos un AppBar simple para tener un botón de "atrás"
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. Logo ---
                  Image.asset('lib/assets/icon_logo_clear.png', height: 150),
                  const SizedBox(height: 16.0),
                  // --- 2. Campo de Nombre Completo ---
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    decoration: _buildInputDecoration(
                      hintText: 'Nombre',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: _lastNameController,
                    keyboardType: TextInputType.name,
                    decoration: _buildInputDecoration(
                      hintText: 'Apellido',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu apellido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

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
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return 'Por favor, ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: _birthDateController,
                    readOnly: true,
                    decoration: _buildInputDecoration(
                      hintText: 'Fecha de Nacimiento',
                      prefixIcon: Icons.cake_outlined,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedBirthDate ?? DateTime.now(),
                        firstDate: DateTime(1900, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedBirthDate = picked;
                          _birthDateController.text =
                              '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecciona tu fecha de nacimiento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: _buildInputDecoration(
                      hintText: 'Género',
                      prefixIcon: Icons.person_outline,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MAN', child: Text('Hombre')),
                      DropdownMenuItem(value: 'WOMAN', child: Text('Mujer')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Otro')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedGender = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: _cityController,
                    decoration: _buildInputDecoration(
                      hintText: 'Ciudad',
                      prefixIcon: Icons.location_city_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu ciudad';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: _countryController,
                    decoration: _buildInputDecoration(
                      hintText: 'País',
                      prefixIcon: Icons.flag_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu país';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
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
                        return 'Por favor, ingresa una contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // --- 5. Campo de Confirmar Contraseña ---
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _isConfirmPasswordObscured,
                    decoration: _buildInputDecoration(
                      hintText: 'Confirmar Contraseña',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kPrimaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordObscured =
                                !_isConfirmPasswordObscured;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirma tu contraseña';
                      }
                      // Compara con el valor del primer campo de contraseña
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),
                  // Document image picker
                  // const SizedBox(height: 12.0),
                  // _documentImage == null
                  //     ? const Text('Ninguna imagen de documento seleccionada.')
                  //     : Image.file(_documentImage!, height: 150),
                  // const SizedBox(height: 8.0),
                  // ElevatedButton.icon(
                  //   onPressed: _takeDocumentPhoto,
                  //   icon: const Icon(Icons.camera_alt),
                  //   label: const Text('Tomar foto del documento'),
                  // ),
                  const SizedBox(height: 24.0),

                  // --- Botón de Registrarse ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
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
                            'REGISTRARSE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16.0),

                  // --- 6. Volver a Iniciar Sesión ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes cuenta?',
                        style: TextStyle(color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: () {
                          // Simplemente regresa a la pantalla anterior (login)
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Inicia sesión',
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

  // Copiamos el mismo método helper para unificar estilos
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
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: kPrimaryColor, width: 2.0),
      ),
    );
  }
}
