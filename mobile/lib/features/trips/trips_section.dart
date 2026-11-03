import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/trip_api.dart';
import '../../core/api/trip_models.dart';
import '../../core/labels.dart';
import '../../l10n/app_localizations.dart';
import 'trip_widgets.dart';

/// Counts for the farmer dashboard, from the trip list (planned trips come first, soonest at the top).
({int upcoming, int booked, int waiting, int completed}) tripStats(List<Trip> trips) => (
      upcoming: trips.where((t) => t.isPlanned).length,
      booked: trips.where((t) => t.isPlanned && t.booking?.status == 'Accepted').length,
      waiting: trips.where((t) => t.isPlanned && t.booking?.status == 'Requested').length,
      completed: trips.where((t) => t.status == 'Completed').length,
    );

/// One trip in a list: date block, status, vehicle and area, and the booked or requested space.
class TripCard extends ConsumerWidget {
  const TripCard({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final b = trip.booking;
    final past = !trip.isPlanned;
    // What the farmer should know at a glance: the booked space, the pending request, or "find a space".
    final (statusKey, line) = switch (b) {
      _ when trip.status == 'Cancelled' => ('Cancelled', null),
      final b? when b.isActive => (b.status, '${b.space.title} · ${b.from}–${b.to}'),
      _ when trip.isPlanned => ('Planned', l10n.noSpaceYet),
      _ => ('Completed', null),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push('/farmer/trips/${trip.id}');
          ref.invalidate(tripsProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: past ? scheme.surfaceContainerHighest : scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                Text('${trip.date.day}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: past ? scheme.onSurfaceVariant : scheme.onPrimaryContainer)),
                Text(tripDate(trip.date).split(',').first,
                    style: TextStyle(fontSize: 12, color: past ? scheme.onSurfaceVariant : scheme.onPrimaryContainer)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(tripDate(trip.date), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  BookingStatusChip(statusKey),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(vehicleIcon(trip.vehicle), size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(l10n.vehicle(trip.vehicle), style: TextStyle(color: scheme.onSurfaceVariant)),
                  if (trip.preferredArea != null) ...[
                    Text('  ·  ', style: TextStyle(color: scheme.onSurfaceVariant)),
                    Flexible(
                      child: Text(trip.preferredArea!,
                          overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant)),
                    ),
                  ],
                ]),
                if (line != null) ...[
                  const SizedBox(height: 6),
                  Text(line, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
