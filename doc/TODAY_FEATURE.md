# 📚 Documentation - Onglet Today

## Vue d'ensemble

L'onglet **Today** est l'interface d'exécution quotidienne des entraînements. C'est ici que l'utilisateur voit les figures planifiées pour **aujourd'hui** et **marque comme effectuées** celles qu'il a travaillées, avec la possibilité d'ajouter des **notes de progression**.

### Objectifs principaux

- 📋 **Afficher** les figures à entraîner aujourd'hui (depuis la planification)
- ✅ **Marquer** les figures comme effectuées
- 📝 **Ajouter/modifier** des notes de session
- 🏆 **Promouvoir** une figure de "apprentissage" à "maîtrisée"
- 👁️ **Consulter** la dernière note de journal pour une figure
- 📊 **Voir les records** pour les figures maîtrisées

---

## Table des matières

1. [Architecture générale](#architecture-générale)
2. [Modèles de données](#modèles-de-données)
3. [Écrans et dialogues](#écrans-et-dialogues)
4. [Validation des entraînements](#validation-des-entraînements)
5. [Gestion des notes](#gestion-des-notes)
6. [Promotion de figures](#promotion-de-figures)
7. [Providers et gestion d'état](#providers-et-gestion-détat)
8. [Flux d'interaction complets](#flux-dinteraction-complets)
9. [États et transitions](#états-et-transitions)

---

## Architecture générale

### Vue hiérarchique des composants

```
TodayScreen (écran principal)
├── SliverAppBar (titre)
│
├── États:
│   ├── Chargement (CircularProgressIndicator)
│   ├── Vide (noFiguresToday + icône batterie)
│   ├── Terminé (allDone banner ✅)
│   └── Normal
│
└── SliverGrid (grille 3 colonnes)
    └── FigureSquareCard × N
        ├── Clic: TodayTrainingDialog
        └── Long-press: Annuler si déjà effectué

TodayTrainingDialog (validation + notes)
├── TextEditingController (notes)
├── Lecture todayJournalEntryForFigureProvider (notes existantes)
├── Actions:
│   ├── ⭐ Marquer comme maîtrisée (si learning)
│   ├── 🏆 Enregistrer record (si learned)
│   └── ✅ Valider (ajouter TrainingDone)
└── Sur validation:
    ├── trainingDoneRepository.add()
    └── journalEntryRepository.create/update()

LastJournalEntryDialog (bonus)
├── Affiche dernière note
└── Affiche record (si learned)
```

### Couches architecturales

```
┌─────────────────────────────────────────┐
│   TodayScreen (ConsumerWidget)          │  UI
│   - Affichage figures du jour           │
│   - Grille avec marquage effectué       │
│   - Transition vers dialogues           │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   Providers (State Management)                    │  State
│   ├── todayProvider (date sans heure)             │
│   ├── todayFiguresProvider (figures planifiées)  │
│   ├── todayDoneIdsProvider (IDs effectuées)      │
│   ├── todayJournalEntryForFigureProvider (notes) │
│   └── isFigureDoneTodayProvider (statut/figure)  │
└──────────────┬────────────────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   Repositories (Data Access)                      │  Data
│   ├── TrainingDoneRepository                      │
│   │   - add(TrainingDoneModel)                    │
│   │   - watchByDate(today)                        │
│   │   - delete(figureId, date)                    │
│   ├── JournalEntryRepository                      │
│   │   - create(JournalEntryModel)                 │
│   │   - update(JournalEntryModel)                 │
│   │   - watchByFigureAndDate(figureId, today)    │
│   └── FigureRepository                            │
│       - update(FigureModel)                       │
└──────────────┬────────────────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   Firestore Collections:                          │  Backend
│   ├── /users/{uid}/training_planned               │
│   │   (source: Planning tab)                      │
│   ├── /users/{uid}/training_done                  │
│   │   (créé: Today tab)                           │
│   ├── /users/{uid}/journal_entries                │
│   │   (créé/modifié: Today tab)                   │
│   └── /users/{uid}/figures                        │
│       (modifié: state change)                     │
└─────────────────────────────────────────────────────┘
```

---

## Modèles de données

### TrainingDoneModel

Représente un entraînement effectué/complété.

```dart
class TrainingDoneModel {
  final String figureId;    // Référence à la figure
  final DateTime date;      // Date d'entraînement (jour uniquement)
}
```

**Collection Firestore** : `/users/{uid}/training_done/{id}`

```json
{
  "figureId": "handstand-id",
  "date": "2026-03-15T00:00:00.000Z",
  "id": "auto-generated"
}
```

**Création** : Lors de la validation d'un entraînement dans TodayTrainingDialog

### JournalEntryModel

Notes de session (voir [documentation Figures](FIGURES_FEATURE.md#journalentrymodel))

**Utilisation dans Today** : Créer/modifier les notes d'aujourd'hui lors de la validation

### FigureModel

Voir [documentation Figures](FIGURES_FEATURE.md#figuremodel)

**Champs pertinents pour Today** :
- `state` : FigureState (utilisé pour afficher bouton promotion)
- `paused` : Si figure est en pause (exclue du planning)

---

## Écrans et dialogues

### 1. TodayScreen (Écran principal)

**Fichier** : `lib/screens/today/today_screen.dart`

**Responsabilités**
- Afficher les figures planifiées aujourd'hui
- Afficher le statut "effectué" visuellement
- Naviguer vers TodayTrainingDialog au clic
- Permettre l'annulation (long-press)
- Afficher états (vide, chargement, tout effectué)

**Structure visuelle**

```
┌──────────────────────────────────────────┐
│ SliverAppBar (expandedHeight: 120)       │
│ ┌────────────────────────────────────────┐
│ │ Title: "Séance du jour"                │
│ │ (FlexibleSpaceBar)                     │
│ └────────────────────────────────────────┘
├──────────────────────────────────────────┤
│ État vide:                               │
│ ┌────────────────────────────────────────┐
│ │ 🔋 (icône batterie)                   │
│ │ "Aucune figure aujourd'hui"            │
│ │ "Planifiez vos entraînements"          │
│ │ (SliverFillRemaining)                  │
│ └────────────────────────────────────────┘
│                          OU
│ État tout effectué:                      │
│ ┌────────────────────────────────────────┐
│ │ ✅ Excellent, tout est fait!          │
│ │ (banner vert avec icon)                │
│ └────────────────────────────────────────┘
│                          OU
│ État normal:                             │
│ ┌─ SliverGrid (3 colonnes) ─────────────┐
│ │ 🔵 Handstand   🟡 Planche   🟢 M.Up   │
│ │ (carré)        (carré)     (carré)    │
│ │                                       │
│ │ [Overlay ✅]   [Pas overlay]  [...]   │
│ │ (si effectué)  (si non)               │
│ │                                       │
│ │ Long-press:    Clic:                  │
│ │ └─ Annuler     └─ Validation dialog   │
│ │                                       │
│ └───────────────────────────────────────┘
└──────────────────────────────────────────┘
```

**États possibles**

| État | Condition | Affichage |
|------|-----------|-----------|
| **Chargement** | AsyncValue.loading | CircularProgressIndicator |
| **Erreur** | AsyncValue.error | Texte erreur |
| **Vide** | figures.isEmpty | Banner "Aucune figure" + icône batterie |
| **Tout effectué** | allDone = true | Banner ✅ "Excellent" (vert) |
| **Normal** | figures.isNotEmpty && !allDone | Grille 3 colonnes |

**Interactions**

1. **Clic sur figure** : Ouvre TodayTrainingDialog
   - Permet valider l'entraînement
   - Permet ajouter/modifier notes

2. **Long-press sur figure effectuée** : Annule (revenir "non effectué")
   - Appel trainingDoneRepository.delete()
   - Marquer comme non effectué

3. **Visuellement** : ✅ Overlay sur carte si effectuée

---

### 2. TodayTrainingDialog

**Fichier** : `lib/screens/today/today_training_dialog.dart`

**Contexte** : Valider un entraînement + ajouter notes (au clic sur figure)

**UI**

```
┌──────────────────────────────────────────┐
│ AlertDialog                              │
├──────────────────────────────────────────┤
│ Title: [couleur] Figure Name  [icônes]   │
│                                          │
│ [Si learning] ⭐ Mark as learned        │
│ [Si learned]  🏆 Edit record             │
├──────────────────────────────────────────┤
│ Content:                                 │
│ ┌──────────────────────────────────────┐ │
│ │ Remarques de séance:                 │
│ │ ┌──────────────────────────────────┐ │
│ │ │ TextField (maxLines: 4)          │ │
│ │ │ "Décrivez votre séance..."       │ │
│ │ │                                  │ │
│ │ │ (Pré-rempli si note existante) │ │
│ │ └──────────────────────────────────┘ │
│ │                                      │ │
│ │ Vous avez complété cette figure     │ │
│ │ aujourd'hui ✅ (si déjà validée)    │ │
│ └──────────────────────────────────────┘ │
├──────────────────────────────────────────┤
│ Actions:                                 │
│ [Annuler] [✅ Valider]                   │
│ (ou [Modifier] si déjà fait)            │
└──────────────────────────────────────────┘
```

**Champs**

| Champ | Type | Obligatoire | Comportement |
|-------|------|------------|--------------|
| **Notes** | TextField | ❌ Non | Pré-rempli si entrée exist. aujourd'hui |
| **Bouton ⭐** | IconButton | ❌ Optionnel | Visible si state = learning |
| **Bouton 🏆** | IconButton | ❌ Optionnel | Visible si state = learned |

**Logique de chargement des notes**

```dart
todayJournalEntryForFigureProvider(figureId):
├─ Cherche entrée du jour pour cette figure
├─ Si trouvée: pré-remplit TextField
└─ Sauvegarde référence (_existingEntry)
   → Pour savoir si créer ou modifier
```

**Workflow de validation**

```
User clique figure dans grille
        ↓
TodayTrainingDialog s'ouvre
        ↓
[Optionnel] User écrit notes
        ↓
[Optionnel] User clique ⭐ pour promouvoir (si learning)
        ↓
User clique "Valider" ✅
        ↓
_validate() appelée:
├─ trainingDoneRepository.add(TrainingDoneModel(...))
│  → Crée doc Firestore
│  → todayDoneProvider détecte changement
│  → Figure affiche ✅ overlay
│
└─ Si text non-vide:
   ├─ Si _existingEntry != null:
   │  └─ journalRepository.update()
   │     (modifier note existante)
   │
   └─ Sinon:
      └─ journalRepository.create()
         (créer nouvelle note)
        ↓
Dialog se ferme
        ↓
TodayScreen se reconstruit
```

---

### 3. TodayTrainingDialog - Promotion d'une figure

**Accessibilité** : Bouton ⭐ visible si `figure.state == FigureState.learning`

**Workflow**

```
User dans TodayTrainingDialog
        ↓
Clic bouton ⭐ "Marquer comme maîtrisée"
        ↓
Confirmation dialog:
"Marquer 'Handstand' comme maîtrisée?"
        ↓
User clique "Confirmer"
        ↓
figureRepository.update(figure.copyWith(
  state: FigureState.learned,
  endDate: today  // Date de maîtrise = aujourd'hui
))
        ↓
Firestore met à jour document
        ↓
figuresProvider détecte changement
        ↓
Dialog se ferme (optionnel popup "Félicitations!")
        ↓
TodayScreen se reconstruit
        ↓
Bouton ⭐ est remplacé par bouton 🏆
```

---

### 4. TodayTrainingDialog - Enregistrement d'un record

**Accessibilité** : Bouton 🏆 visible si `figure.state == FigureState.learned`

**Workflow**

```
User dans TodayTrainingDialog (figure maîtrisée)
        ↓
Clic bouton 🏆 "Enregistrer record"
        ↓
RecordFormDialog s'ouvre
        ↓
User entre valeur + choisit unité
        ↓
Clic "Sauver"
        ↓
figureRepository.update(
  figure.copyWith(recordValue, recordUnit)
)
        ↓
RecordFormDialog se ferme
        ↓
TodayTrainingDialog reste ouvert
```

---

### 5. LastJournalEntryDialog

**Fichier** : `lib/screens/today/last_journal_entry_dialog.dart`

**Contexte** : Afficher la dernière note de journal (bonus, accessible depuis d'autres écrans)

**UI**

```
┌──────────────────────────────────────────┐
│ AlertDialog                              │
├──────────────────────────────────────────┤
│ Title: [couleur] Figure Name             │
├──────────────────────────────────────────┤
│ Content:                                 │
│ ┌──────────────────────────────────────┐ │
│ │ 15 mars 2026 (date au format court) │ │
│ │                                      │ │
│ │ "Premiers essais difficiles, posture│ │
│ │  instable mais progression visible" │ │
│ │ (texte de la dernière note)         │ │
│ │                                      │ │
│ │ [Si learned]                         │ │
│ │ ─────────────────────────────────── │ │
│ │ 🏆 20 répétitions                    │ │
│ │ (RecordDisplay)                      │ │
│ └──────────────────────────────────────┘ │
├──────────────────────────────────────────┤
│ Actions: [Fermer]                        │
└──────────────────────────────────────────┘
```

**Logique**

```dart
journalEntriesForFigureProvider(figureId):
├─ Retourne ALL notes pour cette figure
├─ Triées par date (descendante)
└─ first = dernière (la plus récente)

Affichage:
├─ Dernière date
├─ Dernier texte
└─ [Si learned] Affiche aussi record
```

---

## Validation des entraînements

### Concept

Un entraînement est "effectué" quand l'utilisateur le valide dans TodayTrainingDialog. Cela crée un document `TrainingDoneModel` dans Firestore.

### Workflow complet

```
AVANT:
├─ trainingPlanned(Handstand, 2026-03-15)
└─ trainingDone(Handstand, 2026-03-15) = NOT EXISTS

User clique Handstand dans TodayScreen
        ↓
TodayTrainingDialog s'ouvre
        ↓
[Optionnel] Écrit notes
        ↓
Clic "Valider"
        ↓
_validate() exécutée:
├─ trainingDoneRepository.add(
│    TrainingDoneModel(
│      figureId: "handstand",
│      date: 2026-03-15
│    )
│  )
│  → Firestore crée document
│  → todayDoneProvider détecte changement
│  → todayDoneIdsProvider se réexécute
│
└─ Si notes non-vides:
   ├─ Si existingEntry != null:
   │  └─ journalRepository.update()
   │
   └─ Sinon:
      └─ journalRepository.create()

APRÈS:
├─ trainingPlanned(Handstand, 2026-03-15) = EXISTS
├─ trainingDone(Handstand, 2026-03-15) = EXISTS ✅
└─ journalEntry(Handstand, 2026-03-15) = EXISTS (optionnel)
```

### Marquage visuel

```
TodayScreen grille:
├─ Figure NOT done: FigureSquareCard(isDone: false)
│  └─ Pas d'overlay
│
└─ Figure IS done: FigureSquareCard(isDone: true)
   └─ Overlay ✅ semi-transparent
```

### Annulation (Long-press)

```
User long-press sur figure effectuée
        ↓
_handleLongPress() appelée
        ↓
trainingDoneRepository.delete(figureId, date)
        ↓
Firestore supprime document TrainingDone
        ↓
todayDoneProvider détecte suppression
        ↓
todayDoneIdsProvider se réexécute
        ↓
Figure perd overlay ✅
        ↓
État revient à "non effectué"
```

---

## Gestion des notes

### Création de note

```
User valide entraînement avec notes non-vides
        ↓
journalRepository.create(
  JournalEntryModel(
    id: '',
    figureId: 'handstand',
    date: today,
    text: 'Premiers essais...'
  )
)
        ↓
Firestore crée document:
/users/{uid}/journal_entries/{auto-id}
  figureId: "handstand"
  date: 2026-03-15
  text: "Premiers essais..."
```

### Modification de note

```
User avait note d'aujourd'hui pour cette figure
        ↓
_existingEntry = note trouvée
        ↓
User valide avec texte modifié
        ↓
journalRepository.update(
  existingEntry.copyWith(text: newText)
)
        ↓
Firestore met à jour document
```

### Règle métier

✅ **Une seule note par figure par jour**

```dart
todayJournalEntryForFigureProvider:
└─ watchByFigureAndDate(figureId, today)
   → Retourne l'entrée du jour (ou null)
```

**Comportement** :
- Si note existe → Pré-remplir + modification au validate
- Si pas note → Création au validate (si texte non-vide)

---

## Promotion de figures

### Concept

Un utilisateur peut **promouvoir une figure** directement depuis la validation d'aujourd'hui. Cela change son état de `learning` à `learned`.

### Workflow

```
User dans TodayTrainingDialog
        ↓
Figure.state = learning
        ↓
Bouton ⭐ "Marquer comme maîtrisée" visible
        ↓
Clic ⭐
        ↓
Confirmation dialog
        ↓
User confirme
        ↓
figureRepository.update(figure.copyWith(
  state: FigureState.learned,
  endDate: today  // Aujourd'hui
))
        ↓
Firestore met à jour
        ↓
figuresProvider détecte changement
        ↓
Bouton ⭐ remplacé par 🏆
        ↓
Peut maintenant ajouter record
```

### Différence avec FigureDetailDialog

| Dialog | Contexte | Bouton |
|--------|----------|--------|
| **TodayTrainingDialog** | Validation jour | ⭐ Marquer (rapide) |
| **FigureDetailDialog** | Détails | 🔧 Changer statut |

---

## Providers et gestion d'état

### Providers principaux

| Provider | Type | Description |
|----------|------|-------------|
| `todayProvider` | Provider | Date d'aujourd'hui (sans heure) |
| `todayPlannedProvider` | StreamProvider | TrainingPlanned pour aujourd'hui |
| `todayDoneProvider` | StreamProvider | TrainingDone pour aujourd'hui |
| `todayFiguresProvider` | Provider | FigureModels planifiées aujourd'hui |
| `todayDoneIdsProvider` | Provider | Set des IDs effectuées aujourd'hui |
| `isFigureDoneTodayProvider` | Provider.family | Booléen: figure effectuée? |
| `todayJournalEntryForFigureProvider` | StreamProvider.family | Note du jour pour une figure |
| `journalEntriesForFigureProvider` | StreamProvider.family | Toutes les notes (pour LastJournalEntryDialog) |

### Repositories

| Repository | Méthodes |
|------------|----------|
| `TrainingDoneRepository` | `add()`, `delete()`, `watchByDate()` |
| `JournalEntryRepository` | `create()`, `update()`, `watchByFigureAndDate()`, `watchByFigure()` |
| `FigureRepository` | `update()` (pour changer state) |

---

## Flux d'interaction complets

### Flux 1 : Valider un entraînement simple

```
┌─ User voit TodayScreen
│  Grille 3 colonnes avec figures planifiées
│  Ex: 🔵 Handstand, 🟡 Planche, 🟢 M.Up
│
├─ Clic sur 🔵 Handstand
│  → TodayTrainingDialog s'ouvre
│
├─ [Optionnel] Écrit notes: "Bonne séance!"
│
├─ Clic "Valider" ✅
│
├─ _validate() exécutée:
│  ├─ trainingDoneRepository.add(
│  │    TrainingDoneModel(
│  │      figureId: "handstand",
│  │      date: today
│  │    )
│  │  )
│  │
│  └─ journalRepository.create(
│       JournalEntryModel(
│         figureId: "handstand",
│         date: today,
│         text: "Bonne séance!"
│       )
│     )
│
├─ Firestore: 2 documents créés
│
├─ Providers détectent changement:
│  ├─ todayDoneProvider
│  ├─ todayDoneIdsProvider
│  └─ todayJournalEntryForFigureProvider
│
├─ Dialog se ferme
│
└─ TodayScreen se reconstruit
   └─ 🔵 Handstand affiche ✅ overlay
      (isDone = true)
```

### Flux 2 : Promouvoir une figure

```
┌─ User valide entraînement
│  Figure.state = learning
│
├─ TodayTrainingDialog affiche ⭐
│
├─ [Optionnel] Écrit notes
│
├─ Clic ⭐ "Marquer comme maîtrisée"
│
├─ Confirmation dialog:
│  "Marquer 'Handstand' comme maîtrisée?"
│
├─ User clique "Confirmer"
│
├─ figureRepository.update(figure.copyWith(
│    state: FigureState.learned,
│    endDate: today
│  ))
│
├─ Firestore met à jour /figures/handstand
│  state: "learned"
│  endDate: 2026-03-15
│
├─ figuresProvider détecte changement
│
├─ Dialog disparaît (optionnel popup)
│
├─ TodayTrainingDialog se reconstruit
│  ├─ Bouton ⭐ disparaît
│  └─ Bouton 🏆 apparaît
│
└─ User peut cliquer 🏆 pour ajouter record
```

### Flux 3 : Ajouter un record après promotion

```
┌─ Figure vient d'être promue (state = learned)
│
├─ TodayTrainingDialog affiche 🏆
│
├─ Clic 🏆 "Enregistrer record"
│
├─ RecordFormDialog s'ouvre
│
├─ User:
│  ├─ Entre "20"
│  └─ Sélectionne "Répétitions"
│
├─ Clic "Sauver"
│
├─ figureRepository.update(figure.copyWith(
│    recordValue: 20,
│    recordUnit: RecordUnit.reps
│  ))
│
├─ RecordFormDialog se ferme
│
└─ TodayTrainingDialog remains ouvert
   avec nouvelle valeur de record
```

### Flux 4 : Modifier une note existante

```
┌─ User valide même figure deux fois dans la journée
│  (Ex: matin = note A, soir = note B)
│
├─ Première validation: créé note "Matin: difficile"
│
├─ Plus tard dans la journée...
│
├─ User clic sur figure à nouveau
│
├─ TodayTrainingDialog s'ouvre
│
├─ todayJournalEntryForFigureProvider détecte note existante
│
├─ TextField pré-rempli: "Matin: difficile"
│
├─ _existingEntry = note trouvée
│
├─ User modifie: "Matin: difficile. Soir: mieux!"
│
├─ Clic "Valider"
│
├─ journalRepository.update(
│    existingEntry.copyWith(
│      text: "Matin: difficile. Soir: mieux!"
│    )
│  )
│
├─ Note mise à jour dans Firestore
│
└─ Text complet: "Matin: difficile. Soir: mieux!"
```

### Flux 5 : Voir la dernière note

```
┌─ User accède LastJournalEntryDialog
│  (Ex: depuis FigureDetailDialog)
│
├─ journalEntriesForFigureProvider(figureId)
│  → Tous les notes (toutes les dates)
│  → Triées par date (descendante)
│
├─ first = dernière note (la plus récente)
│
├─ Affichage:
│  ├─ Date: "15 mars 2026"
│  ├─ Texte: "Grands progrès!"
│  └─ [Si learned] Record: "20 reps"
│
└─ User peut fermer dialog
```

### Flux 6 : Tout est effectué

```
┌─ User a validé TOUTES les figures du jour
│  figures.every((f) => doneIds.contains(f.id))
│
├─ allDone = true
│
├─ TodayScreen affiche banner:
│  "✅ Excellent, tout est fait!"
│  (vert, en haut du contenu)
│
└─ Motivation visuelle pour l'utilisateur
```

### Flux 7 : Aucune figure aujourd'hui

```
┌─ todayFiguresProvider retourne liste vide
│  (Aucune figure planifiée aujourd'hui)
│
├─ TodayScreen affiche SliverFillRemaining
│
├─ Affichage:
│  ├─ Icône batterie 🔋 (vide)
│  ├─ "Aucune figure aujourd'hui"
│  └─ "Planifiez vos entraînements"
│
└─ Invite à utiliser Planning tab
```

### Flux 8 : Annuler un entraînement effectué

```
┌─ User a validé 🔵 Handstand
│  Figure affiche ✅ overlay
│
├─ User change d'avis
│
├─ Long-press sur 🔵 Handstand
│
├─ _handleLongPress() appelée
│
├─ trainingDoneRepository.delete(
│    figureId: "handstand",
│    date: today
│  )
│
├─ Firestore supprime TrainingDone
│
├─ todayDoneProvider détecte suppression
│
├─ todayDoneIdsProvider se réexécute
│  → "handstand" n'est plus dans l'ensemble
│
├─ TodayScreen se reconstruit
│
└─ 🔵 Handstand perd overlay ✅
   (isDone = false)
```

---

## États et transitions

### État d'une figure dans Today

```
┌─────────────────────────────┐
│   Figure NOT DONE           │
│ ┌────────────────────────┐  │
│ │ Carré simple (pas ✅)  │  │
│ │ Clic: valider          │  │
│ │ Long-press: N/A        │  │
│ └────────────────────────┘  │
└────────────┬────────────────┘
             │ User valide
             ▼
┌─────────────────────────────┐
│   Figure DONE               │
│ ┌────────────────────────┐  │
│ │ Carré avec ✅ overlay  │  │
│ │ Clic: modifier notes   │  │
│ │ Long-press: annuler    │  │
│ └────────────────────────┘  │
└─────────────────────────────┘
```

### État de la note pour un jour/figure

```
┌─────────────────────────────┐
│   NO NOTE                   │
│ (JournalEntry not exists)   │
└────────────┬────────────────┘
             │ User valide avec texte
             ▼
┌─────────────────────────────┐
│   NOTE EXISTS               │
│ TextField pré-rempli        │
│ (JournalEntry created)      │
└────────────┬────────────────┘
             │ User modifie et valide
             ▼
┌─────────────────────────────┐
│   NOTE UPDATED              │
│ Text modifié                │
│ (JournalEntry updated)      │
└─────────────────────────────┘
```

---

## Interactions avec autres onglets

### Today ↔ Planning

```
Planning tab:
└─ Ajoute figure à aujourd'hui
   → trainingPlanned(figureId, today)

Today tab:
└─ Affiche figure planifiée aujourd'hui
   → todayFiguresProvider (filtre planned)
```

### Today ↔ Figures

```
Figures tab:
├─ Gère FigureModel (state, dates, etc.)
└─ Affiche DetailDialog avec journal history

Today tab:
├─ Valide entraînement (crée TrainingDone)
├─ Ajoute notes (crée JournalEntry)
└─ Promeut figure (change state = learned)

Both:
└─ Partent même source Firestore
```

### Today ↔ Records

```
Records tab:
└─ Affiche historique complet des entraînements
   (tous les TrainingDone triés)

Today tab:
└─ Crée UN document TrainingDone par validation
   (contribue à l'historique)
```

---

## Gestion des erreurs et cas limites

### Erreur de synchronisation Firestore

```dart
todayFiguresProvider.when(
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Center(child: Text('Erreur : $e')),
  data: (figures) => ...
)
```

### Cas limite : Valider sans notes

```
User clique Valider sans texte
        ↓
text.trim().isEmpty = true
        ↓
trainingDoneRepository.add() exécutée
        ↓
journalRepository.create() NOT exécutée
        ↓
Résultat:
├─ TrainingDone créé ✅
└─ JournalEntry pas créé (optionnel)
```

### Cas limite : Modifier note plusieurs fois

```
Même jour, même figure
1. Matin: User valide + note "Difficile"
   → create(JournalEntry)
   → _existingEntry = nouvelle note

2. Soir: User valide + note "Mieux!"
   → update(_existingEntry) avec nouveau texte
   → Un seul document final
```

### Cas limite : Promouvoir déjà maîtrisée

```
Figure.state = learned (déjà maîtrisée)
        ↓
Bouton ⭐ NOT visible (condition: state == learning)
        ↓
User voit bouton 🏆 record à la place
```

---

## Synthèse et architecture

L'onglet **Today** est une **interface de validation quotidienne** simple mais puissante avec :

✅ **Vue jour** des figures planifiées  
✅ **Validation rapide** avec marquage visuel  
✅ **Notes de session** créées/modifiées à la validation  
✅ **Promotion directe** de figures  
✅ **Enregistrement de records** post-promotion  
✅ **Annulation facile** (long-press)  
✅ **États visuels clairs** (effectué = ✅, tout fait = banner vert)  
✅ **Synchronisation temps réel** (Firestore streams)  

Le module crée les **TrainingDone** (historique) et **JournalEntry** (notes) et permet les **promotions de figures** en un seul endroit optimisé pour la validation quotidienne.

---

*Dernière mise à jour : Juin 2026*
