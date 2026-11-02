import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/prefs.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';

/// One app, three roles (Section 4): farmer, host, buyer. The choice is saved on the server.
class RoleScreen extends ConsumerStatefulWidget {
  const RoleScreen({super.key});

  @override
  ConsumerState<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends ConsumerState<RoleScreen> {
  String? _saving;

  Future<void> _choose(String role) async {
    setState(() => _saving = role);
    try {
      await ref.read(authApiProvider).chooseRole(role);
      await Prefs.setRole(role);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(apiErrorMessage(e, AppLocalizations.of(context).errorGeneric))));
      }
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final roles = [
      ('Farmer', Icons.agriculture, l10n.roleFarmer, l10n.roleFarmerHint),
      ('Host', Icons.home_work, l10n.roleHost, l10n.roleHostHint),
      ('Buyer', Icons.shopping_basket, l10n.roleBuyer, l10n.roleBuyerHint),
    ];
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.whoAreYou, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          for (final (role, icon, title, hint) in roles)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _saving == null ? () => _choose(role) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(icon, size: 30, color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(hint, style: TextStyle(color: scheme.onSurfaceVariant)),
                        ]),
                      ),
                      _saving == role
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.chevron_right),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
