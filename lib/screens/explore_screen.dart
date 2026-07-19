import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';
import 'public_profile_screen.dart';

const _textFilterKeys = ['city', 'style', 'username', 'price'];
const _carouselKeys = ['city', 'style', 'username', 'price', 'date', 'eventType'];

class ExploreScreen extends StatefulWidget {
  final String token;
  final String currentUserId;

  const ExploreScreen({super.key, required this.token, required this.currentUserId});

  @override
  ExploreScreenState createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final _filterInputController = TextEditingController();

  List<Event>? _events;
  bool _loading = false;
  String? _error;

  String? _activeFilterKey;

  String? _searchTitle;
  String? _filterCity;
  String? _filterStyle;
  String? _filterUsername;
  DateTime? _filterDateFrom;
  double? _filterMaxPrice;
  EventType? _filterEventType;

  bool get _hasFilterValues =>
      _filterCity != null ||
      _filterStyle != null ||
      _filterUsername != null ||
      _filterDateFrom != null ||
      _filterMaxPrice != null ||
      _filterEventType != null;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterInputController.dispose();
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
        maxPrice: _filterMaxPrice,
        eventType: _filterEventType,
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

  String _filterLabel(String key) => switch (key) {
        'city' => 'Ciudad',
        'style' => 'Estilo',
        'username' => 'Usuario',
        'price' => 'Precio',
        'date' => 'Fecha',
        'eventType' => 'Tipo de evento',
        _ => key,
      };

  // Formatted for display: chips, and the running "; "-joined preview.
  String? _filterValue(String key) => switch (key) {
        'city' => _filterCity,
        'style' => _filterStyle,
        'username' => _filterUsername,
        'price' => _filterMaxPrice != null ? '${_filterMaxPrice!.toStringAsFixed(0)} €' : null,
        'date' => _filterDateFrom != null
            ? 'Desde ${_filterDateFrom!.day}/${_filterDateFrom!.month}/${_filterDateFrom!.year}'
            : null,
        'eventType' => _filterEventType?.label,
        _ => null,
      };

  // Raw editable text for text-based filters, used to prefill the input when
  // re-opening an already-set filter.
  String? _filterRawValue(String key) => switch (key) {
        'city' => _filterCity,
        'style' => _filterStyle,
        'username' => _filterUsername,
        'price' => _filterMaxPrice?.toStringAsFixed(0),
        _ => null,
      };

  String _committedSummary({String? excludeKey}) {
    final parts = _textFilterKeys
        .where((k) => k != excludeKey)
        .map(_filterValue)
        .whereType<String>()
        .toList();
    return parts.isEmpty ? '' : '${parts.join('; ')}; ';
  }

  void _commitActiveTextFilter() {
    final key = _activeFilterKey;
    if (key == null || !_textFilterKeys.contains(key)) return;
    final value = _filterInputController.text.trim();
    switch (key) {
      case 'city':
        _filterCity = value.isEmpty ? null : value;
      case 'style':
        _filterStyle = value.isEmpty ? null : value;
      case 'username':
        _filterUsername = value.isEmpty ? null : value;
      case 'price':
        _filterMaxPrice = value.isEmpty ? null : double.tryParse(value.replaceAll(',', '.'));
    }
  }

  void _activateFilter(String key) {
    setState(() {
      _commitActiveTextFilter();
      if (_activeFilterKey == key) {
        _activeFilterKey = null;
        return;
      }
      _activeFilterKey = key;
      _filterInputController.text = _filterRawValue(key) ?? '';
      _filterInputController.selection =
          TextSelection.collapsed(offset: _filterInputController.text.length);
    });
  }

  void _finishActiveTextFilter() {
    setState(() {
      _commitActiveTextFilter();
      _activeFilterKey = null;
    });
  }

  Future<void> _pickDateFilter() async {
    setState(() {
      _commitActiveTextFilter();
      _activeFilterKey = null;
    });
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDateFrom ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) setState(() => _filterDateFrom = picked);
  }

  void _selectEventTypeFilter(EventType type) {
    setState(() {
      _filterEventType = _filterEventType == type ? null : type;
      _activeFilterKey = null;
    });
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
        case 'price':
          _filterMaxPrice = null;
        case 'eventType':
          _filterEventType = null;
      }
      if (_activeFilterKey == key) {
        _filterInputController.clear();
        _activeFilterKey = null;
      }
    });
    _loadEvents();
  }

  void _clearAllFilters() {
    setState(() {
      _filterCity = null;
      _filterStyle = null;
      _filterUsername = null;
      _filterDateFrom = null;
      _filterMaxPrice = null;
      _filterEventType = null;
      _filterInputController.clear();
      _activeFilterKey = null;
    });
    _loadEvents();
  }

  void _runSearch() {
    setState(() {
      _commitActiveTextFilter();
      final title = _searchController.text.trim();
      _searchTitle = title.isEmpty ? null : title;
      _activeFilterKey = null;
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
            child: Row(
              children: [
                Expanded(child: _buildFilterCarousel(context)),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar',
                  onPressed: _runSearch,
                ),
              ],
            ),
          ),
          if (_activeFilterKey != null) _buildActiveFilterInput(context),
          if (_hasFilterValues) _buildActiveFilterChips(context),
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

  Widget _buildFilterCarousel(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _carouselKeys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = _carouselKeys[index];
          final hasValue = _filterValue(key) != null;
          return ChoiceChip(
            label: Text(_filterLabel(key)),
            selected: _activeFilterKey == key,
            showCheckmark: false,
            avatar: hasValue ? const Icon(Icons.check, size: 16) : null,
            onSelected: (_) => key == 'date' ? _pickDateFilter() : _activateFilter(key),
          );
        },
      ),
    );
  }

  Widget _buildActiveFilterInput(BuildContext context) {
    final key = _activeFilterKey!;
    if (key == 'eventType') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EventType.values
              .map((t) => ChoiceChip(
                    label: Text(t.label),
                    selected: _filterEventType == t,
                    onSelected: (_) => _selectEventTypeFilter(t),
                  ))
              .toList(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _filterInputController,
        autofocus: true,
        decoration: InputDecoration(
          prefixText: _committedSummary(excludeKey: key),
          labelText: _filterLabel(key),
          hintText: key == 'style'
              ? '#urbano #rave'
              : key == 'price'
                  ? 'Ej: 30'
                  : null,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check),
            onPressed: _finishActiveTextFilter,
          ),
        ),
        textCapitalization:
            key == 'username' || key == 'price' ? TextCapitalization.none : TextCapitalization.words,
        keyboardType: key == 'price' ? const TextInputType.numberWithOptions(decimal: true) : null,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _finishActiveTextFilter(),
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
    if (_filterMaxPrice != null) {
      chips.add(_summaryChip(
          'Hasta ${_filterMaxPrice!.toStringAsFixed(0)} €', () => _clearFilter('price')));
    }
    if (_filterEventType != null) {
      chips.add(_summaryChip('Tipo: ${_filterEventType!.label}', () => _clearFilter('eventType')));
    }
    chips.add(ActionChip(
      label: const Text('Limpiar filtros'),
      avatar: const Icon(Icons.clear_all, size: 16),
      onPressed: _clearAllFilters,
    ));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _summaryChip(String label, VoidCallback onDeleted) =>
      InputChip(label: Text(label), onDeleted: onDeleted);

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
            _hasFilterValues || _searchTitle != null
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
