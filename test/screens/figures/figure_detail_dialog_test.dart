import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/figure_model.dart';
import 'package:kalis/models/journal_entry_model.dart';
import 'package:kalis/providers/core_providers.dart';
import 'package:kalis/providers/journal_providers.dart';
import 'package:kalis/repositories/figure_repository.dart';
import 'package:kalis/screens/figures/figure_detail_dialog.dart';

void main() {
  testWidgets('restores an archived figure from its detail dialog', (
    tester,
  ) async {
    final repository = _FigureRepositorySpy();
    const figure = FigureModel(
      id: 'figure-id',
      name: 'Traction',
      color: FigureColor.blue,
      state: FigureState.toLearn,
      archived: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          figureRepositoryProvider.overrideWithValue(repository),
          journalEntriesForFigureProvider(
            figure.id,
          ).overrideWith((ref) => Stream.value(const <JournalEntryModel>[])),
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
                  builder: (_) => const FigureDetailDialog(figure: figure),
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

    expect(find.text('Restaurer'), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);

    await tester.tap(find.text('Restaurer'));
    await tester.pumpAndSettle();

    expect(repository.updatedFigure?.archived, isFalse);
    expect(find.text('Restaurer'), findsNothing);
  });
}

class _FigureRepositorySpy implements FigureRepository {
  FigureModel? updatedFigure;

  @override
  Future<void> update(FigureModel figure) async {
    updatedFigure = figure;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
