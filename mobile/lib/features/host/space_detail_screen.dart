import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/models.dart';
import '../../core/widgets/document_tile.dart';
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

  Future<void> _deleteFile(Space s, SpaceFile f) async {
    final l10n = AppLocalizations.of(context);
    final withdrawn = await ref.read(hostApiProvider).deletePhoto(s.id, f.id);
    ref.invalidate(_spaceProvider(widget.id));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(withdrawn ? l10n.spaceWithdrawnToast : l10n.photoDeletedToast)));
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
                title: '${l10n.spacePhotos} · ${s.photos.length}',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _TileGrid(children: [
                    for (final (i, p) in s.photos.indexed)
                      DocumentTile(
                        label: l10n.photoNumber(i + 1),
                        icon: Icons.image_outlined,
                        filePath: spaceFilePath(s.id, p),
                        fileName: 'space-photo-${i + 1}',
                        canChange: s.canChangeFiles,
                        deleteWarning: s.status == 'PendingReview' ? l10n.spaceWithdrawWarning : null,
                        onUpload: (photo) async {
                          await api.replacePhoto(s.id, p.id, photo);
                          ref.invalidate(_spaceProvider(widget.id));
                        },
                        onDelete: () => _deleteFile(s, p),
                      ),
                  ]),
                  if (s.canChangeFiles && s.photos.length < 8) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(l10n.addMorePhotos),
                      onPressed: _busy
                          ? null
                          : () async {
                              if (await pickPhoto() case final p?) await _do(() => api.addPhoto(s.id, p));
                            },
                    ),
                  ],
                ]),
              ),
              FormSection(
                title: l10n.proofOfRight,
                subtitle: l10n.proofHint,
                child: _TileGrid(children: [
                  DocumentTile(
                    label: l10n.proofOfRight,
                    filePath: s.proof == null ? null : spaceFilePath(s.id, s.proof!),
                    fileName: 'space-proof',
                    canChange: s.canChangeFiles,
                    deleteWarning: s.status == 'PendingReview' ? l10n.spaceWithdrawWarning : null,
                    // Setting the proof again replaces the old one.
                    onUpload: (photo) async {
                      await api.addPhoto(s.id, photo, isProof: true);
                      ref.invalidate(_spaceProvider(widget.id));
                    },
                    onDelete: s.proof == null ? null : () => _deleteFile(s, s.proof!),
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

/// Document tiles in as many ~220 px columns as fit (one on narrow phones, two at least from 460 px).
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        const gap = 12.0;
        final cols = ((c.maxWidth + gap) / (220 + gap)).floor().clamp(1, 4);
        final width = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final child in children) SizedBox(width: width, child: child),
        ]);
      });
}
