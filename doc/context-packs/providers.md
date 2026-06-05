# Context Pack — Kalis Providers

## Overview

All state management uses `flutter_riverpod`. Providers live in `lib/providers/` split across six files. `core_providers.dart` is the root of the dependency graph — all other providers ultimately depend on it.

Repositories are **nullable** (`FigureRepository?`, etc.) because `userIdProvider` returns `null` when unauthenticated. Feature providers must guard against null repos.

---

## Dependency Graph

```
core_providers          firestore, auth, userId, all repositories
    │
    ├── filter_providers        colorFilterProvider (StateProvider)
    │       │
    ├── today_providers         todayProvider (DateTime, no time component)
    │       │                   todayPlanned/Done/Figures, isFigureDoneToday
    │       │
    ├── figure_providers  ◄─────┤ (consumes filter + today + core)
    │       │               figures list, byState, byId, order, training dates
    │       │
    ├── planning_providers ◄────┤ (consumes figure + today + core)
    │       │               14-day window, availableFiguresForDay, showLearned pref
    │       │
    └── journal_providers ◄─────┤ (consumes today + core)
                            journal entries per figure
```

---

## core_providers.dart

| Provider | Type | Description |
|---|---|---|
| `firestoreProvider` | Provider | FirebaseFirestore instance |
| `firebaseAuthProvider` | Provider | FirebaseAuth instance |
| `authStateProvider` | StreamProvider\<User?\> | Auth state stream |
| `userIdProvider` | Provider\<String?\> | Current UID or null |
| `figureRepositoryProvider` | Provider\<FigureRepository?\> | Null if not authenticated |
| `trainingDoneRepositoryProvider` | Provider\<TrainingDoneRepository?\> | Null if not authenticated |
| `trainingPlannedRepositoryProvider` | Provider\<TrainingPlannedRepository?\> | Null if not authenticated |
| `journalEntryRepositoryProvider` | Provider\<JournalEntryRepository?\> | Null if not authenticated |
| `googleSignInProvider` | Provider | GoogleSignIn instance |
| `isLinkedToGoogleProvider` | Provider\<bool\> | Watches authStateProvider |

---

## filter_providers.dart

| Provider | Type | Description |
|---|---|---|
| `colorFilterProvider` | StateProvider\<FigureColor?\> | null = no filter |

Consumed only by `figuresProvider` to filter the figure list.

---

## today_providers.dart

| Provider | Type | Description |
|---|---|---|
| `todayProvider` | Provider\<DateTime\> | Today's date, time stripped |
| `todayPlannedProvider` | StreamProvider | TrainingPlannedModels for today |
| `todayDoneProvider` | StreamProvider | TrainingDoneModels for today |
| `todayFiguresProvider` | StreamProvider | FigureModels planned for today |
| `todayDoneIdsProvider` | StreamProvider\<List\<String\>\> | IDs of figures done today |
| `isFigureDoneTodayProvider` | Provider.family\<bool, String\> | Is a given figure done today |

`todayProvider` is the single source of truth for "today". Always read from it — never use `DateTime.now()` directly in other providers or UI.

---

## figure_providers.dart

| Provider | Type | Description |
|---|---|---|
| `figuresProvider` | StreamProvider\<List\<FigureModel\>\> | All figures, filtered by `colorFilterProvider`, sorted by `order` |
| `figuresByStateProvider` | StreamProvider.family\<…, FigureState\> | Subset of `figuresProvider` by state |
| `figureByIdProvider` | Provider.family\<FigureModel?, String\> | Derived from `figuresProvider` |
| `lastTrainingDateProvider` | FutureProvider.family | Last done date for a figure (via trainingDoneRepo) |
| `nextTrainingDateProvider` | FutureProvider.family | Next planned date ≥ today |
| `nextTrainingDateAfterTodayProvider` | FutureProvider.family | Next planned date strictly after today |
| `nextTrainingDateAfterDayProvider` | FutureProvider.family | Next planned date after a given date |
| `figureOrderProvider` | NotifierProvider | FigureOrderNotifier — writes order changes to FigureRepository |
| `trainingDoneDatesProvider` | StreamProvider.family | Done dates for one figure |
| `trainingPlannedDatesProvider` | StreamProvider.family | Planned dates for one figure |
| `allTrainingDoneDatesProvider` | StreamProvider | Aggregated done dates for all figures |
| `allTrainingPlannedDatesProvider` | StreamProvider | Aggregated planned dates for all figures |

---

## planning_providers.dart

Contains the heaviest business logic in the provider layer.

| Provider | Type | Description |
|---|---|---|
| `showLearnedProvider` | NotifierProvider\<bool\> | Persisted via SharedPreferences (`showLearnedFigures` key) |
| `planningProvider` | StreamProvider | All TrainingPlannedModels for the next 14 days from today |
| `plannedForDayProvider` | Provider.family\<…, DateTime\> | Subset of `planningProvider` for one day |
| `figuresForDayProvider` | Provider.family\<…, DateTime\> | FigureModels for planned entries on a day |
| `trainingPlannedForFigureProvider` | StreamProvider.family | TrainingPlannedModels stream for one figure |
| `effectiveLastTrainingDateProvider` | FutureProvider.family | Last done date, falling back to last planned date if no done record exists |
| `availableFiguresForDayProvider` | FutureProvider.family\<…, DateTime\> | Figures available to add to a given day — filters out already-planned, applies showLearned, sorts by effectiveLastTrainingDate |
| `trainingDoneForDateProvider` | StreamProvider.family | Done trainings for a past date |
| `plannedForPastDateProvider` | StreamProvider.family | Planned trainings for a past date |
| `figuresForPastDateProvider` | Provider.family | FigureModels for a past date |

Key logic in `availableFiguresForDayProvider`: excludes figures already planned on the target day, optionally hides `learned` figures (per `showLearnedProvider`), and sorts by `effectiveLastTrainingDate` ascending (least recently trained first).

---

## journal_providers.dart

| Provider | Type | Description |
|---|---|---|
| `journalEntriesForFigureProvider` | StreamProvider.family\<List\<JournalEntryModel\>, String\> | All entries for a figure, ordered by date desc |
| `todayJournalEntryForFigureProvider` | FutureProvider.family | Entry for a figure on today's date (may be null) |

---

## Conventions

- New feature providers should consume repositories from `core_providers` and date from `todayProvider`.
- Never call `DateTime.now()` inside a provider — always use `todayProvider`.
- Providers that aggregate across multiple figures (e.g. `allTrainingDoneDatesProvider`) depend on `figuresProvider` first to get the list of IDs, then fan out to per-figure streams.
- `.family` providers take a single typed parameter; pass a composite object or record if multiple parameters are needed.