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
├── main.dart                          # Point d'entrée, configuration de l'app
├── firebase_options.dart              # Configuration Firebase (généré)
│
├── core/                              # Infrastructure et configuration globale
│   ├── router/
│   │   └── app_router.dart           # Routes et navigation Go Router
│   ├── theme/
│   │   └── app_theme.dart            # Thème global (couleurs, typographie)
│   └── utils/
│       └── date_utils.dart           # Utilitaires pour dates
│
├── models/                            # Modèles de données (entités métier)
│   ├── figure_model.dart             # Figure d'entraînement (principale)
│   ├── journal_entry_model.dart      # Note journal pour une figure
│   ├── training_done_model.dart      # Entraînement effectué
│   └── training_planned_model.dart   # Entraînement planifié
│
├── repositories/                      # Accès aux données (Firestore)
│   ├── figure_repository.dart        # CRUD des figures
│   ├── training_done_repository.dart # Gestion des entraînements effectués
│   ├── training_planned_repository.dart # Gestion des planifications
│   └── journal_entry_repository.dart # Gestion des notes journal
│
├── providers/                         # Gestion d'état (Riverpod)
│   ├── core_providers.dart           # Providers fondamentaux (Firebase, repos)
│   ├── figure_providers.dart         # Providers des figures
│   ├── journal_providers.dart        # Providers du journal
│   ├── today_providers.dart          # Providers pour le jour courant
│   ├── planning_providers.dart       # Providers pour la planification
│   └── filter_providers.dart         # Provider de filtrage
│
├── screens/                           # Écrans et dialogues de l'application
│   ├── main/
│   │   └── main_screen.dart          # Navigation principale
│   ├── today/                        # Vue du jour
│   ├── planning/                     # Planification 14 jours
│   ├── figures/                      # Gestion des figures
│   ├── records/                      # Historique des entraînements
│   └── settings/                     # Paramètres
│
├── widgets/                           # Composants réutilisables
│   ├── figure_card.dart              # Carte figure (format large)
│   ├── figure_square_card.dart       # Carte figure (format carré)
│   ├── journal_entry_tile.dart       # Ligne de note journal
│   ├── color_picker_row.dart         # Sélecteur de couleur
│   ├── color_filter_dialog.dart      # Dialogue de filtrage couleur
│   ├── date_row.dart                 # Composant de date
│   └── record_display.dart           # Affichage d'un record
│
└── l10n/                              # Localisation (français)
    ├── app_localizations.dart        # Classe i18n
    ├── app_localizations_fr.dart     # Traductions
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
| **Firebase Auth** | Authentification (anonyme) |
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

```
MainScreen (Navigation principale avec BottomNavigationBar)
├── /today              → TodayScreen (Séance du jour)
├── /planning           → PlanningScreen (Planification 14j)
├── /figures            → FiguresScreen (Gestion figures)
├── /records            → RecordsScreen (Historique)
└── /settings           → SettingsScreen (Paramètres)

Dialogues (modaux)
├── /figures/form       → FigureFormDialog (Créer/éditer)
├── /figures/detail/:id → FigureDetailDialog (Détails)
├── /figures/calendar/:id → FigureCalendarDialog (Calendrier figure)
├── /planning/add       → AddFigureToDayDialog (Ajouter à jour)
└── ...
```

### Écrans principaux

| Écran | Chemin | Usage |
|-------|--------|-------|
| **Today** | `/today` | Afficher les figures à entraîner aujourd'hui |
| **Planning** | `/planning` | Planifier les entraînements sur 14 jours |
| **Figures** | `/figures` | Gérer le portefeuille de figures |
| **Records** | `/records` | Consulter l'historique des entraînements |
| **Settings** | `/settings` | Configurer l'authentification et les préférences |

---

## Cycle de vie de l'application

```
┌─────────────────────────────────┐
│  main() - Point d'entrée        │
│  - Configuration Firebase       │
│  - ProviderScope (Riverpod)     │
│  - MaterialApp + GoRouter       │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│  KalisApp (MaterialApp)         │
│  - Go Router configuration      │
│  - Thème global                 │
│  - Localization (français)      │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│  MainScreen                     │
│  (NavigationBar - 5 sections)   │
│  - Gère la navigation centrale  │
└──────────────┬──────────────────┘
               │
        ┌──────┴──────┬──────────┬────────┐
        │             │          │        │
   TodayScreen  PlanningScreen Figures   Records
        │       Screen      Screen     Screen
        │             │          │        │
        └─────────────┴──────────┴────────┘
        Dialogues modaux au besoin
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
