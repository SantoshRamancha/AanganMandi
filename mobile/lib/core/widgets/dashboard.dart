import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Building blocks for the role dashboards (farmer, host, operations): a greeting banner, number tiles,
/// section headings and a "how it works" step list. Colours come from the theme, so light and dark both work.

/// Brand banner at the top of a dashboard: greeting, one line of context, and an optional action.
class DashboardBanner extends StatelessWidget {
  const DashboardBanner({super.key, required this.title, required this.subtitle, required this.icon, this.action});
  final String title, subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onPrimary;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, Color.lerp(scheme.primary, scheme.tertiary, .55)!],
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: fg, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: fg.withValues(alpha: .9), fontSize: 15, height: 1.35)),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ]),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 34,
          backgroundColor: fg.withValues(alpha: .16),
          child: Icon(icon, size: 38, color: fg),
        ),
      ]),
    );
  }
}

/// A white button for use on the banner's brand colour.
class BannerButton extends StatelessWidget {
  const BannerButton({super.key, required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.onPrimary,
        foregroundColor: scheme.primary,
        minimumSize: const Size(0, 48),
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

/// One number with a label and icon; [highlight] (amber) marks something waiting for the user.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.highlight = false,
    this.onTap,
  });
  final int value;
  final String label;
  final IconData icon;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = highlight ? scheme.onWarningContainer : scheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      color: highlight ? scheme.warningContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('$value', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: accent, height: 1.1)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (highlight ? scheme.onWarningContainer : scheme.primary).withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: accent),
              ),
            ]),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(color: highlight ? scheme.onWarningContainer : scheme.onSurfaceVariant, height: 1.3)),
          ]),
        ),
      ),
    );
  }
}

/// Tiles in equal columns: 2 on phones, 4 on wide screens (3 when [maxColumns] is 3).
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children, this.maxColumns = 4});
  final List<Widget> children;
  final int maxColumns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        const gap = 12.0;
        final cols = c.maxWidth >= 720 ? maxColumns : 2;
        final width = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final child in children) SizedBox(width: width, child: child),
        ]);
      });
}

/// Section title with an optional action on the right ("Plan a trip", "View all").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.top = 28});
  final String title;
  final Widget? action;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 12),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
          ?action,
        ]),
      );
}

/// Numbered steps explaining how the app works; [done] steps get a tick, the [current] one is highlighted.
class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key, required this.steps, this.done = 0});

  /// (icon, title, explanation)
  final List<(IconData, String, String)> steps;

  /// How many steps are already complete; the next one is the current step.
  final int done;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: [
          for (final (i, (icon, title, body)) in steps.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: i < done
                    ? scheme.primary
                    : i == done
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                foregroundColor: i < done
                    ? scheme.onPrimary
                    : i == done
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                child: Icon(i < done ? Icons.check : icon),
              ),
              title: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: i > done ? scheme.onSurfaceVariant : scheme.onSurface)),
              subtitle: Text(body),
            ),
        ]),
      ),
    );
  }
}
