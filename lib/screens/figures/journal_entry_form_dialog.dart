import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/providers/today_providers.dart';
import '../../models/journal_entry_model.dart';
import '../../providers/core_providers.dart';

class JournalEntryFormDialog extends ConsumerStatefulWidget {
  final String figureId;
  final JournalEntryModel? entry;

  const JournalEntryFormDialog({super.key, required this.figureId, this.entry});

  @override
  ConsumerState<JournalEntryFormDialog> createState() =>
      _JournalEntryFormDialogState();
}

class _JournalEntryFormDialogState
    extends ConsumerState<JournalEntryFormDialog> {
  late TextEditingController _controller;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry?.text);
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

    if (_isEditing && widget.entry != null) {
      await repository.update(widget.entry!.copyWith(text: text));
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
