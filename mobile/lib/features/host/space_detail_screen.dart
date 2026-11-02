import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/models.dart';
import '../../core/widgets/photo_tile.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import 'host_home.dart';
import 'space_form_screen.dart';

final _spaceProvider = FutureProvider.autoDispose.family<Space, String>((ref, id) => ref.watch(hostApiProvider).get(id));

/// One space: status, rejection reason, photos; finish and submit a draft or fix a rejected one.
class SpaceDetailScreen extends ConsumerStatefulWidget {
  const SpaceDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends ConsumerState<SpaceDetailScreen> {
  bool _busy = false;

  Future<void> _do(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(_spaceProvider(widget.id));
      if (mounted && success != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(apiErrorMessage(e, AppLocalizations.of(context).errorGeneric))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = ref.watch(_spaceProvider(widget.id));
    final api = ref.read(hostApiProvider);
    final gutter = Breakpoints.gutter(context);

    return Scaffold(
      appBar: AppBar(title: Text(space.value?.title ?? '')),
      body: space.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e, l10n.errorGeneric))),
        data: (s) => ListView(padding: EdgeInsets.all(gutter), children: [
          MaxWidth(
            maxWidth: 900,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [StatusChip(status: s.status)]),
              if (s.status == 'Rejected' && s.rejectionReason != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  margin: const EdgeInsets.only(top: 12),
                  child: Padding(padding: const EdgeInsets.all(16), child: Text(l10n.rejectedReason(s.rejectionReason!))),
                ),
              const SizedBox(height: 16),
              FormSection(
                title: l10n.spaceDetails,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _row(Icons.place, '${s.address}, ${s.locality}'),
                  _row(Icons.square_foot, '${s.areaSqFt} sq ft'),
                  _row(Icons.event, s.availableDays.map((d) => weekdayLabel(context, d)).join(', ')),
                  _row(Icons.schedule, '${s.openFrom.substring(0, 5)} – ${s.openTo.substring(0, 5)}'),
                  _row(Icons.currency_rupee, s.isFree ? l10n.free : l10n.perSlot(s.fee.toStringAsFixed(0))),
                ]),
              ),
              FormSection(
                title: '${l10n.spacePhotos} · ${s.photoUrls.length}',
                child: Wrap(spacing: 12, runSpacing: 12, children: [
                  for (final url in s.photoUrls)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network('$apiOrigin$url', width: 160, height: 120, fit: BoxFit.cover),
                    ),
                  if (s.canSubmit && s.photoUrls.length < 8)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(l10n.addMorePhotos),
                      onPressed: _busy
                          ? null
                          : () async {
                              if (await pickPhoto() case final p?) await _do(() => api.addPhoto(s.id, p));
                            },
                    ),
                ]),
              ),
              FormSection(
                title: l10n.proofOfRight,
                subtitle: l10n.proofHint,
                child: Row(children: [
                  Icon(s.hasProof ? Icons.check_circle : Icons.cancel,
                      color: s.hasProof ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.hasProof ? l10n.uploaded : '—')),
                  if (s.canSubmit)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              if (await pickPhoto() case final p?) await _do(() => api.addPhoto(s.id, p, isProof: true));
                            },
                      child: Text(s.hasProof ? l10n.retakePhoto : l10n.takePhoto),
                    ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: switch (space.value) {
        final s? when s.canSubmit => Material(
            elevation: 4,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 12),
                child: MaxWidth(
                  maxWidth: 900,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text(l10n.finishAndSubmit),
                      onPressed: _busy ? null : () => _do(() => api.submit(s.id), success: l10n.spaceSubmitted),
                    ),
                  ),
                ),
              ),
            ),
          ),
        _ => null,
      },
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ]),
      );
}
