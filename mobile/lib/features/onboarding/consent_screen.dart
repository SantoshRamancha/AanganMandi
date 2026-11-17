import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/storage/prefs.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';

/// Opens the terms (`terms`) or privacy policy (`privacy`) page in the browser, in the app language.
Future<void> openLegalPage(String page, String lang) =>
    launchUrl(Uri.parse('$apiOrigin/legal/$page?lang=$lang'), mode: LaunchMode.externalApplication);

/// Shown once after login (and again when the terms change): what Aangan Mandi uses and why, links to the terms
/// and the privacy policy, and "I agree". Without agreeing the user can only log out.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _agreed = false;
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      // The server says which version is current; agreeing records exactly that one.
      final profile = await ref.read(profileProvider.future);
      await ref.read(authApiProvider).acceptTerms(profile.termsVersion);
      ref.invalidate(profileProvider);
      if (mounted) context.go(Prefs.role != null ? '/home' : '/role');
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logOut() async {
    await Session.clear();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = ref.watch(localeProvider);
    Widget point(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4))),
        ],
      ),
    );
    return PopScope(
      canPop: false, // agreeing or logging out are the only ways on
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.consentTitle), automaticallyImplyLeading: false),
        body: ListView(
          padding: EdgeInsets.all(Breakpoints.gutter(context)),
          children: [
            MaxWidth(
              maxWidth: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.consentIntro, style: const TextStyle(fontSize: 16, height: 1.4)),
                  const SizedBox(height: 16),
                  point(Icons.phone_android, l10n.consentData1),
                  point(Icons.agriculture_outlined, l10n.consentData2),
                  point(Icons.home_work_outlined, l10n.consentData3),
                  point(Icons.my_location, l10n.consentData4),
                  point(Icons.verified_user_outlined, l10n.consentPromise),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.description_outlined),
                        label: Text(l10n.readTerms),
                        onPressed: () => openLegalPage('terms', lang),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.privacy_tip_outlined),
                        label: Text(l10n.readPrivacy),
                        onPressed: () => openLegalPage('privacy', lang),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _agreed,
                    title: Text(l10n.consentAgree),
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: _agreed && !_busy ? _continue : null,
                    child: Text(l10n.consentContinue),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _busy ? null : _logOut, child: Text(l10n.consentDecline)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
