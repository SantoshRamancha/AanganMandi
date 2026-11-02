import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/prefs.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';

/// First-launch language picker; English pre-selected (FR-5.1).
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  static const languages = {'en': 'English', 'te': 'తెలుగు', 'hi': 'हिन्दी'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.chooseLanguage, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          for (final e in languages.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: e.key == current ? scheme.primary : scheme.outlineVariant,
                    width: e.key == current ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  title: Text(e.value, style: const TextStyle(fontSize: 20)),
                  trailing: e.key == current ? Icon(Icons.check_circle, color: scheme.primary) : null,
                  onTap: () => ref.read(localeProvider.notifier).set(e.key),
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.continueButton),
            onPressed: () async {
              await ref.read(localeProvider.notifier).set(current);
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
