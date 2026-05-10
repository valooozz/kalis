import 'package:flutter/material.dart';
import '../models/figure_model.dart';

class FigureSquareCard extends StatelessWidget {
  final FigureModel figure;
  final bool isDone;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FigureSquareCard({
    super.key,
    required this.figure,
    required this.onTap,
    required this.onLongPress,
    this.isDone = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final figureColor = figure.color.color;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: figureColor, width: 10)),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    figure.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isDone)
                  Center(
                    child: Icon(
                      Icons.done_outline,
                      color: figureColor.withValues(alpha: 0.5),
                      size: 70,
                    ),
                  ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Icon(figure.state.icon, size: 20, color: figureColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
