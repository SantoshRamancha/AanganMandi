import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/document_tile.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Date and time in the app language (Intl.defaultLocale follows it).
String formatWhen(DateTime? t) => t == null ? '–' : DateFormat('dd MMM yyyy, HH:mm').format(t);

/// Page heading with an optional line of explanation under it.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35)),
          ],
        ]),
      );
}

/// Amber notice card: something staff should act on.
class WarningCard extends StatelessWidget {
  const WarningCard({super.key, required this.title, required this.body});
  final String title, body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.warningContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        iconColor: scheme.onWarningContainer,
        textColor: scheme.onWarningContainer,
        leading: const Icon(Icons.warning_amber_rounded),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(body),
      ),
    );
  }
}

/// Titled card holding label/value rows.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...children,
          ]),
        ),
      );
}

/// One label/value row; [warn] paints the value red (something the reviewer must notice).
class Fact extends StatelessWidget {
  const Fact(this.label, this.value, {super.key, this.warn = false});
  final String label, value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant))),
        Expanded(
          child: Text(value,
              style: TextStyle(color: warn ? scheme.error : null, fontWeight: warn ? FontWeight.w600 : null)),
        ),
      ]),
    );
  }
}

/// Coloured status pill used in lists and review headers.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, this.label, {super.key});
  final String status, label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      'Pending' || 'PendingReview' => (scheme.warningContainer, scheme.onWarningContainer),
      'Verified' || 'Live' => (scheme.primaryContainer, scheme.onPrimaryContainer),
      'Rejected' => (scheme.errorContainer, scheme.onErrorContainer),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

/// Row of choice chips that filters a list by status.
class StatusFilter extends StatelessWidget {
  const StatusFilter({super.key, required this.options, required this.selected, required this.onChanged});
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (value, label) in options)
          ChoiceChip(label: Text(label), selected: value == selected, onSelected: (_) => onChanged(value)),
      ]);
}

/// A private file loaded with the staff login (works on web and phones), with preview and download.
/// Staff never change a document they review: only the farmer or host can replace it.
class AuthImage extends ConsumerWidget {
  const AuthImage(this.path, {super.key, this.height = 220, this.caption});

  /// Storage path, e.g. "kyc/…/x.jpg".
  final String path;
  final double height;
  final String? caption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final api = '/ops/files/$path';
    final name = path.split('/').last.split('.').first;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: ref.watch(authFileProvider(api)).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Icon(Icons.broken_image_outlined, size: 40, color: scheme.onSurfaceVariant),
                  data: (f) => InkWell(
                    onTap: () => showFilePreview(context, api, name),
                    child: Image.memory(f.bytes, fit: BoxFit.cover),
                  ),
                ),
          ),
        ),
      ),
      Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        if (caption != null) Text(caption!, style: Theme.of(context).textTheme.bodySmall),
        TextButton.icon(
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          icon: const Icon(Icons.visibility_outlined, size: 20),
          label: Text(l10n.preview),
          onPressed: () => showFilePreview(context, api, name),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          icon: const Icon(Icons.download_outlined, size: 20),
          label: Text(l10n.download),
          onPressed: () => downloadFile(context, ref, api, name),
        ),
      ]),
    ]);
  }
}

/// Approve / reject with a reason (required to reject, shown to the farmer or host), plus quick reasons.
class DecisionPanel extends StatefulWidget {
  const DecisionPanel({
    super.key,
    required this.guidance,
    required this.approveLabel,
    required this.quickReasons,
    required this.onDecide,
  });

  final String guidance, approveLabel;
  final List<String> quickReasons;

  /// Saves the decision; throw to show the error and stay on the page.
  final Future<void> Function(bool approve, String? reason) onDecide;

  @override
  State<DecisionPanel> createState() => _DecisionPanelState();
}

class _DecisionPanelState extends State<DecisionPanel> {
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reason.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _decide(bool approve) async {
    setState(() => _busy = true);
    try {
      await widget.onDecide(approve, approve ? null : _reason.text.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e, AppLocalizations.of(context).couldNotSave))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InfoCard(title: l10n.decision, children: [
      Text(widget.guidance),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final r in widget.quickReasons) ActionChip(label: Text(r), onPressed: () => _reason.text = r),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: _reason,
        maxLines: 2,
        maxLength: 500,
        decoration: InputDecoration(labelText: l10n.reasonLabel),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 12, children: [
        FilledButton.icon(
          icon: const Icon(Icons.check),
          label: Text(widget.approveLabel),
          onPressed: _busy ? null : () => _decide(true),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.close),
          label: Text(l10n.reject),
          style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: _busy || _reason.text.trim().isEmpty ? null : () => _decide(false),
        ),
      ]),
    ]);
  }
}
