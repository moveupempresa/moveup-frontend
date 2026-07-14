import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final String token;

  const NotificationsScreen({super.key, required this.token});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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

  void _onFollowSectionExpanded(bool expanded) {
    if (!expanded || _markedRead) return;
    final hasUnread = _notifications?.any((n) => !n.read) ?? false;
    if (!hasUnread) return;
    _markedRead = true;
    NotificationService.markAllAsRead(token: widget.token).catchError((_) {});
  }

  List<AppNotification> get _followNotifications =>
      (_notifications ?? [])
          .where((n) =>
              n.type == NotificationType.followedUser ||
              n.type == NotificationType.followedUserNewEvent)
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView(
        children: [
          const _NotificationSection(title: 'Reservas', icon: Icons.calendar_today_outlined),
          const _NotificationSection(title: 'Mis Eventos', icon: Icons.school_outlined),
          _buildFollowSection(context),
          const _NotificationSection(title: 'Recordatorios', icon: Icons.alarm_outlined),
        ],
      ),
    );
  }

  Widget _buildFollowSection(BuildContext context) {
    final items = _followNotifications;
    final unreadCount = items.where((n) => !n.read).length;

    return Column(
      children: [
        ExpansionTile(
          leading: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.bookmark_outline),
          ),
          title: const Text('Perfiles guardados'),
          onExpansionChanged: _onFollowSectionExpanded,
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
              ...items.map((n) => _FollowNotificationTile(notification: n)),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _FollowNotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _FollowNotificationTile({required this.notification});

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day} ${_months[local.month - 1]}. ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final icon = notification.type == NotificationType.followedUser
        ? Icons.person_add_alt_outlined
        : Icons.event_available_outlined;

    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
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
      trailing: notification.read
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
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
