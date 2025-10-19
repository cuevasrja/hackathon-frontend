import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/category_model.dart';
import 'package:hackathon_frontend/services/category_service.dart';
import '../auth/login.dart';
import 'package:hackathon_frontend/services/event_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:hackathon_frontend/services/communities_service.dart';
import 'package:hackathon_frontend/services/places_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _participantsController;
  late TextEditingController _minAgeController;
  late TextEditingController _externalUrlController;

  DateTime? _selectedDate;
  int? _selectedCategoryId;
  bool _isPrivate = false;
  bool _submitting = false;
  bool _imageSelected = false;
  bool _processingImage = false;
  File? _selectedImageFile;
  Uint8List? _previewBytes;
  final ImagePicker _imagePicker = ImagePicker();

  List<CommunitySummary> _communities = [];
  int? _selectedCommunityId;
  List<PlaceSummary> _places = [];
  int? _selectedPlaceId;
  bool _loadingPlaces = true;

  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _participantsController = TextEditingController();
    _minAgeController = TextEditingController();
    _externalUrlController = TextEditingController();
    _loadInitialData();
  }

  void _loadInitialData() {
    _loadCommunities();
    _loadPlaces();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _participantsController.dispose();
    _minAgeController.dispose();
    _externalUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
      });
    }
  }

  Future<void> _loadCommunities() async {
    try {
      final list = await CommunitiesService().fetchCommunities();
      if (!mounted) return;
      setState(() {
        _communities = list;
      });
    } catch (_) {}
  }

  Future<void> _loadPlaces() async {
    try {
      setState(() {
        _loadingPlaces = true;
      });
      final response = await PlacesService().fetchPlaces(limit: 50);
      if (!mounted) return;
      setState(() {
        _places = response.places;
        if (_places.isNotEmpty) {
          _selectedPlaceId = _selectedPlaceId ?? _places.first.id;
          _locationController.text = _places
              .firstWhere(
                (place) => place.id == _selectedPlaceId,
                orElse: () => _places.first,
              )
              .direction;
        } else {
          _selectedPlaceId = null;
          _locationController.text = '';
        }
        _loadingPlaces = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPlaces = false;
      });
    }
  }

  Future<void> _createPlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una fecha y hora')),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una categoría')),
      );
      return;
    }
    if (!_isPrivate && _selectedCommunityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una comunidad para planes públicos'),
        ),
      );
      return;
    }
    if (_selectedPlaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un lugar para el evento')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final minAge = _minAgeController.text.trim().isEmpty
          ? null
          : int.tryParse(_minAgeController.text.trim());

      await EventService().createEvent(
        name: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        timeBegin: _selectedDate!,
        placeId: _selectedPlaceId!,
        categoryId: _selectedCategoryId, // Pass the selected category ID

        minAge: minAge,
        visibility: _isPrivate ? 'PRIVATE' : 'PUBLIC',
        communityId: _selectedCommunityId,
        externalUrl: _externalUrlController.text.trim().isEmpty
            ? null
            : _externalUrlController.text.trim(),
        imageFile: _selectedImageFile,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tu plancito ha sido creado con éxito!'),
          backgroundColor: kPrimaryColor,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (!mounted) return;
      setState(() {
        _submitting = false;
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
          'Crear Nuevo Plan',
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
                'Dale vida a tu idea',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _processingImage ? null : _handleImageSelection,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _imageSelected
                        ? kPrimaryColor.withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kPrimaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: _processingImage
                        ? const CircularProgressIndicator()
                        : _imageSelected && _selectedImageFile != null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 90,
                                    child: _previewBytes != null
                                        ? Image.memory(
                                            _previewBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            _selectedImageFile!,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _clearSelectedImage,
                                    child: const Text(
                                      'Eliminar imagen',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    color: kPrimaryColor,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _processingImage
                                        ? 'Procesando imagen...'
                                        : 'Añadir foto del plan',
                                    style: const TextStyle(color: kPrimaryColor),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: _buildInputDecoration(
                  hintText: 'Título del plan',
                  icon: Icons.title,
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'El título es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration(
                  hintText: 'Describe tu plan...',
                  icon: Icons.description_outlined,
                ),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty
                    ? 'La descripción es obligatoria'
                    : null,
              ),
              const SizedBox(height: 16),
              if (_loadingCategories)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: _buildInputDecoration(
                    hintText: 'Categoría',
                    icon: Icons.category_outlined,
                  ),
                  items: _categories.map((Category category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategoryId = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona una categoría' : null,
                ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: _buildInputDecoration(
                    hintText: 'Fecha y Hora',
                    icon: Icons.calendar_today_outlined,
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Toca para seleccionar'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} - ${_selectedDate!.hour}:${_selectedDate!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Colors.grey[600]
                          : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCommunityId,
                decoration: _buildInputDecoration(
                  hintText: 'Comunidad',
                  icon: Icons.groups_outlined,
                ),
                items: _communities
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedCommunityId = v;
                  });
                },
                validator: (value) {
                  if (!_isPrivate && (value == null)) {
                    return 'Selecciona una comunidad';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_loadingPlaces)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              else if (_places.isEmpty)
                InputDecorator(
                  decoration: _buildInputDecoration(
                    hintText: 'Lugar del evento',
                    icon: Icons.place_outlined,
                  ),
                  child: const Text(
                    'No hay lugares disponibles',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  value: _selectedPlaceId,
                  decoration: _buildInputDecoration(
                    hintText: 'Lugar del evento',
                    icon: Icons.place_outlined,
                  ),
                  items: _places
                      .map(
                        (p) => DropdownMenuItem<int>(
                          value: p.id,
                          child: Text(p.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedPlaceId = v;
                      final matchingPlace = _places.firstWhere(
                        (place) => place.id == v,
                        orElse: () => _places.first,
                      );
                      _locationController.text = matchingPlace.direction;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona un lugar' : null,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: _buildInputDecoration(
                        hintText: 'Lugar',
                        icon: Icons.location_on_outlined,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Define un lugar'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _participantsController,
                      decoration: _buildInputDecoration(
                        hintText: 'Cupos',
                        icon: Icons.group_outlined,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Cupos?' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minAgeController,
                decoration: _buildInputDecoration(
                  hintText: 'Edad mínima (opcional)',
                  icon: Icons.cake_outlined,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final v = int.tryParse(value.trim());
                    if (v == null || v < 0) return 'Número inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _externalUrlController,
                decoration: _buildInputDecoration(
                  hintText: 'Enlace externo (opcional)',
                  icon: Icons.link_outlined,
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Plan Privado'),
                subtitle: const Text(
                  'Solo visible para tus amigos o comunidades.',
                ),
                value: _isPrivate,
                onChanged: (bool value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
                activeColor: kPrimaryColor,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _createPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'CREAR PLANCITO',
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

  Future<void> _handleImageSelection() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _processingImage = true;
    });

    try {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        picked.path,
        format: CompressFormat.jpeg,
        quality: 90,
        rotate: 0,
      );

      Uint8List previewBytes;
      File fileForUpload;

      if (compressedBytes != null && compressedBytes.isNotEmpty) {
        previewBytes = compressedBytes;
        final tempDir = await getTemporaryDirectory();
        final filename = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final targetPath = p.join(tempDir.path, filename);
        fileForUpload = await File(targetPath).writeAsBytes(
          compressedBytes,
          flush: true,
        );
      } else {
        // Fallback: usar el archivo original
        fileForUpload = File(picked.path);
        previewBytes = await fileForUpload.readAsBytes();
      }

      if (!mounted) return;
      setState(() {
        _selectedImageFile = fileForUpload;
        _previewBytes = previewBytes;
        _imageSelected = true;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo procesar la imagen: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _processingImage = false;
      });
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageFile = null;
      _previewBytes = null;
      _imageSelected = false;
    });
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