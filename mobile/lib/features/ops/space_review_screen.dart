import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/ops_api.dart';
import '../../core/widgets/responsive.dart';
import 'ops_widgets.dart';

/// One space: details, right-to-use proof and photos; approve (goes Live) or reject with a reason.
class SpaceReviewScreen extends ConsumerWidget {
  const SpaceReviewScreen({super.key, required this.id});
  final String id;

  static const _quickReasons = [
    'Space is on a public road or footpath',
    'Photos are unclear or do not show the space',
    'Proof document does not show the right to use this space',
    'Location pin does not match the address',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(opsSpaceProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(space.value?.title ?? 'Review space')),
      body: space.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(padding: const EdgeInsets.all(24), child: Text(apiErrorMessage(e, 'Could not load this space.'))),
        ),
        data: (s) => ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
          MaxWidth(
            maxWidth: 860,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Align(alignment: Alignment.centerLeft, child: StatusChip(s.status, spaceStatusLabel(s.status))),
              const SizedBox(height: 12),
              if (s.status == 'Rejected' && s.rejectionReason != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(leading: const Icon(Icons.error_outline), title: Text('Rejected: ${s.rejectionReason}')),
                ),
              InfoCard(title: 'Space', children: [
                Fact('Type', s.type),
                Fact('Address', s.address),
                Fact('Locality', s.locality),
                Fact('Usable area', '${s.areaSqFt} sq ft (stall up to ${s.maxStallSize})'),
                Fact('Largest vehicle', s.maxVehicle),
                Fact('Amenities', s.amenities.isEmpty ? 'None' : s.amenities.join(', ')),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open location in maps'),
                    onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps?q=${s.latitude},${s.longitude}'),
                        mode: LaunchMode.externalApplication),
                  ),
                ),
              ]),
              InfoCard(title: 'Availability and host', children: [
                Fact('Days', s.availableDays.map((d) => d.length > 3 ? d.substring(0, 3) : d).join(', ')),
                Fact('Hours', '${s.openFrom} – ${s.openTo}'),
                Fact('Fee', s.isFree ? 'Free community space' : '₹${s.fee.toStringAsFixed(0)} per slot'),
                Fact('House rules', s.rules ?? '–'),
                Fact('Host', '${s.hostName}, ${s.hostPhone}'),
              ]),
              InfoCard(title: 'Right-to-use proof', children: [
                if (s.proof != null) AuthImage(s.proof!, height: 280) else const Fact('Proof', 'Missing', warn: true),
              ]),
              InfoCard(title: 'Photos (${s.photos.length})', children: [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  for (final p in s.photos) SizedBox(width: 200, child: AuthImage(p, height: 150)),
                ]),
              ]),
              if (s.status == 'PendingReview')
                DecisionPanel(
                  guidance: 'Approve only if it is private space (not a road or footpath), the photos match the location, '
                      'and the proof names the host or allows the use.',
                  approveLabel: 'Approve — make live',
                  quickReasons: _quickReasons,
                  onDecide: (approve, reason) async {
                    await ref.read(opsApiProvider).decideSpace(id, approve: approve, reason: reason);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(approve ? '${s.title} is live' : 'Rejected. The host will see your reason.')));
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
