import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/core/utils/date_utils.dart';
import 'package:kalis/l10n/app_localizations.dart';
import '../../models/figure_model.dart';
import '../../models/training_planned_model.dart';
import '../../providers/figure_providers.dart';
import '../../providers/core_providers.dart';
import '../../widgets/figure_card.dart';

class BeginLearningDialog extends ConsumerWidget {
  final DateTime date;

  const BeginLearningDialog({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbl = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final figuresAsync = ref.watch(figuresByStateProvider(FigureState.toLearn));

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      title: Text(
        '${lbl.beginLearningDialogTitle}\n${date.toShortLabel(Localizations.localeOf(context))}',
        style: theme.textTheme.titleMedium,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: figuresAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erreur : $e'),
          data: (figures) {
            if (figures.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  lbl.noFiguresToLearn,
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
                  onTap: () => _confirmBeginLearning(context, ref, figure, lbl),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lbl.buttonClose),
        ),
      ],
    );
  }

  Future<void> _confirmBeginLearning(
    BuildContext context,
    WidgetRef ref,
    FigureModel figure,
    AppLocalizations lbl,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lbl.beginLearningConfirmTitle),
        content: Text(lbl.beginLearningConfirm(figure.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(lbl.buttonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(lbl.buttonConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final figureRepository = ref.read(figureRepositoryProvider);
    final plannedRepository = ref.read(trainingPlannedRepositoryProvider);
    if (figureRepository == null || plannedRepository == null) return;

    // Passage en apprentissage avec la date sélectionnée comme startDate
    final newOrder = await figureRepository.getMaxOrder(FigureState.learning);
    final updated = figure.copyWith(
      state: FigureState.learning,
      startDate: date,
      order: newOrder,
    );
    await figureRepository.update(updated);

    // Ajout dans TrainingPlanned pour ce jour
    await plannedRepository.add(
      TrainingPlannedModel(figureId: figure.id, date: date),
    );

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
