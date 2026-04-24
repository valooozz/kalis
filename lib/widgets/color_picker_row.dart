// lib/widgets/color_picker_row.dart

import 'package:flutter/material.dart';
import '../models/figure_model.dart';

class ColorPickerRow extends StatelessWidget {
  final FigureColor selected;
  final ValueChanged<FigureColor> onChanged;

  const ColorPickerRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: FigureColor.values.map((figureColor) {
        final isSelected = figureColor == selected;
        return GestureDetector(
          onTap: () => onChanged(figureColor),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: figureColor.color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: figureColor.color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}