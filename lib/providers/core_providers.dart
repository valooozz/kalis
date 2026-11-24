import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/figure_repository.dart';
import '../repositories/training_done_repository.dart';
import '../repositories/training_planned_repository.dart';
import '../repositories/journal_entry_repository.dart';
import '../repositories/place_repository.dart';
import '../repositories/general_note_repository.dart';
import '../repositories/weekly_activities_repository.dart';
import '../repositories/renfo_repository.dart';
import '../repositories/renfo_done_repository.dart';

const helpBubblesEnabledKey = 'help_bubbles_enabled';
const appLocaleKey = 'app_locale';

class AppLocaleNotifier extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(appLocaleKey);
    if (languageCode != 'fr' && languageCode != 'en') return null;
    return Locale(languageCode!);
  }

  Future<void> setLocale(Locale locale) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(appLocaleKey, locale.languageCode);
    state = AsyncData(locale);
  }
}

final appLocaleProvider = AsyncNotifierProvider<AppLocaleNotifier, Locale?>(
  AppLocaleNotifier.new,
);

class HelpBubblesNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final preferences = await SharedPreferences.getInstance();
    state = preferences.getBool(helpBubblesEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(helpBubblesEnabledKey, enabled);
  }
}

final helpBubblesEnabledProvider = NotifierProvider<HelpBubblesNotifier, bool>(
  HelpBubblesNotifier.new,
);

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

// Provider pour les lieux (places)
final placeRepositoryProvider = Provider<PlaceRepository?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;
  return PlaceRepository(
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

final trainingPlannedRepositoryProvider = Provider<TrainingPlannedRepository?>((
  ref,
) {
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

final generalNoteRepositoryProvider = Provider<GeneralNoteRepository?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;
  return GeneralNoteRepository(
    firestore: ref.watch(firestoreProvider),
    userId: userId,
  );
});

final weeklyActivitiesRepositoryProvider =
    Provider<WeeklyActivitiesRepository?>((ref) {
      final userId = ref.watch(userIdProvider);
      if (userId == null) return null;
      return WeeklyActivitiesRepository(
        firestore: ref.watch(firestoreProvider),
        userId: userId,
      );
    });

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final isLinkedToGoogleProvider = Provider<bool>((ref) {
  // On force la relecture à chaque changement d'auth
  ref.watch(authStateProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  return user.providerData.any((p) => p.providerId == 'google.com');
});

final renfoRepositoryProvider = Provider<RenfoRepository?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;
  return RenfoRepository(
    firestore: ref.watch(firestoreProvider),
    userId: userId,
  );
});

final renfoDoneRepositoryProvider = Provider<RenfoDoneRepository?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;
  return RenfoDoneRepository(
    firestore: ref.watch(firestoreProvider),
    userId: userId,
  );
});
