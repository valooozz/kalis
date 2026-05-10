// lib/widgets/color_filter_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import '../models/figure_model.dart';
import '../providers/filter_providers.dart';

class ColorFilterDialog extends ConsumerWidget {
  const ColorFilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = ref.watch(colorFilterProvider);
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(lbl.filterByColor),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          // Bouton "Toutes"
          GestureDetector(
            onTap: () {
              ref.read(colorFilterProvider.notifier).state = null;
              Navigator.of(context).pop();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: selectedColor == null
                    ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                    : Border.all(color: Colors.transparent, width: 3),
              ),
              child: Icon(
                Icons.palette,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Un cercle par couleur
          ...FigureColor.values.map((figureColor) {
            final isSelected = selectedColor == figureColor;
            return GestureDetector(
              onTap: () {
                ref.read(colorFilterProvider.notifier).state = isSelected
                    ? null
                    : figureColor;
                Navigator.of(context).pop();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: figureColor.color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                      : Border.all(color: Colors.transparent, width: 3),
                ),
              ),
            );
          }),
        ],
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
