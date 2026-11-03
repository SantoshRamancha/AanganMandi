import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/trip_api.dart';
import '../../core/api/trip_models.dart';
import '../../core/labels.dart';
import '../../core/storage/prefs.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import 'trip_widgets.dart';

/// Plan a selling trip (or edit one): date, vehicle, the crops being brought, preferred area.
class TripFormScreen extends ConsumerStatefulWidget {
  const TripFormScreen({super.key, this.tripId});

  /// Set when editing.
  final String? tripId;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

/// One crop row: whether it is chosen, plus optional kg and ₹/kg.
class _CropInput {
  bool selected = false;
  final kg = TextEditingController();
  final price = TextEditingController();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  DateTime? _date;
  String _vehicle = 'Auto';
  final _area = TextEditingController();
  final _notes = TextEditingController();
  final _crops = <String, _CropInput>{};
  bool _loaded = false;
  bool _busy = false;
  bool _hasBooking = false;

  @override
  void dispose() {
    _area.dispose();
    _notes.dispose();
    for (final c in _crops.values) {
      c.kg.dispose();
      c.price.dispose();
    }
    super.dispose();
  }

  _CropInput _input(String code) => _crops.putIfAbsent(code, _CropInput.new);

  void _load(Trip t) {
    if (_loaded) return;
    _loaded = true;
    _date = t.date;
    _vehicle = t.vehicle;
    _area.text = t.preferredArea ?? '';
    _notes.text = t.notes ?? '';
    _hasBooking = t.booking?.isActive ?? false;
    String num(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v');
    for (final p in t.produce) {
      _input(p.cropCode)
        ..selected = true
        ..kg.text = num(p.quantityKg)
        ..price.text = num(p.pricePerKg);
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final produce = [
      for (final MapEntry(key: code, value: c) in _crops.entries)
        if (c.selected)
          ProduceItem(code, quantityKg: double.tryParse(c.kg.text.trim()), pricePerKg: double.tryParse(c.price.text.trim())),
    ];
    if (_date == null || produce.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tripNeedsDateAndCrop)));
      return;
    }
    setState(() => _busy = true);
    try {
      final trip = await ref.read(tripApiProvider).save(
            id: widget.tripId,
            date: _date!,
            vehicle: _vehicle,
            produce: produce,
            preferredArea: _area.text.trim().isEmpty ? null : _area.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      ref.invalidate(tripsProvider);
      if (!mounted) return;
      if (widget.tripId == null) {
        context.pushReplacement('/farmer/trips/${trip.id}');
      } else {
        ref.invalidate(tripProvider(trip.id));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e, l10n.errorGeneric))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.tripId != null) {
      final trip = ref.watch(tripProvider(widget.tripId!));
      if (trip.value case final t?) _load(t);
      if (!_loaded) {
        return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
      }
    }
    final lang = ref.watch(localeProvider);
    final crops = ref.watch(cropsProvider).value ?? const [];
    // The farmer's own crops first (from verification), then the rest.
    final mine = ref.watch(farmerProvider).value?.cropCodes ?? const <String>[];
    final ordered = [...crops.where((c) => mine.contains(c.code)), ...crops.where((c) => !mine.contains(c.code))];
    final gutter = Breakpoints.gutter(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.tripId == null ? l10n.planTrip : l10n.editTrip)),
      body: ListView(padding: EdgeInsets.all(gutter), children: [
        MaxWidth(
          maxWidth: 760,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FormSection(
              title: l10n.tripWhen,
              subtitle: _hasBooking ? l10n.tripDateLocked : null,
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(_date == null ? l10n.chooseDate : tripDate(_date!)),
                  onPressed: _hasBooking ? null : _pickDate,
                ),
              ),
            ),
            FormSection(
              title: l10n.tripVehicle,
              subtitle: l10n.tripVehicleHint,
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final v in vehicles)
                  ChoiceChip(
                    avatar: Icon(vehicleIcon(v), size: 20),
                    label: Text(l10n.vehicle(v)),
                    selected: _vehicle == v,
                    onSelected: _hasBooking ? null : (_) => setState(() => _vehicle = v),
                  ),
              ]),
            ),
            FormSection(
              title: l10n.tripProduce,
              subtitle: l10n.tripProduceHint,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in ordered)
                    FilterChip(
                      label: Text(c.name(lang)),
                      selected: _crops[c.code]?.selected ?? false,
                      onSelected: (on) => setState(() => _input(c.code).selected = on),
                    ),
                ]),
                for (final c in ordered)
                  if (_crops[c.code]?.selected ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text(c.name(lang), style: const TextStyle(fontWeight: FontWeight.w600))),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: _numberField(_crops[c.code]!.kg, l10n.quantityKg)),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: _numberField(_crops[c.code]!.price, l10n.priceKg)),
                      ]),
                    ),
              ]),
            ),
            FormSection(
              title: l10n.tripWhere,
              child: Column(children: [
                TextField(
                  controller: _area,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l10n.preferredArea, hintText: l10n.preferredAreaHint),
                ),
                TextField(
                  controller: _notes,
                  maxLength: 200,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.tripNotes),
                ),
              ]),
            ),
            FilledButton.icon(
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(widget.tripId == null ? l10n.saveTripFindSpace : l10n.save),
              onPressed: _busy ? null : _save,
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }

  Widget _numberField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
        decoration: InputDecoration(labelText: label, isDense: true),
      );
}
