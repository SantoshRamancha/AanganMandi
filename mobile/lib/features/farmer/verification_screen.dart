import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/models.dart';
import '../../core/crops.dart';
import '../../core/districts.dart';
import '../../core/storage/prefs.dart';
import '../../core/widgets/crop_picker.dart';
import '../../core/widgets/document_tile.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';

/// The phone is already OTP-verified at login, so verification is 3 steps:
/// farming details → one piece of farming evidence → submit to the assigned verifier.
/// Each step saves to the server, so the farmer can stop and continue later.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  int _step = 0;
  bool _busy = false;
  bool _loaded = false;
  bool _consent = false;

  final _detailsForm = GlobalKey<FormState>();
  final _evidenceForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _village = TextEditingController();
  final _acres = TextEditingController();
  final _evidenceDetails = TextEditingController();
  String? _district;
  String? _source;
  final Set<String> _crops = {};
  String? _evidenceType;
  bool _hasPhoto = false;
  String? _photoAt;

  @override
  void dispose() {
    for (final c in [_name, _village, _acres, _evidenceDetails]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Farmer f) {
    if (_loaded) return;
    _loaded = true;
    _name.text = f.name ?? '';
    _village.text = f.village ?? '';
    _district = telanganaDistricts.any((d) => d.$1 == f.district) ? f.district : null;
    _crops.addAll(f.cropCodes);
    if (f.farmSizeAcres case final a?) _acres.text = a.toString();
    _source = f.produceSource;
    _evidenceType = f.evidenceType;
    _evidenceDetails.text = f.evidenceDetails ?? '';
    _hasPhoto = f.hasEvidencePhoto;
    _photoAt = f.evidencePhotoAt;
  }

  void _error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(apiErrorMessage(e, AppLocalizations.of(context).errorGeneric))));
  }

  Future<void> _run(Future<void> Function() action, {required int next}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) setState(() => _step = next);
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadPhoto(XFile photo) async {
    final api = ref.read(farmerApiProvider);
    await api.uploadEvidencePhoto(photo);
    // The new upload time is the photo's cache key, so the tile shows the replacement.
    final f = await api.me();
    if (mounted) {
      setState(() {
        _hasPhoto = f.hasEvidencePhoto;
        _photoAt = f.evidencePhotoAt;
      });
    }
  }

  Future<void> _deletePhoto() async {
    await ref.read(farmerApiProvider).deleteEvidencePhoto();
    if (mounted) setState(() => _hasPhoto = false);
  }

  // Step actions --------------------------------------------------------------

  void _next() {
    // The failing field may be scrolled out of view, so always say why Next did nothing.
    final incomplete = AppLocalizations.of(context).completeAllSteps;
    switch (_step) {
      case 0:
        if (!_detailsForm.currentState!.validate() || _crops.isEmpty || _source == null) return _error(incomplete);
        _run(() => ref.read(farmerApiProvider).saveDetails(
              name: _name.text.trim(),
              village: _village.text.trim(),
              district: _district!,
              cropCodes: _crops.toList(),
              farmSizeAcres: double.tryParse(_acres.text),
              produceSource: _source!,
            ), next: 1);
      case 1:
        if (!_evidenceForm.currentState!.validate()) return _error(incomplete);
        final details = _evidenceDetails.text.trim();
        _run(() => ref.read(farmerApiProvider).saveEvidence(
              type: _evidenceType!,
              details: details.isEmpty ? null : details,
            ), next: 2);
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref.read(farmerApiProvider).submit();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).submittedMessage)));
      Navigator.of(context).pop();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _stepReady => switch (_step) {
        1 => _evidenceType != null && _hasPhoto,
        _ => true,
      };

  // UI -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final farmer = ref.watch(farmerProvider);
    final titles = [l10n.stepAboutYou, l10n.stepEvidence, l10n.stepReview];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.startVerification)),
      body: farmer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e, l10n.errorGeneric))),
        data: (f) {
          _load(f);
          return Column(children: [
            _StepHeader(titles: titles, current: _step),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Breakpoints.gutter(context)),
                child: MaxWidth(
                  maxWidth: 860,
                  child: switch (_step) {
                    0 => _details(l10n),
                    1 => _evidence(l10n),
                    _ => _review(l10n),
                  },
                ),
              ),
            ),
            _navBar(l10n),
          ]);
        },
      ),
    );
  }

  Widget _navBar(AppLocalizations l10n) {
    final last = _step == 2;
    return Material(
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Breakpoints.gutter(context), vertical: 12),
          child: MaxWidth(
            maxWidth: 860,
            child: Row(children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.back),
                    onPressed: _busy ? null : () => setState(() => _step--),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(last ? Icons.send : Icons.arrow_forward),
                  label: Text(last ? l10n.submitForReview : l10n.next),
                  onPressed: _busy || !_stepReady || (last && !_consent) ? null : (last ? _submit : _next),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _details(AppLocalizations l10n) {
    String? required(String? v) => (v == null || v.trim().isEmpty) ? l10n.required : null;
    final lang = ref.watch(localeProvider);
    final crops = ref.watch(cropsProvider);
    return Form(
      key: _detailsForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FormSection(
          title: l10n.stepAboutYou,
          child: ResponsiveFields(children: [
            TextFormField(controller: _name, decoration: InputDecoration(labelText: l10n.fullName), validator: required,
                textCapitalization: TextCapitalization.words),
            TextFormField(controller: _village, decoration: InputDecoration(labelText: l10n.village), validator: required,
                textCapitalization: TextCapitalization.words),
            DropdownButtonFormField<String>(
              initialValue: _district,
              decoration: InputDecoration(labelText: l10n.district),
              menuMaxHeight: 420,
              items: [
                // Stored in English; shown in the app language.
                for (final d in telanganaDistricts) DropdownMenuItem(value: d.$1, child: Text(districtName(d.$1, lang))),
              ],
              onChanged: (v) => setState(() => _district = v),
              validator: (v) => v == null ? l10n.required : null,
            ),
            TextFormField(
              controller: _acres,
              decoration: InputDecoration(labelText: l10n.farmSizeOptional),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              // Up to 4 digits and 2 decimals, a single point: 2.5, 10, 0.75.
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}(\.\d{0,2})?'))],
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final n = double.tryParse(v);
                return n == null || n <= 0 || n > 1000 ? l10n.farmSizeInvalid : null;
              },
            ),
          ]),
        ),
        FormSection(
          title: l10n.cropsYouGrow,
          child: crops.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(l10n.errorGeneric),
            data: (_) => CropPicker(
              selected: _crops,
              onChanged: (code, on) => setState(() => on ? _crops.add(code) : _crops.remove(code)),
            ),
          ),
        ),
        FormSection(
          title: l10n.produceSourceQuestion,
          child: RadioGroup<String>(
            groupValue: _source,
            onChanged: (v) => setState(() => _source = v),
            child: Column(children: [
              for (final (value, label) in [
                ('OwnFarm', l10n.sourceOwnFarm),
                ('OwnAndOtherFarmers', l10n.sourceOwnAndOthers),
                ('OtherFarmers', l10n.sourceOthers),
              ])
                RadioListTile<String>(contentPadding: EdgeInsets.zero, value: value, title: Text(label)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _evidence(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final options = [
      ('AgriStackFarmerId', Icons.badge_outlined, l10n.evidenceAgriStack, l10n.evidenceAgriStackHint),
      ('LandRecord', Icons.description_outlined, l10n.evidenceLandRecord, l10n.evidenceLandRecordHint),
      ('FpoMembership', Icons.groups_outlined, l10n.evidenceFpo, l10n.evidenceFpoHint),
      ('OfficerReference', Icons.verified_user_outlined, l10n.evidenceOfficer, l10n.evidenceOfficerHint),
    ];
    final (detailsLabel, detailsRequired) = switch (_evidenceType) {
      'AgriStackFarmerId' => (l10n.detailsAgriStack, true),
      'LandRecord' => (l10n.detailsLandRecord, false),
      'FpoMembership' => (l10n.detailsFpo, true),
      _ => (l10n.detailsOfficer, true),
    };
    return Form(
      key: _evidenceForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FormSection(
          title: l10n.evidenceQuestion,
          subtitle: l10n.evidenceSubtitle,
          child: RadioGroup<String>(
            groupValue: _evidenceType,
            onChanged: (v) => setState(() => _evidenceType = v),
            child: Column(children: [
              for (final (value, icon, title, hint) in options)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: _evidenceType == value ? scheme.primary : scheme.outlineVariant,
                        width: _evidenceType == value ? 2 : 1),
                  ),
                  child: RadioListTile<String>(
                    value: value,
                    secondary: Icon(icon, color: scheme.primary),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(hint),
                  ),
                ),
            ]),
          ),
        ),
        if (_evidenceType != null)
          ResponsiveFields(children: [
            TextFormField(
              controller: _evidenceDetails,
              decoration: InputDecoration(labelText: detailsLabel),
              maxLength: 200,
              validator: (v) => detailsRequired && (v == null || v.trim().isEmpty) ? l10n.required : null,
            ),
            DocumentTile(
              label: l10n.evidencePhoto,
              hint: l10n.evidencePhotoHint,
              icon: Icons.photo_camera_outlined,
              filePath: _hasPhoto ? evidencePhotoPath(_photoAt) : null,
              fileName: 'evidence',
              canChange: true,
              onUpload: _uploadPhoto,
              onDelete: _deletePhoto,
            ),
          ]),
      ]),
    );
  }

  Widget _review(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final lang = ref.watch(localeProvider);
    final crops = ref.watch(cropsProvider).value ?? const <Crop>[];
    final cropNames = _crops.map((c) => cropName(c, crops, lang)).join(', ');
    final evidenceName = switch (_evidenceType) {
      'AgriStackFarmerId' => l10n.evidenceAgriStack,
      'LandRecord' => l10n.evidenceLandRecord,
      'FpoMembership' => l10n.evidenceFpo,
      'OfficerReference' => l10n.evidenceOfficer,
      _ => '—',
    };
    final details = _evidenceDetails.text.trim();
    final items = [
      (l10n.stepAboutYou, '${_name.text}, ${_village.text}, ${_district == null ? '' : districtName(_district!, lang)}'),
      (l10n.cropsYouGrow, cropNames.isEmpty ? '—' : cropNames),
      (l10n.stepEvidence, details.isEmpty ? evidenceName : '$evidenceName · $details'),
      (l10n.evidencePhoto, _hasPhoto ? l10n.uploaded : '—'),
    ];
    return FormSection(
      title: l10n.reviewChecklist,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final (label, value) in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(value == '—' ? Icons.cancel : Icons.check_circle, color: value == '—' ? scheme.error : scheme.primary),
            title: Text(label),
            subtitle: Text(value),
          ),
        const Divider(height: 32),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _consent,
          onChanged: (v) => setState(() => _consent = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l10n.consentText),
        ),
      ]),
    );
  }
}

/// Numbered progress header; shows titles only where there is room.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.titles, required this.current});
  final List<String> titles;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showTitles = Breakpoints.isWide(context);
    return Material(
      color: scheme.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Breakpoints.gutter(context), vertical: 12),
        child: MaxWidth(
          maxWidth: 860,
          child: Row(children: [
            for (final (i, t) in titles.indexed) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: i <= current ? scheme.primary : scheme.surfaceContainerHighest,
                child: i < current
                    ? Icon(Icons.check, size: 18, color: scheme.onPrimary)
                    : Text('${i + 1}', style: TextStyle(color: i <= current ? scheme.onPrimary : scheme.onSurfaceVariant)),
              ),
              if (showTitles || i == current) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(t,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: i == current ? FontWeight.w600 : FontWeight.normal)),
                ),
              ],
              if (i < titles.length - 1)
                Expanded(child: Divider(indent: 8, endIndent: 8, color: i < current ? scheme.primary : null)),
            ],
          ]),
        ),
      ),
    );
  }
}
