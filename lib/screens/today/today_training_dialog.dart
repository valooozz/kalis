import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import '../../models/figure_model.dart';
import '../../models/training_done_model.dart';
import '../../models/journal_entry_model.dart';
import '../../providers/today_providers.dart';
import '../../providers/journal_providers.dart';
import '../../providers/core_providers.dart';

class TodayTrainingDialog extends ConsumerStatefulWidget {
  final FigureModel figure;

  const TodayTrainingDialog({super.key, required this.figure});

  @override
  ConsumerState<TodayTrainingDialog> createState() =>
      _TodayTrainingDialogState();
}

class _TodayTrainingDialogState extends ConsumerState<TodayTrainingDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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
    final entryAsync = ref.watch(
      todayJournalEntryForFigureProvider(widget.figure.id),
    );

    // Quand l'entrée est chargée, on initialise le controller
    entryAsync.whenData((entry) {
      if (entry != null && _controller.text.isEmpty) {
        _controller.text = entry.text;
      }
    });

    return AlertDialog(
      title: Text(widget.figure.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lbl.trainingNote, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 4,
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
          onPressed: () => _validate(entryAsync.valueOrNull),
          icon: const Icon(Icons.check),
          label: Text(lbl.buttonValidate),
        ),
      ],
    );
  }

  Future<void> _validate(JournalEntryModel? existingEntry) async {
    final repository = ref.read(trainingDoneRepositoryProvider);
    final journalRepository = ref.read(journalEntryRepositoryProvider);
    if (repository == null || journalRepository == null) return;

    final today = ref.read(todayProvider);
    final text = _controller.text.trim();

    // Ajout dans TrainingDone
    await repository.add(
      TrainingDoneModel(figureId: widget.figure.id, date: today),
    );

    // Gestion de l'entrée de journal
    if (text.isNotEmpty) {
      if (existingEntry != null) {
        // Modification de l'entrée existante
        await journalRepository.update(existingEntry.copyWith(text: text));
      } else {
        // Création d'une nouvelle entrée
        await journalRepository.create(
          JournalEntryModel(
            id: '',
            figureId: widget.figure.id,
            date: today,
            text: text,
          ),
        );
      }
    }

    if (mounted) Navigator.of(context).pop();
  }
}
