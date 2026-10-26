import 'package:flutter/material.dart';

class SignupActionButton extends StatelessWidget {
  final bool isFull;
  final bool isSignedUp;
  final bool isWaitlisted;
  final bool isPending;
  final bool isAwaitingPayment;
  final bool isLoading;
  final bool isExpandable;
  final bool isExpanded;
  final String defaultLabel;
  final IconData? payIcon;
  final String? payTooltip;
  final VoidCallback? onPay;
  final VoidCallback onToggleSignUp;
  final VoidCallback onToggleWaitlist;

  const SignupActionButton({
    super.key,
    required this.isFull,
    required this.isSignedUp,
    required this.isWaitlisted,
    this.isPending = false,
    this.isAwaitingPayment = false,
    required this.isLoading,
    this.isExpandable = false,
    this.isExpanded = false,
    this.defaultLabel = 'Reservar',
    this.payIcon,
    this.payTooltip,
    this.onPay,
    required this.onToggleSignUp,
    required this.onToggleWaitlist,
  });

  Widget _button(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    final button = FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final primary = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;
    if (isPending) {
      return _button(
        context,
        icon: Icons.hourglass_top,
        label: 'Pendiente',
        color: primary,
        tooltip: 'Solicitud pendiente de aprobación · toca para cancelar',
        onPressed: onToggleSignUp,
      );
    }
    if (isAwaitingPayment) {
      if (onPay != null) {
        return _button(
          context,
          icon: payIcon ?? Icons.payment,
          label: 'Pagar',
          color: Colors.amber.shade800,
          tooltip: payTooltip,
          onPressed: onPay!,
        );
      }
      return _button(
        context,
        icon: Icons.hourglass_bottom,
        label: 'Pago pendiente',
        color: Colors.amber.shade800,
        tooltip: 'Esperando tu pago · toca para cancelar',
        onPressed: onToggleSignUp,
      );
    }
    if (isFull && !isSignedUp) {
      return _button(
        context,
        icon: isWaitlisted
            ? Icons.notifications_active
            : Icons.notifications_none,
        label: isWaitlisted ? 'En espera' : 'Avisarme',
        color: isWaitlisted ? primary : outline,
        tooltip: isWaitlisted
            ? 'Cancelar aviso de disponibilidad'
            : 'Avisarme si hay un cupo disponible',
        onPressed: onToggleWaitlist,
      );
    }
    if (isExpandable && !isSignedUp) {
      return _button(
        context,
        icon: isExpanded ? Icons.expand_less : Icons.checklist,
        label: isExpanded ? 'Ocultar' : 'Elegir sesiones',
        color: isExpanded ? primary : outline,
        onPressed: onToggleSignUp,
      );
    }
    return _button(
      context,
      icon: isSignedUp ? Icons.check_circle : Icons.check_circle_outline,
      label: isSignedUp ? 'Cancelar' : defaultLabel,
      color: isSignedUp ? primary : outline,
      tooltip: isSignedUp ? 'Cancelar inscripción' : null,
      onPressed: onToggleSignUp,
    );
  }
}
