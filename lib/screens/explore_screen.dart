import 'dart:async';

import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/explore_sections.dart';
import '../models/popular_profile.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import '../widgets/event_card.dart';
import '../widgets/event_mini_card.dart';
import '../widgets/following_profile_card.dart';
import '../widgets/profile_mini_card.dart';
import 'event_detail_screen.dart';
import 'public_profile_screen.dart';

const _carouselKeys = ['city', 'style', 'price', 'date', 'eventType'];

enum _DatePickMode { single, range }

enum _ExploreMode { events, users }

class ExploreScreen extends StatefulWidget {
  final String token;
  final String currentUserId;

  const ExploreScreen({super.key, required this.token, required this.currentUserId});

  @override
  ExploreScreenState createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  _ExploreMode _mode = _ExploreMode.events;

  final _searchController = TextEditingController();

  List<Event>? _events;
  bool _loading = false;
  String? _error;

  ExploreSections? _sections;
  bool _loadingSections = false;
  String? _sectionsError;

  // null means the search field is in "title" mode. Otherwise it's the key
  // of the text filter (city/style/price) currently being typed.
  String? _activeFilterKey;
  // Only 'eventType' uses an inline picker separate from the search field.
  String? _expandedPicker;

  String? _searchTitle;
  String? _filterCity;
  String? _filterStyle;
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  double? _filterMaxPrice;
  EventType? _filterEventType;

  bool get _hasFilterValues =>
      _filterCity != null ||
      _filterStyle != null ||
      _filterDateFrom != null ||
      _filterMaxPrice != null ||
      _filterEventType != null;

  bool get _isSearching => _hasFilterValues || _searchTitle != null;

  final _userSearchController = TextEditingController();
  List<PopularProfile>? _userSearchResults;
  bool _loadingUserSearch = false;
  String? _userSearchError;
  Timer? _userSearchDebounce;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userSearchController.dispose();
    _userSearchDebounce?.cancel();
    super.dispose();
  }

  void _onUserSearchChanged(String query) {
    _userSearchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _userSearchResults = null;
        _loadingUserSearch = false;
        _userSearchError = null;
      });
      return;
    }
    _userSearchDebounce = Timer(const Duration(milliseconds: 400), () => _searchUsers(trimmed));
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _loadingUserSearch = true;
      _userSearchError = null;
    });
    try {
      final results = await UserService.searchProfiles(token: widget.token, query: query);
      if (mounted) setState(() => _userSearchResults = results);
    } catch (e) {
      if (mounted) setState(() => _userSearchError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingUserSearch = false);
    }
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
        dateFrom: _filterDateFrom,
        // Include the whole last day of the range, not just its midnight.
        dateTo: _filterDateTo?.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
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
        'price' => 'Precio',
        'date' => 'Fecha',
        'eventType' => 'Tipo de evento',
        _ => key,
      };

  // Formatted for the carousel "has value" indicator and the chips summary.
  String? _filterValue(String key) => switch (key) {
        'city' => _filterCity,
        'style' => _filterStyle,
        'price' => _filterMaxPrice != null ? '${_filterMaxPrice!.toStringAsFixed(0)} €' : null,
        'date' => _dateFilterLabel(),
        'eventType' => _filterEventType?.label,
        _ => null,
      };

  String _formatDay(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String? _dateFilterLabel() {
    if (_filterDateFrom == null) return null;
    if (_filterDateTo == null) return 'Desde ${_formatDay(_filterDateFrom!)}';
    return '${_formatDay(_filterDateFrom!)} - ${_formatDay(_filterDateTo!)}';
  }

  // Raw editable text for the search field's current mode (title or a text filter).
  String? _rawValueFor(String? key) => switch (key) {
        null => _searchTitle,
        'city' => _filterCity,
        'style' => _filterStyle,
        'price' => _filterMaxPrice?.toStringAsFixed(0),
        _ => null,
      };

  String get _activeHint => switch (_activeFilterKey) {
        null => 'Buscar eventos por nombre',
        'city' => 'Ciudad',
        'style' => 'Estilo (#urbano #rave)',
        'price' => 'Precio máximo (ej: 30)',
        _ => '',
      };

  TextCapitalization get _activeTextCapitalization => switch (_activeFilterKey) {
        null || 'price' => TextCapitalization.none,
        _ => TextCapitalization.words,
      };

  // Everything already set for title/city/style/price, other than whatever
  // is currently being typed, chained together with "; ".
  String _committedPrefix() {
    final values = <String?>[
      _activeFilterKey == null ? null : _searchTitle,
      _activeFilterKey == 'city' ? null : _filterCity,
      _activeFilterKey == 'style' ? null : _filterStyle,
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
    final mode = await showDialog<_DatePickMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Filtrar por fecha'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(_DatePickMode.single),
            child: const Text('Un día concreto'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(_DatePickMode.range),
            child: const Text('Rango de fechas'),
          ),
        ],
      ),
    );
    if (mode == _DatePickMode.single) {
      await _pickSingleDate();
    } else if (mode == _DatePickMode.range) {
      await _pickDateRange();
    }
  }

  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDateFrom ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _filterDateFrom = picked;
        _filterDateTo = null;
      });
      _loadEvents();
    }
  }

  Future<void> _pickDateRange() async {
    final initialRange = _filterDateFrom != null && _filterDateTo != null
        ? DateTimeRange(start: _filterDateFrom!, end: _filterDateTo!)
        : null;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _filterDateFrom = picked.start;
        _filterDateTo = picked.end;
      });
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
        case 'date':
          _filterDateFrom = null;
          _filterDateTo = null;
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
      _filterDateFrom = null;
      _filterDateTo = null;
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
            child: SegmentedButton<_ExploreMode>(
              segments: const [
                ButtonSegment(
                  value: _ExploreMode.events,
                  label: Text('Eventos'),
                  icon: Icon(Icons.event_outlined),
                ),
                ButtonSegment(
                  value: _ExploreMode.users,
                  label: Text('Usuarios'),
                  icon: Icon(Icons.people_outline),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => setState(() => _mode = selection.first),
            ),
          ),
          Expanded(
            child: _mode == _ExploreMode.events
                ? _buildEventsMode(context)
                : _buildUsersMode(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsMode(BuildContext context) {
    return Column(
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
    );
  }

  Widget _buildUsersMode(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText: 'Buscar usuarios',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _userSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _userSearchController.clear();
                        _onUserSearchChanged('');
                      },
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) {
              setState(() {});
              _onUserSearchChanged(value);
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildUserSearchBody(context)),
      ],
    );
  }

  Widget _buildUserSearchBody(BuildContext context) {
    final query = _userSearchController.text.trim();
    if (query.length < 2) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.people_outline, size: 40, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'Busca perfiles por nombre de usuario',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      );
    }

    if (_loadingUserSearch && _userSearchResults == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_userSearchError != null && _userSearchResults == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          const Text('No se pudieron cargar los resultados', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => _searchUsers(query),
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    final results = _userSearchResults ?? [];
    if (results.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.person_search_outlined,
              size: 40, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'Ningún perfil coincide con "$query"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _searchUsers(query),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final profile = results[index];
          return FollowingProfileCard(
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
    if (_filterDateFrom != null) {
      chips.add(_summaryChip(_dateFilterLabel()!, () => _clearFilter('date')));
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
        _buildEventSection(
          'Castings / Audiciones',
          sections.castings,
          emptyMessage: 'Todavía no hay castings ni audiciones publicados',
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
