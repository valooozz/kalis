import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/core/utils/date_utils.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/providers/figure_providers.dart';
import 'package:table_calendar/table_calendar.dart';

class GlobalCalendarDialog extends ConsumerStatefulWidget {
  const GlobalCalendarDialog({super.key});

  @override
  ConsumerState<GlobalCalendarDialog> createState() =>
      _GlobalCalendarDialogState();
}

class _GlobalCalendarDialogState extends ConsumerState<GlobalCalendarDialog> {
  late DateTime _focusedDay;
  final DateTime _firstDay = DateTime(2026);
  late DateTime _lastDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    final now = DateTime.now();
    _lastDay = DateTime(now.year, now.month, now.day + 13);
  }

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final doneDatesAsync = ref.watch(allTrainingDoneDatesProvider);
    final plannedDatesAsync = ref.watch(allTrainingPlannedDatesProvider);

    final doneDates = doneDatesAsync.valueOrNull ?? {};
    final plannedDates = plannedDatesAsync.valueOrNull ?? {};

    // Calcul des entraînements du mois affiché
    final firstOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final allDaysInMonth = {
      ...doneDates.keys,
      ...plannedDates.keys,
    }.where((d) => !d.isBefore(firstOfMonth) && !d.isAfter(lastOfMonth));

    final trainingDaysInMonth = allDaysInMonth.fold<int>(0, (sum, day) {
      final doneCount = doneDates[day]?.length ?? 0;
      final plannedColors = List<Color>.from(plannedDates[day] ?? []);
      for (final c in doneDates[day] ?? []) {
        plannedColors.remove(c);
      }
      return sum + doneCount + plannedColors.length;
    });

    return AlertDialog(
      title: Text(lbl.globalCalendarTitle),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 440,
        child: Column(
          children: [
            Expanded(
              child: TableCalendar(
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: _focusedDay,
                locale: lbl.localeName,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: theme.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: theme.textTheme.bodySmall!,
                  weekendStyle: theme.textTheme.bodySmall!,
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: const BoxDecoration(shape: BoxShape.circle),
                  todayTextStyle: theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  defaultTextStyle: theme.textTheme.bodySmall!,
                  weekendTextStyle: theme.textTheme.bodySmall!,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final dateOnly = day.dateOnly;
                    final doneColors = doneDates[dateOnly] ?? [];
                    final plannedColors = plannedDates[dateOnly] ?? [];

                    // On construit une liste de (color, isDone)
                    // Une figure done ne doit pas apparaître aussi en planned
                    final allDots = <(Color, bool)>[];
                    for (final c in doneColors) {
                      allDots.add((c, true));
                    }
                    // Pour planned, on retire les figures déjà comptées en done
                    final remainingPlanned = List<Color>.from(plannedColors);
                    for (final c in doneColors) {
                      remainingPlanned.remove(c);
                    }
                    for (final c in remainingPlanned) {
                      allDots.add((c, false));
                    }

                    if (allDots.isEmpty) return null;

                    return Positioned(
                      bottom: 2,
                      child: _DotsGrid(dots: allDots),
                    );
                  },
                ),
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                lbl.calendarMonthCount(trainingDaysInMonth),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
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

class _DotsGrid extends StatelessWidget {
  final List<(Color, bool)> dots; // (color, isDone)
  static const int _maxPerRow = 5;
  static const double _dotSize = 5;
  static const double _dotSpacing = 1.5;

  const _DotsGrid({required this.dots});

  @override
  Widget build(BuildContext context) {
    // Découpage en lignes de 5 max
    final rows = <List<(Color, bool)>>[];
    for (var i = 0; i < dots.length; i += _maxPerRow) {
      rows.add(
        dots.sublist(
          i,
          i + _maxPerRow > dots.length ? dots.length : i + _maxPerRow,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: row.map((dot) {
            final (color, isDone) = dot;
            return Container(
              width: _dotSize,
              height: _dotSize,
              margin: EdgeInsets.all(_dotSpacing / 2),
              decoration: BoxDecoration(
                color: isDone ? color : color.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
