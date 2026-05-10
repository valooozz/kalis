import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/screens/today/last_journal_entry_dialog.dart';
import '../../models/figure_model.dart';
import '../../providers/today_providers.dart';
import '../../providers/core_providers.dart';
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
              final allDone =
                  figures.isNotEmpty &&
                  figures.every((f) => doneIds.contains(f.id));
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
                              Icons.battery_3_bar,
                              size: 88,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 24),
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
                  else if (allDone)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.done_outline,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lbl.allFiguresDone,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                          onTap: () =>
                              _openTrainingDialog(context, ref, figure, isDone),
                          onLongPress: () =>
                              _handleLongPress(context, ref, figure, isDone),
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

  Future<void> _handleLongPress(
    BuildContext context,
    WidgetRef ref,
    FigureModel figure,
    bool isDone,
  ) async {
    if (isDone) {
      final repository = ref.read(trainingDoneRepositoryProvider);
      if (repository == null) return;

      final today = ref.read(todayProvider);

      await repository.remove(figure.id, today);
    } else {
      showDialog(
        context: context,
        builder: (_) => LastJournalEntryDialog(figure: figure),
      );
    }
  }
}
