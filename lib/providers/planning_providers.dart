import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/core/utils/date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_planned_model.dart';
import '../models/figure_model.dart';
import 'core_providers.dart';
import 'figure_providers.dart';
import 'today_providers.dart';

// Clé pour la persistance de la case à cocher
const _showLearnedKey = 'showLearnedFigures';

// Notifier pour la case à cocher showLearnedFigures
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
final planningProvider = StreamProvider<List<TrainingPlannedModel>>((ref) {
  final repository = ref.watch(trainingPlannedRepositoryProvider);
  if (repository == null) return const Stream.empty();

  final today = ref.watch(todayProvider);
  final endDate = today.add(const Duration(days: 13));
  return repository.watchByDateRange(today, endDate);
});

// Entraînements planifiés pour un jour donné
final plannedForDayProvider =
    Provider.family<AsyncValue<List<TrainingPlannedModel>>, DateTime>((
      ref,
      date,
    ) {
      return ref.watch(planningProvider).whenData((planned) {
        return planned
            .where(
              (t) =>
                  t.date.year == date.year &&
                  t.date.month == date.month &&
                  t.date.day == date.day,
            )
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

// Provider qui calcule la date effective de dernier entraînement
// pour une figure à une date donnée, en tenant compte des
// TrainingPlanned entre aujourd'hui et cette date
final effectiveLastTrainingDateProvider =
    Provider.family<AsyncValue<DateTime?>, ({String figureId, DateTime date})>((
      ref,
      params,
    ) {
      final lastDateAsync = ref.watch(
        lastTrainingDateProvider(params.figureId),
      );
      final plannedAsync = ref.watch(
        trainingPlannedForFigureProvider(params.figureId),
      );
      final today = ref.watch(todayProvider);

      return lastDateAsync.whenData((lastDate) {
        final plannedValue = plannedAsync.valueOrNull ?? [];

        final targetDay = DateTime(
          params.date.year,
          params.date.month,
          params.date.day,
        );

        // On cherche la dernière séance prévue entre aujourd'hui
        // et le jour sélectionné (exclu)
        final plannedBefore = plannedValue
            .where(
              (t) =>
                  (t.date.isToday || t.date.isAfter(today)) &&
                  t.date.isBefore(targetDay),
            )
            .map((t) => t.date)
            .toList();

        if (plannedBefore.isEmpty) return lastDate;

        plannedBefore.sort((a, b) => b.compareTo(a));
        final lastPlanned = plannedBefore.first;

        // On retourne la date la plus récente entre lastDate et lastPlanned
        if (lastDate == null) return lastPlanned;
        return lastPlanned.isAfter(lastDate) ? lastPlanned : lastDate;
      });
    });

// Provider du stream de TrainingPlanned pour une figure
final trainingPlannedForFigureProvider =
    StreamProvider.family<List<TrainingPlannedModel>, String>((ref, figureId) {
      final repository = ref.watch(trainingPlannedRepositoryProvider);
      if (repository == null) return const Stream.empty();
      return repository.watchByFigure(figureId);
    });

final availableFiguresForDayProvider =
    Provider.family<AsyncValue<List<FigureModel>>, DateTime>((ref, date) {
      final figuresAsync = ref.watch(figuresProvider);
      final plannedAsync = ref.watch(plannedForDayProvider(date));
      final showLearned = ref.watch(showLearnedProvider);

      return figuresAsync.whenData((figures) {
        final plannedValue = plannedAsync.valueOrNull ?? [];
        final plannedForDayIds = plannedValue.map((t) => t.figureId).toSet();

        // Filtrage
        final available = figures.where((figure) {
          if (plannedForDayIds.contains(figure.id)) return false;
          if (figure.state == FigureState.toLearn) return false;
          if (!showLearned && figure.state == FigureState.learned) return false;
          if (figure.paused) return false;
          return true;
        }).toList();

        // Récupération des dates pour le tri
        final effectiveLastDates = <String, DateTime?>{};
        final nextTrainingDates = <String, DateTime?>{};

        for (final figure in available) {
          effectiveLastDates[figure.id] = ref
              .watch(
                effectiveLastTrainingDateProvider((
                  figureId: figure.id,
                  date: date,
                )),
              )
              .valueOrNull;
          nextTrainingDates[figure.id] = ref
              .watch(
                nextTrainingDateAfterDayProvider((
                  figureId: figure.id,
                  date: date,
                )),
              )
              .valueOrNull;
        }

        // Tri selon les règles métier
        available.sort((a, b) {
          final aNext = nextTrainingDates[a.id];
          final bNext = nextTrainingDates[b.id];
          final aLast = effectiveLastDates[a.id];
          final bLast = effectiveLastDates[b.id];

          // Règle 1 : sans date de prochain entraînement en premier
          if (aNext == null && bNext != null) return -1;
          if (aNext != null && bNext == null) return 1;

          // Règle 2 : dernier entraînement effectif le plus éloigné
          // du jour sélectionné en premier
          if (aLast == null && bLast != null) return -1;
          if (aLast != null && bLast == null) return 1;
          if (aLast != null && bLast != null) {
            final aDiff = date.difference(aLast).inDays;
            final bDiff = date.difference(bLast).inDays;
            final lastComparison = bDiff.compareTo(aDiff);
            if (lastComparison != 0) return lastComparison;
          }

          // Règle 3 : date de prochain entraînement la plus éloignée
          // du jour sélectionné en premier
          if (aNext != null && bNext != null) {
            final aDiff = aNext.difference(date).inDays.abs();
            final bDiff = bNext.difference(date).inDays.abs();
            final nextComparison = bDiff.compareTo(aDiff);
            if (nextComparison != 0) return nextComparison;
          }

          // Règle 4 : en apprentissage avant apprise
          if (a.state != b.state) {
            if (a.state == FigureState.learning) return -1;
            if (b.state == FigureState.learning) return 1;
          }

          // Règle 5 : ordre alphabétique
          return a.name.compareTo(b.name);
        });

        return available;
      });
    });
