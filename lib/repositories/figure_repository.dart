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
    if (!figure.archived) {
      await _collection.doc(figure.id).update(figure.toFirestore());
      return;
    }

    final archivedFigure = figure.copyWith(paused: false);
    final figureWrite = _collection
        .doc(figure.id)
        .update(archivedFigure.toFirestore());
    final placesFuture = _firestore
        .collection('users')
        .doc(_userId)
        .collection('places')
        .where('figureIds', arrayContains: figure.id)
        .get();
    final renfosFuture = _firestore
        .collection('users')
        .doc(_userId)
        .collection('renfos')
        .where('figureIds', arrayContains: figure.id)
        .get();

    final relationCleanup = Future.wait([placesFuture, renfosFuture]).then((
      snapshots,
    ) async {
      final batch = _firestore.batch();
      for (final doc in snapshots[0].docs) {
        batch.update(doc.reference, {
          'figureIds': FieldValue.arrayRemove([figure.id]),
        });
      }
      for (final doc in snapshots[1].docs) {
        batch.update(doc.reference, {
          'figureIds': FieldValue.arrayRemove([figure.id]),
        });
      }
      await batch.commit();
    });

    await Future.wait([figureWrite, relationCleanup]);
  }

  Future<void> delete(String figureId) async {
    final figureDelete = _collection.doc(figureId).delete();
    final trainingDoneFuture = _firestore
        .collection('users')
        .doc(_userId)
        .collection('trainingDone')
        .where('figureId', isEqualTo: figureId)
        .get();
    final trainingPlannedFuture = _firestore
        .collection('users')
        .doc(_userId)
        .collection('trainingPlanned')
        .where('figureId', isEqualTo: figureId)
        .get();
    final journalEntriesFuture = _firestore
        .collection('users')
        .doc(_userId)
        .collection('journalEntries')
        .where('figureId', isEqualTo: figureId)
        .get();
    final placesFuture = _firestore
        .collection('users')
        .doc(_userId)
        .collection('places')
        .where('figureIds', arrayContains: figureId)
        .get();
    final renfosFuture = _firestore
        .collection('users')
        .doc(_userId)
        .collection('renfos')
        .where('figureIds', arrayContains: figureId)
        .get();

    final cascadeDelete =
        Future.wait([
          trainingDoneFuture,
          trainingPlannedFuture,
          journalEntriesFuture,
          placesFuture,
          renfosFuture,
        ]).then((snapshots) async {
          final batch = _firestore.batch();
          for (final snapshot in snapshots.take(3)) {
            for (final doc in snapshot.docs) {
              batch.delete(doc.reference);
            }
          }
          for (final snapshot in snapshots.skip(3)) {
            for (final doc in snapshot.docs) {
              batch.update(doc.reference, {
                'figureIds': FieldValue.arrayRemove([figureId]),
              });
            }
          }
          await batch.commit();
        });

    await Future.wait([figureDelete, cascadeDelete]);
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
