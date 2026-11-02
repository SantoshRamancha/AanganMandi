import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/location.dart';
import '../../core/widgets/photo_tile.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';

/// Monday..Sunday as the API's DayOfWeek names.
const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Localised short weekday name (Mon / సోమ / सोम).
String weekdayLabel(BuildContext context, String day) =>
    DateFormat.E(Localizations.localeOf(context).toString()).format(DateTime(2024, 1, 1 + weekdays.indexOf(day)));

/// Host lists a space: details, location, pricing, availability, 3–8 photos and a private proof document.
class SpaceFormScreen extends ConsumerStatefulWidget {
  const SpaceFormScreen({super.key});

  @override
  ConsumerState<SpaceFormScreen> createState() => _SpaceFormScreenState();
}

class _SpaceFormScreenState extends ConsumerState<SpaceFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _address = TextEditingController();
  final _locality = TextEditingController();
  final _area = TextEditingController();
  final _fee = TextEditingController();
  final _rules = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  String _type = 'Driveway';
  String _vehicle = 'Auto';
  final Set<String> _amenities = {};
  bool _isFree = false;
  final Set<String> _days = {'Saturday', 'Sunday'};
  TimeOfDay _from = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 11, minute: 0);
  bool _manualLocation = false;
  final List<(XFile, Uint8List)> _photos = [];
  (XFile, Uint8List)? _proof;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_title, _address, _locality, _area, _fee, _rules, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _useLocation() async {
    setState(() => _busy = true);
    try {
      final pos = await currentPosition();
      if (pos == null) {
        if (mounted) _toast(AppLocalizations.of(context).locationDenied);
        setState(() => _manualLocation = true);
      } else {
        _lat.text = pos.latitude.toStringAsFixed(6);
        _lng.text = pos.longitude.toStringAsFixed(6);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addPhotos() async {
    final picked = kIsWeb
        ? await ImagePicker().pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 70, limit: 8 - _photos.length)
        : [?await pickPhoto()];
    for (final p in picked.take(8 - _photos.length)) {
      final bytes = await p.readAsBytes();
      setState(() => _photos.add((p, bytes)));
    }
  }

  Future<void> _pickProof() async {
    if (await pickPhoto() case final p?) {
      final bytes = await p.readAsBytes();
      setState(() => _proof = (p, bytes));
    }
  }

  Future<void> _pickTime(bool from) async {
    final t = await showTimePicker(context: context, initialTime: from ? _from : _to);
    if (t != null) setState(() => from ? _from = t : _to = t);
  }

  int get _slotMinutes => (_to.hour * 60 + _to.minute) - (_from.hour * 60 + _from.minute);
  String _hms(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return _toast(l10n.completeAllSteps);
    if (double.tryParse(_lat.text) == null || double.tryParse(_lng.text) == null) {
      return _toast(l10n.spaceLocation);
    }
    if (_days.isEmpty || _slotMinutes < 120 || _slotMinutes > 360) return _toast(l10n.slotRule);
    if (_photos.length < 3 || _proof == null) return _toast(l10n.photosNeeded);

    setState(() => _busy = true);
    final api = ref.read(hostApiProvider);
    try {
      final space = await api.create({
        'title': _title.text.trim(),
        'type': _type,
        'address': _address.text.trim(),
        'locality': _locality.text.trim(),
        'latitude': double.parse(_lat.text),
        'longitude': double.parse(_lng.text),
        'areaSqFt': int.parse(_area.text),
        'maxStallSize': '10x10 ft',
        'maxVehicle': _vehicle,
        'amenities': _amenities.toList(),
        'isFree': _isFree,
        'fee': _isFree ? 0 : double.parse(_fee.text),
        'rules': _rules.text.trim().isEmpty ? null : _rules.text.trim(),
        'availableDays': weekdays.where(_days.contains).toList(),
        'openFrom': _hms(_from),
        'openTo': _hms(_to),
      });
      // If an upload fails the space stays a draft; the host can finish it from its page.
      for (final (photo, _) in _photos) {
        await api.addPhoto(space.id, photo);
      }
      await api.addPhoto(space.id, _proof!.$1, isProof: true);
      await api.submit(space.id);
      if (!mounted) return;
      _toast(l10n.spaceSubmitted);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _toast(apiErrorMessage(e, l10n.errorGeneric));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? required(String? v) => (v == null || v.trim().isEmpty) ? l10n.required : null;
    final gutter = Breakpoints.gutter(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addSpace)),
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, 120),
          children: [
            MaxWidth(
              maxWidth: 900,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                FormSection(
                  title: l10n.spaceDetails,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    TextFormField(
                      controller: _title,
                      decoration: InputDecoration(labelText: l10n.spaceName, hintText: l10n.spaceNameHint),
                      validator: required,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.spaceType),
                    const SizedBox(height: 8),
                    _choices({
                      'Driveway': l10n.driveway,
                      'Courtyard': l10n.courtyard,
                      'OpenArea': l10n.openArea,
                      'CommercialFrontage': l10n.commercialFrontage,
                    }, _type, (v) => setState(() => _type = v)),
                    const SizedBox(height: 16),
                    ResponsiveFields(children: [
                      TextFormField(
                        controller: _area,
                        decoration: InputDecoration(labelText: l10n.areaSqFt),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) < 50 ? l10n.required : null,
                      ),
                      const SizedBox.shrink(),
                    ]),
                    const SizedBox(height: 16),
                    Text(l10n.maxVehicle),
                    const SizedBox(height: 8),
                    _choices({
                      'TwoWheeler': l10n.twoWheeler,
                      'Auto': l10n.auto,
                      'MiniTruck': l10n.miniTruck,
                      'Tractor': l10n.tractor,
                    }, _vehicle, (v) => setState(() => _vehicle = v)),
                  ]),
                ),
                FormSection(
                  title: l10n.spaceLocation,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    ResponsiveFields(children: [
                      TextFormField(
                        controller: _address,
                        decoration: InputDecoration(labelText: l10n.address, helperText: l10n.addressHint, helperMaxLines: 2),
                        validator: required,
                        maxLines: 2,
                      ),
                      TextFormField(controller: _locality, decoration: InputDecoration(labelText: l10n.locality), validator: required),
                    ]),
                    const SizedBox(height: 16),
                    Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: Text(l10n.useMyLocation),
                        onPressed: _busy ? null : _useLocation,
                      ),
                      TextButton(
                        onPressed: () => setState(() => _manualLocation = !_manualLocation),
                        child: Text(l10n.enterCoordinates),
                      ),
                    ]),
                    if (_manualLocation || _lat.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ResponsiveFields(children: [
                        TextFormField(
                          controller: _lat,
                          decoration: InputDecoration(labelText: l10n.latitude, hintText: '17.4622'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                        TextFormField(
                          controller: _lng,
                          decoration: InputDecoration(labelText: l10n.longitude, hintText: '78.3568'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ]),
                    ],
                  ]),
                ),
                FormSection(
                  title: l10n.amenities,
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final (value, label, icon) in [
                      ('Water', l10n.water, Icons.water_drop),
                      ('Shade', l10n.shade, Icons.umbrella),
                      ('PowerPoint', l10n.powerPoint, Icons.power),
                      ('BuyerParking', l10n.buyerParking, Icons.local_parking),
                      ('LoadingAccess', l10n.loadingAccess, Icons.local_shipping),
                      ('Toilet', l10n.toilet, Icons.wc),
                    ])
                      FilterChip(
                        // The tick would cover the icon; the filled colour already shows selection.
                        showCheckmark: false,
                        avatar: Icon(icon, size: 18),
                        label: Text(label),
                        selected: _amenities.contains(value),
                        onSelected: (on) => setState(() => on ? _amenities.add(value) : _amenities.remove(value)),
                      ),
                  ]),
                ),
                FormSection(
                  title: l10n.availability,
                  subtitle: l10n.slotRule,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(l10n.availableDays),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final d in weekdays)
                        FilterChip(
                          label: Text(weekdayLabel(context, d)),
                          selected: _days.contains(d),
                          onSelected: (on) => setState(() => on ? _days.add(d) : _days.remove(d)),
                        ),
                    ]),
                    const SizedBox(height: 16),
                    ResponsiveFields(children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.schedule),
                        label: Text('${l10n.openFrom}  ${_from.format(context)}'),
                        onPressed: () => _pickTime(true),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.schedule),
                        label: Text('${l10n.openTo}  ${_to.format(context)}'),
                        onPressed: () => _pickTime(false),
                      ),
                    ]),
                    if (_slotMinutes < 120 || _slotMinutes > 360)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(l10n.slotRule, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                  ]),
                ),
                FormSection(
                  title: l10n.pricing,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.freeSpace),
                      value: _isFree,
                      onChanged: (v) => setState(() => _isFree = v),
                    ),
                    if (!_isFree)
                      ResponsiveFields(children: [
                        TextFormField(
                          controller: _fee,
                          decoration: InputDecoration(labelText: l10n.feePerSlot, prefixText: '₹ '),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => _isFree || (int.tryParse(v ?? '') ?? 0) > 0 ? null : l10n.required,
                        ),
                        const SizedBox.shrink(),
                      ]),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rules,
                      decoration: InputDecoration(labelText: l10n.houseRules, hintText: l10n.houseRulesHint),
                      maxLines: 2,
                    ),
                  ]),
                ),
                FormSection(
                  title: l10n.spacePhotos,
                  child: _PhotoGrid(
                    photos: [for (final (_, b) in _photos) b],
                    onAdd: _photos.length < 8 ? _addPhotos : null,
                    onRemove: (i) => setState(() => _photos.removeAt(i)),
                    addLabel: l10n.addPhotos,
                  ),
                ),
                FormSection(
                  title: l10n.proofOfRight,
                  subtitle: l10n.proofHint,
                  child: _PhotoGrid(
                    photos: [if (_proof case (_, final b)) b],
                    onAdd: _proof == null ? _pickProof : null,
                    onRemove: (_) => setState(() => _proof = null),
                    addLabel: l10n.takePhoto,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 4,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 12),
            child: MaxWidth(
              maxWidth: 900,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(l10n.submitSpace),
                  onPressed: _busy ? null : _submit,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _choices(Map<String, String> options, String selected, ValueChanged<String> onSelected) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in options.entries)
            ChoiceChip(label: Text(e.value), selected: e.key == selected, onSelected: (_) => onSelected(e.key)),
        ],
      );
}

/// Thumbnails with remove buttons and an "add" tile.
class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.photos, required this.onAdd, required this.onRemove, required this.addLabel});
  final List<Uint8List> photos;
  final VoidCallback? onAdd;
  final ValueChanged<int> onRemove;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(spacing: 12, runSpacing: 12, children: [
      for (final (i, bytes) in photos.indexed)
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, width: 140, height: 105, fit: BoxFit.cover),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton.filledTonal(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close),
              onPressed: () => onRemove(i),
            ),
          ),
        ]),
      if (onAdd != null)
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 140,
            height: 105,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline),
              color: scheme.surfaceContainerHighest,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_a_photo, color: scheme.primary),
              const SizedBox(height: 6),
              Text(addLabel, textAlign: TextAlign.center, style: TextStyle(color: scheme.primary)),
            ]),
          ),
        ),
    ]);
  }
}
