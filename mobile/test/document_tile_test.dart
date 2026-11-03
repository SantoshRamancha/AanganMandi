import 'dart:convert';

import 'package:aangan_mandi/core/widgets/document_tile.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 1×1 transparent PNG, so the thumbnail decodes without a server.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

Widget _app(DocumentTile tile) => ProviderScope(
      overrides: [authFileProvider.overrideWith((ref, path) async => (bytes: _png, contentType: 'image/png'))],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SizedBox(width: 360, child: tile)),
      ),
    );

DocumentTile _tile({required bool canChange, String? path = '/farmers/me/evidence/photo?v=1'}) => DocumentTile(
      label: 'Evidence photo',
      filePath: path,
      fileName: 'evidence',
      canChange: canChange,
      onUpload: (_) async {},
      onDelete: () async {},
    );

void main() {
  testWidgets('waiting for approval: preview, download, reupload and delete', (tester) async {
    await tester.pumpWidget(_app(_tile(canChange: true)));
    await tester.pumpAndSettle();
    for (final label in ['Preview', 'Download', 'Reupload', 'Delete']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.textContaining('can no longer be changed'), findsNothing);
  });

  testWidgets('approved: preview and download only', (tester) async {
    await tester.pumpWidget(_app(_tile(canChange: false)));
    await tester.pumpAndSettle();
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Reupload'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.textContaining('can no longer be changed'), findsOneWidget);
  });

  testWidgets('nothing uploaded yet: only the upload button', (tester) async {
    await tester.pumpWidget(_app(_tile(canChange: true, path: null)));
    await tester.pumpAndSettle();
    expect(find.text('Upload photo'), findsOneWidget);
    expect(find.text('Preview'), findsNothing);
  });

  testWidgets('delete asks first, and says when a waiting submission is withdrawn', (tester) async {
    var deleted = 0;
    await tester.pumpWidget(_app(DocumentTile(
      label: 'Evidence photo',
      filePath: '/x?v=1',
      fileName: 'evidence',
      canChange: true,
      deleteWarning: 'It leaves the review queue.',
      onUpload: (_) async {},
      onDelete: () async => deleted++,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('It leaves the review queue.'), findsOneWidget);
    expect(deleted, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
  });
}
