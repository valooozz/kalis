# 📚 Documentation Technique - Kalis

## Vue d'ensemble

**Kalis** est une application mobile Flutter de suivi et d'organisation de séances de callisthénie (entraînement au poids du corps). Elle permet de gérer un portefeuille de figures à maîtriser, de planifier les entraînements sur 14 jours et de suivre la progression grâce à un journal personnel.

L'application synchronise les données en temps réel via Firebase Firestore et offre une expérience utilisateur multiplateforme sur iOS, Android, Web et Desktop.

---

## 📋 Table des matières

1. [Architecture générale](#architecture-générale)
2. [Structure des répertoires](#structure-des-répertoires)
3. [Modèles de données](#modèles-de-données)
4. [Flux de données](#flux-de-données)
5. [Stack technique](#stack-technique)
6. [Composants principaux](#composants-principaux)
7. [Navigation](#navigation)

---

## Architecture générale

Kalis suit une architecture **MVVM (Model-View-ViewModel)** avec une séparation claire des responsabilités et l'utilisation du **Repository Pattern**.

### Principes architecturaux

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer (Screens)                    │
│                    Consumer Widgets (Riverpod)               │
└────────────────────────┬────────────────────────────────────┘
                         │ (Consomme)
┌────────────────────────▼────────────────────────────────────┐
│                   State Management Layer                      │
│              Providers (Riverpod - StreamProvider)            │
│         Coordonnent les appels Repository et cachent          │
│              la logique métier à la couche UI                 │
└────────────────────────┬────────────────────────────────────┘
                         │ (Utilise)
┌────────────────────────▼────────────────────────────────────┐
│                   Data Access Layer                          │
│                   Repositories (CRUD)                         │
│              Abstraient l'accès à Firestore                   │
└────────────────────────┬────────────────────────────────────┘
                         │ (Appelle)
┌────────────────────────▼────────────────────────────────────┐
│                   Backend Services                           │
│         Firestore + Firebase Authentication                  │
│              Base de données cloud temps réel                │
└─────────────────────────────────────────────────────────────┘
```

### Couches architecturales

| Couche | Responsabilité | Technologie |
|--------|-----------------|------------|
| **UI Layer** | Affichage et interaction utilisateur | Flutter Widgets, Material Design |
| **State Management** | Gestion d'état, cache, coordination | Riverpod (Provider pattern) |
| **Data Access** | CRUD et abstraction de la base de données | Custom Repositories |
| **Backend** | Persistance et synchronisation | Firebase Firestore + Auth |

---

## Structure des répertoires

```
lib/
├── main.dart                          # Point d'entrée, init Firebase + auth anonyme
├── firebase_options.dart              # Configuration Firebase générée
│
├── core/                              # Infrastructure globale
│   ├── router/
│   │   └── app_router.dart           # Routes Go Router + redirection d'auth
│   ├── theme/
│   │   └── app_theme.dart            # Thème global (light/dark)
│   └── utils/
│       └── date_utils.dart           # Utilitaires de date
│
├── models/                            # Entités métier
│   ├── figure_model.dart             # Figure d'entraînement
│   ├── journal_entry_model.dart      # Note de journal liée à une figure
│   ├── place_model.dart              # Lieu d'entraînement
│   ├── training_done_model.dart      # Entraînement effectué
│   └── training_planned_model.dart   # Entraînement planifié
│
├── repositories/                      # Accès aux collections Firestore
│   ├── figure_repository.dart        # CRUD sur les figures
│   ├── general_note_repository.dart  # Note générale utilisateur
│   ├── journal_entry_repository.dart # Notes de journal
│   ├── place_repository.dart         # Gestion des lieux
│   ├── training_done_repository.dart # Entraînements validés
│   └── training_planned_repository.dart # Planification 14 jours
│
├── providers/                         # Gestion d'état Riverpod
│   ├── core_providers.dart           # Firebase/Auth + repos partagés
│   ├── figure_providers.dart         # Figures, dates, records, filtres
│   ├── filter_providers.dart         # Filtre couleur actif
│   ├── general_note_providers.dart   # Note générale utilisateur
│   ├── journal_providers.dart        # Journal d'une figure
│   ├── place_providers.dart          # Lieux utilisateur
│   ├── planning_providers.dart       # Planification + logique métier
│   └── today_providers.dart          # Vue du jour
│
├── screens/                           # Écrans et dialogues
│   ├── figures/                      # Gestion des figures + note générale
│   ├── main/
│   │   └── main_screen.dart          # Shell avec 3 onglets
│   ├── places/                       # Gestion des lieux
│   ├── planning/                     # Planification 14 jours
│   ├── records/                      # Historique / records
│   ├── settings/                     # Auth Google + paramètres compte
│   └── today/                        # Séance du jour
│
├── widgets/                           # Composants UI réutilisables
│   ├── color_filter_dialog.dart      # Filtre couleur
│   ├── color_picker_row.dart         # Sélecteur de couleur
│   ├── figure_card.dart              # Carte figure
│   ├── figure_square_card.dart       # Variante carte carrée
│   ├── journal_entry_tile.dart       # Entrée de journal
│   ├── place_card.dart               # Carte lieu
│   ├── record_display.dart           # Affichage d'un record
│   └── ...
│
└── l10n/                              # Localisation et fichiers arb
    ├── app_localizations.dart        # Classe générée
    ├── app_localizations_fr.dart     # Implémentation FR
    └── app_fr.arb                    # Ressources de traduction
```

---

## Modèles de données

### FigureModel (Modèle principal)

Représente une figure ou un mouvement d'entraînement à maîtriser.

```dart
class FigureModel {
  final String id;                    // Identifiant unique Firestore
  final String name;                  // Nom (ex: "Handstand")
  final FigureColor color;            // Couleur pour catégorisation
  final FigureState state;            // État: toLearn, learning, learned
  final DateTime? startDate;          // Date début apprentissage
  final DateTime? endDate;            // Date fin apprentissage/maîtrise
  final int? recordValue;             // Meilleur score numérique
  final RecordUnit? recordUnit;       // Unité: reps ou seconds
  final int order;                    // Position dans la liste
  final bool paused;                  // Figure en pause?
}

// Énumérés associés
enum FigureState { toLearn, learning, learned }
enum FigureColor { red, orange, yellow, green, blue, purple }
enum RecordUnit { reps, seconds }
```

### JournalEntryModel

Notes textuelles de progression associées à une figure.

```dart
class JournalEntryModel {
  final String id;                    // Identifiant unique
  final String figureId;              // Référence à la figure
  final DateTime date;                // Date de l'entrée
  final String text;                  // Contenu de la note
}
```

### TrainingDoneModel

Enregistrement qu'un entraînement a été effectué.

```dart
class TrainingDoneModel {
  final String figureId;              // Référence à la figure
  final DateTime date;                // Date (jour uniquement)
}
```

### TrainingPlannedModel

Entraînement planifié pour une date donnée.

```dart
class TrainingPlannedModel {
  final String figureId;              // Référence à la figure
  final DateTime date;                // Date planifiée (jour uniquement)
}
```

### PlaceModel

Represente un lieu d'entraînement (salle, parc, tapis, etc.) et les figures associées à ce lieu.

```dart
class PlaceModel {
  final String id;
  final String name;
  final List<String> figureIds;
}
```

### GeneralNoteModel / note générale utilisateur

La note générale n'est pas un modèle de figure mais un document unique par utilisateur, utilisé pour stocker un texte libre de contexte, objectifs ou remarques globales.

```dart
// collection: users/{uid}/generalNote/main
{
  "text": "Objectif de la semaine: améliorer l'alignement..."
}
```

---

## Flux de données

### Cycle général de flux

```
┌──────────────────┐
│    Firestore     │  Base de données cloud
│   (Persistent)   │
└─────────┬────────┘
          │
          │ watch() / get()
          │
┌─────────▼──────────────────┐
│   Repository               │  Accès aux données
│  - Figure Repository       │  - CRUD complet
│  - Training Done Repo.     │  - Abstraction Firestore
│  - Training Planned Repo.  │
│  - Journal Entry Repo.     │
└─────────┬──────────────────┘
          │
          │ return Stream/Future
          │
┌─────────▼────────────────────────────┐
│   Providers (Riverpod)               │  Gestion d'état
│  - Core (Firebase, Auth, Repos)      │  - Caching
│  - Figure Providers (filtres, stats) │  - Réactivité
│  - Today Providers (vue du jour)     │  - Coordonation
│  - Planning Providers (14 jours)     │
│  - Journal Providers (notes)         │
│  - Filter Providers (couleurs)       │
└─────────┬────────────────────────────┘
          │
          │ listen() / watch()
          │
┌─────────▼────────────────────────────┐
│   Screens & Widgets                  │  Présentation
│  - Écrans principaux                 │  - Consumer Widgets
│  - Dialogues                         │  - Material Design
│  - Widgets réutilisables             │  - Interaction
└──────────────────────────────────────┘
```

### Exemple de flux complet : Ajouter une figure

1. **UI** : Utilisateur clique sur "Ajouter figure" → `FigureFormDialog`
2. **Widget** : Collecte nom, couleur via `ColorPickerRow` et champs de texte
3. **Appel Repository** : `figureRepository.add(name, color)`
4. **Firestore** : Sauvegarde le document dans la collection `figures`
5. **Repository** : Retourne le nouvel ID
6. **Provider** : `figuresProvider` détecte la mise à jour via watch
7. **UI** : Écran `FiguresScreen` se reconstruit avec la nouvelle figure

---

## Stack technique

### Frontend

| Technologie | Version | Usage |
|-------------|---------|-------|
| **Flutter** | 3.x+ | Framework mobile multiplateforme |
| **Dart** | 3.x+ | Langage de programmation |
| **Material Design** | 3.0 | Design system UI |
| **Go Router** | Latest | Navigation déclarative |
| **Riverpod** | 2.x+ | Gestion d'état (StateManagement) |

### Backend & Services

| Service | Usage |
|---------|-------|
| **Firebase Firestore** | Base de données NoSQL temps réel cloud |
| **Firebase Auth** | Authentification anonyme + liaison à un compte Google |
| **Firebase Core** | Configuration et initialisation |

### Outils & Librairies

| Outil | Usage |
|-------|-------|
| **SharedPreferences** | Persistance locale des préférences |
| **Flutter Localization** | Support multilingue (.arb files) |
| **Google Sign-In** | Authentification avec compte Google (optionnel) |

### Architecture & Patterns

| Pattern | Usage |
|---------|-------|
| **MVVM** | Séparation Model-View-ViewModel |
| **Repository Pattern** | Abstraction de la couche données |
| **Provider Pattern** | Injection de dépendances & state management |
| **Stream Pattern** | Réactivité aux changements Firestore |

---

## Composants principaux

### Providers clés (Riverpod)

| Provider | Scope | Description |
|----------|-------|-------------|
| `figuresProvider` | Global | Stream de toutes les figures (avec filtrage couleur) |
| `figuresByStateProvider` | Family | Figures filtrées par état (toLearn/learning/learned) |
| `todayPlannedProvider` | Global | Entraînements planifiés pour aujourd'hui |
| `todayDoneProvider` | Global | Entraînements complétés aujourd'hui |
| `planningProvider` | Global | Entraînements planifiés sur 14 jours |
| `journalEntriesForFigureProvider` | Family | Notes journal pour une figure |
| `placesProvider` | Global | Lieux utilisateur triés par nom |
| `generalNoteProvider` | Global | Texte libre de note générale utilisateur |
| `isLinkedToGoogleProvider` | Global | Indique si le compte Firebase est lié à Google |
| `colorFilterProvider` | Global | Filtre couleur actif |

### Repositories (CRUD)

**FigureRepository**
- `Stream<List<FigureModel>> watchAllFigures()` - Monitorer toutes figures
- `Future<FigureModel> addFigure(...)` - Créer une figure
- `Future<void> updateFigure(FigureModel)` - Mettre à jour
- `Future<void> deleteFigure(String id)` - Supprimer
- `Future<FigureModel?> getFigureById(String id)` - Récupérer par ID

**TrainingDoneRepository**
- `Future<void> addTrainingDone(String figureId, DateTime date)` - Marquer comme effectué
- `Stream<List<TrainingDoneModel>> watchAllTrainingsDone()` - Monitorer les entraînements effectués
- `Stream<List<TrainingDoneModel>> watchTrainingsDoneForDate(DateTime)` - Entraînements du jour

**TrainingPlannedRepository**
- `Future<void> planTraining(String figureId, DateTime date)` - Planifier un entraînement
- `Stream<List<TrainingPlannedModel>> watchTrainingsPlanedForDateRange(...)` - Monitorer 14 jours

**JournalEntryRepository**
- `Future<void> addJournalEntry(String figureId, String text, DateTime)` - Ajouter note
- `Stream<List<JournalEntryModel>> watchJournalEntriesForFigure(String figureId)` - Notes d'une figure
- `Future<JournalEntryModel?> getLatestJournalEntryForFigure(String figureId)` - Dernière note

---

## Navigation

### Structure de navigation (Go Router)

L'application utilise **Go Router** pour une navigation déclarative et structurée.

Le shell principal est construit dans `MainScreen`, qui expose seulement 3 onglets dans la barre de navigation :

```
MainScreen (Navigation principale avec BottomNavigationBar)
├── /figures            → FiguresScreen (gestion des figures)
├── /today              → TodayScreen (séance du jour)
└── /planning           → PlanningScreen (planification sur 14 jours)

Routes plein écran (hors onglets)
├── /places             → PlacesScreen (gestion des lieux)
├── /records            → RecordsScreen (historique + records)
├── /settings           → SettingsScreen (compte Google / paramètres)
└── Dialogues modaux   → FigureFormDialog, FigureDetailDialog, PlaceFormDialog, etc.
```

### Écrans principaux

| Écran | Chemin | Usage |
|-------|--------|-------|
| **Figures** | `/figures` | Gérer le portefeuille de figures |
| **Today** | `/today` | Afficher les figures à entraîner aujourd'hui |
| **Planning** | `/planning` | Planifier les entraînements sur 14 jours |
| **Places** | `/places` | Gérer les lieux d'entraînement et leurs figures associées |
| **Records** | `/records` | Consulter l'historique des entraînements |
| **Settings** | `/settings` | Configurer l'authentification et lier son compte Google |

---

## Cycle de vie de l'application

```
┌─────────────────────────────────┐
│  main() - Point d'entrée        │
│  - Configuration Firebase       │
│  - SignInAnonymously() si besoin│
│  - ProviderScope (Riverpod)     │
│  - MaterialApp + GoRouter       │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│  KalisApp (MaterialApp)         │
│  - Router configuration         │
│  - Theme global                 │
│  - Localization (français)      │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│  MainScreen                     │
│  (BottomNavigationBar - 3 tabs) │
│  - /figures /today /planning     │
└──────────────┬──────────────────┘
               │
      ┌────────┴────────┬──────────┬──────────┐
      │                 │          │          │
  FiguresScreen     TodayScreen  PlanningScreen   
      │                 │          │          │
      └─────┬───────────┴──────────┴──────────┘
            │
      Routes plein écran : /places, /records, /settings
      Dialogues modulaires : figures, lieux, journal, records, notes générales
```

---

## Localisation

L'application est actuellement disponible **uniquement en français**.

La localisation est gérée via le système officiel Flutter avec des fichiers `.arb` (Application Resource Bundle) :

- `l10n/app_fr.arb` : Ressources français (clés → traductions)
- `l10n/app_localizations.dart` : Classe générée pour accès aux traductions
- `l10n/app_localizations_fr.dart` : Implémentation français

Pour ajouter une langue supplémentaire, voir [Flutter i18n documentation](https://flutter.dev/docs/development/accessibility-and-localization/internationalization).

---

## Synthèse

Kalis est une application **réactive**, **moderne** et **modulaire** qui :

✅ Synchronise les données en temps réel avec Firestore  
✅ Offre une gestion d'état fluide et prévisible via Riverpod  
✅ Suit les bonnes pratiques Flutter (Repository Pattern, MVVM)  
✅ Supporte plusieurs plateformes (iOS, Android, Web, Desktop)  
✅ Offre une UX fluide avec Material Design 3  
✅ Est facilement extensible grâce à son architecture modulaire  

Pour des détails sur des composants spécifiques, consultez la documentation détaillée des écrans et services.

---

*Dernière mise à jour : Juin 2026*
