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
- placeRepositoryProvider : `Provider<PlaceRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
- trainingDoneRepositoryProvider : `Provider<TrainingDoneRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
- trainingPlannedRepositoryProvider : `Provider<TrainingPlannedRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
- journalEntryRepositoryProvider : `Provider<JournalEntryRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
- generalNoteRepositoryProvider : `Provider<GeneralNoteRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
- weeklyActivitiesRepositoryProvider : `Provider<WeeklyActivitiesRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
- renfoRepositoryProvider : `Provider<RenfoRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
- renfoDoneRepositoryProvider : `Provider<RenfoDoneRepository?>` dépendant de `firestoreProvider` et `userIdProvider`.
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
- `figuresProvider` (StreamProvider<List<FigureModel>>) : lit `figureRepositoryProvider` et `colorFilterProvider` pour renvoyer uniquement les figures actives (filtrage & tri).
- `archivedFiguresProvider` (StreamProvider<List<FigureModel>>) : lit toutes les figures et ne conserve que celles dont `archived == true`.
- `figuresByStateProvider` : dérivé de `figuresProvider` (filtre par `FigureState`).
- `figureByIdProvider` : dérivé de `figuresProvider` (recherche par id).
- `lastTrainingDateProvider` : dépend de `trainingDoneRepositoryProvider` (renvoie la dernière date d'entraînement effectué pour une figure).
- `nextTrainingDateProvider` : dépend de `trainingPlannedRepositoryProvider` et `todayProvider` (renvoie la prochaine date planifiée, incluant aujourd'hui).
- `nextTrainingDateAfterTodayProvider` & `nextTrainingDateAfterDayProvider` : variantes qui utilisent `trainingPlannedRepositoryProvider` et `todayProvider` ou une date cible.
- `figureOrderProvider` : fournit un `FigureOrderNotifier` pour modifier l'ordre via `FigureRepository`.
- `trainingDoneDatesProvider` / `trainingPlannedDatesProvider` : listes de dates pour une figure à partir des repositories correspondants.
- `allTrainingDoneDatesProvider` / `allTrainingPlannedDatesProvider` : agrègent pour toutes les figures ; dépendent de `figuresProvider` et des repositories `trainingDone` / `trainingPlanned`.
- `allFiguresProvider` : stream de toutes les figures, sans exclusion des figures archivées ni filtre couleur.
- `nextFigureOrderProvider` / `previousFigureOrderProvider` : calculent les ordres suivant/précédent pour une catégorie depuis le cache de toutes les figures.

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

## place_providers.dart
- `placesProvider` : `StreamProvider<List<PlaceModel>>` — lit `placeRepositoryProvider` et renvoie les lieux triés par nom.
- `placeByIdProvider` : `Provider.family<AsyncValue<PlaceModel?>, String>` — retourne le lieu correspondant à un identifiant.

## general_note_providers.dart
- `generalNoteProvider` : `StreamProvider<String>` — lit `generalNoteRepositoryProvider` et expose le texte de la note générale utilisateur.

---

## weekly_activities_providers.dart
- `weeklyActivitiesProvider` : `StreamProvider<WeeklyActivitiesModel>` lit `weeklyActivitiesRepositoryProvider` et retourne un modèle vide si l'utilisateur ou la ressource n'est pas disponible.

Le document surveillé est `users/{uid}/weeklyActivities/main`.

---

## renfo_providers.dart

- `renfosProvider` : stream des renfos triés par nom.
- `renfoDoneAllProvider` : stream de toutes les validations de renfo.
- `renfoDoneDatesProvider` : dates de validation pour un renfo donné.
- `renfoLastDoneDatesProvider` : dernière date d'exécution du renfo ou de ses figures associées, hors date du jour.
- `todayRenfoItemsProvider` : renfos disponibles aujourd'hui avec leur alerte et leur statut effectué.
- `renfoButtonStateProvider` : état visuel `hidden`, `red`, `green` ou `grey` du bouton Today.

L'alerte utilise un seuil de 4 jours. La date du jour est exclue du calcul de la dernière exécution afin qu'une validation récente ne masque pas un retard réel.

---

## Écritures Firestore détachées

Les écrans utilisent `core/utils/firestore_write_utils.dart` pour lancer les mutations Firestore sans attendre leur fin avant de fermer le dialogue. `detachFirestoreWrite()` exécute l'écriture en tâche détachée et rapporte les erreurs via `FlutterError.reportError` avec le contexte de l'opération. Les échecs restent donc visibles dans les diagnostics sans bloquer la fermeture immédiate de l'interface.

---

## Graphe de dépendances (résumé)
- `core_providers.dart` (racine)
  - fournit : firestore, auth, repositories (figure, place, training done/planned, journal, general note)
- `filter_providers.dart`
  - utilisé par : `figure_providers.dart`
- `today_providers.dart`
  - utilisé par : `figure_providers.dart`, `planning_providers.dart`, `journal_providers.dart`
- `figure_providers.dart`
  - consomme : `core_providers`, `filter_providers`, `today_providers`
  - fourni à : `planning_providers.dart`, `today_providers.dart`, composants UI
- `place_providers.dart`
  - consomme : `core_providers`
  - fourni à : écrans de gestion des lieux
- `general_note_providers.dart`
  - consomme : `core_providers`
  - fourni à : dialogue de note générale dans `figures`
- `planning_providers.dart`
  - consomme : `core_providers`, `figure_providers`, `today_providers`, `filter_providers` (indirectement)
- `journal_providers.dart`
  - consomme : `core_providers`, `today_providers`
