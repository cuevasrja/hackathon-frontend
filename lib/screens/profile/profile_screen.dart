import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:hackathon_frontend/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hackathon_frontend/screens/profile/change_password_screen.dart';
import 'package:hackathon_frontend/screens/profile/edit_profile_screen.dart';
import 'package:hackathon_frontend/screens/profile/notifications_screen.dart';
import 'package:hackathon_frontend/screens/profile/privacy_screen.dart';
import 'package:hackathon_frontend/screens/profile/support_screen.dart';
import '../auth/login.dart'; // Importamos para usar las constantes de color

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _userIdKey = 'userId';
  // Datos del usuario (se rellenan desde la API)
  String _userFirstName = '';
  String _userLastName = '';
  String _userName = '';
  String _userEmail = '';
  String _profileImageUrl = '';
  String _userMembership = '';
  String _userCity = '';
  int? _userId;
  late ProfileService _profileService;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_userIdKey);
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'No se encontró el usuario autenticado.';
          _isLoading = false;
        });
        return;
      }

  final user = await _profileService.fetchUser(userId);

      if (!mounted) return;

      final fetchedFirstName = user.name.trim();
      final fetchedLastName = user.lastName.trim();
      final fullName = '${fetchedFirstName} ${fetchedLastName}'.trim();

      setState(() {
        _userFirstName = fetchedFirstName;
        _userLastName = fetchedLastName;
        _userName = fullName.isNotEmpty ? fullName : user.email;
        _userEmail = user.email;
        _userMembership = user.membership;
        _userCity = user.city;
        _userId = user.id;
        _isLoading = false;
      });
    } on ProfileException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error inesperado al cargar la información del perfil.';
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
  developer.log('[ProfileScreen] _profileImageUrl: $_profileImageUrl');
  return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Perfil',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorContent()
          : Column(
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
                                backgroundImage: _profileImageUrl.isNotEmpty
                                    ? NetworkImage(_profileImageUrl)
                                    : null,
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
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_userCity.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _userCity,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        if (_userMembership.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Membresía: $_userMembership',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 32.0),

                        // --- 4. Botón de Editar Perfil ---
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _userId == null
                                ? null
                                : () async {
                                    final nameParts = _userName.trim().isEmpty
                                        ? <String>[]
                                        : _userName.trim().split(RegExp(r'\s+'));
                                    final fallbackFirstName =
                                        _userFirstName.isNotEmpty
                                            ? _userFirstName
                                            : (nameParts.isNotEmpty &&
                                                    !_userName.contains('@')
                                                ? nameParts.first
                                                : '');
                                    final fallbackLastName =
                                        _userLastName.isNotEmpty
                                            ? _userLastName
                                            : (nameParts.length > 1 &&
                                                    !_userName.contains('@')
                                                ? nameParts
                                                    .sublist(1)
                                                    .join(' ')
                                                    .trim()
                                                : '');

                                    final updated = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfileScreen(
                                          currentName: fallbackFirstName,
                                          currentLastName: fallbackLastName,
                                          currentUserEmail: _userEmail,
                                          currentProfileImageUrl:
                                              _profileImageUrl,
                                          currentCity: _userCity,
                                          userId: _userId!,
                                        ),
                                      ),
                                    );

                                    if (updated == true && mounted) {
                                      _loadProfile();
                                    }
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: kPrimaryColor,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        _buildProfileOption(
                          icon: Icons.notifications_none_outlined,
                          title: 'Notificaciones',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildProfileOption(
                          icon: Icons.security_outlined,
                          title: 'Privacidad',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyScreen(),
                              ),
                            );
                          },
                        ),
                        _buildProfileOption(
                          icon: Icons.help_outline,
                          title: 'Ayuda y Soporte',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SupportScreen(),
                              ),
                            );
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

  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage ?? 'Error al cargar el perfil.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
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
  Future<void> _logout(BuildContext context) async {
    // En un app real, aquí borrarías tokens, datos de usuario, etc.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(LoginStorageKeys.token);
    await prefs.remove(LoginStorageKeys.userRole);

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
