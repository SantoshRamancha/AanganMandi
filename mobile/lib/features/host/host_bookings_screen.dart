import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/trip_api.dart';
import '../../core/api/trip_models.dart';
import '../../core/labels.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../trips/trip_widgets.dart';

/// Farmers' requests for the host's spaces (accept / decline), confirmed upcoming bookings, and past ones.
class HostBookingsScreen extends ConsumerWidget {
  const HostBookingsScreen({super.key, this.initialTab = 0});

  /// 0 requests, 1 upcoming, 2 past.
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requests = ref.watch(hostBookingsProvider('requests')).value?.length ?? 0;
    return DefaultTabController(
      initialIndex: initialTab.clamp(0, 2),
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.bookings),
          bottom: TabBar(tabs: [
            Tab(text: requests > 0 ? l10n.requestsCount(requests) : l10n.bookingRequestsTab),
            Tab(text: l10n.upcomingTab),
            Tab(text: l10n.pastTab),
          ]),
        ),
        body: const TabBarView(children: [_BookingList('requests'), _BookingList('upcoming'), _BookingList('past')]),
      ),
    );
  }
}

class _BookingList extends ConsumerWidget {
  const _BookingList(this.view);
  final String view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rows = ref.watch(hostBookingsProvider(view));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(hostBookingsProvider(view).future),
      child: ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
        MaxWidth(
          maxWidth: 760,
          child: rows.when(
            loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text(apiErrorMessage(e, l10n.couldNotLoad)),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(children: [
                      Icon(Icons.event_available_outlined, size: 48, color: scheme.outline),
                      const SizedBox(height: 8),
                      Text(switch (view) {
                        'requests' => l10n.noRequests,
                        'upcoming' => l10n.noUpcoming,
                        _ => l10n.noPastBookings,
                      }, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                    ]),
                  )
                : Column(children: [for (final b in list) _HostBookingCard(booking: b, view: view)]),
          ),
        ),
      ]),
    );
  }
}

class _HostBookingCard extends ConsumerWidget {
  const _HostBookingCard({required this.booking, required this.view});
  final HostBooking booking;
  final String view;

  /// Asks for the reason the farmer will see; null if cancelled.
  Future<String?> _reason(BuildContext context, String title, String action, List<String> quick) =>
      showDialog<String>(context: context, builder: (_) => _ReasonDialog(title: title, action: action, quick: quick));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final b = booking;
    final api = ref.read(hostBookingApiProvider);
    void refresh() {
      for (final v in ['requests', 'upcoming', 'past']) {
        ref.invalidate(hostBookingsProvider(v));
      }
    }

    final farmerFrom = [b.farmerVillage, b.farmerDistrict].whereType<String>().join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Text('${tripDate(b.date)} · ${b.from} – ${b.to}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            BookingStatusChip(b.status, forHost: true),
          ]),
          const SizedBox(height: 4),
          Text(b.spaceTitle, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          IconFact(Icons.verified_user_outlined,
              '${b.farmerName ?? l10n.noName}${farmerFrom.isEmpty ? '' : ' · $farmerFrom'} · ${l10n.verifiedFarmerTag}'),
          IconFact(vehicleIcon(b.vehicle), l10n.vehicle(b.vehicle)),
          if (b.farmerPhone != null) IconFact(Icons.phone_outlined, b.farmerPhone!, bold: true),
          if (b.message != null) IconFact(Icons.chat_bubble_outline, '“${b.message}”'),
          ProduceChips(b.produce),
          // The booking day: did the farmer check in at the space?
          if (b.status == 'Accepted') ...[
            const SizedBox(height: 8),
            if (b.arrivedAt case final at?)
              _ArrivalLine(Icons.where_to_vote, l10n.arrivedAt(TimeOfDay.fromDateTime(at).format(context)), scheme.primary)
            else if (b.noShow)
              _ArrivalLine(Icons.person_off_outlined, l10n.didNotCome, scheme.error)
            else if (DateUtils.isSameDay(b.date, DateTime.now()))
              _ArrivalLine(Icons.schedule, l10n.notArrivedYet, scheme.onSurfaceVariant),
            if (b.canMarkNoShow)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_off_outlined),
                  label: Text(l10n.didNotCome),
                  style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialog) => AlertDialog(
                        title: Text(l10n.markNoShowQ),
                        content: Text(l10n.markNoShowBody),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l10n.back)),
                          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: Text(l10n.didNotCome)),
                        ],
                      ),
                    );
                    if (ok != true || !context.mounted) return;
                    if (await runWithToast(context, () => api.markNoShow(b.id), success: l10n.noShowMarkedToast)) refresh();
                  },
                ),
              ),
          ],
          if (b.status == 'Declined' || b.status == 'Cancelled') ...[
            const SizedBox(height: 8),
            Text(
              b.slotTaken
                  ? l10n.hostAutoDeclined
                  : b.status == 'Cancelled' && b.cancelledBy == 'Farmer'
                      ? l10n.farmerCancelled
                      : l10n.yourReason(b.reason ?? '–'),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
          if (view == 'requests') ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: Text(l10n.accept),
                onPressed: () async {
                  if (await runWithToast(context, () => api.accept(b.id), success: l10n.acceptedToast)) refresh();
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: Text(l10n.decline),
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                onPressed: () async {
                  final reason = await _reason(context, l10n.declineQ, l10n.decline,
                      [l10n.qrNotAvailableDay, l10n.qrVehicleTooBig, l10n.qrOnlySomeProduce]);
                  if (reason == null || !context.mounted) return;
                  if (await runWithToast(context, () => api.decline(b.id, reason), success: l10n.declinedToast)) refresh();
                },
              ),
            ]),
          ],
          if (view == 'upcoming') ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (b.farmerPhone != null)
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.call),
                  label: Text(l10n.callFarmer),
                  onPressed: () => launchUrl(Uri.parse('tel:${b.farmerPhone}')),
                ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                onPressed: () async {
                  final reason = await _reason(context, l10n.cancelBookingQ, l10n.cancelBooking, [l10n.qrNotAvailableDay]);
                  if (reason == null || !context.mounted) return;
                  if (await runWithToast(context, () => api.cancel(b.id, reason), success: l10n.bookingCancelledToast)) {
                    refresh();
                  }
                },
                child: Text(l10n.cancelBooking),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

/// Whether the farmer has arrived, as one coloured line.
class _ArrivalLine extends StatelessWidget {
  const _ArrivalLine(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ]),
      );
}

/// Reason for declining or cancelling, with quick picks. Pops with the reason, or null for Back.
/// Owns its controller so it is disposed only after the dialog's closing animation.
class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.action, required this.quick});
  final String title, action;
  final List<String> quick;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in widget.quick) ActionChip(label: Text(r), onPressed: () => setState(() => _reason.text = r)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _reason,
          maxLength: 200,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.reasonForFarmer),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.back)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
          onPressed: _reason.text.trim().isEmpty ? null : () => Navigator.pop(context, _reason.text.trim()),
          child: Text(widget.action),
        ),
      ],
    );
  }
}
