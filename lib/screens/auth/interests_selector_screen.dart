import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/home/home_screen.dart';
import 'login.dart'; // Para los colores

// --- Modelo de Datos para un Interés ---
class Interest {
  final String name;
  final IconData icon;

  Interest({required this.name, required this.icon});
}

// --- Pantalla de Selección de Intereses ---
class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  State<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  // Lista de todos los intereses disponibles
  final List<Interest> _allInterests = [
    Interest(name: 'Comer Afuera', icon: Icons.restaurant_menu_outlined),
    Interest(name: 'Senderismo', icon: Icons.terrain_outlined),
    Interest(name: 'Rumbear', icon: Icons.nightlife_outlined),
    Interest(name: 'Cine', icon: Icons.theaters_outlined),
    Interest(name: 'Conciertos', icon: Icons.music_note_outlined),
    Interest(name: 'Deportes', icon: Icons.sports_soccer_outlined),
    Interest(name: 'Arte y Cultura', icon: Icons.palette_outlined),
    Interest(name: 'Tomar Café', icon: Icons.coffee_outlined),
    Interest(name: 'Juegos', icon: Icons.games_outlined),
    Interest(name: 'Viajar', icon: Icons.explore_outlined),
    Interest(name: 'Compras', icon: Icons.shopping_bag_outlined),
    Interest(name: 'Relajarse', icon: Icons.spa_outlined),
  ];

  // Usamos un Set para guardar los intereses seleccionados (es más eficiente)
  final Set<String> _selectedInterests = {};
  final int _minSelection = 3;

  void _toggleInterest(String interestName) {
    setState(() {
      if (_selectedInterests.contains(interestName)) {
        _selectedInterests.remove(interestName);
      } else {
        _selectedInterests.add(interestName);
      }
    });
  }

  void _saveInterests() {
    if (_selectedInterests.length >= _minSelection) {
      // --- Lógica para guardar las preferencias en el backend ---
      print('Intereses guardados: $_selectedInterests');
      // -----------------------------------------------------------

      // Navegamos a la pantalla principal de la app
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = _selectedInterests.length >= _minSelection;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Oculta el botón de "atrás"
        title: const Text(
          '¡Bienvenido a Plancito!',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuéntanos qué te gusta',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige al menos $_minSelection para que podamos recomendarte los mejores planes.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: _allInterests.length,
                itemBuilder: (context, index) {
                  final interest = _allInterests[index];
                  final isSelected = _selectedInterests.contains(interest.name);
                  return _buildInterestCard(interest, isSelected);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(canContinue),
    );
  }

  Widget _buildInterestCard(Interest interest, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleInterest(interest.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              interest.icon,
              size: 40,
              color: isSelected ? Colors.white : kPrimaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              interest.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool canContinue) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedInterests.length < _minSelection
                  ? 'Selecciona ${_minSelection - _selectedInterests.length} más'
                  : '¡Todo listo!',
              style: TextStyle(
                color: canContinue ? kPrimaryColor : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canContinue ? _saveInterests : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'CONTINUAR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
