import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis/models/renfo_done_model.dart';
import 'package:kalis/models/renfo_model.dart';
import 'package:kalis/providers/figure_providers.dart';
import 'package:kalis/providers/renfo_providers.dart';
import 'package:kalis/providers/today_providers.dart';

void main() {
  testWidgets('includes the latest training date of associated figures', (
    tester,
  ) async {
    final today = DateTime(2026, 11, 22);
    final lastRenfoTraining = DateTime(2026, 11, 19);
    final lastFigureTraining = DateTime(2026, 11, 21);
    const renfo = RenfoModel(
      id: 'renfo-id',
      name: 'Renfo',
      figureIds: ['figure-id'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(today),
          renfosProvider.overrideWith((ref) => Stream.value([renfo])),
          renfoDoneAllProvider.overrideWith(
            (ref) => Stream.value([
              RenfoDoneModel(renfoId: renfo.id, date: lastRenfoTraining),
            ]),
          ),
          lastTrainingDateProvider(
            'figure-id',
          ).overrideWith((ref) => Stream.value(lastFigureTraining)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) =>
                  Text('${ref.watch(renfoLastDoneDatesProvider)['renfo-id']}'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(lastFigureTraining.toString()), findsOneWidget);
  });
}
