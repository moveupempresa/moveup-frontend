import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onOwnerTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onOwnerTap,
  });

  static const _months = [
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

  // Desaturates the cover thumbnail for past events instead of just fading
  // it, so "finished" reads as a deliberate style rather than a loading state.
  static const _grayscaleFilter = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  // A diagonal glass-like highlight sweeping across the thumbnail, giving
  // active events a glossy, "alive" feel that contrasts with the flat,
  // desaturated look of finished ones.
  static const _shineGradient = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [
      Colors.transparent,
      Colors.white24,
      Colors.white60,
      Colors.white24,
      Colors.transparent,
    ],
    stops: [0.0, 0.35, 0.47, 0.6, 1.0],
  );

  String _eventDate() {
    final sessions = event.sessions;
    if (sessions != null && sessions.isNotEmpty) {
      final dt = sessions.first.startDatetime.toLocal();
      return '${dt.day} ${_months[dt.month - 1]}. ${dt.year}';
    }
    final dt = event.createdAt.toLocal();
    return '${dt.day} ${_months[dt.month - 1]}. ${dt.year}';
  }

  bool get _isPast {
    final sessions = event.sessions;
    if (sessions == null || sessions.isEmpty) return false;
    final now = DateTime.now();
    return sessions.every((s) => s.endDatetime.isBefore(now));
  }

  Widget _buildThumbnail(BuildContext context, bool isPast) {
    final image = Image.network(
      ApiConfig.mediaUrl(event.coverMediaUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_not_supported_outlined),
      ),
    );
    return isPast
        ? ColorFiltered(colorFilter: _grayscaleFilter, child: image)
        : image;
  }

  @override
  Widget build(BuildContext context) {
    final isPast = _isPast;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      color: isPast ? Theme.of(context).colorScheme.surfaceContainerLow : null,
      elevation: isPast ? 0 : 4,
      shadowColor: isPast ? null : Theme.of(context).colorScheme.primary,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(context, isPast),
                  if (!isPast)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(gradient: _shineGradient),
                        ),
                      ),
                    ),
                  if (isPast)
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Finalizado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Opacity(
                opacity: isPast ? 0.7 : 1,
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
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _eventDate(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              event.city,
                              event.country,
                            ].where((s) => s.isNotEmpty).join(', '),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (event.organizerName.isNotEmpty &&
                        onOwnerTap != null) ...[
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: onOwnerTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 13,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event.organizerName,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
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
