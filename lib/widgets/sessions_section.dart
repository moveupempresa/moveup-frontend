import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/session.dart';

enum _SessionsViewMode { list, calendar }

class SessionsSection extends StatefulWidget {
  final List<Session> sessions;
  final Widget Function(Session session) cardBuilder;
  final String title;

  const SessionsSection({
    super.key,
    required this.sessions,
    required this.cardBuilder,
    this.title = 'Sesiones',
  });

  @override
  State<SessionsSection> createState() => SessionsSectionState();
}

class SessionsSectionState extends State<SessionsSection> {
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
              sessions.isEmpty
                  ? widget.title
                  : '${widget.title} (${sessions.length})',
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
