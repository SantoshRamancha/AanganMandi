import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../api/api_client.dart';
import 'photo_tile.dart';

/// A private file and its type, fetched with the login token (a web <img> cannot send the token itself).
typedef FileBytes = ({Uint8List bytes, String contentType});

/// Keyed by the API path, e.g. "/farmers/me/evidence/photo?v=…". Change the "v" to refetch a replaced file.
final authFileProvider = FutureProvider.autoDispose.family<FileBytes, String>((ref, path) async {
  final res = await ref.watch(dioProvider).get<List<int>>(path, options: Options(responseType: ResponseType.bytes));
  return (bytes: Uint8List.fromList(res.data!), contentType: res.headers.value('content-type') ?? 'image/jpeg');
});

/// Saves the file: a browser download on the web, the system "save to…" dialog on phones. False if cancelled.
Future<bool> saveFileBytes(FileBytes file, String name) async {
  final (mime, ext) = switch (file.contentType.split(';').first.trim()) {
    'image/png' => (MimeType.png, 'png'),
    'image/webp' => (MimeType.webp, 'webp'),
    _ => (MimeType.jpeg, 'jpg'),
  };
  if (kIsWeb) {
    await FileSaver.instance.saveFile(name: name, bytes: file.bytes, fileExtension: ext, mimeType: mime);
    return true;
  }
  return await FileSaver.instance.saveAs(name: name, bytes: file.bytes, fileExtension: ext, mimeType: mime) != null;
}

/// Downloads [path] and reports the result in a snack bar.
Future<void> downloadFile(BuildContext context, WidgetRef ref, String path, String name) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final file = await ref.read(authFileProvider(path).future);
    if (await saveFileBytes(file, name)) messenger.showSnackBar(SnackBar(content: Text(l10n.downloadSaved)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.downloadFailed)));
  }
}

/// Full-screen, zoomable view of [path] with download and close buttons.
Future<void> showFilePreview(BuildContext context, String path, String name) => showDialog<void>(
      context: context,
      builder: (dialog) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Consumer(builder: (context, ref, _) {
          final l10n = AppLocalizations.of(context);
          return Stack(children: [
            Positioned.fill(
              child: ref.watch(authFileProvider(path)).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(child: Icon(Icons.broken_image_outlined, size: 56, color: Colors.white70)),
                    data: (f) => InteractiveViewer(maxScale: 6, child: Center(child: Image.memory(f.bytes))),
                  ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: Row(children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.download),
                    tooltip: l10n.download,
                    onPressed: () => downloadFile(context, ref, path, name),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.close,
                    onPressed: () => Navigator.pop(dialog),
                  ),
                ]),
              ),
            ),
          ]);
        }),
      ),
    );

/// Asks before deleting something; true only when the user taps the red Delete button.
Future<bool> confirmDelete(BuildContext context, {required String title, required String body}) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      icon: const Icon(Icons.delete_outline),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialog).colorScheme.error,
            foregroundColor: Theme.of(dialog).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return ok == true;
}

/// A document (photo of a record, proof, space photo) with preview and download, plus reupload and
/// delete while [canChange] (until it is approved). Without a file it offers the first upload.
class DocumentTile extends ConsumerStatefulWidget {
  const DocumentTile({
    super.key,
    required this.label,
    required this.filePath,
    required this.fileName,
    required this.canChange,
    required this.onUpload,
    this.onDelete,
    this.hint,
    this.deleteWarning,
    this.icon = Icons.description_outlined,
  });

  final String label;
  final String? hint;
  final IconData icon;

  /// API path of the stored file, or null when nothing is uploaded yet.
  final String? filePath;

  /// Download name, without extension.
  final String fileName;
  final bool canChange;

  /// Uploads a new or replacement file; throw to show the error.
  final Future<void> Function(XFile photo) onUpload;

  /// Deletes the file; null hides Delete (e.g. the only copy of something required).
  final Future<void> Function()? onDelete;

  /// Extra line in the delete confirmation, e.g. that a waiting submission is withdrawn.
  final String? deleteWarning;

  @override
  ConsumerState<DocumentTile> createState() => _DocumentTileState();
}

class _DocumentTileState extends ConsumerState<DocumentTile> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e, AppLocalizations.of(context).errorGeneric))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final photo = await pickPhoto();
    if (photo != null) await _run(() => widget.onUpload(photo));
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmDelete(context,
        title: l10n.deleteDocumentQ, body: [l10n.deleteDocumentBody, ?widget.deleteWarning].join('\n\n'));
    if (ok) await _run(widget.onDelete!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final path = widget.filePath;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: path != null ? scheme.primary.withValues(alpha: .6) : scheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : path == null
                    ? Icon(widget.icon, size: 48, color: scheme.onSurfaceVariant)
                    : ref.watch(authFileProvider(path)).when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, _) => Icon(Icons.broken_image_outlined, size: 40, color: scheme.onSurfaceVariant),
                          data: (f) => InkWell(
                            onTap: () => showFilePreview(context, path, widget.fileName),
                            child: Image.memory(f.bytes, fit: BoxFit.cover),
                          ),
                        ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (widget.hint != null) Text(widget.hint!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            if (path == null)
              widget.canChange
                  ? OutlinedButton.icon(
                      onPressed: _busy ? null : _upload,
                      icon: const Icon(Icons.upload_outlined),
                      label: Text(l10n.uploadPhoto),
                    )
                  : Text('—', style: TextStyle(color: scheme.onSurfaceVariant))
            else ...[
              Wrap(spacing: 4, runSpacing: 4, children: [
                _Action(Icons.visibility_outlined, l10n.preview,
                    _busy ? null : () => showFilePreview(context, path, widget.fileName)),
                _Action(Icons.download_outlined, l10n.download,
                    _busy ? null : () => downloadFile(context, ref, path, widget.fileName)),
                if (widget.canChange) _Action(Icons.upload_outlined, l10n.reupload, _busy ? null : _upload),
                if (widget.canChange && widget.onDelete != null)
                  _Action(Icons.delete_outline, l10n.delete, _busy ? null : _delete, color: scheme.error),
              ]),
              if (!widget.canChange)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    Icon(Icons.lock_outline, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text(l10n.documentLocked, style: Theme.of(context).textTheme.bodySmall)),
                  ]),
                ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onPressed, {this.color});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(icon, size: 20),
        label: Text(label),
        onPressed: onPressed,
      );
}
