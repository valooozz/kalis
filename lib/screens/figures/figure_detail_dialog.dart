import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/journal_entry_model.dart';
import 'package:kalis/models/training_planned_model.dart';
import 'package:kalis/providers/today_providers.dart';
import 'package:kalis/screens/figures/figure_calendar_dialog.dart';
import 'package:kalis/widgets/record_display.dart';
import '../../models/figure_model.dart';
import '../../providers/journal_providers.dart';
import '../../providers/core_providers.dart';
import '../../widgets/journal_entry_tile.dart';
import '../../core/utils/date_utils.dart';
import 'figure_form_dialog.dart';
import 'figure_status_picker_dialog.dart';
import 'journal_entry_form_dialog.dart';

class FigureDetailDialog extends ConsumerWidget {
  final FigureModel figure;

  const FigureDetailDialog({super.key, required this.figure});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(journalEntriesForFigureProvider(figure.id));

    return AlertDialog(
      backgroundColor: figure.paused ? theme.colorScheme.outlineVariant : null,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      title: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: figure.color.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(figure.name)),
          if (figure.state != FigureState.toLearn) ...[
            IconButton(
              onPressed: () => _openCalendarDialog(context, ref, figure),
              icon: Icon(Icons.calendar_month),
            ),
            IconButton(
              onPressed: () => _togglePaused(context, ref, lbl, figure),
              icon: Icon(figure.paused ? Icons.play_arrow : Icons.pause),
            ),
          ],
          IconButton(
            icon: _stateIcon(figure.state, theme),
            onPressed: () => _openStatusPicker(context, ref),
            tooltip: lbl.changeStatus,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dates
              if (figure.startDate != null)
                _InfoRow(
                  label: lbl.fieldStartedOn,
                  value: figure.startDate!.toShortDate(),
                ),
              if (figure.endDate != null)
                _InfoRow(
                  label: lbl.fieldMasteredOn,
                  value: figure.endDate!.toShortDate(),
                ),
              if (figure.state == FigureState.learned)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: RecordDisplay(figure: figure),
                ),

              if (figure.state == FigureState.toLearn)
                Center(
                  child: FilledButton.icon(
                    onPressed: () {
                      _beginLearning(context, ref);
                    },
                    icon: Icon(FigureState.learning.icon),
                    label: Text(lbl.beginLearning),
                  ),
                ),

              const Divider(height: 24),

              entriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erreur : $e'),
                data: (entries) {
                  final hasTodayEntry = entries.any((e) => e.date.isToday);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lbl.journal,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!hasTodayEntry)
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _openAddEntry(context, ref),
                              tooltip: lbl.addJournalEntry,
                            ),
                        ],
                      ),
                      if (entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            lbl.noJournalEntry,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: entries
                              .map(
                                (entry) => JournalEntryTile(
                                  entry: entry,
                                  onEdit: () =>
                                      _openEditEntry(context, ref, entry),
                                  onDelete: () => _deleteEntry(ref, entry.id),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lbl.buttonClose),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (_) => FigureFormDialog(figure: figure),
            );
          },
          icon: const Icon(Icons.edit),
          label: Text(lbl.buttonEdit),
        ),
      ],
    );
  }

  Widget _stateIcon(FigureState state, ThemeData theme) {
    return Icon(figure.state.icon, color: figure.color.color);
  }

  Future<void> _openCalendarDialog(
    BuildContext context,
    WidgetRef ref,
    FigureModel figure,
  ) async {
    Navigator.of(context).pop();
    await showDialog(
      context: context,
      builder: (_) => FigureCalendarDialog(figure: figure),
    );
  }

  void _openStatusPicker(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (_) => FigureStatusPickerDialog(figure: figure),
    );
  }

  void _openAddEntry(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => JournalEntryFormDialog(figureId: figure.id),
    );
  }

  void _openEditEntry(
    BuildContext context,
    WidgetRef ref,
    JournalEntryModel entry,
  ) {
    showDialog(
      context: context,
      builder: (_) => JournalEntryFormDialog(figureId: figure.id, entry: entry),
    );
  }

  Future<void> _deleteEntry(WidgetRef ref, String entryId) async {
    final repository = ref.read(journalEntryRepositoryProvider);
    await repository?.delete(entryId);
  }

  Future<void> _beginLearning(BuildContext context, WidgetRef ref) async {
    final today = ref.read(todayProvider);

    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    final figureRepository = ref.read(figureRepositoryProvider);
    final plannedRepository = ref.read(trainingPlannedRepositoryProvider);
    if (figureRepository == null || plannedRepository == null) return;

    final newOrder = await figureRepository.getMaxOrder(FigureState.learning);
    final updated = figure.copyWith(
      state: FigureState.learning,
      startDate: picked,
      order: newOrder,
    );
    await figureRepository.update(updated);

    await plannedRepository.add(
      TrainingPlannedModel(figureId: figure.id, date: picked),
    );

    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _togglePaused(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations lbl,
    FigureModel figure,
  ) async {
    bool? confirmed = true;

    if (!figure.paused) {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(lbl.pauseFigureTitle),
          content: Text(lbl.pauseFigureConfirm(figure.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(lbl.buttonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(lbl.buttonPause),
            ),
          ],
        ),
      );
    }
    if (confirmed != true) return;

    if (context.mounted) Navigator.of(context).pop();

    final figureRepository = ref.read(figureRepositoryProvider);
    final trainingPlannedRepository = ref.read(
      trainingPlannedRepositoryProvider,
    );

    final newPaused = !figure.paused;
    final newFigure = figure.copyWith(paused: newPaused);

    await figureRepository?.update(newFigure);
    await trainingPlannedRepository?.removeAllForFigure(figure.id);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
