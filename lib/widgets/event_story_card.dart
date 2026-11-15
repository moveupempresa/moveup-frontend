import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/event.dart';

const _storyCardMonths = [
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

/// Vertical (9:16) summary card for an event, meant to be rendered off-screen
/// and exported as an image to share to Instagram Stories - not shown as an
/// interactive widget anywhere in the app itself.
class EventStoryCard extends StatelessWidget {
  final Event event;

  const EventStoryCard({super.key, required this.event});

  String get _dateLabel {
    final sessions = event.sessions;
    if (sessions == null || sessions.isEmpty) return '';
    final sorted = [...sessions]
      ..sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
    final dt = sorted.first.startDatetime.toLocal();
    return '${dt.day} ${_storyCardMonths[dt.month - 1]}. ${dt.year}';
  }

  String get _locationLabel =>
      [event.city, event.country].where((s) => s.isNotEmpty).join(', ');

  @override
  Widget build(BuildContext context) {
    final coverUrl = event.coverImageUrl;

    return SizedBox(
      width: 360,
      height: 640,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null)
            Image.network(ApiConfig.mediaUrl(coverUrl), fit: BoxFit.cover)
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF17213A), Color(0xFF0F5B4E)],
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.4, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ATRYUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Text(
                  event.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                if (_dateLabel.isNotEmpty)
                  _InfoRow(icon: Icons.calendar_today, text: _dateLabel),
                if (_locationLabel.isNotEmpty)
                  _InfoRow(icon: Icons.place, text: _locationLabel),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Resérvalo en Atryum',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
