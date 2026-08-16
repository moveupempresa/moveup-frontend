import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../config/api_config.dart';
import '../models/event.dart';
import '../models/pack.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../widgets/video_player_view.dart';
import 'event_form_screen.dart';
import 'payment_screen.dart';
import 'public_profile_screen.dart';
import 'registrants_screen.dart';

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String _formatSessionDate(DateTime dt) {
  final local = dt.toLocal();
  return '${local.day} ${_months[local.month - 1]}. ${local.year}';
}

String _formatSessionTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final String token;
  final String currentUserId;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.token,
    required this.currentUserId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isDeleting = false;
  bool _isTogglingSave = false;
  late bool _isSaved = widget.event.isSaved;
  int _heroCoverPage = 0;

  List<Widget> _coverSlides(BuildContext context, Event event) {
    final slides = <Widget>[];
    if (event.coverImageUrl != null) {
      slides.add(
        Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Image.network(
            ApiConfig.mediaUrl(event.coverImageUrl!),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
      );
    }
    if (event.coverVideoUrl != null) {
      slides.add(
        VideoPlayerView(networkUrl: ApiConfig.mediaUrl(event.coverVideoUrl!)),
      );
    }
    return slides;
  }

  Widget _buildCoverCarousel(BuildContext context, Event event) {
    final slides = _coverSlides(context, event);
    if (slides.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_not_supported_outlined, size: 48),
      );
    }
    if (slides.length == 1) return slides.first;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView(
          onPageChanged: (i) => setState(() => _heroCoverPage = i),
          children: slides,
        ),
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              slides.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _heroCoverPage == i
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleSave() async {
    setState(() => _isTogglingSave = true);
    try {
      final isSaved = _isSaved
          ? await EventService.unsaveEvent(
              token: widget.token,
              eventId: widget.event.id,
            )
          : await EventService.saveEvent(
              token: widget.token,
              eventId: widget.event.id,
            );
      if (mounted) setState(() => _isSaved = isSaved);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isTogglingSave = false);
    }
  }

  Future<void> _editEvent() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EventFormScreen(token: widget.token, event: widget.event),
      ),
    );
    if (changed == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar evento?'),
        content: Text(
          'Se eliminará "${widget.event.title}" junto con sus sesiones y packs. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await EventService.deleteEvent(
        token: widget.token,
        eventId: widget.event.id,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
        setState(() => _isDeleting = false);
      }
    }
  }

  Widget _buildSessionCard(Session s, String eventId, bool isOwner) {
    final card = _SessionCard(
      session: s,
      token: widget.token,
      eventId: eventId,
      isOwner: isOwner,
    );
    if (!isOwner) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegistrantsScreen(
            token: widget.token,
            currentUserId: widget.currentUserId,
            eventId: eventId,
            targetType: RegistrantsTargetType.session,
            targetId: s.id,
            targetName: s.name,
          ),
        ),
      ),
      child: card,
    );
  }

  Widget _buildPackCard(
    Pack p,
    String eventId,
    List<Session> sessions,
    bool isOwner,
  ) {
    final card = _PackCard(
      pack: p,
      sessions: sessions,
      token: widget.token,
      eventId: eventId,
      isOwner: isOwner,
    );
    if (!isOwner) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegistrantsScreen(
            token: widget.token,
            currentUserId: widget.currentUserId,
            eventId: eventId,
            targetType: RegistrantsTargetType.pack,
            targetId: p.id,
            targetName: p.name,
            sessions: sessions,
            paymentType: p.paymentType,
          ),
        ),
      ),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final sessions = event.sessions ?? [];
    final packs = event.packs ?? [];
    final isOwner = event.ownerUserId == widget.currentUserId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildCoverCarousel(context, event),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isOwner)
                      IconButton(
                        icon: _isTogglingSave
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_outline,
                              ),
                        tooltip: _isSaved
                            ? 'Quitar de guardados'
                            : 'Guardar evento',
                        onPressed: _isTogglingSave ? null : _toggleSave,
                      ),
                    if (isOwner) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar evento',
                        onPressed: _isDeleting ? null : _editEvent,
                      ),
                      IconButton(
                        icon: _isDeleting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar evento',
                        onPressed: _isDeleting ? null : _deleteEvent,
                      ),
                    ],
                  ],
                ),
                if (!isOwner && event.organizerName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          token: widget.token,
                          userId: event.ownerUserId,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Organizado por ${event.organizerName}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.place_outlined,
                  text: [
                    event.city,
                    event.country,
                  ].where((s) => s.isNotEmpty).join(', '),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.category_outlined,
                  text: event.eventTypeLabel,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: event.locationType == LocationType.online
                      ? Icons.videocam_outlined
                      : Icons.location_on_outlined,
                  text: event.locationType.label,
                ),
                const SizedBox(height: 20),
                if (event.description.isNotEmpty) ...[
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                ],
                if (event.style.isNotEmpty) ...[
                  Text(
                    'Estilos',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: event.style
                        .map(
                          (s) => Chip(
                            label: Text(s),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                if (isOwner || packs.isEmpty) ...[
                  _SessionsSection(
                    sessions: sessions,
                    cardBuilder: (s) => _buildSessionCard(s, event.id, isOwner),
                  ),
                ],
                if (event.reservationEnabled) ...[
                  const SizedBox(height: 20),
                  Text('Packs', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (packs.isEmpty)
                    Text(
                      'Sin packs',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    ...packs.map(
                      (p) => _buildPackCard(p, event.id, sessions, isOwner),
                    ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

enum _SessionsViewMode { list, calendar }

class _SessionsSection extends StatefulWidget {
  final List<Session> sessions;
  final Widget Function(Session session) cardBuilder;

  const _SessionsSection({required this.sessions, required this.cardBuilder});

  @override
  State<_SessionsSection> createState() => _SessionsSectionState();
}

class _SessionsSectionState extends State<_SessionsSection> {
  _SessionsViewMode _viewMode = _SessionsViewMode.list;
  late DateTime _focusedDay = _initialFocusedDay;
  DateTime? _selectedDay;

  DateTime get _initialFocusedDay {
    if (widget.sessions.isEmpty) return DateTime.now();
    final sorted = [...widget.sessions]
      ..sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
    return _dayKey(sorted.first.startDatetime);
  }

  // table_calendar requires firstDay <= focusedDay <= lastDay, so the range
  // must stretch to cover every session's date, not just a fixed window
  // around today.
  DateTime get _calendarFirstDay {
    final base = DateTime.now().subtract(const Duration(days: 365));
    if (widget.sessions.isEmpty) return base;
    final earliest = widget.sessions
        .map((s) => _dayKey(s.startDatetime))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return earliest.isBefore(base) ? earliest : base;
  }

  DateTime get _calendarLastDay {
    final base = DateTime.now().add(const Duration(days: 365 * 2));
    if (widget.sessions.isEmpty) return base;
    final latest = widget.sessions
        .map((s) => _dayKey(s.startDatetime))
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return latest.isAfter(base) ? latest : base;
  }

  // Real timestamps carry a timezone offset, so convert to local time before
  // taking the calendar day.
  DateTime _dayKey(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  // table_calendar hands back day-only values normalized to UTC; converting
  // those with .toLocal() can shift them onto the wrong calendar day, so just
  // read the y/m/d fields directly instead.
  DateTime _calendarDayKey(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Map<DateTime, List<Session>> _groupByDay(List<Session> sessions) {
    final map = <DateTime, List<Session>>{};
    for (final s in sessions) {
      map.putIfAbsent(_dayKey(s.startDatetime), () => []).add(s);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final sessions = widget.sessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              sessions.isEmpty ? 'Sesiones' : 'Sesiones (${sessions.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            if (sessions.isNotEmpty)
              ToggleButtons(
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
                isSelected: [
                  _viewMode == _SessionsViewMode.list,
                  _viewMode == _SessionsViewMode.calendar,
                ],
                onPressed: (index) => setState(() {
                  _viewMode = index == 0
                      ? _SessionsViewMode.list
                      : _SessionsViewMode.calendar;
                }),
                children: const [
                  Icon(Icons.view_list_outlined, size: 16),
                  Icon(Icons.calendar_month_outlined, size: 16),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (sessions.isEmpty)
          Text(
            'Sin sesiones',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          )
        else if (_viewMode == _SessionsViewMode.list)
          _buildList(sessions)
        else
          _buildCalendar(context, sessions),
      ],
    );
  }

  Widget _buildList(List<Session> sessions) {
    if (sessions.length > 3) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: const Text('Ver sesiones'),
          children: sessions.map(widget.cardBuilder).toList(),
        ),
      );
    }
    return Column(children: sessions.map(widget.cardBuilder).toList());
  }

  Widget _buildCalendar(BuildContext context, List<Session> sessions) {
    final sessionsByDay = _groupByDay(sessions);
    final selectedDay = _selectedDay ?? _calendarDayKey(_focusedDay);
    final selectedSessions = sessionsByDay[selectedDay] ?? const <Session>[];

    return Column(
      children: [
        TableCalendar<Session>(
          firstDay: _calendarFirstDay,
          lastDay: _calendarLastDay,
          focusedDay: _focusedDay,
          locale: 'es_ES',
          selectedDayPredicate: (day) =>
              isSameDay(_selectedDay ?? _focusedDay, day),
          eventLoader: (day) =>
              sessionsByDay[_calendarDayKey(day)] ?? const <Session>[],
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = _calendarDayKey(selected);
              _focusedDay = focused;
            });
          },
          onPageChanged: (focused) => _focusedDay = focused,
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 12),
        if (selectedSessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Sin sesiones este día',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          )
        else
          Column(children: selectedSessions.map(widget.cardBuilder).toList()),
      ],
    );
  }
}

class _SessionCard extends StatefulWidget {
  final Session session;
  final String token;
  final String eventId;
  final bool isOwner;

  const _SessionCard({
    required this.session,
    required this.token,
    required this.eventId,
    required this.isOwner,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  late int _confirmedCount = widget.session.confirmedCount;
  late bool _isSignedUp = widget.session.isSignedUp;
  late bool _isWaitlisted = widget.session.isWaitlisted;
  bool _isLoading = false;

  bool get _isFull =>
      !widget.session.isUnlimitedCapacity &&
      widget.session.capacity != null &&
      _confirmedCount >= widget.session.capacity!;

  void _showError(Object e) {
    if (e is AuthException && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggleSignUp() async {
    setState(() => _isLoading = true);
    try {
      final (status, count) = _isSignedUp
          ? await RegistrationService.cancelSessionSignUp(
              token: widget.token,
              eventId: widget.eventId,
              sessionId: widget.session.id,
            )
          : await RegistrationService.signUpForSession(
              token: widget.token,
              eventId: widget.eventId,
              sessionId: widget.session.id,
            );
      if (mounted) {
        setState(() {
          _isSignedUp = status == 'confirmed';
          _confirmedCount = count;
        });
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWaitlist() async {
    setState(() => _isLoading = true);
    try {
      final (status, count) = _isWaitlisted
          ? await RegistrationService.leaveSessionWaitlist(
              token: widget.token,
              eventId: widget.eventId,
              sessionId: widget.session.id,
            )
          : await RegistrationService.joinSessionWaitlist(
              token: widget.token,
              eventId: widget.eventId,
              sessionId: widget.session.id,
            );
      if (mounted) {
        setState(() {
          _isWaitlisted = status == 'waitlisted';
          _confirmedCount = count;
        });
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final start = session.startDatetime.toLocal();
    final end = session.endDatetime.toLocal();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, widget.isOwner ? 14 : 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        session.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (!session.isUnlimitedCapacity &&
                        session.capacity != null) ...[
                      const SizedBox(width: 8),
                      _CapacityBadge(
                        confirmedCount: _confirmedCount,
                        capacity: session.capacity!,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formatSessionDate(start),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatSessionTime(start)} – ${_formatSessionTime(end)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (session.address != null && session.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          session.address!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      session.isUnlimitedCapacity
                          ? 'Aforo ilimitado'
                          : session.capacity != null
                          ? '$_confirmedCount / ${session.capacity} personas'
                          : 'Aforo no especificado',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!widget.isOwner)
            Positioned(
              right: 4,
              bottom: 4,
              child: _SignupIconButton(
                isFull: _isFull,
                isSignedUp: _isSignedUp,
                isWaitlisted: _isWaitlisted,
                isLoading: _isLoading,
                onToggleSignUp: _toggleSignUp,
                onToggleWaitlist: _toggleWaitlist,
              ),
            ),
        ],
      ),
    );
  }
}

class _CapacityBadge extends StatelessWidget {
  final int confirmedCount;
  final int capacity;

  const _CapacityBadge({required this.confirmedCount, required this.capacity});

  @override
  Widget build(BuildContext context) {
    final ratio = capacity == 0 ? 1.0 : confirmedCount / capacity;
    final Color color;
    if (ratio >= 1.0) {
      color = Colors.red.shade700;
    } else if (ratio >= 0.7) {
      color = Colors.amber.shade800;
    } else {
      color = Colors.green.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$confirmedCount/$capacity',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SignupIconButton extends StatelessWidget {
  final bool isFull;
  final bool isSignedUp;
  final bool isWaitlisted;
  final bool isPending;
  final bool isAwaitingPayment;
  final bool isLoading;
  final bool isExpandable;
  final bool isExpanded;
  final VoidCallback onToggleSignUp;
  final VoidCallback onToggleWaitlist;

  const _SignupIconButton({
    required this.isFull,
    required this.isSignedUp,
    required this.isWaitlisted,
    this.isPending = false,
    this.isAwaitingPayment = false,
    required this.isLoading,
    this.isExpandable = false,
    this.isExpanded = false,
    required this.onToggleSignUp,
    required this.onToggleWaitlist,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (isPending) {
      return IconButton(
        icon: Icon(
          Icons.hourglass_top,
          color: Theme.of(context).colorScheme.primary,
        ),
        tooltip: 'Solicitud pendiente de aprobación · toca para cancelar',
        onPressed: onToggleSignUp,
      );
    }
    if (isAwaitingPayment) {
      return IconButton(
        icon: Icon(Icons.hourglass_bottom, color: Colors.amber.shade800),
        tooltip: 'Esperando tu pago · toca para cancelar',
        onPressed: onToggleSignUp,
      );
    }
    if (isFull && !isSignedUp) {
      return IconButton(
        icon: Icon(
          isWaitlisted ? Icons.notifications_active : Icons.notifications_none,
        ),
        color: isWaitlisted ? Theme.of(context).colorScheme.primary : null,
        tooltip: isWaitlisted
            ? 'Cancelar aviso de disponibilidad'
            : 'Avisarme si hay un cupo disponible',
        onPressed: onToggleWaitlist,
      );
    }
    if (isExpandable && !isSignedUp) {
      return IconButton(
        icon: Icon(isExpanded ? Icons.expand_less : Icons.checklist),
        color: isExpanded ? Theme.of(context).colorScheme.primary : null,
        tooltip: isExpanded ? 'Ocultar sesiones' : 'Elegir sesiones',
        onPressed: onToggleSignUp,
      );
    }
    return IconButton(
      icon: Icon(isSignedUp ? Icons.check_circle : Icons.check_circle_outline),
      color: isSignedUp ? Theme.of(context).colorScheme.primary : null,
      tooltip: isSignedUp ? 'Cancelar inscripción' : 'Inscribirme',
      onPressed: onToggleSignUp,
    );
  }
}

class _PackCard extends StatefulWidget {
  final Pack pack;
  final List<Session> sessions;
  final String token;
  final String eventId;
  final bool isOwner;

  const _PackCard({
    required this.pack,
    required this.sessions,
    required this.token,
    required this.eventId,
    required this.isOwner,
  });

  @override
  State<_PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<_PackCard> {
  late int _confirmedCount = widget.pack.confirmedCount;
  late bool _isSignedUp = widget.pack.isSignedUp;
  late bool _isPending = widget.pack.isPending;
  late bool _isAwaitingPayment = widget.pack.isAwaitingPayment;
  late final Set<String> _selectedSessionIds = widget.pack.mySelectedSessionIds
      .toSet();
  bool _isLoading = false;
  bool _isExpanded = false;

  bool get _isCommitted => _isSignedUp || _isPending || _isAwaitingPayment;

  bool get _selectionValid {
    if (_selectedSessionIds.isEmpty) return false;
    final max = widget.pack.maxSelectableSessions;
    return max == null || _selectedSessionIds.length <= max;
  }

  void _onSessionToggled(String sessionId, bool checked) {
    setState(() {
      if (checked) {
        _selectedSessionIds.add(sessionId);
      } else {
        _selectedSessionIds.remove(sessionId);
      }
    });
  }

  void _showError(Object e) {
    if (e is AuthException && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  bool get _isCustomizable => widget.pack.packType == PackType.customizable;

  bool get _isPaymentReady => _isAwaitingPayment || _isSignedUp;

  void _onPaymentIconTap() {
    if (_isSignedUp) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ya has pagado este pack')));
      return;
    }
    if (!_isPaymentReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando aprobación del organizador')),
      );
      return;
    }
    widget.pack.paymentType == PaymentType.online
        ? _openPayment()
        : _showManualPaymentMessage();
  }

  void _openPayment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          token: widget.token,
          eventId: widget.eventId,
          packId: widget.pack.id,
          packName: widget.pack.name,
        ),
      ),
    );
  }

  IconData _paymentIcon(PaymentType type) => switch (type) {
    PaymentType.online => Icons.credit_card,
    PaymentType.offline => Icons.money,
    PaymentType.bizum => Icons.phone_android,
    PaymentType.paypal => Icons.account_balance_wallet,
  };

  String _paymentTooltip(PaymentType type) => switch (type) {
    PaymentType.online => 'Pagar con tarjeta',
    PaymentType.offline => 'Pago en efectivo',
    PaymentType.bizum => 'Pago por Bizum',
    PaymentType.paypal => 'Pago por PayPal',
  };

  void _showManualPaymentMessage() {
    final pack = widget.pack;
    final details = pack.paymentDetails;
    final hasDetails = details != null && details.isNotEmpty;
    final message = switch (pack.paymentType) {
      PaymentType.offline => 'El pago de este pack es en efectivo',
      PaymentType.bizum =>
        hasDetails
            ? 'Paga por Bizum al número $details'
            : 'El pago de este pack es por Bizum',
      PaymentType.paypal =>
        hasDetails
            ? 'Paga por PayPal a $details'
            : 'El pago de este pack es por PayPal',
      PaymentType.online => '',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleSignUp() async {
    if (_isCommitted) {
      setState(() => _isLoading = true);
      try {
        final (status, count) = await RegistrationService.cancelPackSignUp(
          token: widget.token,
          eventId: widget.eventId,
          packId: widget.pack.id,
        );
        if (mounted) {
          setState(() {
            _isSignedUp = status == 'confirmed';
            _isPending = status == 'pending';
            _isAwaitingPayment = status == 'awaiting_payment';
            _confirmedCount = count;
            _isExpanded = false;
          });
        }
      } catch (e) {
        _showError(e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    if (_isCustomizable) {
      setState(() => _isExpanded = !_isExpanded);
      return;
    }

    await _confirmSignUp();
  }

  Future<void> _confirmSignUp() async {
    if (_isCustomizable && !_selectionValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.pack.maxSelectableSessions != null
                ? 'Selecciona entre 1 y ${widget.pack.maxSelectableSessions} sesiones'
                : 'Selecciona al menos una sesión',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final (status, count) = await RegistrationService.signUpForPack(
        token: widget.token,
        eventId: widget.eventId,
        packId: widget.pack.id,
        selectedSessionIds: _isCustomizable
            ? _selectedSessionIds.toList()
            : null,
      );
      if (mounted) {
        setState(() {
          _isSignedUp = status == 'confirmed';
          _isPending = status == 'pending';
          _isAwaitingPayment = status == 'awaiting_payment';
          _confirmedCount = count;
        });
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;
    final priceLabel =
        '${pack.price.toStringAsFixed(2)} · ${pack.paymentType.label}';

    final includedSessionNames = pack.sessionIds
        .map((id) => widget.sessions.where((s) => s.id == id).firstOrNull?.name)
        .whereType<String>()
        .toList();
    final candidateSessions = pack.sessionIds
        .map((id) => widget.sessions.where((s) => s.id == id).firstOrNull)
        .whereType<Session>()
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, widget.isOwner ? 14 : 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pack.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      priceLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      pack.packType.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$_confirmedCount inscritos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.rule_outlined, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Aprobación ${pack.approvalMode.label.toLowerCase()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (pack.packType == PackType.customizable) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event_available_outlined, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        pack.maxSelectableSessions != null
                            ? 'Elige hasta ${pack.maxSelectableSessions} sesiones'
                            : 'Elige tus sesiones',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (widget.isOwner && candidateSessions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            candidateSessions.map((s) => s.name).join(', '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!widget.isOwner && _isCommitted)
                    ...candidateSessions
                        .where((s) => _selectedSessionIds.contains(s.id))
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(left: 20, top: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s.name,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                  if (!widget.isOwner && !_isCommitted && _isExpanded) ...[
                    ...candidateSessions.map(
                      (s) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _selectedSessionIds.contains(s.id),
                        title: Text(
                          s.name,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            _formatSessionDate(s.startDatetime),
                            '${_formatSessionTime(s.startDatetime)} – ${_formatSessionTime(s.endDatetime)}',
                            if (s.address != null && s.address!.isNotEmpty)
                              s.address!,
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        onChanged: (checked) =>
                            _onSessionToggled(s.id, checked ?? false),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _confirmSignUp,
                        child: const Text('Confirmar inscripción'),
                      ),
                    ),
                  ],
                ],
                if (pack.packType == PackType.fixed &&
                    includedSessionNames.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          includedSessionNames.join(', '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!widget.isOwner)
            Positioned(
              right: 4,
              bottom: 4,
              child: _SignupIconButton(
                isFull: false,
                isSignedUp: _isSignedUp,
                isWaitlisted: false,
                isPending: _isPending,
                isAwaitingPayment: _isAwaitingPayment,
                isLoading: _isLoading,
                isExpandable: _isCustomizable,
                isExpanded: _isExpanded,
                onToggleSignUp: _toggleSignUp,
                onToggleWaitlist: () {},
              ),
            ),
          if (!widget.isOwner)
            Positioned(
              left: 4,
              bottom: 4,
              child: IconButton(
                icon: Icon(_paymentIcon(pack.paymentType)),
                color: _isPaymentReady ? Colors.green.shade700 : Colors.grey,
                tooltip: _paymentTooltip(pack.paymentType),
                onPressed: _onPaymentIconTap,
              ),
            ),
          if (widget.isOwner && pack.pendingRequestsCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Tooltip(
                message: pack.pendingRequestsCount == 1
                    ? '1 solicitud pendiente de aprobación'
                    : '${pack.pendingRequestsCount} solicitudes pendientes de aprobación',
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
