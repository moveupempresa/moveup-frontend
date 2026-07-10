import 'package:flutter/material.dart';

import '../models/user.dart';
import 'event_form_screen.dart';
import 'settings/pro_plan_screen.dart';

class CreateScreen extends StatefulWidget {
  final User user;
  final String token;

  const CreateScreen({super.key, required this.user, required this.token});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  bool get _isPro => _user.subscriptionPlan == SubscriptionPlan.pro;

  Future<void> _goToPro() async {
    final updated = await Navigator.of(context).push<User>(
      MaterialPageRoute(
        builder: (_) => ProPlanScreen(
          token: widget.token,
          subscriptionPlan: _user.subscriptionPlan,
        ),
      ),
    );
    if (updated != null) setState(() => _user = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear')),
      body: _isPro ? _buildProContent() : _buildFreeContent(),
    );
  }

  Widget _buildProContent() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.event_outlined, size: 32),
            title: Text('Evento', style: Theme.of(context).textTheme.titleMedium),
            subtitle: const Text('Clase, workshop, battle, fiesta y más'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventFormScreen(token: widget.token),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildFreeContent() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium, size: 64, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Solo para usuarios Pro',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Crea y publica eventos, gestiona reservas y mucho más con el plan Pro.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _goToPro,
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Actualizar a Pro'),
            style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
          ),
        ],
      ),
    );
  }
}
