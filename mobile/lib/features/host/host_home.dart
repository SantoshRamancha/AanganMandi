import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/models.dart';
import '../../core/api/trip_api.dart';
import '../../core/api/trip_models.dart' show HostBooking;
import '../../core/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/dashboard.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';
import '../trips/trip_widgets.dart';

/// Host dashboard: requests waiting for an answer, the next confirmed farmer, numbers, and the host's spaces.
/// With no spaces yet: how hosting works and a button to list the first one.
class HostHome extends ConsumerWidget {
  const HostHome({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    await context.push('/host/spaces/new');
    ref.invalidate(mySpacesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spaces = ref.watch(mySpacesProvider);
    final name = ref.watch(profileProvider).value?.name?.trim().split(RegExp(r'\s+')).first;
    final greeting = name == null || name.isEmpty ? l10n.greetingNoName : l10n.greetingName(name);
    return spaces.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => EmptyState(
        icon: Icons.cloud_off,
        title: l10n.errorGeneric,
        body: '',
        action: OutlinedButton(onPressed: () => ref.invalidate(mySpacesProvider), child: Text(l10n.retry)),
      ),
      data: (list) {
        final requests = ref.watch(hostBookingsProvider('requests')).value ?? const <HostBooking>[];
        final upcoming = ref.watch(hostBookingsProvider('upcoming')).value ?? const <HostBooking>[];
        final live = list.where((s) => s.status == 'Live').length;
        final inReview = list.where((s) => s.status == 'PendingReview').length;

        Future<void> openBookings([int tab = 0]) async {
          await context.push('/host/bookings?tab=$tab');
          ref.invalidate(hostBookingsProvider);
        }

        return RefreshIndicator(
          onRefresh: () {
            ref.invalidate(hostBookingsProvider);
            return ref.refresh(mySpacesProvider.future);
          },
          child: ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
            MaxWidth(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                DashboardBanner(
                  title: greeting,
                  subtitle: list.isEmpty ? l10n.hostBannerNew : l10n.hostBanner(live, requests.length),
                  icon: Icons.home_work,
                  action: BannerButton(icon: Icons.add, label: l10n.addSpace, onPressed: () => _add(context, ref)),
                ),
                if (list.isEmpty) ...[
                  SectionHeader(l10n.howItWorks),
                  HowItWorks(steps: [
                    (Icons.add_home_outlined, l10n.hostHowList, l10n.hostHowListBody),
                    (Icons.fact_check_outlined, l10n.hostHowApproved, l10n.hostHowApprovedBody),
                    (Icons.agriculture_outlined, l10n.hostHowRequests, l10n.hostHowRequestsBody),
                    (Icons.handshake_outlined, l10n.hostHowAccept, l10n.hostHowAcceptBody),
                  ]),
                ] else ...[
                  const SizedBox(height: 16),
                  StatGrid(children: [
                    StatTile(
                      value: requests.length,
                      label: l10n.statNewRequests,
                      icon: Icons.mark_email_unread_outlined,
                      highlight: requests.isNotEmpty,
                      onTap: openBookings,
                    ),
                    StatTile(
                      value: upcoming.length,
                      label: l10n.statUpcomingBookings,
                      icon: Icons.event_available_outlined,
                      onTap: () => openBookings(1),
                    ),
                    StatTile(value: live, label: l10n.statSpacesLive, icon: Icons.storefront_outlined),
                    StatTile(value: inReview, label: l10n.statusPendingReview, icon: Icons.pending_actions),
                  ]),
                  if (requests.isNotEmpty) ...[
                    SectionHeader(l10n.needsYourAnswer,
                        action: TextButton(onPressed: openBookings, child: Text(l10n.viewAll))),
                    for (final b in requests.take(3)) _RequestTile(booking: b, onTap: openBookings),
                  ],
                  SectionHeader(l10n.nextBooking),
                  if (upcoming.firstOrNull case final next?)
                    _NextBookingCard(booking: next, onTap: () => openBookings(1))
                  else
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(Icons.event_outlined, color: Theme.of(context).colorScheme.outline),
                        title: Text(l10n.noBookingYet),
                      ),
                    ),
                  SectionHeader(l10n.mySpaces,
                      action: TextButton.icon(
                          icon: const Icon(Icons.add), label: Text(l10n.addSpace), onPressed: () => _add(context, ref))),
                  LayoutBuilder(builder: (context, c) {
                    const gap = 16.0;
                    final cols = ((c.maxWidth + gap) / (340 + gap)).floor().clamp(1, 3);
                    final width = (c.maxWidth - gap * (cols - 1)) / cols;
                    return Wrap(spacing: gap, runSpacing: gap, children: [
                      for (final s in list) SizedBox(width: width, height: 300, child: SpaceCard(space: s)),
                    ]);
                  }),
                ],
                const SizedBox(height: 24),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

/// A farmer's request waiting for the host, in one line; opens the bookings screen to answer it.
class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.booking, required this.onTap});
  final HostBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final b = booking;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.warningContainer,
          foregroundColor: scheme.onWarningContainer,
          child: Text((b.farmerName ?? '?').characters.first.toUpperCase()),
        ),
        title: Text('${b.farmerName ?? l10n.noName} · ${tripDate(b.date)}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${b.spaceTitle} · ${b.from}–${b.to} · ${l10n.vehicle(b.vehicle)}'),
        trailing: FilledButton.tonal(onPressed: onTap, child: Text(l10n.answer)),
      ),
    );
  }
}

/// The soonest confirmed booking: who is coming, when, to which space, and a call button.
class _NextBookingCard extends StatelessWidget {
  const _NextBookingCard({required this.booking, required this.onTap});
  final HostBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final b = booking;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DateBlock(date: b.date),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.farmerName ?? l10n.noName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${b.spaceTitle} · ${b.from} – ${b.to}', style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  ProduceLine(b.produce),
                  if (b.farmerPhone != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.call),
                      label: Text(l10n.callFarmer),
                      onPressed: () => launchUrl(Uri.parse('tel:${b.farmerPhone}')),
                    ),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class SpaceCard extends ConsumerWidget {
  const SpaceCard({super.key, required this.space});
  final Space space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push('/host/spaces/${space.id}');
          ref.invalidate(mySpacesProvider);
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              space.photoUrls.isEmpty
                  ? ColoredBox(color: scheme.surfaceContainerHighest, child: Icon(Icons.home_work, size: 56, color: scheme.onSurfaceVariant))
                  : Image.network('$apiOrigin${space.photoUrls.first}', fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(color: scheme.surfaceContainerHighest)),
              Positioned(left: 12, top: 12, child: StatusChip(status: space.status)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(space.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${space.locality} · ${space.areaSqFt} sq ft', style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(space.isFree ? l10n.free : l10n.perSlot(space.fee.toStringAsFixed(0)),
                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Solid colours: the badge sits on top of a photo.
    final (label, bg, fg) = switch (status) {
      'Live' => (l10n.statusLive, scheme.primary, scheme.onPrimary),
      'PendingReview' => (l10n.statusPendingReview, scheme.warning, scheme.onWarning),
      'Rejected' => (l10n.statusRejected, scheme.error, scheme.onError),
      _ => (l10n.statusDraft, scheme.inverseSurface, scheme.onInverseSurface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

