import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Width breakpoints: phones < 600, tablets 600–1023, desktop ≥ 1024.
class Breakpoints {
  static const tablet = 600.0;
  static const desktop = 1024.0;

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= tablet;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;

  /// Side padding that grows with the screen.
  static double gutter(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= desktop ? 32 : w >= tablet ? 24 : 16;
  }
}

/// Centers [child] and caps its width so lines stay readable on large screens.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.maxWidth = 1120});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        // Take only the child's height, so it also works in bottom bars.
        heightFactor: 1,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Layout for language, login and role screens: a brand panel beside the form on wide
/// screens, the form alone (with a compact header) on phones.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.showBack = false});
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final desktop = Breakpoints.isDesktop(context);
    final form = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Breakpoints.gutter(context)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBack)
                  Align(alignment: Alignment.centerLeft, child: BackButton(onPressed: () => Navigator.of(context).maybePop())),
                if (!desktop) const _BrandHeader(),
                child,
              ],
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      body: desktop
          ? Row(children: [
              const Expanded(flex: 5, child: _BrandPanel()),
              Expanded(flex: 4, child: form),
            ])
          : form,
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Column(children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: scheme.primaryContainer,
          child: Icon(Icons.storefront, size: 40, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(height: 12),
        Text(l10n.appTitle, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(l10n.tagline, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const onBrand = Colors.white;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF558B2F)],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.storefront, size: 64, color: onBrand),
                const SizedBox(height: 24),
                Text(l10n.appTitle,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(color: onBrand, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(l10n.tagline, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: onBrand)),
                const SizedBox(height: 40),
                for (final (icon, text) in [
                  (Icons.verified_user, l10n.featureVerified),
                  (Icons.home_work, l10n.featureSpaces),
                  (Icons.notifications_active, l10n.featureAlerts),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(children: [
                      Icon(icon, color: onBrand),
                      const SizedBox(width: 16),
                      Expanded(child: Text(text, style: const TextStyle(color: onBrand, fontSize: 16))),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays children in [columns] equal columns on wide screens, one column on phones.
class ResponsiveFields extends StatelessWidget {
  const ResponsiveFields({super.key, required this.children, this.columns = 2, this.spacing = 16});
  final List<Widget> children;
  final int columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 560 ? columns : 1;
      final width = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    });
  }
}

/// A titled card section used by long forms.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: text.bodySmall),
          ],
          const SizedBox(height: 16),
          child,
        ]),
      ),
    );
  }
}
