import 'package:flutter/material.dart';

import '../models/cancelled_reservation.dart';
import '../models/event.dart';
import '../models/reservation.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../widgets/calendario_tab.dart';
import '../widgets/cancelled_reservation_card.dart';
import '../widgets/events_locked_banner.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/profile_events_section.dart';
import '../widgets/reservation_card.dart';
import 'event_detail_screen.dart';
import 'settings/pro_plan_screen.dart';

enum _ReservationsMode { proximas, finalizadas, canceladas }

class MySpaceScreen extends StatefulWidget {
  final String token;
  final String currentUserId;
  final bool isPro;
  final bool hasUnreadNotifications;
  final VoidCallback onNotificationsTap;

  const MySpaceScreen({
    super.key,
    required this.token,
    required this.currentUserId,
    required this.isPro,
    required this.hasUnreadNotifications,
    required this.onNotificationsTap,
  });

  @override
  MySpaceScreenState createState() => MySpaceScreenState();
}

class MySpaceScreenState extends State<MySpaceScreen> {
  late bool _isPro = widget.isPro;
  final _calendarioKey = GlobalKey<CalendarioTabState>();

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

  @override
  void initState() {
    super.initState();
    if (_isPro) _loadEvents();
    _loadSavedEvents();
    _loadReservations();
    _loadCancelledReservations();
  }

  void refreshMySpace() {
    if (_isPro) _loadEvents();
    _loadSavedEvents();
    _loadReservations();
    _loadCancelledReservations();
    _calendarioKey.currentState?.refresh();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loadingEvents = true;
      _eventsError = null;
    });
    try {
      final events = await EventService.getMyEvents(token: widget.token);
      if (mounted) {
        setState(
          () => _events = events
              .where((e) => e.status != EventStatus.draft)
              .toList(),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi espacio'),
          actions: [
            NotificationBellButton(
              hasUnread: widget.hasUnreadNotifications,
              onTap: widget.onNotificationsTap,
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Mis Eventos'),
              Tab(text: 'Mis reservas'),
              Tab(text: 'Guardados'),
              Tab(text: 'Calendario'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyEventsTab(context),
            _buildMisReservasTab(context),
            _buildGuardadosTab(context),
            CalendarioTab(
              key: _calendarioKey,
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
            showSelectedIcon: false,
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
}
