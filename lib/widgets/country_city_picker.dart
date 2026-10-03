import 'package:flutter/material.dart';

import '../data/country_city_data.dart';

/// Cascading País -> Ciudad dropdowns backed by [CountryCityData].
///
/// Both fields let the user type to filter the list down (e.g. "Esp" ->
/// España) via [DropdownMenu]'s built-in search/filter.
///
/// Accepts the event's current (possibly free-typed, legacy) country/city
/// values so editing an older event doesn't crash or silently drop data:
/// a value that doesn't match the dataset is kept as an extra, selectable
/// item until the user actively picks a new one.
class CountryCityPicker extends StatefulWidget {
  final String initialCountry;
  final String initialCity;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onCityChanged;

  const CountryCityPicker({
    super.key,
    required this.initialCountry,
    required this.initialCity,
    required this.onCountryChanged,
    required this.onCityChanged,
  });

  @override
  State<CountryCityPicker> createState() => _CountryCityPickerState();
}

class _CountryCityPickerState extends State<CountryCityPicker> {
  List<CountryOption>? _countries;
  List<String> _cities = [];
  String? _selectedCountry;
  String? _selectedCity;
  bool _loadingCities = false;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry.trim().isEmpty
        ? null
        : widget.initialCountry.trim();
    _selectedCity = widget.initialCity.trim().isEmpty
        ? null
        : widget.initialCity.trim();
    _init();
  }

  Future<void> _init() async {
    final countries = await CountryCityData.countries();
    if (!mounted) return;
    setState(() => _countries = countries);

    final selected = _selectedCountry;
    if (selected == null) return;
    CountryOption? match;
    for (final c in countries) {
      if (c.nameEs.toLowerCase() == selected.toLowerCase()) {
        match = c;
        break;
      }
    }
    if (match != null) await _loadCities(match.id);
  }

  Future<void> _loadCities(int countryId) async {
    setState(() => _loadingCities = true);
    final cities = await CountryCityData.citiesForCountry(countryId);
    if (!mounted) return;
    setState(() {
      _cities = cities;
      _loadingCities = false;
    });
  }

  void _onCountryChanged(String? value) {
    setState(() {
      _selectedCountry = value;
      _selectedCity = null;
      _cities = [];
    });
    widget.onCountryChanged(value ?? '');
    widget.onCityChanged('');
    if (value == null) return;

    final countries = _countries ?? [];
    for (final c in countries) {
      if (c.nameEs == value) {
        _loadCities(c.id);
        break;
      }
    }
  }

  void _onCityChanged(String? value) {
    setState(() => _selectedCity = value);
    widget.onCityChanged(value ?? '');
  }

  List<DropdownMenuEntry<String>> _countryEntries() {
    final countries = _countries ?? [];
    final entries = <DropdownMenuEntry<String>>[];
    final selected = _selectedCountry;
    if (selected != null &&
        !countries.any(
          (c) => c.nameEs.toLowerCase() == selected.toLowerCase(),
        )) {
      entries.add(DropdownMenuEntry(value: selected, label: selected));
    }
    entries.addAll(
      countries.map((c) => DropdownMenuEntry(value: c.nameEs, label: c.nameEs)),
    );
    return entries;
  }

  List<DropdownMenuEntry<String>> _cityEntries() {
    final entries = <DropdownMenuEntry<String>>[];
    final selected = _selectedCity;
    if (selected != null &&
        !_cities.any((c) => c.toLowerCase() == selected.toLowerCase())) {
      entries.add(DropdownMenuEntry(value: selected, label: selected));
    }
    entries.addAll(_cities.map((c) => DropdownMenuEntry(value: c, label: c)));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('País', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        FormField<String>(
          key: ValueKey('country-$_selectedCountry'),
          initialValue: _selectedCountry,
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
          builder: (field) => DropdownMenu<String>(
            expandedInsets: EdgeInsets.zero,
            enableFilter: true,
            requestFocusOnTap: true,
            initialSelection: _selectedCountry,
            hintText: 'Selecciona un país',
            errorText: field.errorText,
            dropdownMenuEntries: _countryEntries(),
            onSelected: (value) {
              field.didChange(value);
              _onCountryChanged(value);
            },
          ),
        ),
        const SizedBox(height: 24),
        Text('Ciudad', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        FormField<String>(
          key: ValueKey('city-$_selectedCity'),
          initialValue: _selectedCity,
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
          builder: (field) => DropdownMenu<String>(
            expandedInsets: EdgeInsets.zero,
            enableFilter: true,
            requestFocusOnTap: true,
            enabled: _selectedCountry != null && !_loadingCities,
            initialSelection: _selectedCity,
            hintText: _selectedCountry == null
                ? 'Selecciona primero un país'
                : (_loadingCities
                      ? 'Cargando ciudades...'
                      : 'Selecciona una ciudad'),
            errorText: field.errorText,
            dropdownMenuEntries: _cityEntries(),
            onSelected: (value) {
              field.didChange(value);
              _onCityChanged(value);
            },
          ),
        ),
      ],
    );
  }
}
