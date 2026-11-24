import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/figure_model.dart';
import 'package:kalis/models/journal_entry_model.dart';
import 'package:kalis/providers/journal_providers.dart';
import 'package:kalis/screens/figures/journal_entry_form_dialog.dart';
import 'package:kalis/screens/today/today_training_dialog.dart';

void main() {
  testWidgets('keeps the journal field unfocused until the user taps it', (
    tester,
  ) async {
    final entry = JournalEntryModel(
      id: 'entry-id',
      figureId: 'figure-id',
      date: DateTime(2026, 11, 24),
      text: 'Une note avec plusieurs mots à modifier.',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => JournalEntryFormDialog(
                    figureId: 'figure-id',
                    entry: entry,
                  ),
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

    final fieldFinder = find.byType(TextField);
    final field = tester.widget<TextField>(fieldFinder);
    expect(field.focusNode?.hasFocus ?? false, isFalse);

    final fieldRect = tester.getRect(fieldFinder);
    await tester.tapAt(Offset(fieldRect.left + 60, fieldRect.center.dy));
    await tester.pump();

    expect(field.controller!.selection.isCollapsed, isTrue);
  });

  testWidgets('preserves the caret when the existing note loads late', (
    tester,
  ) async {
    final entryStream = StreamController<JournalEntryModel?>();
    addTearDown(entryStream.close);
    const figure = FigureModel(
      id: 'figure-id',
      name: 'Traction',
      color: FigureColor.blue,
      state: FigureState.learning,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayJournalEntryForFigureProvider(
            figure.id,
          ).overrideWith((ref) => entryStream.stream),
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
                  builder: (_) => const TodayTrainingDialog(figure: figure),
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

    final fieldFinder = find.byType(TextField);
    final fieldRect = tester.getRect(fieldFinder);
    await tester.tapAt(Offset(fieldRect.left + 20, fieldRect.center.dy));
    await tester.pump();
    final controller = tester.widget<TextField>(fieldFinder).controller!;
    final caretOffset = controller.selection.extentOffset;

    entryStream.add(
      JournalEntryModel(
        id: 'entry-id',
        figureId: 'figure-id',
        date: DateTime(2026, 11, 24),
        text: 'Ancienne note',
      ),
    );
    await tester.pump();

    expect(controller.text, 'Ancienne note');
    expect(controller.selection, TextSelection.collapsed(offset: caretOffset));
  });

  testWidgets('does not replace a note edited before its entry loads', (
    tester,
  ) async {
    final entryStream = StreamController<JournalEntryModel?>();
    addTearDown(entryStream.close);
    const figure = FigureModel(
      id: 'figure-id',
      name: 'Traction',
      color: FigureColor.blue,
      state: FigureState.learning,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayJournalEntryForFigureProvider(
            figure.id,
          ).overrideWith((ref) => entryStream.stream),
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
                  builder: (_) => const TodayTrainingDialog(figure: figure),
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

    final fieldFinder = find.byType(TextField);
    await tester.enterText(fieldFinder, 'Ma note en cours');
    entryStream.add(
      JournalEntryModel(
        id: 'entry-id',
        figureId: 'figure-id',
        date: DateTime(2026, 11, 24),
        text: 'Ancienne note',
      ),
    );
    await tester.pump();

    expect(
      tester.widget<TextField>(fieldFinder).controller!.text,
      'Ma note en cours',
    );
  });
}
