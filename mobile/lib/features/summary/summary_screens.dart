import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/summary_api.dart';
import '../../core/crops.dart';
import '../../core/storage/prefs.dart';
import '../../core/widgets/dashboard.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../ops/analytics_page.dart' show Figure, TopList;

/// Rupees without paise when whole: ₹1,500 or ₹1,500.50.
String rupees(BuildContext context, double amount) {
  final locale = Localizations.localeOf(context).toString();
  final format = amount == amount.roundToDouble()
      ? NumberFormat.decimalPattern(locale)
      : NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2);
  return format.format(amount);
}

String _stars(double? v) => v == null ? '–' : '★ ${v.toStringAsFixed(1)}';

String _period(AppLocalizations l10n, int days) => days == 365 ? l10n.oneYear : l10n.lastDays(days);

/// A host's earnings for the last 30, 90 or 365 days: fees from stalls held, no-shows, stalls coming up, requests,
/// their rating, and the fees per space.
class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SummaryScaffold(
      title: l10n.myEarnings,
      subtitle: l10n.myEarningsSubtitle,
      days: _days,
      onDays: (d) => setState(() => _days = d),
      data: ref.watch(hostSummaryProvider(_days)),
      onRefresh: () => ref.refresh(hostSummaryProvider(_days).future),
      body: (s) => [
        StatGrid(
          maxColumns: 3,
          children: [
            Figure('₹${rupees(context, s.feesEarned)}', l10n.figFeesEarned, Icons.currency_rupee),
            Figure('${s.held}', l10n.figHeld, Icons.storefront_outlined),
            Figure('${s.noShows}', l10n.figNoShows, Icons.person_off_outlined, warn: s.noShows > 0),
            Figure(
              '${s.upcoming}',
              l10n.figComingUp,
              Icons.event_available_outlined,
              caption: s.feesExpected > 0 ? l10n.figExpected(rupees(context, s.feesExpected)) : null,
            ),
            Figure(
              '${s.requests}',
              l10n.figRequests,
              Icons.send_outlined,
              caption: l10n.figRequestsAnswered(s.accepted, s.declined),
            ),
            Figure(
              _stars(s.rating),
              l10n.figMyRating,
              Icons.star_outline_rounded,
              caption: l10n.ratingCount(s.ratingCount),
            ),
          ],
        ),
        if (s.spaces.isNotEmpty) ...[
          SectionHeader(l10n.bySpace),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final sp in s.spaces)
                  ListTile(
                    leading: const Icon(Icons.home_work_outlined),
                    title: Text(sp.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(l10n.stallCount(sp.held)),
                    trailing: Text(
                      '₹${rupees(context, sp.fees)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A farmer's stalls for the last 30, 90 or 365 days: selling days, stalls held, no-shows, fees paid, their rating,
/// and what they sold most and where.
class MyStallsScreen extends ConsumerStatefulWidget {
  const MyStallsScreen({super.key});

  @override
  ConsumerState<MyStallsScreen> createState() => _MyStallsScreenState();
}

class _MyStallsScreenState extends ConsumerState<MyStallsScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final crops = ref.watch(cropsProvider).value ?? const [];
    final lang = ref.watch(localeProvider);
    return _SummaryScaffold(
      title: l10n.myStalls,
      subtitle: l10n.myStallsSubtitle,
      days: _days,
      onDays: (d) => setState(() => _days = d),
      data: ref.watch(farmerSummaryProvider(_days)),
      onRefresh: () => ref.refresh(farmerSummaryProvider(_days).future),
      body: (s) => [
        StatGrid(
          maxColumns: 3,
          children: [
            Figure('${s.held}', l10n.figHeld, Icons.storefront_outlined),
            Figure('${s.trips}', l10n.figSellingDays, Icons.event_outlined),
            Figure('${s.noShows}', l10n.figNoShows, Icons.person_off_outlined, warn: s.noShows > 0),
            Figure('₹${rupees(context, s.feesPaid)}', l10n.figFeesPaid, Icons.currency_rupee),
            Figure('${s.upcoming}', l10n.figComingUp, Icons.event_available_outlined),
            Figure(
              _stars(s.rating),
              l10n.figMyRating,
              Icons.star_outline_rounded,
              caption: l10n.ratingCount(s.ratingCount),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final cropsCard = TopList(
              title: l10n.soldMost,
              items: [for (final t in s.crops) (cropName(t.key, crops, lang), t.stalls)],
            );
            final placesCard = TopList(title: l10n.soldWhere, items: [for (final t in s.places) (t.key, t.stalls)]);
            if (c.maxWidth < 640) return Column(children: [cropsCard, const SizedBox(height: 12), placesCard]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cropsCard),
                const SizedBox(width: 12),
                Expanded(child: placesCard),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The page both summaries share: title, period buttons, loading and error states, and a note at the end.
class _SummaryScaffold<T> extends StatelessWidget {
  const _SummaryScaffold({
    required this.title,
    required this.subtitle,
    required this.days,
    required this.onDays,
    required this.data,
    required this.onRefresh,
    required this.body,
  });
  final String title, subtitle;
  final int days;
  final ValueChanged<int> onDays;
  final AsyncValue<T> data;
  final Future<T> Function() onRefresh;
  final List<Widget> Function(T) body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () => onRefresh().then((_) {}, onError: (_) {}),
        child: ListView(
          padding: EdgeInsets.all(Breakpoints.gutter(context)),
          children: [
            MaxWidth(
              maxWidth: 960,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(subtitle, style: muted),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<int>(
                      segments: [
                        for (final d in summaryPeriods) ButtonSegment(value: d, label: Text(_period(l10n, d))),
                      ],
                      selected: {days},
                      onSelectionChanged: (v) => onDays(v.first),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            OutlinedButton(onPressed: onRefresh, child: Text(l10n.retry)),
                          ],
                        ),
                      ),
                    ],
                    data: (s) => [
                      ...body(s),
                      const SizedBox(height: 16),
                      Text(l10n.summaryNote, style: muted.copyWith(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// On the host home: this month's earnings in one line; opens [EarningsScreen].
class EarningsCard extends ConsumerWidget {
  const EarningsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(hostSummaryProvider(30)).value;
    return _SummaryCard(
      icon: Icons.currency_rupee,
      title: l10n.myEarnings,
      line: s == null ? null : l10n.earningsCardLine(s.held, rupees(context, s.feesEarned)),
      onTap: () => context.push('/host/earnings'),
    );
  }
}

/// On the farmer home: this month's stalls in one line; opens [MyStallsScreen].
class MyStallsCard extends ConsumerWidget {
  const MyStallsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(farmerSummaryProvider(30)).value;
    return _SummaryCard(
      icon: Icons.insights_outlined,
      title: l10n.myStalls,
      line: s == null ? null : l10n.stallsCardLine(s.held, rupees(context, s.feesPaid)),
      onTap: () => context.push('/farmer/stalls'),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.title, required this.line, required this.onTap});
  final IconData icon;
  final String title;
  final String? line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: line == null ? null : Text(line!),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
