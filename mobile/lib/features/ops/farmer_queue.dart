import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/ops_api.dart';
import '../../core/districts.dart';
import '../../core/labels.dart';
import '../../core/storage/prefs.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import 'ops_widgets.dart';

/// Farmers to verify. A verifier sees only the farmers assigned to them; an admin sees all, with who has each.
class FarmerQueue extends ConsumerStatefulWidget {
  const FarmerQueue({super.key, required this.isAdmin});
  final bool isAdmin;

  @override
  ConsumerState<FarmerQueue> createState() => _FarmerQueueState();
}

class _FarmerQueueState extends ConsumerState<FarmerQueue> {
  String _status = 'Pending';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final rows = ref.watch(opsFarmersProvider(_status));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(opsFarmersProvider(_status).future),
      child: ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
        MaxWidth(
          maxWidth: 960,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PageHeader(l10n.farmerVerificationTitle,
                subtitle: widget.isAdmin ? l10n.farmerQueueAdminHint : l10n.farmerQueueVerifierHint),
            StatusFilter(
              selected: _status,
              onChanged: (s) => setState(() => _status = s),
              options: [
                for (final s in ['Pending', 'Verified', 'Rejected', if (widget.isAdmin) 'NotStarted']) (s, l10n.farmerStatus(s)),
              ],
            ),
            const SizedBox(height: 16),
            rows.when(
              loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text(apiErrorMessage(e, l10n.couldNotLoad)),
              data: (list) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (widget.isAdmin && _status == 'Pending' && list.any((r) => r.verifierName == null))
                  WarningCard(title: l10n.noVerifierWarnTitle, body: l10n.noVerifierWarnBody),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(children: [
                      Icon(Icons.inbox_outlined, size: 48, color: scheme.outline),
                      const SizedBox(height: 8),
                      Text(l10n.emptyList, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                    ]),
                  ),
                for (final r in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.secondaryContainer,
                        foregroundColor: scheme.onSecondaryContainer,
                        child: Text((r.name ?? '?').characters.first.toUpperCase()),
                      ),
                      title: Text(r.name ?? l10n.noName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text([
                        r.phone,
                        if (r.village != null) '${r.village}, ${r.district == null ? '' : districtName(r.district!, lang)}',
                        if (r.evidenceType != null) l10n.evidence(r.evidenceType),
                        if (r.submittedAt != null) l10n.submittedOn(formatWhen(r.submittedAt)),
                        if (widget.isAdmin && _status == 'Pending') l10n.verifierIs(r.verifierName ?? l10n.unassigned),
                      ].join('\n')),
                      isThreeLine: true,
                      trailing: widget.isAdmin && _status == 'Pending' && r.verifierName == null
                          ? StatusChip('Pending', l10n.unassigned)
                          : const Icon(Icons.chevron_right),
                      onTap: () async {
                        await context.push('/ops/farmers/${r.id}');
                        refreshOps(ref);
                      },
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
