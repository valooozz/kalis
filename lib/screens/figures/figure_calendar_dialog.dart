import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/models/figure_model.dart';
import 'package:kalis/providers/figure_providers.dart';
import 'package:kalis/widgets/training_calendar_dialog.dart';

class FigureCalendarDialog extends ConsumerWidget {
  final FigureModel figure;

  const FigureCalendarDialog({super.key, required this.figure});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doneDates = ref.watch(trainingDoneDatesProvider(figure.id));
    final plannedDates = ref.watch(trainingPlannedDatesProvider(figure.id));

    return TrainingCalendarDialog(
      title: figure.name,
      color: figure.color.color,
      doneDates: doneDates.valueOrNull ?? {},
      plannedDates: plannedDates.valueOrNull ?? {},
    );
  }
}
