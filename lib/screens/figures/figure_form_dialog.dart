import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _nameController =
        TextEditingController(text: widget.figure?.name ?? '');
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

    return AlertDialog(
      title: Text(_isEditing ? 'Modifier la figure' : 'Nouvelle figure'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Ex: Muscle-up',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 24),
            // Couleur
            Text('Couleur', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            ColorPickerRow(
              selected: _selectedColor,
              onChanged: (color) => setState(() => _selectedColor = color),
            ),
            // Dates (uniquement en mode édition)
            if (_isEditing) ...[
              const SizedBox(height: 24),
              _DatePicker(
                label: 'Date de début',
                date: _startDate,
                onChanged: (date) => setState(() => _startDate = date),
                onCleared: () => setState(() => _startDate = null),
              ),
              const SizedBox(height: 12),
              _DatePicker(
                label: 'Date de maîtrise',
                date: _endDate,
                onChanged: (date) => setState(() => _endDate = date),
                onCleared: () => setState(() => _endDate = null),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Enregistrer' : 'Ajouter'),
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
            date != null
                ? '$label : ${date!.toShortDate()}'
                : '$label : —',
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