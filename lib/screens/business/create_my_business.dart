import 'package:flutter/material.dart';
import 'package:hackathon_frontend/services/places_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login.dart'; // Para las constantes de color

class CreateBusinessScreen extends StatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  State<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends State<CreateBusinessScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para cada campo del formulario
  final _nameController = TextEditingController();
  final _directionController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _capacityController = TextEditingController();
  final _mapUrlController = TextEditingController();
  final _imageController = TextEditingController(); // Para la URL de la imagen

  String? _selectedType;
  bool _isSubmitting = false;

  final PlacesService _placesService = PlacesService();

  final List<String> _businessTypes = [
    'Club',
    'Restaurante',
    'Bar',
    'Teatro',
    'Cine',
    'Gimnasio',
    'Café',
    'Otro',
  ];

  @override
  void dispose() {
    // Limpiamos los controllers para liberar memoria
    _nameController.dispose();
    _directionController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _capacityController.dispose();
    _mapUrlController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  // --- Lógica para enviar los datos al backend ---
  Future<void> _submitBusiness() async {
    if (_isSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final selectedType = _selectedType;
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un tipo de negocio.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final proprietorId = prefs.getInt(LoginStorageKeys.userId);

      if (proprietorId == null) {
        throw PlacesException('No se encontró el usuario autenticado.');
      }

      final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;

      final response = await _placesService.createPlace(
        name: _nameController.text.trim(),
        direction: _directionController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        capacity: capacity,
        type: selectedType,
        proprietorId: proprietorId,
        mapUrl: _mapUrlController.text.trim(),
        image: _imageController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: kPrimaryColor,
        ),
      );

      Navigator.of(context).pop(true);
    } on PlacesException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Ocurrió un error inesperado al registrar el negocio.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
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
          icon: const Icon(Icons.close, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Registrar Nuevo Negocio',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Título y Campos Principales ---
              _buildSectionTitle('Información Principal'),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(
                  hintText: 'Nombre del negocio',
                  icon: Icons.storefront_outlined,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: _buildInputDecoration(
                  hintText: 'Tipo de negocio',
                  icon: Icons.category_outlined,
                ),
                items: _businessTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (value) =>
                    value == null ? 'Selecciona un tipo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: _buildInputDecoration(
                  hintText: 'Capacidad (personas)',
                  icon: Icons.group_outlined,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La capacidad es requerida';
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un número mayor a cero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Ubicación ---
              _buildSectionTitle('Ubicación'),
              TextFormField(
                controller: _directionController,
                decoration: _buildInputDecoration(
                  hintText: 'Dirección',
                  icon: Icons.signpost_outlined,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'La dirección es obligatoria' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: _buildInputDecoration(
                        hintText: 'Ciudad',
                        icon: Icons.location_city_outlined,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'La ciudad es obligatoria' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: _buildInputDecoration(
                        hintText: 'País',
                        icon: Icons.flag_outlined,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'El país es obligatorio' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mapUrlController,
                decoration: _buildInputDecoration(
                  hintText: 'URL de Google Maps',
                  icon: Icons.map_outlined,
                ),
                keyboardType: TextInputType.url,
                validator: (value) =>
                    value!.isEmpty ? 'La URL del mapa es requerida' : null,
              ),
              const SizedBox(height: 24),

              // --- Imagen ---
              _buildSectionTitle('Imagen del Negocio'),
              TextFormField(
                controller: _imageController,
                decoration: _buildInputDecoration(
                  hintText: 'URL de la imagen principal',
                  icon: Icons.image_outlined,
                ),
                keyboardType: TextInputType.url,
                validator: (value) =>
                    value!.isEmpty ? 'La URL de la imagen es requerida' : null,
              ),
              const SizedBox(height: 32),

              // --- Botón de Envío ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBusiness,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'REGISTRAR NEGOCIO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Helpers ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: kPrimaryColor.withOpacity(0.7)),
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
