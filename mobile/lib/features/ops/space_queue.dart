import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/ops_api.dart';
import '../../core/widgets/responsive.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final rows = ref.watch(opsSpacesProvider(_status));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(opsSpacesProvider(_status).future),
      child: ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
        MaxWidth(
          maxWidth: 960,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Space approvals', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            StatusFilter(
              selected: _status,
              onChanged: (s) => setState(() => _status = s),
              options: [for (final s in ['PendingReview', 'Live', 'Rejected', 'Draft']) (s, spaceStatusLabel(s))],
            ),
            const SizedBox(height: 16),
            rows.when(
              loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text(apiErrorMessage(e, 'Could not load spaces.')),
              data: (list) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (list.isEmpty)
                  Padding(padding: const EdgeInsets.all(24), child: Text('No spaces in this list.', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant))),
                for (final s in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.home_work_outlined),
                      title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${s.type} · ${s.locality}\nHost: ${s.hostName} · updated ${formatWhen(s.updatedAt)}'),
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
