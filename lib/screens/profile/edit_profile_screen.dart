import 'package:flutter/material.dart';
import '../auth/login.dart'; // Importamos para usar las constantes de color
import 'package:hackathon_frontend/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  // Recibimos los datos actuales para pre-rellenar los campos
  final String currentName;
  final String currentLastName;
  final String currentUserEmail;
  final String currentProfileImageUrl;
  final String currentCity;
  final int userId;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentUserEmail,
    required this.currentProfileImageUrl,
    required this.currentCity,
    required this.currentLastName,
    required this.userId,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _cityController;
  bool _isSaving = false;
  String? _errorMessage;
  late ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    // Inicializamos los controllers con los datos actuales
    _nameController = TextEditingController(text: widget.currentName);
    _lastNameController = TextEditingController(text: widget.currentLastName);
    _cityController = TextEditingController(text: widget.currentCity);
    _profileService = ProfileService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // --- Lógica para guardar los cambios ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _profileService.updateUser(
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        city: _cityController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado con éxito.'),
          backgroundColor: kPrimaryColor,
        ),
      );

      Navigator.of(context).pop(true);
    } on ProfileException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error inesperado al actualizar el perfil.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Botón de Guardar en la AppBar
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    ),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              // --- Sección de Foto de Perfil ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(
                        widget.currentProfileImageUrl,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Lógica para seleccionar una nueva imagen
                          print('Cambiar imagen de perfil');
                        },
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: kPrimaryColor,
                          child: Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Campos del Formulario ---
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(
                  labelText: 'Nombre',
                  icon: Icons.person_outline,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'El nombre no puede estar vacío' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: _buildInputDecoration(
                  labelText: 'Apellido',
                  icon: Icons.person,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'El apellido no puede estar vacío' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: _buildInputDecoration(
                  labelText: 'Ciudad',
                  icon: Icons.location_city,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'La ciudad no puede estar vacía' : null,
              ),
              const SizedBox(height: 16),
              // --- Correo (no editable) ---
              TextFormField(
                initialValue: widget.currentUserEmail,
                decoration: _buildInputDecoration(
                  labelText: 'Correo Electrónico',
                  icon: Icons.email_outlined,
                ),
                readOnly: true, // El usuario no puede cambiar esto
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: kPrimaryColor.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white,
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
