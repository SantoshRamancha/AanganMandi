import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/trip_api.dart';
import '../../core/api/trip_models.dart';
import '../../core/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import 'trip_widgets.dart';

/// One trip: what and when, then its space booking — find a space, waiting for the host, or booked
/// (address, host phone, map). Edit or cancel while it is planned.
class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.id});
  final String id;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(tripProvider(id));
    ref.invalidate(tripsProvider);
  }

  Future<bool> _confirm(BuildContext context, String title, String body, String yes) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(AppLocalizations.of(context).back)),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialog).colorScheme.error,
                foregroundColor: Theme.of(dialog).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(yes),
            ),
          ],
        ),
      ) ==
      true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trip = ref.watch(tripProvider(id));
    final api = ref.read(tripApiProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(trip.value == null ? l10n.myTrips : tripDate(trip.value!.date)),
        actions: [
          if (trip.value case final t? when t.isPlanned) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.editTrip,
              onPressed: () async {
                await context.push('/farmer/trips/$id/edit');
                _refresh(ref);
              },
            ),
            IconButton(
              icon: const Icon(Icons.event_busy_outlined),
              tooltip: l10n.cancelTrip,
              onPressed: () async {
                if (!await _confirm(context, l10n.cancelTripQ, l10n.cancelTripBody, l10n.cancelTrip)) return;
                if (!context.mounted) return;
                if (await runWithToast(context, () => api.cancel(id), success: l10n.tripCancelledToast)) _refresh(ref);
              },
            ),
          ],
          SizedBox(width: Breakpoints.gutter(context) - 8),
        ],
      ),
      body: trip.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e, l10n.couldNotLoad))),
        data: (t) => RefreshIndicator(
          onRefresh: () => ref.refresh(tripProvider(id).future),
          child: ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
            MaxWidth(
              maxWidth: 760,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                FormSection(
                  title: l10n.tripDetails,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(
                        child: Text(tripDate(t.date), style: Theme.of(context).textTheme.titleLarge),
                      ),
                      BookingStatusChip(t.status),
                    ]),
                    const SizedBox(height: 12),
                    IconFact(vehicleIcon(t.vehicle), l10n.vehicle(t.vehicle)),
                    if (t.preferredArea != null) IconFact(Icons.place_outlined, t.preferredArea!),
                    if (t.notes != null) IconFact(Icons.notes, t.notes!),
                    const SizedBox(height: 4),
                    ProduceChips(t.produce),
                  ]),
                ),
                _BookingCard(trip: t, onChanged: () => _refresh(ref), confirm: _confirm),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.trip, required this.onChanged, required this.confirm});
  final Trip trip;
  final VoidCallback onChanged;
  final Future<bool> Function(BuildContext, String, String, String) confirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final b = trip.booking;
    final api = ref.read(tripApiProvider);

    Future<void> cancelBooking() async {
      if (!await confirm(context, l10n.cancelBookingQ, l10n.cancelBookingBody, l10n.cancelBooking)) return;
      if (!context.mounted) return;
      if (await runWithToast(context, () => api.cancelBooking(trip.id, b!.id), success: l10n.bookingCancelledToast)) {
        onChanged();
      }
    }

    // Booked: everything needed on the day.
    if (b != null && b.status == 'Accepted') {
      final h = b.host!;
      return _StatusPanel(
        icon: Icons.verified,
        title: l10n.spaceBookedTitle,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        children: [
          Text(b.space.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          IconFact(Icons.schedule, '${tripDate(b.date)} · ${b.from} – ${b.to}', bold: true),
          IconFact(Icons.home_outlined, h.address),
          IconFact(Icons.person_outline, '${h.name ?? ''}  ${h.phone}'),
          IconFact(Icons.currency_rupee, '${feeLabel(l10n, b.fee == 0, b.fee)} · ${l10n.payAtSpace}'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              icon: const Icon(Icons.call),
              label: Text(l10n.callHost),
              onPressed: () => launchUrl(Uri.parse('tel:${h.phone}')),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.openInMaps),
              onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps?q=${h.latitude},${h.longitude}'),
                  mode: LaunchMode.externalApplication),
            ),
            if (trip.isPlanned)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                onPressed: cancelBooking,
                child: Text(l10n.cancelBooking),
              ),
          ]),
        ],
      );
    }

    // Waiting for the host.
    if (b != null && b.status == 'Requested') {
      return _StatusPanel(
        icon: Icons.hourglass_top,
        title: l10n.waitingForHostTitle,
        background: scheme.warningContainer,
        foreground: scheme.onWarningContainer,
        children: [
          Text(l10n.waitingForHostBody, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Text(b.space.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...spaceFacts(l10n, b.space).take(3),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              onPressed: cancelBooking,
              child: Text(l10n.cancelRequest),
            ),
          ),
        ],
      );
    }

    // No active booking: say how the last one ended, then offer to find a space.
    final outcome = b == null ? null : bookingOutcome(l10n, b);
    return FormSection(
      title: l10n.spaceForTrip,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (outcome != null)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: scheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.info_outline, color: scheme.onErrorContainer),
              title: Text(b!.space.title, style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w600)),
              subtitle: Text(outcome, style: TextStyle(color: scheme.onErrorContainer)),
            ),
          ),
        if (trip.canBook) ...[
          Text(outcome == null ? l10n.findSpaceIntro : l10n.findAnotherSpaceIntro),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.search),
            label: Text(outcome == null ? l10n.findSpace : l10n.findAnotherSpace),
            onPressed: () async {
              await context.push('/farmer/trips/${trip.id}/spaces');
              onChanged();
            },
          ),
        ] else
          Text(trip.status == 'Cancelled' ? l10n.tripWasCancelled : l10n.tripIsOver,
              style: TextStyle(color: scheme.onSurfaceVariant)),
      ]),
    );
  }
}

/// A card with a coloured header (icon + title) over a plain body, so buttons in the body keep normal contrast.
class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.title,
    required this.background,
    required this.foreground,
    required this.children,
  });
  final IconData icon;
  final String title;
  final Color background, foreground;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ColoredBox(
            color: background,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(children: [
                Icon(icon, color: foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: foreground)),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ]),
      );
}
