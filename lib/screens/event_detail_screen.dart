import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/event.dart';
import '../models/pack.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import 'event_form_screen.dart';
import 'payment_screen.dart';
import 'public_profile_screen.dart';

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String _formatSessionDate(DateTime dt) {
  final local = dt.toLocal();
  return '${local.day} ${_months[local.month - 1]}. ${local.year}';
}

String _formatSessionTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final String token;
  final String currentUserId;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.token,
    required this.currentUserId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isDeleting = false;
  bool _isTogglingSave = false;
  late bool _isSaved = widget.event.isSaved;

  Future<void> _toggleSave() async {
    setState(() => _isTogglingSave = true);
    try {
      final isSaved = _isSaved
          ? await EventService.unsaveEvent(token: widget.token, eventId: widget.event.id)
          : await EventService.saveEvent(token: widget.token, eventId: widget.event.id);
      if (mounted) setState(() => _isSaved = isSaved);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isTogglingSave = false);
    }
  }

  void _addToCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función próximamente disponible')),
    );
  }

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
    final isOwner = event.ownerUserId == widget.currentUserId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
              if (!isOwner) ...[
                IconButton(
                  icon: _isTogglingSave
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_isSaved ? Icons.bookmark : Icons.bookmark_outline),
                  tooltip: _isSaved ? 'Quitar de guardados' : 'Guardar evento',
                  onPressed: _isTogglingSave ? null : _toggleSave,
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  tooltip: 'Añadir al calendario',
                  onPressed: _addToCalendar,
                ),
              ],
              if (isOwner) ...[
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
                if (!isOwner && event.organizerName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          token: widget.token,
                          userId: event.ownerUserId,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline,
                            size: 15, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Organizado por ${event.organizerName}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                if (isOwner || packs.isEmpty) ...[
                  if (sessions.length > 3)
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text('Sesiones (${sessions.length})',
                            style: Theme.of(context).textTheme.titleSmall),
                        children: sessions
                            .map((s) => _SessionCard(
                                  session: s,
                                  token: widget.token,
                                  eventId: event.id,
                                  isOwner: isOwner,
                                ))
                            .toList(),
                      ),
                    )
                  else ...[
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
                      ...sessions.map((s) => _SessionCard(
                            session: s,
                            token: widget.token,
                            eventId: event.id,
                            isOwner: isOwner,
                          )),
                  ],
                ],
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
                    ...packs.map((p) => _PackCard(
                          pack: p,
                          sessions: sessions,
                          token: widget.token,
                          eventId: event.id,
                          isOwner: isOwner,
                        )),
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

class _SessionCard extends StatefulWidget {
  final Session session;
  final String token;
  final String eventId;
  final bool isOwner;

  const _SessionCard({
    required this.session,
    required this.token,
    required this.eventId,
    required this.isOwner,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  late int _confirmedCount = widget.session.confirmedCount;
  late bool _isSignedUp = widget.session.isSignedUp;
  late bool _isWaitlisted = widget.session.isWaitlisted;
  bool _isLoading = false;

  bool get _isFull =>
      !widget.session.isUnlimitedCapacity &&
      widget.session.capacity != null &&
      _confirmedCount >= widget.session.capacity!;

  void _showError(Object e) {
    if (e is AuthException && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggleSignUp() async {
    setState(() => _isLoading = true);
    try {
      final (status, count) = _isSignedUp
          ? await RegistrationService.cancelSessionSignUp(
              token: widget.token, eventId: widget.eventId, sessionId: widget.session.id)
          : await RegistrationService.signUpForSession(
              token: widget.token, eventId: widget.eventId, sessionId: widget.session.id);
      if (mounted) {
        setState(() {
          _isSignedUp = status == 'confirmed';
          _confirmedCount = count;
        });
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWaitlist() async {
    setState(() => _isLoading = true);
    try {
      final (status, count) = _isWaitlisted
          ? await RegistrationService.leaveSessionWaitlist(
              token: widget.token, eventId: widget.eventId, sessionId: widget.session.id)
          : await RegistrationService.joinSessionWaitlist(
              token: widget.token, eventId: widget.eventId, sessionId: widget.session.id);
      if (mounted) {
        setState(() {
          _isWaitlisted = status == 'waitlisted';
          _confirmedCount = count;
        });
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final start = session.startDatetime.toLocal();
    final end = session.endDatetime.toLocal();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, widget.isOwner ? 14 : 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(session.name, style: Theme.of(context).textTheme.titleSmall),
                    ),
                    if (!session.isUnlimitedCapacity && session.capacity != null) ...[
                      const SizedBox(width: 8),
                      _CapacityBadge(confirmedCount: _confirmedCount, capacity: session.capacity!),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14),
                    const SizedBox(width: 6),
                    Text(_formatSessionDate(start), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, size: 14),
                    const SizedBox(width: 6),
                    Text('${_formatSessionTime(start)} – ${_formatSessionTime(end)}',
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
                              ? '$_confirmedCount / ${session.capacity} personas'
                              : 'Aforo no especificado',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!widget.isOwner)
            Positioned(
              right: 4,
              bottom: 4,
              child: _SignupIconButton(
                isFull: _isFull,
                isSignedUp: _isSignedUp,
                isWaitlisted: _isWaitlisted,
                isLoading: _isLoading,
                onToggleSignUp: _toggleSignUp,
                onToggleWaitlist: _toggleWaitlist,
              ),
            ),
        ],
      ),
    );
  }

}

class _CapacityBadge extends StatelessWidget {
  final int confirmedCount;
  final int capacity;

  const _CapacityBadge({required this.confirmedCount, required this.capacity});

  @override
  Widget build(BuildContext context) {
    final ratio = capacity == 0 ? 1.0 : confirmedCount / capacity;
    final Color color;
    if (ratio >= 1.0) {
      color = Colors.red.shade700;
    } else if (ratio >= 0.7) {
      color = Colors.amber.shade800;
    } else {
      color = Colors.green.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$confirmedCount/$capacity',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SignupIconButton extends StatelessWidget {
  final bool isFull;
  final bool isSignedUp;
  final bool isWaitlisted;
  final bool isPending;
  final bool isLoading;
  final bool isExpandable;
  final bool isExpanded;
  final VoidCallback onToggleSignUp;
  final VoidCallback onToggleWaitlist;

  const _SignupIconButton({
    required this.isFull,
    required this.isSignedUp,
    required this.isWaitlisted,
    this.isPending = false,
    required this.isLoading,
    this.isExpandable = false,
    this.isExpanded = false,
    required this.onToggleSignUp,
    required this.onToggleWaitlist,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (isPending) {
      return IconButton(
        icon: Icon(Icons.hourglass_top, color: Theme.of(context).colorScheme.primary),
        tooltip: 'Solicitud pendiente de aprobación · toca para cancelar',
        onPressed: onToggleSignUp,
      );
    }
    if (isFull && !isSignedUp) {
      return IconButton(
        icon: Icon(isWaitlisted ? Icons.notifications_active : Icons.notifications_none),
        color: isWaitlisted ? Theme.of(context).colorScheme.primary : null,
        tooltip: isWaitlisted
            ? 'Cancelar aviso de disponibilidad'
            : 'Avisarme si hay un cupo disponible',
        onPressed: onToggleWaitlist,
      );
    }
    if (isExpandable && !isSignedUp) {
      return IconButton(
        icon: Icon(isExpanded ? Icons.expand_less : Icons.checklist),
        color: isExpanded ? Theme.of(context).colorScheme.primary : null,
        tooltip: isExpanded ? 'Ocultar sesiones' : 'Elegir sesiones',
        onPressed: onToggleSignUp,
      );
    }
    return IconButton(
      icon: Icon(isSignedUp ? Icons.check_circle : Icons.check_circle_outline),
      color: isSignedUp ? Theme.of(context).colorScheme.primary : null,
      tooltip: isSignedUp ? 'Cancelar inscripción' : 'Inscribirme',
      onPressed: onToggleSignUp,
    );
  }
}

class _PackCard extends StatefulWidget {
  final Pack pack;
  final List<Session> sessions;
  final String token;
  final String eventId;
  final bool isOwner;

  const _PackCard({
    required this.pack,
    required this.sessions,
    required this.token,
    required this.eventId,
    required this.isOwner,
  });

  @override
  State<_PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<_PackCard> {
  late int _confirmedCount = widget.pack.confirmedCount;
  late bool _isSignedUp = widget.pack.isSignedUp;
  late bool _isWaitlisted = widget.pack.isWaitlisted;
  late bool _isPending = widget.pack.isPending;
  late final Set<String> _selectedSessionIds = widget.pack.mySelectedSessionIds.toSet();
  bool _isLoading = false;
  bool _isExpanded = false;

  bool get _isFull =>
      !widget.pack.isUnlimitedCapacity &&
      widget.pack.capacity != null &&
      _confirmedCount >= widget.pack.capacity!;

  bool get _isCommitted => _isSignedUp || _isPending;

  bool get _selectionValid {
    if (_selectedSessionIds.isEmpty) return false;
    final max = widget.pack.maxSelectableSessions;
    return max == null || _selectedSessionIds.length <= max;
  }

  void _onSessionToggled(String sessionId, bool checked) {
    setState(() {
      if (checked) {
        _selectedSessionIds.add(sessionId);
      } else {
        _selectedSessionIds.remove(sessionId);
      }
    });
  }

  void _showError(Object e) {
    if (e is AuthException && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  bool get _isCustomizable => widget.pack.packType == PackType.customizable;

  bool get _isPaymentReady =>
      widget.pack.approvalMode == ApprovalMode.automatic || _isSignedUp;

  void _openPayment() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentScreen(packName: widget.pack.name)),
    );
  }

  void _showCashMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('El pago de este pack es en efectivo')),
    );
  }

  Future<void> _toggleSignUp() async {
    if (_isCommitted) {
      setState(() => _isLoading = true);
      try {
        final (status, count) = await RegistrationService.cancelPackSignUp(
            token: widget.token, eventId: widget.eventId, packId: widget.pack.id);
        if (mounted) {
          setState(() {
            _isSignedUp = status == 'confirmed';
            _isPending = status == 'pending';
            _confirmedCount = count;
            _isExpanded = false;
          });
        }
      } catch (e) {
        _showError(e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    if (_isCustomizable) {
      setState(() => _isExpanded = !_isExpanded);
      return;
    }

    await _confirmSignUp();
  }

  Future<void> _confirmSignUp() async {
    if (_isCustomizable && !_selectionValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.pack.maxSelectableSessions != null
            ? 'Selecciona entre 1 y ${widget.pack.maxSelectableSessions} sesiones'
            : 'Selecciona al menos una sesión'),
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final (status, count) = await RegistrationService.signUpForPack(
        token: widget.token,
        eventId: widget.eventId,
        packId: widget.pack.id,
        selectedSessionIds: _isCustomizable ? _selectedSessionIds.toList() : null,
      );
      if (mounted) {
        setState(() {
          _isSignedUp = status == 'confirmed';
          _isPending = status == 'pending';
          _confirmedCount = count;
        });
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWaitlist() async {
    setState(() => _isLoading = true);
    try {
      final (status, count) = _isWaitlisted
          ? await RegistrationService.leavePackWaitlist(
              token: widget.token, eventId: widget.eventId, packId: widget.pack.id)
          : await RegistrationService.joinPackWaitlist(
              token: widget.token, eventId: widget.eventId, packId: widget.pack.id);
      if (mounted) {
        setState(() {
          _isWaitlisted = status == 'waitlisted';
          _confirmedCount = count;
        });
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;
    final priceLabel = pack.paymentType == PaymentType.free
        ? 'Gratis'
        : '${pack.price.toStringAsFixed(2)} · ${pack.paymentType.label}';

    final includedSessionNames = pack.sessionIds
        .map((id) => widget.sessions.where((s) => s.id == id).firstOrNull?.name)
        .whereType<String>()
        .toList();
    final candidateSessions = pack.sessionIds
        .map((id) => widget.sessions.where((s) => s.id == id).firstOrNull)
        .whereType<Session>()
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, widget.isOwner ? 14 : 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(pack.name, style: Theme.of(context).textTheme.titleSmall),
                    ),
                    if (!pack.isUnlimitedCapacity && pack.capacity != null) ...[
                      const SizedBox(width: 8),
                      _CapacityBadge(confirmedCount: _confirmedCount, capacity: pack.capacity!),
                    ],
                  ],
                ),
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
                              ? '$_confirmedCount / ${pack.capacity} personas'
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
                if (pack.packType == PackType.customizable) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event_available_outlined, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        pack.maxSelectableSessions != null
                            ? 'Elige hasta ${pack.maxSelectableSessions} sesiones'
                            : 'Elige tus sesiones',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (widget.isOwner && candidateSessions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            candidateSessions.map((s) => s.name).join(', '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!widget.isOwner && _isCommitted)
                    ...candidateSessions.where((s) => _selectedSessionIds.contains(s.id)).map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(left: 20, top: 2),
                            child: Row(
                              children: [
                                Icon(Icons.check, size: 14, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(s.name, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ),
                  if (!widget.isOwner && !_isCommitted && _isExpanded) ...[
                    ...candidateSessions.map((s) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _selectedSessionIds.contains(s.id),
                          title: Text(
                            s.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              _formatSessionDate(s.startDatetime),
                              '${_formatSessionTime(s.startDatetime)} – ${_formatSessionTime(s.endDatetime)}',
                              if (s.address != null && s.address!.isNotEmpty) s.address!,
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          onChanged: (checked) => _onSessionToggled(s.id, checked ?? false),
                        )),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _confirmSignUp,
                        child: const Text('Confirmar inscripción'),
                      ),
                    ),
                  ],
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
          if (!widget.isOwner)
            Positioned(
              right: 4,
              bottom: 4,
              child: _SignupIconButton(
                isFull: _isFull,
                isSignedUp: _isSignedUp,
                isWaitlisted: _isWaitlisted,
                isPending: _isPending,
                isLoading: _isLoading,
                isExpandable: _isCustomizable,
                isExpanded: _isExpanded,
                onToggleSignUp: _toggleSignUp,
                onToggleWaitlist: _toggleWaitlist,
              ),
            ),
          if (!widget.isOwner && pack.paymentType != PaymentType.free)
            Positioned(
              left: 4,
              bottom: 4,
              child: IconButton(
                icon: Icon(
                  pack.paymentType == PaymentType.online ? Icons.credit_card : Icons.money,
                ),
                color: _isPaymentReady ? Colors.green.shade700 : Colors.grey,
                tooltip: pack.paymentType == PaymentType.online
                    ? 'Pagar con tarjeta'
                    : 'Pago en efectivo',
                onPressed: pack.paymentType == PaymentType.online ? _openPayment : _showCashMessage,
              ),
            ),
        ],
      ),
    );
  }
}
