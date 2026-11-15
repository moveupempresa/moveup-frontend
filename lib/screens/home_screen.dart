import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/user.dart';
import '../services/app_location_service.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import 'create_screen.dart';
import 'event_detail_screen.dart';
import 'explore_screen.dart';
import 'my_space_screen.dart';
import 'profile_screen.dart';
import 'settings/notifications_screen.dart';

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

  bool _hasUnreadNotifications = false;

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _restoreLocation();
    _loadNotificationStatus();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // Handles https://atryumapp.com/evento/<id> links shared from outside the
  // app (e.g. an Instagram story link sticker) once they're verified as
  // Universal/App Links by iOS/Android and handed off to us.
  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleDeepLink(initial);
    } catch (_) {
      // No initial link, or the platform channel isn't ready yet - either
      // way there's nothing to recover from here.
    }
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  void _handleDeepLink(Uri uri) {
    final segments = uri.pathSegments;
    final i = segments.indexOf('evento');
    if (i == -1 || i + 1 >= segments.length) return;
    final eventId = segments[i + 1];
    if (eventId.isEmpty) return;
    _openEventById(eventId);
  }

  Future<void> _openEventById(String eventId) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el evento')),
        );
      }
    }
  }

  Future<void> _loadNotificationStatus() async {
    try {
      final notifications = await NotificationService.getMyNotifications(
        token: widget.token,
      );
      if (mounted) {
        setState(
          () => _hasUnreadNotifications = notifications.any((n) => !n.read),
        );
      }
    } catch (_) {
      // Keep the current badge state if this background check fails.
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          token: widget.token,
          currentUserId: widget.user.id,
        ),
      ),
    );
    _loadNotificationStatus();
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
        hasUnreadNotifications: _hasUnreadNotifications,
        onNotificationsTap: _openNotifications,
      ),
      CreateScreen(user: widget.user, token: widget.token),
      MySpaceScreen(
        key: _mySpaceKey,
        token: widget.token,
        currentUserId: widget.user.id,
        isPro: widget.user.subscriptionPlan == SubscriptionPlan.pro,
        hasUnreadNotifications: _hasUnreadNotifications,
        onNotificationsTap: _openNotifications,
      ),
      ProfileScreen(
        key: _profileKey,
        user: widget.user,
        profile: widget.profile,
        token: widget.token,
        hasUnreadNotifications: _hasUnreadNotifications,
        onNotificationsTap: _openNotifications,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          AppLocationService.saveTab(index);
          _loadNotificationStatus();
          if (index == _profileTabIndex) {
            _profileKey.currentState?.refreshEvents();
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
