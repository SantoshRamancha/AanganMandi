import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/trip_api.dart';
import '../../core/api/trip_models.dart';
import '../../core/labels.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import 'trip_widgets.dart';

/// Spaces a farmer can request for one trip: live, open that weekday, fit the vehicle, nobody booked that day.
class SpaceSearchScreen extends ConsumerStatefulWidget {
  const SpaceSearchScreen({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<SpaceSearchScreen> createState() => _SpaceSearchScreenState();
}

class _SpaceSearchScreenState extends ConsumerState<SpaceSearchScreen> {
  final _area = TextEditingController();
  String? _filter;
  bool _seeded = false;

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  void _search() => setState(() => _filter = _area.text.trim().isEmpty ? null : _area.text.trim());

  Future<void> _request(Trip trip, SpaceCard s) async {
    final l10n = AppLocalizations.of(context);
    // The sheet owns its text field's controller: disposing it here would break the sheet's closing animation.
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RequestSheet(trip: trip, space: s),
    );
    if (message == null || !mounted) return;
    final ok = await runWithToast(
      context,
      () => ref.read(tripApiProvider).book(trip.id, s.id, message.isEmpty ? null : message),
      success: l10n.requestSentToast,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final trip = ref.watch(tripProvider(widget.tripId)).value;
    if (trip == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    // Start with the trip's preferred area, once.
    if (!_seeded) {
      _seeded = true;
      _area.text = trip.preferredArea ?? '';
      _filter = trip.preferredArea;
    }
    final spaces = ref.watch(tripSpacesProvider((widget.tripId, _filter)));
    final gutter = Breakpoints.gutter(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.spacesFor(tripDate(trip.date)))),
      body: ListView(padding: EdgeInsets.all(gutter), children: [
        MaxWidth(
          maxWidth: 960,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _area,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.searchArea,
                suffixIcon: _area.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: l10n.clear,
                        onPressed: () {
                          _area.clear();
                          _search();
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.spacesMatchHint(l10n.vehicle(trip.vehicle)), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            spaces.when(
              loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text(apiErrorMessage(e, l10n.couldNotLoad)),
              data: (list) => list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(children: [
                        Icon(Icons.search_off, size: 48, color: scheme.outline),
                        const SizedBox(height: 8),
                        Text(_filter == null ? l10n.noSpacesThatDay : l10n.noSpacesInArea,
                            textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                      ]),
                    )
                  : LayoutBuilder(builder: (context, c) {
                      final cols = c.maxWidth >= 640 ? 2 : 1;
                      final width = (c.maxWidth - 16 * (cols - 1)) / cols;
                      return Wrap(spacing: 16, runSpacing: 16, children: [
                        for (final s in list)
                          SizedBox(
                            width: width,
                            child: _SpaceResult(space: s, onRequest: trip.canBook ? () => _request(trip, s) : null),
                          ),
                      ]);
                    }),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SpaceResult extends StatelessWidget {
  const _SpaceResult({required this.space, required this.onRequest});
  final SpaceCard space;
  final VoidCallback? onRequest;

  void _gallery(BuildContext context) => showDialog<void>(
        context: context,
        builder: (dialog) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(children: [
            PageView(children: [
              for (final url in space.photoUrls)
                InteractiveViewer(child: Center(child: Image.network('$apiOrigin$url'))),
            ]),
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: IconButton.filledTonal(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialog)),
              ),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = space;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: s.photoUrls.isEmpty
              ? ColoredBox(color: scheme.surfaceContainerHighest, child: Icon(Icons.home_work, size: 48, color: scheme.outline))
              : InkWell(
                  onTap: () => _gallery(context),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.network('$apiOrigin${s.photoUrls.first}', fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(color: scheme.surfaceContainerHighest)),
                    if (s.photoUrls.length > 1)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.photo_library_outlined, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('${s.photoUrls.length}', style: const TextStyle(color: Colors.white)),
                          ]),
                        ),
                      ),
                  ]),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(s.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...spaceFacts(l10n, s),
            if (s.rules != null) IconFact(Icons.rule, s.rules!),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: Text(l10n.requestThisSpace),
              onPressed: onRequest,
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Confirms a space request with an optional message. Pops with the message ('' for none), or null if dismissed.
class _RequestSheet extends StatefulWidget {
  const _RequestSheet({required this.trip, required this.space});
  final Trip trip;
  final SpaceCard space;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.space;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.requestSpaceTitle(s.title), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('${tripDate(widget.trip.date)} · ${s.openFrom} – ${s.openTo} · ${feeLabel(l10n, s.isFree, s.fee)}'),
        const SizedBox(height: 16),
        TextField(
          controller: _message,
          maxLength: 200,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.messageToHost, hintText: l10n.messageToHostHint),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          icon: const Icon(Icons.send),
          label: Text(l10n.sendRequest),
          onPressed: () => Navigator.pop(context, _message.text.trim()),
        ),
      ]),
    );
  }
}
