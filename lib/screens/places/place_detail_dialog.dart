import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/place_model.dart';
import 'package:kalis/models/figure_model.dart';
import 'package:kalis/providers/place_providers.dart';
import 'package:kalis/providers/core_providers.dart';
import 'package:kalis/providers/figure_providers.dart';
import 'place_form_dialog.dart';

class PlaceDetailDialog extends ConsumerStatefulWidget {
  final PlaceModel place;
  const PlaceDetailDialog({required this.place, super.key});

  @override
  ConsumerState<PlaceDetailDialog> createState() => _PlaceDetailDialogState();
}

class _PlaceDetailDialogState extends ConsumerState<PlaceDetailDialog> {
  late PlaceModel _place;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
  }

  Future<void> _updatePlace(PlaceModel p) async {
    final repo = ref.read(placeRepositoryProvider);
    if (repo == null) return;
    setState(() => _loading = true);
    await repo.update(p);
    setState(() {
      _place = p;
      _loading = false;
    });
  }

  Future<void> _deletePlace() async {
    final repo = ref.read(placeRepositoryProvider);
    if (repo == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.buttonDelete),
            content: Text(AppLocalizations.of(context)!.deletePlaceConfirm(_place.name)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocalizations.of(context)!.buttonCancel)),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocalizations.of(context)!.buttonDelete)),
            ],
          ),
        ) ?? false;
    if (!confirmed) return;
    await repo.delete(_place.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    final figuresAsync = ref.watch(figuresProvider);

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(_place.name)),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final res = await showDialog(context: context, builder: (_) => PlaceFormDialog(initial: _place));
              if (res is PlaceModel) {
                setState(() => _place = res);
              }
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
      content: figuresAsync.when(
        loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Erreur : $e'),
        data: (figures) {
          if (figures.isEmpty) return Text(lbl.noFigureAvailable);
          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: figures.length,
              itemBuilder: (context, index) {
                final f = figures[index];
                final checked = _place.figureIds.contains(f.id);
                return CheckboxListTile(
                  value: checked,
                  title: Text(f.name),
                  onChanged: (v) async {
                    final updatedIds = List<String>.from(_place.figureIds);
                    if (v == true) {
                      if (!updatedIds.contains(f.id)) updatedIds.add(f.id);
                    } else {
                      updatedIds.remove(f.id);
                    }
                    final updated = _place.copyWith(figureIds: updatedIds);
                    await _updatePlace(updated);
                  },
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(lbl.buttonClose)),
      ],
    );
  }
}
