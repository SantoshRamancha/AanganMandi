import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_api.dart';
import '../../core/api/models.dart';
import '../../core/crops.dart';
import '../../core/districts.dart';
import '../../core/labels.dart';
import '../../core/storage/prefs.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';
import '../onboarding/language_screen.dart';

/// The signed-in user's details, plus app settings (theme, language) and log out. Same for every role.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(profileProvider.future),
        child: ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
          MaxWidth(
            maxWidth: 720,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              profile.when(
                loading: () => const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_off),
                    title: Text(apiErrorMessage(e, l10n.couldNotLoad)),
                    trailing: TextButton(onPressed: () => ref.invalidate(profileProvider), child: Text(l10n.retry)),
                  ),
                ),
                data: (p) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _Header(profile: p),
                  _AccountCard(profile: p),
                  if (p.roles.contains('Farmer')) const _FarmerCard(),
                  if (p.roles.contains('Host')) const _HostCard(),
                ]),
              ),
              const _AppearanceCard(),
              const _LanguageCard(),
              const SizedBox(height: 8),
              _LogoutCard(phone: profile.value?.phone),
              const SizedBox(height: 24),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final name = profile.name?.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(children: [
        InitialsAvatar(name: name, radius: 44),
        const SizedBox(height: 12),
        Text(name == null || name.isEmpty ? profile.phone : name,
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (final r in profile.roles)
            Chip(
              avatar: Icon(_roleIcon(r), size: 18, color: scheme.onSecondaryContainer),
              label: Text(l10n.roleName(r)),
              backgroundColor: scheme.secondaryContainer,
              labelStyle: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600),
              side: BorderSide.none,
            ),
        ]),
      ]),
    );
  }

  static IconData _roleIcon(String role) => switch (role) {
        'Farmer' => Icons.agriculture,
        'Host' => Icons.home_work,
        'Buyer' => Icons.shopping_basket,
        'Verifier' => Icons.fact_check,
        'Admin' => Icons.admin_panel_settings,
        _ => Icons.person,
      };
}

/// Icon, label and value in one row of a settings-style card.
class _Row extends StatelessWidget {
  const _Row(this.icon, this.label, this.value, {this.muted = false});
  final IconData icon;
  final String label, value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 8,
      leading: Icon(icon, color: scheme.primary),
      title: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
      subtitle: Text(value,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
              fontStyle: muted ? FontStyle.italic : null)),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = profile.name?.trim() ?? '';
    return FormSection(
      title: l10n.accountDetails,
      child: Column(children: [
        _Row(Icons.badge_outlined, l10n.name, name.isEmpty ? l10n.nameNotSet : name, muted: name.isEmpty),
        _Row(Icons.phone_iphone, l10n.mobileNumber, profile.phone),
        _Row(Icons.event_available, l10n.memberSince, DateFormat.yMMMd().format(profile.memberSince)),
        _Row(Icons.groups_outlined, l10n.yourRoles, profile.roles.map(l10n.roleName).join(', ')),
      ]),
    );
  }
}

class _FarmerCard extends ConsumerWidget {
  const _FarmerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final farmer = ref.watch(farmerProvider).value;
    if (farmer == null) return const SizedBox.shrink();
    final lang = ref.watch(localeProvider);
    final crops = ref.watch(cropsProvider).value ?? const <Crop>[];
    final cropNames = [
      for (final code in farmer.cropCodes) cropName(code, crops, lang),
    ];
    return FormSection(
      title: l10n.farmDetails,
      child: Column(children: [
        _Row(Icons.verified_user_outlined, l10n.verificationStatus, l10n.farmerStatus(farmer.status)),
        _Row(Icons.location_on_outlined, l10n.village,
            [farmer.village, if (farmer.district case final d?) districtName(d, lang)].whereType<String>().join(', ').ifEmpty(l10n.notGiven)),
        _Row(Icons.grass, l10n.crops, cropNames.join(', ').ifEmpty(l10n.notGiven)),
        if (farmer.farmSizeAcres != null) _Row(Icons.straighten, l10n.farmSize, l10n.aboutAcres('${farmer.farmSizeAcres}')),
      ]),
    );
  }
}

class _HostCard extends ConsumerWidget {
  const _HostCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spaces = ref.watch(mySpacesProvider).value;
    if (spaces == null) return const SizedBox.shrink();
    return FormSection(
      title: l10n.mySpaces,
      child: _Row(Icons.home_work_outlined, l10n.roleNameHost,
          l10n.mySpacesSummary(spaces.length, spaces.where((s) => s.status == 'Live').length)),
    );
  }
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return FormSection(
      title: l10n.appearance,
      subtitle: l10n.themeSystemHint,
      child: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(l10n.themeSystem)),
          ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(l10n.themeLight)),
          ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(l10n.themeDark)),
        ],
        selected: {ref.watch(themeModeProvider)},
        onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.single),
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return FormSection(
      title: l10n.language,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          for (final e in LanguageScreen.languages.entries) ButtonSegment(value: e.key, label: Text(e.value)),
        ],
        selected: {ref.watch(localeProvider)},
        onSelectionChanged: (s) {
          ref.read(localeProvider.notifier).set(s.single);
          // Alerts and SMS follow the saved language; a failure here is not worth interrupting the user.
          ref.read(authApiProvider).setLanguage(s.single).ignore();
        },
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

/// Log out as a clear, separate row at the end of the profile; asks before logging out.
class _LogoutCard extends ConsumerWidget {
  const _LogoutCard({required this.phone});
  final String? phone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.error.withValues(alpha: .35)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: scheme.errorContainer,
          foregroundColor: scheme.onErrorContainer,
          child: const Icon(Icons.logout),
        ),
        title: Text(l10n.logout, style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700, fontSize: 17)),
        subtitle: phone == null ? null : Text(l10n.signedInAs(phone!)),
        trailing: Icon(Icons.chevron_right, color: scheme.error),
        onTap: () => confirmLogout(context, ref),
      ),
    );
  }
}
