import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry_model.dart';

class JournalEntryRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  JournalEntryRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_userId).collection('journalEntries');

  Stream<List<JournalEntryModel>> watchByFigure(String figureId) {
    return _collection
        .where('figureId', isEqualTo: figureId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JournalEntryModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<JournalEntryModel?> watchByFigureAndDate(
    String figureId,
    DateTime date,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _collection
        .where('figureId', isEqualTo: figureId)
        .where('date', isGreaterThanOrEqualTo: dayStart.toIso8601String())
        .where('date', isLessThanOrEqualTo: dayEnd.toIso8601String())
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return JournalEntryModel.fromFirestore(doc.data(), doc.id);
        });
  }

  Future<JournalEntryModel?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return JournalEntryModel.fromFirestore(doc.data()!, doc.id);
  }

  Future<JournalEntryModel> create(JournalEntryModel journalEntry) async {
    final doc = await _collection.add(journalEntry.toFirestore());
    return journalEntry.copyWith(id: doc.id);
  }

  Future<void> update(JournalEntryModel journalEntry) async {
    await _collection.doc(journalEntry.id).update(journalEntry.toFirestore());
  }

  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}
