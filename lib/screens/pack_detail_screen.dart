import 'package:flutter/material.dart';

import '../models/pack.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/registration_service.dart';
import '../utils/session_format.dart';
import '../widgets/sessions_section.dart';
import '../widgets/signup_action_button.dart';
import 'payment_screen.dart';

IconData _packPaymentIcon(PaymentType type) => switch (type) {
  PaymentType.online => Icons.credit_card,
  PaymentType.offline => Icons.money,
  PaymentType.bizum => Icons.phone_android,
  PaymentType.paypal => Icons.account_balance_wallet,
};

String _packPaymentTooltip(PaymentType type) => switch (type) {
  PaymentType.online => 'Pagar con tarjeta',
  PaymentType.offline => 'Pago en efectivo',
  PaymentType.bizum => 'Pagar por Bizum',
  PaymentType.paypal => 'Pagar por PayPal',
};

/// Full-page detail for a pack, opened by a student tapping its (closed)
/// card on the event detail screen. Shows everything about the pack -
/// place/date/time of every session it includes, price and payment method -
/// and is where reserving (and, for self-pay packs, paying) actually
/// happens, instead of inline in the collapsed card.
class PackDetailScreen extends StatefulWidget {
  final String token;
  final String eventId;
  final Pack pack;
  final List<Session> sessions;

  const PackDetailScreen({
    super.key,
    required this.token,
    required this.eventId,
    required this.pack,
    required this.sessions,
  });

  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  late bool _isSignedUp = widget.pack.isSignedUp;
  late bool _isPending = widget.pack.isPending;
  late bool _isAwaitingPayment = widget.pack.isAwaitingPayment;
  late final Set<String> _selectedSessionIds = widget.pack.mySelectedSessionIds
      .toSet();
  bool _isLoading = false;

  bool get _isCommitted => _isSignedUp || _isPending || _isAwaitingPayment;
  bool get _isCustomizable => widget.pack.packType == PackType.customizable;

  bool get _selectionValid {
    if (_selectedSessionIds.isEmpty) return false;
    final max = widget.pack.maxSelectableSessions;
    return max == null || _selectedSessionIds.length <= max;
  }

  String? get _currentStatus => _isSignedUp
      ? 'confirmed'
      : _isPending
      ? 'pending'
      : _isAwaitingPayment
      ? 'awaiting_payment'
      : null;

  void _onSessionToggled(String sessionId, bool checked) {
    setState(() {
      if (checked) {
        _selectedSessionIds.add(sessionId);
      } else {
        _selectedSessionIds.remove(sessionId);
      }
    });
  }

  void _showError(Object e) {
    if (e is AuthException && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggleSignUp() async {
    if (_isCommitted) {
      setState(() => _isLoading = true);
      try {
        final (status, _) = await RegistrationService.cancelPackSignUp(
          token: widget.token,
          eventId: widget.eventId,
          packId: widget.pack.id,
        );
        if (mounted) {
          setState(() {
            _isSignedUp = status == 'confirmed';
            _isPending = status == 'pending';
            _isAwaitingPayment = status == 'awaiting_payment';
          });
        }
      } catch (e) {
        _showError(e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }
    await _confirmSignUp();
  }

  Future<void> _confirmSignUp() async {
    if (_isCustomizable && !_selectionValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.pack.maxSelectableSessions != null
                ? 'Selecciona entre 1 y ${widget.pack.maxSelectableSessions} sesiones'
                : 'Selecciona al menos una sesión',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final (status, _) = await RegistrationService.signUpForPack(
        token: widget.token,
        eventId: widget.eventId,
        packId: widget.pack.id,
        selectedSessionIds: _isCustomizable
            ? _selectedSessionIds.toList()
            : null,
      );
      if (mounted) {
        setState(() {
          _isSignedUp = status == 'confirmed';
          _isPending = status == 'pending';
          _isAwaitingPayment = status == 'awaiting_payment';
        });
      }
      if (status == 'confirmed') {
        _showReservationConfirmed();
      } else if (status == 'awaiting_payment') {
        await _openPayment();
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openPayment() async {
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          token: widget.token,
          eventId: widget.eventId,
          packId: widget.pack.id,
          packName: widget.pack.name,
          paymentType: widget.pack.paymentType,
          paymentDetails: widget.pack.paymentDetails,
          bizumConcept: widget.pack.bizumConcept,
        ),
      ),
    );
    // payForPack and uploadPaymentProof only ever resolve awaiting_payment
    // straight to confirmed on success, so this is always the right status.
    if (success == true && mounted) {
      setState(() {
        _isSignedUp = true;
        _isPending = false;
        _isAwaitingPayment = false;
      });
      _showReservationConfirmed();
    }
  }

  void _showReservationConfirmed() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reserva confirmada'),
        content: Text(
          '${widget.pack.name}\n${widget.pack.price.toStringAsFixed(2)} ${widget.pack.currency}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(Session s) {
    final start = s.startDatetime;
    final end = s.endDatetime;
    final showCheckbox = _isCustomizable && !_isCommitted;
    final selected = _selectedSessionIds.contains(s.id);
    final showCheckmark = _isCustomizable && _isCommitted && selected;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: showCheckbox
            ? Checkbox(
                value: selected,
                onChanged: (v) => _onSessionToggled(s.id, v ?? false),
              )
            : showCheckmark
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        title: Text(
          s.name,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${formatSessionDate(start)} · ${formatSessionTime(start)} – ${formatSessionTime(end)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (s.address != null && s.address!.isNotEmpty)
              Text(s.address!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        onTap: showCheckbox ? () => _onSessionToggled(s.id, !selected) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;
    final colorScheme = Theme.of(context).colorScheme;
    final candidateSessions = pack.sessionIds
        .map((id) => widget.sessions.where((s) => s.id == id).firstOrNull)
        .whereType<Session>()
        .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_currentStatus);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(pack.name)),
        body: AbsorbPointer(
          absorbing: _isLoading,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Icon(Icons.payments_outlined, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    '${pack.price.toStringAsFixed(2)} ${pack.currency}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(_packPaymentIcon(pack.paymentType), size: 16),
                  const SizedBox(width: 10),
                  Text(
                    pack.paymentType.label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (pack.description != null && pack.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  pack.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              if (_isCustomizable && !_isCommitted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    pack.maxSelectableSessions != null
                        ? 'Elige hasta ${pack.maxSelectableSessions} sesiones'
                        : 'Elige tus sesiones',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              SessionsSection(
                title: 'Sesiones incluidas',
                sessions: candidateSessions,
                cardBuilder: _buildSessionTile,
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: SignupActionButton(
              isFull: false,
              isSignedUp: _isSignedUp,
              isWaitlisted: false,
              isPending: _isPending,
              isAwaitingPayment: _isAwaitingPayment,
              isLoading: _isLoading,
              defaultLabel: pack.paymentType == PaymentType.offline
                  ? 'Reservar'
                  : 'Reservar y pagar',
              payIcon: _packPaymentIcon(pack.paymentType),
              payTooltip: _packPaymentTooltip(pack.paymentType),
              onPay: pack.paymentType == PaymentType.offline
                  ? null
                  : _openPayment,
              onToggleSignUp: _toggleSignUp,
              onToggleWaitlist: () {},
            ),
          ),
        ),
      ),
    );
  }
}
