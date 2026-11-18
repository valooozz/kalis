import 'package:flutter_test/flutter_test.dart';
import 'package:kalis/models/figure_model.dart';

void main() {
  group('FigureModel archive state', () {
    test('defaults to not archived for existing Firestore documents', () {
      final figure = FigureModel.fromFirestore({
        'name': 'Traction',
        'color': 'blue',
        'state': 'learning',
      }, 'figure-id');

      expect(figure.archived, isFalse);
    });

    test('persists and copies archive state', () {
      const figure = FigureModel(
        id: 'figure-id',
        name: 'Traction',
        color: FigureColor.blue,
        state: FigureState.learning,
        archived: true,
      );

      expect(figure.toFirestore()['archived'], isTrue);
      expect(figure.copyWith(archived: false).archived, isFalse);
    });
  });
}
