import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/models.dart';
import '../../core/api/trip_api.dart';
import '../../core/api/trip_models.dart';
import '../../core/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/dashboard.dart';
import '../../core/widgets/document_tile.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';
import '../trips/trip_widgets.dart';
import '../trips/trips_section.dart';

/// Farmer dashboard. Before Level 2: the verification status and how selling works.
/// Once verified: trip numbers, the next trip, all trips, and the evidence document.
class FarmerHome extends ConsumerWidget {
  const FarmerHome({super.key});

  Future<void> _planTrip(BuildContext context, WidgetRef ref) async {
    await context.push('/farmer/trips/new');
    ref.invalidate(tripsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final farmer = ref.watch(farmerProvider);
    return farmer.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => EmptyState(
        icon: Icons.cloud_off,
        title: l10n.errorGeneric,
        body: '',
        action: OutlinedButton(onPressed: () => ref.invalidate(farmerProvider), child: Text(l10n.retry)),
      ),
      data: (f) {
        final verified = f.status == 'Verified';
        final firstName = f.name?.trim().split(RegExp(r'\s+')).first;
        return RefreshIndicator(
          onRefresh: () {
            ref.invalidate(tripsProvider);
            return ref.refresh(farmerProvider.future);
          },
          child: ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
            MaxWidth(
              maxWidth: 960,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                DashboardBanner(
                  title: firstName == null || firstName.isEmpty ? l10n.greetingNoName : l10n.greetingName(firstName),
                  subtitle: verified ? l10n.farmerBannerVerified : l10n.farmerBannerNotVerified,
                  icon: verified ? Icons.verified : Icons.agriculture,
                  action: verified
                      ? BannerButton(icon: Icons.add, label: l10n.planTrip, onPressed: () => _planTrip(context, ref))
                      : null,
                ),
                if (verified)
                  _VerifiedDashboard(onPlan: () => _planTrip(context, ref))
                else ...[
                  SectionHeader(l10n.yourVerification),
                  _StatusCard(farmer: f),
                  SectionHeader(l10n.howItWorks),
                  HowItWorks(steps: [
                    (Icons.badge_outlined, l10n.howStepVerify, l10n.howStepVerifyBody),
                    (Icons.event_outlined, l10n.howStepTrip, l10n.howStepTripBody),
                    (Icons.home_work_outlined, l10n.howStepBook, l10n.howStepBookBody),
                    (Icons.storefront_outlined, l10n.howStepSell, l10n.howStepSellBody),
                  ]),
                ],
                // While editing, the photo is managed in the verification form; after submitting, here.
                if (f.hasEvidencePhoto && (f.status == 'Pending' || verified)) ...[
                  SectionHeader(l10n.yourDocument),
                  _EvidenceCard(farmer: f),
                ],
                const SizedBox(height: 16),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

/// Numbers, next trip and the trip list for a verified farmer.
class _VerifiedDashboard extends ConsumerWidget {
  const _VerifiedDashboard({required this.onPlan});
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(tripsProvider);
    return trips.when(
      loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.only(top: 24), child: Text(apiErrorMessage(e, l10n.couldNotLoad))),
      data: (list) {
        final s = tripStats(list);
        final next = list.where((t) => t.isPlanned).firstOrNull;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 16),
          StatGrid(children: [
            StatTile(value: s.upcoming, label: l10n.statUpcomingTrips, icon: Icons.event_outlined),
            StatTile(value: s.booked, label: l10n.statSpacesBooked, icon: Icons.home_work_outlined),
            StatTile(
                value: s.waiting, label: l10n.statWaitingHost, icon: Icons.hourglass_top, highlight: s.waiting > 0),
            StatTile(value: s.completed, label: l10n.statCompletedTrips, icon: Icons.task_alt),
          ]),
          SectionHeader(l10n.nextTrip),
          if (next != null) _NextTripCard(trip: next) else _NoTripCard(onPlan: onPlan),
          if (list.isNotEmpty) ...[
            SectionHeader(l10n.allTrips,
                action: TextButton.icon(icon: const Icon(Icons.add), label: Text(l10n.planTrip), onPressed: onPlan)),
            for (final t in list) TripCard(trip: t),
          ],
        ]);
      },
    );
  }
}

/// The soonest planned trip, with the one thing to do next: find a space, wait, or go.
class _NextTripCard extends ConsumerWidget {
  const _NextTripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final b = trip.booking;
    final accepted = b?.status == 'Accepted';
    final requested = b?.status == 'Requested';
    final (icon, color, line) = accepted
        ? (Icons.verified, scheme.primary, l10n.bookedAt(b!.space.title))
        : requested
            ? (Icons.hourglass_top, scheme.warning, l10n.waitingAt(b!.space.title))
            : (Icons.search, scheme.error, l10n.noSpaceYet);

    Future<void> open(String path) async {
      await context.push(path);
      ref.invalidate(tripsProvider);
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DateBlock(date: trip.date),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 6),
                  Expanded(child: Text(line, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 6),
                if (b != null && (accepted || requested))
                  Text('${b.from} – ${b.to} · ${feeLabel(l10n, b.fee == 0, b.fee)}',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(vehicleIcon(trip.vehicle), size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(l10n.vehicle(trip.vehicle), style: TextStyle(color: scheme.onSurfaceVariant)),
                ]),
                const SizedBox(height: 8),
                ProduceLine(trip.produce),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (trip.canBook)
                    FilledButton.icon(
                      icon: const Icon(Icons.search),
                      label: Text(l10n.findSpace),
                      onPressed: () => open('/farmer/trips/${trip.id}/spaces'),
                    ),
                  if (trip.canBook)
                    OutlinedButton(onPressed: () => open('/farmer/trips/${trip.id}'), child: Text(l10n.viewTrip))
                  else
                    FilledButton.tonal(onPressed: () => open('/farmer/trips/${trip.id}'), child: Text(l10n.viewTrip)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _NoTripCard extends StatelessWidget {
  const _NoTripCard({required this.onPlan});
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Icon(Icons.route_outlined, size: 48, color: scheme.primary),
          const SizedBox(height: 8),
          Text(l10n.noUpcomingTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.noUpcomingBody, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(icon: const Icon(Icons.add), label: Text(l10n.planTrip), onPressed: onPlan),
        ]),
      ),
    );
  }
}

/// Verification status for a farmer who is not verified yet, with the button to start, continue or fix it.
class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.farmer});
  final Farmer farmer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, title, body) = switch (farmer.status) {
      'Pending' => (Icons.hourglass_top, scheme.warning, l10n.verifyPendingTitle, l10n.verifyPendingBody),
      'Rejected' => (Icons.error_outline, scheme.error, l10n.rejectedTitle, l10n.rejectedReason(farmer.rejectionReason ?? '')),
      _ => (Icons.badge_outlined, scheme.primary, l10n.verifyNotStartedTitle, l10n.verifyNotStartedBody),
    };
    final steps = [l10n.stepAboutYou, l10n.stepEvidence, l10n.stepReview];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 28, backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color, size: 32)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 16),
          Text(body, style: const TextStyle(fontSize: 16, height: 1.4)),
          if (farmer.status == 'NotStarted') ...[
            const SizedBox(height: 20),
            for (final (i, s) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  CircleAvatar(radius: 14, backgroundColor: scheme.secondaryContainer, child: Text('${i + 1}')),
                  const SizedBox(width: 12),
                  Text(s, style: const TextStyle(fontSize: 16)),
                ]),
              ),
          ],
          if (farmer.canEdit) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: Text(switch (farmer.status) {
                  'Rejected' => l10n.fixAndResubmit,
                  _ when farmer.hasStarted => l10n.continueVerification,
                  _ => l10n.startVerification,
                }),
                onPressed: () async {
                  await context.push('/farmer/verify');
                  ref.invalidate(profileProvider);
                  ref.invalidate(farmerProvider);
                },
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// The submitted evidence photo: replace or delete while waiting for review, view and download once verified.
class _EvidenceCard extends ConsumerWidget {
  const _EvidenceCard({required this.farmer});
  final Farmer farmer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final waiting = farmer.status == 'Pending';
    final api = ref.read(farmerApiProvider);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (waiting) ...[
            Text(l10n.yourDocumentPendingHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: DocumentTile(
              label: l10n.evidence(farmer.evidenceType),
              hint: farmer.evidenceDetails,
              icon: Icons.photo_camera_outlined,
              filePath: evidencePhotoPath(farmer.evidencePhotoAt),
              fileName: 'evidence',
              canChange: waiting,
              deleteWarning: l10n.evidenceWithdrawWarning,
              onUpload: (photo) async {
                await api.uploadEvidencePhoto(photo);
                ref.invalidate(farmerProvider);
              },
              onDelete: () async {
                final withdrawn = await api.deleteEvidencePhoto();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(withdrawn ? l10n.evidenceWithdrawnToast : l10n.photoDeletedToast)));
                }
                ref.invalidate(farmerProvider);
              },
            ),
          ),
        ]),
      ),
    );
  }
}
