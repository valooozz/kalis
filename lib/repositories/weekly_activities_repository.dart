import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weekly_activities_model.dart';

class WeeklyActivitiesRepository {
  static const _docId = 'main';

  final FirebaseFirestore _firestore;
  final String _userId;

  WeeklyActivitiesRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection('users')
      .doc(_userId)
      .collection('weeklyActivities')
      .doc(_docId);

  Stream<WeeklyActivitiesModel> watch() {
    return _doc.snapshots().map((snapshot) {
      if (!snapshot.exists) return const WeeklyActivitiesModel();
      return WeeklyActivitiesModel.fromFirestore(snapshot.data()!);
    });
  }

  Future<void> save(WeeklyActivitiesModel activities) async {
    await _doc.set(activities.toFirestore());
  }
}
