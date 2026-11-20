import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/app_api.dart';
import '../../core/api/trip_api.dart';
import '../../core/api/trip_models.dart';
import '../../core/crops.dart';
import '../../core/storage/prefs.dart';
import '../../core/widgets/crop_picker.dart';
import '../../core/widgets/feedback.dart';
import '../../l10n/app_localizations.dart';

/// Most crops a buyer can look for at once (the server checks it too).
const maxWantedCrops = 10;

/// "Looking for": the crops the buyer wants, as chips they can remove, and a button to choose them. With none, every
/// farmer nearby is listed. The choice is saved, so the alerts follow it too.
class CropFilter extends ConsumerStatefulWidget {
  const CropFilter({super.key, required this.area});
  final BuyerArea area;

  @override
  ConsumerState<CropFilter> createState() => _CropFilterState();
}

class _CropFilterState extends ConsumerState<CropFilter> {
  bool _busy = false;

  Future<void> _save(List<String> crops) async {
    final api = ref.read(buyerApiProvider);
    setState(() => _busy = true);
    try {
      await api.saveCrops(crops);
      ref.invalidate(buyerSettingsProvider);
      ref.invalidate(nearbyStallsProvider);
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose() async {
    final chosen = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CropSheet(initial: widget.area.crops),
    );
    if (chosen != null && mounted) await _save(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = ref.watch(localeProvider);
    final crops = ref.watch(cropsProvider).value ?? const [];
    final wanted = widget.area.crops;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.lookingFor, style: Theme.of(context).textTheme.titleSmall)),
                TextButton(
                  key: const ValueKey('chooseCrops'),
                  onPressed: _busy ? null : _choose,
                  child: Text(wanted.isEmpty ? l10n.chooseCrops : l10n.changeCrops),
                ),
              ],
            ),
            if (wanted.isEmpty)
              Text(l10n.allCropsHint, style: TextStyle(color: scheme.onSurfaceVariant))
            else ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final code in wanted)
                    InputChip(
                      label: Text(cropName(code, crops, lang)),
                      onDeleted: _busy ? null : () => _save([...wanted.where((c) => c != code)]),
                      deleteButtonTooltipMessage: l10n.remove,
                    ),
                  if (wanted.length > 1)
                    ActionChip(label: Text(l10n.showAllCrops), onPressed: _busy ? null : () => _save(const [])),
                ],
              ),
              const SizedBox(height: 6),
              Text(l10n.cropFilterHint, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

/// The crop picker in a sheet, with a Save button; pops the chosen codes.
class _CropSheet extends StatefulWidget {
  const _CropSheet({required this.initial});
  final List<String> initial;

  @override
  State<_CropSheet> createState() => _CropSheetState();
}

class _CropSheetState extends State<_CropSheet> {
  late final _selected = <String>{...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tooMany = _selected.length > maxWantedCrops;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (context, scroll) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(l10n.whatCropsQ, style: Theme.of(context).textTheme.titleLarge),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    CropPicker(
                      selected: _selected,
                      onChanged: (code, on) => setState(() => on ? _selected.add(code) : _selected.remove(code)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (tooMany)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.chooseAtMostCrops(maxWantedCrops),
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    FilledButton(
                      onPressed: tooMany ? null : () => Navigator.pop(context, _selected.toList()),
                      child: Text(_selected.isEmpty ? l10n.showAllCrops : l10n.showTheseCrops(_selected.length)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
