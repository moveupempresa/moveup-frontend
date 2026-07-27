import 'package:flutter/material.dart';

import '../models/calendar_note.dart';
import '../models/event.dart';
import '../models/pending_request.dart';
import '../models/popular_profile.dart';
import '../models/reservation.dart';
import '../services/auth_service.dart';
import '../services/calendar_note_service.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../services/user_service.dart';
import '../widgets/eventos_section.dart';
import '../widgets/following_profile_card.dart';
import '../widgets/pending_request_card.dart';
import '../widgets/reservation_card.dart';
import 'event_detail_screen.dart';
import 'public_profile_screen.dart';

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
  List<Reservation>? _reservations;
  bool _loadingReservations = false;
  String? _reservationsError;

  List<Event>? _savedEvents;
  bool _loadingSaved = false;
  String? _savedError;

  List<PopularProfile>? _following;
  bool _loadingFollowing = false;
  String? _followingError;

  List<PendingRequest>? _pendingRequests;
  bool _loadingPendingRequests = false;
  String? _pendingRequestsError;
  final Set<String> _processingRequestIds = {};

  List<CalendarNote>? _calendarNotes;

  Map<String, CalendarNote> get _notesByDate => {
        for (final n in _calendarNotes ?? <CalendarNote>[]) n.date: n,
      };

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _loadSavedEvents();
    _loadFollowing();
    _loadCalendarNotes();
    if (widget.isPro) _loadPendingRequests();
  }

  void refreshMySpace() {
    _loadReservations();
    _loadSavedEvents();
    _loadFollowing();
    _loadCalendarNotes();
    if (widget.isPro) _loadPendingRequests();
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

  Future<void> _loadPendingRequests() async {
    setState(() {
      _loadingPendingRequests = true;
      _pendingRequestsError = null;
    });
    try {
      final requests = await RegistrationService.getMyPendingRequests(token: widget.token);
      if (mounted) setState(() => _pendingRequests = requests);
    } catch (e) {
      if (mounted) setState(() => _pendingRequestsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPendingRequests = false);
    }
  }

  Future<void> _respondToRequest(PendingRequest request, {required bool approve}) async {
    setState(() => _processingRequestIds.add(request.id));
    try {
      approve
          ? await RegistrationService.approvePackRequest(
              token: widget.token,
              eventId: request.eventId,
              packId: request.packId,
              userId: request.userId,
            )
          : await RegistrationService.rejectPackRequest(
              token: widget.token,
              eventId: request.eventId,
              packId: request.packId,
              userId: request.userId,
            );
      if (mounted) {
        setState(() {
          _pendingRequests = _pendingRequests?.where((r) => r.id != request.id).toList();
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _processingRequestIds.remove(request.id));
    }
  }

  Future<void> _loadCalendarNotes() async {
    try {
      final notes = await CalendarNoteService.getMyNotes(token: widget.token);
      if (mounted) setState(() => _calendarNotes = notes);
    } catch (_) {
      // Keep whatever notes are already loaded if a background refresh fails.
    }
  }

  Future<void> _saveCalendarNote(String date, String text) async {
    try {
      final note = await CalendarNoteService.setNote(token: widget.token, date: date, text: text);
      if (mounted) {
        setState(() {
          _calendarNotes = [...?_calendarNotes?.where((n) => n.date != date), note];
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteCalendarNote(String date) async {
    try {
      await CalendarNoteService.deleteNote(token: widget.token, date: date);
      if (mounted) {
        setState(() {
          _calendarNotes = _calendarNotes?.where((n) => n.date != date).toList();
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
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
      length: widget.isPro ? 4 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi espacio'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(text: 'Eventos'),
              const Tab(text: 'Pasadas'),
              const Tab(text: 'Siguiendo'),
              if (widget.isPro) const Tab(text: 'Solicitudes'),
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
              notesByDate: _notesByDate,
              onSaveNote: _saveCalendarNote,
              onDeleteNote: _deleteCalendarNote,
            ),
            _buildPastReservationsTab(),
            _buildFollowingTab(),
            if (widget.isPro) _buildPendingRequestsTab(),
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

  Widget _buildPendingRequestsTab() {
    if (_loadingPendingRequests && _pendingRequests == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pendingRequestsError != null && _pendingRequests == null) {
      return _ErrorState(onRetry: _loadPendingRequests);
    }

    final requests = _pendingRequests ?? [];
    if (requests.isEmpty) {
      return const _EmptyState(
        icon: Icons.pending_actions_outlined,
        message: 'No tienes solicitudes pendientes',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return PendingRequestCard(
            request: request,
            isProcessing: _processingRequestIds.contains(request.id),
            onApprove: () => _respondToRequest(request, approve: true),
            onReject: () => _respondToRequest(request, approve: false),
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
