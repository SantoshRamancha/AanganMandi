import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/ops_api.dart';
import '../../core/widgets/responsive.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final rows = ref.watch(opsFarmersProvider(_status));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(opsFarmersProvider(_status).future),
      child: ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
        MaxWidth(
          maxWidth: 960,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Farmer verification', style: Theme.of(context).textTheme.headlineSmall),
            Text(widget.isAdmin ? 'All farmers. Each submission goes to the verifier with the fewest waiting.' : 'Farmers assigned to you, oldest first.',
                style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            StatusFilter(
              selected: _status,
              onChanged: (s) => setState(() => _status = s),
              options: [
                for (final s in ['Pending', 'Verified', 'Rejected', if (widget.isAdmin) 'NotStarted']) (s, farmerStatusLabel(s)),
              ],
            ),
            const SizedBox(height: 16),
            rows.when(
              loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text(apiErrorMessage(e, 'Could not load farmers.')),
              data: (list) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (widget.isAdmin && _status == 'Pending' && list.any((r) => r.verifierName == null))
                  Card(
                    color: Colors.amber.shade50,
                    child: const ListTile(
                      leading: Icon(Icons.warning_amber),
                      title: Text('Some farmers have no verifier'),
                      subtitle: Text('Add a verifier and they are assigned automatically, or open a farmer to assign one.'),
                    ),
                  ),
                if (list.isEmpty)
                  Padding(padding: const EdgeInsets.all(24), child: Text('No farmers in this list.', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant))),
                for (final r in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(r.name ?? '(no name)', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text([
                        r.phone,
                        if (r.village != null) '${r.village}, ${r.district ?? ''}',
                        if (r.evidenceType != null) evidenceLabel(r.evidenceType),
                        if (r.submittedAt != null) 'Submitted ${formatWhen(r.submittedAt)}',
                        if (widget.isAdmin && _status == 'Pending') 'Verifier: ${r.verifierName ?? 'Unassigned'}',
                      ].join('\n')),
                      isThreeLine: true,
                      trailing: widget.isAdmin && _status == 'Pending' && r.verifierName == null
                          ? const StatusChip('Pending', 'Unassigned')
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
