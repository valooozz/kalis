import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/renfo_done_model.dart';
import 'package:kalis/providers/core_providers.dart';
import 'package:kalis/providers/renfo_providers.dart';
import 'package:kalis/providers/today_providers.dart';
import 'package:kalis/widgets/renfo_today_card.dart';

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.fitness_center,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(lbl.renfoSessionTitle)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? Text(
                lbl.noRenfoToday,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => RenfoTodayCard(
                  item: items[index],
                  onTap: () => _toggle(ref, items[index]),
                ),
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
