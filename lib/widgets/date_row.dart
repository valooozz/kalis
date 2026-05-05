import 'package:flutter/material.dart';
import 'package:kalis/core/utils/date_utils.dart';
import 'package:kalis/l10n/app_localizations.dart';

class DateRow extends StatelessWidget {
  final IconData icon;
  final DateTime? date;
  final String label;
  final DateTime? referenceDate;
  final bool isAlert;
  final bool isMediumSize;

  const DateRow({
    super.key,
    required this.icon,
    required this.date,
    required this.label,
    this.referenceDate,
    this.isAlert = false,
    this.isMediumSize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;
    final dateText = date != null
        ? date!.toRelativeLabel(lbl, reference: referenceDate)
        : '—';
    final color = isAlert ? theme.colorScheme.error : theme.colorScheme.outline;

    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          '$label : $dateText',
          style: isMediumSize
              ? theme.textTheme.bodyMedium?.copyWith(color: color)
              : theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
