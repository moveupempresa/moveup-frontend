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
      appBar: AppBar(title: const Text('Explorar')),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTextFilterButton(
                    key: 'city',
                    label: 'Ciudad',
                    icon: Icons.location_city_outlined,
                    value: _filterCity,
                  ),
                  _buildTextFilterButton(
                    key: 'style',
                    label: 'Estilo',
                    icon: Icons.style_outlined,
                    value: _filterStyle,
                  ),
                  _buildTextFilterButton(
                    key: 'username',
                    label: 'Usuario',
                    icon: Icons.person_outline,
                    value: _filterUsername,
                  ),
                  _buildDateFilterButton(),
                ],
              ),
            ),
          ),
          if (_expandedFilter != null) _buildExpandedFilterForm(context),
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

  Widget _buildTextFilterButton({
    required String key,
    required String label,
    required IconData icon,
    required String? value,
  }) {
    final active = value != null;
    final selected = _expandedFilter == key;
    return InputChip(
      avatar: Icon(icon, size: 18),
      label: Text(active ? value : label),
      selected: selected,
      onPressed: () => _toggleExpanded(key),
      onDeleted: active ? () => _clearFilter(key) : null,
    );
  }

  Widget _buildDateFilterButton() {
    final active = _filterDateFrom != null;
    final label = active
        ? 'Desde ${_filterDateFrom!.day}/${_filterDateFrom!.month}/${_filterDateFrom!.year}'
        : 'Fecha';
    return InputChip(
      avatar: const Icon(Icons.calendar_month_outlined, size: 18),
      label: Text(label),
      onPressed: _pickDateFilter,
      onDeleted: active ? () => _clearFilter('date') : null,
    );
  }

  Widget _buildExpandedFilterForm(BuildContext context) {
    final (controller, label) = switch (_expandedFilter) {
      'city' => (_cityController, 'Ciudad'),
      'style' => (_styleController, 'Estilo'),
      'username' => (_usernameController, 'Usuario organizador'),
      _ => (_cityController, ''),
    };
    final key = _expandedFilter!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _submitTextFilter(key, controller.text),
          ),
        ),
        textCapitalization:
            key == 'username' ? TextCapitalization.none : TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => _submitTextFilter(key, value),
      ),
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
