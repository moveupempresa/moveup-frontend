import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/explore_sections.dart';
import '../models/popular_profile.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import '../widgets/event_mini_card.dart';
import '../widgets/profile_mini_card.dart';
import 'event_detail_screen.dart';
import 'public_profile_screen.dart';

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

  List<Event>? _events;
  bool _loading = false;
  String? _error;

  ExploreSections? _sections;
  bool _loadingSections = false;
  String? _sectionsError;

  // null means the search field is in "title" mode. Otherwise it's the key
  // of the text filter (city/style/username/price) currently being typed.
  String? _activeFilterKey;
  // Only 'eventType' uses an inline picker separate from the search field.
  String? _expandedPicker;

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

  bool get _isSearching => _hasFilterValues || _searchTitle != null;

  @override
  void initState() {
    super.initState();
    _loadSections();
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

  void refreshEvents() {
    _loadSections();
    if (_events != null) _loadEvents();
  }

  Future<void> _loadSections() async {
    setState(() {
      _loadingSections = true;
      _sectionsError = null;
    });
    try {
      final sections = await EventService.getExploreSections(token: widget.token);
      if (mounted) setState(() => _sections = sections);
    } catch (e) {
      if (mounted) setState(() => _sectionsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingSections = false);
    }
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

  // Formatted for the carousel "has value" indicator and the chips summary.
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

  // Raw editable text for the search field's current mode (title or a text filter).
  String? _rawValueFor(String? key) => switch (key) {
        null => _searchTitle,
        'city' => _filterCity,
        'style' => _filterStyle,
        'username' => _filterUsername,
        'price' => _filterMaxPrice?.toStringAsFixed(0),
        _ => null,
      };

  String get _activeHint => switch (_activeFilterKey) {
        null => 'Buscar eventos por nombre',
        'city' => 'Ciudad',
        'style' => 'Estilo (#urbano #rave)',
        'username' => 'Usuario',
        'price' => 'Precio máximo (ej: 30)',
        _ => '',
      };

  TextCapitalization get _activeTextCapitalization => switch (_activeFilterKey) {
        null || 'username' || 'price' => TextCapitalization.none,
        _ => TextCapitalization.words,
      };

  // Everything already set for title/city/style/username/price, other than
  // whatever is currently being typed, chained together with "; ".
  String _committedPrefix() {
    final values = <String?>[
      _activeFilterKey == null ? null : _searchTitle,
      _activeFilterKey == 'city' ? null : _filterCity,
      _activeFilterKey == 'style' ? null : _filterStyle,
      _activeFilterKey == 'username' ? null : _filterUsername,
      _activeFilterKey == 'price' ? null : _filterMaxPrice?.toStringAsFixed(0),
    ].whereType<String>().toList();
    return values.isEmpty ? '' : '${values.join('; ')}; ';
  }

  void _commitActiveTextFilter() {
    final value = _searchController.text.trim();
    switch (_activeFilterKey) {
      case null:
        _searchTitle = value.isEmpty ? null : value;
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
      _expandedPicker = null;
      _activeFilterKey = _activeFilterKey == key ? null : key;
      _searchController.text = _rawValueFor(_activeFilterKey) ?? '';
      _searchController.selection =
          TextSelection.collapsed(offset: _searchController.text.length);
    });
  }

  void _submitSearch(String value) {
    setState(() => _commitActiveTextFilter());
    _loadEvents();
  }

  void _clearActive() {
    setState(() {
      _searchController.clear();
      switch (_activeFilterKey) {
        case null:
          _searchTitle = null;
        case 'city':
          _filterCity = null;
        case 'style':
          _filterStyle = null;
        case 'username':
          _filterUsername = null;
        case 'price':
          _filterMaxPrice = null;
      }
    });
    _loadEvents();
  }

  Future<void> _pickDateFilter() async {
    setState(() {
      _commitActiveTextFilter();
      _expandedPicker = null;
    });
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

  void _toggleEventTypePicker() {
    setState(() {
      _commitActiveTextFilter();
      _expandedPicker = _expandedPicker == 'eventType' ? null : 'eventType';
    });
  }

  void _selectEventTypeFilter(EventType type) {
    setState(() {
      _filterEventType = _filterEventType == type ? null : type;
      _expandedPicker = null;
    });
    _loadEvents();
  }

  void _onFilterChipTapped(String key) {
    switch (key) {
      case 'date':
        _pickDateFilter();
      case 'eventType':
        _toggleEventTypePicker();
      default:
        _activateFilter(key);
    }
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
      if (_activeFilterKey == key) _searchController.clear();
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
      _expandedPicker = null;
      if (_activeFilterKey != null) {
        _activeFilterKey = null;
        _searchController.text = _searchTitle ?? '';
      }
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
                hintText: _activeHint,
                prefixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar',
                  onPressed: () => _submitSearch(_searchController.text),
                ),
                prefixText: _committedPrefix(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearActive,
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: _activeTextCapitalization,
              keyboardType: _activeFilterKey == 'price'
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : null,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: _submitSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildFilterCarousel(context),
          ),
          if (_expandedPicker == 'eventType') _buildEventTypeChips(context),
          if (_hasFilterValues) _buildActiveFilterChips(context),
          Expanded(
            child: _isSearching
                ? RefreshIndicator(onRefresh: _loadEvents, child: _buildBody(context))
                : RefreshIndicator(onRefresh: _loadSections, child: _buildSections(context)),
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
          final selected = key == 'eventType' ? _expandedPicker == 'eventType' : _activeFilterKey == key;
          return ChoiceChip(
            label: Text(_filterLabel(key)),
            selected: selected,
            showCheckmark: false,
            avatar: hasValue ? const Icon(Icons.check, size: 16) : null,
            onSelected: (_) => _onFilterChipTapped(key),
          );
        },
      ),
    );
  }

  Widget _buildEventTypeChips(BuildContext context) {
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

  Widget _buildSections(BuildContext context) {
    if (_loadingSections && _sections == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sectionsError != null && _sections == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          const Text('No se pudieron cargar los eventos', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: _loadSections, child: const Text('Reintentar'))),
        ],
      );
    }

    final sections = _sections;
    if (sections == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildEventSection(
          'Cerca de ti',
          sections.nearYou,
          emptyMessage: sections.viewerHasLocation
              ? 'Todavía no hay eventos cerca de ti'
              : 'Configura tu ciudad en tu perfil para ver eventos cerca de ti',
        ),
        _buildEventSection('Lo más nuevo', sections.newest, emptyMessage: 'Nada nuevo por ahora'),
        _buildEventSection(
          'Eventos populares',
          sections.popular,
          emptyMessage: 'Todavía no hay eventos populares',
        ),
        _buildProfileSection(
          'Perfiles populares',
          sections.popularProfiles,
          emptyMessage: 'Todavía no hay perfiles populares',
        ),
        _buildEventSection(
          'Para ti',
          sections.forYou,
          emptyMessage: 'Guarda o resérvate a eventos para recibir recomendaciones',
        ),
      ],
    );
  }

  Widget _buildSectionEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }

  Widget _buildEventSection(String title, List<Event> events, {required String emptyMessage}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          if (events.isEmpty)
            _buildSectionEmptyMessage(emptyMessage)
          else
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventMiniCard(
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
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
    String title,
    List<PopularProfile> profiles, {
    required String emptyMessage,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          if (profiles.isEmpty)
            _buildSectionEmptyMessage(emptyMessage)
          else
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: profiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  return ProfileMiniCard(
                    profile: profile,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          token: widget.token,
                          userId: profile.userId,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
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
