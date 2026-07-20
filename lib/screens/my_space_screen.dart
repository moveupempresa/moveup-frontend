import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/popular_profile.dart';
import '../models/reservation.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../services/user_service.dart';
import '../widgets/eventos_section.dart';
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

  // Every event the user is attending (upcoming reservation) or has saved,
  // deduplicated so an event that's both only shows once (as "attending").
  List<EventosItem>? get _eventosItems {
    if (_reservations == null && _savedEvents == null) return null;

    final byEventId = <String, EventosItem>{};
    for (final r in (_reservations ?? []).where((r) => !r.isPast)) {
      final existing = byEventId[r.event.id];
      final existingDate = existing?.reservation?.sessionDate;
      final shouldReplace = existing == null ||
          (r.sessionDate != null && (existingDate == null || r.sessionDate!.isBefore(existingDate)));
      if (shouldReplace) byEventId[r.event.id] = EventosItem(event: r.event, reservation: r);
    }
    for (final e in (_savedEvents ?? [])) {
      byEventId.putIfAbsent(e.id, () => EventosItem(event: e));
    }
    return byEventId.values.toList();
  }

  Future<void> _openEventosItem(EventosItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          token: widget.token,
          event: item.event,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
    _loadReservations();
    _loadSavedEvents();
  }

  void _openOwnerProfile(Event event) {
    if (event.ownerUserId == widget.currentUserId) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          token: widget.token,
          userId: event.ownerUserId,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi espacio'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Eventos'),
              Tab(text: 'Pasadas'),
              Tab(text: 'Siguiendo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            EventosSection(
              items: _eventosItems,
              isLoading: _loadingReservations || _loadingSaved,
              error: _reservationsError ?? _savedError,
              onRetry: () {
                _loadReservations();
                _loadSavedEvents();
              },
              emptyMessage: 'Todavía no tienes eventos aquí. Reserva o guarda alguno para verlo.',
              onItemTap: _openEventosItem,
              onOwnerTap: _openOwnerProfile,
            ),
            _buildPastReservationsTab(),
            _buildFollowingTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPastReservationsTab() {
    if (_loadingReservations && _reservations == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reservationsError != null && _reservations == null) {
      return _ErrorState(onRetry: _loadReservations);
    }

    final reservations = (_reservations ?? [])
        .where((r) => r.isPast)
        .toList()
      ..sort((a, b) {
        final aDate = a.sessionDate;
        final bDate = b.sessionDate;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

    if (reservations.isEmpty) {
      return const _EmptyState(
        icon: Icons.event_busy_outlined,
        message: 'Todavía no tienes reservas pasadas',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) => ReservationCard(
          reservation: reservations[index],
          onTap: () => _openEventosItem(EventosItem(event: reservations[index].event, reservation: reservations[index])),
        ),
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
