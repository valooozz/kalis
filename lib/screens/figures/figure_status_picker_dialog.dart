import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/providers/today_providers.dart';
import '../../models/figure_model.dart';
import '../../providers/core_providers.dart';

class FigureStatusPickerDialog extends ConsumerWidget {
  final FigureModel figure;

  const FigureStatusPickerDialog({super.key, required this.figure});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(lbl.changeStatus),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: FigureState.values.map((state) {
          final isSelected = state == figure.state;
          return GestureDetector(
            onTap: () => _changeState(context, ref, state),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
              ),
              child: _stateIcon(state, theme, isSelected),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lbl.buttonCancel),
        ),
      ],
    );
  }

  Widget _stateIcon(FigureState state, ThemeData theme, bool isSelected) {
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    switch (state) {
      case FigureState.toLearn:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(state.icon, color: color),
            const SizedBox(height: 4),
            Text(
              state.label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        );
      case FigureState.learning:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(state.icon, color: color),
            const SizedBox(height: 4),
            Text(
              state.label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        );
      case FigureState.learned:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(state.icon, color: color),
            const SizedBox(height: 4),
            Text(
              state.label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        );
    }
  }

  Future<void> _changeState(
    BuildContext context,
    WidgetRef ref,
    FigureState newState,
  ) async {
    if (newState == figure.state) {
      Navigator.of(context).pop();
      return;
    }

    final figureRepository = ref.read(figureRepositoryProvider);
    final trainingPlannedRepository = ref.read(
      trainingPlannedRepositoryProvider,
    );
    if (figureRepository == null || trainingPlannedRepository == null) return;

    final today = ref.read(todayProvider);

    // Mise à jour des dates selon le nouveau statut
    FigureModel updated = figure.copyWith(state: newState);
    if (newState == FigureState.toLearn) {
      updated = updated.copyWith(clearStartDate: true, clearEndDate: true);
      await trainingPlannedRepository.removeAllForFigure(figure.id);
    } else if (newState == FigureState.learning) {
      updated = updated.copyWith(startDate: today, clearEndDate: true);
    } else if (newState == FigureState.learned) {
      updated = updated.copyWith(endDate: today);
    }

    await figureRepository.update(updated);
    if (context.mounted) Navigator.of(context).pop();
  }
}
