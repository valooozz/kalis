import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/models/renfo_model.dart';
import 'package:kalis/providers/renfo_providers.dart';
import 'package:kalis/widgets/training_calendar_dialog.dart';

class RenfoCalendarDialog extends ConsumerWidget {
  final RenfoModel renfo;

  const RenfoCalendarDialog({super.key, required this.renfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doneDatesAsync = ref.watch(renfoDoneDatesProvider(renfo.id));

    return TrainingCalendarDialog(
      title: renfo.name,
      color: Theme.of(context).colorScheme.primary,
      doneDates: doneDatesAsync.valueOrNull ?? {},
      plannedDates: const {},
    );
  }
}
