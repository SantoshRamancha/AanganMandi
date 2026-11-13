import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/models.dart';
import '../../core/api/trip_api.dart';
import '../../core/api/trip_models.dart';
import '../../core/crops.dart';
import '../../core/storage/prefs.dart';
import '../../l10n/app_localizations.dart';
import '../trips/trip_widgets.dart';

/// Lets the host tell neighbours about a confirmed stall: a ready-made message with the public link
/// (no app or sign-up needed to open it), sent to a WhatsApp group or copied.
Future<void> showShareStallSheet(BuildContext context, HostBooking booking) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(child: ShareStallSheet(booking: booking)),
    );

/// The message in the host's language, with the crops and prices the farmer gave.
String stallMessage(AppLocalizations l10n, HostBooking b, List<Crop> crops, String lang, String url) {
  final produce = b.produce
      .map((p) => [cropName(p.cropCode, crops, lang), if (p.pricePerKg != null) '₹${p.pricePerKg!.toStringAsFixed(0)}/kg']
          .join(' '))
      .join(', ');
  return l10n.shareStallMessage(tripDate(b.date), '${b.from}–${b.to}', b.spaceTitle, produce, url);
}

class ShareStallSheet extends ConsumerStatefulWidget {
  const ShareStallSheet({super.key, required this.booking});
  final HostBooking booking;

  @override
  ConsumerState<ShareStallSheet> createState() => _ShareStallSheetState();
}

class _ShareStallSheetState extends ConsumerState<ShareStallSheet> {
  late final Future<String> _link = ref.read(hostBookingApiProvider).shareLink(widget.booking.id);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider);
    final crops = ref.watch(cropsProvider).value ?? const <Crop>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: FutureBuilder<String>(
        future: _link,
        builder: (context, snap) {
          if (snap.hasError) return Text(apiErrorMessage(snap.error!, l10n.errorGeneric));
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
          final message = stallMessage(l10n, widget.booking, crops, lang, snap.data!);
          final scheme = Theme.of(context).colorScheme;
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l10n.shareSheetTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.shareSheetHint, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
              child: SelectableText(message, style: const TextStyle(fontSize: 15, height: 1.4)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: Text(l10n.shareOnWhatsApp),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              // wa.me without a number opens WhatsApp's chat picker, where the host chooses the group.
              onPressed: () => launchUrl(Uri.https('wa.me', '/', {'text': message}), mode: LaunchMode.externalApplication),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: Text(l10n.copyMessage),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: message));
                messenger.showSnackBar(SnackBar(content: Text(l10n.messageCopied)));
              },
            ),
          ]);
        },
      ),
    );
  }
}
