import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/ops_api.dart';
import '../../core/labels.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../host/space_form_screen.dart' show weekdayLabel;
import 'ops_widgets.dart';

/// One space: details, right-to-use proof and photos; approve (goes Live) or reject with a reason.
class SpaceReviewScreen extends ConsumerWidget {
  const SpaceReviewScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = ref.watch(opsSpaceProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(space.value?.title ?? l10n.reviewSpace)),
      body: space.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(padding: const EdgeInsets.all(24), child: Text(apiErrorMessage(e, l10n.couldNotLoad))),
        ),
        data: (s) => ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
          MaxWidth(
            maxWidth: 860,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Align(alignment: Alignment.centerLeft, child: StatusChip(s.status, l10n.spaceStatus(s.status))),
              const SizedBox(height: 12),
              if (s.status == 'Rejected' && s.rejectionReason != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(leading: const Icon(Icons.error_outline), title: Text(l10n.rejectedWith(s.rejectionReason!))),
                ),
              InfoCard(title: l10n.spaceSection, children: [
                Fact(l10n.factType, l10n.spaceKind(s.type)),
                Fact(l10n.address, s.address),
                Fact(l10n.locality, s.locality),
                Fact(l10n.usableArea, l10n.areaValue(s.areaSqFt, s.maxStallSize)),
                Fact(l10n.maxVehicle, l10n.vehicle(s.maxVehicle)),
                Fact(l10n.amenities, s.amenities.isEmpty ? l10n.none : s.amenities.map(l10n.amenity).join(', ')),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l10n.openInMaps),
                    onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps?q=${s.latitude},${s.longitude}'),
                        mode: LaunchMode.externalApplication),
                  ),
                ),
              ]),
              InfoCard(title: l10n.availabilityAndHost, children: [
                Fact(l10n.availableDays, s.availableDays.map((d) => weekdayLabel(context, d)).join(', ')),
                Fact(l10n.hours, '${s.openFrom} – ${s.openTo}'),
                Fact(l10n.fee, s.isFree ? l10n.freeCommunitySpace : l10n.perSlot(s.fee.toStringAsFixed(0))),
                Fact(l10n.rules, s.rules ?? '–'),
                Fact(l10n.host, '${s.hostName}, ${s.hostPhone}'),
              ]),
              InfoCard(title: l10n.proofOfRight, children: [
                if (s.proof != null) AuthImage(s.proof!, height: 280) else Fact(l10n.proofOfRight, l10n.proofMissing, warn: true),
              ]),
              InfoCard(title: l10n.photosCount(s.photos.length), children: [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  for (final p in s.photos) SizedBox(width: 200, child: AuthImage(p, height: 150)),
                ]),
              ]),
              if (s.status == 'PendingReview')
                DecisionPanel(
                  guidance: l10n.spaceApproveGuidance,
                  approveLabel: l10n.spaceApproveLabel,
                  quickReasons: [l10n.qrSpacePublicRoad, l10n.qrSpacePhotos, l10n.qrSpaceProof, l10n.qrSpacePin],
                  onDecide: (approve, reason) async {
                    await ref.read(opsApiProvider).decideSpace(id, approve: approve, reason: reason);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(approve ? l10n.spaceLiveToast(s.title) : l10n.spaceRejectedToast)));
                    Navigator.of(context).pop();
                  },
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
