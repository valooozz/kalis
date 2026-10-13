import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import '../../providers/core_providers.dart';
import '../../providers/general_note_providers.dart';

class GeneralNoteDialog extends ConsumerStatefulWidget {
  const GeneralNoteDialog({super.key});

  @override
  ConsumerState<GeneralNoteDialog> createState() => _GeneralNoteDialogState();
}

class _GeneralNoteDialogState extends ConsumerState<GeneralNoteDialog> {
  final _controller = TextEditingController();

  // On n'initialise le controller qu'une seule fois, à la première
  // réception de la donnée, pour ne pas écraser une saisie en cours
  // si le stream Firestore émet à nouveau pendant l'édition.
  bool _initialized = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    final noteAsync = ref.watch(generalNoteProvider);

    return AlertDialog(
      title: Text(lbl.generalNoteDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: noteAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Erreur : $e'),
          data: (text) {
            if (!_initialized) {
              _controller.text = text;
              _initialized = true;
            }
            return TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: lbl.generalNoteHint),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lbl.buttonCancel),
        ),
        FilledButton(
          onPressed: _initialized ? _save : null,
          child: Text(lbl.buttonSave),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final repository = ref.read(generalNoteRepositoryProvider);
    if (repository == null) return;

    await repository.save(_controller.text.trim());

    if (mounted) Navigator.of(context).pop();
  }
}
