import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/app_version_service.dart';
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
  static const _myEventsTypes = {
    NotificationType.newRegistration,
    NotificationType.signupRequest,
    NotificationType.packPaid,
    NotificationType.registrantCancelled,
    NotificationType.capacityFull,
    NotificationType.spotFreed,
    NotificationType.eventReminderOrganizerDay,
    NotificationType.eventReminderOrganizerHours,
  };
  static const _myReservationsTypes = {
    NotificationType.signedUp,
    NotificationType.waitlisted,
    NotificationType.spotAvailable,
    NotificationType.targetUpdated,
    NotificationType.signupApproved,
    NotificationType.signupRejected,
    NotificationType.registrationRevoked,
    NotificationType.paymentRequired,
    NotificationType.selfCancelConfirmed,
    NotificationType.eventCancelled,
    NotificationType.eventReminderStudent,
  };
  static const _savedEventTypes = {
    NotificationType.savedEventCapacityLow,
    NotificationType.savedEventCapacityFull,
    NotificationType.savedEventSpotFreed,
    NotificationType.savedEventReminder,
  };
  static const _followedUsersTypes = {
    NotificationType.followedUserNewEvent,
  };
  static const _socialTypes = {
    NotificationType.followedUser,
    NotificationType.newFollower,
  };

  List<AppNotification>? _notifications;
  bool _loading = true;
  String? _error;
  bool _markedRead = false;
  bool? _updateAvailable;

  @override
  void initState() {
    super.initState();
    _load();
    _checkAppVersion();
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

  Future<void> _checkAppVersion() async {
    try {
      final updateAvailable = await AppVersionService.isUpdateAvailable();
      if (mounted) setState(() => _updateAvailable = updateAvailable);
    } catch (_) {
      if (mounted) setState(() => _updateAvailable = false);
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
            title: 'Mis Eventos',
            icon: Icons.school_outlined,
            items: _itemsOfTypes(_myEventsTypes),
          ),
          _buildNotificationSection(
            title: 'Mis Reservas',
            icon: Icons.calendar_today_outlined,
            items: _itemsOfTypes(_myReservationsTypes),
          ),
          _buildDiscoverySection(context),
          _buildAccountSection(context),
        ],
      ),
    );
  }

  Widget _buildDiscoverySection(BuildContext context) {
    final savedItems = _itemsOfTypes(_savedEventTypes);
    final followedItems = _itemsOfTypes(_followedUsersTypes);
    final unreadCount =
        savedItems.where((n) => !n.read).length + followedItems.where((n) => !n.read).length;

    return Column(
      children: [
        ExpansionTile(
          leading: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.explore_outlined),
          ),
          title: const Text('Descubrimiento'),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _buildNotificationSection(
                title: 'Eventos guardados',
                icon: Icons.bookmark_outline,
                items: savedItems,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _buildNotificationSection(
                title: 'Usuarios que sigo',
                icon: Icons.person_search_outlined,
                items: followedItems,
              ),
            ),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final socialItems = _itemsOfTypes(_socialTypes);
    final unreadCount =
        socialItems.where((n) => !n.read).length + (_updateAvailable == true ? 1 : 0);

    return Column(
      children: [
        ExpansionTile(
          leading: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.person_outline),
          ),
          title: const Text('Cuenta'),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _buildNotificationSection(
                title: 'Social',
                icon: Icons.people_alt_outlined,
                items: socialItems,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _buildSystemSection(context),
            ),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSystemSection(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          leading: Badge(
            isLabelVisible: _updateAvailable == true,
            label: const Text('1'),
            child: const Icon(Icons.settings_outlined),
          ),
          title: const Text('Sistema'),
          children: [
            if (_updateAvailable == true)
              ListTile(
                leading: Icon(Icons.system_update_alt_outlined,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text(
                  'Nueva versión disponible',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Actualiza la app para disfrutar de las últimas novedades'),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Sin novedades todavía',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
          ],
        ),
        const Divider(height: 1),
      ],
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
        NotificationType.newFollower => Icons.person_add_alt_1_outlined,
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
        NotificationType.registrantCancelled => Icons.person_remove_outlined,
        NotificationType.selfCancelConfirmed => Icons.event_busy_outlined,
        NotificationType.capacityFull => Icons.groups_outlined,
        NotificationType.spotFreed => Icons.event_seat_outlined,
        NotificationType.eventCancelled => Icons.cancel_outlined,
        NotificationType.savedEventCapacityLow => Icons.bookmark_outline,
        NotificationType.savedEventCapacityFull => Icons.bookmark_outline,
        NotificationType.savedEventSpotFreed => Icons.bookmark_outline,
        NotificationType.eventReminderOrganizerDay => Icons.today_outlined,
        NotificationType.eventReminderOrganizerHours => Icons.access_time_outlined,
        NotificationType.eventReminderStudent => Icons.today_outlined,
        NotificationType.savedEventReminder => Icons.today_outlined,
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
