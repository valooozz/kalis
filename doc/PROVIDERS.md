# Documentation des providers

Ce document décrit les providers présents dans `lib/providers` : leur utilité, les données exposées, et les dépendances entre eux.

## Vue d'ensemble
- Les providers sont implémentés avec `flutter_riverpod`.
- `core_providers.dart` contient les providers de bas niveau (accès à Firebase, repositories, authentification) et constitue la racine du graphe de dépendances.
- Les autres fichiers (`figure_providers.dart`, `planning_providers.dart`, `today_providers.dart`, `journal_providers.dart`, `filter_providers.dart`) s'appuient principalement sur ces providers de base et entre eux.

---

## core_providers.dart
- firestoreProvider : instance de `FirebaseFirestore`.
- firebaseAuthProvider : instance de `FirebaseAuth`.
- authStateProvider : `StreamProvider<User?>` exposant l'état d'authentification.
- userIdProvider : `Provider<String?>` retournant l'UID courant ou `null`.
- figureRepositoryProvider : `Provider<FigureRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
- trainingDoneRepositoryProvider : `Provider<TrainingDoneRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
- trainingPlannedRepositoryProvider : `Provider<TrainingPlannedRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
- journalEntryRepositoryProvider : `Provider<JournalEntryRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
- googleSignInProvider : `Provider<GoogleSignIn>`.
- isLinkedToGoogleProvider : `Provider<bool>` qui observe `authStateProvider`.

Rôle principal : fournir les points d'entrée vers Firestore/Auth et les repositories réutilisables par les autres providers.

---

## filter_providers.dart
- colorFilterProvider : `StateProvider<FigureColor?>` (null = pas de filtre).

Utilisé par `figure_providers.dart` pour filtrer la liste des figures selon une couleur sélectionnée.

---

## figure_providers.dart
Providers exposés et dépendances principales :
- `figuresProvider` (StreamProvider<List<FigureModel>>) : lit `figureRepositoryProvider` et `colorFilterProvider` pour renvoyer la liste des figures (filtrage & tri).
- `figuresByStateProvider` : dérivé de `figuresProvider` (filtre par `FigureState`).
- `figureByIdProvider` : dérivé de `figuresProvider` (recherche par id).
- `lastTrainingDateProvider` : dépend de `trainingDoneRepositoryProvider` (renvoie la dernière date d'entraînement effectué pour une figure).
- `nextTrainingDateProvider` : dépend de `trainingPlannedRepositoryProvider` et `todayProvider` (renvoie la prochaine date planifiée, incluant aujourd'hui).
- `nextTrainingDateAfterTodayProvider` & `nextTrainingDateAfterDayProvider` : variantes qui utilisent `trainingPlannedRepositoryProvider` et `todayProvider` ou une date cible.
- `figureOrderProvider` : fournit un `FigureOrderNotifier` pour modifier l'ordre via `FigureRepository`.
- `trainingDoneDatesProvider` / `trainingPlannedDatesProvider` : listes de dates pour une figure à partir des repositories correspondants.
- `allTrainingDoneDatesProvider` / `allTrainingPlannedDatesProvider` : agrègent pour toutes les figures ; dépendent de `figuresProvider` et des repositories `trainingDone` / `trainingPlanned`.

Remarque : `figure_providers.dart` est un consommateur majeur des repositories définis dans `core_providers.dart` et du filtre couleur.

---

## planning_providers.dart
Providers et responsabilités :
- `ShowLearnedNotifier` / `showLearnedProvider` : persistance via `SharedPreferences` d'une option utilisateur (`showLearnedFigures`).
- `planningProvider` : `StreamProvider<List<TrainingPlannedModel>>` sur 14 jours — dépend de `trainingPlannedRepositoryProvider` et `todayProvider`.
- `plannedForDayProvider` : dérivé de `planningProvider` (filtre par date).
- `figuresForDayProvider` : combine `plannedForDayProvider` et `figuresProvider` pour fournir les `FigureModel` planifiées.
- `effectiveLastTrainingDateProvider` : calcule la date effective du dernier entraînement en combinant `lastTrainingDateProvider` et `trainingPlannedForFigureProvider` (et `todayProvider`).
- `trainingPlannedForFigureProvider` : stream des `TrainingPlannedModel` pour une figure (dep. repo).
- `availableFiguresForDayProvider` : logique métier pour sélectionner et trier les figures disponibles un jour donné ; dépend de `figuresProvider`, `plannedForDayProvider`, `showLearnedProvider`, `effectiveLastTrainingDateProvider`, et `nextTrainingDateAfterDayProvider`.
- `trainingDoneForDateProvider`, `plannedForPastDateProvider`, `figuresForPastDateProvider` : providers utilitaires basés sur les repositories.

Ces providers contiennent une logique métier importante pour le planning et utilisent largement d'autres providers pour agréger les données.

---

## today_providers.dart
- `todayProvider` : `Provider<DateTime>` exposant la date du jour sans l'heure.
- `todayPlannedProvider` / `todayDoneProvider` : streams des entraînements planifiés et effectués aujourd'hui (dépendent des repositories et `todayProvider`).
- `todayFiguresProvider` : figures planifiées aujourd'hui (combine `todayPlannedProvider` et `figuresProvider`).
- `todayDoneIdsProvider` : ids des figures travaillées aujourd'hui.
- `isFigureDoneTodayProvider` : bool par figure selon `todayDoneIdsProvider`.

Usage : centraliser la logique liée à « aujourd'hui » et fournir des informations rapides aux écrans/journaux.

---

## journal_providers.dart
- `journalEntriesForFigureProvider` : `StreamProvider.family<List<JournalEntryModel>, String>` — dépend de `journalEntryRepositoryProvider`.
- `todayJournalEntryForFigureProvider` : récupère l'entrée de journal pour une figure et la date `todayProvider`.

---

## Graphe de dépendances (résumé)
- `core_providers.dart` (racine)
  - fournit : firestore, auth, repositories (figure, training done/planned, journal)
- `filter_providers.dart`
  - utilisé par : `figure_providers.dart`
- `today_providers.dart`
  - utilisé par : `figure_providers.dart`, `planning_providers.dart`, `journal_providers.dart`
- `figure_providers.dart`
  - consomme : `core_providers`, `filter_providers`, `today_providers`
  - fourni à : `planning_providers.dart`, `today_providers.dart`, composants UI
- `planning_providers.dart`
  - consomme : `core_providers`, `figure_providers`, `today_providers`, `filter_providers` (indirectement)
- `journal_providers.dart`
  - consomme : `core_providers`, `today_providers`
