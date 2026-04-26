import 'package:flutter/material.dart';
import 'package:kalis/l10n/app_localizations.dart';

extension AppDateUtils on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  DateTime get dateOnly => DateTime(year, month, day);

  bool get isToday {
    final now = DateTime.now();
    return isSameDay(now);
  }

  bool get isPast {
    final now = DateTime.now().dateOnly;
    return dateOnly.isBefore(now);
  }

  // Formate la date en "lun. 15 jan."
  String toShortLabel(Locale locale) {
    final weekdays = {
      1: 'lun.',
      2: 'mar.',
      3: 'mer.',
      4: 'jeu.',
      5: 'ven.',
      6: 'sam.',
      7: 'dim.',
    };
    final months = {
      1: 'jan.',
      2: 'fév.',
      3: 'mar.',
      4: 'avr.',
      5: 'mai',
      6: 'juin',
      7: 'juil.',
      8: 'août',
      9: 'sep.',
      10: 'oct.',
      11: 'nov.',
      12: 'déc.',
    };
    return '${weekdays[weekday]} $day ${months[month]}';
  }

  // Formate la date en "15/01/2024"
  String toShortDate() {
    return '${day.toString().padLeft(2, '0')}/'
        '${month.toString().padLeft(2, '0')}/'
        '$year';
  }

  int daysFrom(DateTime reference) {
    final ref = reference.dateOnly;
    return dateOnly.difference(ref).inDays;
  }

  String toRelativeLabel(AppLocalizations lbl, {DateTime? reference}) {
    final days = daysFrom(reference ?? DateTime.now());
    final referenceIsToday = reference == null;
    if (days == 0) return lbl.today;
    if (days == 1) return referenceIsToday ? lbl.tomorrow : lbl.dayAfter;
    if (days == -1) return referenceIsToday ? lbl.yesterday : lbl.dayBefore;
    if (days > 0) {
      return referenceIsToday ? lbl.inDays(days) : lbl.daysAfter(days);
    }
    return referenceIsToday
        ? lbl.daysAgo(days.abs())
        : lbl.daysBefore(days.abs());
  }
}
