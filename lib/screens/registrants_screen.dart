import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/pack.dart';
import '../models/registrant.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/registration_service.dart';
import 'public_profile_screen.dart';

enum RegistrantsTargetType { session, pack }

class RegistrantsScreen extends StatefulWidget {
  final String token;
  final String currentUserId;
  final String eventId;
  final RegistrantsTargetType targetType;
  final String targetId;
  final String targetName;
  final List<Session> sessions;
  final PaymentType? paymentType;

  const RegistrantsScreen({
    super.key,
    required this.token,
    required this.currentUserId,
    required this.eventId,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    this.sessions = const [],
    this.paymentType,
  });

  @override
  State<RegistrantsScreen> createState() => _RegistrantsScreenState();
}

class _RegistrantsScreenState extends State<RegistrantsScreen> {
  List<Registrant>? _registrants;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final registrants = widget.targetType == RegistrantsTargetType.session
          ? await RegistrationService.getSessionRegistrants(
              token: widget.token,
              eventId: widget.eventId,
              sessionId: widget.targetId,
            )
          : await RegistrationService.getPackRegistrants(
              token: widget.token,
              eventId: widget.eventId,
              packId: widget.targetId,
            );
      if (mounted) setState(() => _registrants = registrants);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo cargar la lista');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(RegistrationStatus status) => switch (status) {
    RegistrationStatus.confirmed => Colors.green.shade700,
    RegistrationStatus.pending => Colors.grey.shade600,
    RegistrationStatus.waitlisted => Colors.amber.shade800,
    RegistrationStatus.awaitingPayment => Colors.orange.shade800,
  };

  bool get _showsPayment =>
      widget.targetType == RegistrantsTargetType.pack &&
      widget.paymentType != null;

  bool get _canTogglePayment => widget.paymentType != PaymentType.online;

  Future<void> _togglePaid(Registrant r) async {
    final newValue = !r.hasPaid;
    try {
      await RegistrationService.setPackPaymentStatus(
        token: widget.token,
        eventId: widget.eventId,
        packId: widget.targetId,
        userId: r.userId,
        hasPaid: newValue,
      );
      if (mounted) {
        setState(() {
          final index = _registrants!.indexWhere((x) => x.userId == r.userId);
          _registrants![index] = r.copyWith(hasPaid: newValue);
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ocurrió un error')));
      }
    }
  }

  bool get _showsAttendance =>
      widget.targetType == RegistrantsTargetType.session;

  Future<void> _toggleAttendance(Registrant r) async {
    final newValue = !r.attended;
    try {
      await RegistrationService.markSessionAttendance(
        token: widget.token,
        eventId: widget.eventId,
        sessionId: widget.targetId,
        userId: r.userId,
        attended: newValue,
      );
      if (mounted) {
        setState(() {
          final index = _registrants!.indexWhere((x) => x.userId == r.userId);
          _registrants![index] = r.copyWith(attended: newValue);
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ocurrió un error')));
      }
    }
  }

  Future<void> _confirmRevoke(Registrant r) async {
    final name = r.displayName.isNotEmpty ? r.displayName : r.username;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Revocar inscripción?'),
        content: Text('$name perderá su plaza en "${widget.targetName}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await RegistrationService.revokePackRegistration(
        token: widget.token,
        eventId: widget.eventId,
        packId: widget.targetId,
        userId: r.userId,
      );
      if (mounted) {
        setState(() => _registrants!.removeWhere((x) => x.userId == r.userId));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ocurrió un error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.targetName)),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final registrants = _registrants ?? [];
          if (registrants.isEmpty) {
            return Center(
              child: Text(
                'Todavía no hay nadie inscrito',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: registrants.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = registrants[index];
              final sessionNames = r.selectedSessionIds
                  .map(
                    (id) => widget.sessions
                        .where((s) => s.id == id)
                        .firstOrNull
                        ?.name,
                  )
                  .whereType<String>()
                  .toList();
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: r.profileImage != null
                      ? NetworkImage(ApiConfig.mediaUrl(r.profileImage!))
                      : null,
                  child: r.profileImage == null
                      ? const Icon(Icons.person_outline)
                      : null,
                ),
                title: Text(
                  r.displayName.isNotEmpty ? r.displayName : r.username,
                ),
                subtitle: Text(
                  [
                    '@${r.username}',
                    if (sessionNames.isNotEmpty) sessionNames.join(', '),
                    if (r.viaPack != null) 'vía pack "${r.viaPack}"',
                  ].join(' · '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showsAttendance &&
                        r.status == RegistrationStatus.confirmed)
                      IconButton(
                        icon: Icon(
                          r.attended ? Icons.event_available : Icons.close,
                        ),
                        color: r.attended ? Colors.green.shade700 : null,
                        tooltip: r.attended
                            ? 'Marcar como no asistido'
                            : 'Marcar como asistido',
                        onPressed: () => _toggleAttendance(r),
                      ),
                    if (_showsPayment && _canTogglePayment)
                      IconButton(
                        icon: Icon(r.hasPaid ? Icons.paid : Icons.money_off),
                        color: r.hasPaid
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        tooltip: r.hasPaid
                            ? 'Marcar como no pagado'
                            : 'Marcar como pagado',
                        onPressed: () => _togglePaid(r),
                      )
                    else if (_showsPayment)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Tooltip(
                          message: r.hasPaid ? 'Pagado' : 'No pagado',
                          child: Icon(
                            r.hasPaid ? Icons.paid : Icons.money_off,
                            color: r.hasPaid
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    if (widget.targetType == RegistrantsTargetType.pack &&
                        r.status == RegistrationStatus.confirmed)
                      IconButton(
                        icon: const Icon(Icons.person_remove_outlined),
                        color: Theme.of(context).colorScheme.error,
                        tooltip: 'Revocar inscripción',
                        onPressed: () => _confirmRevoke(r),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(r.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _statusColor(r.status)),
                      ),
                      child: Text(
                        r.status.label,
                        style: TextStyle(
                          color: _statusColor(r.status),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(
                      token: widget.token,
                      userId: r.userId,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
