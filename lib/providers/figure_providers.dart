import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/core/utils/date_utils.dart';
import 'package:kalis/providers/today_providers.dart';
import '../models/figure_model.dart';
import 'core_providers.dart';

// Stream de toutes les figures, triées par statut puis alphabétiquement
final figuresProvider = StreamProvider<List<FigureModel>>((ref) {
  final repository = ref.watch(figureRepositoryProvider);
  if (repository == null) return const Stream.empty();

  return repository.watchAll().map((figures) {
    figures.sort((a, b) {
      // Tri par statut : learned > learning > toLearn
      final stateOrder = {
        FigureState.learned: 0,
        FigureState.learning: 1,
        FigureState.toLearn: 2,
      };
      final stateComparison = stateOrder[a.state]!.compareTo(
        stateOrder[b.state]!,
      );
      if (stateComparison != 0) return stateComparison;

      // Tri alphabétique au sein du même statut
      return a.name.compareTo(b.name);
    });
    return figures;
  });
});

// Figures filtrées par statut
final figuresByStateProvider =
    Provider.family<AsyncValue<List<FigureModel>>, FigureState>((ref, state) {
      return ref
          .watch(figuresProvider)
          .whenData(
            (figures) => figures.where((f) => f.state == state).toList(),
          );
    });

// Une figure par son id
final figureByIdProvider = Provider.family<AsyncValue<FigureModel?>, String>((
  ref,
  id,
) {
  return ref
      .watch(figuresProvider)
      .whenData((figures) => figures.where((f) => f.id == id).firstOrNull);
});

// Date du dernier entraînement d'une figure
final lastTrainingDateProvider = StreamProvider.family<DateTime?, String>((
  ref,
  figureId,
) {
  final repository = ref.watch(trainingDoneRepositoryProvider);
  if (repository == null) return const Stream.empty();

  return repository.watchByFigure(figureId).map((trainings) {
    if (trainings.isEmpty) return null;
    // Les trainings sont déjà triés par date décroissante
    return trainings.first.date;
  });
});

// Date du prochain entraînement d'une figure
final nextTrainingDateProvider = StreamProvider.family<DateTime?, String>((
  ref,
  figureId,
) {
  final repository = ref.watch(trainingPlannedRepositoryProvider);
  if (repository == null) return const Stream.empty();

  final today = ref.watch(todayProvider);

  return repository.watchByFigure(figureId).map((trainings) {
    final upcoming = trainings
        .where(
          (t) =>
              t.date.isAfter(today) ||
              (t.date.year == today.year &&
                  t.date.month == today.month &&
                  t.date.day == today.day),
        )
        .toList();

    if (upcoming.isEmpty) return null;
    // On prend la date la plus proche
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    return upcoming.first.date;
  });
});

// Date du prochain entraînement en ignorant aujourd'hui
final nextTrainingDateAfterTodayProvider =
    StreamProvider.family<DateTime?, String>((ref, figureId) {
      final repository = ref.watch(trainingPlannedRepositoryProvider);
      if (repository == null) return const Stream.empty();

      final today = ref.watch(todayProvider);
      final tomorrow = today.add(const Duration(days: 1));

      return repository.watchByFigure(figureId).map((trainings) {
        final upcoming = trainings
            .where((t) => t.date.isAfter(today) || t.date.isSameDay(tomorrow))
            .toList();
        if (upcoming.isEmpty) return null;
        upcoming.sort((a, b) => a.date.compareTo(b.date));
        return upcoming.first.date;
      });
    });
