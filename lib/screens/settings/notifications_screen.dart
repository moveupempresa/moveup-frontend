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
    NotificationType.bizumPaymentClaimed,
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
  static const _followedUsersTypes = {NotificationType.followedUserNewEvent};
  static const _socialTypes = {
    NotificationType.followedUser,
    NotificationType.newFollower,
  };
  static const _systemTypes = {NotificationType.phoneNumberRequired};

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
      final notifications = await NotificationService.getMyNotifications(
        token: widget.token,
      );
      if (mounted) setState(() => _notifications = notifications);
      _markAllReadOnce(notifications);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar las notificaciones');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final notifications = await NotificationService.getMyNotifications(
        token: widget.token,
      );
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

  void _markAllReadOnce(List<AppNotification> notifications) {
    if (_markedRead) return;
    if (!notifications.any((n) => !n.read)) return;
    _markedRead = true;
    NotificationService.markAllAsRead(token: widget.token).catchError((_) {});
  }

  List<AppNotification> _itemsOfTypes(Set<NotificationType> types) =>
      (_notifications ?? []).where((n) => types.contains(n.type)).toList();

  int _unreadCount(Set<NotificationType> types) =>
      _itemsOfTypes(types).where((n) => !n.read).length;

  @override
  Widget build(BuildContext context) {
    final discoveryUnread =
        _unreadCount(_savedEventTypes) + _unreadCount(_followedUsersTypes);
    final accountUnread =
        _unreadCount(_socialTypes) +
        _unreadCount(_systemTypes) +
        (_updateAvailable == true ? 1 : 0);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notificaciones'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(
                child: _tabLabel('Mis Eventos', _unreadCount(_myEventsTypes)),
              ),
              Tab(
                child: _tabLabel(
                  'Mis Reservas',
                  _unreadCount(_myReservationsTypes),
                ),
              ),
              Tab(child: _tabLabel('Descubrimiento', discoveryUnread)),
              Tab(child: _tabLabel('Cuenta', accountUnread)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFlatTab(_myEventsTypes),
            _buildFlatTab(_myReservationsTypes),
            _buildDiscoveryTab(context),
            _buildAccountTab(context),
          ],
        ),
      ),
    );
  }

  Widget _tabLabel(String text, int count) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: Text(text),
    );
  }

  Widget _buildFlatTab(Set<NotificationType> types) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(children: [_buildNotificationList(_itemsOfTypes(types))]),
    );
  }

  Widget _buildDiscoveryTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          _sectionHeader(context, 'Eventos guardados', Icons.bookmark_outline),
          _buildNotificationList(_itemsOfTypes(_savedEventTypes)),
          const Divider(height: 32),
          _sectionHeader(
            context,
            'Usuarios que sigo',
            Icons.person_search_outlined,
          ),
          _buildNotificationList(_itemsOfTypes(_followedUsersTypes)),
        ],
      ),
    );
  }

  Widget _buildAccountTab(BuildContext context) {
    final systemItems = _itemsOfTypes(_systemTypes);
    final hasSystemContent = _updateAvailable == true || systemItems.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          _sectionHeader(context, 'Social', Icons.people_alt_outlined),
          _buildNotificationList(_itemsOfTypes(_socialTypes)),
          const Divider(height: 32),
          _sectionHeader(context, 'Sistema', Icons.settings_outlined),
          if (!hasSystemContent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Sin novedades todavía',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            )
          else ...[
            if (_updateAvailable == true) _buildVersionTile(context),
            _buildNotificationList(systemItems, showEmptyState: false),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  Widget _buildVersionTile(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.system_update_alt_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text(
        'Nueva versión disponible',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: const Text(
        'Actualiza la app para disfrutar de las últimas novedades',
      ),
    );
  }

  Widget _buildNotificationList(
    List<AppNotification> items, {
    bool showEmptyState = true,
  }) {
    if (_loading && _notifications == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _notifications == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      if (!showEmptyState) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Sin novedades todavía',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }
    return Column(
      children: items
          .map(
            (n) => _NotificationTile(
              notification: n,
              token: widget.token,
              onResolved: _silentRefresh,
            ),
          )
          .toList(),
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
    NotificationType.bizumPaymentClaimed => Icons.phone_android,
    NotificationType.savedEventCapacityLow => Icons.bookmark_outline,
    NotificationType.savedEventCapacityFull => Icons.bookmark_outline,
    NotificationType.savedEventSpotFreed => Icons.bookmark_outline,
    NotificationType.eventReminderOrganizerDay => Icons.today_outlined,
    NotificationType.eventReminderOrganizerHours => Icons.access_time_outlined,
    NotificationType.eventReminderStudent => Icons.today_outlined,
    NotificationType.savedEventReminder => Icons.today_outlined,
    NotificationType.phoneNumberRequired => Icons.phone_outlined,
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
              token: widget.token,
              eventId: eventId,
              packId: packId,
              userId: userId,
            )
          : await RegistrationService.rejectPackRequest(
              token: widget.token,
              eventId: eventId,
              packId: packId,
              userId: userId,
            );
      if (mounted) setState(() => _responded = true);
      widget.onResolved();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ocurrió un error')));
      }
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }

  Future<void> _acceptBizumPayment() async {
    final n = widget.notification;
    final eventId = n.relatedEventId;
    final packId = n.relatedTargetId;
    final userId = n.relatedUserId;
    if (eventId == null || packId == null || userId == null) return;

    setState(() => _isResponding = true);
    try {
      await RegistrationService.setPackPaymentStatus(
        token: widget.token,
        eventId: eventId,
        packId: packId,
        userId: userId,
        hasPaid: true,
      );
      if (mounted) setState(() => _responded = true);
      widget.onResolved();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ocurrió un error')));
      }
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }

  Widget? get _trailing {
    final n = widget.notification;
    if (n.type == NotificationType.signupRequest &&
        n.isPending == true &&
        !_responded) {
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
    if (n.type == NotificationType.bizumPaymentClaimed && !_responded) {
      if (_isResponding) {
        return const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return IconButton(
        icon: const Icon(Icons.check_circle_outline),
        color: Colors.green.shade700,
        tooltip: 'Aceptar pago',
        onPressed: _acceptBizumPayment,
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
    final organizerPhone = notification.organizerPhone;
    final showContactButton =
        notification.type == NotificationType.eventCancelled &&
        organizerPhone != null &&
        organizerPhone.isNotEmpty;

    return ListTile(
      leading: Icon(_icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        notification.message,
        style: notification.read
            ? null
            : const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(notification.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (showContactButton) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('Contactar por WhatsApp'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
      isThreeLine: showContactButton,
      trailing: _trailing,
    );
  }
}
