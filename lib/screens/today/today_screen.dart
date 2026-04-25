import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
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
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;
    final figuresAsync = ref.watch(todayFiguresProvider);
    final doneIdsAsync = ref.watch(todayDoneIdsProvider);

    return Scaffold(
      body: figuresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (figures) {
          return doneIdsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (doneIds) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 120,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(lbl.todayScreenTitle),
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    ),
                  ),
                  if (figures.isEmpty)
                    SliverFillRemaining(
                      child: Center(
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
                              lbl.noFiguresToday,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lbl.noFiguresTodaySubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final figure = figures[index];
                          final isDone = doneIds.contains(figure.id);
                          return FigureSquareCard(
                            figure: figure,
                            isDone: isDone,
                            onTap: () => _openTrainingDialog(
                              context,
                              ref,
                              figure,
                              isDone,
                            ),
                            onLongPress: () => _toggleDone(ref, figure, isDone),
                          );
                        }, childCount: figures.length),
                      ),
                    ),
                ],
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
