import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/figure_model.dart';
import '../providers/figure_providers.dart';
import '../core/utils/date_utils.dart';

class FigureCard extends ConsumerWidget {
  final FigureModel figure;
  final VoidCallback onTap;

  const FigureCard({super.key, required this.figure, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastDateAsync = ref.watch(lastTrainingDateProvider(figure.id));
    final nextDateAsync = ref.watch(nextTrainingDateProvider(figure.id));
    final theme = Theme.of(context);
    final figureColor = figure.color.color;

    // Si le dernier entraînement est aujourd'hui, on ignore
    // la première occurrence de TrainingPlanned (qui est aujourd'hui)
    // et on prend la suivante
    final lastDate = lastDateAsync.valueOrNull;
    final nextDate = nextDateAsync.valueOrNull;
    final lastIsToday = lastDate != null && lastDate.isToday;
    final displayedNextDate =
        lastIsToday && nextDate != null && nextDate.isToday
        ? ref.watch(nextTrainingDateAfterTodayProvider(figure.id)).valueOrNull
        : nextDate;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: figureColor, width: 10)),
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
                      ),
                    ),
                    if (figure.state != FigureState.toLearn) ...[
                      const SizedBox(height: 4),
                      _DateRow(
                        icon: Icons.history,
                        date: lastDateAsync.valueOrNull,
                        label: 'Dernier',
                      ),
                      const SizedBox(height: 2),
                      _DateRow(
                        icon: Icons.event,
                        date: displayedNextDate,
                        label: 'Prochain',
                      ),
                    ],
                  ],
                ),
              ),
              _StateIcon(state: figure.state, color: figure.color.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final DateTime? date;
  final String label;

  const _DateRow({required this.icon, required this.date, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = date != null ? date!.toRelativeLabel() : '—';

    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          '$label : $dateText',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
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
