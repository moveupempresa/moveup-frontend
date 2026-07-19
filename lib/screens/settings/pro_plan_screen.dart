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
    if (_isPro) {
      await _downgrade();
    } else {
      await _openBillingSheet();
    }
  }

  Future<void> _downgrade() async {
    setState(() => _isUpgrading = true);
    try {
      final updatedUser = await UserService.downgradeToFree(token: widget.token);
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

  Future<void> _upgrade(String accountHolderName, String iban) async {
    setState(() => _isUpgrading = true);
    try {
      final updatedUser = await UserService.upgradeToPro(
        token: widget.token,
        accountHolderName: accountHolderName,
        iban: iban,
      );
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

  Future<void> _openBillingSheet() async {
    final nameCtrl = TextEditingController();
    final ibanCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final nameValid = nameCtrl.text.trim().isNotEmpty;
            final ibanValid =
                RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$').hasMatch(ibanCtrl.text.replaceAll(' ', '').toUpperCase());
            final canConfirm = nameValid && ibanValid;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos de facturación', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Necesitamos tu cuenta bancaria para domiciliar el pago mensual del plan Pro.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del titular'),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ibanCtrl,
                    decoration: const InputDecoration(
                      labelText: 'IBAN',
                      hintText: 'ES00 0000 0000 0000 0000 0000',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: canConfirm && !_isUpgrading
                        ? () {
                            Navigator.pop(ctx);
                            _upgrade(nameCtrl.text.trim(), ibanCtrl.text.trim());
                          }
                        : null,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('Confirmar y actualizar a Pro'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
