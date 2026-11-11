import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../api/app_api.dart';
import '../api/models.dart';
import '../crops.dart';
import '../labels.dart';
import '../storage/prefs.dart';

/// Order of the crop groups.
const _categories = ['Vegetable', 'Leafy', 'Fruit', 'Grain', 'Pulse', 'Oilseed', 'Spice', 'Flower', 'Other'];

/// Choose crops: search in any language, [suggested] crops first, the rest grouped by type, and
/// "Add another crop" for anything not in the list (kept as the farmer typed it).
class CropPicker extends ConsumerStatefulWidget {
  const CropPicker({super.key, required this.selected, required this.onChanged, this.suggested = const []});

  final Set<String> selected;
  final void Function(String code, bool on) onChanged;

  /// Codes shown first under "Your crops", e.g. the crops from verification (custom ones included).
  final List<String> suggested;

  @override
  ConsumerState<CropPicker> createState() => _CropPickerState();
}

class _CropPickerState extends ConsumerState<CropPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addCustom([String initial = '']) async {
    final name = await showDialog<String>(context: context, builder: (_) => _AddCropDialog(initial: initial));
    if (name == null || !mounted) return;
    widget.onChanged(customCropCode(name), true);
    setState(_search.clear);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider);
    final crops = ref.watch(cropsProvider).value ?? const <Crop>[];
    final query = _search.text.trim();
    final custom = {...widget.suggested, ...widget.selected}.where(isCustomCrop).toList();

    // A crop the farmer typed in gets an ✕ while selected, so a typo is easy to remove.
    Widget chip(String code) => FilterChip(
          label: Text(cropName(code, crops, lang)),
          selected: widget.selected.contains(code),
          onSelected: (on) => widget.onChanged(code, on),
          onDeleted: isCustomCrop(code) && widget.selected.contains(code) ? () => widget.onChanged(code, false) : null,
          deleteButtonTooltipMessage: l10n.delete,
        );
    Widget group(String title, List<String> codes) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final c in codes) chip(c)]),
          ]),
        );

    final List<Widget> body;
    if (query.isNotEmpty) {
      final matches = [
        for (final c in crops)
          if (c.matches(query)) c.code,
        for (final c in custom)
          if (cropName(c, crops, lang).toLowerCase().contains(query.toLowerCase())) c,
      ];
      final exact = matches.any((c) => cropName(c, crops, lang).toLowerCase() == query.toLowerCase());
      body = [
        const SizedBox(height: 12),
        if (matches.isEmpty) Text(l10n.noCropsMatch, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in matches) chip(c),
          if (!exact)
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(l10n.addCropNamed(query)),
              onPressed: () => customCropNamePattern.hasMatch(query)
                  ? setState(() {
                      widget.onChanged(customCropCode(query), true);
                      _search.clear();
                    })
                  : _addCustom(query),
            ),
        ]),
      ];
    } else {
      final first = widget.suggested.toSet();
      body = [
        if (first.isNotEmpty) group(l10n.yourCrops, widget.suggested),
        for (final cat in _categories)
          if (crops.where((c) => c.category == cat && !first.contains(c.code)).toList() case final inCat when inCat.isNotEmpty)
            group(l10n.cropCategory(cat), [for (final c in inCat) c.code]),
        if (custom.where((c) => !first.contains(c)).toList() case final mine when mine.isNotEmpty)
          group(l10n.addedByYou, mine),
        const SizedBox(height: 14),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l10n.addAnotherCrop),
          onPressed: _addCustom,
        ),
      ];
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: l10n.searchCrops,
          isDense: true,
          suffixIcon: query.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.clear), tooltip: l10n.clear, onPressed: () => setState(_search.clear)),
        ),
      ),
      ...body,
    ]);
  }
}

/// Name of a crop that is not in the list. Owns its controller (disposed after the closing animation).
class _AddCropDialog extends StatefulWidget {
  const _AddCropDialog({required this.initial});
  final String initial;

  @override
  State<_AddCropDialog> createState() => _AddCropDialogState();
}

class _AddCropDialogState extends State<_AddCropDialog> {
  late final _name = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (!customCropNamePattern.hasMatch(name)) {
      setState(() => _error = AppLocalizations.of(context).addCropInvalid);
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.eco_outlined),
      title: Text(l10n.addCropTitle),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.addCropBody),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(labelText: l10n.addCropHint, errorText: _error),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.addButton)),
      ],
    );
  }
}
