import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/renfo_model.dart';
import 'package:kalis/providers/core_providers.dart';
import 'package:kalis/providers/renfo_providers.dart';

class RenfoFormDialog extends ConsumerStatefulWidget {
  final RenfoModel? initial;
  const RenfoFormDialog({this.initial, super.key});

  @override
  ConsumerState<RenfoFormDialog> createState() => _RenfoFormDialogState();
}

class _RenfoFormDialogState extends ConsumerState<RenfoFormDialog> {
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
      title: Text(widget.initial == null ? lbl.newRenfo : lbl.editRenfo),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: lbl.fieldRenfoName,
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
                  final repo = ref.read(renfoRepositoryProvider);
                  if (repo == null) return;
                  setState(() => _saving = true);
                  final name = _controller.text.trim();
                  if (name.isEmpty) {
                    setState(() => _saving = false);
                    return;
                  }

                  final renfos = ref.read(renfosProvider).valueOrNull ?? [];
                  final exists = renfos.any(
                    (r) =>
                        r.name.toLowerCase() == name.toLowerCase() &&
                        (widget.initial == null || r.id != widget.initial!.id),
                  );
                  if (exists) {
                    setState(() {
                      _saving = false;
                      _errorText = lbl.renfoAlreadyExistError;
                    });
                    return;
                  }

                  if (widget.initial == null) {
                    final created = await repo.create(
                      RenfoModel(id: '', name: name),
                    );
                    if (context.mounted) Navigator.of(context).pop(created);
                  } else {
                    final updated = widget.initial!.copyWith(name: name);
                    await repo.update(updated);
                    if (context.mounted) Navigator.of(context).pop(updated);
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
