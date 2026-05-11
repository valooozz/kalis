import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/providers/planning_providers.dart';
import 'package:kalis/providers/today_providers.dart';
import 'package:kalis/widgets/date_row.dart';
import '../models/figure_model.dart';
import '../providers/figure_providers.dart';
import '../core/utils/date_utils.dart';

class FigureCard extends ConsumerWidget {
  final FigureModel figure;
  final VoidCallback onTap;
  final DateTime? referenceDate;
  final bool inkEffect;

  const FigureCard({
    super.key,
    required this.figure,
    required this.onTap,
    this.referenceDate,
    this.inkEffect = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;
    final figureColor = figure.color.color;

    // Si une date de référence est fournie, on utilise les providers adaptés
    final DateTime? lastDate;
    final DateTime? displayedNextDate;

    if (referenceDate != null) {
      lastDate = ref
          .watch(
            effectiveLastTrainingDateProvider((
              figureId: figure.id,
              date: referenceDate!,
            )),
          )
          .valueOrNull;
      displayedNextDate = ref
          .watch(
            nextTrainingDateAfterDayProvider((
              figureId: figure.id,
              date: referenceDate!,
            )),
          )
          .valueOrNull;
    } else {
      final lastDateAsync = ref.watch(lastTrainingDateProvider(figure.id));
      final nextDateAsync = ref.watch(nextTrainingDateProvider(figure.id));
      final lastDateValue = lastDateAsync.valueOrNull;
      final nextDate = nextDateAsync.valueOrNull;
      final lastIsToday = lastDateValue != null && lastDateValue.isToday;
      lastDate = lastDateValue;
      displayedNextDate = lastIsToday && nextDate != null && nextDate.isToday
          ? ref.watch(nextTrainingDateAfterTodayProvider(figure.id)).valueOrNull
          : nextDate;
    }

    // Calcul de l'alerte sur le dernier entraînement
    final bool lastDateAlert;
    if (lastDate == null || displayedNextDate != null) {
      lastDateAlert = false;
    } else {
      final today = ref.read(todayProvider);
      final referenceDateForDateAlert = referenceDate ?? today;
      final daysSinceLast = referenceDateForDateAlert
          .difference(lastDate.dateOnly)
          .inDays;
      lastDateAlert = figure.state == FigureState.learning
          ? daysSinceLast >= 4
          : daysSinceLast >= 15;
    }

    final alphaValue = figure.paused ? 0.5 : 1.0;
    final cardColor = figure.paused
        ? figureColor.withValues(alpha: alphaValue)
        : figureColor;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: inkEffect ? null : Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: cardColor, width: 10)),
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
                      figure.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: alphaValue,
                        ),
                      ),
                    ),
                    if (figure.state != FigureState.toLearn &&
                        !figure.paused) ...[
                      const SizedBox(height: 4),
                      DateRow(
                        icon: Icons.history,
                        date: lastDate,
                        label: lbl.lastTraining,
                        referenceDate: referenceDate,
                        isAlert: lastDateAlert,
                      ),
                      const SizedBox(height: 2),
                      DateRow(
                        icon: Icons.event,
                        date: displayedNextDate,
                        label: lbl.nextTraining,
                        referenceDate: referenceDate,
                      ),
                    ],
                  ],
                ),
              ),
              _StateIcon(state: figure.state, color: cardColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateIcon extends StatelessWidget {
  final FigureState state;
  final Color color;

  const _StateIcon({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(state.icon, color: color);
  }
}
