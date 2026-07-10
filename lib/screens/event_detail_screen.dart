import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/event.dart';
import '../models/pack.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import 'event_form_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final String token;

  const EventDetailScreen({super.key, required this.event, required this.token});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isDeleting = false;

  Future<void> _editEvent() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventFormScreen(token: widget.token, event: widget.event),
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
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await EventService.deleteEvent(token: widget.token, eventId: widget.event.id);
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final sessions = event.sessions ?? [];
    final packs = event.packs ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                tooltip: 'Eliminar evento',
                onPressed: _isDeleting ? null : _deleteEvent,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                ApiConfig.mediaUrl(event.coverMediaUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_not_supported_outlined, size: 48),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.place_outlined,
                  text: [event.city, event.country].where((s) => s.isNotEmpty).join(', '),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.category_outlined,
                  text: event.eventType.label,
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
                  Text('Descripción', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(event.description, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                ],
                if (event.style.isNotEmpty) ...[
                  Text('Estilos', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: event.style
                        .map((s) => Chip(label: Text(s), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                Text('Sesiones', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (sessions.isEmpty)
                  Text(
                    'Sin sesiones',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                  )
                else
                  ...sessions.map((s) => _SessionCard(session: s)),
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
                    ...packs.map((p) => _PackCard(pack: p, sessions: sessions)),
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

class _SessionCard extends StatelessWidget {
  final Session session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final start = session.startDatetime.toLocal();
    final end = session.endDatetime.toLocal();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14),
                const SizedBox(width: 6),
                Text(_formatDate(start), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.access_time_outlined, size: 14),
                const SizedBox(width: 6),
                Text('${_formatTime(start)} – ${_formatTime(end)}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (session.address != null && session.address!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(session.address!, style: Theme.of(context).textTheme.bodySmall),
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
                          ? '${session.capacity} personas'
                          : 'Aforo no especificado',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]}. ${dt.year}';

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _PackCard extends StatelessWidget {
  final Pack pack;
  final List<Session> sessions;

  const _PackCard({required this.pack, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final priceLabel = pack.paymentType == PaymentType.free
        ? 'Gratis'
        : '${pack.price.toStringAsFixed(2)} · ${pack.paymentType.label}';

    final includedSessionNames = pack.sessionIds
        .map((id) => sessions.where((s) => s.id == id).firstOrNull?.name)
        .whereType<String>()
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pack.name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 14),
                const SizedBox(width: 6),
                Text(priceLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 14),
                const SizedBox(width: 6),
                Text(pack.packType.label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 14),
                const SizedBox(width: 6),
                Text(
                  pack.isUnlimitedCapacity
                      ? 'Aforo ilimitado'
                      : pack.capacity != null
                          ? '${pack.capacity} personas'
                          : 'Aforo no especificado',
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
            if (pack.packType == PackType.customizable && pack.maxSelectableSessions != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.event_available_outlined, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'El estudiante elige hasta ${pack.maxSelectableSessions} sesiones',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (pack.packType == PackType.fixed && includedSessionNames.isNotEmpty) ...[
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
    );
  }
}
