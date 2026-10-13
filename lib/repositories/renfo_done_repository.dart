import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/renfo_done_model.dart';

class RenfoDoneRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  RenfoDoneRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_userId).collection('renfoDone');

  String _docId(String renfoId, DateTime date) =>
      '${renfoId}_${DateTime(date.year, date.month, date.day).toIso8601String().substring(0, 10)}';

  Stream<List<RenfoDoneModel>> watchAll() {
    return _collection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => RenfoDoneModel.fromFirestore(doc.data()))
          .toList(),
    );
  }

  Future<void> add(RenfoDoneModel renfoDone) async {
    await _collection
        .doc(_docId(renfoDone.renfoId, renfoDone.date))
        .set(renfoDone.toFirestore());
  }

  Future<void> remove(String renfoId, DateTime date) async {
    await _collection.doc(_docId(renfoId, date)).delete();
  }

  Future<void> removeAllForRenfo(String renfoId) async {
    final snapshot = await _collection
        .where('renfoId', isEqualTo: renfoId)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
