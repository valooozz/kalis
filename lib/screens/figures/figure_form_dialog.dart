import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/screens/figures/record_form_dialog.dart';
import 'package:kalis/widgets/record_display.dart';
import '../../models/figure_model.dart';
import '../../providers/core_providers.dart';
import '../../widgets/color_picker_row.dart';
import '../../core/utils/date_utils.dart';

class FigureFormDialog extends ConsumerStatefulWidget {
  final FigureModel? figure;

  const FigureFormDialog({super.key, this.figure});

  @override
  ConsumerState<FigureFormDialog> createState() => _FigureFormDialogState();
}

class _FigureFormDialogState extends ConsumerState<FigureFormDialog> {
  late TextEditingController _nameController;
  late FigureColor _selectedColor;
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isEditing => widget.figure != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.figure?.name ?? '');
    _selectedColor = widget.figure?.color ?? FigureColor.blue;
    _startDate = widget.figure?.startDate;
    _endDate = widget.figure?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(_isEditing ? lbl.editFigure : lbl.newFigure),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: lbl.fieldName,
                hintText: lbl.fieldNameHint,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            // Couleur
            Text(lbl.fieldColor, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            ColorPickerRow(
              selected: _selectedColor,
              onChanged: (color) => setState(() => _selectedColor = color),
            ),
            // Dates, record, et suppression (uniquement en mode édition)
            if (_isEditing) ...[
              const SizedBox(height: 24),
              _DatePicker(
                label: lbl.fieldStartDate,
                date: _startDate,
                onChanged: (date) => setState(() => _startDate = date),
                onCleared: () => setState(() => _startDate = null),
              ),
              const SizedBox(height: 12),
              _DatePicker(
                label: lbl.fieldMasteryDate,
                date: _endDate,
                onChanged: (date) => setState(() => _endDate = date),
                onCleared: () => setState(() => _endDate = null),
              ),
              if (_isEditing &&
                  widget.figure!.state == FigureState.learned) ...[
                const SizedBox(height: 12),
                _RecordRow(
                  figure: widget.figure!,
                  onEdit: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (_) => RecordFormDialog(figure: widget.figure!),
                    );
                  },
                  onDelete: () async {
                    Navigator.of(context).pop();
                    final repository = ref.read(figureRepositoryProvider);
                    await repository?.update(
                      widget.figure!.copyWith(clearRecord: true),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: () => _delete(lbl),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(lbl.deleteFigure),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lbl.buttonCancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? lbl.buttonSave : lbl.buttonAdd),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final repository = ref.read(figureRepositoryProvider);
    if (repository == null) return;

    if (_isEditing) {
      final updated = widget.figure!.copyWith(
        name: name,
        color: _selectedColor,
        startDate: _startDate,
        endDate: _endDate,
        clearStartDate: _startDate == null,
        clearEndDate: _endDate == null,
      );
      await repository.update(updated);
    } else {
      final figure = FigureModel(
        id: '',
        name: name,
        color: _selectedColor,
        state: FigureState.toLearn,
      );
      await repository.create(figure);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(AppLocalizations lbl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lbl.deleteFigure),
        content: Text(lbl.deleteFigureConfirm(widget.figure!.name)),
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

    final repository = ref.read(figureRepositoryProvider);
    if (repository == null) return;

    await repository.delete(widget.figure!.id);

    if (mounted) Navigator.of(context).pop();
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onCleared;

  const _DatePicker({
    required this.label,
    required this.date,
    required this.onChanged,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            date != null ? '$label : ${date!.toShortDate()}' : '$label : —',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today, size: 20),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onChanged(picked);
          },
        ),
        if (date != null)
          IconButton(
            icon: Icon(Icons.clear, size: 20, color: theme.colorScheme.error),
            onPressed: onCleared,
          ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  final FigureModel figure;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordRow({
    required this.figure,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: figure.recordValue != null
              ? RecordDisplay(figure: figure)
              : Text(lbl.noRecord, style: theme.textTheme.bodyMedium),
        ),
        IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
        if (figure.recordValue != null)
          IconButton(
            icon: Icon(Icons.clear, size: 20, color: theme.colorScheme.error),
            onPressed: onDelete,
          ),
      ],
    );
  }
}
