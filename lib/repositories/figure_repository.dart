import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/figure_model.dart';

class FigureRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  FigureRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
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

  Future<void> delete(String figureId) async {
    final batch = _firestore.batch();

    // Suppression de la figure
    batch.delete(_collection.doc(figureId));

    // Suppression des trainingDone associés
    final trainingDone = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('trainingDone')
        .where('figureId', isEqualTo: figureId)
        .get();
    for (final doc in trainingDone.docs) {
      batch.delete(doc.reference);
    }

    // Suppression des trainingPlanned associés
    final trainingPlanned = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('trainingPlanned')
        .where('figureId', isEqualTo: figureId)
        .get();
    for (final doc in trainingPlanned.docs) {
      batch.delete(doc.reference);
    }

    // Suppression des journalEntries associées
    final journalEntries = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('journalEntries')
        .where('figureId', isEqualTo: figureId)
        .get();
    for (final doc in journalEntries.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> updateOrder(List<FigureModel> figures) async {
    final batch = _firestore.batch();
    for (int i = 0; i < figures.length; i++) {
      batch.update(_collection.doc(figures[i].id), {'order': i});
    }
    await batch.commit();
  }

  Future<int> getMaxOrder(FigureState state) async {
    final snapshot = await _collection
        .where('state', isEqualTo: state.name)
        .get();
    if (snapshot.docs.isEmpty) return 0;
    final orders = snapshot.docs
        .map((d) => (d.data()['order'] as int?) ?? 0)
        .toList();
    return orders.reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<int> getMinOrder(FigureState state) async {
    final snapshot = await _collection
        .where('state', isEqualTo: state.name)
        .get();
    if (snapshot.docs.isEmpty) return 0;
    final orders = snapshot.docs
        .map((d) => (d.data()['order'] as int?) ?? 0)
        .toList();
    return orders.reduce((a, b) => a < b ? a : b) - 1;
  }
}
