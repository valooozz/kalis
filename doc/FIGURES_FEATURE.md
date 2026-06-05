# 📚 Documentation - Onglet Figures

## Vue d'ensemble

L'onglet **Figures** est le cœur de l'application Kalis. C'est ici que l'utilisateur gère son portefeuille complet de figures/mouvements à maîtriser. Cet onglet offre une vue d'ensemble organisée, des outils de gestion détaillée et une visualisation riche des entraînements.

### Objectifs principaux

- 📋 **Gérer** le portefeuille de figures (création, édition, suppression)
- 📊 **Organiser** les figures par statut (à apprendre, en apprentissage, maîtrisées)
- 🎯 **Suivre** la progression individuelle de chaque figure
- 📅 **Visualiser** les entraînements (calendrier personnel et global)
- 📝 **Documenter** les notes de progression (journal)
- 🏆 **Enregistrer** les records/meilleurs résultats

---

## Table des matières

1. [Architecture générale](#architecture-générale)
2. [Modèles de données](#modèles-de-données)
3. [Écrans et dialogues](#écrans-et-dialogues)
4. [Gestion des figures (CRUD)](#gestion-des-figures-crud)
5. [Gestion du journal](#gestion-du-journal)
6. [Système de calendrier](#système-de-calendrier)
7. [Filtrage et organisation](#filtrage-et-organisation)
8. [Providers et gestion d'état](#providers-et-gestion-détat)
9. [Widgets réutilisables](#widgets-réutilisables)
10. [Flux d'interaction complets](#flux-dinteraction-complets)

---

## Architecture générale

### Vue hiérarchique des composants

```
FiguresScreen (écran principal)
├── AppBar (titre + actions)
│   ├── IconButton: Filtrage couleur (ColorFilterDialog)
│   ├── IconButton: Calendrier global (GlobalCalendarDialog)
│   ├── IconButton: Records (go to Records Screen)
│   └── IconButton: Paramètres (go to Settings Screen)
│
├── CustomScrollView (liste scrollable avec headers sticky)
│   ├── _FigureSection (Maîtrisées)
│   │   ├── _StickyHeader (header persistant)
│   │   └── _FigureSliver (grille réordonnables)
│   │       └── FigureCard × N (clickable)
│   │           └── FigureDetailDialog
│   │
│   ├── _FigureSection (En apprentissage)
│   │   └── ... (même structure)
│   │
│   └── _FigureSection (À apprendre)
│       └── ... (même structure)
│
└── FloatingActionButton (+ Ajouter)
    └── FigureFormDialog (création)
```

### Couches architecturales

```
┌─────────────────────────────────────────┐
│   FiguresScreen (ConsumerWidget)        │  UI
│   - Affichage des figures               │
│   - Tri par statut                      │
│   - Navigation vers dialogues           │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   Providers (State Management)                    │  State
│   ├── figuresProvider (stream filtered)           │
│   ├── figuresByStateProvider (filtrées)           │
│   ├── colorFilterProvider (filtre actif)          │
│   ├── trainingDoneDatesProvider (entraînements)   │
│   └── trainingPlannedDatesProvider (planification)│
└──────────────┬────────────────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   FigureRepository (Data Access)                  │  Data
│   - watchAll() / Stream<List<FigureModel>>        │
│   - create(name, color) / Future<FigureModel>     │
│   - update(FigureModel) / Future<void>            │
│   - delete(id) / Future<void>                     │
│   - updateOrder(figures) / Future<void>           │
└──────────────┬────────────────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   Firestore Collection: /users/{uid}/figures      │  Backend
│   - Document ID: Figure.id                        │
│   - Fields: name, color, state, dates, records    │
└─────────────────────────────────────────────────────┘
```

---

## Modèles de données

### FigureModel

Représente une figure/mouvement d'entraînement.

```dart
class FigureModel {
  final String id;                    // ID Firestore unique
  final String name;                  // Nom de la figure
  final FigureColor color;            // Couleur pour catégorisation visuelle
  final FigureState state;            // État actuel (3 états possibles)
  final DateTime? startDate;          // Date de début d'apprentissage
  final DateTime? endDate;            // Date de maîtrise (si état = learned)
  final int? recordValue;             // Meilleur score numérique
  final RecordUnit? recordUnit;       // Unité du record (reps ou secondes)
  final int order;                    // Position dans la liste (pour tri custom)
  final bool paused;                  // Figure actuellement en pause?
}
```

### Énumérés associés

#### FigureState (Statut d'une figure)

```dart
enum FigureState {
  toLearn(0),      // À apprendre (figure pas encore commencée)
  learning(1),     // En apprentissage (figure en cours de travail)
  learned(2),      // Maîtrisée (figure complètement maîtrisée)
}
```

| État | Icon | Description | Actions possibles |
|------|------|-------------|-------------------|
| **toLearn** | 📌 | Figure à apprendre | Commencer l'apprentissage, supprimer |
| **learning** | 🤸 | En apprentissage | Planifier des entraînements, modifier, maîtriser |
| **learned** | ✅ | Maîtrisée | Ajouter record, reprise d'apprentissage, pause |

#### FigureColor (Catégorisation visuelle)

```dart
enum FigureColor {
  red,      // Rouge (#E57373)
  orange,   // Orange (#FFB74D)
  yellow,   // Jaune (#FFF176)
  green,    // Vert (#81C784)
  blue,     // Bleu (#64B5F6)
  purple,   // Mauve (#BA68C8)
}
```

**Usage** : Catégoriser visuellement les figures (ex: par groupe musculaire, par difficulté, par type)

#### RecordUnit (Unité de measurement du record)

```dart
enum RecordUnit {
  reps,     // Répétitions (ex: 20 répétitions en HandStand)
  seconds,  // Secondes (ex: 45 secondes en Planche)
}
```

---

## Écrans et dialogues

### 1. FiguresScreen (Écran principal)

**Fichier** : `lib/screens/figures/figures_screen.dart`

**Responsabilités**
- Afficher toutes les figures organisées par statut
- Permettre le filtrage par couleur
- Naviguer vers les détails d'une figure
- Créer une nouvelle figure
- Accéder aux actions globales (calendrier global, records, settings)

**Composition UI**

```
┌─────────────────────────────────────────────┐
│ SliverAppBar (expandedHeight: 120)          │
│ ┌───────────────────────────────────────┐   │
│ │ Title: "Figures" (FlexibleSpaceBar)   │   │
│ ├───────────────────────────────────────┤   │
│ │ Actions:                              │   │
│ │ 🎨 Filtrer par couleur                │   │
│ │ 📅 Calendrier global                  │   │
│ │ 🏆 Records                            │   │
│ │ ⚙️ Paramètres                         │   │
│ └───────────────────────────────────────┘   │
├─────────────────────────────────────────────┤
│ CustomScrollView (corps)                    │
│ ├─────────────────────────────────────────┤│
│ │ Section: "Maîtrisées (3)"              ││
│ │ ┌─────────────────────────────────────┐││
│ │ │ FigureCard × 3 (grille réord.)      │││
│ │ └─────────────────────────────────────┘││
│ ├─────────────────────────────────────────┤│
│ │ Section: "En apprentissage (2)"        ││
│ │ ┌─────────────────────────────────────┐││
│ │ │ FigureCard × 2                      │││
│ │ └─────────────────────────────────────┘││
│ ├─────────────────────────────────────────┤│
│ │ Section: "À apprendre (5)"             ││
│ │ ┌─────────────────────────────────────┐││
│ │ │ FigureCard × 5                      │││
│ │ └─────────────────────────────────────┘││
│ └─────────────────────────────────────────┘│
├─────────────────────────────────────────────┤
│ FloatingActionButton (+ Ajouter une figure) │
└─────────────────────────────────────────────┘
```

**Fonctionnalités clés**
- ✅ Tri automatique par statut (toLearn → learning → learned)
- ✅ Groupement par section sticky (headers restent visibles)
- ✅ Réordonnement drag-and-drop (au sein d'une section)
- ✅ Filtrage par couleur en temps réel
- ✅ Vide state gracieux (message si aucune figure)

---

### 2. FigureFormDialog

**Fichier** : `lib/screens/figures/figure_form_dialog.dart`

**Contexte d'utilisation**
- Création d'une nouvelle figure (depuis FAB)
- Édition d'une figure existante (depuis FigureDetailDialog)

**UI et champs**

```
┌─────────────────────────────────┐
│ AlertDialog                     │
├─────────────────────────────────┤
│ Title: "Nouvelle figure"        │
│ ou "Modifier la figure"         │
├─────────────────────────────────┤
│ Content:                        │
│ ┌───────────────────────────┐   │
│ │ Name TextField            │   │
│ │ "Entrez le nom..."        │   │
│ └───────────────────────────┘   │
│                                 │
│ Color:                          │
│ ┌───────────────────────────┐   │
│ │ 🔴 🟠 🟡 🟢 🔵 🟣         │   │
│ │ ColorPickerRow (selector) │   │
│ └───────────────────────────┘   │
│                                 │
│ [Si édition uniquement]         │
│ ┌───────────────────────────┐   │
│ │ Start Date: 15 mars 2026  │   │
│ │ Mastery Date: 20 avril... │   │
│ │ Record: 20 reps (delete)  │   │
│ └───────────────────────────┘   │
├─────────────────────────────────┤
│ Actions:                        │
│ [Annuler] [Supprimer] [Ajouter]│
│ ou                              │
│ [Annuler] [Supprimer] [Sauver] │
└─────────────────────────────────┘
```

**Logique métier**

| Champ | Création | Édition | Obligatoire |
|-------|----------|---------|------------|
| **Nom** | ✅ Editable | ✅ Editable | ✅ Oui |
| **Couleur** | ✅ Sélectable | ✅ Modifiable | ✅ Oui (défaut: bleu) |
| **Dates** | ❌ Cachées | ✅ Modifiables | ❌ Optionnel |
| **Record** | ❌ Cachée | ✅ Visible (si learned) | ❌ Optionnel |
| **Suppression** | ❌ N/A | ✅ Bouton rouge | - |

**Flux d'enregistrement**

```
Utilisateur clique "Ajouter"
        ↓
Validation du nom (non-vide)
        ↓
[CRÉATION]              [ÉDITION]
figureRepository        figureRepository
.create(               .update(
  name,                 figure.copyWith(
  color                   name,
)                        color,
        ↓                startDate,
Firestore               endDate,
ajoute document        )
        ↓                      ↓
figuresProvider             Firestore
détecte changement          met à jour
        ↓
UI refresh
```

---

### 3. FigureDetailDialog

**Fichier** : `lib/screens/figures/figure_detail_dialog.dart`

**Contexte** : Affichage détaillé et gestion d'une figure (ouvert au clic sur une carte)

**UI composée**

```
┌──────────────────────────────────────────┐
│ AlertDialog (insetPadding: symmetric)    │
├──────────────────────────────────────────┤
│ Title: [couleur] Figure Name             │
│ Actions: 📅 [pauseIcon] 🔧               │
├──────────────────────────────────────────┤
│ Content (SingleChildScrollView):         │
│                                          │
│ [Statuts toLearn/learning/learned]      │
│ ┌──────────────────────────────────────┐ │
│ │ 📌 Commencé le: 15 mars 2026        │ │
│ │ ✅ Maîtrisé le: 20 avril 2026       │ │
│ │ 🏆 Record: 20 reps                  │ │
│ │                                      │ │
│ │ [SI toLearn]                         │ │
│ │ 🎯 Commencer l'apprentissage (btn) │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ ─────────────────── Divider             │
│                                          │
│ Journal (Notes de progression)           │
│ ┌──────────────────────────────────────┐ │
│ │ "Journal" [+]                        │ │
│ │ • 15 mars: "Trop difficile, à..."   │ │
│ │ • 10 mars: "Premiers essais..."     │ │
│ │                                      │ │
│ │ (Cliquer pour éditer/supprimer)     │ │
│ └──────────────────────────────────────┘ │
│                                          │
├──────────────────────────────────────────┤
│ Actions: [Fermer]                        │
└──────────────────────────────────────────┘
```

**Boutons d'action dans le titre**

| Icône | Condition | Action | Dialog |
|-------|-----------|--------|--------|
| 📅 | state ≠ toLearn | Voir calendrier personnel | FigureCalendarDialog |
| ⏸️/▶️ | state ≠ toLearn | Marquer pause/reprendre | Appel repository |
| 🔧 | Toujours | Changer le statut | FigureStatusPickerDialog |

**Interactions principales**
- Cliquer sur une note → Éditer la note (JournalEntryFormDialog)
- Cliquer le X d'une note → Supprimer la note
- Cliquer bouton "Commencer" (si toLearn) → Passe en "learning" (BeginLearningDialog)
- Cliquer bouton record (si learned) → Éditer record (RecordFormDialog)

---

### 4. FigureStatusPickerDialog

**Fichier** : `lib/screens/figures/figure_status_picker_dialog.dart`

**Contexte** : Changer le statut d'une figure

**UI**

```
┌──────────────────────────────────────────┐
│ AlertDialog                              │
├──────────────────────────────────────────┤
│ Title: "Changer le statut"               │
├──────────────────────────────────────────┤
│ Content: Column                          │
│ ┌──────────────────────────────────────┐ │
│ │ [ANIMATED CONTAINER - Selected]      │ │
│ │         📌 À apprendre               │ │
│ ├──────────────────────────────────────┤ │
│ │ 🤸 En apprentissage                  │ │
│ ├──────────────────────────────────────┤ │
│ │ ✅ Maîtrisée                         │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ (Sélection animée + border highlight)   │
├──────────────────────────────────────────┤
│ Actions: [Annuler]                       │
└──────────────────────────────────────────┘
```

**Logique de changement**

- **toLearn → learning** : Fixe startDate automatiquement (aujourd'hui)
- **learning → learned** : Fixe endDate automatiquement (aujourd'hui)
- **learned → learning** : Efface endDate
- **Tout → toLearn** : Efface les dates et entraînements planifiés

---

### 5. FigureCalendarDialog

**Fichier** : `lib/screens/figures/figure_calendar_dialog.dart`

**Contexte** : Vue calendrier des entraînements d'une figure spécifique

**UI**

```
┌──────────────────────────────────────────┐
│ AlertDialog                              │
├──────────────────────────────────────────┤
│ Title: "Figure Name"                     │
├──────────────────────────────────────────┤
│ Content: TableCalendar                   │
│ ┌──────────────────────────────────────┐ │
│ │        Avril 2026           [< >]    │ │
│ ├──────────────────────────────────────┤ │
│ │ Lun Mer Mer Jeu Ven Sam Dim          │ │
│ │  1   2   3   4   5   6   7           │ │
│ │  8  🔵 10  11  12 🔴 14           │
│ │                    ▲ Entraînement    │ │
│ │                      effectué        │ │
│ │ (Couleur figure si done)             │ │
│ │ (Marquage si planned)                │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ Bottom: "3 entraînements en avril"      │
├──────────────────────────────────────────┤
│ Actions: [Fermer]                        │
└──────────────────────────────────────────┘
```

**Codage couleur**
- 🔵 **Plein** = Entraînement effectué (couleur figure)
- ⭕ **Contour** = Entraînement planifié (contour couleur)
- ◯ **Aujourd'hui** = Border avec couleur primaire

---

### 6. GlobalCalendarDialog

**Fichier** : `lib/screens/figures/global_calendar_dialog.dart`

**Contexte** : Vue calendrier de TOUS les entraînements (multicolore)

**UI et logique**

```
┌──────────────────────────────────────────┐
│ AlertDialog                              │
├──────────────────────────────────────────┤
│ Title: "Calendrier global"               │
├──────────────────────────────────────────┤
│ Content: TableCalendar                   │
│ ┌──────────────────────────────────────┐ │
│ │      Avril 2026          [< >]       │ │
│ ├──────────────────────────────────────┤ │
│ │ Lun Mar Mer Jeu Ven Sam Dim          │ │
│ │  1   2   3   4   5   6   7           │ │
│ │  8   9  10 🔵 12  🔴🟡 14          │ │
│ │         multiple       multiple      │ │
│ │         colors in       colors       │ │
│ │         one day         in one day   │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ Bottom: "12 entraînements en avril"     │
├──────────────────────────────────────────┤
│ Actions: [Fermer]                        │
└──────────────────────────────────────────┘
```

**Gestion multicolore**
- Pour chaque jour, on affiche jusqu'à 5 petits points colorés
- 1 point par figure + couleur de la figure
- Permet de voir en un coup d'oeil la charge d'entraînement
- Distinction visuelle entre "done" (rempli) et "planned" (vide)

---

### 7. JournalEntryFormDialog

**Fichier** : `lib/screens/figures/journal_entry_form_dialog.dart`

**Contexte** : Créer ou éditer une note de journal pour une figure

**UI**

```
┌──────────────────────────────────────────┐
│ AlertDialog                              │
├──────────────────────────────────────────┤
│ Title: "Nouvelle entrée journal"         │
│ ou "Modifier l'entrée"                   │
├──────────────────────────────────────────┤
│ Content:                                 │
│ ┌──────────────────────────────────────┐ │
│ │ TextField (maxLines: 5, multiline)   │ │
│ │ "Décrivez vos notes de progression"  │ │
│ │                                      │ │
│ │ • Difficultés rencontrées            │ │
│ │ • Progrès réalisés                   │ │
│ │ • Points de focus pour demain        │ │
│ │                                      │ │
│ └──────────────────────────────────────┘ │
├──────────────────────────────────────────┤
│ Actions: [Annuler] [Ajouter]             │
│ ou      [Annuler] [Sauver]               │
└──────────────────────────────────────────┘
```

**Règles**
- ✅ Une seule entrée par figure par jour
- 📝 Si une entrée existe pour aujourd'hui, le bouton "+" disparaît
- 📌 Les entrées sont affichées avec date dans FigureDetailDialog

---

### 8. RecordFormDialog

**Fichier** : `lib/screens/figures/record_form_dialog.dart`

**Contexte** : Enregistrer/éditer le record d'une figure (uniquement si learned)

**UI**

```
┌──────────────────────────────────────────┐
│ AlertDialog                              │
├──────────────────────────────────────────┤
│ Title: "Enregistrer mon record"          │
├──────────────────────────────────────────┤
│ Content:                                 │
│ ┌──────────────────────────────────────┐ │
│ │ TextField: "20" (digits only)         │ │
│ │ Record value                          │ │
│ │                                      │ │
│ │ Unité:                                │ │
│ │ [X] Répétitions  [ ] Secondes        │ │
│ │ (ChoiceChip selector)                 │ │
│ └──────────────────────────────────────┘ │
├──────────────────────────────────────────┤
│ Actions: [Annuler] [Sauver]              │
└──────────────────────────────────────────┘
```

**Logique**
- Uniquement accessible depuis FigureDetailDialog
- Uniquement si figure.state == learned
- Enregistre la meilleure valeur + unité

---

## Gestion des figures (CRUD)

### Create (Création)

```dart
// Workflow utilisateur
1. Clic sur FAB (+) dans FiguresScreen
2. FigureFormDialog s'ouvre (sans paramètre figure)
3. Utilisateur:
   - Entre le nom
   - Choisit la couleur
4. Clic "Ajouter"
5. Appel: figureRepository.create(name, color)
6. Firestore: Crée document dans /users/{uid}/figures
7. figuresProvider détecte le changement
8. FiguresScreen se reconstruit avec la nouvelle figure
```

**Données créées**

```json
{
  "id": "auto-generated",
  "name": "Handstand",
  "color": "blue",
  "state": "toLearn",      // État initial
  "startDate": null,
  "endDate": null,
  "recordValue": null,
  "recordUnit": null,
  "order": 0,              // Ajoutée à la fin
  "paused": false
}
```

### Read (Lecture)

**Tous les figures** (avec filtrage couleur)
```dart
figuresProvider.watch()
  → Stream<List<FigureModel>>
  → Filtré par colorFilterProvider
  → Trié par order (custom order)
```

**Une figure spécifique**
```dart
figureByIdProvider(figureId).watch()
  → Provider.family<FigureModel?>
```

**Dates d'entraînement**
```dart
trainingDoneDatesProvider(figureId)      // Effectués
trainingPlannedDatesProvider(figureId)   // Planifiés
```

### Update (Modification)

**Éditer nom/couleur/dates**
```
1. Clic sur FigureCard → FigureDetailDialog
2. Clic bouton édition → FigureFormDialog (avec figure)
3. Modifier les champs
4. Clic "Sauver"
5. figureRepository.update(figure.copyWith(...))
6. Firestore: Met à jour le document
```

**Changer l'état**
```
1. Depuis FigureDetailDialog: clic icône 🔧
2. FigureStatusPickerDialog affiche 3 options
3. Sélectionner nouveau statut
4. figureRepository.update(figure.copyWith(state: newState))
   + Mise à jour automatique des dates
```

**Marquer en pause**
```
1. Depuis FigureDetailDialog: clic ⏸️
2. figure.paused toggle
3. figureRepository.update(figure.copyWith(paused: true/false))
```

**Enregistrer un record**
```
1. Depuis FigureDetailDialog: clic sur RecordDisplay
2. RecordFormDialog s'ouvre
3. Entrer valeur + choisir unité
4. figureRepository.update(figure.copyWith(
     recordValue: value,
     recordUnit: unit
   ))
```

**Réordonnancer**
```
1. Long-press sur FigureCard dans _FigureSliver
2. Drag-and-drop (ReorderableListView)
3. Au drop: figureOrderProvider.reorder(newOrder)
   → Met à jour field "order" de chaque figure
```

### Delete (Suppression)

```
1. Depuis FigureDetailDialog ou FigureFormDialog
2. Clic bouton "Supprimer" (rouge)
3. Confirmation (optionnel)
4. figureRepository.delete(figureId)
5. Firestore: Supprime document
6. Cascade: Supprime aussi:
   - Toutes les notes journal associées
   - Toutes les dates d'entraînement (done + planned)
```

---

## Gestion du journal

### Modèle JournalEntryModel

```dart
class JournalEntryModel {
  final String id;           // ID unique
  final String figureId;     // Référence figure
  final DateTime date;       // Date de l'entrée (jour uniquement)
  final String text;         // Contenu texte
}
```

### Règles métier

1. **Une entrée par jour par figure** : Un utilisateur ne peut avoir qu'une seule entrée le même jour pour la même figure
2. **Affichage** : Les entrées sont affichées dans FigureDetailDialog, triées par date décroissante (plus récente en haut)
3. **Édition** : Cliquer sur une entrée pour l'éditer
4. **Suppression** : Cliquer le X pour supprimer

### Workflow complet

```
Utilisateur visualise FigureDetailDialog
        ↓
S'il n'a pas d'entrée pour aujourd'hui: bouton [+] visible
        ↓
Clic [+] → JournalEntryFormDialog
        ↓
Entre du texte
        ↓
Clic "Ajouter"
        ↓
journalEntryRepository.create(
  JournalEntryModel(
    figureId: figure.id,
    date: today,
    text: texte
  )
)
        ↓
Firestore: Crée document dans /users/{uid}/journal_entries
        ↓
journalEntriesForFigureProvider détecte le changement
        ↓
FigureDetailDialog se reconstruit avec la nouvelle entrée
        ↓
[+] bouton disparaît si entrée existe pour aujourd'hui
```

### Suppression d'une entrée

```
User clique le X sur une JournalEntryTile
        ↓
journalEntryRepository.delete(entryId)
        ↓
Firestore: Supprime document
        ↓
UI se remet à jour
```

---

## Système de calendrier

### Calendrier personnel (FigureCalendarDialog)

**Données utilisées**

```dart
trainingDoneDatesProvider(figureId)       // Set<DateTime>
trainingPlannedDatesProvider(figureId)    // Set<DateTime>
```

**Affichage**

- 🔵 **Rempli** (couleur figure) = Jour où la figure a été entraînée
- ⭕ **Contour** (couleur figure) = Jour où la figure est planifiée
- ◯ **Aujourd'hui** = Border avec couleur primaire
- Blanc = Pas d'entraînement prévu

**Calculs statistiques**

```dart
// Nombre d'entraînements le mois affiché
trainingDaysInMonth = {
  ...doneDates,
  ...plannedDates,
}.where((d) => d >= firstOfMonth && d <= lastOfMonth).length;
```

### Calendrier global (GlobalCalendarDialog)

**Données utilisées**

```dart
allTrainingDoneDatesProvider        // Map<DateTime, List<Color>>
allTrainingPlannedDatesProvider     // Map<DateTime, List<Color>>
```

**Affichage multicolore**

Pour chaque jour, on affiche jusqu'à 5 points:
- 1 point par figure
- Couleur = couleur de la figure
- Plein = done, Vide = planned

**Logique d'exclusion**

Si une figure est à la fois "done" et "planned" le même jour:
- Afficher seulement le point "done" (plein)
- Ne pas afficher le "planned" (évite la redondance)

---

## Filtrage et organisation

### Filtrage par couleur

**Provider**

```dart
colorFilterProvider = StateProvider<FigureColor?>((ref) => null);
```

**UI**

```
1. Clic icône 🎨 dans AppBar → ColorFilterDialog
2. Affiche 6 couleurs + "Toutes"
3. Sélection d'une couleur
4. colorFilterProvider.state = FigureColor.red
```

**Effet**

```dart
figuresProvider.map((figures) => 
  selectedColor == null
    ? figures
    : figures.where((f) => f.color == selectedColor).toList()
)
```

### Tri et organisation

**Ordre par défaut**
1. Par statut (toLearn → learning → learned)
2. Par custom order (field `order`)
3. Alphabétique (si même order)

**Réordonnancement custom**

```
Dans _FigureSliver:
- ReorderableListView permet drag-and-drop
- Au drop: FigureOrderNotifier.reorder(newList)
  → Met à jour field `order` dans Firestore
  → Persist l'ordre custom
```

**Groupement visuel**

```
_FigureSection (statut)
├── _StickyHeader (label + compte)
│   └── Reste visible au scroll
└── _FigureSliver (grille)
    └── FigureCard × N
```

---

## Providers et gestion d'état

### Providers de figures

| Provider | Type | Description |
|----------|------|-------------|
| `figuresProvider` | StreamProvider | Toutes les figures + filtrage couleur + tri |
| `figuresByStateProvider` | Provider.family | Figures d'un statut donné |
| `figureByIdProvider` | Provider.family | Accès une figure par ID |
| `figureOrderProvider` | Provider | Notifier pour réordonnancement |

### Providers d'entraînements

| Provider | Type | Description |
|----------|------|-------------|
| `trainingDoneDatesProvider` | StreamProvider.family | Dates entraînements effectués (une figure) |
| `trainingPlannedDatesProvider` | StreamProvider.family | Dates entraînements planifiés (une figure) |
| `allTrainingDoneDatesProvider` | StreamProvider | Map des dates effectuées (toutes figures) |
| `allTrainingPlannedDatesProvider` | StreamProvider | Map des dates planifiées (toutes figures) |
| `lastTrainingDateProvider` | StreamProvider.family | Dernière date d'entraînement (une figure) |
| `nextTrainingDateProvider` | StreamProvider.family | Prochaine date planifiée (une figure) |
| `nextTrainingDateAfterDayProvider` | StreamProvider.family | Prochaine date après un jour donné |

### Providers de journal

| Provider | Type | Description |
|----------|------|-------------|
| `journalEntriesForFigureProvider` | StreamProvider.family | Toutes les notes d'une figure |
| `todayJournalEntryForFigureProvider` | StreamProvider.family | Note d'aujourd'hui (une figure) |

### Providers de filtre

| Provider | Type | Description |
|----------|------|-------------|
| `colorFilterProvider` | StateProvider | Couleur sélectionnée (null = toutes) |

### Repositories

| Repository | Méthodes principales |
|------------|----------------------|
| `FigureRepository` | `watchAll()`, `create()`, `update()`, `delete()`, `updateOrder()` |
| `JournalEntryRepository` | `create()`, `update()`, `delete()`, `watchByFigure()` |
| `TrainingDoneRepository` | `add()`, `watchByFigure()` |
| `TrainingPlannedRepository` | `plan()`, `watchByFigure()` |

---

## Widgets réutilisables

### FigureCard

**Fichier** : `lib/widgets/figure_card.dart`

**Usage** : Affichage grande format (rectangulaire) d'une figure

**Props**
```dart
FigureCard({
  required FigureModel figure,
  required VoidCallback onTap,
  DateTime? referenceDate,    // Pour calculs de dates contextuels
  bool inkEffect = true,      // Animation clic
})
```

**Affichage**

```
┌─────────────────────────┐
│ 🔵 Figure Name          │
├─────────────────────────┤
│ État: 🤸 En apprentissage│
│ Dernière: 5 jours       │
│ Prochaine: Demain       │
│ Record: 20 reps         │
│ [Si paused] ⏸️ Pause    │
└─────────────────────────┘
```

### ColorPickerRow

**Fichier** : `lib/widgets/color_picker_row.dart`

**Usage** : Sélectionner une couleur parmi 6

**Props**
```dart
ColorPickerRow({
  required FigureColor selected,
  required ValueChanged<FigureColor> onChanged,
})
```

**Affichage**

```
🔴 🟠 🟡 🟢 🔵 🟣
(cercles colorés, avec border si sélectionné)
```

### JournalEntryTile

**Fichier** : `lib/widgets/journal_entry_tile.dart`

**Usage** : Afficher une entrée de journal dans la liste

**Affichage**

```
┌──────────────────────────────────┐
│ 15 mars 2026  Trop difficile...  │ [✏️] [✕]
└──────────────────────────────────┘
```

### RecordDisplay

**Fichier** : `lib/widgets/record_display.dart`

**Usage** : Afficher le record d'une figure

**Affichage**

```
🏆 20 répétitions
ou
🏆 45 secondes
```

---

## Flux d'interaction complets

### Flux 1 : Créer une nouvelle figure

```
┌─ FiguresScreen (écran vide ou avec figures)
│
├─ User clique FAB [+]
│
├─ FigureFormDialog({figure: null})  [mode: création]
│
├─ User:
│  ├─ Entre "Handstand"
│  ├─ Sélectionne couleur 🔵 (bleu)
│  └─ Clique "Ajouter"
│
├─ Validation + appel:
│  └─ figureRepository.create("Handstand", FigureColor.blue)
│
├─ Firestore:
│  └─ Crée /users/{uid}/figures/{id}
│     {
│       name: "Handstand",
│       color: "blue",
│       state: "toLearn",
│       order: 0,
│       ...
│     }
│
├─ figuresProvider détecte changement
│
└─ FiguresScreen se reconstruit
   └─ "Handstand" 🔵 apparaît section "À apprendre"
```

### Flux 2 : Commencer l'apprentissage d'une figure

```
┌─ User clique sur carte "Handstand" (toLearn)
│
├─ FigureDetailDialog s'ouvre
│  └─ Affiche: "À apprendre" + bouton "Commencer"
│
├─ User clique "Commencer l'apprentissage"
│
├─ Appel (peut passer par BeginLearningDialog):
│  └─ figureRepository.update(figure.copyWith(
│       state: FigureState.learning,
│       startDate: today
│     ))
│
├─ Firestore mise à jour
│
├─ figuresProvider détecte changement
│
└─ FiguresScreen se reconstruit
   └─ "Handstand" 🔵 se déplace section "En apprentissage"
      + startDate = aujourd'hui
```

### Flux 3 : Marquer comme maîtrisée + ajouter record

```
┌─ User dans FigureDetailDialog
│  (figure en apprentissage depuis 2 mois)
│
├─ Clique icône 🔧 "Changer statut"
│
├─ FigureStatusPickerDialog affiche:
│  📌 À apprendre | 🤸 En apprentissage | ✅ Maîtrisée
│
├─ User sélectionne "Maîtrisée"
│
├─ Appel:
│  └─ figureRepository.update(figure.copyWith(
│       state: FigureState.learned,
│       endDate: today
│     ))
│
├─ Firestore mise à jour
│
├─ FigureDetailDialog se ferme
│
├─ FiguresScreen se reconstruit
│  └─ "Handstand" déplacée section "Maîtrisées"
│
├─ User clique à nouveau sur "Handstand"
│  └─ FigureDetailDialog se réouvre
│  └─ Affiche maintenant RecordDisplay (vide)
│
├─ User clique sur RecordDisplay
│
├─ RecordFormDialog s'ouvre
│
├─ User:
│  ├─ Entre "20"
│  ├─ Sélectionne "Répétitions"
│  └─ Clique "Sauver"
│
├─ Appel:
│  └─ figureRepository.update(figure.copyWith(
│       recordValue: 20,
│       recordUnit: RecordUnit.reps
│     ))
│
└─ RecordDisplay met à jour: "🏆 20 répétitions"
```

### Flux 4 : Ajouter une note de journal

```
┌─ User visualise FigureDetailDialog pour "Handstand"
│  (figure en apprentissage)
│
├─ Section Journal: "Aucune note" + bouton [+]
│
├─ User clique [+]
│
├─ JournalEntryFormDialog s'ouvre
│
├─ User tape: "Premiers essais difficiles, posture instable"
│
├─ Clique "Ajouter"
│
├─ Appel:
│  └─ journalEntryRepository.create(JournalEntryModel(
│       figureId: "handstand-id",
│       date: today,
│       text: "Premiers essais..."
│     ))
│
├─ Firestore crée document dans /users/{uid}/journal_entries
│
├─ journalEntriesForFigureProvider détecte changement
│
└─ FigureDetailDialog se reconstruit
   └─ Journal affiche: "Aujourd'hui: Premiers essais..."
   └─ Bouton [+] disparaît (déjà une entrée pour aujourd'hui)
```

### Flux 5 : Voir le calendrier personnel et global

```
┌─ User dans FigureDetailDialog ("Handstand")
│
├─ Clique bouton 📅 "Calendrier"
│
├─ FigureCalendarDialog s'ouvre
│
├─ Affiche calendrier complet
│  ├─ 🔵 jours avec entraînement effectué
│  ├─ ⭕ jours avec entraînement planifié
│  └─ Compte: "4 entraînements ce mois"
│
├─ User clique icône [<-] ou [->] pour changer mois
│
├─ Ferme le dialog (clic fermeture)
│
├─ Retour FigureDetailDialog
│
├─ User retourne FiguresScreen
│
├─ Clique bouton 📅 "Calendrier global" (AppBar)
│
├─ GlobalCalendarDialog s'ouvre
│
├─ Affiche calendrier avec TOUS les entraînements
│  ├─ Multicolore (une couleur par figure)
│  ├─ Rempli = done, Vide = planned
│  └─ Compte: "12 entraînements ce mois"
│
└─ User peut voir d'un coup d'oeil la charge d'entraînement
```

---

## Gestion des erreurs et cas limites

### Gestion des erreurs Firestore

Tous les appels repository sont async et peuvent échouer. La UI affiche:

```dart
AsyncValue.when(
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Erreur : $e'),
  data: (data) => ...afficher les données...
)
```

### Cas limite : Utilisateur non authentifié

```
Si repository null (pas d'authentification):
- Affichage état de chargement indéfini
- Les actions CRUD échouent silencieusement
- Nécessite passage par authentication d'abord
```

### Cas limite : Suppression avec dépendances

```
User supprime une figure qui a:
- Notes de journal
- Entraînements effectués
- Entraînements planifiés

Repository effectue suppression cascade:
1. Supprime la figure
2. Supprime tous les journalEntries
3. Supprime toutes les trainingDone
4. Supprime toutes les trainingPlanned
```

---

## Synthèse et architecture

L'onglet **Figures** est architec­turé comme un module **complet et autonome** avec :

✅ **CRUD complet** (créer, lire, mettre à jour, supprimer)  
✅ **Gestion d'état réactive** via Riverpod StreamProviders  
✅ **Organisation visuelle** (tri par statut, sections sticky, drag-and-drop)  
✅ **Filtrage dynamique** (par couleur, en temps réel)  
✅ **Visualisation calendaire** (personnelle + globale)  
✅ **Journalisation** (notes de progression par jour)  
✅ **Enregistrement de records** (pour figures maîtrisées)  
✅ **Synchronisation cloud** (Firestore temps réel)  

Le module est **modulaire et réutilisable** avec des composants d'interface bien séparés (screen, dialogs, widgets) et une logique métier claire (repositories, providers).

---

*Dernière mise à jour : Juin 2026*
