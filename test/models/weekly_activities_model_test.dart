import 'package:flutter_test/flutter_test.dart';
import 'package:kalis/models/weekly_activities_model.dart';

void main() {
  group('WeeklyActivitiesModel', () {
    test('round-trips activities by weekday', () {
      const activities = WeeklyActivitiesModel(
        activities: {DateTime.wednesday: 'Cours de danse'},
      );

      final restored = WeeklyActivitiesModel.fromFirestore(
        activities.toFirestore(),
      );

      expect(restored.activities[DateTime.wednesday], 'Cours de danse');
      expect(restored.activityFor(DateTime(2026, 11, 18)), 'Cours de danse');
      expect(restored.activityFor(DateTime(2026, 11, 19)), isEmpty);
    });

    test('ignores invalid weekday keys when reading Firestore data', () {
      final activities = WeeklyActivitiesModel.fromFirestore({
        'activities': {'0': 'Invalid', '8': 'Invalid', '3': 'Danse'},
      });

      expect(activities.activities, {DateTime.wednesday: 'Danse'});
    });
  });
}
