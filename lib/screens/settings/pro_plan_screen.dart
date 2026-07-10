import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class ProPlanScreen extends StatefulWidget {
  final String token;
  final SubscriptionPlan subscriptionPlan;

  const ProPlanScreen({
    super.key,
    required this.token,
    required this.subscriptionPlan,
  });

  @override
  State<ProPlanScreen> createState() => _ProPlanScreenState();
}

class _ProPlanScreenState extends State<ProPlanScreen> {
  bool _isUpgrading = false;

  static const _features = [
    (Icons.event_outlined, 'Publicar eventos'),
    (Icons.book_online_outlined, 'Gestionar reservas'),
    (Icons.checklist_outlined, 'Control asistencia'),
    (Icons.build_outlined, 'Herramientas profesionales'),
    (Icons.workspace_premium_outlined, 'Perfil visual premium'),
    (Icons.tune_outlined, 'Personalización avanzada perfil'),
  ];

  bool get _isPro => widget.subscriptionPlan == SubscriptionPlan.pro;

  Future<void> _changePlan() async {
    setState(() => _isUpgrading = true);
    try {
      final updatedUser = _isPro
          ? await UserService.downgradeToFree(token: widget.token)
          : await UserService.upgradeToPro(token: widget.token);
      if (!mounted) return;
      Navigator.of(context).pop(updatedUser);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isUpgrading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Pro')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.workspace_premium,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Desbloquea todo con Pro',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ...(_features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(f.$1, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 16),
                      Text(f.$2, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              )),
              const Spacer(),
              FilledButton(
                onPressed: _isUpgrading ? null : _changePlan,
                child: _isUpgrading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isPro ? 'Volver al plan gratuito' : 'Actualizar a Pro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
