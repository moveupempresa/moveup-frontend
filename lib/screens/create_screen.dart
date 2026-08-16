import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import 'event_form_screen.dart';
import 'settings/pro_plan_screen.dart';

class CreateScreen extends StatefulWidget {
  final User user;
  final String token;

  const CreateScreen({super.key, required this.user, required this.token});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  late User _user;
  List<Event>? _drafts;
  bool _loadingDrafts = false;
  String? _draftsError;

  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    if (_isPro) _loadDrafts();
  }

  bool get _isPro => _user.subscriptionPlan == SubscriptionPlan.pro;

  Future<void> _loadDrafts() async {
    setState(() {
      _loadingDrafts = true;
      _draftsError = null;
    });
    try {
      final events = await EventService.getMyEvents(token: widget.token);
      if (mounted) {
        setState(() {
          _drafts = events.where((e) => e.status == EventStatus.draft).toList();
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _draftsError = e.message);
    } finally {
      if (mounted) setState(() => _loadingDrafts = false);
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day} ${_months[local.month - 1]}. ${local.year}';
  }

  Future<void> _openDraft(Event draft) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventFormScreen(token: widget.token, event: draft),
      ),
    );
    if (changed == true) _loadDrafts();
  }

  Future<void> _goToPro() async {
    final updated = await Navigator.of(context).push<User>(
      MaterialPageRoute(
        builder: (_) => ProPlanScreen(
          token: widget.token,
          subscriptionPlan: _user.subscriptionPlan,
        ),
      ),
    );
    if (updated != null) setState(() => _user = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear')),
      body: _isPro ? _buildProContent() : _buildFreeContent(),
    );
  }

  Widget _buildProContent() {
    return RefreshIndicator(
      onRefresh: _loadDrafts,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_outlined, size: 32),
              title: Text(
                'Evento',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: const Text('Clase, workshop, battle, fiesta y más'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EventFormScreen(token: widget.token),
                  ),
                );
                if (changed == true) _loadDrafts();
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
            ),
          ),
          ..._buildDraftsSection(),
        ],
      ),
    );
  }

  List<Widget> _buildDraftsSection() {
    if (_loadingDrafts && _drafts == null) {
      return const [
        SizedBox(height: 32),
        Center(child: CircularProgressIndicator()),
      ];
    }
    if (_draftsError != null && _drafts == null) {
      return [
        const SizedBox(height: 24),
        Text('No se pudieron cargar los borradores'),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _loadDrafts,
            child: const Text('Reintentar'),
          ),
        ),
      ];
    }
    final drafts = _drafts ?? [];
    if (drafts.isEmpty) return const [];

    return [
      const SizedBox(height: 24),
      Text('Borradores', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ...drafts.map(
        (draft) => Card(
          child: ListTile(
            leading: const Icon(Icons.drafts_outlined),
            title: Text(
              draft.title.isEmpty ? 'Sin título' : draft.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('Editado el ${_formatDate(draft.updatedAt)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openDraft(draft),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildFreeContent() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium, size: 64, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Solo para usuarios Pro',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Crea y publica eventos, gestiona reservas y mucho más con el plan Pro.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _goToPro,
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Actualizar a Pro'),
            style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
          ),
        ],
      ),
    );
  }
}
