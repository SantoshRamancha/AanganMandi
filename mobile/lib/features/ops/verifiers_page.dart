import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/ops_api.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import 'ops_widgets.dart';

/// Admin only: add and remove verifiers. A new verifier signs in with their mobile number and OTP.
class VerifiersPage extends ConsumerStatefulWidget {
  const VerifiersPage({super.key});

  @override
  ConsumerState<VerifiersPage> createState() => _VerifiersPageState();
}

class _VerifiersPageState extends ConsumerState<VerifiersPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }


  void _say(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _add() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final name = _name.text.trim();
      final assigned = await ref.read(opsApiProvider).addVerifier(name: name, phone: _phone.text);
      _say([l10n.verifierAddedToast(name, _phone.text), if (assigned > 0) l10n.farmersAssignedToNew(assigned)].join(' '));
      _name.clear();
      _phone.clear();
      refreshOps(ref);
    } catch (e) {
      _say(apiErrorMessage(e, l10n.couldNotSave));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(VerifierRow v) async {
    final l10n = AppLocalizations.of(context);
    final name = v.name ?? v.phone;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        icon: const Icon(Icons.person_remove_outlined),
        title: Text(l10n.removeVerifierQ(name)),
        content: Text([l10n.removeVerifierBody, if (v.waiting > 0) l10n.removeVerifierMoves(v.waiting)].join('\n\n')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialog).colorScheme.error,
              foregroundColor: Theme.of(dialog).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final r = await ref.read(opsApiProvider).removeVerifier(v.userId);
      _say([
        l10n.verifierRemovedToast(name),
        if (r.moved > 0) l10n.farmersMoved(r.moved),
        if (r.unassigned > 0) l10n.farmersNowUnassigned(r.unassigned),
      ].join(' '));
      refreshOps(ref);
    } catch (e) {
      _say(apiErrorMessage(e, l10n.couldNotSave));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rows = ref.watch(verifiersProvider);
    return ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
      MaxWidth(
        maxWidth: 960,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageHeader(l10n.opsTabVerifiers, subtitle: l10n.verifiersHint),
          Form(
            key: _form,
            child: InfoCard(title: l10n.addVerifierTitle, children: [
              ResponsiveFields(children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.name),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.enterName : null,
                ),
                TextFormField(
                  controller: _phone,
                  decoration: InputDecoration(labelText: l10n.mobileNumber, prefixText: '+91 '),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => (v?.length ?? 0) == 10 ? null : l10n.enterTenDigits,
                ),
              ]),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.person_add_alt),
                  label: Text(l10n.addVerifierButton),
                  onPressed: _busy ? null : _add,
                ),
              ),
            ]),
          ),
          rows.when(
            loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text(apiErrorMessage(e, l10n.couldNotLoad)),
            data: (list) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noVerifiersBody, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              for (final v in list)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      child: Text((v.name ?? '?').characters.first.toUpperCase()),
                    ),
                    title: Text(v.name ?? l10n.noName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${l10n.verifierAddedOn(v.phone, formatWhen(v.addedAt))}\n'
                        '${l10n.verifierCounts(v.waiting, v.reviewed)}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: Icon(Icons.person_remove_outlined, color: scheme.error),
                      tooltip: l10n.removeVerifierTooltip,
                      onPressed: () => _remove(v),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
