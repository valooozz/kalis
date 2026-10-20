import 'package:flutter/material.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/providers/renfo_providers.dart';
import 'package:kalis/widgets/date_row.dart';

class RenfoTodayCard extends StatelessWidget {
  final RenfoTodayItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const RenfoTodayCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;

    final done = item.doneToday;
    final doneColor = Colors.green.shade700;
    // Bande latérale : vert si fait, rouge si en alerte, sinon couleur neutre
    final accentColor = done
        ? doneColor
        : item.isAlert
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accentColor, width: 10)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.renfo.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DateRow(
                      icon: Icons.history,
                      date: item.lastDone,
                      label: lbl.lastTraining,
                      isAlert: !done && item.isAlert,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? doneColor : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
