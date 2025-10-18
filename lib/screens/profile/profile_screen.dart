import 'package:flutter/material.dart';
import '../auth/login.dart'; // Importamos para usar las constantes de color

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Datos de usuario de ejemplo (en un app real vendrían de un estado o API)
  String _userName = 'John Doe';
  String _userEmail = 'john.doe@example.com';
  String _profileImageUrl =
      'https://via.placeholder.com/150/4BBAC3/FFFFFF?text=JD'; // Placeholder

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Perfil',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // Aquí podrías agregar un botón de ajustes si lo necesitas
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.settings, color: kPrimaryColor),
        //     onPressed: () {
        //       print('Ajustes presionados');
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- 1. Foto de Perfil ---
                  GestureDetector(
                    onTap: () {
                      // TODO: Lógica para cambiar la foto de perfil
                      print('Cambiar foto de perfil');
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 100,
                          backgroundColor: kPrimaryColor.withOpacity(0.2),
                          backgroundImage: NetworkImage(_profileImageUrl),
                          child: _profileImageUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 100,
                                  color: kPrimaryColor,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: kPrimaryColor,
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // --- 2. Nombre de Usuario ---
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // --- 3. Correo Electrónico ---
                  Text(
                    _userEmail,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32.0),

                  // --- 4. Botón de Editar Perfil ---
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navegar a pantalla de edición de perfil
                        print('Editar perfil');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimaryColor,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit_outlined, color: kPrimaryColor),
                          SizedBox(width: 8.0),
                          Text('Editar Perfil'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE0E0E0),
                  ),
                  const SizedBox(height: 24.0),

                  // --- Secciones de Opciones ---
                  _buildProfileOption(
                    icon: Icons.vpn_key_outlined,
                    title: 'Cambiar Contraseña',
                    onTap: () {
                      // TODO: Navegar a pantalla de cambio de contraseña
                      print('Cambiar contraseña');
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notificaciones',
                    onTap: () {
                      // TODO: Navegar a pantalla de ajustes de notificaciones
                      print('Ajustes de notificaciones');
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.security_outlined,
                    title: 'Privacidad',
                    onTap: () {
                      // TODO: Navegar a pantalla de privacidad
                      print('Ajustes de privacidad');
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.help_outline,
                    title: 'Ayuda y Soporte',
                    onTap: () {
                      // TODO: Navegar a pantalla de ayuda
                      print('Ayuda y Soporte');
                    },
                  ),
                  const SizedBox(height: 48.0),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // TODO: Lógica para cerrar sesión
                    _logout(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    alignment: Alignment.centerLeft,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Cerrar Sesión'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper para las opciones del perfil
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            foregroundColor: Colors.black87,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: kPrimaryColor),
              const SizedBox(width: 8.0),
              Text(title),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 12.0),
      ],
    );
  }

  // Lógica de cerrar sesión simple
  void _logout(BuildContext context) {
    // En un app real, aquí borrarías tokens, datos de usuario, etc.
    print('Cerrando sesión...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesión cerrada correctamente.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    // Navegar de vuelta al login y eliminar todas las rutas anteriores
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }
}
