import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:hackathon_frontend/screens/business/my_businesses_screen.dart';
import 'package:hackathon_frontend/screens/communities/communities_screen.dart';
import 'package:hackathon_frontend/screens/events/my_events_screen.dart';
import 'package:hackathon_frontend/screens/profile/profile_screen.dart';
import 'package:hackathon_frontend/widgets/bottom_navigation.dart';
import 'package:hackathon_frontend/widgets/home_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navItems;

  void _onItemTapped(int index) {
    if (index >= _pages.length) {
      return;
    }
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _pages = _buildPages(includeBusiness: false);
    _navItems = _buildNavItems(includeBusiness: false);
    _initializeNavigation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(LoginStorageKeys.userRole);
      final isMarket = role?.toUpperCase() == 'MARKET';

      if (!mounted) {
        return;
      }

      setState(() {
        _pages = _buildPages(includeBusiness: isMarket);
        _navItems = _buildNavItems(includeBusiness: isMarket);
        if (_selectedIndex >= _pages.length) {
          _selectedIndex = _pages.length - 1;
          _pageController.jumpToPage(_selectedIndex);
        }
      });
    } on Exception {
      // Si falla la lectura del rol, mantenemos la navegación base.
    }
  }

  List<Widget> _buildPages({required bool includeBusiness}) {
    return [
      const HomeBody(),
      const MyEventsScreen(),
      const CommunitiesScreen(),
      if (includeBusiness) const MyBusinessesListScreen(),
      const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _buildNavItems({
    required bool includeBusiness,
  }) {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.event_note_outlined),
        label: 'Mis eventos',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.groups_outlined),
        label: 'Comunidades',
      ),
      if (includeBusiness)
        const BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined),
          label: 'Mis negocios',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Perfil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}
