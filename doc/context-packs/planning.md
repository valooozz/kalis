# Context Pack — Kalis: Planning Tab

## Overview

The Planning tab manages a **14-day rolling window** of training sessions (today + 13 days ahead). Users add/remove figures to each day, start learning new figures directly from the planner, and consult the past 14 days of history.

---

## Component Tree

```
PlanningScreen
├── SliverAppBar
│   └── Action: PastPlanningDialog (history)
└── CustomScrollView  (14 days, sticky headers)
    └── per day:
        ├── _DayHeader (SliverPersistentHeader — sticks on scroll)
        ├── FigureSquareCard × N  (tap → TrainingDatesDialog, long-press → remove)
        └── _AddFigureButton [+]  → AddFigureToDayDialog
                                       └── (if toLearn figure tapped) BeginLearningDialog
```

**Dialogs:**
| Dialog | Trigger | Purpose |
|---|---|---|
| `AddFigureToDayDialog` | [+] button | Pick an available figure to add to a day |
| `BeginLearningDialog` | Tap a `toLearn` figure in AddFigureToDayDialog | Transition a `toLearn` figure to `learning` + add to plan, or resume a `paused` figure + add to plan |
| `TrainingDatesDialog` | Tap a `FigureSquareCard` | Show last/next training dates for that figure |
| `PastPlanningDialog` | 📜 icon in AppBar | Browse the past 14 days |

---

## Data Models

```dart
TrainingPlannedModel { figureId: String, date: DateTime }
// Firestore: /users/{uid}/training_planned/{id}
```

Relevant `FigureModel` fields: `state`, `startDate`, `paused`, `order`.

---

## Key Business Rules

**14-day window**: `planningProvider` streams `TrainingPlannedModel` for `[today, today + 13]`.

**Removing a figure** (long-press): deletes both `TrainingPlanned` *and* `TrainingDone` for that figure+date if both exist.

**`availableFiguresForDayProvider(date)`** — figures eligible to add to a given day:
- Excludes figures already planned that day.
- Excludes `paused` figures.
- Excludes `learned` figures unless `showLearnedProvider == true`.
- Sorted by `effectiveLastTrainingDate` ascending (least recently trained first).

**`showLearnedProvider`**: bool persisted in SharedPreferences (`showLearnedFigures` key). Toggled via checkbox in `AddFigureToDayDialog`.

**`BeginLearningDialog`** vs starting learning from the Figures tab:
| Entry point | `startDate` | Auto-adds to plan |
|---|---|---|
| `BeginLearningDialog` — `toLearn` figure (Planning tab) | The selected planning date | ✅ Yes |
| `BeginLearningDialog` — `paused` figure (Planning tab) | Unchanged | ✅ Yes |
| "Start learning" in `FigureDetailDialog` (Figures tab) | Today | ❌ No |

`BeginLearningDialog` performs two writes depending on the figure type:

**`toLearn` figure:**
1. `figureRepository.update(figure.copyWith(state: learning, startDate: date, order: newOrder))`
2. `trainingPlannedRepository.add(TrainingPlannedModel(figureId, date))`

**`paused` figure:**
1. `figureRepository.update(figure.copyWith(paused: false))`
2. `trainingPlannedRepository.add(TrainingPlannedModel(figureId, date))`

---

## Date Calculation Providers

**`effectiveLastTrainingDateProvider({figureId, date})`**
Combines actual done dates with planned dates that fall between today and the target date, returning the most recent. Used in `TrainingDatesDialog` and to sort `availableFiguresForDayProvider`.

**`nextTrainingDateAfterDayProvider({figureId, date})`**
Returns the first `TrainingPlanned.date` strictly after the target date. Used in `TrainingDatesDialog`.

Both display results as relative strings ("yesterday", "in 3 days").

---

## Past Planning (PastPlanningDialog)

- Shows 14 days before today (yesterday → -14 days).
- For each day: reads `figuresForPastDateProvider(date)` (planned figures) and `trainingDoneForDateProvider(date)` (done IDs).
- `FigureSquareCard` receives `isDone: doneIds.contains(figure.id)` to render a ✅ overlay.

---

## Providers Used in This Tab

| Provider | Role |
|---|---|
| `planningProvider` | Stream of all `TrainingPlannedModel` for the 14-day window |
| `plannedForDayProvider(date)` | Planned entries for one day |
| `figuresForDayProvider(date)` | Full `FigureModel` list for planned entries on a day |
| `availableFiguresForDayProvider(date)` | Figures eligible to add to a day (filtered + sorted) |
| `pausedFiguresProvider` | All paused figures across all states (no color filter) |
| `showLearnedProvider` | Checkbox state, persisted in SharedPreferences |
| `effectiveLastTrainingDateProvider({figureId, date})` | Last training date (done + planned) |
| `trainingPlannedForFigureProvider(figureId)` | All planned entries for one figure |
| `nextTrainingDateAfterDayProvider({figureId, date})` | Next planned date after a given day |
| `figuresForPastDateProvider(date)` | Planned figures for a past date |
| `trainingDoneForDateProvider(date)` | Done figure IDs for a past date |
| `todayProvider` | Single source of truth for today's date |

---

## Repositories Called

| Repository | Methods |
|---|---|
| `TrainingPlannedRepository` | `watchByDateRange`, `add`, `delete`, `watchByFigure` |
| `TrainingDoneRepository` | `watchByDate`, `delete` |
| `FigureRepository` | `update` (state transition in BeginLearningDialog) |

---

## Reusable Widgets

**`FigureSquareCard`** (`widgets/figure_square_card.dart`)
```dart
FigureSquareCard({
  required FigureModel figure,
  required VoidCallback onTap,
  required VoidCallback onLongPress,
  bool isDone = false,        // renders ✅ overlay
  bool showStateIcon = true,  // shows learning/learned icon
})
```

---

## Cross-Tab Interactions

- **Planning → Today**: `todayFiguresProvider` is a subset of `planningProvider` for today. Adding a figure to today in Planning immediately appears in the Today tab.
- **Planning → Figures**: `BeginLearningDialog` writes to the `figures` collection; `figuresProvider` picks it up and the Figures tab reflects the state change.
- **Planning → Records**: both read from `trainingDone`; Planning shows a simplified past view while Records shows the full history.