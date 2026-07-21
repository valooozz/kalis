import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place_model.dart';

class PlaceRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  PlaceRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_userId).collection('places');

  Stream<List<PlaceModel>> watchAll() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((d) => PlaceModel.fromFirestore(d.data(), d.id))
          .toList();
    });
  }

  Future<PlaceModel?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return PlaceModel.fromFirestore(doc.data()!, doc.id);
  }

  Future<PlaceModel> create(PlaceModel place) async {
    final doc = await _collection.add(place.toFirestore());
    return place.copyWith(id: doc.id);
  }

  Future<void> update(PlaceModel place) async {
    await _collection.doc(place.id).update(place.toFirestore());
  }

  Future<void> delete(String placeId) async {
    await _collection.doc(placeId).delete();
  }
}
