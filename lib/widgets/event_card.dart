import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];

  String _eventDate() {
    final sessions = event.sessions;
    if (sessions != null && sessions.isNotEmpty) {
      final dt = sessions.first.startDatetime.toLocal();
      return '${dt.day} ${_months[dt.month - 1]}. ${dt.year}';
    }
    final dt = event.createdAt.toLocal();
    return '${dt.day} ${_months[dt.month - 1]}. ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Image.network(
                ApiConfig.mediaUrl(event.coverMediaUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        _eventDate(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 13, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [event.city, event.country]
                              .where((s) => s.isNotEmpty)
                              .join(', '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
