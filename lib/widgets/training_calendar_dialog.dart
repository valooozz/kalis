import 'package:flutter/material.dart';
import 'package:kalis/core/utils/date_utils.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

class TrainingCalendarDialog extends StatefulWidget {
  final String title;
  final Color color;
  final Set<DateTime> doneDates;
  final Set<DateTime> plannedDates;

  const TrainingCalendarDialog({
    super.key,
    required this.title,
    required this.color,
    required this.doneDates,
    required this.plannedDates,
  });

  @override
  State<TrainingCalendarDialog> createState() => _TrainingCalendarDialogState();
}

class _TrainingCalendarDialogState extends State<TrainingCalendarDialog> {
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
    final doneDates = widget.doneDates;
    final plannedDates = widget.plannedDates;
    final calendarColor = widget.color;

    final firstOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final trainingDaysInMonth = {
      ...doneDates,
      ...plannedDates,
    }.where((d) => !d.isBefore(firstOfMonth) && !d.isAfter(lastOfMonth)).length;

    return AlertDialog(
      title: Text(widget.title),
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
                  todayDecoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.primary),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: theme.colorScheme.primary),
                  defaultTextStyle: theme.textTheme.bodySmall!,
                  weekendTextStyle: theme.textTheme.bodySmall!,
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final dateOnly = day.dateOnly;
                    final isDone = doneDates.contains(dateOnly);
                    final isPlanned = plannedDates.contains(dateOnly);

                    if (!isDone && !isPlanned) return null;

                    return _CalendarDay(
                      day: day,
                      color: isDone
                          ? calendarColor
                          : calendarColor.withValues(alpha: 0.35),
                      textColor: isDone
                          ? _contrastColor(calendarColor)
                          : theme.colorScheme.onSurface,
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final dateOnly = day.dateOnly;
                    final isDone = doneDates.contains(dateOnly);
                    final isPlanned = plannedDates.contains(dateOnly);

                    if (isDone || isPlanned) {
                      return _CalendarDay(
                        day: day,
                        color: isDone
                            ? calendarColor
                            : calendarColor.withValues(alpha: 0.35),
                        textColor: isDone
                            ? _contrastColor(calendarColor)
                            : theme.colorScheme.onSurface,
                        isToday: true,
                      );
                    }

                    return _CalendarDay(
                      day: day,
                      color: Colors.transparent,
                      textColor: theme.colorScheme.primary,
                      isToday: true,
                      borderColor: theme.colorScheme.primary,
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
        Row(
          children: [
            _LegendDot(color: calendarColor),
            const SizedBox(width: 4),
            Text(lbl.calendarLegendDone, style: theme.textTheme.bodySmall),
            const SizedBox(width: 12),
            _LegendDot(color: calendarColor.withValues(alpha: 0.35)),
            const SizedBox(width: 4),
            Text(lbl.calendarLegendPlanned, style: theme.textTheme.bodySmall),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(lbl.buttonClose),
            ),
          ],
        ),
      ],
    );
  }

  Color _contrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime day;
  final Color color;
  final Color textColor;
  final bool isToday;
  final Color? borderColor;

  const _CalendarDay({
    required this.day,
    required this.color,
    required this.textColor,
    this.isToday = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
