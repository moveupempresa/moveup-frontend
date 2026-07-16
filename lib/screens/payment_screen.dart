import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/registration_service.dart';

class PaymentScreen extends StatefulWidget {
  final String token;
  final String eventId;
  final String packId;
  final String packName;

  const PaymentScreen({
    super.key,
    required this.token,
    required this.eventId,
    required this.packId,
    required this.packName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isPaying = false;

  Future<void> _pay() async {
    setState(() => _isPaying = true);
    try {
      await RegistrationService.payForPack(
        token: widget.token,
        eventId: widget.eventId,
        packId: widget.packId,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago realizado')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ocurrió un error')));
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  void _openBizumSheet() {
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final phoneValid = RegExp(r'^[0-9]{9}$').hasMatch(phoneCtrl.text.trim());
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
                  Text('Pagar con Bizum', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Número de teléfono',
                      hintText: '600000000',
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: phoneValid && !_isPaying
                        ? () {
                            Navigator.pop(ctx);
                            _pay();
                          }
                        : null,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('Pagar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openCardSheet() {
    final numberCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final numberValid =
                RegExp(r'^[0-9]{13,19}$').hasMatch(numberCtrl.text.replaceAll(' ', ''));
            final expiryValid = RegExp(r'^(0[1-9]|1[0-2])\/[0-9]{2}$').hasMatch(expiryCtrl.text.trim());
            final cvvValid = RegExp(r'^[0-9]{3,4}$').hasMatch(cvvCtrl.text.trim());
            final nameValid = nameCtrl.text.trim().isNotEmpty;
            final canPay = numberValid && expiryValid && cvvValid && nameValid;

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
                  Text('Pagar con tarjeta', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del titular'),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: numberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Número de tarjeta',
                      hintText: '0000 0000 0000 0000',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: expiryCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Caducidad',
                            hintText: 'MM/AA',
                          ),
                          keyboardType: TextInputType.datetime,
                          maxLength: 5,
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: cvvCtrl,
                          decoration: const InputDecoration(labelText: 'CVV'),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: canPay && !_isPaying
                        ? () {
                            Navigator.pop(ctx);
                            _pay();
                          }
                        : null,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('Pagar'),
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
      appBar: AppBar(title: const Text('Pago')),
      body: AbsorbPointer(
        absorbing: _isPaying,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pagar "${widget.packName}"',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Elige un método de pago',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 20),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      'B',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: const Text('Bizum'),
                  trailing: _isPaying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isPaying ? null : _openBizumSheet,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Tarjeta'),
                  trailing: _isPaying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isPaying ? null : _openCardSheet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
