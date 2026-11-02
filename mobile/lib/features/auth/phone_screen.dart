import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import 'otp_screen.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.length == 10;

  Future<void> _send() async {
    if (!_valid || _busy) return;
    final phone = '+91${_controller.text}';
    setState(() => _busy = true);
    try {
      final devCode = await ref.read(authApiProvider).requestOtp(phone);
      if (mounted) context.push('/otp', extra: OtpArgs(phone, devCode));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(apiErrorMessage(e, AppLocalizations.of(context).errorGeneric))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.enterPhone, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            autofocus: true,
            style: const TextStyle(fontSize: 22, letterSpacing: 2),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(prefixText: '+91 ', prefixIcon: Icon(Icons.phone)),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sms),
            label: Text(l10n.sendOtp),
            onPressed: _valid && !_busy ? _send : null,
          ),
        ],
      ),
    );
  }
}
