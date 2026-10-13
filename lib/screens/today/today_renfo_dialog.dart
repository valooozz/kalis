import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/renfo_done_model.dart';
import 'package:kalis/providers/core_providers.dart';
import 'package:kalis/providers/renfo_providers.dart';
import 'package:kalis/providers/today_providers.dart';
import 'package:kalis/widgets/date_row.dart';

class TodayRenfoDialog extends ConsumerWidget {
  const TodayRenfoDialog({super.key});

  Future<void> _toggle(WidgetRef ref, RenfoTodayItem item) async {
    final repo = ref.read(renfoDoneRepositoryProvider);
    if (repo == null) return;
    final today = ref.read(todayProvider);
    if (item.doneToday) {
      await repo.remove(item.renfo.id, today);
    } else {
      await repo.add(RenfoDoneModel(renfoId: item.renfo.id, date: today));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;
    final items = ref.watch(todayRenfoItemsProvider);

    return AlertDialog(
      title: Text(lbl.renfoSessionTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? Text(
                lbl.noRenfoToday,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final color = item.isAlert
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _toggle(ref, item),
                    leading: Icon(
                      item.doneToday
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: item.doneToday
                          ? Colors.green.shade700
                          : theme.colorScheme.outline,
                    ),
                    title: Text(
                      item.renfo.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    subtitle: DateRow(
                      icon: Icons.history,
                      date: item.lastDone,
                      label: lbl.lastTraining,
                      isAlert: item.isAlert,
                    ),
                  );
                },
              ),
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
