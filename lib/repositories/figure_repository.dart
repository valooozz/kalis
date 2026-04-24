import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/figure_model.dart';

class FigureRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  FigureRepository({
    required FirebaseFirestore firestore,
    required String userId,
  })  : _firestore = firestore,
        _userId = userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_userId).collection('figures');

  Stream<List<FigureModel>> watchAll() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FigureModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<FigureModel?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return FigureModel.fromFirestore(doc.data()!, doc.id);
  }

  Future<FigureModel> create(FigureModel figure) async {
    final doc = await _collection.add(figure.toFirestore());
    return figure.copyWith(id: doc.id);
  }

  Future<void> update(FigureModel figure) async {
    await _collection.doc(figure.id).update(figure.toFirestore());
  }

  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}