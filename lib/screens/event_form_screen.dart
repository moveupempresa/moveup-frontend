import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../models/event.dart';
import '../models/pack.dart';
import '../models/session.dart' show Session;
import '../services/address_service.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/pack_service.dart';
import '../services/session_service.dart';
import '../widgets/video_player_view.dart';

class _SessionDraft {
  String? id;
  String name;
  DateTime startDatetime;
  DateTime endDatetime;
  String address;
  bool isUnlimitedCapacity;
  int? capacity;

  _SessionDraft({
    this.id,
    required this.name,
    required this.startDatetime,
    required this.endDatetime,
    required this.address,
    required this.isUnlimitedCapacity,
    this.capacity,
  });

  factory _SessionDraft.fromSession(Session s) => _SessionDraft(
    id: s.id,
    name: s.name,
    startDatetime: s.startDatetime,
    endDatetime: s.endDatetime,
    address: s.address ?? '',
    isUnlimitedCapacity: s.isUnlimitedCapacity,
    capacity: s.capacity,
  );
}

class _PackDraft {
  String? id;
  String name;
  PaymentType paymentType;
  double price;
  ApprovalMode approvalMode;
  PackType packType;
  int? maxSelectableSessions;
  List<_SessionDraft> selectedSessions;

  _PackDraft({
    this.id,
    required this.name,
    required this.paymentType,
    required this.price,
    required this.approvalMode,
    required this.packType,
    this.maxSelectableSessions,
    required this.selectedSessions,
  });

  factory _PackDraft.fromPack(Pack p, List<_SessionDraft> allSessions) =>
      _PackDraft(
        id: p.id,
        name: p.name,
        paymentType: p.paymentType,
        price: p.price,
        approvalMode: p.approvalMode,
        packType: p.packType,
        maxSelectableSessions: p.maxSelectableSessions,
        selectedSessions: allSessions
            .where((s) => p.sessionIds.contains(s.id))
            .toList(),
      );
}

class EventFormScreen extends StatefulWidget {
  final String token;
  final Event? event;

  const EventFormScreen({super.key, required this.token, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _styleInputController = TextEditingController();
  final _customEventTypeController = TextEditingController();

  final List<String> _styles = [];
  final List<_SessionDraft> _sessions = [];
  final List<_PackDraft> _packs = [];
  final Set<String> _deletedSessionIds = {};
  final Set<String> _deletedPackIds = {};
  File? _coverImageFile;
  File? _coverVideoFile;
  bool _removeCoverImage = false;
  bool _removeCoverVideo = false;
  int _coverPage = 0;
  bool? _reservationChoice;
  bool _isSubmitting = false;

  EventType _eventType = EventType.specialEvent;
  LocationType _locationType = LocationType.presential;
  EventVisibility _visibility = EventVisibility.public;
  EventStatus _status = EventStatus.published;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _titleController.text = event.title;
      _cityController.text = event.city;
      _countryController.text = event.country;
      _descriptionController.text = event.description;
      _styles.addAll(event.style);
      _reservationChoice = event.reservationEnabled;
      _eventType = event.eventType;
      _customEventTypeController.text = event.customEventType ?? '';
      _locationType = event.locationType;
      _visibility = event.visibility;
      _status = event.status;

      final sessionDrafts = (event.sessions ?? [])
          .map(_SessionDraft.fromSession)
          .toList();
      _sessions.addAll(sessionDrafts);
      _packs.addAll(
        (event.packs ?? []).map((p) => _PackDraft.fromPack(p, sessionDrafts)),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    _styleInputController.dispose();
    _customEventTypeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _addStyle() {
    if (_styles.length >= 3) {
      _showError('Puedes elegir hasta 3 estilos');
      return;
    }
    final value = _styleInputController.text.trim();
    if (value.isEmpty) return;
    if (_styles.contains(value)) {
      _styleInputController.clear();
      return;
    }
    setState(() {
      _styles.add(value);
      _styleInputController.clear();
    });
  }

  Future<void> _pickCoverImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _coverImageFile = File(picked.path);
      _removeCoverImage = false;
    });
  }

  Future<void> _pickCoverVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _coverVideoFile = File(picked.path);
      _removeCoverVideo = false;
    });
  }

  void _clearCoverImage() {
    setState(() {
      _coverImageFile = null;
      if (_isEditing) _removeCoverImage = true;
    });
  }

  void _clearCoverVideo() {
    setState(() {
      _coverVideoFile = null;
      if (_isEditing) _removeCoverVideo = true;
    });
  }

  bool get _hasEffectiveCoverImage =>
      _coverImageFile != null ||
      (_isEditing && !_removeCoverImage && widget.event!.coverImageUrl != null);

  bool get _hasEffectiveCoverVideo =>
      _coverVideoFile != null ||
      (_isEditing && !_removeCoverVideo && widget.event!.coverVideoUrl != null);

  Widget _buildCoverSlot({
    required bool hasMedia,
    required Widget preview,
    required IconData addIcon,
    required String addLabel,
    required VoidCallback onAdd,
    required VoidCallback onChange,
    required VoidCallback onRemove,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!hasMedia) {
      return InkWell(
        onTap: onAdd,
        child: Container(
          color: colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(addIcon, size: 40, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                addLabel,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),
        preview,
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: FilledButton.tonal(
            onPressed: onChange,
            child: const Text('Cambiar'),
          ),
        ),
      ],
    );
  }

  Future<void> _setReservationChoice(bool value) async {
    if (value == false && _packs.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Eliminar packs?'),
          content: const Text(
            'Si desactivas la gestión de reservas, se eliminarán todos los packs de este evento.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar packs'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      setState(() {
        for (final p in _packs) {
          if (p.id != null) _deletedPackIds.add(p.id!);
        }
        _packs.clear();
        _reservationChoice = false;
      });
      return;
    }
    setState(() => _reservationChoice = value);
  }

  Future<void> _openSessionSheet({_SessionDraft? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final capacityCtrl = TextEditingController(
      text: existing?.capacity != null ? existing!.capacity.toString() : '',
    );
    DateTime? startDt = existing?.startDatetime;
    DateTime? endDt = existing?.endDatetime;
    bool isUnlimited = existing?.isUnlimitedCapacity ?? true;
    List<AddressSuggestion> addressSuggestions = [];
    Timer? addressDebounce;

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    DateTime firstSelectableDate(DateTime? current) {
      if (current == null) return startOfToday;
      final currentDay = DateTime(current.year, current.month, current.day);
      return currentDay.isBefore(startOfToday) ? currentDay : startOfToday;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> pickStart() async {
              final firstDate = firstSelectableDate(startDt);
              final date = await showDatePicker(
                context: ctx,
                initialDate: startDt ?? today,
                firstDate: firstDate,
                lastDate: firstDate.add(const Duration(days: 365 * 2)),
                locale: const Locale('es', 'ES'),
              );
              if (date == null || !ctx.mounted) return;
              final time = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay.now(),
              );
              if (time == null) return;
              setSheetState(
                () => startDt = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                ),
              );
            }

            Future<void> pickEnd() async {
              final firstDate = firstSelectableDate(endDt ?? startDt);
              final date = await showDatePicker(
                context: ctx,
                initialDate: endDt ?? startDt ?? today,
                firstDate: firstDate,
                lastDate: firstDate.add(const Duration(days: 365 * 2)),
                locale: const Locale('es', 'ES'),
              );
              if (date == null || !ctx.mounted) return;
              final time = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay.now(),
              );
              if (time == null) return;
              setSheetState(
                () => endDt = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                ),
              );
            }

            String fmt(DateTime? dt) {
              if (dt == null) return 'Seleccionar';
              return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            }

            void onAddressChanged(String value) {
              setSheetState(() {});
              addressDebounce?.cancel();
              addressDebounce = Timer(
                const Duration(milliseconds: 400),
                () async {
                  final results = await AddressService.search(value);
                  if (ctx.mounted) {
                    setSheetState(() => addressSuggestions = results);
                  }
                },
              );
            }

            void selectAddress(AddressSuggestion suggestion) {
              addressCtrl.text = suggestion.displayName;
              setSheetState(() => addressSuggestions = []);
            }

            final capacityValid =
                isUnlimited ||
                (capacityCtrl.text.trim().isNotEmpty &&
                    int.tryParse(capacityCtrl.text.trim()) != null &&
                    int.parse(capacityCtrl.text.trim()) > 0);

            final canSave =
                nameCtrl.text.trim().isNotEmpty &&
                addressCtrl.text.trim().isNotEmpty &&
                startDt != null &&
                endDt != null &&
                capacityValid;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? 'Nueva sesión' : 'Editar sesión',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la sesión',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: onAddressChanged,
                  ),
                  if (addressSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(ctx).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: addressSuggestions.length,
                        itemBuilder: (_, i) {
                          final suggestion = addressSuggestions[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, size: 18),
                            title: Text(
                              suggestion.displayName,
                              style: Theme.of(ctx).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => selectAddress(suggestion),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: pickStart,
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: Text('Inicio: ${fmt(startDt)}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: pickEnd,
                    icon: const Icon(Icons.stop_outlined),
                    label: Text('Fin: ${fmt(endDt)}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Capacidad ilimitada'),
                    value: isUnlimited,
                    onChanged: (v) => setSheetState(() {
                      isUnlimited = v;
                      if (v) capacityCtrl.clear();
                    }),
                  ),
                  if (!isUnlimited) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: capacityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Capacidad (nº de personas)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: canSave
                        ? () {
                            setState(() {
                              if (existing != null) {
                                existing.name = nameCtrl.text.trim();
                                existing.startDatetime = startDt!;
                                existing.endDatetime = endDt!;
                                existing.address = addressCtrl.text.trim();
                                existing.isUnlimitedCapacity = isUnlimited;
                                existing.capacity = isUnlimited
                                    ? null
                                    : int.parse(capacityCtrl.text.trim());
                              } else {
                                _sessions.add(
                                  _SessionDraft(
                                    name: nameCtrl.text.trim(),
                                    startDatetime: startDt!,
                                    endDatetime: endDt!,
                                    address: addressCtrl.text.trim(),
                                    isUnlimitedCapacity: isUnlimited,
                                    capacity: isUnlimited
                                        ? null
                                        : int.parse(capacityCtrl.text.trim()),
                                  ),
                                );
                              }
                            });
                            Navigator.pop(ctx);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(
                      existing == null ? 'Añadir sesión' : 'Guardar sesión',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    addressDebounce?.cancel();
  }

  void _removeSession(_SessionDraft session) {
    setState(() {
      if (session.id != null) _deletedSessionIds.add(session.id!);
      _sessions.remove(session);
      for (final pack in _packs) {
        pack.selectedSessions.remove(session);
      }
    });
  }

  Future<void> _openPackSheet({_PackDraft? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null && existing.paymentType != PaymentType.free
          ? existing.price.toString()
          : '',
    );
    final maxSelectableSessionsCtrl = TextEditingController(
      text: existing?.maxSelectableSessions != null
          ? existing!.maxSelectableSessions.toString()
          : '',
    );
    PaymentType paymentType = existing?.paymentType ?? PaymentType.online;
    ApprovalMode approvalMode =
        existing?.approvalMode ?? ApprovalMode.automatic;
    PackType packType = existing?.packType ?? PackType.fixed;
    final selectedSessions = <_SessionDraft>{
      ...(existing?.selectedSessions ?? []),
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final priceValid =
                paymentType == PaymentType.free ||
                (priceCtrl.text.trim().isNotEmpty &&
                    double.tryParse(priceCtrl.text.trim()) != null &&
                    double.parse(priceCtrl.text.trim()) > 0);

            final maxSelectableSessionsValid =
                packType != PackType.customizable ||
                (maxSelectableSessionsCtrl.text.trim().isNotEmpty &&
                    int.tryParse(maxSelectableSessionsCtrl.text.trim()) !=
                        null &&
                    int.parse(maxSelectableSessionsCtrl.text.trim()) > 0);

            final selectedSessionsValid =
                packType != PackType.fixed || selectedSessions.isNotEmpty;

            final customizableSessionsValid =
                packType != PackType.customizable || _sessions.isNotEmpty;

            final canSave =
                nameCtrl.text.trim().isNotEmpty &&
                priceValid &&
                maxSelectableSessionsValid &&
                selectedSessionsValid &&
                customizableSessionsValid;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? 'Nuevo pack' : 'Editar pack',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título del pack',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PaymentType>(
                    value: paymentType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de pago',
                    ),
                    // "Gratis" is retired for new/edited choices, but stays
                    // selectable if a legacy pack already used it so the
                    // dropdown's current value is never missing from the list.
                    items: PaymentType.values
                        .where(
                          (p) =>
                              p != PaymentType.free ||
                              paymentType == PaymentType.free,
                        )
                        .map(
                          (p) =>
                              DropdownMenuItem(value: p, child: Text(p.label)),
                        )
                        .toList(),
                    onChanged: (v) => setSheetState(() {
                      if (v != null) {
                        paymentType = v;
                        if (v == PaymentType.free) priceCtrl.clear();
                      }
                    }),
                  ),
                  if (paymentType != PaymentType.free) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Precio'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ApprovalMode>(
                    value: approvalMode,
                    decoration: const InputDecoration(
                      labelText: 'Confirmación de reserva',
                    ),
                    items: ApprovalMode.values
                        .map(
                          (a) =>
                              DropdownMenuItem(value: a, child: Text(a.label)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setSheetState(() => approvalMode = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PackType>(
                    value: packType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de pack',
                    ),
                    items: PackType.values
                        .map(
                          (p) =>
                              DropdownMenuItem(value: p, child: Text(p.label)),
                        )
                        .toList(),
                    onChanged: (v) => setSheetState(() {
                      if (v != null) {
                        packType = v;
                        if (v != PackType.customizable) {
                          maxSelectableSessionsCtrl.clear();
                        }
                        if (v != PackType.fixed) selectedSessions.clear();
                      }
                    }),
                  ),
                  if (packType == PackType.customizable) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: maxSelectableSessionsCtrl,
                      decoration: const InputDecoration(
                        labelText:
                            'Nº de sesiones que puede elegir el estudiante',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sessions.isEmpty
                          ? 'Este evento todavía no tiene sesiones. Añade sesiones antes de crear un pack personalizable.'
                          : 'El estudiante podrá elegir entre las ${_sessions.length} sesiones del evento',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: _sessions.isEmpty
                            ? Theme.of(ctx).colorScheme.error
                            : Theme.of(ctx).colorScheme.outline,
                      ),
                    ),
                  ],
                  if (packType == PackType.fixed) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Sesiones incluidas',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    ..._sessions.map(
                      (s) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(s.name),
                        subtitle: Text(
                          '${_formatDatetime(s.startDatetime)} → ${_formatDatetime(s.endDatetime)}',
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                        value: selectedSessions.contains(s),
                        onChanged: (checked) => setSheetState(() {
                          if (checked == true) {
                            selectedSessions.add(s);
                          } else {
                            selectedSessions.remove(s);
                          }
                        }),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    approvalMode == ApprovalMode.automatic
                        ? 'La reserva se confirma automáticamente después de completar el proceso de pago.'
                        : 'Recibirás cada solicitud y podrás aceptarla o rechazarla antes de que el alumno realice el pago.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: canSave
                        ? () {
                            setState(() {
                              final price = paymentType == PaymentType.free
                                  ? 0.0
                                  : double.parse(priceCtrl.text.trim());
                              final maxSelectable =
                                  packType == PackType.customizable
                                  ? int.parse(
                                      maxSelectableSessionsCtrl.text.trim(),
                                    )
                                  : null;
                              final sessions = switch (packType) {
                                PackType.fixed => selectedSessions.toList(),
                                PackType.customizable => _sessions.toList(),
                              };

                              if (existing != null) {
                                existing.name = nameCtrl.text.trim();
                                existing.paymentType = paymentType;
                                existing.price = price;
                                existing.approvalMode = approvalMode;
                                existing.packType = packType;
                                existing.maxSelectableSessions = maxSelectable;
                                existing.selectedSessions = sessions;
                              } else {
                                _packs.add(
                                  _PackDraft(
                                    name: nameCtrl.text.trim(),
                                    paymentType: paymentType,
                                    price: price,
                                    approvalMode: approvalMode,
                                    packType: packType,
                                    maxSelectableSessions: maxSelectable,
                                    selectedSessions: sessions,
                                  ),
                                );
                              }
                            });
                            Navigator.pop(ctx);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(
                      existing == null ? 'Añadir pack' : 'Guardar pack',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _removePack(_PackDraft pack) {
    setState(() {
      if (pack.id != null) _deletedPackIds.add(pack.id!);
      _packs.remove(pack);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_styles.isEmpty) {
      _showError('Añade al menos un estilo');
      return;
    }
    if (_sessions.isEmpty) {
      _showError('Añade al menos una sesión');
      return;
    }
    if (!_hasEffectiveCoverImage && !_hasEffectiveCoverVideo) {
      _showError('Selecciona una imagen o un video de portada');
      return;
    }
    if (_reservationChoice == null) {
      _showError('Indica si necesitas gestionar reservas');
      return;
    }
    if (_reservationChoice == true && _packs.isEmpty) {
      _showError('Añade al menos un pack');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final String eventId;
      if (_isEditing) {
        final updated = await EventService.updateEvent(
          token: widget.token,
          eventId: widget.event!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          style: _styles,
          city: _cityController.text.trim(),
          country: _countryController.text.trim(),
          coverImageFile: _coverImageFile,
          coverVideoFile: _coverVideoFile,
          removeCoverImage: _removeCoverImage,
          removeCoverVideo: _removeCoverVideo,
          reservationEnabled: _reservationChoice!,
          eventType: _eventType,
          customEventType: _eventType == EventType.other
              ? _customEventTypeController.text.trim()
              : null,
          locationType: _locationType,
          visibility: _visibility,
          status: _status,
        );
        eventId = updated.id;
      } else {
        final created = await EventService.createEvent(
          token: widget.token,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          style: _styles,
          city: _cityController.text.trim(),
          country: _countryController.text.trim(),
          coverImageFile: _coverImageFile,
          coverVideoFile: _coverVideoFile,
          reservationEnabled: _reservationChoice!,
          status: EventStatus.published,
          eventType: _eventType,
          customEventType: _eventType == EventType.other
              ? _customEventTypeController.text.trim()
              : null,
        );
        eventId = created.id;
      }

      for (final sessionId in _deletedSessionIds) {
        await SessionService.deleteSession(
          token: widget.token,
          eventId: eventId,
          sessionId: sessionId,
        );
      }

      for (final session in _sessions) {
        if (session.id == null) {
          final created = await SessionService.createSession(
            token: widget.token,
            eventId: eventId,
            name: session.name,
            startDatetime: session.startDatetime,
            endDatetime: session.endDatetime,
            address: session.address,
            isUnlimitedCapacity: session.isUnlimitedCapacity,
            capacity: session.capacity,
          );
          session.id = created.id;
        } else {
          await SessionService.updateSession(
            token: widget.token,
            eventId: eventId,
            sessionId: session.id!,
            name: session.name,
            startDatetime: session.startDatetime,
            endDatetime: session.endDatetime,
            address: session.address,
            isUnlimitedCapacity: session.isUnlimitedCapacity,
            capacity: session.capacity,
          );
        }
      }

      for (final packId in _deletedPackIds) {
        await PackService.deletePack(
          token: widget.token,
          eventId: eventId,
          packId: packId,
        );
      }

      for (final pack in _packs) {
        final sessionIds = pack.selectedSessions.map((s) => s.id!).toList();
        if (pack.id == null) {
          await PackService.createPack(
            token: widget.token,
            eventId: eventId,
            name: pack.name,
            price: pack.price,
            paymentType: pack.paymentType,
            packType: pack.packType,
            approvalMode: pack.approvalMode,
            maxSelectableSessions: pack.maxSelectableSessions,
            sessionIds: sessionIds,
          );
        } else {
          await PackService.updatePack(
            token: widget.token,
            eventId: eventId,
            packId: pack.id!,
            name: pack.name,
            price: pack.price,
            paymentType: pack.paymentType,
            packType: pack.packType,
            approvalMode: pack.approvalMode,
            maxSelectableSessions: pack.maxSelectableSessions,
            sessionIds: sessionIds,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? '¡Cambios guardados!' : '¡Evento publicado!',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatDatetime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar evento' : 'Crear evento'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // 1. Nombre
              _label('Nombre del evento'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Nombre del evento',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),

              // 2. Ciudad
              _label('Ciudad'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(hintText: 'Ciudad'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),

              // 3. País
              _label('País'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(hintText: 'País'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),

              // 4. Categoría / modalidad / visibilidad
              _label('Categoría'),
              const SizedBox(height: 8),
              DropdownButtonFormField<EventType>(
                value: _eventType,
                items: EventType.values
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  if (v != null) _eventType = v;
                }),
              ),
              if (_eventType == EventType.other) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customEventTypeController,
                  decoration: const InputDecoration(
                    hintText: '¿De qué tipo de evento se trata?',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      _eventType == EventType.other &&
                          (v == null || v.trim().isEmpty)
                      ? 'Requerido'
                      : null,
                ),
              ],
              if (_isEditing) ...[
                const SizedBox(height: 16),
                _label('Estado'),
                const SizedBox(height: 8),
                DropdownButtonFormField<EventStatus>(
                  value: _status,
                  items: EventStatus.values
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    if (v != null) _status = v;
                  }),
                ),
              ],
              const SizedBox(height: 24),

              // 5. Estilo (chips)
              Row(
                children: [
                  _label('Estilo'),
                  const SizedBox(width: 8),
                  Text(
                    '(${_styles.length}/3)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _styleInputController,
                      decoration: InputDecoration(
                        hintText: _styles.length >= 3
                            ? 'Máximo de estilos alcanzado'
                            : 'ej: Salsa, Bachata, Hip-hop...',
                      ),
                      enabled: _styles.length < 3,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _addStyle(),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed:
                        _styles.length < 3 &&
                            _styleInputController.text.trim().isNotEmpty
                        ? _addStyle
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (_styles.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _styles
                      .map(
                        (s) => InputChip(
                          label: Text(s),
                          onDeleted: () => setState(() => _styles.remove(s)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),

              // 6. Descripción
              _label('Descripción'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe el evento...',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),

              // 7. Sesiones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label('Sesiones'),
                  if (_sessions.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _openSessionSheet(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Añadir'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_sessions.isEmpty)
                OutlinedButton.icon(
                  onPressed: () => _openSessionSheet(),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Añadir sesión'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                )
              else
                ..._sessions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => _openSessionSheet(existing: s),
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(s.name),
                      subtitle: Text(
                        '${_formatDatetime(s.startDatetime)} → ${_formatDatetime(s.endDatetime)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeSession(s),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // 8. Portada
              _label('Portada'),
              const SizedBox(height: 4),
              Text(
                'Añade una imagen, un video, o ambos',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    PageView(
                      onPageChanged: (i) => setState(() => _coverPage = i),
                      children: [
                        _buildCoverSlot(
                          hasMedia: _hasEffectiveCoverImage,
                          preview: _coverImageFile != null
                              ? Image.file(
                                  _coverImageFile!,
                                  fit: BoxFit.contain,
                                )
                              : (_isEditing &&
                                        widget.event!.coverImageUrl != null
                                    ? Image.network(
                                        ApiConfig.mediaUrl(
                                          widget.event!.coverImageUrl!,
                                        ),
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 40,
                                            ),
                                      )
                                    : const SizedBox.shrink()),
                          addIcon: Icons.add_photo_alternate_outlined,
                          addLabel: 'Añadir imagen',
                          onAdd: _pickCoverImage,
                          onChange: _pickCoverImage,
                          onRemove: _clearCoverImage,
                        ),
                        _buildCoverSlot(
                          hasMedia: _hasEffectiveCoverVideo,
                          preview: _coverVideoFile != null
                              ? VideoPlayerView(filePath: _coverVideoFile!.path)
                              : (_isEditing &&
                                        widget.event!.coverVideoUrl != null
                                    ? VideoPlayerView(
                                        networkUrl: ApiConfig.mediaUrl(
                                          widget.event!.coverVideoUrl!,
                                        ),
                                      )
                                    : const SizedBox.shrink()),
                          addIcon: Icons.videocam_outlined,
                          addLabel: 'Añadir video',
                          onAdd: _pickCoverVideo,
                          onChange: _pickCoverVideo,
                          onRemove: _clearCoverVideo,
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          2,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _coverPage == i
                                  ? colorScheme.primary
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 9. Reservas
              _label('¿Necesitas gestionar reservas?'),
              const SizedBox(height: 12),
              _ReservationCard(
                label: 'No, publicar sin reservas',
                icon: Icons.public,
                selected: _reservationChoice == false,
                onTap: () => _setReservationChoice(false),
              ),
              const SizedBox(height: 10),
              _ReservationCard(
                label: 'Sí, quiero gestionar reservas',
                icon: Icons.confirmation_number_outlined,
                selected: _reservationChoice == true,
                onTap: () => _setReservationChoice(true),
              ),
              if (_reservationChoice == true) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _label('Packs'),
                    if (_packs.isNotEmpty)
                      TextButton.icon(
                        onPressed: _sessions.isEmpty
                            ? null
                            : () => _openPackSheet(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Añadir'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_sessions.isEmpty)
                  Text(
                    'Añade al menos una sesión antes de crear un pack',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  )
                else if (_packs.isEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _openPackSheet(),
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: const Text('Añadir pack'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  )
                else
                  ..._packs.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    final priceLabel = p.paymentType == PaymentType.free
                        ? 'Gratis'
                        : '${p.price.toStringAsFixed(2)} · ${p.paymentType.label}';
                    final packTypeLabel = p.packType == PackType.customizable
                        ? '${p.packType.label} (máx. ${p.maxSelectableSessions} sesiones)'
                        : p.packType.label;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _openPackSheet(existing: p),
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(p.name),
                        subtitle: Text(
                          '$priceLabel · $packTypeLabel',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removePack(p),
                        ),
                      ),
                    );
                  }),
              ],
              const SizedBox(height: 32),

              if (_reservationChoice != null)
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditing ? 'Guardar cambios' : 'Publicar evento',
                        ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: Theme.of(context).textTheme.titleSmall);
}

class _ReservationCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ReservationCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
