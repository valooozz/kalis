import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/providers/today_providers.dart';
import '../../models/journal_entry_model.dart';
import '../../providers/journal_providers.dart';
import '../../providers/core_providers.dart';

class JournalEntryFormDialog extends ConsumerStatefulWidget {
  final String figureId;
  final String? entryId;

  const JournalEntryFormDialog({
    super.key,
    required this.figureId,
    this.entryId,
  });

  @override
  ConsumerState<JournalEntryFormDialog> createState() =>
      _JournalEntryFormDialogState();
}

class _JournalEntryFormDialogState
    extends ConsumerState<JournalEntryFormDialog> {
  late TextEditingController _controller;
  bool _initialized = false;

  bool get _isEditing => widget.entryId != null;

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
    final lbl = AppLocalizations.of(context)!;
    final today = ref.read(todayProvider);

    // Chargement de l'entrée existante si on est en mode édition
    if (_isEditing) {
      final entryAsync = ref.read(
        journalEntryForFigureAndDateProvider((
          figureId: widget.figureId,
          date: today,
        )),
      );
      entryAsync.whenData((entry) {
        if (entry != null && !_initialized) {
          _controller.text = entry.text;
          _initialized = true;
        }
      });
    }

    return AlertDialog(
      title: Text(_isEditing ? lbl.editJournalEntry : lbl.newJournalEntry),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        autofocus: true,
        decoration: InputDecoration(hintText: lbl.journalHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lbl.buttonCancel),
        ),
        FilledButton(
          onPressed: () => _save(today),
          child: Text(_isEditing ? lbl.buttonSave : lbl.buttonAdd),
        ),
      ],
    );
  }

  Future<void> _save(DateTime today) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final repository = ref.read(journalEntryRepositoryProvider);
    if (repository == null) return;

    if (_isEditing) {
      final entry = await repository.getById(widget.entryId!);
      if (entry != null) {
        await repository.update(entry.copyWith(text: text));
      }
    } else {
      await repository.create(
        JournalEntryModel(
          id: '',
          figureId: widget.figureId,
          date: today,
          text: text,
        ),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }
}
