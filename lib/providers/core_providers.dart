import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/figure_repository.dart';
import '../repositories/training_done_repository.dart';
import '../repositories/training_planned_repository.dart';
import '../repositories/journal_entry_repository.dart';

// Provider de l'instance Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Provider de l'instance FirebaseAuth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Provider de l'utilisateur courant (connecté anonymement)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Provider de l'userId courant
// Retourne null si l'utilisateur n'est pas encore authentifié
final userIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

final figureRepositoryProvider = Provider<FigureRepository?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;
  return FigureRepository(
    firestore: ref.watch(firestoreProvider),
    userId: userId,
  );
});

final trainingDoneRepositoryProvider = Provider<TrainingDoneRepository?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;
  return TrainingDoneRepository(
    firestore: ref.watch(firestoreProvider),
    userId: userId,
  );
});

final trainingPlannedRepositoryProvider = Provider<TrainingPlannedRepository?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;
  return TrainingPlannedRepository(
    firestore: ref.watch(firestoreProvider),
    userId: userId,
  );
});

final journalEntryRepositoryProvider = Provider<JournalEntryRepository?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;
  return JournalEntryRepository(
    firestore: ref.watch(firestoreProvider),
    userId: userId,
  );
});