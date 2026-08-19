import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/place_model.dart';
import 'package:kalis/providers/core_providers.dart';
import 'package:kalis/providers/place_providers.dart';

class PlaceFormDialog extends ConsumerStatefulWidget {
  final PlaceModel? initial;
  const PlaceFormDialog({this.initial, super.key});

  @override
  ConsumerState<PlaceFormDialog> createState() => _PlaceFormDialogState();
}

class _PlaceFormDialogState extends ConsumerState<PlaceFormDialog> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initial?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.initial == null ? lbl.newPlace : lbl.editPlace),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: lbl.fieldPlaceName,
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lbl.buttonCancel),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  final repo = ref.read(placeRepositoryProvider);
                  if (repo == null) return;
                  setState(() => _saving = true);
                  final name = _controller.text.trim();
                  if (name.isEmpty) {
                    setState(() => _saving = false);
                    return;
                  }

                  // Check for duplicate name among existing places
                  final places = ref.read(placesProvider).valueOrNull ?? [];
                  final exists = places.any(
                    (p) =>
                        p.name.toLowerCase() == name.toLowerCase() &&
                        (widget.initial == null || p.id != widget.initial!.id),
                  );
                  if (exists) {
                    setState(() {
                      _saving = false;
                      _errorText = lbl.placeAlreadyExistError;
                    });
                    return;
                  }

                  if (widget.initial == null) {
                    final created = await repo.create(
                      PlaceModel(id: '', name: name),
                    );
                    Navigator.of(context).pop(created);
                  } else {
                    final updated = widget.initial!.copyWith(name: name);
                    await repo.update(updated);
                    Navigator.of(context).pop(updated);
                  }
                },
          child: Text(lbl.buttonSave),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
