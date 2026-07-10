import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/user.dart';
import 'create_screen.dart';
import 'explore_screen.dart';
import 'my_space_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  final Profile profile;
  final String token;

  const HomeScreen({
    super.key,
    required this.user,
    required this.profile,
    required this.token,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _profileKey = GlobalKey<ProfileScreenState>();

  static const _profileTabIndex = 3;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ExploreScreen(),
      CreateScreen(user: widget.user, token: widget.token),
      const MySpaceScreen(),
      ProfileScreen(
        key: _profileKey,
        user: widget.user,
        profile: widget.profile,
        token: widget.token,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == _profileTabIndex) _profileKey.currentState?.refreshEvents();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorar'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Crear'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Mi espacio'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
