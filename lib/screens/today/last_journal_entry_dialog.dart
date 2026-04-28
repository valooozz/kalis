import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/widgets/record_display.dart';
import '../../models/figure_model.dart';
import '../../providers/journal_providers.dart';
import '../../core/utils/date_utils.dart';

class LastJournalEntryDialog extends ConsumerWidget {
  final FigureModel figure;

  const LastJournalEntryDialog({super.key, required this.figure});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(journalEntriesForFigureProvider(figure.id));

    return AlertDialog(
      title: Text(figure.name),
      content: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (entries) {
          if (entries.isEmpty) {
            return Text(
              lbl.noJournalEntry,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            );
          }

          final lastEntry = entries.first;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lastEntry.date.toShortDate(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(lastEntry.text, style: theme.textTheme.bodyMedium),
              if (figure.state == FigureState.learned) ...[
                const Divider(height: 24),
                RecordDisplay(figure: figure),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lbl.buttonClose),
        ),
      ],
    );
  }
}
