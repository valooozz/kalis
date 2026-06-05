# Context Pack — Kalis: Figures Tab

## Overview

The Figures tab is the central module of Kalis. It manages the full portfolio of calisthenics moves (*figures*): CRUD, state transitions, journal notes, records, calendar views, color filtering, and manual reordering.

---

## Component Tree

```
FiguresScreen
├── SliverAppBar
│   └── Actions: ColorFilterDialog, GlobalCalendarDialog, → RecordsScreen, → SettingsScreen
├── CustomScrollView
│   └── _FigureSection × 3  (one per FigureState, sticky headers)
│       └── _FigureSliver  (ReorderableListView, drag-and-drop within section)
│           └── FigureCard (tap → FigureDetailDialog)
└── FAB (+) → FigureFormDialog (create mode)
```

**Modal dialogs** (pushed as sub-routes):

| Dialog | Trigger | Purpose |
|---|---|---|
| `FigureFormDialog` | FAB or edit button | Create / edit name, color, dates, record |
| `FigureDetailDialog` | Tap FigureCard | View details, journal, state actions |
| `FigureStatusPickerDialog` | 🔧 icon in FigureDetailDialog | Change FigureState |
| `FigureCalendarDialog` | 📅 icon in FigureDetailDialog | Per-figure training calendar |
| `GlobalCalendarDialog` | 📅 icon in AppBar | All-figures training calendar |
| `JournalEntryFormDialog` | [+] in FigureDetailDialog | Create / edit a journal entry |
| `RecordFormDialog` | Tap RecordDisplay in FigureDetailDialog | Set recordValue + recordUnit |
| `BeginLearningDialog` | "Start learning" btn (toLearn figure) | Confirm transition to learning |

---

## FigureModel — Fields & Enums

```dart
FigureModel { id, name, color, state, startDate, endDate, recordValue, recordUnit, order, paused }

FigureState  { toLearn, learning, learned }
FigureColor  { red, orange, yellow, green, blue, purple }
RecordUnit   { reps, seconds }
```

Default on create: `state = toLearn`, `paused = false`, all date/record fields null.

---

## State Transition Rules

| From → To | Side effects |
|---|---|
| toLearn → learning | Set `startDate = today` |
| learning → learned | Set `endDate = today` |
| learned → learning | Clear `endDate` |
| any → toLearn | Clear `startDate`, `endDate`, delete all associated `TrainingPlanned` docs |

Transitions are triggered from `FigureStatusPickerDialog`, which calls `figureRepository.update(figure.copyWith(...))`.

---

## Business Rules

**Journal**
- One `JournalEntryModel` per figure per day maximum.
- The [+] button in `FigureDetailDialog` is hidden if an entry already exists for today (checked via `todayJournalEntryForFigureProvider`).
- Entries displayed sorted by date descending.

**Record**
- Only accessible when `figure.state == learned`.
- Stores a single best value (`recordValue: int`) + unit (`recordUnit`).
- Edited via `RecordFormDialog`, saved as `figure.copyWith(recordValue, recordUnit)`.

**Pause**
- `paused` is a bool on `FigureModel`, toggled from the ⏸️/▶️ icon in `FigureDetailDialog`.
- Paused figures are hidden from planning/today views (enforced in those providers, not here).

**Ordering**
- Figures are grouped by `FigureState` (toLearn → learning → learned), then sorted by `order` field within each group.
- `ReorderableListView` in `_FigureSliver` allows drag-and-drop reorder within a section.
- Drop triggers `figureOrderProvider` (a `FigureOrderNotifier`) which batch-updates the `order` field via `figureRepository.updateOrder()`.

**Color filter**
- `colorFilterProvider` (StateProvider\<FigureColor?\>) — null means no filter.
- Filter is applied in `figuresProvider` before the stream reaches the UI.
- `ColorFilterDialog` sets/clears this provider.

**Deletion cascade**
- Deleting a figure removes all associated `JournalEntryModel`, `TrainingDoneModel`, and `TrainingPlannedModel` documents (handled in `FigureRepository.delete()`).

---

## Providers Used in This Tab

| Provider | Source file | Role |
|---|---|---|
| `figuresProvider` | figure_providers | All figures, filtered + sorted |
| `figuresByStateProvider` | figure_providers | Figures per FigureState section |
| `figureByIdProvider` | figure_providers | Single figure lookup |
| `figureOrderProvider` | figure_providers | Reorder notifier |
| `colorFilterProvider` | filter_providers | Active color filter |
| `trainingDoneDatesProvider` | figure_providers | Done dates for one figure (calendar) |
| `trainingPlannedDatesProvider` | figure_providers | Planned dates for one figure (calendar) |
| `allTrainingDoneDatesProvider` | figure_providers | Done dates for all figures (global calendar) |
| `allTrainingPlannedDatesProvider` | figure_providers | Planned dates for all figures (global calendar) |
| `lastTrainingDateProvider` | figure_providers | Last done date for FigureCard display |
| `nextTrainingDateProvider` | figure_providers | Next planned date for FigureCard display |
| `journalEntriesForFigureProvider` | journal_providers | All journal entries for a figure |
| `todayJournalEntryForFigureProvider` | journal_providers | Today's entry (controls [+] visibility) |

---

## Repositories Called

| Repository | Methods called from this tab |
|---|---|
| `FigureRepository` | `watchAll`, `create`, `update`, `delete`, `updateOrder` |
| `JournalEntryRepository` | `create`, `update`, `delete`, `watchByFigure` |
| `TrainingDoneRepository` | `watchByFigure` |
| `TrainingPlannedRepository` | `watchByFigure` |

---

## Calendar Logic

**FigureCalendarDialog** (per-figure):
- Reads `trainingDoneDatesProvider(figureId)` and `trainingPlannedDatesProvider(figureId)`.
- Done day → filled circle in figure's color. Planned day → outline circle in figure's color.

**GlobalCalendarDialog** (all figures):
- Reads `allTrainingDoneDatesProvider` and `allTrainingPlannedDatesProvider` → `Map<DateTime, List<Color>>`.
- Renders up to 5 colored dots per day (one per figure). Done = filled, planned = outline.
- If a figure is both done and planned on the same day, show only the done dot.

---

## Reusable Widgets

| Widget | File | Props summary |
|---|---|---|
| `FigureCard` | widgets/figure_card.dart | `figure`, `onTap`, `referenceDate?`, `inkEffect` |
| `ColorPickerRow` | widgets/color_picker_row.dart | `selected`, `onChanged` |
| `JournalEntryTile` | widgets/journal_entry_tile.dart | `entry`, `onEdit`, `onDelete` |
| `RecordDisplay` | widgets/record_display.dart | `figure` (reads recordValue + recordUnit) |

---

## Error Handling

- All async data consumed via `AsyncValue.when(loading, error, data)`.
- If a repository is null (unauthenticated), CRUD calls fail silently; UI stays in loading state until auth resolves.