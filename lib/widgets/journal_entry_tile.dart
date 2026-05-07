import 'package:flutter/material.dart';
import 'package:kalis/l10n/app_localizations.dart';
import '../models/journal_entry_model.dart';
import '../core/utils/date_utils.dart';

class JournalEntryTile extends StatelessWidget {
  final JournalEntryModel entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const JournalEntryTile({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      title: Text(entry.text),
      subtitle: Text(
        entry.date.toShortDate(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
            tooltip: lbl.buttonEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: lbl.buttonDelete,
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }
}
