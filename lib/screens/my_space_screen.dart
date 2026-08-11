import 'package:flutter/material.dart';

import '../models/cancelled_reservation.dart';
import '../models/event.dart';
import '../models/popular_profile.dart';
import '../models/reservation.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../services/user_service.dart';
import '../widgets/calendario_tab.dart';
import '../widgets/cancelled_reservation_card.dart';
import '../widgets/events_locked_banner.dart';
import '../widgets/following_profile_card.dart';
import '../widgets/profile_events_section.dart';
import '../widgets/reservation_card.dart';
import 'event_detail_screen.dart';
import 'public_profile_screen.dart';
import 'settings/pro_plan_screen.dart';

enum _NetworkMode { following, followers }

enum _ReservationsMode { proximas, finalizadas, canceladas }

class MySpaceScreen extends StatefulWidget {
  final String token;
  final String currentUserId;
  final bool isPro;

  const MySpaceScreen({
    super.key,
    required this.token,
    required this.currentUserId,
    required this.isPro,
  });

  @override
  MySpaceScreenState createState() => MySpaceScreenState();
}

class MySpaceScreenState extends State<MySpaceScreen> {
  late bool _isPro = widget.isPro;

  List<Event>? _events;
  bool _loadingEvents = false;
  String? _eventsError;

  List<Event>? _savedEvents;
  bool _loadingSaved = false;
  String? _savedError;

  _ReservationsMode _reservationsMode = _ReservationsMode.proximas;
  List<Reservation>? _reservations;
  bool _loadingReservations = false;
  String? _reservationsError;
  List<CancelledReservation>? _cancelledReservations;
  bool _loadingCancelled = false;
  String? _cancelledError;

  _NetworkMode _networkMode = _NetworkMode.following;
  List<PopularProfile>? _following;
  bool _loadingFollowing = false;
  String? _followingError;
  List<PopularProfile>? _followers;
  bool _loadingFollowers = false;
  String? _followersError;

  @override
  void initState() {
    super.initState();
    if (_isPro) _loadEvents();
    _loadSavedEvents();
    _loadReservations();
    _loadCancelledReservations();
    _loadFollowing();
    _loadFollowers();
  }

  void refreshMySpace() {
    if (_isPro) _loadEvents();
    _loadSavedEvents();
    _loadReservations();
    _loadCancelledReservations();
    _loadFollowing();
    _loadFollowers();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loadingEvents = true;
      _eventsError = null;
    });
    try {
      final events = await EventService.getMyEvents(token: widget.token);
      if (mounted) setState(() => _events = events);
    } catch (e) {
      if (mounted) setState(() => _eventsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  Future<void> _loadSavedEvents() async {
    setState(() {
      _loadingSaved = true;
      _savedError = null;
    });
    try {
      final events = await EventService.getPublicEvents(
        token: widget.token,
        savedOnly: true,
      );
      if (mounted) setState(() => _savedEvents = events);
    } catch (e) {
      if (mounted) setState(() => _savedError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  Future<void> _loadReservations() async {
    setState(() {
      _loadingReservations = true;
      _reservationsError = null;
    });
    try {
      final reservations = await RegistrationService.getMyReservations(
        token: widget.token,
      );
      if (mounted) setState(() => _reservations = reservations);
    } catch (e) {
      if (mounted) setState(() => _reservationsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingReservations = false);
    }
  }

  Future<void> _loadCancelledReservations() async {
    setState(() {
      _loadingCancelled = true;
      _cancelledError = null;
    });
    try {
      final cancellations =
          await RegistrationService.getMyCancelledReservations(
            token: widget.token,
          );
      if (mounted) setState(() => _cancelledReservations = cancellations);
    } catch (e) {
      if (mounted) setState(() => _cancelledError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingCancelled = false);
    }
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _loadingFollowing = true;
      _followingError = null;
    });
    try {
      final profiles = await UserService.getMyFollowing(token: widget.token);
      if (mounted) setState(() => _following = profiles);
    } catch (e) {
      if (mounted) setState(() => _followingError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingFollowing = false);
    }
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _loadingFollowers = true;
      _followersError = null;
    });
    try {
      final profiles = await UserService.getMyFollowers(token: widget.token);
      if (mounted) setState(() => _followers = profiles);
    } catch (e) {
      if (mounted) setState(() => _followersError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingFollowers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi espacio'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Mis Eventos'),
              Tab(text: 'Mis reservas'),
              Tab(text: 'Guardados'),
              Tab(text: 'Mi red'),
              Tab(text: 'Calendario'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyEventsTab(context),
            _buildMisReservasTab(context),
            _buildGuardadosTab(context),
            _buildMiRedTab(context),
            CalendarioTab(
              token: widget.token,
              currentUserId: widget.currentUserId,
              isPro: _isPro,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyEventsTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_isPro) await _loadEvents();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileEventsSection(
            events: _events,
            isLoading: _loadingEvents,
            error: _eventsError,
            onRetry: _loadEvents,
            emptyMessage: 'Todavía no has creado ningún evento',
            lockedBanner: _isPro
                ? null
                : EventsLockedBanner(
                    onUpgrade: () async {
                      final updatedUser = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProPlanScreen(
                            token: widget.token,
                            subscriptionPlan: SubscriptionPlan.free,
                          ),
                        ),
                      );
                      if (updatedUser != null) {
                        setState(
                          () => _isPro =
                              updatedUser.subscriptionPlan ==
                              SubscriptionPlan.pro,
                        );
                        if (_isPro) _loadEvents();
                      }
                    },
                  ),
            onEventTap: (e) async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(
                    token: widget.token,
                    event: e,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
              if (changed == true) _loadEvents();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMisReservasTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<_ReservationsMode>(
            segments: const [
              ButtonSegment(
                value: _ReservationsMode.proximas,
                label: Text('Próximas'),
              ),
              ButtonSegment(
                value: _ReservationsMode.finalizadas,
                label: Text('Finalizadas'),
              ),
              ButtonSegment(
                value: _ReservationsMode.canceladas,
                label: Text('Canceladas'),
              ),
            ],
            selected: {_reservationsMode},
            onSelectionChanged: (selection) =>
                setState(() => _reservationsMode = selection.first),
          ),
        ),
        Expanded(
          child: switch (_reservationsMode) {
            _ReservationsMode.proximas => _buildReservationsList(isPast: false),
            _ReservationsMode.finalizadas => _buildReservationsList(
              isPast: true,
            ),
            _ReservationsMode.canceladas => _buildCancelledList(),
          },
        ),
      ],
    );
  }

  Widget _buildReservationsList({required bool isPast}) {
    if (_loadingReservations && _reservations == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reservationsError != null && _reservations == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.error_outline,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudo cargar la información',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _loadReservations,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    final results = (_reservations ?? [])
        .where((r) => r.isPast == isPast)
        .toList();
    if (results.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.event_busy_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            isPast
                ? 'Todavía no tienes reservas finalizadas'
                : 'Todavía no tienes reservas próximas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final reservation = results[index];
          return ReservationCard(
            reservation: reservation,
            onTap: () async {
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
            },
          );
        },
      ),
    );
  }

  Widget _buildCancelledList() {
    if (_loadingCancelled && _cancelledReservations == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cancelledError != null && _cancelledReservations == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.error_outline,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudo cargar la información',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _loadCancelledReservations,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    final results = _cancelledReservations ?? [];
    if (results.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.event_busy_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Todavía no tienes reservas canceladas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCancelledReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) =>
            CancelledReservationCard(cancellation: results[index]),
      ),
    );
  }

  Widget _buildGuardadosTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadSavedEvents,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileEventsSection(
            events: _savedEvents,
            isLoading: _loadingSaved,
            error: _savedError,
            onRetry: _loadSavedEvents,
            emptyMessage: 'Todavía no has guardado ningún evento',
            onEventTap: (e) async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(
                    token: widget.token,
                    event: e,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
              _loadSavedEvents();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiRedTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<_NetworkMode>(
            segments: const [
              ButtonSegment(
                value: _NetworkMode.following,
                label: Text('Siguiendo'),
              ),
              ButtonSegment(
                value: _NetworkMode.followers,
                label: Text('Seguidores'),
              ),
            ],
            selected: {_networkMode},
            onSelectionChanged: (selection) =>
                setState(() => _networkMode = selection.first),
          ),
        ),
        Expanded(
          child: _networkMode == _NetworkMode.following
              ? _buildProfileList(
                  profiles: _following,
                  isLoading: _loadingFollowing,
                  error: _followingError,
                  onRetry: _loadFollowing,
                  emptyMessage: 'Todavía no sigues a ningún perfil',
                )
              : _buildProfileList(
                  profiles: _followers,
                  isLoading: _loadingFollowers,
                  error: _followersError,
                  onRetry: _loadFollowers,
                  emptyMessage: 'Todavía no tienes seguidores',
                ),
        ),
      ],
    );
  }

  Widget _buildProfileList({
    required List<PopularProfile>? profiles,
    required bool isLoading,
    required String? error,
    required VoidCallback onRetry,
    required String emptyMessage,
  }) {
    if (isLoading && profiles == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && profiles == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.error_outline,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudo cargar la información',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    final results = profiles ?? [];
    if (results.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.people_outline,
            size: 40,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadFollowing();
        _loadFollowers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final profile = results[index];
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
