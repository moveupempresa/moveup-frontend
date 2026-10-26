import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/event.dart';
import '../models/pack.dart';
import '../models/session.dart';
import '../services/app_location_service.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../utils/session_format.dart';
import '../widgets/contact_methods_row.dart';
import '../widgets/sessions_section.dart';
import '../widgets/signup_action_button.dart';
import '../widgets/video_player_view.dart';
import 'event_form_screen.dart';
import 'pack_detail_screen.dart';
import 'public_profile_screen.dart';
import 'registrants_screen.dart';

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
  int _heroCoverPage = 0;

  @override
  void initState() {
    super.initState();
    AppLocationService.saveOpenEvent(widget.event.id);
  }

  @override
  void dispose() {
    AppLocationService.saveOpenEvent(null);
    super.dispose();
  }

  List<Widget> _coverSlides(BuildContext context, Event event) {
    final slides = <Widget>[];
    if (event.coverImageUrl != null) {
      slides.add(
        Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Image.network(
            ApiConfig.mediaUrl(event.coverImageUrl!),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
      );
    }
    if (event.coverVideoUrl != null) {
      slides.add(
        VideoPlayerView(networkUrl: ApiConfig.mediaUrl(event.coverVideoUrl!)),
      );
    }
    return slides;
  }

  Widget _buildCoverCarousel(BuildContext context, Event event) {
    final slides = _coverSlides(context, event);
    if (slides.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_not_supported_outlined, size: 48),
      );
    }
    if (slides.length == 1) return slides.first;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView(
          onPageChanged: (i) => setState(() => _heroCoverPage = i),
          children: slides,
        ),
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              slides.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _heroCoverPage == i
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleSave() async {
    setState(() => _isTogglingSave = true);
    try {
      final isSaved = _isSaved
          ? await EventService.unsaveEvent(
              token: widget.token,
              eventId: widget.event.id,
            )
          : await EventService.saveEvent(
              token: widget.token,
              eventId: widget.event.id,
            );
      if (mounted) setState(() => _isSaved = isSaved);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isTogglingSave = false);
    }
  }

  Future<void> _editEvent() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EventFormScreen(token: widget.token, event: widget.event),
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await EventService.deleteEvent(
        token: widget.token,
        eventId: widget.event.id,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
        setState(() => _isDeleting = false);
      }
    }
  }

  Widget _buildSessionCard(
    Session s,
    String eventId,
    bool isOwner,
    bool allowDirectSignup,
  ) {
    final card = _SessionCard(
      session: s,
      token: widget.token,
      eventId: eventId,
      isOwner: isOwner,
      allowDirectSignup: allowDirectSignup,
    );
    if (!isOwner) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegistrantsScreen(
            token: widget.token,
            currentUserId: widget.currentUserId,
            eventId: eventId,
            targetType: RegistrantsTargetType.session,
            targetId: s.id,
            targetName: s.name,
            sessionStart: s.startDatetime,
            sessionEnd: s.endDatetime,
          ),
        ),
      ),
      child: card,
    );
  }

  Widget _buildPackCard(
    Pack p,
    String eventId,
    List<Session> sessions,
    bool isOwner,
  ) {
    final card = _PackCard(
      pack: p,
      sessions: sessions,
      token: widget.token,
      eventId: eventId,
      isOwner: isOwner,
    );
    if (!isOwner) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegistrantsScreen(
            token: widget.token,
            currentUserId: widget.currentUserId,
            eventId: eventId,
            targetType: RegistrantsTargetType.pack,
            targetId: p.id,
            targetName: p.name,
            sessions: sessions,
            paymentType: p.paymentType,
          ),
        ),
      ),
      child: card,
    );
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
            flexibleSpace: FlexibleSpaceBar(
              background: _buildCoverCarousel(context, event),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isOwner)
                      IconButton(
                        icon: _isTogglingSave
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_outline,
                              ),
                        tooltip: _isSaved
                            ? 'Quitar de guardados'
                            : 'Guardar evento',
                        onPressed: _isTogglingSave ? null : _toggleSave,
                      ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar evento',
                        onPressed: _isDeleting ? null : _deleteEvent,
                      ),
                    ],
                  ],
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
                        Icon(
                          Icons.person_outline,
                          size: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Organizado por ${event.organizerName}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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
                  text: [
                    event.city,
                    event.country,
                  ].where((s) => s.isNotEmpty).join(', '),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.category_outlined,
                  text: event.eventTypeLabel,
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
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                ],
                if (event.style.isNotEmpty) ...[
                  Text(
                    'Estilos',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: event.style
                        .map(
                          (s) => Chip(
                            label: Text(s),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                if (!isOwner && (event.creatorContact?.hasAny ?? false)) ...[
                  Text(
                    'Contactar con el creador del evento',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ContactMethodsRow.fromContactInfo(event.creatorContact),
                  const SizedBox(height: 20),
                ],
                // Students only see the event-level sessions list when the
                // event has no packs (reservationEnabled: false) - that's
                // the only case where a session is directly bookable.
                // Otherwise sessions only matter inside each pack, which
                // students now reach via PackDetailScreen.
                if (isOwner || !event.reservationEnabled)
                  SessionsSection(
                    sessions: sessions,
                    cardBuilder: (s) => _buildSessionCard(
                      s,
                      event.id,
                      isOwner,
                      !event.reservationEnabled,
                    ),
                  ),
                if (event.reservationEnabled) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Packs',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (packs.isEmpty)
                    Text(
                      'Sin packs',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    ...packs.map(
                      (p) => _buildPackCard(p, event.id, sessions, isOwner),
                    ),
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
  final bool allowDirectSignup;

  const _SessionCard({
    required this.session,
    required this.token,
    required this.eventId,
    required this.isOwner,
    required this.allowDirectSignup,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggleSignUp() async {
    setState(() => _isLoading = true);
    try {
      final (status, count) = _isSignedUp
          ? await RegistrationService.cancelSessionSignUp(
              token: widget.token,
              eventId: widget.eventId,
              sessionId: widget.session.id,
            )
          : await RegistrationService.signUpForSession(
              token: widget.token,
              eventId: widget.eventId,
              sessionId: widget.session.id,
            );
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
              token: widget.token,
              eventId: widget.eventId,
              sessionId: widget.session.id,
            )
          : await RegistrationService.joinSessionWaitlist(
              token: widget.token,
              eventId: widget.eventId,
              sessionId: widget.session.id,
            );
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    session.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (!session.isUnlimitedCapacity &&
                    session.capacity != null) ...[
                  const SizedBox(width: 8),
                  _CapacityBadge(
                    confirmedCount: _confirmedCount,
                    capacity: session.capacity!,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14),
                const SizedBox(width: 6),
                Text(
                  formatSessionDate(start),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.access_time_outlined, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${formatSessionTime(start)} – ${formatSessionTime(end)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (session.address != null && session.address!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      session.address!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
            if (!widget.isOwner && widget.allowDirectSignup) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: SignupActionButton(
                  isFull: _isFull,
                  isSignedUp: _isSignedUp,
                  isWaitlisted: _isWaitlisted,
                  isLoading: _isLoading,
                  onToggleSignUp: _toggleSignUp,
                  onToggleWaitlist: _toggleWaitlist,
                ),
              ),
            ],
          ],
        ),
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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

IconData _packPaymentIcon(PaymentType type) => switch (type) {
  PaymentType.online => Icons.credit_card,
  PaymentType.offline => Icons.money,
  PaymentType.bizum => Icons.phone_android,
  PaymentType.paypal => Icons.account_balance_wallet,
};

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
  late final int _confirmedCount = widget.pack.confirmedCount;
  late bool _isSignedUp = widget.pack.isSignedUp;
  late bool _isPending = widget.pack.isPending;
  late bool _isAwaitingPayment = widget.pack.isAwaitingPayment;

  // The whole reserve/pay flow now lives in PackDetailScreen; this card just
  // needs to reflect whatever status it comes back with.
  Future<void> _openPackDetail(BuildContext context) async {
    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => PackDetailScreen(
          token: widget.token,
          eventId: widget.eventId,
          pack: widget.pack,
          sessions: widget.sessions,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _isSignedUp = result == 'confirmed';
        _isPending = result == 'pending';
        _isAwaitingPayment = result == 'awaiting_payment';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isOwner
        ? _buildOwnerCard(context)
        : _buildStudentCard(context);
  }

  Widget _buildOwnerCard(BuildContext context) {
    final pack = widget.pack;
    final priceLabel =
        '${pack.price.toStringAsFixed(2)} ${pack.currency} · ${pack.paymentType.label}';

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
                    Text(
                      priceLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      pack.packType.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$_confirmedCount inscritos',
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
                  if (candidateSessions.isNotEmpty) ...[
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
                ],
                if (pack.packType == PackType.fixed &&
                    includedSessionNames.isNotEmpty) ...[
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
          if (pack.pendingRequestsCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Tooltip(
                message: pack.pendingRequestsCount == 1
                    ? '1 solicitud pendiente de aprobación'
                    : '${pack.pendingRequestsCount} solicitudes pendientes de aprobación',
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  (String?, Color?) _statusBadge(ColorScheme colorScheme) {
    if (_isSignedUp) return ('Reservado', Colors.green.shade700);
    if (_isAwaitingPayment) return ('Pago pendiente', Colors.amber.shade800);
    if (_isPending) return ('Pendiente', colorScheme.primary);
    return (null, null);
  }

  // Closed, student-facing card: just enough to decide whether to open it -
  // name, price and payment method - styled to look clearly tappable. Every
  // other detail (sessions included, reserving, paying) lives in
  // PackDetailScreen now.
  Widget _buildStudentCard(BuildContext context) {
    final pack = widget.pack;
    final colorScheme = Theme.of(context).colorScheme;
    final priceLabel =
        '${pack.price.toStringAsFixed(2)} ${pack.currency} · ${pack.paymentType.label}';
    final (statusLabel, statusColor) = _statusBadge(colorScheme);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openPackDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  child: Icon(_packPaymentIcon(pack.paymentType)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (statusLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor!.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onPrimaryContainer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
