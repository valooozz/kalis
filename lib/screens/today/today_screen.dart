import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/figure_model.dart';
import '../../providers/today_providers.dart';
import '../../providers/core_providers.dart';
import '../../models/training_done_model.dart';
import '../../widgets/figure_square_card.dart';
import 'today_training_dialog.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final figuresAsync = ref.watch(todayFiguresProvider);
    final doneIdsAsync = ref.watch(todayDoneIdsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Séance du jour")),
      body: figuresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (figures) {
          if (figures.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune figure prévue aujourd\'hui',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Profites-en pour te reposer !',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return doneIdsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (doneIds) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: figures.length,
                  itemBuilder: (context, index) {
                    final figure = figures[index];
                    final isDone = doneIds.contains(figure.id);

                    return FigureSquareCard(
                      figure: figure,
                      isDone: isDone,
                      onTap: () =>
                          _openTrainingDialog(context, ref, figure, isDone),
                      onLongPress: () => _toggleDone(ref, figure, isDone),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openTrainingDialog(
    BuildContext context,
    WidgetRef ref,
    FigureModel figure,
    bool isDone,
  ) async {
    await showDialog(
      context: context,
      builder: (_) => TodayTrainingDialog(figure: figure),
    );
  }

  Future<void> _toggleDone(
    WidgetRef ref,
    FigureModel figure,
    bool isDone,
  ) async {
    final repository = ref.read(trainingDoneRepositoryProvider);
    if (repository == null) return;

    final today = ref.read(todayProvider);

    if (isDone) {
      await repository.remove(figure.id, today);
    } else {
      await repository.add(TrainingDoneModel(figureId: figure.id, date: today));
    }
  }
}
