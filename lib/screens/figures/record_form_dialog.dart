import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import '../../models/figure_model.dart';
import '../../providers/core_providers.dart';

class RecordFormDialog extends ConsumerStatefulWidget {
  final FigureModel figure;

  const RecordFormDialog({super.key, required this.figure});

  @override
  ConsumerState<RecordFormDialog> createState() => _RecordFormDialogState();
}

class _RecordFormDialogState extends ConsumerState<RecordFormDialog> {
  late TextEditingController _valueController;
  late RecordUnit _selectedUnit;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.figure.recordValue?.toString() ?? '',
    );
    _selectedUnit = widget.figure.recordUnit ?? RecordUnit.reps;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(lbl.recordDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: InputDecoration(labelText: lbl.recordValue),
          ),
          const SizedBox(height: 16),
          Text(lbl.recordUnit, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: Text(lbl.recordUnitReps),
                selected: _selectedUnit == RecordUnit.reps,
                onSelected: (_) =>
                    setState(() => _selectedUnit = RecordUnit.reps),
                showCheckmark: false,
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(lbl.recordUnitSeconds),
                selected: _selectedUnit == RecordUnit.seconds,
                onSelected: (_) =>
                    setState(() => _selectedUnit = RecordUnit.seconds),
                showCheckmark: false,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lbl.buttonCancel),
        ),
        FilledButton(onPressed: _save, child: Text(lbl.buttonSave)),
      ],
    );
  }

  Future<void> _save() async {
    final value = int.tryParse(_valueController.text.trim());
    if (value == null) return;

    final repository = ref.read(figureRepositoryProvider);
    if (repository == null) return;

    await repository.update(
      widget.figure.copyWith(recordValue: value, recordUnit: _selectedUnit),
    );

    if (mounted) Navigator.of(context).pop();
  }
}
