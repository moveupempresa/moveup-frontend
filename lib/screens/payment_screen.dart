import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  final String packName;

  const PaymentScreen({super.key, required this.packName});

  void _selectMethod(BuildContext context, String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pago con $method próximamente disponible')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagar "$packName"',
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
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectMethod(context, 'Bizum'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
                title: const Text('Tarjeta'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectMethod(context, 'tarjeta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
