import 'package:flutter/material.dart';

/// Small muted pill marking something as over - a past session, pack, or
/// event. Reused wherever a card needs to flag that without the heavier
/// grayscale/shadow treatment this app deliberately avoids on event cards.
class FinishedBadge extends StatelessWidget {
  final String label;

  const FinishedBadge({super.key, this.label = 'Finalizado'});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: outline.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: outline, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: outline,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
