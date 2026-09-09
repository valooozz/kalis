import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/widgets/figure_selection_chip.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/core_providers.dart';
import '../../providers/planning_providers.dart';
import '../../providers/today_providers.dart';

class SwapDaysDialog extends ConsumerStatefulWidget {
  const SwapDaysDialog({super.key});

  @override
  ConsumerState<SwapDaysDialog> createState() => _SwapDaysDialogState();
}

class _SwapDaysDialogState extends ConsumerState<SwapDaysDialog> {
  DateTime? _dayA;
  DateTime? _dayB;
  bool _isSwapping = false;

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    final materialLbl = MaterialLocalizations.of(context);
    final today = ref.watch(todayProvider);
    final days = List.generate(14, (i) => today.add(Duration(days: i)));

    return AlertDialog(
      title: Text(lbl.swapDaysDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (final day in days) _buildDayTile(context, day)],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSwapping ? null : () => Navigator.of(context).pop(),
          child: Text(materialLbl.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: (_dayA != null && _dayB != null && !_isSwapping)
              ? () => _confirmSwap(context)
              : null,
          child: _isSwapping
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(lbl.swapDaysConfirmButton),
        ),
      ],
    );
  }

  Widget _buildDayTile(BuildContext context, DateTime day) {
    final lbl = AppLocalizations.of(context)!;
    final isToday = day.isToday;
    final isSelected =
        (_dayA != null && day.isSameDay(_dayA!)) ||
        (_dayB != null && day.isSameDay(_dayB!));
    // On peut cocher tant qu'il reste une case libre (max 2)
    final canToggle = isSelected || _dayA == null || _dayB == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: isSelected,
          onChanged: canToggle
              ? (checked) => _onDayToggled(day, checked ?? false)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          title: Text(
            isToday
                ? lbl.today
                : day.toShortLabel(Localizations.localeOf(context)),
          ),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: _DayFiguresPreview(date: day),
          ),
      ],
    );
  }

  void _onDayToggled(DateTime day, bool checked) {
    setState(() {
      if (checked) {
        if (_dayA == null) {
          _dayA = day;
        } else {
          _dayB ??= day;
        }
      } else {
        if (_dayA != null && day.isSameDay(_dayA!)) _dayA = null;
        if (_dayB != null && day.isSameDay(_dayB!)) _dayB = null;
      }
    });
  }

  Future<void> _confirmSwap(BuildContext context) async {
    final lbl = AppLocalizations.of(context)!;
    final dayA = _dayA!;
    final dayB = _dayB!;

    final plannedRepository = ref.read(trainingPlannedRepositoryProvider);
    final doneRepository = ref.read(trainingDoneRepositoryProvider);
    if (plannedRepository == null || doneRepository == null) return;

    final today = ref.read(todayProvider);

    setState(() => _isSwapping = true);

    try {
      // Blocage si une figure déjà faite aujourd'hui serait déplacée
      for (final day in [dayA, dayB]) {
        if (!day.isSameDay(today)) continue;
        final planned = ref.read(plannedForDayProvider(day)).valueOrNull ?? [];
        for (final entry in planned) {
          final isDone = await doneRepository.exists(entry.figureId, day);
          if (isDone) {
            if (context.mounted) {
              await showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(lbl.cannotSwapDoneFigureTitle),
                  content: Text(lbl.cannotSwapDoneFigure),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        MaterialLocalizations.of(context).okButtonLabel,
                      ),
                    ),
                  ],
                ),
              );
            }
            return;
          }
        }
      }

      final plannedA = ref.read(plannedForDayProvider(dayA)).valueOrNull ?? [];
      final plannedB = ref.read(plannedForDayProvider(dayB)).valueOrNull ?? [];

      await plannedRepository.swapDays(
        dayA: dayA,
        dayB: dayB,
        figureIdsA: plannedA.map((t) => t.figureId).toList(),
        figureIdsB: plannedB.map((t) => t.figureId).toList(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(lbl.swapDaysSuccess)));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSwapping = false);
    }
  }
}

class _DayFiguresPreview extends ConsumerWidget {
  final DateTime date;

  const _DayFiguresPreview({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbl = AppLocalizations.of(context)!;
    final figuresAsync = ref.watch(figuresForDayProvider(date));

    return figuresAsync.when(
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('Erreur : $e'),
      data: (figures) {
        if (figures.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              lbl.noFigurePlannedThisDay,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: figures
              .map(
                (figure) => FigureSelectionChip(figure: figure, selected: true),
              )
              .toList(),
        );
      },
    );
  }
}
