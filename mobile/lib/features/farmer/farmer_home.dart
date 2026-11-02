import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/app_api.dart';
import '../../core/api/models.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';

/// Farmer home: verification status first, since nothing else unlocks before Level 2.
class FarmerHome extends ConsumerWidget {
  const FarmerHome({super.key});

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
      data: (f) => RefreshIndicator(
        onRefresh: () => ref.refresh(farmerProvider.future),
        child: ListView(
          padding: EdgeInsets.all(Breakpoints.gutter(context)),
          children: [MaxWidth(maxWidth: 720, child: _StatusCard(farmer: f))],
        ),
      ),
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.farmer});
  final Farmer farmer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, title, body) = switch (farmer.status) {
      'Pending' => (Icons.hourglass_top, Colors.amber.shade800, l10n.verifyPendingTitle, l10n.verifyPendingBody),
      'Verified' => (Icons.verified, scheme.primary, l10n.verifiedTitle, l10n.verifiedBody),
      'Rejected' => (Icons.error_outline, scheme.error, l10n.rejectedTitle, l10n.rejectedReason(farmer.rejectionReason ?? '')),
      _ => (Icons.badge_outlined, scheme.primary, l10n.verifyNotStartedTitle, l10n.verifyNotStartedBody),
    };
    final steps = [l10n.stepAboutYou, l10n.stepEvidence, l10n.stepReview];

    return Card(
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
          if (farmer.status == 'Verified' && farmer.name != null) ...[
            const SizedBox(height: 16),
            Chip(avatar: Icon(Icons.verified, color: scheme.primary), label: Text('${farmer.name} · ${farmer.village ?? ''}')),
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
