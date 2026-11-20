import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/analytics_api.dart';
import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/crops.dart';
import '../../core/storage/prefs.dart';
import '../../core/widgets/dashboard.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import 'ops_widgets.dart';

/// The periods an admin can pick (the server accepts only these).
const analyticsPeriods = [7, 30, 90];

/// Admin analytics: how selling is going (requests, how hosts answer, stalls held, no-shows), day by day, the crops
/// and areas with most stalls, who is on the app, ratings and problem reports. Figures only, no names.
class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(analyticsProvider(_days));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(analyticsProvider(_days).future).then((_) {}, onError: (_) {}),
      child: ListView(
        padding: EdgeInsets.all(Breakpoints.gutter(context)),
        children: [
          MaxWidth(
            maxWidth: 960,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(l10n.analyticsTitle, subtitle: l10n.analyticsSubtitle),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<int>(
                    segments: [
                      for (final d in analyticsPeriods)
                        ButtonSegment(value: d, label: Text(l10n.lastDays(d)), tooltip: l10n.lastDays(d)),
                    ],
                    selected: {_days},
                    onSelectionChanged: (v) => setState(() => _days = v.first),
                  ),
                ),
                ...data.when(
                  loading: () => [
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (e, _) => [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Text(apiErrorMessage(e, l10n.couldNotLoad)),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => ref.invalidate(analyticsProvider(_days)),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  ],
                  data: (a) => _body(context, a),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context, Analytics a) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final lang = ref.watch(localeProvider);
    final crops = ref.watch(cropsProvider).value ?? const [];
    String pct(int? v) => v == null ? '–' : '$v%';
    String stars(double? v) => v == null ? '–' : '★ ${v.toStringAsFixed(1)}';
    final range = '${DateFormat.MMMd(locale).format(a.from)} – ${DateFormat.MMMd(locale).format(a.to)}';
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(range, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
      SectionHeader(l10n.analyticsSelling, top: 20),
      StatGrid(
        maxColumns: 3,
        children: [
          Figure(
            '${a.requests.made}',
            l10n.figRequests,
            Icons.send_outlined,
            caption: l10n.figRequestsDetail(a.requests.accepted, a.requests.declined, a.requests.waiting),
          ),
          Figure(pct(a.requests.acceptanceRate), l10n.figAcceptance, Icons.thumb_up_alt_outlined),
          Figure('${a.stalls.held} / ${a.stalls.confirmed}', l10n.figStallsHeld, Icons.storefront_outlined),
          Figure(pct(a.stalls.showRate), l10n.figShowRate, Icons.how_to_reg_outlined),
          Figure('${a.stalls.noShows}', l10n.figNoShows, Icons.person_off_outlined, warn: a.stalls.noShows > 0),
          Figure(
            '₹${NumberFormat.decimalPattern(locale).format(a.stalls.hostFees)}',
            l10n.figHostFees,
            Icons.currency_rupee,
          ),
        ],
      ),
      SectionHeader(l10n.analyticsDaily),
      Card(
        margin: EdgeInsets.zero,
        child: Padding(padding: const EdgeInsets.all(16), child: DailyBars(a.daily)),
      ),
      SectionHeader(l10n.analyticsTop),
      LayoutBuilder(
        builder: (context, c) {
          final cropsCard = TopList(
            title: l10n.topCrops,
            items: [for (final t in a.topCrops) (cropName(t.key, crops, lang), t.stalls)],
          );
          final areasCard = TopList(title: l10n.topAreas, items: [for (final t in a.topAreas) (t.key, t.stalls)]);
          if (c.maxWidth < 640) return Column(children: [cropsCard, const SizedBox(height: 12), areasCard]);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cropsCard),
              const SizedBox(width: 12),
              Expanded(child: areasCard),
            ],
          );
        },
      ),
      SectionHeader(l10n.analyticsPeople),
      StatGrid(
        maxColumns: 3,
        children: [
          Figure(
            '${a.people.users}',
            l10n.figUsers,
            Icons.groups_outlined,
            caption: l10n.figNewInPeriod(a.people.newUsers),
          ),
          Figure(
            '${a.people.verifiedFarmers}',
            l10n.figVerifiedFarmers,
            Icons.agriculture_outlined,
            caption: l10n.figWaiting(a.people.farmersWaiting),
          ),
          Figure(
            '${a.people.spacesLive}',
            l10n.statSpacesLive,
            Icons.home_work_outlined,
            caption: l10n.figWaiting(a.people.spacesWaiting),
          ),
          Figure('${a.people.hosts}', l10n.figHosts, Icons.house_outlined),
          Figure(
            '${a.people.buyers}',
            l10n.figBuyers,
            Icons.shopping_basket_outlined,
            caption: l10n.figBuyersWithArea(a.people.buyersWithArea),
          ),
        ],
      ),
      SectionHeader(l10n.analyticsTrust),
      StatGrid(
        maxColumns: 3,
        children: [
          Figure(
            stars(a.ratings.spaceAverage),
            l10n.figSpaceStars,
            Icons.star_outline_rounded,
            caption: l10n.ratingCount(a.ratings.given),
          ),
          Figure(stars(a.ratings.farmerAverage), l10n.figFarmerStars, Icons.star_outline_rounded),
          Figure(
            '${a.reports.openNow}',
            l10n.figReportsOpen,
            Icons.report_outlined,
            warn: a.reports.openNow > 0,
            caption: l10n.figReportsDetail(a.reports.opened, a.reports.resolved),
          ),
        ],
      ),
      const SizedBox(height: 24),
    ];
  }
}

/// One figure that may not be a whole number ("67%", "★ 4.2", "₹1,200"), with a label and an optional line below.
class Figure extends StatelessWidget {
  const Figure(this.value, this.label, this.icon, {super.key, this.caption, this.warn = false});
  final String value, label;
  final String? caption;
  final IconData icon;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = warn ? scheme.error : scheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: accent, height: 1.1),
                    ),
                  ),
                ),
                Icon(icon, size: 22, color: accent),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.3)),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(caption!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Requests made and stalls held for each day, as pairs of bars on one scale; a tap or hover shows the numbers.
class DailyBars extends StatelessWidget {
  const DailyBars(this.days, {super.key});
  final List<DayCount> days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final top = days.fold(0, (m, d) => math.max(m, math.max(d.requests, d.held)));
    if (top == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(l10n.analyticsNoActivity, textAlign: TextAlign.center),
      );
    }
    const height = 140.0;
    final requestColor = scheme.primary.withValues(alpha: .35);
    final heldColor = scheme.primary;
    Widget legend(Color c, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(spacing: 16, children: [legend(requestColor, l10n.figRequests), legend(heldColor, l10n.figHeld)]),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$top', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: height,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final d in days)
                      Expanded(
                        child: Tooltip(
                          message:
                              '${DateFormat.MMMEd(locale).format(d.date)}\n'
                              '${l10n.figRequests}: ${d.requests} · ${l10n.figHeld}: ${d.held}',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: days.length > 31 ? 0.5 : 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _bar(height * d.requests / top, requestColor),
                                _bar(height * d.held / top, heldColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat.MMMd(locale).format(days.first.date), style: const TextStyle(fontSize: 12)),
            Text(DateFormat.MMMd(locale).format(days.last.date), style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _bar(double h, Color c) => Expanded(
    child: Container(
      height: math.max(h, h > 0 ? 2 : 0),
      decoration: BoxDecoration(
        color: c,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      ),
    ),
  );
}

/// A ranked list with a bar for each row's share of the first.
class TopList extends StatelessWidget {
  const TopList({super.key, required this.title, required this.items});
  final String title;
  final List<(String, int)> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final top = items.isEmpty ? 1 : items.first.$2;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            if (items.isEmpty) Text(l10n.analyticsNoActivity, style: TextStyle(color: scheme.onSurfaceVariant)),
            for (final (name, count) in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
                        Text(l10n.stallCount(count), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: count / top, minHeight: 6),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
