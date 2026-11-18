import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_activities_model.dart';
import 'core_providers.dart';

final weeklyActivitiesProvider = StreamProvider<WeeklyActivitiesModel>((ref) {
  final repository = ref.watch(weeklyActivitiesRepositoryProvider);
  if (repository == null) {
    return Stream.value(const WeeklyActivitiesModel());
  }
  return repository.watch();
});
