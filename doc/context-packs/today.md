# Context Pack — Kalis: Today Tab

## Overview

The Today tab is the daily execution interface. It shows figures planned for today (from the Planning tab) and lets the user mark them as done, add session notes, inspect recent journal entries, open the Renfo dialog with a long press, and log records.

---

## Component Tree

```
TodayScreen
├── GestureDetector (onLongPress)
│   └── opens TodayRenfoDialog when Renfo button is active
├── SliverAppBar
└── Body (one of four states):
    ├── loading  → CircularProgressIndicator
    ├── empty    → "No figures today" banner (todayFiguresProvider returns [])
    ├── allDone  → "Excellent, all done!" green banner
    └── normal   → SliverGrid (3 columns)
                   └── FigureSquareCard × N
                       ├── tap          → TodayTrainingDialog
                       ├── long-press   → cancel done if marked, or show last journal note
                       └── screen long-press → TodayRenfoDialog
```

**Dialogs:**

| Dialog | Trigger | Purpose |
|---|---|---|
| `TodayTrainingDialog` | Tap FigureSquareCard | Validate training + add/edit note + promote/record |
| `RecordFormDialog` | 🏆 button inside TodayTrainingDialog | Set recordValue + recordUnit |
| `LastJournalEntryDialog` | External (e.g. from Figures tab) | Read-only view of latest note + record |

---

## Key Business Rules

**Marking done**: tapping a figure opens `TodayTrainingDialog`; clicking "Validate" creates a `TrainingDoneModel`. The note field is optional — if empty, no `JournalEntryModel` is created.

**Background long-press**: `TodayScreen` wraps the body in a `GestureDetector` and opens `TodayRenfoDialog` on `onLongPress` when renfo sessions are available. This is separate from the card-level interactions.

**Cancelling done**: long-press on a done figure calls `trainingDoneRepository.delete(figureId, today)`. Does **not** delete the journal entry.

**Reading the last journal entry**: long-press on a not-done figure opens `LastJournalEntryDialog` so the user can review the latest note without leaving the Today tab.

**One journal entry per figure per day**: `TodayTrainingDialog` reads `todayJournalEntryForFigureProvider(figureId)` on open. If an entry exists it pre-fills the text field and stores `_existingEntry`. It also reads `journalEntriesForFigureProvider(figureId)` to show the latest entry above the field. On validate: calls `update()` if `_existingEntry != null`, `create()` otherwise.

**Promotion to `learned`** (⭐ button, visible only when `figure.state == learning`):
- Shows a confirmation dialog.
- On confirm: `figureRepository.update(figure.copyWith(state: learned, endDate: today))`.
- Does **not** automatically validate the training — user still clicks "Validate" separately.
- After promotion the ⭐ button is replaced by 🏆.

**Record** (🏆 button, visible only when `figure.state == learned`):
- Opens `RecordFormDialog`.
- Saves `figure.copyWith(recordValue, recordUnit)`.
- `TodayTrainingDialog` stays open after record is saved.

**`allDone` banner**: shown when `figures.isNotEmpty && figures.every((f) => doneIds.contains(f.id))`.

---

## Validate Flow (TodayTrainingDialog)

On "Validate" tap:
1. `trainingDoneRepository.add(TrainingDoneModel(figureId, today))`
2. If `text.trim().isNotEmpty`:
   - `_existingEntry != null` → `journalRepository.update(existingEntry.copyWith(text))`
   - `_existingEntry == null` → `journalRepository.create(JournalEntryModel(figureId, today, text))`
3. Dialog closes.

---

## Providers Used in This Tab

| Provider | Role |
|---|---|
| `todayProvider` | Single source of truth for today's date |
| `todayFiguresProvider` | FigureModels planned for today |
| `todayDoneProvider` | TrainingDoneModels for today |
| `todayDoneIdsProvider` | Set\<String\> of done figureIds today |
| `isFigureDoneTodayProvider(figureId)` | Bool — is a given figure done today |
| `todayJournalEntryForFigureProvider(figureId)` | Today's JournalEntry for a figure (nullable) |
| `journalEntriesForFigureProvider(figureId)` | All entries for a figure (used in LastJournalEntryDialog) |

---

## Repositories Called

| Repository | Methods |
|---|---|
| `TrainingDoneRepository` | `add`, `delete`, `watchByDate` |
| `JournalEntryRepository` | `create`, `update`, `watchByFigureAndDate`, `watchByFigure` |
| `FigureRepository` | `update` (state promotion + record) |

---

## Cross-Tab Interactions

- **Planning → Today**: `todayFiguresProvider` is a filtered view of `planningProvider` for today. Adding a figure to today in Planning immediately appears here.
- **Today → Figures**: promoting a figure writes to the `figures` collection; `figuresProvider` picks it up and the Figures tab reflects the change.
- **Today → Records**: each "Validate" creates a `TrainingDoneModel` that feeds the Records tab history.