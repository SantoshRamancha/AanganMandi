import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/models.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';

/// Host home: the host's spaces as a responsive grid, plus "Add a space".
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
    return spaces.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => EmptyState(
        icon: Icons.cloud_off,
        title: l10n.errorGeneric,
        body: '',
        action: OutlinedButton(onPressed: () => ref.invalidate(mySpacesProvider), child: Text(l10n.retry)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.home_work,
            title: l10n.noSpacesTitle,
            body: l10n.noSpacesBody,
            action: FilledButton.icon(icon: const Icon(Icons.add), label: Text(l10n.addSpace), onPressed: () => _add(context, ref)),
          );
        }
        final gutter = Breakpoints.gutter(context);
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: Text(l10n.addSpace),
            onPressed: () => _add(context, ref),
          ),
          body: RefreshIndicator(
            onRefresh: () => ref.refresh(mySpacesProvider.future),
            child: MaxWidth(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, 96),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisExtent: 320,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) => SpaceCard(space: list[i]),
              ),
            ),
          ),
        );
      },
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
    final (label, color) = switch (status) {
      'Live' => (l10n.statusLive, Colors.green.shade700),
      'PendingReview' => (l10n.statusPendingReview, Colors.amber.shade800),
      'Rejected' => (l10n.statusRejected, Colors.red.shade700),
      _ => (l10n.statusDraft, Colors.blueGrey.shade600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
