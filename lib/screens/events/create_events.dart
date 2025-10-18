import 'package:flutter/material.dart';
//import 'package:dotted_border/dotted_border.dart'; // Importamos el paquete
import '../auth/login.dart'; // Para usar las constantes de color

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores y variables de estado
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _participantsController;

  DateTime? _selectedDate;
  String? _selectedCategory;
  bool _isPrivate = false;
  // En un app real, aquí guardarías el archivo de imagen.
  // Por ahora, simulamos que se ha seleccionado una.
  bool _imageSelected = false;

  final List<String> _categories = [
    'Gastronomía',
    'Deporte',
    'Fiesta',
    'Cultural',
    'Aire Libre',
    'Cine',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _participantsController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  // --- Lógica para seleccionar fecha y hora ---
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

  // --- Lógica para "crear" el plan ---
  void _createPlan() {
    if (_formKey.currentState!.validate()) {
      // Validamos que se haya seleccionado fecha y categoría
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecciona una fecha y hora'),
          ),
        );
        return;
      }

      // Aquí recolectarías todos los datos y los enviarías a tu backend
      print('--- NUEVO PLAN CREADO ---');
      print('Título: ${_titleController.text}');
      print('Descripción: ${_descriptionController.text}');
      print('Categoría: $_selectedCategory');
      print('Fecha y Hora: $_selectedDate');
      print('Ubicación: ${_locationController.text}');
      print('Participantes: ${_participantsController.text}');
      print('Privado: $_isPrivate');
      print('Imagen Seleccionada: $_imageSelected');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tu plancito ha sido creado con éxito!'),
          backgroundColor: kPrimaryColor,
        ),
      );
      // Regresamos a la pantalla anterior
      Navigator.of(context).pop();
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

              // --- Campo para Añadir Imagen ---
              GestureDetector(
                onTap: () {
                  // TODO: Lógica para abrir la galería de imágenes
                  setState(() {
                    _imageSelected = true;
                  });
                },
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
                    child: _imageSelected
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle,
                                color: kPrimaryColor,
                                size: 48,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Imagen seleccionada',
                                style: TextStyle(color: kPrimaryColor),
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
                              const Text(
                                'Añadir foto del plan',
                                style: TextStyle(color: kPrimaryColor),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Título del Plan ---
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

              // --- Descripción ---
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

              // --- Fecha y Hora ---
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

              // --- Ubicación y Participantes (en una fila) ---
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

              // --- Switch Público/Privado ---
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

              // --- Botón de Crear Plan ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'CREAR PLANCITO',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
