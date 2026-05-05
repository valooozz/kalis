import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/providers/figure_providers.dart';
import 'package:kalis/providers/planning_providers.dart';
import 'package:kalis/widgets/date_row.dart';
import '../../models/figure_model.dart';

class TrainingDatesDialog extends ConsumerWidget {
  final FigureModel figure;
  final DateTime date;

  const TrainingDatesDialog({
    super.key,
    required this.figure,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbl = AppLocalizations.of(context)!;

    final AsyncValue lastDateAsync = ref.watch(
      effectiveLastTrainingDateProvider((figureId: figure.id, date: date)),
    );

    final AsyncValue nextDateAsync = ref.watch(
      nextTrainingDateAfterDayProvider((figureId: figure.id, date: date)),
    );

    return AlertDialog(
      title: Text(figure.name),
      content: lastDateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (lastDate) {
          return nextDateAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur : $e'),
            data: (nextDate) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DateRow(
                    icon: Icons.history,
                    date: lastDate,
                    label: lbl.previousTraining,
                    referenceDate: date,
                    isMediumSize: true,
                  ),
                  const SizedBox(height: 2),
                  DateRow(
                    icon: Icons.event,
                    date: nextDate,
                    label: lbl.followingTraining,
                    referenceDate: date,
                    isMediumSize: true,
                  ),
                ],
              );
            },
          );
        },
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
