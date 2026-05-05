import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/core/utils/date_utils.dart';
import 'package:kalis/providers/today_providers.dart';
import 'package:kalis/repositories/figure_repository.dart';
import '../models/figure_model.dart';
import 'core_providers.dart';

// Stream de toutes les figures, triées par statut puis alphabétiquement
final figuresProvider = StreamProvider<List<FigureModel>>((ref) {
  final repository = ref.watch(figureRepositoryProvider);
  if (repository == null) return const Stream.empty();

  return repository.watchAll().map((figures) {
    figures.sort((a, b) {
      return a.order.compareTo(b.order);
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

// Date du prochain entraînement après un jour donné
final nextTrainingDateAfterDayProvider =
    StreamProvider.family<DateTime?, ({String figureId, DateTime date})>((
      ref,
      params,
    ) {
      final repository = ref.watch(trainingPlannedRepositoryProvider);
      if (repository == null) return const Stream.empty();

      final targetDay = params.date.dateOnly;

      return repository.watchByFigure(params.figureId).map((trainings) {
        final upcoming = trainings
            .where((t) => t.date.isAfter(targetDay))
            .toList();
        if (upcoming.isEmpty) return null;
        upcoming.sort((a, b) => a.date.compareTo(b.date));
        return upcoming.first.date;
      });
    });

// Ordre des figures
final figureOrderProvider = Provider<FigureOrderNotifier>((ref) {
  final repository = ref.watch(figureRepositoryProvider);
  return FigureOrderNotifier(repository);
});

class FigureOrderNotifier {
  final FigureRepository? _repository;

  FigureOrderNotifier(this._repository);

  Future<void> reorder(List<FigureModel> figures) async {
    await _repository?.updateOrder(figures);
  }
}

// Toutes les dates d'entraînement effectué pour une figure
final trainingDoneDatesProvider = StreamProvider.family<Set<DateTime>, String>((
  ref,
  figureId,
) {
  final repository = ref.watch(trainingDoneRepositoryProvider);
  if (repository == null) return const Stream.empty();

  return repository.watchByFigure(figureId).map((trainings) {
    return trainings.map((t) => t.date.dateOnly).toSet();
  });
});

// Toutes les dates d'entraînement planifié pour une figure
final trainingPlannedDatesProvider =
    StreamProvider.family<Set<DateTime>, String>((ref, figureId) {
      final repository = ref.watch(trainingPlannedRepositoryProvider);
      if (repository == null) return const Stream.empty();

      return repository.watchByFigure(figureId).map((trainings) {
        return trainings.map((t) => t.date.dateOnly).toSet();
      });
    });

// Provider qui récupère toutes les dates d'entraînement effectué
// pour toutes les figures, avec leur couleur associée
final allTrainingDoneDatesProvider = StreamProvider<Map<DateTime, List<Color>>>(
  (ref) {
    final figuresAsync = ref.watch(figuresProvider);
    final repository = ref.watch(trainingDoneRepositoryProvider);
    if (repository == null) return const Stream.empty();

    return figuresAsync.when(
      data: (figures) {
        if (figures.isEmpty) return Stream.value({});
        return Stream.periodic(const Duration(milliseconds: 100)).asyncMap((
          _,
        ) async {
          final result = <DateTime, List<Color>>{};
          for (final figure in figures) {
            final trainings = await repository.watchByFigure(figure.id).first;
            for (final t in trainings) {
              result.putIfAbsent(t.date.dateOnly, () => []);
              result[t.date.dateOnly]!.add(figure.color.color);
            }
          }
          return result;
        });
      },
      loading: () => const Stream.empty(),
      error: (_, __) => const Stream.empty(),
    );
  },
);

// Provider qui récupère toutes les dates d'entraînement planifié
// pour toutes les figures, avec leur couleur associée
final allTrainingPlannedDatesProvider =
    StreamProvider<Map<DateTime, List<Color>>>((ref) {
      final figuresAsync = ref.watch(figuresProvider);
      final repository = ref.watch(trainingPlannedRepositoryProvider);
      if (repository == null) return const Stream.empty();

      return figuresAsync.when(
        data: (figures) {
          if (figures.isEmpty) return Stream.value({});
          return Stream.periodic(const Duration(milliseconds: 100)).asyncMap((
            _,
          ) async {
            final result = <DateTime, List<Color>>{};
            for (final figure in figures) {
              final trainings = await repository.watchByFigure(figure.id).first;
              for (final t in trainings) {
                result.putIfAbsent(t.date.dateOnly, () => []);
                result[t.date.dateOnly]!.add(figure.color.color);
              }
            }
            return result;
          });
        },
        loading: () => const Stream.empty(),
        error: (_, __) => const Stream.empty(),
      );
    });
