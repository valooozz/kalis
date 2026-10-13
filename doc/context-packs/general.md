# Context Pack — Kalis (General)

## Overview

Kalis is a Flutter calisthenics tracking app. Users manage a portfolio of body-weight moves (*figures*), plan workouts over a 14-day window, and keep a personal progress journal. Data is persisted and synced in real time via Firebase Firestore. The app targets iOS, Android, Web and Desktop.

---

## Architecture

**MVVM + Repository Pattern**, four layers:

| Layer | Role | Tech |
|---|---|---|
| UI | Screens, dialogs, reusable widgets | Flutter, Material Design 3 |
| State | Reactive state, caching, business logic | Riverpod (StreamProvider / StateProvider) |
| Data Access | CRUD, Firestore abstraction | Custom Repositories |
| Backend | Persistence, real-time sync, auth | Firebase Firestore + Firebase Auth (anonymous + Google linking) |

Data flows bottom-up reactively: Firestore → Repository (Stream) → Riverpod Provider → Consumer Widget. Any Firestore write instantly propagates to all listening widgets.

---

## Data Models

```
FigureModel          id, name, color (FigureColor), state (FigureState),
                     startDate, endDate, recordValue, recordUnit, order, paused

JournalEntryModel    id, figureId, date, text

PlaceModel           id, name, figureIds

TrainingDoneModel    figureId, date

TrainingPlannedModel figureId, date
```

Key enums: `FigureState { toLearn, learning, learned }` · `FigureColor { red, orange, yellow, green, blue, purple }` · `RecordUnit { reps, seconds }`

The app also stores a user-level `generalNote` text in a dedicated Firestore document, not a model class.

---

## Repositories (Data Access Layer)

Each repository wraps one Firestore collection and exposes Streams + Futures.

- **FigureRepository** — watchAllFigures, addFigure, updateFigure, deleteFigure, getFigureById
- **PlaceRepository** — watchAll, getById, create, update, delete
- **TrainingDoneRepository** — addTrainingDone, watchAllTrainingsDone, watchTrainingsDoneForDate
- **TrainingPlannedRepository** — planTraining, watchTrainingsPlanedForDateRange
- **JournalEntryRepository** — addJournalEntry, watchJournalEntriesForFigure, getLatestJournalEntryForFigure
- **GeneralNoteRepository** — watch, save for the single user-level note

Repositories are provided via Riverpod and injected into feature providers.

---

## State Management (Riverpod Providers)

Providers are defined in `lib/providers/`. Key providers:

| Provider | Type | Description |
|---|---|---|
| `figuresProvider` | StreamProvider | All figures, respects active color filter |
| `figuresByStateProvider` | StreamProvider.family | Figures filtered by FigureState |
| `todayPlannedProvider` | StreamProvider | Figures planned for today |
| `todayDoneProvider` | StreamProvider | Figures completed today |
| `planningProvider` | StreamProvider | Planned trainings for the 14-day window |
| `journalEntriesForFigureProvider` | StreamProvider.family | Journal entries for one figure |
| `placesProvider` | StreamProvider | Places for the current user, sorted by name |
| `generalNoteProvider` | StreamProvider | User-level general note text |
| `colorFilterProvider` | StateProvider | Active color filter (nullable FigureColor) |
| `isLinkedToGoogleProvider` | Provider | Whether the anonymous Firebase user is linked to Google |

---

## Navigation (Go Router)

The `MainScreen` hosts a `BottomNavigationBar` with 3 tabs:

```
/figures     FiguresScreen     — figure portfolio
/today       TodayScreen       — today's session
/planning    PlanningScreen    — 14-day planner
```

Additional app screens are full-page routes outside the tab shell:

```
/places      PlacesScreen      — training locations
/records     RecordsScreen     — training history
/settings    SettingsScreen    — auth & preferences
```

Modal dialogs are still used for figure, place, journal, record and note forms.

---

## Project Structure (lib/)

```
core/        router, theme, date utils
models/      FigureModel, JournalEntryModel, PlaceModel, TrainingDoneModel, TrainingPlannedModel
repositories/ one file per model plus general note repository
providers/   core_providers, figure_providers, place_providers,
             general_note_providers, journal_providers,
             today_providers, planning_providers, filter_providers
screens/     main/, today/, planning/, figures/, places/, records/, settings/
widgets/     figure_card, figure_square_card, journal_entry_tile,
             place_card, color_picker_row, color_filter_dialog,
             date_row, record_display
l10n/        French only (app_fr.arb)
```

---

## Key Conventions

- All user-facing strings are localised via Flutter's `.arb` system (French only for now).
- Firestore documents are namespaced per authenticated user (anonymous auth by default; Google linking is optional).
- `order` field on `FigureModel` drives manual sorting in the figure list.
- A figure can be `paused`, which hides it from active planning/today views.
- The app signs in anonymously on startup if no Firebase user exists, and the settings screen can link that account to Google.