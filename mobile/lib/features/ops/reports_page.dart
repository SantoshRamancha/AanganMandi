import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/support_api.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../support/report_problem.dart';

/// The reporter's role in plain words.
String _roleWord(AppLocalizations l10n, String role) => switch (role) {
  'Farmer' => l10n.roleWordFarmer,
  'Host' => l10n.roleWordHost,
  'Buyer' => l10n.roleWordBuyer,
  'Verifier' => l10n.roleWordVerifier,
  _ => l10n.roleWordAdmin,
};

/// Admins: problem reports, open first (oldest on top, so nothing waits too long), then resolved. Resolving asks
/// for a note the reporter sees in the app and by email.
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.opsReportsOpen),
              Tab(text: l10n.opsReportsResolved),
            ],
          ),
          const Expanded(child: TabBarView(children: [_ReportList('Open'), _ReportList('Resolved')])),
        ],
      ),
    );
  }
}

class _ReportList extends ConsumerWidget {
  const _ReportList(this.status);
  final String status;

  Future<void> _resolve(BuildContext context, WidgetRef ref, ProblemReport r) async {
    final l10n = AppLocalizations.of(context);
    final note = await showDialog<String>(context: context, builder: (_) => const _ResolveDialog());
    if (note == null || !context.mounted) return;
    try {
      await ref.read(opsReportsApiProvider).resolve(r.id, note);
      ref.invalidate(opsReportsProvider);
      if (context.mounted) showSuccess(context, l10n.reportResolvedToast);
    } catch (e) {
      if (context.mounted) await showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(opsReportsProvider(status));
    return reports.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(apiErrorMessage(e, l10n.couldNotLoad))),
      data: (list) => RefreshIndicator(
        onRefresh: () => ref.refresh(opsReportsProvider(status).future),
        child: ListView(
          padding: EdgeInsets.all(Breakpoints.gutter(context)),
          children: [
            MaxWidth(
              maxWidth: 820,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text(l10n.opsNoReports)),
                    ),
                  for (final r in list)
                    ReportCard(
                      report: r,
                      footer: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${r.reporterName ?? l10n.noName} · ${r.reporterRoles.map((ro) => _roleWord(l10n, ro)).join(', ')}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (r.reporterPhone != null)
                              TextButton.icon(
                                icon: const Icon(Icons.call, size: 18),
                                label: Text(r.reporterPhone!),
                                onPressed: () => launchUrl(Uri.parse('tel:${r.reporterPhone}')),
                              ),
                            if (r.isOpen)
                              FilledButton.icon(
                                icon: const Icon(Icons.task_alt),
                                label: Text(l10n.resolveReport),
                                onPressed: () => _resolve(context, ref, r),
                              ),
                          ],
                        ),
                      ),
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

/// The note for the reporter. Owns its controller (disposed after the closing animation).
class _ResolveDialog extends StatefulWidget {
  const _ResolveDialog();

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.resolveReportQ),
      content: TextField(
        controller: _note,
        maxLength: 500,
        minLines: 2,
        maxLines: 4,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: l10n.resolveReportHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _note.text.trim().isEmpty ? null : () => Navigator.pop(context, _note.text.trim()),
          child: Text(l10n.resolveReport),
        ),
      ],
    );
  }
}
