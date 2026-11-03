import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/trip_models.dart';
import '../../core/labels.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';

/// "Sat, 7 Nov" in the app language.
String tripDate(DateTime d) => DateFormat('EEE, d MMM').format(d);

/// Vehicles in size order, as the API names them.
const vehicles = ['TwoWheeler', 'Auto', 'MiniTruck', 'Tractor'];

IconData vehicleIcon(String v) => switch (v) {
      'TwoWheeler' => Icons.two_wheeler,
      'Auto' => Icons.electric_rickshaw,
      'MiniTruck' => Icons.local_shipping,
      _ => Icons.agriculture,
    };

/// "₹1000 per slot" or "Free".
String feeLabel(AppLocalizations l10n, bool isFree, double fee) =>
    isFree || fee == 0 ? l10n.free : l10n.perSlot(fee.toStringAsFixed(0));

/// A large calendar block (weekday, day, month) for "next trip" and "next booking" cards.
class DateBlock extends StatelessWidget {
  const DateBlock({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(color: scheme.onPrimaryContainer);
    final phone = !Breakpoints.isWide(context);
    return Container(
      width: phone ? 72 : 96,
      color: scheme.primaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(DateFormat.E().format(date), style: style.copyWith(fontWeight: FontWeight.w600)),
        Text('${date.day}', style: style.copyWith(fontSize: phone ? 32 : 40, fontWeight: FontWeight.w800, height: 1.1)),
        Text(DateFormat.MMM().format(date), style: style),
      ]),
    );
  }
}

/// Booking or trip status as a coloured pill.
class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip(this.status, {super.key, this.forHost = false});

  /// Requested, Accepted, Declined, Cancelled; or a trip's Planned / Completed.
  final String status;

  /// The host sees a request as "New request" rather than "Waiting for host".
  final bool forHost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (status) {
      'Requested' =>
        (forHost ? l10n.newRequest : l10n.bookingRequested, scheme.warningContainer, scheme.onWarningContainer),
      'Accepted' => (l10n.bookingAccepted, scheme.primaryContainer, scheme.onPrimaryContainer),
      'Declined' => (l10n.bookingDeclined, scheme.errorContainer, scheme.onErrorContainer),
      'Planned' => (l10n.tripPlanned, scheme.secondaryContainer, scheme.onSecondaryContainer),
      'Completed' => (l10n.tripCompleted, scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      _ => (l10n.bookingCancelled, scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

/// The crops on a trip, with quantity and price when given, in the app language.
class ProduceChips extends ConsumerWidget {
  const ProduceChips(this.produce, {super.key});
  final List<ProduceItem> produce;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider);
    final crops = ref.watch(cropsProvider).value ?? const [];
    String num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final p in produce)
        Chip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(Icons.eco_outlined, size: 18),
          label: Text([
            crops.where((c) => c.code == p.cropCode).firstOrNull?.name(lang) ?? p.cropCode,
            if (p.quantityKg != null) l10n.kgAmount(num(p.quantityKg!)),
            if (p.pricePerKg != null) l10n.pricePerKgAmount(num(p.pricePerKg!)),
          ].join(' · ')),
        ),
    ]);
  }
}

/// The crops on a trip as one short line ("Banana, Brinjal +3"), for compact cards.
class ProduceLine extends ConsumerWidget {
  const ProduceLine(this.produce, {super.key, this.shown = 2});
  final List<ProduceItem> produce;
  final int shown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final crops = ref.watch(cropsProvider).value ?? const [];
    final names = [
      for (final p in produce) crops.where((c) => c.code == p.cropCode).firstOrNull?.name(lang) ?? p.cropCode,
    ];
    final more = names.length - shown;
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(Icons.eco_outlined, size: 18, color: scheme.primary),
      const SizedBox(width: 6),
      Expanded(
        child: Text('${names.take(shown).join(', ')}${more > 0 ? '  +$more' : ''}',
            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant)),
      ),
    ]);
  }
}

/// Why a booking ended, for the farmer: declined with reason, slot taken, or cancelled (by whom, why).
String? bookingOutcome(AppLocalizations l10n, Booking b) => switch (b.status) {
      'Declined' when b.slotTaken => l10n.bookingSlotTaken,
      'Declined' => l10n.bookingDeclinedBecause(b.reason ?? '–'),
      'Cancelled' when b.cancelledBy == 'Host' => l10n.bookingHostCancelled(b.reason ?? '–'),
      'Cancelled' => l10n.bookingYouCancelled,
      _ => null,
    };

/// One labelled fact with an icon (time, fee, vehicle…).
class IconFact extends StatelessWidget {
  const IconFact(this.icon, this.text, {super.key, this.bold = false});
  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15, fontWeight: bold ? FontWeight.w600 : null))),
        ]),
      );
}

/// Runs [action], shows [success] or the API's error, and returns whether it worked.
Future<bool> runWithToast(BuildContext context, Future<void> Function() action, {String? success}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await action();
    if (success != null) messenger.showSnackBar(SnackBar(content: Text(success)));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e, l10n.errorGeneric))));
    return false;
  }
}

/// Space facts shared by the search results and the booking card.
List<Widget> spaceFacts(AppLocalizations l10n, SpaceCard s) => [
      IconFact(Icons.place_outlined, '${l10n.spaceKind(s.type)} · ${s.locality}'),
      IconFact(Icons.schedule, '${s.openFrom} – ${s.openTo}'),
      IconFact(Icons.currency_rupee, feeLabel(l10n, s.isFree, s.fee), bold: true),
      IconFact(Icons.square_foot, l10n.areaValue(s.areaSqFt, s.maxStallSize)),
      IconFact(vehicleIcon(s.maxVehicle), l10n.upToVehicle(l10n.vehicle(s.maxVehicle))),
      if (s.amenities.isNotEmpty) IconFact(Icons.check_circle_outline, s.amenities.map(l10n.amenity).join(', ')),
    ];
