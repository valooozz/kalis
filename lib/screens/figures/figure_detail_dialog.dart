import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/core/utils/firestore_write_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/journal_entry_model.dart';
import 'package:kalis/models/training_planned_model.dart';
import 'package:kalis/providers/today_providers.dart';
import 'package:kalis/providers/figure_providers.dart';
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

const _favoriteHintSeenKey = 'favorite_hint_seen';
const _activeHintSeenKey = 'active_hint_seen';

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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: figure.color.color.withValues(
                    alpha: figure.paused ? 0.4 : 1,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(figure.name)),
              if (figure.state == FigureState.learned)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _toggleActive(context, ref, lbl);
                  },
                  icon: Icon(
                    figure.active ? Icons.loop : Icons.loop_outlined,
                    color: figure.active ? figure.color.color : null,
                  ),
                  tooltip: figure.active
                      ? lbl.deactivateFigure
                      : lbl.activateFigure,
                ),
              if (figure.state != FigureState.toLearn)
                IconButton(
                  icon: Icon(
                    figure.favorite ? Icons.star : Icons.star_outline,
                    color: figure.favorite ? figure.color.color : null,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _toggleFavorite(context, ref, lbl);
                  },
                  tooltip: figure.favorite
                      ? lbl.unfavoriteFigure
                      : lbl.favoriteFigure,
                ),
              IconButton(
                icon: _stateIcon(figure.state, theme),
                onPressed: () => _openStatusPicker(context, ref),
                tooltip: lbl.changeStatus,
              ),
            ],
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

              Divider(
                height: 24,
                color: figure.paused
                    ? theme.colorScheme.onSurfaceVariant
                    : null,
              ),

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              children: [
                if (figure.state != FigureState.toLearn) ...[
                  IconButton(
                    onPressed: () => _openCalendarDialog(context, ref, figure),
                    icon: const Icon(Icons.calendar_month),
                  ),
                  IconButton(
                    onPressed: () => _togglePaused(context, ref, lbl, figure),
                    icon: Icon(figure.paused ? Icons.play_arrow : Icons.pause),
                    tooltip: figure.paused ? lbl.resumeFigure : lbl.buttonPause,
                  ),
                ],
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(lbl.buttonClose),
                ),
                if (figure.archived)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _restoreFigure(ref);
                    },
                    icon: const Icon(Icons.unarchive_outlined),
                    label: Text(lbl.restoreFigure),
                  )
                else
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
            ),
          ],
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

  void _deleteEntry(WidgetRef ref, String entryId) {
    final repository = ref.read(journalEntryRepositoryProvider);
    final write = repository?.delete(entryId);
    if (write != null) {
      detachFirestoreWrite(write, operation: 'deleting a journal entry');
    }
  }

  Future<void> _beginLearning(BuildContext context, WidgetRef ref) async {
    final today = ref.read(todayProvider);

    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
    );

    if (picked == null || !context.mounted) return;

    final figureRepository = ref.read(figureRepositoryProvider);
    final plannedRepository = ref.read(trainingPlannedRepositoryProvider);
    if (figureRepository == null || plannedRepository == null) return;

    final newOrder = ref.read(nextFigureOrderProvider(FigureState.learning));
    if (newOrder == null) return;
    final updated = figure.copyWith(
      state: FigureState.learning,
      startDate: picked,
      order: newOrder,
    );
    detachFirestoreWrite(
      figureRepository.update(updated),
      operation: 'starting to learn a figure',
    );
    detachFirestoreWrite(
      plannedRepository.add(
        TrainingPlannedModel(figureId: figure.id, date: picked),
      ),
      operation: 'planning a figure',
    );

    Navigator.of(context).pop();
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

    final update = figureRepository?.update(newFigure);
    if (update != null) {
      detachFirestoreWrite(update, operation: 'changing figure pause state');
    }
    final removal = trainingPlannedRepository?.removeAllForFigure(figure.id);
    if (removal != null) {
      detachFirestoreWrite(removal, operation: 'removing a figure from plans');
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations lbl,
  ) async {
    final figureRepository = ref.read(figureRepositoryProvider);
    final write = figureRepository?.update(
      figure.copyWith(active: !figure.active),
    );
    if (write != null) {
      detachFirestoreWrite(write, operation: 'toggling figure activity');
      await _showHintOnce(context, lbl.activeFigureHint, _activeHintSeenKey);
    }
  }

  void _restoreFigure(WidgetRef ref) {
    final figureRepository = ref.read(figureRepositoryProvider);
    final write = figureRepository?.update(figure.copyWith(archived: false));
    if (write != null) {
      detachFirestoreWrite(write, operation: 'restoring a figure');
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations lbl,
  ) async {
    final figureRepository = ref.read(figureRepositoryProvider);
    final write = figureRepository?.update(
      figure.copyWith(favorite: !figure.favorite),
    );
    if (write != null) {
      detachFirestoreWrite(write, operation: 'toggling figure favorite');
      await _showHintOnce(
        context,
        lbl.favoriteFigureHint,
        _favoriteHintSeenKey,
      );
    }
  }

  Future<void> _showHintOnce(
    BuildContext context,
    String message,
    String key,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(key) ?? false) return;

    await preferences.setBool(key, true);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
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
