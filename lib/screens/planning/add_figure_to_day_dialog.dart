import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/figure_model.dart';
import '../../models/training_planned_model.dart';
import '../../providers/planning_providers.dart';
import '../../providers/core_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/figure_card.dart';

class AddFigureToDayDialog extends ConsumerWidget {
  final DateTime date;

  const AddFigureToDayDialog({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(availableFiguresForDayProvider(date));
    final showLearned = ref.watch(showLearnedProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Ajouter une figure\n${date.toShortLabel(Localizations.localeOf(context))}',
        style: theme.textTheme.titleMedium,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Case à cocher
            CheckboxListTile(
              value: showLearned,
              onChanged: (_) => ref.read(showLearnedProvider.notifier).toggle(),
              title: const Text('Afficher les figures apprises'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(),
            Flexible(
              child: availableAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erreur : $e'),
                data: (figures) {
                  if (figures.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Aucune figure disponible',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: figures.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final figure = figures[index];
                      return FigureCard(
                        figure: figure,
                        onTap: () => _addFigure(context, ref, figure),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Future<void> _addFigure(
    BuildContext context,
    WidgetRef ref,
    FigureModel figure,
  ) async {
    final repository = ref.read(trainingPlannedRepositoryProvider);
    if (repository == null) return;

    await repository.add(TrainingPlannedModel(figureId: figure.id, date: date));

    if (context.mounted) Navigator.of(context).pop();
  }
}
