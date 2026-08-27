import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/core/utils/date_utils.dart';
import 'package:kalis/models/training_done_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_planned_model.dart';
import '../models/figure_model.dart';
import 'core_providers.dart';
import 'figure_providers.dart';
import 'today_providers.dart';
import 'place_providers.dart';

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

// Provider des figures disponibles pour un jour donné
// Optionnellement filtré par `placeId` pour ne garder que les figures
// associées à ce lieu.
final availableFiguresForDayProvider =
    Provider.family<
      AsyncValue<List<FigureModel>>,
      ({DateTime date, String? placeId})
    >((ref, params) {
      final date = params.date;
      final placeId = params.placeId;
      final figuresAsync = ref.watch(figuresProvider);
      final plannedAsync = ref.watch(plannedForDayProvider(date));
      final showLearned = ref.watch(showLearnedProvider);
      final placesAsync = ref.watch(placesProvider);

      return figuresAsync.whenData((figures) {
        final plannedValue = plannedAsync.valueOrNull ?? [];
        final plannedForDayIds = plannedValue.map((t) => t.figureId).toSet();

        // Filtrage initial
        var available = figures.where((figure) {
          if (plannedForDayIds.contains(figure.id)) return false;
          if (figure.state == FigureState.toLearn) return false;
          if (figure.paused) return false;
          if (figure.state == FigureState.learned && !figure.active) {
            if (!showLearned) return false;
          }
          return true;
        }).toList();

        // Si un placeId est fourni, restreindre aux figures présentes dans le lieu
        if (placeId != null) {
          final place = placesAsync.maybeWhen(
            data: (places) => places.where((p) => p.id == placeId).firstOrNull,
            orElse: () => null,
          );
          if (place == null) {
            available = [];
          } else {
            final allowed = place.figureIds.toSet();
            available = available.where((f) => allowed.contains(f.id)).toList();
          }
        }

        // Récupération des dates pour le calcul du score
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

        // Calcul du score de chaque figure
        int computeScore(FigureModel figure) {
          var score = 0;

          if (figure.state == FigureState.learning) score += 5;
          if (figure.favorite) score += 20;

          final lastDate = effectiveLastDates[figure.id];
          if (lastDate == null) {
            score += 20;
          } else {
            var difference = date.difference(lastDate).inDays;
            if (difference > 1) {
              score += min(difference * 2, 19);
            }
          }

          final nextDate = nextTrainingDates[figure.id];
          if (nextDate != null && !figure.favorite) {
            var difference = nextDate.difference(date).inDays;
            score -= (20 / (difference * difference)).floor();
          }

          return score;
        }

        final scores = <String, int>{
          for (final figure in available) figure.id: computeScore(figure),
        };

        // Tri par score décroissant, ordre alphabétique en cas d'égalité
        available.sort((a, b) {
          final scoreComparison = scores[b.id]!.compareTo(scores[a.id]!);
          if (scoreComparison != 0) return scoreComparison;
          return a.name.compareTo(b.name);
        });

        return available;
      });
    });

// Stream des entraînements effectués pour une date donnée (générique)
final trainingDoneForDateProvider =
    StreamProvider.family<List<TrainingDoneModel>, DateTime>((ref, date) {
      final repository = ref.watch(trainingDoneRepositoryProvider);
      if (repository == null) return const Stream.empty();
      return repository.watchByDate(date);
    });

// Provider pour les figures planifiées à une date passée
final plannedForPastDateProvider =
    StreamProvider.family<List<TrainingPlannedModel>, DateTime>((ref, date) {
      final repository = ref.watch(trainingPlannedRepositoryProvider);
      if (repository == null) return const Stream.empty();
      return repository.watchByDate(date);
    });

// Figures planifiées pour une date passée avec leurs données complètes
final figuresForPastDateProvider =
    Provider.family<AsyncValue<List<FigureModel>>, DateTime>((ref, date) {
      final plannedAsync = ref.watch(plannedForPastDateProvider(date));
      final figuresAsync = ref.watch(figuresProvider);

      return plannedAsync.whenData((planned) {
        final figuresValue = figuresAsync.whenData((figures) {
          final plannedIds = planned.map((t) => t.figureId).toSet();
          return figures.where((f) => plannedIds.contains(f.id)).toList();
        });
        return figuresValue.valueOrNull ?? [];
      });
    });
