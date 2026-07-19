import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/registration_service.dart';

class NotificationsScreen extends StatefulWidget {
  final String token;

  const NotificationsScreen({super.key, required this.token});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _reservationTypes = {
    NotificationType.signedUp,
    NotificationType.waitlisted,
    NotificationType.spotAvailable,
    NotificationType.targetUpdated,
    NotificationType.signupApproved,
    NotificationType.signupRejected,
    NotificationType.registrationRevoked,
    NotificationType.paymentRequired,
  };
  static const _myEventsTypes = {
    NotificationType.newRegistration,
    NotificationType.signupRequest,
    NotificationType.packPaid,
  };
  static const _followTypes = {
    NotificationType.followedUser,
    NotificationType.followedUserNewEvent,
  };

  List<AppNotification>? _notifications;
  bool _loading = true;
  String? _error;
  bool _markedRead = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifications = await NotificationService.getMyNotifications(token: widget.token);
      if (mounted) setState(() => _notifications = notifications);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudieron cargar las notificaciones');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final notifications = await NotificationService.getMyNotifications(token: widget.token);
      if (mounted) setState(() => _notifications = notifications);
    } catch (_) {
      // Keep the current list if the background refresh fails.
    }
  }

  void _onSectionExpanded(bool expanded) {
    if (!expanded || _markedRead) return;
    final hasUnread = _notifications?.any((n) => !n.read) ?? false;
    if (!hasUnread) return;
    _markedRead = true;
    NotificationService.markAllAsRead(token: widget.token).catchError((_) {});
  }

  List<AppNotification> _itemsOfTypes(Set<NotificationType> types) =>
      (_notifications ?? []).where((n) => types.contains(n.type)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView(
        children: [
          _buildNotificationSection(
            title: 'Reservas',
            icon: Icons.calendar_today_outlined,
            items: _itemsOfTypes(_reservationTypes),
          ),
          _buildNotificationSection(
            title: 'Mis Eventos',
            icon: Icons.school_outlined,
            items: _itemsOfTypes(_myEventsTypes),
          ),
          _buildNotificationSection(
            title: 'Perfiles seguidos',
            icon: Icons.bookmark_outline,
            items: _itemsOfTypes(_followTypes),
          ),
          const _NotificationSection(title: 'Recordatorios', icon: Icons.alarm_outlined),
        ],
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required IconData icon,
    required List<AppNotification> items,
  }) {
    final unreadCount = items.where((n) => !n.read).length;

    return Column(
      children: [
        ExpansionTile(
          leading: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: Icon(icon),
          ),
          title: Text(title),
          onExpansionChanged: _onSectionExpanded,
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                    TextButton(onPressed: _load, child: const Text('Reintentar')),
                  ],
                ),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Sin novedades todavía',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              )
            else
              ...items.map((n) => _NotificationTile(
                    notification: n,
                    token: widget.token,
                    onResolved: _silentRefresh,
                  )),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _NotificationTile extends StatefulWidget {
  final AppNotification notification;
  final String token;
  final VoidCallback onResolved;

  const _NotificationTile({
    required this.notification,
    required this.token,
    required this.onResolved,
  });

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];

  bool _isResponding = false;
  bool _responded = false;

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day} ${_months[local.month - 1]}. ${local.year}';
  }

  IconData get _icon => switch (widget.notification.type) {
        NotificationType.followedUser => Icons.person_add_alt_outlined,
        NotificationType.followedUserNewEvent => Icons.event_available_outlined,
        NotificationType.signedUp => Icons.check_circle_outline,
        NotificationType.waitlisted => Icons.notifications_none,
        NotificationType.spotAvailable => Icons.notifications_active,
        NotificationType.targetUpdated => Icons.edit_calendar_outlined,
        NotificationType.newRegistration => Icons.person_outline,
        NotificationType.signupRequest => Icons.pending_actions_outlined,
        NotificationType.signupApproved => Icons.check_circle_outline,
        NotificationType.signupRejected => Icons.cancel_outlined,
        NotificationType.packPaid => Icons.payments_outlined,
        NotificationType.registrationRevoked => Icons.event_busy_outlined,
        NotificationType.paymentRequired => Icons.hourglass_bottom,
      };

  Future<void> _respond(bool approve) async {
    final n = widget.notification;
    final eventId = n.relatedEventId;
    final packId = n.relatedTargetId;
    final userId = n.relatedUserId;
    if (eventId == null || packId == null || userId == null) return;

    setState(() => _isResponding = true);
    try {
      approve
          ? await RegistrationService.approvePackRequest(
              token: widget.token, eventId: eventId, packId: packId, userId: userId)
          : await RegistrationService.rejectPackRequest(
              token: widget.token, eventId: eventId, packId: packId, userId: userId);
      if (mounted) setState(() => _responded = true);
      widget.onResolved();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ocurrió un error')));
      }
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }

  Widget? get _trailing {
    final n = widget.notification;
    if (n.type == NotificationType.signupRequest && n.isPending == true && !_responded) {
      if (_isResponding) {
        return const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            color: Colors.green.shade700,
            tooltip: 'Aprobar',
            onPressed: () => _respond(true),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            color: Colors.red.shade700,
            tooltip: 'Rechazar',
            onPressed: () => _respond(false),
          ),
        ],
      );
    }
    if (n.read) return null;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    return ListTile(
      leading: Icon(_icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        notification.message,
        style: notification.read
            ? null
            : const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        _formatDate(notification.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: _trailing,
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final IconData icon;

  const _NotificationSection({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          leading: Icon(icon),
          title: Text(title),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
