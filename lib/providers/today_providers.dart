import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/training_planned_model.dart';
import '../models/training_done_model.dart';
import '../models/figure_model.dart';
import 'core_providers.dart';
import 'figure_providers.dart';

// Date d'aujourd'hui (sans l'heure)
final todayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// Stream des entraînements planifiés aujourd'hui
final todayPlannedProvider = StreamProvider<List<TrainingPlannedModel>>((ref) {
  final repository = ref.watch(trainingPlannedRepositoryProvider);
  if (repository == null) return const Stream.empty();

  final today = ref.watch(todayProvider);
  return repository.watchByDate(today);
});

// Stream des entraînements effectués aujourd'hui
final todayDoneProvider = StreamProvider<List<TrainingDoneModel>>((ref) {
  final repository = ref.watch(trainingDoneRepositoryProvider);
  if (repository == null) return const Stream.empty();

  final today = ref.watch(todayProvider);
  return repository.watchByDate(today);
});

// Figures planifiées aujourd'hui, avec leurs données complètes
final todayFiguresProvider = Provider<AsyncValue<List<FigureModel>>>((ref) {
  final plannedAsync = ref.watch(todayPlannedProvider);
  final figuresAsync = ref.watch(figuresProvider);

  return plannedAsync.whenData((planned) {
    return figuresAsync.whenData((figures) {
      final plannedIds = planned.map((t) => t.figureId).toSet();
      return figures.where((f) => plannedIds.contains(f.id)).toList();
    }).valueOrNull ?? [];
  });
});

// Ids des figures déjà travaillées aujourd'hui
final todayDoneIdsProvider = Provider<AsyncValue<Set<String>>>((ref) {
  return ref.watch(todayDoneProvider).whenData(
        (done) => done.map((t) => t.figureId).toSet(),
      );
});

// Indique si une figure spécifique a été travaillée aujourd'hui
final isFigureDoneTodayProvider =
    Provider.family<AsyncValue<bool>, String>((ref, figureId) {
      return ref.watch(todayDoneIdsProvider).whenData(
            (doneIds) => doneIds.contains(figureId),
          );
    });