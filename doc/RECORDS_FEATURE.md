# 📚 Documentation - Onglet Records

## Vue d'ensemble

La page **Records** est une interface d'affichage simple et lisible des records enregistrés pour les figures maîtrisées. Elle liste toutes les figures avec state = `learned` qui possèdent un record enregistré (recordValue + recordUnit).

### Responsabilités

- Afficher la liste des figures maîtrisées avec leurs records
- Afficher la valeur du record et son unité (répétitions ou secondes)
- Filtrer automatiquement les figures sans record enregistré

---

## Table des matières

1. [Architecture générale](#architecture-générale)
2. [Modèles de données](#modèles-de-données)
3. [Écrans et composants](#écrans-et-composants)
4. [Affichage des records](#affichage-des-records)
5. [Providers et gestion d'état](#providers-et-gestion-détat)
6. [Interactions avec autres onglets](#interactions-avec-autres-onglets)

---

## Architecture générale

### Vue hiérarchique des composants

```
RecordsScreen (écran principal)
├── AppBar (titre + actions)
│
├── CustomScrollView
│   └── SliverList
│       └── _FigureSliver
│           └── _RecordCard × N
│               (figures learned uniquement)

Intégrations:
├── FigureModel (source des records)
├── figuresByStateProvider(learned)
└── FigureRepository (CRUD)
```

### Couches architecturales

```
┌─────────────────────────────────────────┐
│   RecordsScreen (ConsumerWidget)        │  UI
│   - Affichage figures maîtrisées        │
│   - Affichage records                   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   Providers (State Management)                    │  State
│   ├── figuresByStateProvider(FigureState.learned) │
│   └── figuresProvider (source)                    │
└──────────────┬────────────────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   Repository (Data Access)                        │  Data
│   └── FigureRepository                            │
│       - watchAll()                                │
└──────────────┬────────────────────────────────────┘
               │
┌──────────────▼────────────────────────────────────┐
│   Firestore Collections:                          │  Backend
│   └── /users/{uid}/figures                        │
│       (recordValue, recordUnit, state=learned)    │
└─────────────────────────────────────────────────────┘
```

---

## Modèles de données

### FigureModel - Champs de record

Les records sont stockés **dans le modèle `FigureModel`** (voir [documentation Figures](FIGURES_FEATURE.md#figuremodel)).

**Champs pertinents pour Records** :

```dart
class FigureModel {
  final String id;
  final String name;
  final FigureColor color;
  final FigureState state;              // ✅ Doit être = FigureState.learned
  final DateTime? endDate;              // Date de maîtrise
  final int? recordValue;               // 🏆 Valeur du record (ex: 20)
  final RecordUnit? recordUnit;         // 🏆 Unité (reps ou seconds)
  // ... autres champs
}

enum RecordUnit { reps, seconds }

extension RecordUnitExtension on RecordUnit {
  String getUnit(int? nb) {
    switch (this) {
      case RecordUnit.reps:
        return nb == 1 ? 'répétition' : 'répétitions';
      case RecordUnit.seconds:
        return nb == 1 ? 'seconde' : 'secondes';
    }
  }
}
```

**Stockage Firestore** : `/users/{uid}/figures/{id}`

```json
{
  "id": "handstand-id",
  "name": "Handstand",
  "color": "blue",
  "state": "learned",
  "endDate": "2026-02-15T00:00:00.000Z",
  "recordValue": 20,
  "recordUnit": "reps",
  "startDate": "2026-01-15T00:00:00.000Z"
}
```



---

## Écrans et composants

### 1. RecordsScreen (Écran principal)

**Fichier** : `lib/screens/records/records_screen.dart`

**Responsabilités**
- Charger les figures maîtrisées (state = learned)
- Afficher une liste de cartes avec records
- Filtrer les figures sans record
- Navigation basique

**Structure visuelle**

```
┌──────────────────────────────────────┐
│ AppBar                               │
│ "Records"                            │
├──────────────────────────────────────┤
│ CustomScrollView (SliverList)        │
│                                      │
│ ┌─ Record Card 1 ─────────────────┐ │
│ │ ║ Handstand       20 répétitions │ │
│ │ ║ (border couleur bleu, épais)   │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌─ Record Card 2 ─────────────────┐ │
│ │ ║ Planche        45 secondes     │ │
│ │ ║ (border couleur jaune)         │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌─ Record Card 3 ─────────────────┐ │
│ │ ║ Muscle Up      12 répétitions  │ │
│ │ ║ (border couleur verte)         │ │
│ └──────────────────────────────────┘ │
│                                      │
│ [Figures maîtrisées sans record     │
│  ne sont PAS affichées]              │
│                                      │
└──────────────────────────────────────┘
```

**Logique**

```dart
RecordsScreen:
├─ ref.read(figuresByStateProvider(FigureState.learned))
│  → Figures avec state = "learned"
│
└─ _RecordCard affiche seulement si:
   ├─ figureRecordValue != null
   └─ figureRecordUnit != null
   
Sinon: SizedBox.shrink() (invisible)
```

**États possibles**

| État | Affichage |
|------|----------|
| **Chargement** | CircularProgressIndicator |
| **Erreur** | Texte erreur |
| **Aucune figure learned avec record** | Liste vide |
| **Figures learned sans record** | Exclues automatiquement |

---

### 2. _RecordCard (Composant de carte)

**Composant** : Widget interne de RecordsScreen

**UI**

```
┌───────────────────────────────────────────┐
│ ║ Handstand                20 répétitions  │
│ ║ (2px left + right border color figure) │
└───────────────────────────────────────────┘
```

**Propriétés**

```dart
_RecordCard({
  required FigureModel figure,
})

Affichage:
├─ Nom figure (title style, bold)
├─ Valeur record + unité formatée
└─ Border gauche + droite (couleur figure, épaisseur 10)
```

**Filtrage**

```dart
if (figureRecordValue == null || figureRecordUnit == null) {
  return const SizedBox.shrink();  // Invisible
}
```

**Données affichées**

| Élément | Source | Format |
|---------|--------|--------|
| **Nom** | figure.name | Texte bold, taille medium |
| **Valeur** | figure.recordValue | Integer (ex: 20) |
| **Unité** | figure.recordUnit.getUnit(value) | String formé (ex: "répétitions") |
| **Couleur** | figure.color.color | Border left/right |





## Affichage des records

### RecordDisplay Widget

**Fichier** : `lib/widgets/record_display.dart`

**Usage** : Composant réutilisable pour afficher un record

**UI**

```
🏆 Record : 20 répétitions
  (icône + texte formaté)
```

**Props**

```dart
RecordDisplay({
  required FigureModel figure,
})
```

**Logique**

```dart
if (figure.recordValue == null || figure.recordUnit == null) {
  return SizedBox.shrink();  // Invisible
}

// Sinon affiche:
"Record : {recordValue} {recordUnit.getUnit(recordValue)}"
// Ex: "Record : 20 répétitions"
```

**Affichage via widget** :

Le widget RecordDisplay est utilisé dans **_RecordCard** pour afficher le record dans RecordsScreen.

### Formatage de l'unité

```dart
RecordUnit.reps.getUnit(20)        → "répétitions"
RecordUnit.reps.getUnit(1)         → "répétition"
RecordUnit.seconds.getUnit(45)     → "secondes"
RecordUnit.seconds.getUnit(1)      → "seconde"
```

---

## Providers et gestion d'état

### Providers utilisés

| Provider | Type | Description |
|----------|------|-------------|
| `figuresByStateProvider(FigureState.learned)` | Provider.family | Figures maîtrisées |
| `figuresProvider` | StreamProvider | Source (watch all) |

### Repositories

| Repository | Méthodes |
|------------|----------|
| `FigureRepository` | `watchAll()`, `update()` (record), `delete()` |

---

## Flux d'utilisation

### Consultation des records

```
┌─ User navigue vers Records via icône 🏆 (FiguresScreen)
│
├─ RecordsScreen charge
│
├─ figuresByStateProvider(FigureState.learned) s'exécute
│  → Récupère figures avec state = "learned"
│
├─ Pour chaque figure:
│  ├─ Si recordValue != null ET recordUnit != null:
│  │  └─ _RecordCard affiche la figure + record
│  └─ Sinon: figure exclue (SizedBox.shrink)
│
├─ figuresProvider détecte changements Firestore en temps réel
│
└─ Liste affichée avec records actualisés
```

---

## Interactions avec autres onglets

### Records ↔ Figures

Les records sont gérés et édités depuis l'onglet Figures (FigureFormDialog, FigureDetailDialog, TodayTrainingDialog). L'onglet Records affiche simplement les figures maîtrisées avec leurs records (read-only).

### Records ↔ Today

L'onglet Today permet d'enregistrer ou modifier un record lors de la validation d'un entraînement. L'onglet Records affiche le résultat.

### Source de données

Tous les records proviennent de la même collection Firestore (`/users/{uid}/figures`) et sont synchronisés en temps réel.

---

## Notes de conception

### Filtrage automatique

Seules les figures avec `state = learned` ET possédant un record (`recordValue != null` ET `recordUnit != null`) sont affichées. Les figures maîtrisées sans record enregistré n'apparaissent pas dans la liste.

---

## Gestion des erreurs

### Erreur de synchronisation

```dart
learnedFiguresAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Center(child: Text('Erreur : $e')),
  data: (figures) => ...
)
```

### Cas limite : Passer à learned sans record

```
Figure maîtrisée SANS record saisi
        ↓
RecordsScreen ne l'affiche pas
        ↓
Utilisateur peut ajouter record plus tard
        ↓
Figure réapparaît automatiquement
```

---

## Synthèse

L'onglet **Records** est une **page d'affichage simple et lisible** offrant :

✅ Liste des figures maîtrisées avec records enregistrés  
✅ Affichage du nom et du record (valeur + unité)  
✅ Filtrage automatique des figures sans record  
✅ Synchronisation temps réel des données  
✅ Interface read-only (consultation uniquement)  
✅ Codage couleur via borders (couleur figure)

---

*Dernière mise à jour : Juin 2026*
