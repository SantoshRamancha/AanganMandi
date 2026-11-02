import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/ops_api.dart';
import '../../core/widgets/responsive.dart';
import 'ops_widgets.dart';

/// One farmer's details and proof; the assigned verifier (or an admin) approves or rejects, an admin can reassign.
class FarmerReviewScreen extends ConsumerWidget {
  const FarmerReviewScreen({super.key, required this.id});
  final String id;

  static const _quickReasons = [
    'Evidence photo is unclear — please retake it',
    'Name on the evidence does not match',
    'Could not confirm the Farmer ID',
    'The referee did not confirm you',
    'You sell only produce bought from other farmers',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmer = ref.watch(opsFarmerProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(farmer.value?.name ?? 'Review farmer')),
      body: farmer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(padding: const EdgeInsets.all(24), child: Text(apiErrorMessage(e, 'Could not load this farmer.'))),
        ),
        data: (f) => ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
          MaxWidth(
            maxWidth: 860,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Align(alignment: Alignment.centerLeft, child: StatusChip(f.status, farmerStatusLabel(f.status))),
              const SizedBox(height: 12),
              if (f.status == 'Rejected' && f.rejectionReason != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(leading: const Icon(Icons.error_outline), title: Text('Rejected: ${f.rejectionReason}')),
                ),
              InfoCard(title: 'Farming details', children: [
                Fact('Phone', '${f.phone}  (OTP verified)'),
                Fact('Village', f.village ?? '–'),
                Fact('District', f.district ?? '–'),
                Fact('Crops', f.crops.isEmpty ? '–' : f.crops.join(', ')),
                Fact('Farm size', f.farmSizeAcres == null ? 'Not given' : 'About ${f.farmSizeAcres} acres'),
                Fact('Sells', produceSourceLabel(f.produceSource), warn: f.produceSource == 'OtherFarmers'),
                Fact('Submitted', formatWhen(f.submittedAt)),
              ]),
              InfoCard(title: 'Farming evidence', children: [
                Fact('Type', evidenceLabel(f.evidenceType)),
                Fact('Details', f.evidenceDetails ?? '–'),
                if (f.evidenceType != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(evidenceHowToCheck(f.evidenceType), style: Theme.of(context).textTheme.bodySmall),
                  ),
                if (f.evidencePhoto != null) AuthImage(f.evidencePhoto!, height: 280) else const Text('No photo'),
              ]),
              if (f.olderDocuments.isNotEmpty)
                InfoCard(title: 'Documents from the earlier verification flow', children: [
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final d in f.olderDocuments) SizedBox(width: 180, child: AuthImage(d.path, height: 140, caption: d.type)),
                  ]),
                ]),
              _VerifierCard(farmer: f),
              if (f.canDecide)
                DecisionPanel(
                  guidance: 'Approve only if the evidence is real, the name on it matches this farmer, and they grow what they sell.',
                  approveLabel: 'Approve — verified farmer',
                  quickReasons: _quickReasons,
                  onDecide: (approve, reason) async {
                    await ref.read(opsApiProvider).decideFarmer(id, approve: approve, reason: reason);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(approve ? 'Approved: ${f.name} is a verified farmer' : 'Rejected. The farmer will see your reason.')));
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

class _VerifierCard extends ConsumerStatefulWidget {
  const _VerifierCard({required this.farmer});
  final OpsFarmer farmer;

  @override
  ConsumerState<_VerifierCard> createState() => _VerifierCardState();
}

class _VerifierCardState extends ConsumerState<_VerifierCard> {
  String? _choice;
  bool _busy = false;

  Future<void> _assign() async {
    setState(() => _busy = true);
    try {
      await ref.read(opsApiProvider).assignFarmer(widget.farmer.id, _choice!);
      ref.invalidate(opsFarmerProvider(widget.farmer.id));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verifier assigned')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e, 'Could not assign.'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.farmer;
    return InfoCard(title: 'Verifier', children: [
      Fact('Assigned to', f.assignedVerifierName ?? 'Unassigned', warn: f.assignedVerifierName == null && f.status == 'Pending'),
      if (f.assignedAt != null) Fact('Assigned on', formatWhen(f.assignedAt)),
      if (f.reviewedByName != null) Fact('Reviewed by', '${f.reviewedByName}, ${formatWhen(f.reviewedAt)}'),
      if (f.canAssign) ...[
        const SizedBox(height: 8),
        if (f.verifiers.isEmpty)
          const Text('There are no verifiers yet. Add one on the Verifiers tab.')
        else
          Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: DropdownButtonFormField<String>(
                initialValue: _choice,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Choose a verifier'),
                items: [
                  for (final v in f.verifiers) DropdownMenuItem(value: v.id, child: Text('${v.name} (${v.waiting} waiting)')),
                ],
                onChanged: (v) => setState(() => _choice = v),
              ),
            ),
            FilledButton.tonal(
              onPressed: _busy || _choice == null || _choice == f.assignedVerifierId ? null : _assign,
              child: Text(f.assignedVerifierId == null ? 'Assign' : 'Reassign'),
            ),
          ]),
      ],
    ]);
  }
}
