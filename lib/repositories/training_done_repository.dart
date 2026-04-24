import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/training_done_model.dart';

class TrainingDoneRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  TrainingDoneRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_userId).collection('trainingDone');

  Stream<List<TrainingDoneModel>> watchByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _collection
        .where('date', isGreaterThanOrEqualTo: dayStart.toIso8601String())
        .where('date', isLessThanOrEqualTo: dayEnd.toIso8601String())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TrainingDoneModel.fromFirestore(doc.data()))
              .toList(),
        );
  }

  Stream<List<TrainingDoneModel>> watchByFigure(String figureId) {
    return _collection
        .where('figureId', isEqualTo: figureId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TrainingDoneModel.fromFirestore(doc.data()))
              .toList(),
        );
  }

  Future<void> add(TrainingDoneModel trainingDone) async {
    // On utilise un id déterministe figureId_date pour éviter les doublons
    final docId =
        '${trainingDone.figureId}_${trainingDone.date.toIso8601String().substring(0, 10)}';
    await _collection.doc(docId).set(trainingDone.toFirestore());
  }

  Future<void> remove(String figureId, DateTime date) async {
    final docId = '${figureId}_${date.toIso8601String().substring(0, 10)}';
    await _collection.doc(docId).delete();
  }

  Future<bool> exists(String figureId, DateTime date) async {
    final docId = '${figureId}_${date.toIso8601String().substring(0, 10)}';
    final doc = await _collection.doc(docId).get();
    return doc.exists;
  }
}
