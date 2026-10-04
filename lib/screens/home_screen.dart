import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/user.dart';
import '../services/app_location_service.dart';
import '../services/event_service.dart';
import 'create_screen.dart';
import 'event_detail_screen.dart';
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
  void initState() {
    super.initState();
    _restoreLocation();
  }

  // Only ever meaningfully runs after a genuine cold (re)start - while the
  // app is simply backgrounded and resumed, this State survives in memory
  // and initState doesn't re-run, so this never fights with normal in-app
  // navigation.
  Future<void> _restoreLocation() async {
    final tab = await AppLocationService.loadTab();
    if (mounted && tab != _selectedIndex) {
      setState(() => _selectedIndex = tab);
    }

    final eventId = await AppLocationService.loadOpenEvent();
    if (eventId == null || !mounted) return;
    try {
      final event = await EventService.getEvent(
        token: widget.token,
        eventId: eventId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(
            token: widget.token,
            event: event,
            currentUserId: widget.user.id,
          ),
        ),
      );
    } catch (_) {
      // Event may have been deleted, or this was a network hiccup - either
      // way, landing on the restored tab underneath is a fine fallback.
      AppLocationService.saveOpenEvent(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ExploreScreen(
        key: _exploreKey,
        token: widget.token,
        currentUserId: widget.user.id,
      ),
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
          AppLocationService.saveTab(index);
          if (index == _profileTabIndex) {
            _profileKey.currentState?.refreshEvents();
            _profileKey.currentState?.refreshNotificationStatus();
          }
          if (index == _exploreTabIndex) {
            _exploreKey.currentState?.refreshEvents();
          }
          if (index == _mySpaceTabIndex) {
            _mySpaceKey.currentState?.refreshMySpace();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Crear',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Mi espacio',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
