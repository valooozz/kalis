import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/renfo_model.dart';

class RenfoRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  RenfoRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_userId).collection('renfos');

  Stream<List<RenfoModel>> watchAll() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((d) => RenfoModel.fromFirestore(d.data(), d.id))
          .toList();
    });
  }

  Future<RenfoModel?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return RenfoModel.fromFirestore(doc.data()!, doc.id);
  }

  Future<RenfoModel> create(RenfoModel renfo) async {
    final doc = await _collection.add(renfo.toFirestore());
    return renfo.copyWith(id: doc.id);
  }

  Future<void> update(RenfoModel renfo) async {
    await _collection.doc(renfo.id).update(renfo.toFirestore());
  }

  Future<void> delete(String renfoId) async {
    await _collection.doc(renfoId).delete();
  }
}
