import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/prefs.dart';
import '../../core/widgets/responsive.dart';
import '../../l10n/app_localizations.dart';

/// What the phone screen hands to the OTP screen.
class OtpArgs {
  const OtpArgs(this.phone, this.devCode);
  final String phone;
  final String? devCode;
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, this.devCode});
  final String phone;

  /// The OTP itself, sent by the server only while testing without SMS. Shown in a banner.
  final String? devCode;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  bool _busy = false;
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  // Filling all six boxes fires Pinput's onCompleted, which verifies; calling _verify here too
  // would send the one-time code twice and the second attempt fails.
  void _fillDevCode() => _pin.text = widget.devCode!;

  Future<void> _verify(String code) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final roles = await ref.read(authApiProvider).verifyOtp(widget.phone, code);
      // Staff roles are given by an admin, never chosen here, and open the operations home.
      final appRole = roles.contains('Admin')
          ? 'Admin'
          : roles.contains('Verifier')
              ? 'Verifier'
              : roles.where(const {'Farmer', 'Host', 'Buyer'}.contains).firstOrNull;
      if (appRole != null) await Prefs.setRole(appRole);
      if (mounted) context.go(appRole != null ? '/home' : '/role');
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
    final scheme = Theme.of(context).colorScheme;
    final box = PinTheme(
      width: 52,
      height: 60,
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return AuthShell(
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.enterOtp(widget.phone), style: Theme.of(context).textTheme.titleLarge),
          if (widget.devCode case final code?) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              color: scheme.tertiaryContainer,
              child: ListTile(
                leading: Icon(Icons.science_outlined, color: scheme.onTertiaryContainer),
                title: Text(l10n.testOtp(code),
                    style: TextStyle(color: scheme.onTertiaryContainer, fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.testOtpHint, style: TextStyle(color: scheme.onTertiaryContainer)),
                trailing: TextButton(
                  style: TextButton.styleFrom(foregroundColor: scheme.onTertiaryContainer),
                  onPressed: _busy ? null : _fillDevCode,
                  child: Text(l10n.useTestOtp, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: Pinput(
              controller: _pin,
              length: 6,
              autofocus: true,
              enabled: !_busy,
              defaultPinTheme: box,
              focusedPinTheme: box.copyDecorationWith(border: Border.all(color: scheme.primary, width: 2)),
              onCompleted: _verify,
            ),
          ),
          if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
