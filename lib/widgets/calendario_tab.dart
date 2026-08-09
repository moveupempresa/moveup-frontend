import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/calendar_note.dart';
import '../models/event.dart';
import '../models/reservation.dart';
import '../services/auth_service.dart';
import '../services/calendar_note_service.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../screens/event_detail_screen.dart';
import '../screens/public_profile_screen.dart';
import 'event_card.dart';
import 'reservation_card.dart';

/// One event the user is either attending (has an upcoming reservation for
/// it) or has saved, merged so the same event never shows up twice.
class _CalendarItem {
  final Event event;
  final Reservation? reservation;

  const _CalendarItem({required this.event, this.reservation});

  bool get isAttending => reservation != null;
}

class CalendarioTab extends StatefulWidget {
  final String token;
  final String currentUserId;

  const CalendarioTab({super.key, required this.token, required this.currentUserId});

  @override
  State<CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends State<CalendarioTab> {
  List<Reservation>? _reservations;
  List<Event>? _savedEvents;
  List<CalendarNote>? _notes;
  bool _loading = false;
  String? _error;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, CalendarNote> get _notesByDate => {
        for (final n in _notes ?? <CalendarNote>[]) n.date: n,
      };

  List<_CalendarItem>? get _items {
    if (_reservations == null && _savedEvents == null) return null;

    final byEventId = <String, _CalendarItem>{};
    for (final r in (_reservations ?? []).where((r) => !r.isPast)) {
      final existing = byEventId[r.event.id];
      final existingDate = existing?.reservation?.sessionDate;
      final shouldReplace = existing == null ||
          (r.sessionDate != null && (existingDate == null || r.sessionDate!.isBefore(existingDate)));
      if (shouldReplace) byEventId[r.event.id] = _CalendarItem(event: r.event, reservation: r);
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
      ]);
      if (mounted) {
        setState(() {
          _reservations = results[0] as List<Reservation>;
          _savedEvents = results[1] as List<Event>;
          _notes = results[2] as List<CalendarNote>;
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

  DateTime? _itemDayKey(_CalendarItem item) {
    final reservationDate = item.reservation?.sessionDate;
    if (reservationDate != null) return _dayKey(reservationDate);
    final sessions = item.event.sessions;
    if (sessions == null || sessions.isEmpty) return null;
    return _dayKey(sessions.first.startDatetime);
  }

  List<DateTime> _allDayKeys(List<_CalendarItem> items) =>
      items.map(_itemDayKey).whereType<DateTime>().toList();

  Map<DateTime, List<_CalendarItem>> _groupByDay(List<_CalendarItem> items) {
    final map = <DateTime, List<_CalendarItem>>{};
    for (final item in items) {
      final day = _itemDayKey(item);
      if (day == null) continue;
      map.putIfAbsent(day, () => []).add(item);
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
        ? ReservationCard(reservation: item.reservation!, onTap: () => _openItem(item))
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
      final note = await CalendarNoteService.setNote(token: widget.token, date: date, text: text);
      if (mounted) {
        setState(() {
          _notes = [...?_notes?.where((n) => n.date != date), note];
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
          Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          const Text('No se pudo cargar la información', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: _loadAll, child: const Text('Reintentar'))),
        ],
      );
    }

    final items = _items ?? [];
    final itemsByDay = _groupByDay(items);
    final selectedDay = _selectedDay ?? _calendarDayKey(_focusedDay);
    final selectedItems = itemsByDay[selectedDay] ?? const <_CalendarItem>[];
    final attendingColor = Theme.of(context).colorScheme.primary;
    final savedColor = Theme.of(context).colorScheme.tertiary;
    final noteColor = Theme.of(context).colorScheme.secondary;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(context, attendingColor, 'Asistes'),
                const SizedBox(width: 16),
                _legendDot(context, savedColor, 'Guardado'),
                const SizedBox(width: 16),
                _legendDot(context, noteColor, 'Nota'),
              ],
            ),
          ),
          TableCalendar<_CalendarItem>(
            firstDay: _calendarFirstDay(items),
            lastDay: _calendarLastDay(items),
            focusedDay: _focusedDay,
            locale: 'es_ES',
            calendarFormat: _calendarFormat,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mes',
              CalendarFormat.week: 'Semana',
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            selectedDayPredicate: (day) => isSameDay(_selectedDay ?? _focusedDay, day),
            eventLoader: (day) => itemsByDay[_calendarDayKey(day)] ?? const <_CalendarItem>[],
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = _calendarDayKey(selected);
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(color: attendingColor, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders<_CalendarItem>(
              markerBuilder: (context, day, dayItems) {
                final hasAttending = dayItems.any((i) => i.isAttending);
                final hasSaved = dayItems.any((i) => !i.isAttending);
                final hasNote = _notesByDate.containsKey(_dateKey(day));
                if (!hasAttending && !hasSaved && !hasNote) return null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasAttending) _dot(attendingColor),
                      if (hasAttending && hasSaved) const SizedBox(width: 3),
                      if (hasSaved) _dot(savedColor),
                      if ((hasAttending || hasSaved) && hasNote) const SizedBox(width: 3),
                      if (hasNote) _dot(noteColor),
                    ],
                  ),
                );
              },
            ),
            headerStyle: const HeaderStyle(formatButtonShowsNext: false, titleCentered: true),
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

  Widget _buildNoteSection(BuildContext context, DateTime selectedDay) {
    final dateKey = _dateKey(selectedDay);
    final note = _notesByDate[dateKey];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  Icon(Icons.edit_note_outlined,
                      size: 18, color: Theme.of(context).colorScheme.outline),
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
                Icon(Icons.sticky_note_2_outlined,
                    size: 18, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(note.text, style: Theme.of(context).textTheme.bodySmall),
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

  Future<void> _editNote(BuildContext context, String dateKey, CalendarNote? existing) async {
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
          decoration: const InputDecoration(hintText: 'Escribe una nota para este día'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
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
