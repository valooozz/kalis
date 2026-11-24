import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/core/utils/firestore_write_utils.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/screens/figures/record_form_dialog.dart';
import '../../models/figure_model.dart';
import '../../models/training_done_model.dart';
import '../../models/journal_entry_model.dart';
import '../../providers/today_providers.dart';
import '../../providers/figure_providers.dart';
import '../../providers/journal_providers.dart';
import '../../providers/core_providers.dart';
import '../../core/utils/date_utils.dart';

class TodayTrainingDialog extends ConsumerStatefulWidget {
  final FigureModel figure;

  const TodayTrainingDialog({super.key, required this.figure});

  @override
  ConsumerState<TodayTrainingDialog> createState() =>
      _TodayTrainingDialogState();
}

class _TodayTrainingDialogState extends ConsumerState<TodayTrainingDialog> {
  late TextEditingController _controller;
  JournalEntryModel? _existingEntry;
  bool _hasEditedNote = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    ref.listenManual(todayJournalEntryForFigureProvider(widget.figure.id), (
      _,
      entryAsync,
    ) {
      entryAsync.whenData((entry) {
        _existingEntry = entry;
        if (entry == null || _hasEditedNote || _controller.text.isNotEmpty) {
          return;
        }

        final selection = _controller.selection;
        final offset = selection.isValid
            ? selection.extentOffset.clamp(0, entry.text.length).toInt()
            : entry.text.length;
        _controller.value = TextEditingValue(
          text: entry.text,
          selection: TextSelection.collapsed(offset: offset),
        );
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;
    final journalEntriesAsync = ref.watch(
      journalEntriesForFigureProvider(widget.figure.id),
    );

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: widget.figure.color.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.figure.name)),
          if (widget.figure.state == FigureState.learning)
            IconButton(
              icon: const Icon(Icons.workspace_premium),
              onPressed: () => _markAsLearned(context),
              tooltip: lbl.markAsLearned,
            ),
          if (widget.figure.state == FigureState.learned)
            IconButton(
              icon: const Icon(Icons.emoji_events),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => RecordFormDialog(figure: widget.figure),
              ),
              tooltip: lbl.recordDialogTitle,
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (journalEntriesAsync.valueOrNull case [final lastEntry, ...]) ...[
            Text(
              lastEntry.date.toShortDate(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(lastEntry.text, style: theme.textTheme.bodyMedium),
            const Divider(height: 24),
          ],
          Text(lbl.trainingNote, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 4,
            onChanged: (_) => _hasEditedNote = true,
            decoration: InputDecoration(hintText: lbl.trainingHint),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lbl.buttonCancel),
        ),
        FilledButton.icon(
          onPressed: () => _validate(_existingEntry),
          icon: const Icon(Icons.done_outline),
          label: Text(lbl.buttonValidate),
        ),
      ],
    );
  }

  void _validate(JournalEntryModel? existingEntry, {bool pop = true}) {
    final repository = ref.read(trainingDoneRepositoryProvider);
    final journalRepository = ref.read(journalEntryRepositoryProvider);
    if (repository == null || journalRepository == null) return;

    final today = ref.read(todayProvider);
    final text = _controller.text.trim();

    // Ajout dans TrainingDone
    detachFirestoreWrite(
      repository.add(
        TrainingDoneModel(figureId: widget.figure.id, date: today),
      ),
      operation: 'validating a training',
    );

    // Gestion de l'entrée de journal
    if (text.isNotEmpty) {
      if (existingEntry != null) {
        // Modification de l'entrée existante
        detachFirestoreWrite(
          journalRepository.update(existingEntry.copyWith(text: text)),
          operation: 'updating a training note',
        );
      } else {
        // Création d'une nouvelle entrée
        detachFirestoreWrite(
          journalRepository.create(
            JournalEntryModel(
              id: '',
              figureId: widget.figure.id,
              date: today,
              text: text,
            ),
          ),
          operation: 'creating a training note',
        );
      }
    }

    if (pop && mounted) Navigator.of(context).pop();
  }

  Future<void> _markAsLearned(BuildContext context) async {
    final lbl = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lbl.markAsLearnedTitle),
        content: Text(lbl.markAsLearnedConfirm(widget.figure.name)),
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

    // On valide d'abord l'entraînement et le journal
    _validate(_existingEntry, pop: false);

    final figureRepository = ref.read(figureRepositoryProvider);
    if (figureRepository == null) return;

    final today = ref.read(todayProvider);

    // Passage à l'état maîtrisée avec la date du jour, et en bas de la liste
    final newOrder = ref.read(nextFigureOrderProvider(FigureState.learned));
    if (newOrder == null) return;
    final updated = widget.figure.copyWith(
      state: FigureState.learned,
      endDate: today,
      order: newOrder,
    );
    detachFirestoreWrite(
      figureRepository.update(updated),
      operation: 'marking a figure as learned',
    );

    if (!context.mounted) return;

    // Ouverture de RecordFormDialog avec la figure mise à jour
    await showDialog(
      context: context,
      builder: (_) => RecordFormDialog(figure: updated),
    );

    if (context.mounted) Navigator.of(context).pop();
  }
}
