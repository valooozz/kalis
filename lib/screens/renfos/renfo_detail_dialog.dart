import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/renfo_model.dart';
import 'package:kalis/providers/core_providers.dart';
import 'package:kalis/providers/figure_providers.dart';
import 'package:kalis/widgets/figure_selection_chip.dart';
import 'renfo_form_dialog.dart';

class RenfoDetailDialog extends ConsumerStatefulWidget {
  final RenfoModel renfo;
  const RenfoDetailDialog({required this.renfo, super.key});

  @override
  ConsumerState<RenfoDetailDialog> createState() => _RenfoDetailDialogState();
}

class _RenfoDetailDialogState extends ConsumerState<RenfoDetailDialog> {
  late RenfoModel _renfo;

  @override
  void initState() {
    super.initState();
    _renfo = widget.renfo;
  }

  Future<void> _updateRenfo(RenfoModel r) async {
    final repo = ref.read(renfoRepositoryProvider);
    if (repo == null) return;
    // Mise à jour locale immédiate (l'écriture Firestore peut être lente
    // et le dialog peut être fermé entre-temps)
    setState(() => _renfo = r);
    await repo.update(r);
  }

  Future<void> _toggleFigure(String figureId) async {
    final updatedIds = List<String>.from(_renfo.figureIds);
    if (updatedIds.contains(figureId)) {
      updatedIds.remove(figureId);
    } else {
      updatedIds.add(figureId);
    }
    await _updateRenfo(_renfo.copyWith(figureIds: updatedIds));
  }

  Future<void> _deleteRenfo() async {
    final lbl = AppLocalizations.of(context)!;
    final repo = ref.read(renfoRepositoryProvider);
    final doneRepo = ref.read(renfoDoneRepositoryProvider);
    if (repo == null || doneRepo == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lbl.buttonDelete),
        content: Text(lbl.deleteRenfoConfirm(_renfo.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(lbl.buttonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(lbl.buttonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    await doneRepo.removeAllForRenfo(_renfo.id);
    await repo.delete(_renfo.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;
    final figuresAsync = ref.watch(linkableFiguresProvider);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.fitness_center,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(_renfo.name)),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final res = await showDialog(
                context: context,
                builder: (_) => RenfoFormDialog(initial: _renfo),
              );
              if (res is RenfoModel && mounted) setState(() => _renfo = res);
            },
            tooltip: lbl.buttonEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteRenfo,
            tooltip: lbl.buttonDelete,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Flexible(
              child: figuresAsync.when(
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Erreur : $e'),
                data: (figures) {
                  if (figures.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        lbl.noFigureAvailable,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: figures.length,
                    itemBuilder: (context, index) {
                      final figure = figures[index];
                      return FigureSelectionChip(
                        figure: figure,
                        selected: _renfo.figureIds.contains(figure.id),
                        onTap: () => _toggleFigure(figure.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
