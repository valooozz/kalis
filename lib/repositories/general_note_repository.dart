import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository pour la note générale de l'utilisateur.
///
/// Il n'y a qu'une seule note par utilisateur. Pour rester cohérent avec
/// le reste de l'app (un repository = une collection Firestore), la note
/// est stockée dans une collection dédiée `generalNote` ne contenant
/// qu'un unique document à id fixe.
class GeneralNoteRepository {
  static const _docId = 'main';

  final FirebaseFirestore _firestore;
  final String _userId;

  GeneralNoteRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection('users')
      .doc(_userId)
      .collection('generalNote')
      .doc(_docId);

  /// Flux temps réel du texte de la note.
  /// Retourne une chaîne vide si aucune note n'a encore été enregistrée.
  Stream<String> watch() {
    return _doc.snapshots().map((snapshot) {
      if (!snapshot.exists) return '';
      return (snapshot.data()?['text'] as String?) ?? '';
    });
  }

  /// Enregistre (ou crée) la note. `merge: true` n'est pas nécessaire ici
  /// puisque le document ne contient qu'un seul champ.
  Future<void> save(String text) async {
    await _doc.set({'text': text});
  }
}
