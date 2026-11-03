import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/ops_api.dart';
import '../../core/labels.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import 'ops_widgets.dart';

/// One farmer's details and proof; the assigned verifier (or an admin) approves or rejects, an admin can reassign.
class FarmerReviewScreen extends ConsumerWidget {
  const FarmerReviewScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final farmer = ref.watch(opsFarmerProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(farmer.value?.name ?? l10n.reviewFarmer)),
      body: farmer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(padding: const EdgeInsets.all(24), child: Text(apiErrorMessage(e, l10n.couldNotLoad))),
        ),
        data: (f) => ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
          MaxWidth(
            maxWidth: 860,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Align(alignment: Alignment.centerLeft, child: StatusChip(f.status, l10n.farmerStatus(f.status))),
              const SizedBox(height: 12),
              if (f.status == 'Rejected' && f.rejectionReason != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(l10n.rejectedWith(f.rejectionReason!)),
                  ),
                ),
              InfoCard(title: l10n.farmDetails, children: [
                Fact(l10n.mobileNumber, l10n.phoneOtpVerified(f.phone)),
                Fact(l10n.village, f.village ?? '–'),
                Fact(l10n.district, f.district ?? '–'),
                Fact(l10n.crops, f.crops.isEmpty ? '–' : f.crops.join(', ')),
                Fact(l10n.farmSize, f.farmSizeAcres == null ? l10n.notGiven : l10n.aboutAcres('${f.farmSizeAcres}')),
                Fact(l10n.sells, l10n.produceSource(f.produceSource), warn: f.produceSource == 'OtherFarmers'),
                Fact(l10n.submitted, formatWhen(f.submittedAt)),
              ]),
              InfoCard(title: l10n.farmingEvidence, children: [
                Fact(l10n.factType, l10n.evidence(f.evidenceType)),
                Fact(l10n.factDetails, f.evidenceDetails ?? '–'),
                if (f.evidenceType != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(l10n.evidenceHowToCheck(f.evidenceType), style: Theme.of(context).textTheme.bodySmall),
                  ),
                if (f.evidencePhoto != null) AuthImage(f.evidencePhoto!, height: 280) else Text(l10n.noPhoto),
              ]),
              if (f.olderDocuments.isNotEmpty)
                InfoCard(title: l10n.olderDocuments, children: [
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final d in f.olderDocuments) SizedBox(width: 180, child: AuthImage(d.path, height: 140, caption: d.type)),
                  ]),
                ]),
              _VerifierCard(farmer: f),
              if (f.canDecide)
                DecisionPanel(
                  guidance: l10n.farmerApproveGuidance,
                  approveLabel: l10n.farmerApproveLabel,
                  quickReasons: [
                    l10n.qrFarmerPhotoUnclear,
                    l10n.qrFarmerNameMismatch,
                    l10n.qrFarmerIdUnconfirmed,
                    l10n.qrFarmerRefereeNo,
                    l10n.qrFarmerNotGrower,
                  ],
                  onDecide: (approve, reason) async {
                    await ref.read(opsApiProvider).decideFarmer(id, approve: approve, reason: reason);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(approve ? l10n.farmerApprovedToast(f.name ?? f.phone) : l10n.farmerRejectedToast)));
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
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(opsApiProvider).assignFarmer(widget.farmer.id, _choice!);
      ref.invalidate(opsFarmerProvider(widget.farmer.id));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.verifierAssignedToast)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e, l10n.couldNotSave))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = widget.farmer;
    return InfoCard(title: l10n.roleNameVerifier, children: [
      Fact(l10n.assignedTo, f.assignedVerifierName ?? l10n.unassigned,
          warn: f.assignedVerifierName == null && f.status == 'Pending'),
      if (f.assignedAt != null) Fact(l10n.assignedOn, formatWhen(f.assignedAt)),
      if (f.reviewedByName != null) Fact(l10n.reviewedBy, '${f.reviewedByName}, ${formatWhen(f.reviewedAt)}'),
      if (f.canAssign) ...[
        const SizedBox(height: 8),
        if (f.verifiers.isEmpty)
          Text(l10n.noVerifiersYetAssign)
        else
          Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: DropdownButtonFormField<String>(
                initialValue: _choice,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.chooseVerifier),
                items: [
                  for (final v in f.verifiers) DropdownMenuItem(value: v.id, child: Text(l10n.verifierOption(v.name, v.waiting))),
                ],
                onChanged: (v) => setState(() => _choice = v),
              ),
            ),
            FilledButton.tonal(
              onPressed: _busy || _choice == null || _choice == f.assignedVerifierId ? null : _assign,
              child: Text(f.assignedVerifierId == null ? l10n.assign : l10n.reassign),
            ),
          ]),
      ],
    ]);
  }
}
