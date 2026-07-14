import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';
import 'public_profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String token;
  final String currentUserId;

  const ExploreScreen({super.key, required this.token, required this.currentUserId});

  @override
  ExploreScreenState createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _cityController = TextEditingController();
  final _styleController = TextEditingController();
  final _usernameController = TextEditingController();

  List<Event>? _events;
  bool _loading = false;
  String? _error;

  String? _expandedFilter;

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
    _cityController.dispose();
    _styleController.dispose();
    _usernameController.dispose();
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

  void _toggleExpanded(String key) {
    setState(() => _expandedFilter = _expandedFilter == key ? null : key);
  }

  void _submitTextFilter(String key, String value) {
    final trimmed = value.trim().isEmpty ? null : value.trim();
    setState(() {
      switch (key) {
        case 'city':
          _filterCity = trimmed;
        case 'style':
          _filterStyle = trimmed;
        case 'username':
          _filterUsername = trimmed;
      }
      _expandedFilter = null;
    });
    _loadEvents();
  }

  Future<void> _pickDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDateFrom ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _filterDateFrom = picked);
      _loadEvents();
    }
  }

  void _clearFilter(String key) {
    setState(() {
      switch (key) {
        case 'city':
          _filterCity = null;
          _cityController.clear();
        case 'style':
          _filterStyle = null;
          _styleController.clear();
        case 'username':
          _filterUsername = null;
          _usernameController.clear();
        case 'date':
          _filterDateFrom = null;
      }
      if (_expandedFilter == key) _expandedFilter = null;
    });
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filtrar',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildFilterDrawer(context),
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
          if (_hasActiveFilters) _buildActiveFilterChips(context),
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

  Widget _buildActiveFilterChips(BuildContext context) {
    final chips = <Widget>[];
    if (_filterCity != null) {
      chips.add(_summaryChip('Ciudad: $_filterCity', () => _clearFilter('city')));
    }
    if (_filterStyle != null) {
      chips.add(_summaryChip('Estilo: $_filterStyle', () => _clearFilter('style')));
    }
    if (_filterUsername != null) {
      chips.add(_summaryChip('Usuario: $_filterUsername', () => _clearFilter('username')));
    }
    if (_filterDateFrom != null) {
      final d = _filterDateFrom!;
      chips.add(_summaryChip('Desde ${d.day}/${d.month}/${d.year}', () => _clearFilter('date')));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _summaryChip(String label, VoidCallback onDeleted) =>
      InputChip(label: Text(label), onDeleted: onDeleted);

  Widget _buildFilterDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Filtrar eventos', style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerFilterTile(
                    filterKey: 'city',
                    label: 'Ciudad',
                    icon: Icons.location_city_outlined,
                    value: _filterCity,
                  ),
                  _buildDrawerFilterTile(
                    filterKey: 'style',
                    label: 'Estilo',
                    icon: Icons.style_outlined,
                    value: _filterStyle,
                  ),
                  _buildDrawerFilterTile(
                    filterKey: 'username',
                    label: 'Usuario',
                    icon: Icons.person_outline,
                    value: _filterUsername,
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Fecha'),
                    subtitle: _filterDateFrom != null
                        ? Text(
                            'Desde ${_filterDateFrom!.day}/${_filterDateFrom!.month}/${_filterDateFrom!.year}')
                        : null,
                    trailing: _filterDateFrom != null
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _clearFilter('date'),
                          )
                        : null,
                    onTap: _pickDateFilter,
                  ),
                ],
              ),
            ),
            if (_hasActiveFilters) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterCity = null;
                      _filterStyle = null;
                      _filterUsername = null;
                      _filterDateFrom = null;
                      _cityController.clear();
                      _styleController.clear();
                      _usernameController.clear();
                      _expandedFilter = null;
                    });
                    _loadEvents();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Limpiar filtros'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerFilterTile({
    required String filterKey,
    required String label,
    required IconData icon,
    required String? value,
  }) {
    final expanded = _expandedFilter == filterKey;
    final controller = switch (filterKey) {
      'city' => _cityController,
      'style' => _styleController,
      'username' => _usernameController,
      _ => _cityController,
    };

    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(label),
          subtitle: value != null ? Text(value) : null,
          trailing: value != null
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _clearFilter(filterKey),
                )
              : Icon(expanded ? Icons.expand_less : Icons.expand_more),
          onTap: () => _toggleExpanded(filterKey),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => _submitTextFilter(filterKey, controller.text),
                ),
              ),
              textCapitalization:
                  filterKey == 'username' ? TextCapitalization.none : TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) => _submitTextFilter(filterKey, value),
            ),
          ),
      ],
    );
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
          onOwnerTap: event.ownerUserId == widget.currentUserId
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(
                        token: widget.token,
                        userId: event.ownerUserId,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  ),
        );
      },
    );
  }
}
