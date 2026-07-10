import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView(
        children: const [
          _NotificationSection(title: 'Reservas', icon: Icons.calendar_today_outlined),
          _NotificationSection(title: 'Mis Eventos', icon: Icons.school_outlined),
          _NotificationSection(title: 'Perfiles guardados', icon: Icons.bookmark_outline),
          _NotificationSection(title: 'Recordatorios', icon: Icons.alarm_outlined),
        ],
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
