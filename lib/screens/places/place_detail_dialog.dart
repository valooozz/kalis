import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/place_model.dart';
import 'package:kalis/providers/core_providers.dart';
import 'package:kalis/providers/figure_providers.dart';
import 'package:kalis/widgets/figure_selection_chip.dart';
import 'place_form_dialog.dart';

class PlaceDetailDialog extends ConsumerStatefulWidget {
  final PlaceModel place;
  const PlaceDetailDialog({required this.place, super.key});

  @override
  ConsumerState<PlaceDetailDialog> createState() => _PlaceDetailDialogState();
}

class _PlaceDetailDialogState extends ConsumerState<PlaceDetailDialog> {
  late PlaceModel _place;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
  }

  Future<void> _updatePlace(PlaceModel p) async {
    final repo = ref.read(placeRepositoryProvider);
    if (repo == null) return;
    await repo.update(p);
    setState(() => _place = p);
  }

  Future<void> _toggleFigure(String figureId) async {
    final updatedIds = List<String>.from(_place.figureIds);
    if (updatedIds.contains(figureId)) {
      updatedIds.remove(figureId);
    } else {
      updatedIds.add(figureId);
    }
    await _updatePlace(_place.copyWith(figureIds: updatedIds));
  }

  Future<void> _deletePlace() async {
    final lbl = AppLocalizations.of(context)!;
    final repo = ref.read(placeRepositoryProvider);
    if (repo == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lbl.buttonDelete),
        content: Text(lbl.deletePlaceConfirm(_place.name)),
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

    await repo.delete(_place.id);
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
              Icons.place,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(_place.name)),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final res = await showDialog(
                context: context,
                builder: (_) => PlaceFormDialog(initial: _place),
              );
              if (res is PlaceModel) setState(() => _place = res);
            },
            tooltip: lbl.buttonEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deletePlace,
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
                        selected: _place.figureIds.contains(figure.id),
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
