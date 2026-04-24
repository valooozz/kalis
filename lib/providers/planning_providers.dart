import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_planned_model.dart';
import '../models/figure_model.dart';
import 'core_providers.dart';
import 'figure_providers.dart';
import 'today_providers.dart';

// Clé pour la persistance de la case à cocher
const _showLearnedKey = 'showLearnedFigures';

// Notifier pour la case à cocher "Afficher les figures apprises"
class ShowLearnedNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Chargement asynchrone de la préférence, false par défaut
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_showLearnedKey) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showLearnedKey, state);
  }
}

// Provider de la case à cocher
final showLearnedProvider = NotifierProvider<ShowLearnedNotifier, bool>(() {
  return ShowLearnedNotifier();
});

// Stream des entraînements planifiés sur 14 jours
final planningProvider =
    StreamProvider<List<TrainingPlannedModel>>((ref) {
  final repository = ref.watch(trainingPlannedRepositoryProvider);
  if (repository == null) return const Stream.empty();

  final today = ref.watch(todayProvider);
  final endDate = today.add(const Duration(days: 13));
  return repository.watchByDateRange(today, endDate);
});

// Entraînements planifiés pour un jour donné
final plannedForDayProvider =
    Provider.family<AsyncValue<List<TrainingPlannedModel>>, DateTime>(
        (ref, date) {
  return ref.watch(planningProvider).whenData((planned) {
    return planned
        .where((t) =>
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day)
        .toList();
  });
});

// Figures planifiées pour un jour donné, avec leurs données complètes
final figuresForDayProvider =
    Provider.family<AsyncValue<List<FigureModel>>, DateTime>((ref, date) {
  final plannedAsync = ref.watch(plannedForDayProvider(date));
  final figuresAsync = ref.watch(figuresProvider);

  return plannedAsync.whenData((planned) {
    final figuresValue = figuresAsync.whenData((figures) {
      final plannedIds = planned.map((t) => t.figureId).toSet();
      return figures.where((f) => plannedIds.contains(f.id)).toList();
    });
    return figuresValue.valueOrNull ?? [];
  });
});

// Figures disponibles à ajouter à un jour donné, triées selon les règles métier
final availableFiguresForDayProvider =
    Provider.family<AsyncValue<List<FigureModel>>, DateTime>((ref, date) {
  final figuresAsync = ref.watch(figuresProvider);
  final plannedAsync = ref.watch(plannedForDayProvider(date));
  final showLearned = ref.watch(showLearnedProvider);
  final lastTrainingDates = <String, DateTime?>{};
  final nextTrainingDates = <String, DateTime?>{};

  return figuresAsync.whenData((figures) {
    final plannedValue = plannedAsync.valueOrNull ?? [];
    final plannedForDayIds = plannedValue.map((t) => t.figureId).toSet();

    // Filtrage : exclure les figures déjà planifiées ce jour
    // et les figures "à apprendre"
    var available = figures.where((f) {
      if (plannedForDayIds.contains(f.id)) return false;
      if (f.state == FigureState.toLearn) return false;
      if (!showLearned && f.state == FigureState.learned) return false;
      return true;
    }).toList();

    // Récupération des dates pour le tri
    for (final figure in available) {
      lastTrainingDates[figure.id] =
          ref.watch(lastTrainingDateProvider(figure.id)).valueOrNull;
      nextTrainingDates[figure.id] =
          ref.watch(nextTrainingDateProvider(figure.id)).valueOrNull;
    }

    // Tri selon les règles métier
    available.sort((a, b) {
      final aNext = nextTrainingDates[a.id];
      final bNext = nextTrainingDates[b.id];
      final aLast = lastTrainingDates[a.id];
      final bLast = lastTrainingDates[b.id];

      // Règle 1 : sans date de prochain entraînement en premier
      if (aNext == null && bNext != null) return -1;
      if (aNext != null && bNext == null) return 1;

      // Règle 2 : en apprentissage avant apprise
      if (a.state != b.state) {
        if (a.state == FigureState.learning) return -1;
        if (b.state == FigureState.learning) return 1;
      }

      // Règle 3 : dernier entraînement le plus éloigné en premier
      if (aLast == null && bLast != null) return -1;
      if (aLast != null && bLast == null) return 1;
      if (aLast != null && bLast != null) {
        final lastComparison = aLast.compareTo(bLast);
        if (lastComparison != 0) return lastComparison;
      }

      // Règle 4 : ordre alphabétique
      return a.name.compareTo(b.name);
    });

    return available;
  });
});