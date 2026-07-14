import 'package:flutter/material.dart';

import '../config/api_config.dart';
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

  const RegistrantsScreen({
    super.key,
    required this.token,
    required this.currentUserId,
    required this.eventId,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    this.sessions = const [],
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
              token: widget.token, eventId: widget.eventId, sessionId: widget.targetId)
          : await RegistrationService.getPackRegistrants(
              token: widget.token, eventId: widget.eventId, packId: widget.targetId);
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
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.targetName)),
      body: Builder(builder: (context) {
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
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
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
                .map((id) => widget.sessions.where((s) => s.id == id).firstOrNull?.name)
                .whereType<String>()
                .toList();
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    r.profileImage != null ? NetworkImage(ApiConfig.mediaUrl(r.profileImage!)) : null,
                child: r.profileImage == null ? const Icon(Icons.person_outline) : null,
              ),
              title: Text(r.displayName.isNotEmpty ? r.displayName : r.username),
              subtitle: Text(
                [
                  '@${r.username}',
                  if (sessionNames.isNotEmpty) sessionNames.join(', '),
                ].join(' · '),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      }),
    );
  }
}
