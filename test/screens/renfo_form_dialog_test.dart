import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/renfo_model.dart';
import 'package:kalis/providers/core_providers.dart';
import 'package:kalis/providers/renfo_providers.dart';
import 'package:kalis/repositories/renfo_repository.dart';
import 'package:kalis/screens/renfos/renfo_form_dialog.dart';

void main() {
  testWidgets('closes after creating while the Firestore write is pending', (
    tester,
  ) async {
    final repository = _PendingCreateRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          renfoRepositoryProvider.overrideWithValue(repository),
          renfosProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const RenfoFormDialog(),
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Séance');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(repository.createCalled, isTrue);
    expect(find.text('Nouveau renfo'), findsNothing);
  });
}

class _PendingCreateRepository implements RenfoRepository {
  final _createCompleter = Completer<RenfoModel>();
  bool createCalled = false;

  @override
  Future<RenfoModel> create(RenfoModel renfo) {
    createCalled = true;
    return _createCompleter.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
