import 'package:flutter/material.dart';
import 'package:kalis/l10n/app_localizations.dart';
import '../models/figure_model.dart';

class RecordDisplay extends StatelessWidget {
  final FigureModel figure;

  const RecordDisplay({super.key, required this.figure});

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (figure.recordValue == null || figure.recordUnit == null) {
      return const SizedBox.shrink();
    }

    final unit = figure.recordUnit!.unit;

    return Row(
      children: [
        Icon(Icons.emoji_events, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '${lbl.record} : ${figure.recordValue} $unit',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
