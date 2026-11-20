import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/app_api.dart';
import '../../core/api/models.dart';
import '../../core/api/trip_api.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import 'space_form_screen.dart';

/// The days from today on that the host closed a space.
final blockedDatesProvider = FutureProvider.autoDispose.family<List<BlockedDate>, String>(
  (ref, spaceId) => ref.watch(hostApiProvider).blockedDates(spaceId),
);

/// How far ahead a day can be blocked (the same as how far ahead farmers plan; the server checks it too).
const maxBlockDaysAhead = 60;

/// On the space screen: the days the host closed the space (a family function, travel), with a button to block one
/// more and an ✕ to open a day again. Blocking declines that day's waiting requests; a day with a confirmed farmer
/// cannot be blocked until that booking is cancelled.
class BlockedDatesSection extends ConsumerStatefulWidget {
  const BlockedDatesSection({super.key, required this.space});
  final Space space;

  @override
  ConsumerState<BlockedDatesSection> createState() => _BlockedDatesSectionState();
}

class _BlockedDatesSectionState extends ConsumerState<BlockedDatesSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(blockedDatesProvider(widget.space.id));
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _block(List<BlockedDate> already) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = today.add(const Duration(days: maxBlockDaysAhead));
    final taken = {for (final b in already) DateUtils.dateOnly(b.date)};
    // Only days the space is normally open and not blocked yet.
    bool open(DateTime d) => widget.space.availableDays.contains(weekdays[d.weekday - 1]) && !taken.contains(d);
    var first = today;
    while (!open(first) && first.isBefore(last)) {
      first = first.add(const Duration(days: 1));
    }
    if (!open(first)) {
      await showError(context, l10n.noDaysToBlock);
      return;
    }
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: last,
      initialDate: first,
      selectableDayPredicate: open,
      helpText: l10n.blockDayTitle,
    );
    if (date == null || !mounted) return;
    final day = DateFormat.yMMMEd(Localizations.localeOf(context).toString()).format(date);
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(title: l10n.blockDayQ(day), body: l10n.blockDayBody, confirm: l10n.blockDay),
    );
    if (note == null || !mounted) return;
    final api = ref.read(hostApiProvider);
    await _run(() async {
      final declined = await api.blockDate(widget.space.id, date, note.isEmpty ? null : note);
      ref.invalidate(hostBookingsProvider);
      if (mounted) showSuccess(context, l10n.dayBlockedToast(declined));
    });
  }

  /// Blocks the open days from a first to a last day, then says which days stayed open for a confirmed farmer.
  Future<void> _blockRange() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: maxBlockDaysAhead)),
      helpText: l10n.blockRangeTitle,
    );
    if (range == null || !mounted) return;
    String fmt(DateTime d) => DateFormat.yMMMEd(locale).format(d);
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(
        title: l10n.blockRangeQ(fmt(range.start), fmt(range.end)),
        body: l10n.blockRangeBody,
        confirm: l10n.blockDays,
      ),
    );
    if (note == null || !mounted) return;
    final api = ref.read(hostApiProvider);
    await _run(() async {
      final r = await api.blockRange(widget.space.id, range.start, range.end, note.isEmpty ? null : note);
      ref.invalidate(hostBookingsProvider);
      if (!mounted) return;
      final declined = r.declinedRequests == 0 ? '' : ' · ${l10n.requestsDeclined(r.declinedRequests)}';
      showSuccess(context, '${l10n.daysBlockedToast(r.blocked.length)}$declined');
      if (r.booked.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.bookedDaysTitle),
            content: Text(l10n.bookedDaysBody(r.booked.map(DateFormat.MMMEd(locale).format).join(', '))),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok))],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final dates = ref.watch(blockedDatesProvider(widget.space.id));
    final list = dates.value ?? const <BlockedDate>[];
    return FormSection(
      title: l10n.blockedDays,
      subtitle: l10n.blockedDaysHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dates.isLoading && !dates.hasValue)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (dates.hasError)
            Text(l10n.couldNotLoad, style: TextStyle(color: scheme.error))
          else if (list.isEmpty)
            Text(l10n.noBlockedDays, style: TextStyle(color: scheme.onSurfaceVariant))
          else
            for (final b in list)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.event_busy, color: scheme.error),
                title: Text(
                  DateFormat.yMMMEd(locale).format(b.date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: b.note == null ? null : Text(b.note!),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.unblockDay,
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await ref.read(hostApiProvider).unblockDate(widget.space.id, b.date);
                          if (context.mounted) showSuccess(context, l10n.dayOpenedToast);
                        }),
                ),
              ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.event_busy),
                label: Text(l10n.blockDay),
                onPressed: _busy || !dates.hasValue ? null : () => _block(list),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(l10n.blockDays),
                onPressed: _busy || !dates.hasValue ? null : _blockRange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks for an optional note; returns it ('' for none), or null when cancelled. Owns its controller.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.title, required this.body, required this.confirm});
  final String title, body, confirm;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
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
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.body),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLength: 100,
            decoration: InputDecoration(labelText: l10n.blockNoteHint, border: const OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _note.text.trim()), child: Text(widget.confirm)),
      ],
    );
  }
}
