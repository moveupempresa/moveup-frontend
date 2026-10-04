import 'package:flutter/material.dart';

/// The notification bell, shown top-right on every main tab except Crear.
/// Unread state is tracked centrally by [HomeScreen] (one check covers
/// every tab, rather than each screen polling independently).
class NotificationBellButton extends StatelessWidget {
  final bool hasUnread;
  final VoidCallback onTap;

  const NotificationBellButton({
    super.key,
    required this.hasUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Badge(
        isLabelVisible: hasUnread,
        smallSize: 8,
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: 'Notificaciones',
      onPressed: onTap,
    );
  }
}
