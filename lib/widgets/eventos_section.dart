import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/calendar_note.dart';
import '../models/event.dart';
import '../models/reservation.dart';
import 'event_card.dart';
import 'reservation_card.dart';

/// One event the user is either attending (has an upcoming reservation for
/// it) or has saved, merged so the same event never shows up twice.
class EventosItem {
  final Event event;
  final Reservation? reservation;

  const EventosItem({required this.event, this.reservation});

  bool get isAttending => reservation != null;
}

enum _ViewMode { list, calendar }

class EventosSection extends StatefulWidget {
  final List<EventosItem>? items;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final String emptyMessage;
  final void Function(EventosItem item) onItemTap;
  final void Function(Event event)? onOwnerTap;
  final Map<String, CalendarNote> notesByDate;
  final Future<void> Function(String date, String text) onSaveNote;
  final Future<void> Function(String date) onDeleteNote;

  const EventosSection({
    super.key,
    required this.items,
    this.isLoading = false,
    this.error,
    this.onRetry,
    required this.emptyMessage,
    required this.onItemTap,
    this.onOwnerTap,
    required this.notesByDate,
    required this.onSaveNote,
    required this.onDeleteNote,
  });

  @override
  State<EventosSection> createState() => _EventosSectionState();
}

class _EventosSectionState extends State<EventosSection> {
  _ViewMode _viewMode = _ViewMode.list;
  late DateTime _focusedDay = _initialFocusedDay;
  DateTime? _selectedDay;

  DateTime get _initialFocusedDay {
    final days = _allDayKeys(widget.items ?? []);
    if (days.isEmpty) return DateTime.now();
    return days.reduce((a, b) => a.isBefore(b) ? a : b);
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

  DateTime? _itemDayKey(EventosItem item) {
    final reservationDate = item.reservation?.sessionDate;
    if (reservationDate != null) return _dayKey(reservationDate);
    final sessions = item.event.sessions;
    if (sessions == null || sessions.isEmpty) return null;
    return _dayKey(sessions.first.startDatetime);
  }

  List<DateTime> _allDayKeys(List<EventosItem> items) =>
      items.map(_itemDayKey).whereType<DateTime>().toList();

  Map<DateTime, List<EventosItem>> _groupByDay(List<EventosItem> items) {
    final map = <DateTime, List<EventosItem>>{};
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
  DateTime _calendarFirstDay(List<EventosItem> items) {
    final base = DateTime.now().subtract(const Duration(days: 365));
    final days = _allDayKeys(items);
    if (days.isEmpty) return base;
    final earliest = days.reduce((a, b) => a.isBefore(b) ? a : b);
    return earliest.isBefore(base) ? earliest : base;
  }

  DateTime _calendarLastDay(List<EventosItem> items) {
    final base = DateTime.now().add(const Duration(days: 365 * 2));
    final days = _allDayKeys(items);
    if (days.isEmpty) return base;
    final latest = days.reduce((a, b) => a.isAfter(b) ? a : b);
    return latest.isAfter(base) ? latest : base;
  }

  Widget _cardFor(EventosItem item) {
    return item.isAttending
        ? ReservationCard(reservation: item.reservation!, onTap: () => widget.onItemTap(item))
        : EventCard(
            event: item.event,
            onTap: () => widget.onItemTap(item),
            onOwnerTap: widget.onOwnerTap == null ? null : () => widget.onOwnerTap!(item.event),
          );
  }

  @override
  Widget build(BuildContext context) {
    final showToggle = widget.error == null && !widget.isLoading && (widget.items ?? []).isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showToggle)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
              isSelected: [_viewMode == _ViewMode.list, _viewMode == _ViewMode.calendar],
              onPressed: (index) => setState(() {
                _viewMode = index == 0 ? _ViewMode.list : _ViewMode.calendar;
              }),
              children: const [
                Icon(Icons.view_list_outlined, size: 18),
                Icon(Icons.calendar_month_outlined, size: 18),
              ],
            ),
          ),
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.isLoading && widget.items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.error != null && widget.items == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          const Text('No se pudo cargar la información', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          if (widget.onRetry != null)
            Center(child: TextButton(onPressed: widget.onRetry, child: const Text('Reintentar'))),
        ],
      );
    }

    final items = widget.items ?? [];
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.event_busy_outlined, size: 40, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            widget.emptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      );
    }

    return _viewMode == _ViewMode.list ? _buildList(items) : _buildCalendar(context, items);
  }

  Widget _buildList(List<EventosItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _cardFor(items[index]),
    );
  }

  Widget _buildCalendar(BuildContext context, List<EventosItem> items) {
    final itemsByDay = _groupByDay(items);
    final selectedDay = _selectedDay ?? _calendarDayKey(_focusedDay);
    final selectedItems = itemsByDay[selectedDay] ?? const <EventosItem>[];
    final attendingColor = Theme.of(context).colorScheme.primary;
    final savedColor = Theme.of(context).colorScheme.tertiary;
    final noteColor = Theme.of(context).colorScheme.secondary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(attendingColor, 'Asistes'),
              const SizedBox(width: 16),
              _legendDot(savedColor, 'Guardado'),
              const SizedBox(width: 16),
              _legendDot(noteColor, 'Nota'),
            ],
          ),
        ),
        TableCalendar<EventosItem>(
          firstDay: _calendarFirstDay(items),
          lastDay: _calendarLastDay(items),
          focusedDay: _focusedDay,
          locale: 'es_ES',
          selectedDayPredicate: (day) => isSameDay(_selectedDay ?? _focusedDay, day),
          eventLoader: (day) => itemsByDay[_calendarDayKey(day)] ?? const <EventosItem>[],
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
          calendarBuilders: CalendarBuilders<EventosItem>(
            markerBuilder: (context, day, dayItems) {
              final hasAttending = dayItems.any((i) => i.isAttending);
              final hasSaved = dayItems.any((i) => !i.isAttending);
              final hasNote = widget.notesByDate.containsKey(_dateKey(day));
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
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: selectedItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Sin eventos este día',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: selectedItems.map(_cardFor).toList(),
                ),
        ),
        _buildNoteSection(context, selectedDay),
      ],
    );
  }

  Widget _buildNoteSection(BuildContext context, DateTime selectedDay) {
    final dateKey = _dateKey(selectedDay);
    final note = widget.notesByDate[dateKey];

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
                  onPressed: () => widget.onDeleteNote(dateKey),
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
      await widget.onSaveNote(dateKey, text);
    }
  }

  Widget _legendDot(Color color, String label) {
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
