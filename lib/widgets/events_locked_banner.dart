import 'package:flutter/material.dart';

class EventsLockedBanner extends StatelessWidget {
  final VoidCallback onUpgrade;

  const EventsLockedBanner({super.key, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Los eventos son exclusivos del plan Pro',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onUpgrade,
            child: const Text('Ver plan Pro'),
          ),
        ],
      ),
    );
  }
}
