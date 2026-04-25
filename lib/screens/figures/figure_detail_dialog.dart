import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final entriesAsync = ref.watch(journalEntriesForFigureProvider(figure.id));

    return AlertDialog(
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
          // Bouton changement de statut
          IconButton(
            icon: _stateIcon(figure.state, theme),
            onPressed: () => _openStatusPicker(context, ref),
            tooltip: 'Changer le statut',
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
                  label: 'Débutée le',
                  value: figure.startDate!.toShortDate(),
                ),
              if (figure.endDate != null)
                _InfoRow(
                  label: 'Maîtrisée le',
                  value: figure.endDate!.toShortDate(),
                ),
              const Divider(height: 24),
              // Journal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Journal',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _openAddEntry(context, ref),
                    tooltip: 'Ajouter une entrée',
                  ),
                ],
              ),
              entriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erreur : $e'),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Aucune entrée de journal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: entries
                        .map(
                          (entry) => JournalEntryTile(
                            entry: entry,
                            onEdit: () =>
                                _openEditEntry(context, ref, entry.id),
                            onDelete: () => _deleteEntry(ref, entry.id),
                          ),
                        )
                        .toList(),
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
          child: const Text('Fermer'),
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
          label: const Text('Modifier'),
        ),
      ],
    );
  }

  Widget _stateIcon(FigureState state, ThemeData theme) {
    return Icon(figure.state.icon, color: figure.color.color);
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

  void _openEditEntry(BuildContext context, WidgetRef ref, String entryId) {
    showDialog(
      context: context,
      builder: (_) =>
          JournalEntryFormDialog(figureId: figure.id, entryId: entryId),
    );
  }

  Future<void> _deleteEntry(WidgetRef ref, String entryId) async {
    final repository = ref.read(journalEntryRepositoryProvider);
    await repository?.delete(entryId);
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
