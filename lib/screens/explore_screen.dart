import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String token;
  final String currentUserId;

  const ExploreScreen({super.key, required this.token, required this.currentUserId});

  @override
  ExploreScreenState createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();

  List<Event>? _events;
  bool _loading = false;
  String? _error;

  String? _searchTitle;
  String? _filterCity;
  String? _filterStyle;
  String? _filterUsername;
  DateTime? _filterDateFrom;

  bool get _hasActiveFilters =>
      _searchTitle != null ||
      _filterCity != null ||
      _filterStyle != null ||
      _filterUsername != null ||
      _filterDateFrom != null;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await EventService.getPublicEvents(
        token: widget.token,
        title: _searchTitle,
        city: _filterCity,
        style: _filterStyle,
        username: _filterUsername,
        dateFrom: _filterDateFrom,
      );
      if (mounted) setState(() => _events = events);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void refreshEvents() => _loadEvents();

  void _submitSearch(String value) {
    setState(() => _searchTitle = value.trim().isEmpty ? null : value.trim());
    _loadEvents();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchTitle = null);
    _loadEvents();
  }

  Future<void> _openFilterSheet() async {
    final cityCtrl = TextEditingController(text: _filterCity ?? '');
    final styleCtrl = TextEditingController(text: _filterStyle ?? '');
    final usernameCtrl = TextEditingController(text: _filterUsername ?? '');
    DateTime? dateFrom = _filterDateFrom;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            String fmt(DateTime? dt) {
              if (dt == null) return 'Cualquier fecha';
              return '${dt.day}/${dt.month}/${dt.year}';
            }

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filtrar eventos', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  TextField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(labelText: 'Ciudad'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: styleCtrl,
                    decoration: const InputDecoration(labelText: 'Estilo'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(labelText: 'Usuario organizador'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dateFrom ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        locale: const Locale('es', 'ES'),
                      );
                      if (picked != null) setSheetState(() => dateFrom = picked);
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text('Desde: ${fmt(dateFrom)}'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                  if (dateFrom != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setSheetState(() => dateFrom = null),
                        child: const Text('Quitar fecha'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _filterCity = cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim();
                        _filterStyle = styleCtrl.text.trim().isEmpty ? null : styleCtrl.text.trim();
                        _filterUsername =
                            usernameCtrl.text.trim().isEmpty ? null : usernameCtrl.text.trim();
                        _filterDateFrom = dateFrom;
                      });
                      Navigator.pop(ctx);
                      _loadEvents();
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('Aplicar filtros'),
                  ),
                  if (_hasActiveFilters) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterCity = null;
                          _filterStyle = null;
                          _filterUsername = null;
                          _filterDateFrom = null;
                        });
                        Navigator.pop(ctx);
                        _loadEvents();
                      },
                      child: const Text('Limpiar filtros'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _clearFilter(String key) {
    setState(() {
      switch (key) {
        case 'city':
          _filterCity = null;
        case 'style':
          _filterStyle = null;
        case 'username':
          _filterUsername = null;
        case 'date':
          _filterDateFrom = null;
      }
    });
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list_outlined),
            ),
            tooltip: 'Filtrar',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar eventos por nombre',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchTitle != null
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _submitSearch,
            ),
          ),
          if (_hasActiveFilters) _buildFilterChips(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadEvents,
              child: _buildBody(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final chips = <Widget>[];
    if (_searchTitle != null) {
      chips.add(_filterChip('"$_searchTitle"', _clearSearch));
    }
    if (_filterCity != null) {
      chips.add(_filterChip('Ciudad: $_filterCity', () => _clearFilter('city')));
    }
    if (_filterStyle != null) {
      chips.add(_filterChip('Estilo: $_filterStyle', () => _clearFilter('style')));
    }
    if (_filterUsername != null) {
      chips.add(_filterChip('Usuario: $_filterUsername', () => _clearFilter('username')));
    }
    if (_filterDateFrom != null) {
      final d = _filterDateFrom!;
      chips.add(_filterChip('Desde ${d.day}/${d.month}/${d.year}', () => _clearFilter('date')));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _filterChip(String label, VoidCallback onDeleted) {
    return InputChip(label: Text(label), onDeleted: onDeleted);
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _events == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          const Text('No se pudieron cargar los eventos', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: _loadEvents, child: const Text('Reintentar'))),
        ],
      );
    }
    if (_events == null || _events!.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.explore_outlined,
              size: 40, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            _hasActiveFilters
                ? 'Ningún evento coincide con estos filtros'
                : 'Todavía no hay eventos publicados',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _events!.length,
      itemBuilder: (context, index) {
        final event = _events![index];
        return EventCard(
          event: event,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(
                token: widget.token,
                event: event,
                currentUserId: widget.currentUserId,
              ),
            ),
          ),
        );
      },
    );
  }
}
