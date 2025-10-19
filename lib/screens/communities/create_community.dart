import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/category_model.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:hackathon_frontend/services/category_service.dart';
import 'package:hackathon_frontend/services/communities_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _rulesController;
  late CommunitiesService _communitiesService;
  late CategoryService _categoryService;

  int? _selectedCategoryId;
  bool _isPrivate = false;
  bool _isSubmitting = false;
  String? _submitError;
  String? _categoriesError;

  List<Category> _categories = [];
  bool _loadingCategories = true;
  File? _imageFile;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _rulesController = TextEditingController();
    _communitiesService = CommunitiesService();
    _categoryService = CategoryService();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
        _categoriesError = null;
      });
    } catch (error, stackTrace) {
      developer.log(
        '_loadCategories -> error: $error',
        name: 'CreateCommunityScreen',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _categoriesError = 'No fue posible cargar las categorías.';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      developer.log(
        '_pickImage -> picked path: ${pickedFile.path}',
        name: 'CreateCommunityScreen',
      );
      final bytes = await pickedFile.readAsBytes();
      developer.log(
        '_pickImage -> raw bytes length: ${bytes.length}',
        name: 'CreateCommunityScreen',
      );
      final extension = p.extension(pickedFile.path).toLowerCase();
      String mimeType = 'image/jpeg';
      if (extension == '.png') {
        mimeType = 'image/png';
      } else if (extension == '.gif') {
        mimeType = 'image/gif';
      } else if (extension == '.webp') {
        mimeType = 'image/webp';
      }
      final encoded = base64Encode(bytes);
      developer.log(
        '_pickImage -> encoded length: ${encoded.length}, mimeType: $mimeType',
        name: 'CreateCommunityScreen',
      );
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageBase64 = 'data:$mimeType;base64,$encoded';
      });
    }
  }

  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final selectedCategoryId = _selectedCategoryId;
    if (selectedCategoryId == null) {
      setState(() {
        _isSubmitting = false;
        _submitError = 'Debes seleccionar una categoría.';
      });
      return;
    }

    developer.log(
      '_createCommunity -> current state: name="${_nameController.text}", descriptionLength=${_descriptionController.text.length}, private=$_isPrivate, hasRules=${_rulesController.text.isNotEmpty}',
      name: 'CreateCommunityScreen',
    );
    developer.log(
      '_createCommunity -> sending name=${_nameController.text}, categoryId=$selectedCategoryId, hasImage=${_imageBase64 != null}',
      name: 'CreateCommunityScreen',
    );

    try {
      final response =
          await _communitiesService.createCommunity(
        _nameController.text,
        _descriptionController.text,
        selectedCategoryId,
        _imageBase64,
      );
      developer.log(
        '_createCommunity -> success, communityId=${response.community.id}',
        name: 'CreateCommunityScreen',
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
      Navigator.of(context).pop(response.community);
    } on CommunitiesException catch (e) {
      developer.log(
        '_createCommunity -> CommunitiesException: ${e.message}',
        name: 'CreateCommunityScreen',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitError = e.message;
        _isSubmitting = false;
      });
    } catch (error, stackTrace) {
      developer.log(
        '_createCommunity -> unexpected error: $error',
        name: 'CreateCommunityScreen',
        error: error,
        stackTrace: stackTrace,
      );
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
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _imageFile != null
                        ? Colors.transparent
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kPrimaryColor.withOpacity(0.7),
                      width: 1.5,
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Column(
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
              if (_loadingCategories)
                const Center(child: CircularProgressIndicator())
              else if (_categoriesError != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoriesError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _loadCategories,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryColor,
                        side: BorderSide(
                          color: kPrimaryColor.withOpacity(0.5),
                        ),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                )
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