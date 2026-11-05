import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/ops_api.dart';
import '../../core/api/trip_api.dart';
import '../../core/router/app_router.dart';
import '../../core/storage/prefs.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../farmer/farmer_home.dart';
import '../host/host_home.dart';
import '../onboarding/language_screen.dart';
import '../ops/ops_home.dart';

/// Role-based home with a shared app bar (refresh, language switch, profile).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Statuses change on the ops side (verified, space approved): re-check when the app comes back.
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  void _refresh() {
    ref.invalidate(farmerProvider);
    ref.invalidate(mySpacesProvider);
    ref.invalidate(tripsProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(hostBookingsProvider);
    refreshOps(ref);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = Prefs.role;
    final title = switch (role) {
      'Farmer' => l10n.farmerHome,
      'Host' => l10n.hostHome,
      'Admin' || 'Verifier' => l10n.opsHome,
      _ => l10n.buyerHome,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: l10n.refresh, onPressed: _refresh),
          const LanguageMenuButton(),
          // Profile holds the user's details, theme, language and log out.
          const _ProfileButton(),
          SizedBox(width: Breakpoints.gutter(context) - 8),
        ],
      ),
      body: switch (role) {
        'Farmer' => const FarmerHome(),
        'Host' => const HostHome(),
        'Admin' || 'Verifier' => const OpsHome(),
        _ => const _BuyerHome(),
      },
    );
  }
}

class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.translate),
      tooltip: AppLocalizations.of(context).language,
      onSelected: (code) {
        ref.read(localeProvider.notifier).set(code);
        // Alerts and SMS follow the saved language; failure here is not worth interrupting the user.
        ref.read(authApiProvider).setLanguage(code).ignore();
      },
      itemBuilder: (_) => [
        for (final e in LanguageScreen.languages.entries) PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
    );
  }
}

/// Asks first, then logs out and returns to the login screen.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      icon: const Icon(Icons.logout),
      title: Text(l10n.logoutQ),
      content: Text(l10n.logoutBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l10n.cancel)),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialog).colorScheme.error,
            foregroundColor: Theme.of(dialog).colorScheme.onError,
          ),
          icon: const Icon(Icons.logout),
          label: Text(l10n.logout),
          onPressed: () => Navigator.pop(dialog, true),
        ),
      ],
    ),
  );
  if (ok != true) return;
  await Session.clear();
  ref.read(routerProvider).go('/login');
}

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => FilledButton.tonalIcon(
        icon: const Icon(Icons.logout),
        label: Text(AppLocalizations.of(context).logout),
        onPressed: () => confirmLogout(context, ref),
      );
}

/// The signed-in person's initials in the app bar; opens My profile.
class _ProfileButton extends ConsumerWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
        tooltip: AppLocalizations.of(context).profileTitle,
        icon: InitialsAvatar(name: ref.watch(profileProvider).value?.name, radius: 17),
        onPressed: () => context.push('/profile'),
      );
}

class _BuyerHome extends StatelessWidget {
  const _BuyerHome();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(icon: Icons.shopping_basket, title: l10n.comingSoon, body: l10n.buyerComingSoon);
  }
}

/// Centered icon, title and message for empty or not-yet-built screens.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action});
  final IconData icon;
  final String title, body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Breakpoints.gutter(context)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: scheme.primaryContainer,
              child: Icon(icon, size: 48, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16)),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ]),
        ),
      ),
    );
  }
}
