import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';

/// Opens the camera on phones (spec: documents by camera) or a file picker in a browser.
/// Photos are resized and compressed before upload (< ~300 KB target, FR-5.7).
Future<XFile?> pickPhoto({bool selfie = false}) => ImagePicker().pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 70,
    );

/// One required photo: label, hint, preview, and a take/retake button that uploads at once.
class PhotoTile extends StatefulWidget {
  const PhotoTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onPicked,
    this.hint,
    this.alreadyUploaded = false,
    this.selfie = false,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final IconData icon;
  final bool alreadyUploaded, selfie, enabled;

  /// Uploads the photo; throw to show an error and keep the tile empty.
  final Future<void> Function(XFile photo) onPicked;

  @override
  State<PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<PhotoTile> {
  Uint8List? _preview;
  bool _busy = false;
  late bool _done = widget.alreadyUploaded;

  Future<void> _pick() async {
    final photo = await pickPhoto(selfie: widget.selfie);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    setState(() {
      _busy = true;
      _preview = bytes;
    });
    try {
      await widget.onPicked(photo);
      if (mounted) setState(() => _done = true);
    } catch (_) {
      if (mounted) setState(() => _preview = null);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _done ? scheme.primary : scheme.outlineVariant, width: _done ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: _preview != null
              ? Image.memory(_preview!, fit: BoxFit.cover)
              : ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(_done ? Icons.check_circle : widget.icon, size: 48,
                      color: _done ? scheme.primary : scheme.onSurfaceVariant),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (widget.hint != null) Text(widget.hint!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            if (_busy)
              Row(children: [
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Text(l10n.uploading),
              ])
            else
              OutlinedButton.icon(
                onPressed: widget.enabled ? _pick : null,
                icon: Icon(_done ? Icons.refresh : Icons.photo_camera),
                label: Text(_done ? l10n.retakePhoto : l10n.takePhoto),
              ),
            if (_done && !_busy)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Icon(Icons.check, size: 18, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(l10n.uploaded, style: TextStyle(color: scheme.primary)),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}
