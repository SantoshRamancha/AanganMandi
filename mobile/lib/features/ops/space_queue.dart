import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/ops_api.dart';
import '../../core/labels.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import 'ops_widgets.dart';

/// Spaces hosts submitted; any verifier or admin can approve them.
class SpaceQueue extends ConsumerStatefulWidget {
  const SpaceQueue({super.key});

  @override
  ConsumerState<SpaceQueue> createState() => _SpaceQueueState();
}

class _SpaceQueueState extends ConsumerState<SpaceQueue> {
  String _status = 'PendingReview';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rows = ref.watch(opsSpacesProvider(_status));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(opsSpacesProvider(_status).future),
      child: ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
        MaxWidth(
          maxWidth: 960,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PageHeader(l10n.spaceApprovals),
            StatusFilter(
              selected: _status,
              onChanged: (s) => setState(() => _status = s),
              options: [for (final s in ['PendingReview', 'Live', 'Rejected', 'Draft']) (s, l10n.spaceStatus(s))],
            ),
            const SizedBox(height: 16),
            rows.when(
              loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text(apiErrorMessage(e, l10n.couldNotLoad)),
              data: (list) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(children: [
                      Icon(Icons.inbox_outlined, size: 48, color: scheme.outline),
                      const SizedBox(height: 8),
                      Text(l10n.emptyList, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                    ]),
                  ),
                for (final s in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.secondaryContainer,
                        foregroundColor: scheme.onSecondaryContainer,
                        child: const Icon(Icons.home_work_outlined),
                      ),
                      title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${l10n.spaceKind(s.type)} · ${s.locality}\n'
                          '${l10n.hostedBy(s.hostName, formatWhen(s.updatedAt))}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await context.push('/ops/spaces/${s.id}');
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
