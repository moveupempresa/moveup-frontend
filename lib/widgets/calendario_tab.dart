import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/calendar_note.dart';
import '../models/event.dart';
import '../models/reservation.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/calendar_note_service.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../screens/event_detail_screen.dart';
import '../screens/public_profile_screen.dart';
import 'event_card.dart';
import 'reservation_card.dart';

/// One event the user is either attending (has an upcoming reservation for
/// it), organizes, or has saved, merged so the same event never shows up
/// twice.
class _CalendarItem {
  final Event event;
  final Reservation? reservation;
  final bool isOwned;

  const _CalendarItem({
    required this.event,
    this.reservation,
    this.isOwned = false,
  });

  bool get isAttending => reservation != null;
}

const _hourHeight = 60.0;
const _weekdayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

class CalendarioTab extends StatefulWidget {
  final String token;
  final String currentUserId;
  final bool isPro;

  const CalendarioTab({
    super.key,
    required this.token,
    required this.currentUserId,
    required this.isPro,
  });

  @override
  State<CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends State<CalendarioTab> {
  List<Reservation>? _reservations;
  List<Event>? _savedEvents;
  List<Event>? _createdEvents;
  List<CalendarNote>? _notes;
  bool _loading = false;
  String? _error;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _weekScrollController = ScrollController(
    initialScrollOffset: 7 * _hourHeight,
  );

  Map<String, CalendarNote> get _notesByDate => {
    for (final n in _notes ?? <CalendarNote>[]) n.date: n,
  };

  List<_CalendarItem>? get _items {
    if (_reservations == null &&
        _savedEvents == null &&
        _createdEvents == null) {
      return null;
    }

    final byEventId = <String, _CalendarItem>{};
    for (final r in (_reservations ?? []).where((r) => !r.isPast)) {
      final existing = byEventId[r.event.id];
      final existingDate = existing?.reservation?.sessionDate;
      final shouldReplace =
          existing == null ||
          (r.sessionDate != null &&
              (existingDate == null || r.sessionDate!.isBefore(existingDate)));
      if (shouldReplace) {
        byEventId[r.event.id] = _CalendarItem(event: r.event, reservation: r);
      }
    }
    for (final e in (_createdEvents ?? [])) {
      byEventId.putIfAbsent(e.id, () => _CalendarItem(event: e, isOwned: true));
    }
    for (final e in (_savedEvents ?? [])) {
      byEventId.putIfAbsent(e.id, () => _CalendarItem(event: e));
    }
    return byEventId.values.toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _weekScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        RegistrationService.getMyReservations(token: widget.token),
        EventService.getPublicEvents(token: widget.token, savedOnly: true),
        CalendarNoteService.getMyNotes(token: widget.token),
        widget.isPro
            ? EventService.getMyEvents(token: widget.token)
            : Future.value(<Event>[]),
      ]);
      if (mounted) {
        setState(() {
          _reservations = results[0] as List<Reservation>;
          _savedEvents = results[1] as List<Event>;
          _notes = results[2] as List<CalendarNote>;
          _createdEvents = results[3] as List<Event>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  // The plain 'YYYY-MM-DD' key the backend uses to identify a personal note.
  String _dateKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  // A reservation targets one specific session/pack occurrence, so it only
  // occupies its one sessionDate. An owned or saved event isn't scoped to a
  // single session though - it should appear on every day it runs, not just
  // its first one.
  List<DateTime> _itemDayKeys(_CalendarItem item) {
    final reservationDate = item.reservation?.sessionDate;
    if (reservationDate != null) return [_dayKey(reservationDate)];
    final sessions = item.event.sessions;
    if (sessions == null || sessions.isEmpty) return const [];
    return sessions.map((s) => _dayKey(s.startDatetime)).toSet().toList();
  }

  // Every session (with a start/end time) this item occupies on the given
  // day, used to position its blocks in the week scheduler. An event can run
  // more than once on the same day (e.g. a morning and an afternoon slot), so
  // this returns all of them rather than just the first match. A
  // session-type reservation is narrowed to the exact session it targets,
  // since other same-day sessions of that event aren't what the user booked.
  List<Session> _sessionsForDay(_CalendarItem item, DateTime day) {
    final sessions = item.event.sessions;
    if (sessions == null) return const [];
    final dayMatches = sessions.where((s) => _dayKey(s.startDatetime) == day);
    final reservation = item.reservation;
    if (reservation != null && reservation.targetType == 'session') {
      return dayMatches.where((s) => s.id == reservation.targetId).toList();
    }
    return dayMatches.toList();
  }

  List<DateTime> _allDayKeys(List<_CalendarItem> items) =>
      items.expand(_itemDayKeys).toList();

  Map<DateTime, List<_CalendarItem>> _groupByDay(List<_CalendarItem> items) {
    final map = <DateTime, List<_CalendarItem>>{};
    for (final item in items) {
      for (final day in _itemDayKeys(item)) {
        map.putIfAbsent(day, () => []).add(item);
      }
    }
    return map;
  }

  // table_calendar requires firstDay <= focusedDay <= lastDay, so the range
  // must stretch to cover every item's date, not just a fixed window around
  // today.
  DateTime _calendarFirstDay(List<_CalendarItem> items) {
    final base = DateTime.now().subtract(const Duration(days: 365));
    final days = _allDayKeys(items);
    if (days.isEmpty) return base;
    final earliest = days.reduce((a, b) => a.isBefore(b) ? a : b);
    return earliest.isBefore(base) ? earliest : base;
  }

  DateTime _calendarLastDay(List<_CalendarItem> items) {
    final base = DateTime.now().add(const Duration(days: 365 * 2));
    final days = _allDayKeys(items);
    if (days.isEmpty) return base;
    final latest = days.reduce((a, b) => a.isAfter(b) ? a : b);
    return latest.isAfter(base) ? latest : base;
  }

  Widget _cardFor(_CalendarItem item) {
    return item.isAttending
        ? ReservationCard(
            reservation: item.reservation!,
            onTap: () => _openItem(item),
          )
        : EventCard(
            event: item.event,
            onTap: () => _openItem(item),
            onOwnerTap: () => _openOwnerProfile(item.event),
          );
  }

  Future<void> _openItem(_CalendarItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          token: widget.token,
          event: item.event,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
    _loadAll();
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

  Future<void> _saveNote(String date, String text) async {
    try {
      final note = await CalendarNoteService.setNote(
        token: widget.token,
        date: date,
        text: text,
      );
      if (mounted) {
        setState(() {
          _notes = [...?_notes?.where((n) => n.date != date), note];
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteNote(String date) async {
    try {
      await CalendarNoteService.deleteNote(token: widget.token, date: date);
      if (mounted) {
        setState(() => _notes = _notes?.where((n) => n.date != date).toList());
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items == null) {
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
              onPressed: _loadAll,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    final items = _items ?? [];
    final itemsByDay = _groupByDay(items);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<CalendarFormat>(
            segments: const [
              ButtonSegment(value: CalendarFormat.month, label: Text('Mes')),
              ButtonSegment(value: CalendarFormat.week, label: Text('Semana')),
            ],
            selected: {_calendarFormat},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _calendarFormat = selection.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 4,
            children: [
              _legendDot(
                context,
                Theme.of(context).colorScheme.primary,
                'Asistes',
              ),
              _legendDot(
                context,
                Theme.of(context).colorScheme.error,
                'Tus eventos',
              ),
              _legendDot(
                context,
                Theme.of(context).colorScheme.tertiary,
                'Guardado',
              ),
              _legendDot(
                context,
                Theme.of(context).colorScheme.secondary,
                'Nota',
              ),
            ],
          ),
        ),
        Expanded(
          child: _calendarFormat == CalendarFormat.month
              ? _buildMonthView(context, items, itemsByDay)
              : _buildWeekView(context, itemsByDay),
        ),
      ],
    );
  }

  Widget _buildMonthView(
    BuildContext context,
    List<_CalendarItem> items,
    Map<DateTime, List<_CalendarItem>> itemsByDay,
  ) {
    final selectedDay = _selectedDay ?? _calendarDayKey(_focusedDay);
    final selectedItems = itemsByDay[selectedDay] ?? const <_CalendarItem>[];
    final attendingColor = Theme.of(context).colorScheme.primary;
    final ownedColor = Theme.of(context).colorScheme.error;
    final savedColor = Theme.of(context).colorScheme.tertiary;
    final noteColor = Theme.of(context).colorScheme.secondary;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        children: [
          TableCalendar<_CalendarItem>(
            firstDay: _calendarFirstDay(items),
            lastDay: _calendarLastDay(items),
            focusedDay: _focusedDay,
            locale: 'es_ES',
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) =>
                isSameDay(_selectedDay ?? _focusedDay, day),
            eventLoader: (day) =>
                itemsByDay[_calendarDayKey(day)] ?? const <_CalendarItem>[],
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = _calendarDayKey(selected);
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: attendingColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders<_CalendarItem>(
              markerBuilder: (context, day, dayItems) {
                final hasAttending = dayItems.any((i) => i.isAttending);
                final hasOwned = dayItems.any((i) => i.isOwned);
                final hasSaved = dayItems.any(
                  (i) => !i.isAttending && !i.isOwned,
                );
                final hasNote = _notesByDate.containsKey(_dateKey(day));
                final dots = [
                  if (hasAttending) attendingColor,
                  if (hasOwned) ownedColor,
                  if (hasSaved) savedColor,
                  if (hasNote) noteColor,
                ];
                if (dots.isEmpty) return null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < dots.length; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        _dot(dots[i]),
                      ],
                    ],
                  ),
                );
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 12),
          if (selectedItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Sin eventos este día',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: selectedItems.map(_cardFor).toList()),
            ),
          _buildNoteSection(context, selectedDay),
        ],
      ),
    );
  }

  // Calendar-day arithmetic, not elapsed-time arithmetic: constructing a
  // DateTime from y/m/d fields (rather than adding a Duration) keeps this
  // correct across DST transitions, which Spain observes.
  DateTime _addDays(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);

  DateTime _weekStartFor(DateTime day) => _addDays(day, -(day.weekday - 1));

  Widget _buildWeekView(
    BuildContext context,
    Map<DateTime, List<_CalendarItem>> itemsByDay,
  ) {
    final weekStart = _weekStartFor(_calendarDayKey(_focusedDay));
    final weekDays = List.generate(7, (i) => _addDays(weekStart, i));
    final today = _calendarDayKey(DateTime.now());
    final selectedDay = _selectedDay ?? today;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: Column(
        children: [
          _buildWeekNavHeader(context, weekStart),
          _buildWeekDayHeader(context, weekDays, today),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: _weekScrollController,
              child: SizedBox(
                height: 24 * _hourHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHourLabels(context),
                    Expanded(
                      child: Row(
                        children: weekDays
                            .map(
                              (day) => Expanded(
                                child: _buildDayColumn(
                                  context,
                                  day,
                                  today,
                                  itemsByDay,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildNoteSection(context, selectedDay),
        ],
      ),
    );
  }

  Widget _buildWeekNavHeader(BuildContext context, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    const months = [
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
    final label = weekStart.month == weekEnd.month
        ? '${weekStart.day} - ${weekEnd.day} ${months[weekStart.month - 1]}. ${weekEnd.year}'
        : '${weekStart.day} ${months[weekStart.month - 1]}. - ${weekEnd.day} ${months[weekEnd.month - 1]}. ${weekEnd.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Semana anterior',
            onPressed: () =>
                setState(() => _focusedDay = _addDays(_focusedDay, -7)),
          ),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Semana siguiente',
            onPressed: () =>
                setState(() => _focusedDay = _addDays(_focusedDay, 7)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayHeader(
    BuildContext context,
    List<DateTime> weekDays,
    DateTime today,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 4, bottom: 4),
      child: Row(
        children: weekDays.map((day) {
          final isToday = day == today;
          final isSelected = day == (_selectedDay ?? today);
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedDay = day),
              child: Column(
                children: [
                  Text(
                    _weekdayLabels[day.weekday - 1],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : isToday
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHourLabels(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 24 * _hourHeight,
      child: Stack(
        children: List.generate(24, (hour) {
          return Positioned(
            // Centering each label on its gridline pushes hour 0 above the
            // top edge, where it gets clipped - keep it non-negative.
            top: (hour * _hourHeight - 8).clamp(0.0, 24 * _hourHeight - 16),
            right: 4,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(
    BuildContext context,
    DateTime day,
    DateTime today,
    Map<DateTime, List<_CalendarItem>> itemsByDay,
  ) {
    final dayItems = itemsByDay[day] ?? const <_CalendarItem>[];
    final attendingColor = Theme.of(context).colorScheme.primary;
    final ownedColor = Theme.of(context).colorScheme.error;
    final savedColor = Theme.of(context).colorScheme.tertiary;

    Color blockColor(_CalendarItem item) {
      if (item.isAttending) return attendingColor;
      if (item.isOwned) return ownedColor;
      return savedColor;
    }

    Color blockTextColor(_CalendarItem item) {
      final scheme = Theme.of(context).colorScheme;
      if (item.isAttending) return scheme.onPrimary;
      if (item.isOwned) return scheme.onError;
      return scheme.onTertiary;
    }

    final blocks = <Widget>[];
    for (final item in dayItems) {
      for (final session in _sessionsForDay(item, day)) {
        final start = session.startDatetime.toLocal();
        final end = session.endDatetime.toLocal();
        final top = (start.hour * 60 + start.minute) / 60 * _hourHeight;
        final durationMinutes = end.difference(start).inMinutes;
        final height = (durationMinutes / 60 * _hourHeight).clamp(
          28.0,
          24 * _hourHeight,
        );

        blocks.add(
          Positioned(
            top: top,
            left: 2,
            right: 2,
            height: height,
            child: InkWell(
              onTap: () => _openItem(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: blockColor(item).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.event.title,
                  maxLines: height > 40 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: blockTextColor(item)),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: List.generate(
              24,
              (hour) => Container(
                height: _hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (day == today) _buildNowIndicator(context),
          ...blocks,
        ],
      ),
    );
  }

  Widget _buildNowIndicator(BuildContext context) {
    final now = DateTime.now();
    final top = (now.hour * 60 + now.minute) / 60 * _hourHeight;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Container(height: 2, color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _buildNoteSection(BuildContext context, DateTime selectedDay) {
    final dateKey = _dateKey(selectedDay);
    final note = _notesByDate[dateKey];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: note == null
          ? InkWell(
              onTap: () => _editNote(context, dateKey, null),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Añadir nota',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      note.text,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Editar nota',
                  onPressed: () => _editNote(context, dateKey, note),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Eliminar nota',
                  onPressed: () => _deleteNote(dateKey),
                ),
              ],
            ),
    );
  }

  Future<void> _editNote(
    BuildContext context,
    String dateKey,
    CalendarNote? existing,
  ) async {
    final controller = TextEditingController(text: existing?.text ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nota'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: 'Escribe una nota para este día',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (text != null && text.isNotEmpty) {
      await _saveNote(dateKey, text);
    }
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _dot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
