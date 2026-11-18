import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/rating_api.dart';
import '../../core/api/trip_models.dart';
import '../../core/widgets/feedback.dart';
import '../../l10n/app_localizations.dart';

/// "★ 4.3 · 12 ratings", or "New, no ratings yet".
class StarsLabel extends StatelessWidget {
  const StarsLabel(this.stars, {super.key, this.dense = false});
  final Stars stars;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final size = dense ? 13.0 : 15.0;
    if (!stars.any) {
      return Text(
        l10n.notRatedYet,
        style: TextStyle(fontSize: size, color: scheme.onSurfaceVariant),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 3, color: Colors.amber.shade700),
        const SizedBox(width: 2),
        Text(
          stars.average!.toStringAsFixed(1),
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w700),
        ),
        Text(
          ' · ${l10n.ratingCount(stars.count)}',
          style: TextStyle(fontSize: size, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// On a host's booking card: the farmer's stars from other hosts, stalls they came to, and recent no-shows (in red,
/// so a host deciding on a request sees them).
class FarmerRecordLine extends StatelessWidget {
  const FarmerRecordLine(this.booking, {super.key});
  final HostBooking booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final b = booking;
    return Padding(
      padding: const EdgeInsets.only(left: 30, bottom: 6),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StarsLabel(b.farmerStars, dense: true),
          if (b.farmerStalls > 0)
            Text(l10n.stallsDone(b.farmerStalls), style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          if (b.farmerNoShows > 0)
            Text(
              l10n.recentNoShows(b.farmerNoShows),
              style: TextStyle(fontSize: 13, color: scheme.error, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

/// "You rated ★★★★☆".
class YouRated extends StatelessWidget {
  const YouRated(this.stars, {super.key});
  final int stars;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        AppLocalizations.of(context).youRated,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(width: 6),
      for (var i = 1; i <= 5; i++)
        Icon(i <= stars ? Icons.star_rounded : Icons.star_outline_rounded, size: 18, color: Colors.amber.shade700),
    ],
  );
}

/// Asks for 1–5 stars and an optional comment, then sends them. True when the rating was saved.
Future<bool> showRateSheet(BuildContext context, {required String bookingId, required String title}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
          child: RateForm(bookingId: bookingId, title: title),
        ),
      ),
    ) ??
    false;

class RateForm extends ConsumerStatefulWidget {
  const RateForm({super.key, required this.bookingId, required this.title});
  final String bookingId, title;

  @override
  ConsumerState<RateForm> createState() => _RateFormState();
}

class _RateFormState extends ConsumerState<RateForm> {
  final _comment = TextEditingController();
  int _stars = 0;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final comment = _comment.text.trim();
      await ref.read(ratingApiProvider).rate(widget.bookingId, _stars, comment.isEmpty ? null : comment);
      if (!mounted) return;
      showSuccess(context, l10n.ratingThanks);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  key: ValueKey('star$i'),
                  iconSize: 40,
                  tooltip: l10n.starsTooltip(i),
                  onPressed: _busy ? null : () => setState(() => _stars = i),
                  icon: Icon(
                    i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber.shade700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLength: 300,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(labelText: l10n.ratingCommentHint, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _stars == 0 || _busy ? null : _send,
            child: Text(l10n.sendRating),
          ),
        ],
      ),
    );
  }
}

/// The signed-in user's record on the profile screen: stars from the other side, and a farmer's no-shows.
class MyRecordCard extends ConsumerWidget {
  const MyRecordCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final record = ref.watch(myRecordProvider).value;
    if (record == null || (record.asFarmer == null && record.asHost == null)) return const SizedBox.shrink();
    final farmer = record.asFarmer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.yourRecord, style: Theme.of(context).textTheme.titleMedium),
            if (farmer != null) ...[
              const SizedBox(height: 12),
              Text(l10n.asFarmerLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              StarsLabel(farmer.stars),
              const SizedBox(height: 4),
              Text(l10n.stallsDone(farmer.completedStalls)),
              Text(
                l10n.noShowsOfLimit(farmer.recentNoShows, farmer.noShowLimit, farmer.noShowWindowDays),
                style: TextStyle(
                  color: farmer.recentNoShows > 0 ? scheme.error : null,
                  fontWeight: farmer.recentNoShows > 0 ? FontWeight.w600 : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.noShowRule(farmer.noShowLimit, farmer.noShowWindowDays),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
            if (record.asHost case final host?) ...[
              const SizedBox(height: 12),
              Text(l10n.asHostLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              StarsLabel(host),
            ],
          ],
        ),
      ),
    );
  }
}
