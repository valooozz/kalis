# Context Pack — Kalis: Records Tab

## Overview

Read-only screen. Lists all `learned` figures that have a record set (`recordValue != null && recordUnit != null`). Figures without a record are silently excluded.

---

## Component Tree

```
RecordsScreen
└── SliverList
    └── _RecordCard × N  (one per learned figure with a record)
```

No dialogs, no write actions. Navigation entry point: 🏆 icon in the Figures tab AppBar.

---

## Display Logic

```dart
figuresByStateProvider(FigureState.learned)
  → for each figure:
      if (recordValue == null || recordUnit == null) → SizedBox.shrink()
      else → _RecordCard(figure)
```

`_RecordCard` shows: figure name, left+right border in figure's color, and the record formatted as `"{recordValue} {recordUnit.getUnit(recordValue)}"`.

Unit formatting (pluralization):
- `RecordUnit.reps`    → "répétition" / "répétitions"
- `RecordUnit.seconds` → "seconde" / "secondes"

---

## Providers & Repositories

| | |
|---|---|
| Provider | `figuresByStateProvider(FigureState.learned)` |
| Repository | `FigureRepository.watchAll()` (read only) |

---

## Cross-Tab Notes

Records are written from the Figures tab (`RecordFormDialog`) and the Today tab (`TodayTrainingDialog` → 🏆 button). This screen is purely a display view of the same `figures` Firestore collection.