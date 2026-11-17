import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// The app's root navigator and messenger (set on GoRouter and MaterialApp), so a message can still be shown after
/// the screen that asked for it has closed.
final rootNavigatorKey = GlobalKey<NavigatorState>();
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// "It worked": a green floating card with a check mark that goes away by itself after 3 seconds.
void showSuccess(BuildContext context, String message) {
  final messenger = rootMessengerKey.currentState ?? (context.mounted ? ScaffoldMessenger.maybeOf(context) : null);
  final themed = rootNavigatorKey.currentContext ?? (context.mounted ? context : null);
  if (messenger == null || themed == null) return;
  final scheme = Theme.of(themed).colorScheme;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: scheme.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        elevation: 6,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: scheme.onSuccess),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onSuccess, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
}

/// "That didn't work": a dialog with the reason, closed with OK, so it is never missed.
Future<void> showError(BuildContext context, String message, {String? title}) async {
  final host = rootNavigatorKey.currentContext ?? (context.mounted ? context : null);
  if (host == null) return;
  final l10n = AppLocalizations.of(host);
  await showDialog<void>(
    context: host,
    builder: (dialog) {
      final scheme = Theme.of(dialog).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.error_outline, color: scheme.error, size: 36),
        title: Text(title ?? l10n.errorTitle),
        content: Text(message, style: const TextStyle(fontSize: 16, height: 1.4)),
        actions: [FilledButton(onPressed: () => Navigator.pop(dialog), child: Text(l10n.ok))],
      );
    },
  );
}

/// The words for an API failure: no internet, a problem on our side, or the server's own reason (e.g. "Please wait
/// 30 seconds before asking for a new OTP").
String errorText(AppLocalizations l10n, Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return l10n.noConnection;
      default:
        break;
    }
    final status = error.response?.statusCode ?? 0;
    if (status >= 500) return l10n.serverProblem;
    final data = error.response?.data;
    if (data is Map && data['title'] is String) return data['title'] as String;
  }
  return l10n.errorGeneric;
}

/// Shows an API failure as an error pop-up.
Future<void> showApiError(BuildContext context, Object error) {
  final host = rootNavigatorKey.currentContext ?? (context.mounted ? context : null);
  if (host == null) return Future.value();
  return showError(context, errorText(AppLocalizations.of(host), error));
}
