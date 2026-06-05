# 📚 Documentation - Onglet Planning

## Vue d'ensemble

L'onglet **Planning** est l'interface de planification et de programmation des entraînements. Il permet à l'utilisateur d'organiser ses séances sur une **fenêtre de 14 jours** (du jour actuel aux 13 jours suivants), et de consulter l'historique des 14 jours passés.

### Objectifs principaux

- 📅 **Planifier** les entraînements jour par jour sur 14 jours
- ➕ **Ajouter** des figures à entraîner pour chaque jour
- 🗑️ **Retirer** des figures de la planification
- 👀 **Consulter** l'historique des 14 derniers jours
- 🎯 **Commencer l'apprentissage** d'une nouvelle figure
- 📊 **Visualiser** les dates passées et futures d'entraînement

---

## Table des matières

1. [Architecture générale](#architecture-générale)
2. [Modèles de données](#modèles-de-données)
3. [Écrans et dialogues](#écrans-et-dialogues)
4. [Ajout/Suppression de figures](#ajoutsuppression-de-figures)
5. [Commencer l'apprentissage](#commencer-lapprentissage)
6. [Affichage des dates d'entraînement](#affichage-des-dates-dentraînement)
7. [Historique (Past Planning)](#historique-past-planning)
8. [Providers et gestion d'état](#providers-et-gestion-détat)
9. [Widgets réutilisables](#widgets-réutilisables)
10. [Flux d'interaction complets](#flux-dinteraction-complets)

---

## Architecture générale

### Vue hiérarchique des composants

```
PlanningScreen (écran principal)
├── SliverAppBar (titre + actions)
│   └── IconButton: Historique (PastPlanningDialog)
│
├── CustomScrollView (14 jours scrollable)
│   ├── _DayHeader (Sticky) - "Aujourd'hui" ou "15 mars"
│   ├── _DayContent
│   │   ├── FigureSquareCard × N (cartes carrées)
│   │   └── _AddFigureButton [+]
│   │       └── AddFigureToDayDialog
│   │           └── BeginLearningDialog (sous-option)
│   │
│   ├── [Répété 14 fois pour 14 jours]
│   │
│   └── Padding (spacing)
│
└── PastPlanningDialog (historique 14 jours passés)
    └── _PastDaySection × 14
        └── FigureSquareCard × N
```

### Couches architecturales

```
┌─────────────────────────────────────────┐
│   PlanningScreen (ConsumerWidget)       │  UI
│   - Affichage 14 jours + figures        │
│   - Navigation vers dialogues           │
│   - Headers sticky par jour             │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   Providers (State Management)                    │  State
│   ├── planningProvider (stream 14j)               │
│   ├── figuresForDayProvider (figures/jour)        │
│   ├── availableFiguresForDayProvider (à ajouter) │
│   ├── plannedForDayProvider (données)             │
│   ├── showLearnedProvider (checkbox state)        │
│   └── effectiveLastTrainingDateProvider (calculs) │
└──────────────┬────────────────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   Repositories (Data Access)                      │  Data
│   ├── TrainingPlannedRepository                   │
│   │   - watchByDateRange(start, end)              │
│   │   - add(TrainingPlannedModel)                 │
│   │   - delete(figureId, date)                    │
│   └── FigureRepository                            │
│       - update(FigureModel)                       │
└──────────────┬────────────────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   Firestore Collections:                          │  Backend
│   ├── /users/{uid}/training_planned               │
│   │   (date + figureId)                           │
│   └── /users/{uid}/figures                        │
│       (état + startDate)                          │
└─────────────────────────────────────────────────────┘
```

---

## Modèles de données

### TrainingPlannedModel

Représente un entraînement planifié pour une date donnée.

```dart
class TrainingPlannedModel {
  final String figureId;    // Référence à la figure
  final DateTime date;      // Date planifiée (jour uniquement)
}
```

**Collection Firestore** : `/users/{uid}/training_planned/{id}`

```json
{
  "figureId": "handstand-id",
  "date": Timestamp(2026-03-15),
  "id": "auto-generated"
}
```

### FigureModel (rappel)

Voir [documentation Figures](FIGURES_FEATURE.md#figuremodel)

Les champs pertinents pour le planning :
- `state` : FigureState (toLearn/learning/learned)
- `startDate` : Date de début d'apprentissage (fixée lors du passage à "learning")
- `paused` : Si la figure est en pause

---

## Écrans et dialogues

### 1. PlanningScreen (Écran principal)

**Fichier** : `lib/screens/planning/planning_screen.dart`

**Responsabilités**
- Afficher 14 jours de planification
- Afficher les figures prévues pour chaque jour
- Permettre l'ajout/suppression de figures
- Accéder à l'historique passé
- Gestion du scroll avec headers sticky

**Structure visuelle**

```
┌──────────────────────────────────────────────┐
│ SliverAppBar (expandedHeight: 120)           │
│ ┌────────────────────────────────────────┐   │
│ │ Title: "Planification"                 │   │
│ │ (FlexibleSpaceBar)                     │   │
│ ├────────────────────────────────────────┤   │
│ │ Actions:                               │   │
│ │ 📜 Historique (14 jours passés)        │   │
│ └────────────────────────────────────────┘   │
├──────────────────────────────────────────────┤
│ CustomScrollView (corps, 14 jours)           │
│                                              │
│ ┌─ Jour 1 (Aujourd'hui) ──────────────────┐ │
│ │ [StickyHeader]                          │ │
│ │                                         │ │
│ │ 📦 Figure 1   📦 Figure 2   [+]         │ │
│ │ (carré)       (carré)     (add btn)     │ │
│ └─────────────────────────────────────────┘ │
│                                              │
│ ┌─ Jour 2 (Demain, 16 mars) ──────────────┐ │
│ │ [StickyHeader]                          │ │
│ │                                         │ │
│ │ 📦 Figure 1   [+]                       │ │
│ │ (carré)     (add btn)                   │ │
│ └─────────────────────────────────────────┘ │
│                                              │
│ [... 12 jours supplémentaires ...]           │
│                                              │
└──────────────────────────────────────────────┘
```

**Fonctionnalités clés**

1. **Headers Sticky** : Le jour reste visible au scroll
2. **14 jours** : Fenêtre glissante du jour courant + 13 jours
3. **Grille de cartes** : 3 cartes par ligne (responsive)
4. **Ajouter figure** : Bouton [+] en bas à droite
5. **Long-press** : Supprimer une figure de la planification
6. **Clic figure** : Voir dates d'entraînement précédente/suivante

---

### 2. AddFigureToDayDialog

**Fichier** : `lib/screens/planning/add_figure_to_day_dialog.dart`

**Contexte** : Ajouter une figure à un jour spécifique

**UI**

```
┌──────────────────────────────────────────────┐
│ AlertDialog                                  │
├──────────────────────────────────────────────┤
│ Title: "Ajouter une figure"                  │
│         "15 mars 2026"                       │
├──────────────────────────────────────────────┤
│ Content:                                     │
│ ┌──────────────────────────────────────────┐ │
│ │ [X] Afficher les figures maîtrisées     │ │
│ │     (CheckBox toggleable)                │ │
│ ├──────────────────────────────────────────┤ │
│ │ ListView de FigureCard:                  │ │
│ │                                          │ │
│ │ 🔵 Handstand                             │ │
│ │ 🟡 Planche                               │ │
│ │ 🟢 Muscle Up                             │ │
│ │ ...                                      │ │
│ │                                          │ │
│ │ (Cliquer pour ajouter)                   │ │
│ └──────────────────────────────────────────┘ │
├──────────────────────────────────────────────┤
│ Actions: [Fermer]                            │
└──────────────────────────────────────────────┘
```

**Logique de filtrage**

```dart
availableFiguresForDayProvider(date) :
├─ Exclut les figures déjà planifiées ce jour
├─ Exclut les figures en pause (paused = true)
├─ Si showLearned = false:
│  └─ Exclut les figures maîtrisées (state = learned)
└─ Retourne figures en apprentissage + figures à apprendre
```

**Workflow d'ajout**

```
User clique figure dans la liste
        ↓
trainingPlannedRepository.add(
  TrainingPlannedModel(
    figureId: figure.id,
    date: date
  )
)
        ↓
Firestore crée document
        ↓
planningProvider détecte changement
        ↓
PlanningScreen se reconstruit
        ↓
Figure 🔵 apparaît dans grille du jour
```

**Persistance UI** : La case "Afficher les figures maîtrisées" est persistée dans SharedPreferences via `showLearnedProvider`

---

### 3. BeginLearningDialog

**Fichier** : `lib/screens/planning/begin_learning_dialog.dart`

**Contexte** : Commencer l'apprentissage d'une figure directement depuis la planification

**UI**

```
┌──────────────────────────────────────────────┐
│ AlertDialog                                  │
├──────────────────────────────────────────────┤
│ Title: "Commencer l'apprentissage"           │
│         "15 mars 2026"                       │
├──────────────────────────────────────────────┤
│ Content:                                     │
│ ┌──────────────────────────────────────────┐ │
│ │ ListView de FigureCard (toLearn):        │ │
│ │                                          │ │
│ │ 📌 Figure à apprendre 1                  │ │
│ │ 📌 Figure à apprendre 2                  │ │
│ │                                          │ │
│ │ (Cliquer pour commencer)                 │ │
│ └──────────────────────────────────────────┘ │
├──────────────────────────────────────────────┤
│ Actions: [Fermer]                            │
└──────────────────────────────────────────────┘

[Si sélection]
┌──────────────────────────────────────────────┐
│ Confirmation Dialog                          │
├──────────────────────────────────────────────┤
│ "Commencer l'apprentissage de 'Handstand'?" │
├──────────────────────────────────────────────┤
│ [Annuler] [Confirmer]                        │
└──────────────────────────────────────────────┘
```

**Workflow**

```
User clique sur figure "à apprendre"
        ↓
Confirmation dialog (AlertDialog imbriqué)
        ↓
User clique "Confirmer"
        ↓
Deux opérations en parallèle:
├─ figureRepository.update(figure.copyWith(
│    state: FigureState.learning,
│    startDate: date,      // Date sélectionnée
│    order: newOrder       // Position dans learning
│  ))
│
└─ trainingPlannedRepository.add(
   TrainingPlannedModel(
     figureId: figure.id,
     date: date           // Ajout entraînement ce jour
   )
 )
        ↓
Firestore met à jour figure + crée training_planned
        ↓
UI se reconstruit
        ↓
• Figure disparaît de "toLearn"
• Figure apparaît dans "learning"
• Figure est ajoutée à la planification du jour
```

**Différence vs FigureDetailDialog**

| Dialog | Contexte | startDate | Ajout planning |
|--------|----------|-----------|----------------|
| **BeginLearningDialog** | Depuis Planning | Date sélectionnée | ✅ Oui (automais) |
| **FigureDetailDialog** | Depuis Figures | Aujourd'hui toujours | ❌ Non |

---

### 4. TrainingDatesDialog

**Fichier** : `lib/screens/planning/training_dates_dialog.dart`

**Contexte** : Afficher les dates d'entraînement passée/future pour une figure (au clic sur une carte)

**UI**

```
┌──────────────────────────────────────────────┐
│ AlertDialog                                  │
├──────────────────────────────────────────────┤
│ Title: [couleur] Figure Name  [📅]           │
│                            (calendrier)      │
├──────────────────────────────────────────────┤
│ Content:                                     │
│ ┌──────────────────────────────────────────┐ │
│ │ 📜 Entraînement précédent:               │ │
│ │    5 jours (relative)                    │ │
│ │    ou "aucun entraînement"               │ │
│ │                                          │ │
│ │ 📅 Prochain entraînement:                │ │
│ │    Demain (relative)                     │ │
│ │    ou "aucun entraînement planifié"      │ │
│ │                                          │ │
│ │ [Clic sur DateRow pour détails]          │ │
│ └──────────────────────────────────────────┘ │
├──────────────────────────────────────────────┤
│ Actions: [Fermer]                            │
└──────────────────────────────────────────────┘
```

**Logique de calcul des dates**

```dart
effectiveLastTrainingDateProvider:
├─ Prend en compte trainingDone (entraînements effectués)
├─ ET trainingPlanned PASSÉS (entre aujourd'hui et date_sélectionnée)
├─ Retourne la plus récente parmi les deux
└─ Affichage relatif: "5 jours", "hier", "aujourd'hui"

nextTrainingDateAfterDayProvider:
├─ Cherche le prochain entraînement APRÈS le jour sélectionné
├─ Utilise trainingPlanned (entraînements planifiés)
└─ Affichage relatif: "demain", "dans 3 jours"
```

**Bouton calendrier** : Clic 📅 ouvre FigureCalendarDialog (voir [doc Figures](FIGURES_FEATURE.md))

---

### 5. PastPlanningDialog

**Fichier** : `lib/screens/planning/past_planning_dialog.dart`

**Contexte** : Consulter l'historique des 14 derniers jours

**UI**

```
┌──────────────────────────────────────────────┐
│ Dialog (non-modal, full-screen style)        │
├──────────────────────────────────────────────┤
│ Title: "Historique"                      [X] │
├──────────────────────────────────────────────┤
│ Divider                                      │
├──────────────────────────────────────────────┤
│ ListVie (14 jours passés):                   │
│                                              │
│ ─ 4 mars 2026 ─────────────────────────────  │
│ 🔵 Handstand   🔴 Planche   [+] (3ème card) │
│                                              │
│ ─ 3 mars 2026 ─────────────────────────────  │
│ 🟢 Muscle Up                                 │
│                                              │
│ ─ 2 mars 2026 ─────────────────────────────  │
│ (Pas d'entraînement ce jour)                 │
│                                              │
│ [... 11 jours passés ...]                    │
│                                              │
└──────────────────────────────────────────────┘
```

**Affichage avec indicateurs**

- Les figures affichées sont celles **planifiées** ce jour
- Superposition visuelle : ✅ Icon si entraînement **effectué** (isDone)
- Pas d'icon si seulement planifiée mais non effectuée

**Providers utilisés**

```dart
figuresForPastDateProvider(date)
└─ Figures planifiées ce jour
   (même que figuresForDayProvider mais pour passé)

trainingDoneForDateProvider(date)
└─ Set<String> des figureIds effectués ce jour
   (permet marquer avec ✅)
```

**Accès** : Via icône 📜 dans l'AppBar de PlanningScreen

---

## Ajout/Suppression de figures

### Ajouter une figure

**Méthode 1 : Via AddFigureToDayDialog**

```
User dans PlanningScreen
        ↓
Clic sur bouton [+] au bas d'une grille jour
        ↓
AddFigureToDayDialog s'ouvre pour ce jour
        ↓
Clic sur figure dans la liste
        ↓
trainingPlannedRepository.add(figure.id, date)
        ↓
planningProvider détecte ajout
        ↓
Figure 🔵 carré apparaît dans grille du jour
```

**Méthode 2 : Commencer apprentissage depuis Planning**

```
User dans AddFigureToDayDialog
        ↓
Cherche figure "à apprendre" (pas dans liste par défaut)
        ↓
Coche "Afficher les figures maîtrisées"
        ↓
Clic sur figure toLearn → BeginLearningDialog
        ↓
Figure change state + ajout à la planification
```

### Supprimer une figure

**Suppression depuis PlanningScreen**

```
User long-press sur FigureSquareCard
        ↓
_removeFigure() appelée
        ↓
Deux opérations:
├─ trainingPlannedRepository.delete(figureId, date)
│  └─ Supprime la planification pour ce jour
│
└─ [Optionnel] trainingDoneRepository.delete(figureId, date)
   └─ Supprime aussi si effectué ce jour
```

**Logique du long-press**

```dart
onLongPress: () => _removeFigure(context, ref, figure, date),

Future<void> _removeFigure(...) {
  // Supprime TrainingPlanned ET TrainingDone
  // (les deux si existent pour ce jour)
}
```

---

## Commencer l'apprentissage

### Workflow complet

**Étape 1 : Accès à BeginLearningDialog**

```
Option A:
├─ User dans PlanningScreen
├─ Clic [+] jour
└─ Coche "Afficher figures maîtrisées" dans AddFigureToDayDialog
   → Affiche aussi figures toLearn

Option B:
├─ User dans Figures tab
├─ Clic sur FigureDetailDialog
└─ Bouton "Commencer l'apprentissage"
```

**Étape 2 : Confirmer et mise à jour**

```
User clique figure toLearn
        ↓
Confirmation dialog: "Commencer apprentissage de 'Handstand'?"
        ↓
User clique "Confirmer"
        ↓
Deux modifications simultanées:

1. figureRepository.update(figure.copyWith(
     state: FigureState.learning,
     startDate: date,  // Jour planification
     order: maxOrder+1 // Position dans learning
   ))
   → Firestore: /users/{uid}/figures/{id}
     state = "learning"
     startDate = date sélectionnée

2. trainingPlannedRepository.add(
     TrainingPlannedModel(figureId, date)
   )
   → Firestore: /users/{uid}/training_planned/{id}
     figureId = id
     date = date sélectionnée
        ↓
Deux providers détectent changement:
├─ figuresProvider (figure déplacée toLearn → learning)
├─ planningProvider (nouvelle entrée planned)
└─ figuresForDayProvider (figure 🔵 visible ce jour)
        ↓
UI reconstruit:
├─ Onglet Figures: Figure en "learning"
└─ Onglet Planning: Figure 🔵 dans grille ce jour
```

### Différence avec changement de statut dans Figures

| Action | UI Figures | startDate | Date planification |
|--------|------------|-----------|-------------------|
| **Commencer depuis BeginLearningDialog** | Figure en learning | Date sélectionnée | ✅ Ajoutée ce jour |
| **Commencer depuis FigureDetailDialog** | Figure en learning | Aujourd'hui | ❌ Non |

---

## Affichage des dates d'entraînement

### Provider effectiveLastTrainingDateProvider

**Objectif** : Trouver la date de dernier entraînement en tenant compte de:
1. **TrainingDone** : Entraînements réellement effectués (historique)
2. **TrainingPlanned** : Entraînements planifiés mais pas encore effectués (futurs)

**Logique**

```dart
effectiveLastTrainingDateProvider({figureId, date}):

lastDateAsync = lastTrainingDateProvider(figureId)
               → Dernière date effectuée réelle

plannedAsync = trainingPlannedForFigureProvider(figureId)
              → Tous les entraînements planifiés

today = todayProvider
target = date sélectionnée

Algorithme:
├─ Chercher entraînements planifiés ENTRE aujourd'hui et target
├─ Si aucun: retourner lastDate (dernière vraie effectuée)
├─ Si trouvés: retourner la plus récente entre:
│  ├─ lastDate (vraie)
│  └─ lastPlanned (planifiée)
└─ Retourner la plus récente des deux
```

**Utilisation** : TrainingDatesDialog affiche cette date de façon relative

### Provider nextTrainingDateAfterDayProvider

**Objectif** : Trouver le prochain entraînement après un jour donné

```dart
nextTrainingDateAfterDayProvider({figureId, date}):

└─ Cherche premiers TrainingPlanned.date > targetDate
   → Affiche "demain", "dans 3 jours"
```

---

## Historique (Past Planning)

### Accès à PastPlanningDialog

```
User clique icône 📜 dans AppBar de PlanningScreen
        ↓
PastPlanningDialog s'ouvre
        ↓
Affiche 14 jours précédents (hier → -14j)
        ↓
Pour chaque jour: figures planifiées + marquage si effectuées
```

### Affichage avec statut

**Logique**

```
Pour chaque jour passé:
├─ figuresForPastDateProvider(date)
│  → Figures planifiées ce jour
│
└─ trainingDoneForDateProvider(date)
   → Quelles figures ont été effectuées
   → Ajouter overlay ✅ Icon

Résultat visuel:
├─ 🔵 Handstand      (planifiée + effectuée = ✅)
├─ 🟡 Planche        (planifiée seulement)
└─ 🟢 Muscle Up      (planifiée + effectuée = ✅)
```

### Widgets utilisés

```dart
FigureSquareCard(
  figure: figure,
  isDone: doneIds.contains(figure.id),  // ✅ Icon
  showStateIcon: false,  // Pas d'icon état (learning, etc.)
  onTap: () => ...,
)
```

---

## Providers et gestion d'état

### Providers principaux

| Provider | Type | Description |
|----------|------|-------------|
| `planningProvider` | StreamProvider | Stream de tous TrainingPlanned sur 14 jours |
| `plannedForDayProvider` | Provider.family | TrainingPlanned filtrés pour un jour |
| `figuresForDayProvider` | Provider.family | FigureModels planifiées un jour (données complètes) |
| `availableFiguresForDayProvider` | Provider.family | Figures disponibles à ajouter ce jour (filtrées) |
| `showLearnedProvider` | NotifierProvider | État checkbox "Afficher maîtrisées" (persisté SharedPrefs) |
| `effectiveLastTrainingDateProvider` | Provider.family | Dernier entraînement (done + planned) |
| `trainingPlannedForFigureProvider` | StreamProvider.family | Tous TrainingPlanned d'une figure |
| `figuresForPastDateProvider` | Provider.family | Figures planifiées un jour passé |
| `trainingDoneForDateProvider` | StreamProvider.family | Figures effectuées un jour |

### Repositories

| Repository | Méthodes |
|------------|----------|
| `TrainingPlannedRepository` | `watchByDateRange()`, `add()`, `delete()`, `watchByFigure()` |
| `FigureRepository` | `update()`, `getMaxOrder()` (pour ordre) |
| `TrainingDoneRepository` | `watchByDate()`, `delete()` |

---

## Widgets réutilisables

### FigureSquareCard

**Fichier** : `lib/widgets/figure_square_card.dart`

**Usage** : Affichage carré des figures (planning, historique)

**Props**
```dart
FigureSquareCard({
  required FigureModel figure,
  required VoidCallback onTap,
  required VoidCallback onLongPress,
  bool isDone = false,          // Affiche ✅ overlay
  bool showStateIcon = true,    // Icône état (learning, etc.)
})
```

**Affichage**

```
┌─────────────────┐
│ [top border 🔵] │
│                 │
│   Handstand     │
│                 │
│ [state icon 🤸] │
│                 │
│ [✅ si isDone]  │ (overlay semi-transparent)
└─────────────────┘
```

### _AddFigureButton

**Fichier** : `lib/screens/planning/planning_screen.dart` (composant interne)

**UI** : Carré avec icône [+]

```
┌─────────────────┐
│       [+]       │
│   Ajouter       │
└─────────────────┘
```

**Action** : Clic ouvre AddFigureToDayDialog pour ce jour

### _DayHeader

**Composant** : SliverPersistentHeader sticky

**Affichage**

```
Mardi 15 mars 2026  [ou "Aujourd'hui" en couleur primaire]
```

**Comportement** : Reste visible au scroll (stick au top)

---

## Flux d'interaction complets

### Flux 1 : Planifier un entraînement

```
┌─ User voit PlanningScreen
│  Affichage: 14 jours + figures déjà planifiées
│
├─ Scroll vers jour spécifique
│  Ex: Demain 16 mars
│
├─ Clic [+] dans grille du jour
│  → AddFigureToDayDialog s'ouvre pour 16 mars
│
├─ Liste affiche figures disponibles
│  (non planifiées ce jour, pas maîtrisées par défaut)
│
├─ User voit "Handstand" (en apprentissage)
│
├─ Clic sur "Handstand"
│
├─ Appel:
│  └─ trainingPlannedRepository.add(
│       TrainingPlannedModel(
│         figureId: "handstand-id",
│         date: 2026-03-16
│       )
│     )
│
├─ Firestore crée document
│
├─ planningProvider détecte changement (watchByDateRange)
│
├─ plannedForDayProvider(16 mars) se réexécute
│
├─ figuresForDayProvider(16 mars) se réexécute
│
├─ AddFigureToDayDialog se ferme
│
└─ PlanningScreen se reconstruit
   └─ 🔵 Handstand apparaît dans grille 16 mars
```

### Flux 2 : Commencer l'apprentissage depuis Planning

```
┌─ User dans PlanningScreen
│  Cherche à ajouter "Figure à apprendre"
│
├─ Clic [+] jour
│  → AddFigureToDayDialog (pas de figures toLearn par défaut)
│
├─ Coche "Afficher figures maîtrisées"
│  → showLearnedProvider.toggle()
│  → availableFiguresForDayProvider se réexécute
│  → Liste montre maintenant figures toLearn + learned
│
├─ Cherche "Lever du bras" (en toLearn)
│
├─ Clic sur "Lever du bras"
│  → BeginLearningDialog s'ouvre (pas AddFigureToDayDialog)
│  (sélection automatique de BeginLearningDialog basée sur state)
│
├─ BeginLearningDialog affiche la figure
│
├─ User clic sur "Lever du bras"
│  → Confirmation dialog imbriqué
│
├─ User clique "Confirmer"
│
├─ Deux modifications simultanées:
│  ├─ figureRepository.update(figure.copyWith(
│  │    state: FigureState.learning,
│  │    startDate: date (jour sélectionné),
│  │    order: newOrder
│  │  ))
│  │  → /users/{uid}/figures/lever-du-bras
│  │    state = "learning"
│  │    startDate = 2026-03-16
│  │
│  └─ trainingPlannedRepository.add(
│       TrainingPlannedModel(
│         figureId: "lever-du-bras",
│         date: 2026-03-16
│       )
│     )
│     → /users/{uid}/training_planned/{new}
│
├─ Deux providers détectent changement:
│  ├─ figuresProvider (figure quitte toLearn)
│  └─ planningProvider (nouvelle entry planned)
│
└─ UI reconstruit:
   ├─ Onglet Figures: "Lever du bras" en "En apprentissage"
   └─ Onglet Planning: "Lever du bras" 🔵 dans grille 16 mars
```

### Flux 3 : Voir l'historique des entraînements

```
┌─ User dans PlanningScreen
│
├─ Clic icône 📜 "Historique"
│  → PastPlanningDialog s'ouvre
│
├─ Affiche 14 jours passés (hier → -14j)
│  Ex:
│  ─ 4 mars ─
│  🔵 Handstand ✅  (planifiée + effectuée)
│  🟡 Planche       (planifiée seulement)
│
├─ PastPlanningDialog utilise:
│  ├─ figuresForPastDateProvider(date)
│  │  → Liste figures planifiées ce jour
│  │
│  ├─ trainingDoneForDateProvider(date)
│  │  → Set<String> des figureIds avec done
│  │
│  └─ isDone = doneIds.contains(figure.id)
│     → Affiche ✅ overlay si vrai
│
└─ User peut scroller historique pour voir tous jours
```

### Flux 4 : Supprimer une figure de la planification

```
┌─ User dans PlanningScreen
│  Jour avec figure 🔵 Handstand
│
├─ Long-press sur 🔵 Handstand
│  → _removeFigure(figure, date) appelée
│
├─ Appel:
│  ├─ trainingPlannedRepository.delete("handstand", date)
│  │  → Supprime /users/{uid}/training_planned/{id}
│  │
│  └─ [Si effectué ce jour aussi]
│     trainingDoneRepository.delete("handstand", date)
│     → Supprime /users/{uid}/training_done/{id}
│
├─ planningProvider détecte suppression
│
├─ figuresForDayProvider se réexécute
│
└─ PlanningScreen se reconstruit
   └─ 🔵 Handstand disparaît de la grille du jour
```

### Flux 5 : Voir dates précédente/suivante d'une figure

```
┌─ User dans PlanningScreen
│  Jour avec figure 🔵 Handstand
│
├─ Clic sur 🔵 Handstand
│  → TrainingDatesDialog s'ouvre
│
├─ Dialog affiche:
│  ├─ effectiveLastTrainingDateProvider
│  │  Ex: "Entraînement précédent: il y a 5 jours"
│  │
│  └─ nextTrainingDateAfterDayProvider
│     Ex: "Prochain entraînement: dans 2 jours"
│
├─ Calcul dates:
│  ├─ Considère TrainingDone (effectués)
│  ├─ Considère TrainingPlanned (planifiés futurs)
│  └─ Retourne la plus récente/prochaine
│
├─ User peut cliquer 📅 pour ouvrir calendrier
│  → FigureCalendarDialog
│
└─ Clic fermeture → Dialog se ferme
```

---

## Gestion des erreurs et cas limites

### Erreur de synchronisation Firestore

```dart
planningProvider.when(
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Erreur : $e'),
  data: (planned) => ...
)
```

### Cas limite : Ajouter figure planifiée le même jour

```
User essaie d'ajouter figure déjà planifiée ce jour
        ↓
availableFiguresForDayProvider exclut les figureIds
   déjà dans plannedForDayProvider
        ↓
Figure n'apparaît pas dans la liste
        ↓
Impossible d'ajouter (elle disparaît automatiquement)
```

### Cas limite : Supprimer figure effectuée et planifiée

```
Figure est à la fois:
├─ Dans training_done (a été effectuée ce jour)
└─ Dans training_planned (reste planifiée ce jour)

Long-press supprime LES DEUX
└─ Nettoyage complet
```

### Cas limite : Commencer apprentissage avec date future

```
User sélectionne date 16 mars pour BeginLearningDialog
        ↓
startDate = 16 mars (pas aujourd'hui)
        ↓
FigureDetailDialog affichera "Commencé le: 16 mars"
        ↓
Utile pour entraînements prévus longtemps à l'avance
```

---

## Interactions avec autres onglets

### Planning ↔ Figures

```
Figures tab:
└─ Clic "Commencer" dans FigureDetailDialog
   → Passe state à learning
   → startDate = aujourd'hui (pas de date custom)
   → Ne planifie PAS automatiquement

Planning tab:
└─ BeginLearningDialog
   → Passe state à learning
   → startDate = date sélectionnée
   → Planifie AUTOMATIQUEMENT ce jour
```

### Planning ↔ Today

```
Planning:
└─ "Ajouter figure à 15 mars"

Today:
└─ Affiche figures planifiées AUJOURD'HUI
   (sous-ensemble de planningProvider pour today)
```

### Planning ↔ Records

```
Records affiche historique détaillé des entraînements
        ↓
PastPlanningDialog affiche version simplifiée
        ↓
Les données proviennent du même source: trainingDone
```

---

## Synthèse et architecture

L'onglet **Planning** est une **interface de programmation flexible** avec :

✅ **Vue 14 jours** avec headers sticky  
✅ **Ajout/suppression rapide** de figures  
✅ **Commencer apprentissage direct** depuis planning  
✅ **Affichage dates relatives** (précédent/prochain)  
✅ **Historique 14 jours** avec marquage "effectué"  
✅ **Filtrage intelligent** (exclu planifiée, pause, maîtrisée)  
✅ **Persistance préférences** (checkbox showLearned)  
✅ **Synchronisation temps réel** (Firestore streams)  

Le module utilise **ReferenceDates** pour contextualiser les calculs et offre une **flexibilité** dans la planification des dates de début d'apprentissage.

---

*Dernière mise à jour : Juin 2026*
