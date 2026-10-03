import 'package:flutter/material.dart';

import '../data/country_city_data.dart';

/// Cascading País -> Ciudad text fields backed by [CountryCityData].
///
/// Both fields are free text (so typing never gets blocked and legacy,
/// non-catalogued values on existing events keep working), with a
/// suggestions panel that opens either while typing or when the trailing
/// dropdown icon is tapped - never from merely tapping into the field.
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
  List<CountryOption> _countries = [];
  Map<String, int> _countryIdByName = {};
  List<String> _cities = [];
  int? _loadedCountryId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final countries = await CountryCityData.countries();
    if (!mounted) return;
    setState(() {
      _countries = countries;
      _countryIdByName = {
        for (final c in countries) c.nameEs.toLowerCase(): c.id,
      };
    });

    final id = _countryIdByName[widget.initialCountry.trim().toLowerCase()];
    if (id != null) await _loadCities(id);
  }

  Future<void> _loadCities(int countryId) async {
    final cities = await CountryCityData.citiesForCountry(countryId);
    if (!mounted) return;
    setState(() {
      _cities = cities;
      _loadedCountryId = countryId;
    });
  }

  void _onCountryText(String value) {
    widget.onCountryChanged(value);
    final id = _countryIdByName[value.trim().toLowerCase()];
    if (id != null && id != _loadedCountryId) {
      _loadCities(id);
      widget.onCityChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('País', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _SearchableTextField(
          initialValue: widget.initialCountry,
          hintText: 'País',
          options: _countries.map((c) => c.nameEs).toList(),
          onChanged: _onCountryText,
          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
        ),
        const SizedBox(height: 24),
        Text('Ciudad', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _SearchableTextField(
          key: ValueKey('city-${widget.initialCity}-$_loadedCountryId'),
          initialValue: widget.initialCity,
          hintText: 'Ciudad',
          options: _cities,
          onChanged: widget.onCityChanged,
          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
        ),
      ],
    );
  }
}

/// A [TextFormField] with a suggestions panel: it opens while typing (to
/// filter [options] down, e.g. "Esp" -> España) or when the trailing icon
/// is tapped (showing the full, current filter), but never from a plain
/// tap into the field itself.
class _SearchableTextField extends StatefulWidget {
  final String initialValue;
  final String hintText;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  const _SearchableTextField({
    super.key,
    required this.initialValue,
    required this.hintText,
    required this.options,
    required this.onChanged,
    this.validator,
  });

  @override
  State<_SearchableTextField> createState() => _SearchableTextFieldState();
}

class _SearchableTextFieldState extends State<_SearchableTextField> {
  final _layerLink = LayerLink();
  final _overlayController = OverlayPortalController();
  final _fieldKey = GlobalKey();
  final _groupId = Object();
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  List<String> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _filteredOptions = widget.options;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _overlayController.hide();
    });
  }

  @override
  void didUpdateWidget(_SearchableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options != oldWidget.options) {
      _filteredOptions = _filter(_textController.text);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> _filter(String query) {
    if (query.trim().isEmpty) return widget.options;
    final q = query.toLowerCase();
    return widget.options.where((o) => o.toLowerCase().contains(q)).toList();
  }

  void _toggleOverlay() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
      return;
    }
    setState(() => _filteredOptions = _filter(_textController.text));
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    _overlayController.show();
  }

  void _select(String value) {
    _textController.text = value;
    widget.onChanged(value);
    _overlayController.hide();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final fieldBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final fieldSize = fieldBox?.size;

    return TapRegion(
      groupId: _groupId,
      onTapOutside: (_) => _overlayController.hide(),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (context) => CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, (fieldSize?.height ?? 56) + 4),
            child: TapRegion(
              groupId: _groupId,
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 280,
                      minWidth: fieldSize?.width ?? 0,
                      maxWidth: fieldSize?.width ?? double.infinity,
                    ),
                    child: _filteredOptions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Sin resultados'),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _filteredOptions.length,
                            itemBuilder: (context, i) {
                              final option = _filteredOptions[i];
                              return ListTile(
                                dense: true,
                                title: Text(option),
                                onTap: () => _select(option),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
          child: TextFormField(
            key: _fieldKey,
            controller: _textController,
            focusNode: _focusNode,
            validator: widget.validator,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: widget.hintText,
              suffixIcon: IconButton(
                icon: Icon(
                  _overlayController.isShowing
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                ),
                onPressed: _toggleOverlay,
              ),
            ),
            onChanged: (text) {
              widget.onChanged(text);
              setState(() => _filteredOptions = _filter(text));
              if (!_overlayController.isShowing) _overlayController.show();
            },
          ),
        ),
      ),
    );
  }
}
