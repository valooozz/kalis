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

    final toLearnAsync = ref.watch(figuresByStateProvider(FigureState.toLearn));
    final pausedAsync = ref.watch(pausedFiguresProvider);

    final isLoading = toLearnAsync.isLoading || pausedAsync.isLoading;
    final hasError = toLearnAsync.hasError || pausedAsync.hasError;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      title: Text(
        '${lbl.beginLearningDialogTitle}\n${date.toShortLabel(Localizations.localeOf(context))}',
        style: theme.textTheme.titleMedium,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: () {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (hasError) {
            return Text('Erreur');
          }

          final pausedFigures = pausedAsync.value ?? [];
          final toLearnFigures = (toLearnAsync.value ?? [])
              .where((f) => !f.paused)
              .toList();

          final isEmpty = pausedFigures.isEmpty && toLearnFigures.isEmpty;

          if (isEmpty) {
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

          return ListView(
            shrinkWrap: true,
            children: [
              if (pausedFigures.isNotEmpty) ...[
                _SectionHeader(label: lbl.pausedFiguresSection),
                const SizedBox(height: 4),
                ...pausedFigures.map(
                  (figure) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: FigureCard(
                      figure: figure,
                      onTap: () => _confirmResume(context, ref, figure, lbl),
                    ),
                  ),
                ),
                if (toLearnFigures.isNotEmpty) const SizedBox(height: 8),
              ],
              if (toLearnFigures.isNotEmpty) ...[
                _SectionHeader(label: lbl.toLearnFiguresSection),
                const SizedBox(height: 4),
                ...toLearnFigures.map(
                  (figure) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: FigureCard(
                      figure: figure,
                      onTap: () =>
                          _confirmBeginLearning(context, ref, figure, lbl),
                    ),
                  ),
                ),
              ],
            ],
          );
        }(),
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

    final newOrder = await figureRepository.getMaxOrder(FigureState.learning);
    final updated = figure.copyWith(
      state: FigureState.learning,
      startDate: date,
      order: newOrder,
    );
    await figureRepository.update(updated);

    await plannedRepository.add(
      TrainingPlannedModel(figureId: figure.id, date: date),
    );
  }

  Future<void> _confirmResume(
    BuildContext context,
    WidgetRef ref,
    FigureModel figure,
    AppLocalizations lbl,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lbl.resumeFigureConfirmTitle),
        content: Text(lbl.resumeFigureConfirm(figure.name)),
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

    final updated = figure.copyWith(paused: false);
    await figureRepository.update(updated);

    await plannedRepository.add(
      TrainingPlannedModel(figureId: figure.id, date: date),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}
