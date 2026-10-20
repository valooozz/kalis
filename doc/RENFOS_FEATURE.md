# 📚 Documentation - Renfos

## Vue d'ensemble

Les **Renfos** sont des blocs d'entraînement personnalisés créés par l'utilisateur pour regrouper plusieurs figures autour d'un objectif ou d'un thème. Contrairement à la planification classique, un renfo n'est pas seulement une figure unique à travailler un jour donné : il représente une routine ou une séquence de travail associée à plusieurs figures, avec suivi de son exécution au fil du temps.

### Objectifs principaux

- 🧩 **Créer** des routines d'entraînement personnalisées
- 🎯 **Associer** plusieurs figures à un même renfo
- 📅 **Suivre** si la routine a été effectuée aujourd'hui
- ⚠️ **Alerter** si le renfo n'a pas été pratiqué depuis plusieurs jours
- 🔄 **Valider** le renfo directement depuis l'onglet Today

---

## Table des matières

1. [Architecture générale](#architecture-générale)
2. [Modèles de données](#modèles-de-données)
3. [Écrans et dialogues](#écrans-et-dialogues)
4. [Règles métier](#règles-métier)
5. [Providers et gestion d'état](#providers-et-gestion-détat)
6. [Persistance Firestore](#persistance-firestore)

---

## Architecture générale

### Vue hiérarchique des composants

```
RenfosScreen (écran principal)
├── SliverAppBar (titre + actions)
├── Liste des renfos (RenfoCard × N)
│   └── Tap → RenfoDetailDialog
├── FAB (+) → RenfoFormDialog
└── Empty state si aucun renfo

RenfoDetailDialog
├── Édition du nom du renfo
├── Sélection des figures associées
├── Suppression du renfo + historique associé
└── Bouton Fermer

TodayScreen
├── AppBar action (icône fitness_center)
└── TodayRenfoDialog
    └── RenfoTodayCard × N
        ├── Tap → marquer comme validé aujourd'hui
        └── Couleur rouge/vert/grise selon l'état
```

### Couches architecturales

```
┌────────────────────────────────────────────┐
│   UI (Screens / Dialogs / Widgets)         │
│   - RenfosScreen                           │
│   - RenfoDetailDialog                      │
│   - TodayRenfoDialog                       │
│   - RenfoCard / RenfoTodayCard             │
└──────────────┬─────────────────────────────┘
               │
┌──────────────▼─────────────────────────────┐
│   Providers (Riverpod)                     │
│   - renfosProvider                         │
│   - renfoDoneAllProvider                   │
│   - todayRenfoItemsProvider                │
│   - renfoButtonStateProvider               │
└──────────────┬─────────────────────────────┘
               │
┌──────────────▼─────────────────────────────┐
│   Repositories                             │
│   - RenfoRepository                         │
│   - RenfoDoneRepository                     │
└──────────────┬─────────────────────────────┘
               │
┌──────────────▼─────────────────────────────┐
│   Firestore                                │
│   /users/{uid}/renfos                      │
│   /users/{uid}/renfoDone                   │
└────────────────────────────────────────────┘
```

---

## Modèles de données

### RenfoModel

```dart
class RenfoModel {
  final String id;
  final String name;
  final List<String> figureIds;
}
```

**Rôle** : représenter une routine d'entraînement personnelle. Le nom permet de la désigner (ex. : "Force du bas", "Répétition de tractions", "Cardio léger"), et `figureIds` associe la routine à des figures précises.

### RenfoDoneModel

```dart
class RenfoDoneModel {
  final String renfoId;
  final DateTime date;
}
```

**Rôle** : enregistre le fait qu'un renfo a été validé pour une date précise. Le repository le stocke en tant que document unique par couple (`renfoId`, `date`) afin de ne pas enregistrer de doublons.

---

## Écrans et dialogues

### 1. RenfosScreen

**Fichier** : `lib/screens/renfos/renfos_screen.dart`

**Responsabilités** :
- Afficher la liste des renfos créés par l'utilisateur
- Ouvrir le formulaire de création
- Ouvrir le détail d'un renfo pour modifier ou supprimer
- Gérer l'état vide avec un message explicite

**Accès** : depuis l'onglet Figures via l'icône `fitness_center` de la barre d'outils, qui redirige vers `/renfos`.

### 2. RenfoFormDialog

**Fichier** : `lib/screens/renfos/renfo_form_dialog.dart`

**Fonction** : créer ou modifier un renfo, en vérifiant que le nom n'existe pas déjà pour cet utilisateur.

**Validation** :
- Le nom ne peut pas être vide
- Deux renfos ne peuvent pas porter le même nom (insensible à la casse)
- La soumission met à jour Firestore puis ferme le dialogue

### 3. RenfoDetailDialog

**Fichier** : `lib/screens/renfos/renfo_detail_dialog.dart`

**Fonction** :
- Consulter le nom du renfo
- Éditer le renfo
- Ajouter ou retirer des figures associées à la routine
- Supprimer le renfo et son historique de validation

**Comportement** : les figures sont affichées sous forme de `FigureSelectionChip`, avec un état visuel de sélection.

### 4. TodayRenfoDialog

**Fichier** : `lib/screens/today/today_renfo_dialog.dart`

**Contexte** : la séance du jour affiche une icône dédiée au niveau de l'AppBar. En appuyant dessus, l'utilisateur ouvre la liste des renfos qui peuvent être validés aujourd'hui.

**Rôle** :
- Afficher les renfos non planifiés et encore à travailler
- Marquer un renfo comme validé pour aujourd'hui
- Retirer la validation si besoin

### 5. RenfoCalendarDialog

**Fichier** : `lib/screens/renfos/renfo_calendar_dialog.dart`

**Contexte** : le calendrier d'un renfo peut être ouvert depuis le dialogue de validation du jour ou depuis le détail du renfo.

**Rôle** :
- Afficher les dates exactes de validation d'un renfo sur un calendrier mensuel
- Rendre visible l'historique de travail du renfo sans quitter le flux actuel
- Reprendre le composant générique `TrainingCalendarDialog` pour garder un rendu cohérent avec les autres calendriers de Kalis

**Données affichées** : le composant réutilise `renfoDoneDatesProvider` pour afficher uniquement les validations passées du renfo, sans ajouter les dates planifiées. Cette vue met donc l'accent sur l'historique réel d'exécution de la routine.

---

## Règles métier

### Sélection des renfos du jour

Dans `todayRenfoItemsProvider`, les renfos sont filtrés selon les règles suivantes :

- on exclut les renfos dont au moins une figure associée est déjà planifiée aujourd'hui
- on calcule la date du dernier enregistrement validé (`renfoLastDoneDatesProvider`) en ignorant explicitement la date du jour pour éviter qu'une validation récente masque un retard réel
- on considère qu'un renfo est "fait aujourd'hui" à partir des validations réelles de la journée (`doneTodayIds`), sans utiliser cette date comme référence de dernier succès pour l'alerte
- un renfo est considéré en alerte quand il n'a pas été validé depuis au moins `renfoAlertDays` jours (seuil fixé à 4 jours)

### Couleur de l'icône Today

`renfoButtonStateProvider` renvoie un état visuel :

- `hidden` : aucun renfo à traiter aujourd'hui
- `red` : au moins un renfo est en retard / en alerte
- `green` : au moins un renfo est validé aujourd'hui
- `grey` : renfos existants mais non urgents

L'icône de la barre d'outils de `TodayScreen` est colorée selon cet état.

---

## Providers et gestion d'état

### Providers principaux

| Provider | Rôle |
|---|---|
| `renfosProvider` | Stream de tous les renfos triés par nom |
| `renfoDoneAllProvider` | Stream de toutes les validations de renfo |
| `renfoLastDoneDatesProvider` | Dernière date d'exécution de chaque renfo |
| `todayRenfoItemsProvider` | Renfos éligibles pour aujourd'hui, avec état d’alerte et validation |
| `renfoButtonStateProvider` | État visuel de l'icône du bouton Today |

### Dépendances

Les providers renfo s'appuient sur :
- `renfoRepositoryProvider`
- `renfoDoneRepositoryProvider`
- `todayPlannedProvider`
- `todayProvider`

---

## Persistance Firestore

### Collections utilisées

```text
/users/{uid}/renfos
/users/{uid}/renfoDone
```

### Exemple de document `renfos`

```json
{
  "id": "abc123",
  "name": "Force du bas",
  "figureIds": ["f1", "f2", "f3"]
}
```

### Exemple de document `renfoDone`

```json
{
  "renfoId": "abc123",
  "date": "2026-10-13T00:00:00.000Z"
}
```

Les validations sont identifiées par le couple `renfoId + date` pour éviter les doublons sur une même journée.

---

## Synthèse

Le système de renfos apporte un niveau supplémentaire de personnalisation dans Kalis : il permet de définir des routines d'entraînement cohérentes et de les suivre de manière rapide et visuelle, sans dépendre uniquement de la planification hebdomadaire des figures.
