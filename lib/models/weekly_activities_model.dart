class WeeklyActivitiesModel {
  final Map<int, String> activities;

  const WeeklyActivitiesModel({this.activities = const {}});

  factory WeeklyActivitiesModel.fromFirestore(Map<String, dynamic> data) {
    final rawActivities = data['activities'] as Map<String, dynamic>?;
    if (rawActivities == null) return const WeeklyActivitiesModel();

    return WeeklyActivitiesModel(
      activities: {
        for (final entry in rawActivities.entries)
          if (int.tryParse(entry.key) case final weekday?
              when weekday >= DateTime.monday &&
                  weekday <= DateTime.sunday &&
                  entry.value is String)
            weekday: entry.value as String,
      },
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'activities': {
        for (final entry in activities.entries)
          entry.key.toString(): entry.value,
      },
    };
  }

  String activityFor(DateTime date) => activities[date.weekday] ?? '';
}
