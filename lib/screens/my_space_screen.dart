import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/popular_profile.dart';
import '../models/reservation.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../services/user_service.dart';
import '../widgets/event_card.dart';
import '../widgets/following_profile_card.dart';
import '../widgets/reservation_card.dart';
import 'event_detail_screen.dart';
import 'public_profile_screen.dart';

class MySpaceScreen extends StatefulWidget {
  final String token;
  final String currentUserId;

  const MySpaceScreen({super.key, required this.token, required this.currentUserId});

  @override
  MySpaceScreenState createState() => MySpaceScreenState();
}

class MySpaceScreenState extends State<MySpaceScreen> {
  List<Reservation>? _reservations;
  bool _loadingReservations = false;
  String? _reservationsError;

  List<Event>? _savedEvents;
  bool _loadingSaved = false;
  String? _savedError;

  List<PopularProfile>? _following;
  bool _loadingFollowing = false;
  String? _followingError;

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _loadSavedEvents();
    _loadFollowing();
  }

  void refreshMySpace() {
    _loadReservations();
    _loadSavedEvents();
    _loadFollowing();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _loadingReservations = true;
      _reservationsError = null;
    });
    try {
      final reservations = await RegistrationService.getMyReservations(token: widget.token);
      if (mounted) setState(() => _reservations = reservations);
    } catch (e) {
      if (mounted) setState(() => _reservationsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingReservations = false);
    }
  }

  Future<void> _loadSavedEvents() async {
    setState(() {
      _loadingSaved = true;
      _savedError = null;
    });
    try {
      final events = await EventService.getPublicEvents(token: widget.token, savedOnly: true);
      if (mounted) setState(() => _savedEvents = events);
    } catch (e) {
      if (mounted) setState(() => _savedError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _loadingFollowing = true;
      _followingError = null;
    });
    try {
      final following = await UserService.getMyFollowing(token: widget.token);
      if (mounted) setState(() => _following = following);
    } catch (e) {
      if (mounted) setState(() => _followingError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingFollowing = false);
    }
  }

  Future<void> _openReservation(Reservation reservation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          token: widget.token,
          event: reservation.event,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
    _loadReservations();
  }

  Future<void> _openEvent(Event event) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          token: widget.token,
          event: event,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
    _loadSavedEvents();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi espacio'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Próximas'),
              Tab(text: 'Pasadas'),
              Tab(text: 'Guardados'),
              Tab(text: 'Siguiendo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReservationsTab(upcoming: true),
            _buildReservationsTab(upcoming: false),
            _buildSavedTab(),
            _buildFollowingTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsTab({required bool upcoming}) {
    if (_loadingReservations && _reservations == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reservationsError != null && _reservations == null) {
      return _ErrorState(onRetry: _loadReservations);
    }

    final reservations = (_reservations ?? [])
        .where((r) => r.isPast == !upcoming)
        .toList()
      ..sort((a, b) {
        final aDate = a.sessionDate;
        final bDate = b.sessionDate;
        if (aDate == null || bDate == null) return 0;
        return upcoming ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });

    if (reservations.isEmpty) {
      return _EmptyState(
        icon: Icons.event_busy_outlined,
        message: upcoming
            ? 'No tienes reservas próximas'
            : 'Todavía no tienes reservas pasadas',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) => ReservationCard(
          reservation: reservations[index],
          onTap: () => _openReservation(reservations[index]),
        ),
      ),
    );
  }

  Widget _buildSavedTab() {
    if (_loadingSaved && _savedEvents == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_savedError != null && _savedEvents == null) {
      return _ErrorState(onRetry: _loadSavedEvents);
    }

    final events = _savedEvents ?? [];
    if (events.isEmpty) {
      return const _EmptyState(
        icon: Icons.bookmark_outline,
        message: 'Todavía no has guardado ningún evento',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSavedEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return EventCard(
            event: event,
            onTap: () => _openEvent(event),
            onOwnerTap: event.ownerUserId == widget.currentUserId
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          token: widget.token,
                          userId: event.ownerUserId,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildFollowingTab() {
    if (_loadingFollowing && _following == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_followingError != null && _following == null) {
      return _ErrorState(onRetry: _loadFollowing);
    }

    final following = _following ?? [];
    if (following.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_outline,
        message: 'Todavía no sigues a ningún perfil',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowing,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: following.length,
        itemBuilder: (context, index) {
          final profile = following[index];
          return FollowingProfileCard(
            profile: profile,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(
                  token: widget.token,
                  userId: profile.userId,
                  currentUserId: widget.currentUserId,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 12),
        const Text('No se pudo cargar la información', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Center(child: TextButton(onPressed: onRetry, child: const Text('Reintentar'))),
      ],
    );
  }
}
