import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import '../../models/figure_model.dart';
import '../../models/training_done_model.dart';
import '../../providers/core_providers.dart';
import '../../providers/planning_providers.dart';
import '../../widgets/figure_square_card.dart';
import '../../core/utils/date_utils.dart';

class PastPlanningDialog extends StatelessWidget {
  const PastPlanningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final days = List.generate(
      14,
      (i) => DateTime(now.year, now.month, now.day - 1 - i),
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    lbl.pastPlanningTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: days.length,
              itemBuilder: (context, index) {
                return _PastDaySection(date: days[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PastDaySection extends ConsumerWidget {
  final DateTime date;

  const _PastDaySection({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbl = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final figuresAsync = ref.watch(figuresForPastDateProvider(date));
    final doneAsync = ref.watch(trainingDoneForDateProvider(date));

    final doneIds = doneAsync.valueOrNull?.map((t) => t.figureId).toSet() ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            date.toShortLabel(Localizations.localeOf(context)),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        figuresAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Erreur : $e'),
          data: (figures) {
            if (figures.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  lbl.noFiguresPast,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: figures.map((figure) {
                  final isDone = doneIds.contains(figure.id);
                  return SizedBox(
                    width: _cardSize(context),
                    height: _cardSize(context),
                    child: FigureSquareCard(
                      figure: figure,
                      isDone: isDone,
                      showStateIcon: false,
                      onTap: () =>
                          _confirmToggleDone(context, ref, figure, isDone),
                      onLongPress: () =>
                          _confirmRemove(context, ref, figure, isDone),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        const Divider(height: 1),
      ],
    );
  }

  double _cardSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth - 32 - 32 - 16) / 3;
  }

  Future<void> _confirmToggleDone(
    BuildContext context,
    WidgetRef ref,
    FigureModel figure,
    bool isDone,
  ) async {
    final lbl = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          isDone
              ? lbl.pastPlanningMarkNotDoneTitle
              : lbl.pastPlanningMarkDoneTitle,
        ),
        content: Text(
          isDone
              ? lbl.pastPlanningMarkNotDoneConfirm(figure.name)
              : lbl.pastPlanningMarkDoneConfirm(figure.name),
        ),
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

    final repository = ref.read(trainingDoneRepositoryProvider);
    if (repository == null) return;

    if (isDone) {
      await repository.remove(figure.id, date);
    } else {
      await repository.add(TrainingDoneModel(figureId: figure.id, date: date));
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    FigureModel figure,
    bool isDone,
  ) async {
    final lbl = AppLocalizations.of(context)!;

    if (isDone) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(lbl.errorRemovalTitle),
            ],
          ),
          content: Text(lbl.errorRemoval),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(lbl.buttonClose),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lbl.pastPlanningRemoveTitle),
        content: Text(lbl.pastPlanningRemoveConfirm(figure.name)),
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

    final repository = ref.read(trainingPlannedRepositoryProvider);
    if (repository == null) return;

    await repository.remove(figure.id, date);
  }
}
