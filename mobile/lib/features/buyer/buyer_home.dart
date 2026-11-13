import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/trip_api.dart';
import '../../core/api/trip_models.dart';
import '../../core/location.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../trips/trip_widgets.dart';

/// Buyer home: save where you live and how far you will go, then see verified farmers selling inside that area
/// today and tomorrow (selling now first). The exact place shows only once the farmer has arrived.
class BuyerHome extends ConsumerWidget {
  const BuyerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(buyerSettingsProvider);
    final gutter = Breakpoints.gutter(context);
    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(apiErrorMessage(e, l10n.couldNotLoad)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => ref.invalidate(buyerSettingsProvider), child: Text(l10n.retry)),
        ]),
      ),
      data: (s) {
        final area = s.area;
        // No area yet: explain and ask for it.
        if (area == null) {
          return ListView(padding: EdgeInsets.all(gutter), children: [
            MaxWidth(
              maxWidth: 640,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Icon(Icons.storefront_outlined, size: 40, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(l10n.nearbySetupTitle, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(l10n.nearbySetupBody, style: const TextStyle(fontSize: 16, height: 1.4)),
                    const SizedBox(height: 16),
                    AreaForm(hasEmail: s.hasEmail),
                  ]),
                ),
              ),
            ),
          ]);
        }

        final stalls = ref.watch(nearbyStallsProvider);
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(buyerSettingsProvider);
            await ref.refresh(nearbyStallsProvider.future).catchError((_) => <NearbyStall>[]);
          },
          child: ListView(padding: EdgeInsets.all(gutter), children: [
            MaxWidth(
              maxWidth: 760,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l10n.nearbyTitle, style: Theme.of(context).textTheme.titleLarge),
                      Text(l10n.withinKm(area.radiusKm),
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.tune),
                    label: Text(l10n.changeArea),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (sheet) => SafeArea(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(sheet).bottom),
                          child: AreaForm(initial: area, hasEmail: s.hasEmail, inSheet: true),
                        ),
                      ),
                    ),
                  ),
                ]),
                if (area.alertsOn && !s.hasEmail)
                  Card(
                    margin: const EdgeInsets.only(top: 12),
                    child: ListTile(leading: const Icon(Icons.mail_outline), title: Text(l10n.addEmailForAlerts)),
                  ),
                const SizedBox(height: 12),
                ...stalls.when(
                  loading: () => [const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))],
                  error: (e, _) => [Text(apiErrorMessage(e, l10n.couldNotLoad))],
                  data: (list) => list.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(l10n.nearbyEmpty,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                        ]
                      : [for (final st in list) StallCard(stall: st)],
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

/// One farmer's stall: when, how far, what they bring; while selling now, the address and a map link.
class StallCard extends StatelessWidget {
  const StallCard({super.key, required this.stall});
  final NearbyStall stall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = stall;
    final today = DateUtils.isSameDay(s.date, DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: s.sellingNow
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: scheme.primary, width: 2))
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Chip(
              avatar: Icon(s.sellingNow ? Icons.storefront : Icons.event, size: 18,
                  color: s.sellingNow ? scheme.onPrimary : scheme.onSecondaryContainer),
              label: Text(s.sellingNow ? l10n.sellingNow : (today ? l10n.today : l10n.tomorrow)),
              backgroundColor: s.sellingNow ? scheme.primary : scheme.secondaryContainer,
              labelStyle: TextStyle(
                  color: s.sellingNow ? scheme.onPrimary : scheme.onSecondaryContainer, fontWeight: FontWeight.w600),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
            Text(s.sellingNow ? l10n.untilTime(s.to) : '${s.from} – ${s.to}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('· ${l10n.kmAway(s.distanceKm.toStringAsFixed(1))}', style: TextStyle(color: scheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 8),
          Text([s.farmerName ?? l10n.noName, ?s.village].join(', '),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${s.spaceTitle} · ${s.locality}', style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          ProduceChips(s.produce),
          const SizedBox(height: 8),
          if (s.sellingNow && s.address != null) ...[
            IconFact(Icons.place_outlined, s.address!, bold: true),
            if (s.latitude != null && s.longitude != null)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.map_outlined),
                  label: Text(l10n.openInMaps),
                  onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps?q=${s.latitude},${s.longitude}'),
                      mode: LaunchMode.externalApplication),
                ),
              ),
          ] else
            Text(l10n.exactPlaceLater, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
        ]),
      ),
    );
  }
}

/// Where the buyer lives (from GPS), how far they will go, and email alerts on or off. In the sheet it can also
/// remove the area. Saving refreshes the nearby list.
class AreaForm extends ConsumerStatefulWidget {
  const AreaForm({super.key, this.initial, required this.hasEmail, this.inSheet = false});
  final BuyerArea? initial;
  final bool hasEmail, inSheet;

  @override
  ConsumerState<AreaForm> createState() => _AreaFormState();
}

class _AreaFormState extends ConsumerState<AreaForm> {
  late double? _lat = widget.initial?.latitude;
  late double? _lng = widget.initial?.longitude;
  late int _radius = widget.initial?.radiusKm ?? 2;
  late bool _alerts = widget.initial?.alertsOn ?? true;
  bool _busy = false;

  Future<void> _locate() async {
    setState(() => _busy = true);
    final pos = await currentPosition();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (pos != null) {
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
    });
    if (pos == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).locationDenied)));
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(buyerSettingsProvider);
      ref.invalidate(nearbyStallsProvider);
      messenger.showSnackBar(SnackBar(content: Text(success)));
      if (widget.inSheet) navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e, l10n.errorGeneric))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final api = ref.read(buyerApiProvider);
    final located = _lat != null && _lng != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      OutlinedButton.icon(
        icon: Icon(located ? Icons.check_circle : Icons.my_location, color: located ? scheme.primary : null),
        label: Text(located ? l10n.locationSaved : l10n.useMyLocation),
        onPressed: _busy ? null : _locate,
      ),
      const SizedBox(height: 16),
      Text(l10n.howFar, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      SegmentedButton<int>(
        segments: [for (final km in const [1, 2, 5]) ButtonSegment(value: km, label: Text(l10n.radiusKm(km)))],
        selected: {_radius},
        onSelectionChanged: (v) => setState(() => _radius = v.first),
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.emailAlerts),
        subtitle: Text(widget.hasEmail ? l10n.emailAlertsBody : l10n.addEmailForAlerts),
        value: _alerts,
        onChanged: (v) => setState(() => _alerts = v),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: !located || _busy
            ? null
            : () => _run(
                () => api.saveArea(BuyerArea(latitude: _lat!, longitude: _lng!, radiusKm: _radius, alertsOn: _alerts)),
                l10n.areaSavedToast),
        child: Text(l10n.save),
      ),
      if (widget.inSheet && widget.initial != null)
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: _busy ? null : () => _run(api.deleteArea, l10n.areaRemovedToast),
          child: Text(l10n.removeArea),
        ),
    ]);
  }
}
