import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/ops_api.dart';
import '../../core/widgets/dashboard.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';
import 'farmer_queue.dart';
import 'ops_widgets.dart';
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
              title: revoked ? l10n.staffAccessRevokedTitle : l10n.errorGeneric,
              body: revoked ? l10n.staffAccessRevokedBody : '',
              action: revoked
                  ? const LogoutButton()
                  : OutlinedButton(onPressed: () => ref.invalidate(opsDashboardProvider), child: Text(l10n.retry)),
            );
          },
          data: (d) {
            final pages = <(IconData, IconData, String, Widget)>[
              (Icons.space_dashboard_outlined, Icons.space_dashboard, l10n.opsTabDashboard,
                  _Dashboard(d, open: (tab) => setState(() => _tab = tab))),
              (Icons.agriculture_outlined, Icons.agriculture, l10n.opsTabFarmers, FarmerQueue(isAdmin: d.isAdmin)),
              (Icons.home_work_outlined, Icons.home_work, l10n.opsTabSpaces, const SpaceQueue()),
              if (d.isAdmin) (Icons.badge_outlined, Icons.badge, l10n.opsTabVerifiers, const VerifiersPage()),
            ];
            final tab = _tab.clamp(0, pages.length - 1);
            final page = pages[tab].$4;
            if (Breakpoints.isWide(context)) {
              return Row(children: [
                NavigationRail(
                  selectedIndex: tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -0.9,
                  destinations: [
                    for (final (icon, selected, label, _) in pages)
                      NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
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
                destinations: [
                  for (final (icon, selected, label, _) in pages)
                    NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
                ],
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
    final l10n = AppLocalizations.of(context);
    final tiles = [
      (d.farmersWaiting, d.isAdmin ? l10n.statFarmersWaitingAll : l10n.statFarmersWaitingYou, Icons.hourglass_top, 1,
          d.farmersWaiting > 0),
      if (d.isAdmin)
        (d.farmersUnassigned, l10n.statUnassigned, Icons.person_off_outlined, 1, d.farmersUnassigned > 0),
      if (d.isAdmin) (d.verifiers, l10n.opsTabVerifiers, Icons.badge_outlined, 3, false),
      (d.spacesWaiting, l10n.statSpacesWaiting, Icons.pending_actions, 2, d.spacesWaiting > 0),
      (d.farmersVerified, d.isAdmin ? l10n.statVerifiedAll : l10n.statVerifiedYou, Icons.verified_outlined, 1, false),
      (d.spacesLive, l10n.statSpacesLive, Icons.storefront_outlined, 2, false),
    ];
    return ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
      MaxWidth(
        maxWidth: 960,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageHeader(d.name == null ? l10n.opsHelloNoName : l10n.opsHello(d.name!),
              subtitle: d.isAdmin ? l10n.opsAdminSubtitle : l10n.opsVerifierSubtitle),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 720 ? 3 : 2;
            final width = (c.maxWidth - 12 * (cols - 1)) / cols;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final (value, label, icon, tab, highlight) in tiles)
                SizedBox(
                  width: width,
                  child: StatTile(value: value, label: label, icon: icon, highlight: highlight, onTap: () => open(tab)),
                ),
            ]);
          }),
        ]),
      ),
    ]);
  }
}

