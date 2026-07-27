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
  final _exploreKey = GlobalKey<ExploreScreenState>();
  final _mySpaceKey = GlobalKey<MySpaceScreenState>();

  static const _exploreTabIndex = 0;
  static const _mySpaceTabIndex = 2;
  static const _profileTabIndex = 3;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ExploreScreen(key: _exploreKey, token: widget.token, currentUserId: widget.user.id),
      CreateScreen(user: widget.user, token: widget.token),
      MySpaceScreen(
        key: _mySpaceKey,
        token: widget.token,
        currentUserId: widget.user.id,
        isPro: widget.user.subscriptionPlan == SubscriptionPlan.pro,
      ),
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
          if (index == _exploreTabIndex) _exploreKey.currentState?.refreshEvents();
          if (index == _mySpaceTabIndex) _mySpaceKey.currentState?.refreshMySpace();
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
