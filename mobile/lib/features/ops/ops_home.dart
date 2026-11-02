import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/ops_api.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';
import 'farmer_queue.dart';
import 'space_queue.dart';
import 'verifiers_page.dart';

/// Home for staff accounts (Verifier, Admin) — the operations console inside the app, on web and phones.
/// Staff roles are never chosen at sign-up: an admin adds verifiers, and admins are created on the server.
class OpsHome extends ConsumerStatefulWidget {
  const OpsHome({super.key});

  @override
  ConsumerState<OpsHome> createState() => _OpsHomeState();
}

class _OpsHomeState extends ConsumerState<OpsHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ref.watch(opsDashboardProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) {
            // 403: the staff role was removed since this device signed in.
            final revoked = e is DioException && e.response?.statusCode == 403;
            return EmptyState(
              icon: revoked ? Icons.lock_outline : Icons.cloud_off,
              title: revoked ? 'You no longer have staff access' : l10n.errorGeneric,
              body: revoked ? 'Ask an admin if you think this is a mistake. Log out to continue with your other account.' : '',
              action: revoked
                  ? const LogoutButton()
                  : OutlinedButton(onPressed: () => ref.invalidate(opsDashboardProvider), child: Text(l10n.retry)),
            );
          },
          data: (d) {
            final pages = <(IconData, String, Widget)>[
              (Icons.dashboard_outlined, 'Dashboard', _Dashboard(d, open: (tab) => setState(() => _tab = tab))),
              (Icons.agriculture, 'Farmers', FarmerQueue(isAdmin: d.isAdmin)),
              (Icons.home_work_outlined, 'Spaces', const SpaceQueue()),
              if (d.isAdmin) (Icons.badge_outlined, 'Verifiers', const VerifiersPage()),
            ];
            final tab = _tab.clamp(0, pages.length - 1);
            final page = pages[tab].$3;
            if (Breakpoints.isWide(context)) {
              return Row(children: [
                NavigationRail(
                  selectedIndex: tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final (icon, label, _) in pages) NavigationRailDestination(icon: Icon(icon), label: Text(label)),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ]);
            }
            return Column(children: [
              Expanded(child: page),
              NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: [for (final (icon, label, _) in pages) NavigationDestination(icon: Icon(icon), label: label)],
              ),
            ]);
          },
        );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard(this.d, {required this.open});
  final OpsDashboard d;
  final ValueChanged<int> open;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tiles = [
      (d.farmersWaiting, d.isAdmin ? 'Farmers waiting for review' : 'Farmers waiting for you', 1, d.farmersWaiting > 0),
      if (d.isAdmin) (d.farmersUnassigned, 'Waiting with no verifier', 1, d.farmersUnassigned > 0),
      if (d.isAdmin) (d.verifiers, 'Verifiers', 3, false),
      (d.spacesWaiting, 'Spaces waiting for approval', 2, d.spacesWaiting > 0),
      (d.farmersVerified, d.isAdmin ? 'Verified farmers' : 'Farmers you verified', 1, false),
      (d.spacesLive, 'Live spaces', 2, false),
    ];
    return ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
      MaxWidth(
        maxWidth: 960,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Hello${d.name == null ? '' : ', ${d.name}'}', style: text.headlineSmall),
          Text(d.isAdmin ? 'Admin · you see every farmer and manage verifiers' : 'Verifier · you review the farmers assigned to you',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 720 ? 3 : 2;
            final width = (c.maxWidth - 12 * (cols - 1)) / cols;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final (value, label, tab, highlight) in tiles)
                SizedBox(width: width, child: _StatTile(value: value, label: label, highlight: highlight, onTap: () => open(tab))),
            ]);
          }),
        ]),
      ),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, required this.highlight, required this.onTap});
  final int value;
  final String label;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: highlight ? Colors.amber.shade50 : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w700, color: highlight ? Colors.amber.shade900 : scheme.primary)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
