import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/reservation.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onTap;

  const ReservationCard({super.key, required this.reservation, required this.onTap});

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day} ${_months[local.month - 1]}. ${local.year}';
  }

  (IconData, Color, String) _statusInfo(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return switch (reservation.status) {
      'confirmed' => (Icons.check_circle, Colors.green.shade700, 'Confirmado'),
      'pending' => (Icons.hourglass_top, primary, 'Pendiente de aprobación'),
      'awaiting_payment' => (Icons.hourglass_bottom, Colors.amber.shade800, 'Esperando pago'),
      'waitlisted' => (Icons.notifications_active, primary, 'Lista de espera'),
      _ => (Icons.info_outline, Theme.of(context).colorScheme.outline, reservation.status),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (statusIcon, statusColor, statusLabel) = _statusInfo(context);
    final event = reservation.event;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.network(
                    ApiConfig.mediaUrl(event.coverMediaUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reservation.targetName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (reservation.sessionDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 13, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(reservation.sessionDate!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_outlined, color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
