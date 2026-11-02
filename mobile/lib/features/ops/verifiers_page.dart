import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/ops_api.dart';
import '../../core/widgets/responsive.dart';
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
    setState(() => _busy = true);
    try {
      final name = _name.text.trim();
      final assigned = await ref.read(opsApiProvider).addVerifier(name: name, phone: _phone.text);
      _say('Added $name. They can sign in with +91 ${_phone.text}.'
          '${assigned > 0 ? ' $assigned waiting farmer(s) were assigned to them.' : ''}');
      _name.clear();
      _phone.clear();
      refreshOps(ref);
    } catch (e) {
      _say(apiErrorMessage(e, 'Could not add the verifier.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(VerifierRow v) async {
    final name = v.name ?? v.phone;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Remove $name?'),
        content: Text('They can no longer review farmers or spaces.'
            '${v.waiting > 0 ? '\n\nTheir ${v.waiting} waiting farmer(s) move to the other verifiers.' : ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialog).colorScheme.error),
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final r = await ref.read(opsApiProvider).removeVerifier(v.userId);
      _say('Removed $name.'
          '${r.moved > 0 ? ' ${r.moved} waiting farmer(s) moved to other verifiers.' : ''}'
          '${r.unassigned > 0 ? ' ${r.unassigned} farmer(s) are now unassigned: add a verifier to pick them up.' : ''}');
      refreshOps(ref);
    } catch (e) {
      _say(apiErrorMessage(e, 'Could not remove the verifier.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = ref.watch(verifiersProvider);
    return ListView(padding: EdgeInsets.all(Breakpoints.gutter(context)), children: [
      MaxWidth(
        maxWidth: 960,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Verifiers', style: Theme.of(context).textTheme.headlineSmall),
          Text('Each farmer who submits goes to the verifier with the fewest farmers waiting; a resubmission goes back to the same verifier.',
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Form(
            key: _form,
            child: InfoCard(title: 'Add a verifier', children: [
              ResponsiveFields(children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the name' : null,
                ),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+91 '),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => (v?.length ?? 0) == 10 ? null : 'Enter a 10-digit number',
                ),
              ]),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.person_add_alt),
                  label: const Text('Add verifier'),
                  onPressed: _busy ? null : _add,
                ),
              ),
            ]),
          ),
          rows.when(
            loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text(apiErrorMessage(e, 'Could not load verifiers.')),
            data: (list) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No verifiers yet. Farmers who submit stay unassigned until you add one.',
                      textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              for (final v in list)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text((v.name ?? '?').characters.first.toUpperCase())),
                    title: Text(v.name ?? '(no name)', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${v.phone} · added ${formatWhen(v.addedAt)}\n${v.waiting} waiting · ${v.reviewed} reviewed'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: Icon(Icons.person_remove_outlined, color: scheme.error),
                      tooltip: 'Remove verifier',
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
