import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

/// Texte de la note générale de l'utilisateur, en temps réel.
/// Retourne une chaîne vide tant que l'utilisateur n'est pas authentifié
/// ou qu'aucune note n'a encore été enregistrée.
final generalNoteProvider = StreamProvider<String>((ref) {
  final repository = ref.watch(generalNoteRepositoryProvider);
  if (repository == null) return Stream.value('');
  return repository.watch();
});
