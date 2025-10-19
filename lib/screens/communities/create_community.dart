import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/auth/login.dart'; // Para usar las constantes de color
import 'package:hackathon_frontend/services/communities_service.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores y variables de estado
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _rulesController;
  late CommunitiesService _communitiesService;

  String? _selectedCategory;
  bool _isPrivate = false;
  bool _imageSelected = false;
  bool _isSubmitting = false;
  String? _submitError;

  final List<String> _categories = [
    'Universidad',
    'Trabajo',
    'Deporte',
    'Gastronomía',
    'Arte y Cultura',
    'Música',
    'Gaming',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _rulesController = TextEditingController();
    _communitiesService = CommunitiesService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  // --- Lógica para "crear" la comunidad ---
  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final response =
          await _communitiesService.createCommunity(_nameController.text, _descriptionController.text);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: kPrimaryColor,
        ),
      );
      Navigator.of(context).pop(response.community);
    } on CommunitiesException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitError = e.message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitError = 'Ocurrió un error al crear la comunidad.';
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
          icon: Icon(Icons.close, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Crear Comunidad',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forma tu propio grupo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // --- Campo para Añadir Imagen ---
              GestureDetector(
                onTap: () {
                  // TODO: Lógica para abrir la galería de imágenes
                  setState(() {
                    _imageSelected = true;
                  });
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _imageSelected
                        ? kPrimaryColor.withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: _imageSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: kPrimaryColor,
                            size: 48,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: kPrimaryColor,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Añadir foto de la comunidad',
                                style: TextStyle(color: kPrimaryColor),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Nombre de la Comunidad ---
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(
                  hintText: 'Nombre de la comunidad',
                  icon: Icons.group_work_outlined,
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Categoría ---
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _buildInputDecoration(
                  hintText: 'Categoría',
                  icon: Icons.category_outlined,
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 16),

              // --- Descripción ---
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration(
                  hintText: 'Describe el propósito del grupo...',
                  icon: Icons.description_outlined,
                ),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty
                    ? 'La descripción es obligatoria'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Reglas (Opcional) ---
              TextFormField(
                controller: _rulesController,
                decoration: _buildInputDecoration(
                  hintText:
                      'Reglas (opcional)\nEj: Ser respetuoso, puntualidad...',
                  icon: Icons.rule_folder_outlined,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // --- Switch Público/Privado ---
              SwitchListTile(
                title: const Text('Comunidad Privada'),
                subtitle: const Text(
                  'Solo se podrá unir gente con invitación.',
                ),
                value: _isPrivate,
                onChanged: (bool value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
                activeColor: kPrimaryColor,
                secondary: Icon(
                  _isPrivate ? Icons.lock_outline : Icons.public,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 32),

              if (_submitError != null) ...[
                Text(
                  _submitError!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],

              // --- Botón de Crear Comunidad ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _createCommunity,
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
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'CREAR COMUNIDAD',
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para el estilo de los campos
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
