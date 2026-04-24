import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/figure_model.dart';
import '../../providers/core_providers.dart';

class FigureStatusPickerDialog extends ConsumerWidget {
  final FigureModel figure;

  const FigureStatusPickerDialog({super.key, required this.figure});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Changer le statut'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: FigureState.values.map((state) {
          final isSelected = state == figure.state;
          return GestureDetector(
            onTap: () => _changeState(context, ref, state),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  Widget _stateIcon(FigureState state, ThemeData theme, bool isSelected) {
    final color =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.outline;
    switch (state) {
      case FigureState.toLearn:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outline, color: color),
            const SizedBox(height: 4),
            Text('À apprendre',
                style: theme.textTheme.labelSmall?.copyWith(color: color)),
          ],
        );
      case FigureState.learning:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_gymnastics, color: color),
            const SizedBox(height: 4),
            Text('En apprentissage',
                style: theme.textTheme.labelSmall?.copyWith(color: color)),
          ],
        );
      case FigureState.learned:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_outline, color: color),
            const SizedBox(height: 4),
            Text('Apprise',
                style: theme.textTheme.labelSmall?.copyWith(color: color)),
          ],
        );
    }
  }

  Future<void> _changeState(
      BuildContext context, WidgetRef ref, FigureState newState) async {
    if (newState == figure.state) {
      Navigator.of(context).pop();
      return;
    }

    final repository = ref.read(figureRepositoryProvider);
    if (repository == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Mise à jour des dates selon le nouveau statut
    FigureModel updated = figure.copyWith(state: newState);
    if (newState == FigureState.learning) {
      updated = updated.copyWith(startDate: today);
    } else if (newState == FigureState.learned) {
      updated = updated.copyWith(endDate: today);
    }

    await repository.update(updated);
    if (context.mounted) Navigator.of(context).pop();
  }
}