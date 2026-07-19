import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/event.dart';
import 'event_card.dart';

enum _ViewMode { list, calendar }

class ProfileEventsSection extends StatefulWidget {
  final List<Event>? events;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget? lockedBanner;
  final String emptyMessage;
  final void Function(Event event) onEventTap;

  const ProfileEventsSection({
    super.key,
    required this.events,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.lockedBanner,
    required this.emptyMessage,
    required this.onEventTap,
  });

  @override
  State<ProfileEventsSection> createState() => _ProfileEventsSectionState();
}

class _ProfileEventsSectionState extends State<ProfileEventsSection> {
  _ViewMode _viewMode = _ViewMode.list;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _dayKey(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  Map<DateTime, List<Event>> _groupByDay(List<Event> events) {
    final map = <DateTime, List<Event>>{};
    for (final event in events) {
      final days = (event.sessions ?? []).map((s) => _dayKey(s.startDatetime)).toSet();
      for (final day in days) {
        map.putIfAbsent(day, () => []).add(event);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final showToggle =
        widget.lockedBanner == null && widget.error == null && !widget.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Eventos', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (showToggle)
              ToggleButtons(
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
          ],
        ),
        const SizedBox(height: 12),
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.lockedBanner != null) return widget.lockedBanner!;

    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text('No se pudieron cargar los eventos'),
            const SizedBox(height: 8),
            if (widget.onRetry != null)
              TextButton(onPressed: widget.onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final events = widget.events ?? [];
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(widget.emptyMessage),
      );
    }

    return _viewMode == _ViewMode.list ? _buildList(events) : _buildCalendar(context, events);
  }

  Widget _buildList(List<Event> events) {
    return Column(
      children: events.map((e) => EventCard(event: e, onTap: () => widget.onEventTap(e))).toList(),
    );
  }

  Widget _buildCalendar(BuildContext context, List<Event> events) {
    final eventsByDay = _groupByDay(events);
    final selectedDay = _selectedDay ?? _dayKey(_focusedDay);
    final selectedEvents = eventsByDay[selectedDay] ?? const <Event>[];

    return Column(
      children: [
        TableCalendar<Event>(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
          focusedDay: _focusedDay,
          locale: 'es_ES',
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: (day) => eventsByDay[_dayKey(day)] ?? const <Event>[],
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
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
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        ),
        const SizedBox(height: 12),
        if (selectedEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Sin eventos este día',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          )
        else
          Column(
            children: selectedEvents
                .map((e) => EventCard(event: e, onTap: () => widget.onEventTap(e)))
                .toList(),
          ),
      ],
    );
  }
}
