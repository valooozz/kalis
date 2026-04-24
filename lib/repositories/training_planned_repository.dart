import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/training_planned_model.dart';

class TrainingPlannedRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  TrainingPlannedRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_userId).collection('trainingPlanned');

  Stream<List<TrainingPlannedModel>> watchByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _collection
        .where('date', isGreaterThanOrEqualTo: dayStart.toIso8601String())
        .where('date', isLessThanOrEqualTo: dayEnd.toIso8601String())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TrainingPlannedModel.fromFirestore(doc.data()))
              .toList(),
        );
  }

  Stream<List<TrainingPlannedModel>> watchByFigure(String figureId) {
    return _collection
        .where('figureId', isEqualTo: figureId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TrainingPlannedModel.fromFirestore(doc.data()))
              .toList(),
        );
  }

  Stream<List<TrainingPlannedModel>> watchByDateRange(
    DateTime start,
    DateTime end,
  ) {
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return _collection
        .where('date', isGreaterThanOrEqualTo: rangeStart.toIso8601String())
        .where('date', isLessThanOrEqualTo: rangeEnd.toIso8601String())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TrainingPlannedModel.fromFirestore(doc.data()))
              .toList(),
        );
  }

  Future<void> add(TrainingPlannedModel trainingPlanned) async {
    // On utilise un id déterministe figureId_date pour éviter les doublons
    final docId =
        '${trainingPlanned.figureId}_${trainingPlanned.date.toIso8601String().substring(0, 10)}';
    await _collection.doc(docId).set(trainingPlanned.toFirestore());
  }

  Future<void> remove(String figureId, DateTime date) async {
    final docId = '${figureId}_${date.toIso8601String().substring(0, 10)}';
    await _collection.doc(docId).delete();
  }

  Future<void> removeAllForFigure(String figureId) async {
    final snapshot = await _collection
        .where('figureId', isEqualTo: figureId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<bool> exists(String figureId, DateTime date) async {
    final docId = '${figureId}_${date.toIso8601String().substring(0, 10)}';
    final doc = await _collection.doc(docId).get();
    return doc.exists;
  }
}
