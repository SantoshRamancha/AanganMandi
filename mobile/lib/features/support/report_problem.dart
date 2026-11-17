import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/support_api.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';

/// The words for a report category.
String reportCategoryLabel(AppLocalizations l10n, String category) => switch (category) {
  'NoShow' => l10n.reportCatNoShow,
  'SpaceProblem' => l10n.reportCatSpaceProblem,
  'PaymentDispute' => l10n.reportCatPaymentDispute,
  'Behaviour' => l10n.reportCatBehaviour,
  'AppProblem' => l10n.reportCatAppProblem,
  _ => l10n.reportCatOther,
};

/// "Report a problem": pick what it is about, describe it, send. [bookingId] ties it to a booking.
Future<void> showReportProblemSheet(BuildContext context, {String? bookingId}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheet) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
    child: SafeArea(child: ReportProblemForm(bookingId: bookingId)),
  ),
);

class ReportProblemForm extends ConsumerStatefulWidget {
  const ReportProblemForm({super.key, this.bookingId});
  final String? bookingId;

  @override
  ConsumerState<ReportProblemForm> createState() => _ReportProblemFormState();
}

class _ReportProblemFormState extends ConsumerState<ReportProblemForm> {
  static const _minLength = 10, _maxLength = 1000;
  final _message = TextEditingController();
  String? _category;
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool get _ready => _category != null && _message.text.trim().length >= _minLength;

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(reportsApiProvider)
          .report(category: _category!, message: _message.text.trim(), bookingId: widget.bookingId);
      ref.invalidate(myReportsProvider);
      if (mounted) showSuccess(context, l10n.reportSentToast);
      navigator.pop();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.reportProblemTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in reportCategories)
                ChoiceChip(
                  label: Text(reportCategoryLabel(l10n, c)),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _message,
            minLines: 3,
            maxLines: 6,
            maxLength: _maxLength,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.reportDescribe,
              helperText: l10n.reportDescribeHint,
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.send),
            label: Text(l10n.reportSend),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _ready && !_busy ? _send : null,
          ),
        ],
      ),
    );
  }
}

/// The user's own reports and the team's answers (My profile → My reports).
class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(myReportsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myReports)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.report_outlined),
        label: Text(l10n.reportProblem),
        onPressed: () => showReportProblemSheet(context),
      ),
      body: reports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e, l10n.couldNotLoad))),
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(myReportsProvider.future),
          child: ListView(
            padding: EdgeInsets.all(Breakpoints.gutter(context)),
            children: [
              MaxWidth(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(l10n.myReportsEmpty, textAlign: TextAlign.center),
                      ),
                    for (final r in list) ReportCard(report: r),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One report: category, status, when, the booking it is about, what was written, and the team's answer.
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report, this.footer});
  final ProblemReport report;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final r = report;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reportCategoryLabel(l10n, r.category),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  label: Text(r.isOpen ? l10n.reportOpen : l10n.reportResolved),
                  backgroundColor: r.isOpen ? scheme.secondaryContainer : scheme.primaryContainer,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Text(DateFormat.yMMMd().add_jm().format(r.createdAt), style: TextStyle(color: scheme.onSurfaceVariant)),
            if (r.spaceTitle != null && r.bookingDate != null)
              Text(
                l10n.reportAbout(r.spaceTitle!, DateFormat.yMMMd().format(r.bookingDate!)),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            const SizedBox(height: 8),
            Text(r.message, style: const TextStyle(height: 1.4)),
            if (r.resolution != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Text(l10n.reportAnswer(r.resolution!), style: TextStyle(color: scheme.onPrimaryContainer)),
              ),
            ],
            ?footer,
          ],
        ),
      ),
    );
  }
}
