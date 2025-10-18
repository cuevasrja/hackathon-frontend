import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/home/communities_screen.dart';
import 'package:hackathon_frontend/screens/home/my_diet_screen.dart';
import 'package:hackathon_frontend/screens/profile/profile_screen.dart';
import 'package:hackathon_frontend/widgets/home_body.dart';
import 'package:hackathon_frontend/widgets/bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
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
        children: const <Widget>[
          // This is the actual home screen content
          HomeBody(),
          MyDietScreen(),
          CommunitiesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
