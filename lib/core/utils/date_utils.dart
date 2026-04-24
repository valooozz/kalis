import 'package:flutter/material.dart';

extension AppDateUtils on DateTime {
  // Vérifie si deux dates sont le même jour
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  // Retourne une DateTime sans l'heure
  DateTime get dateOnly => DateTime(year, month, day);

  // Vérifie si la date est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return isSameDay(now);
  }

  // Vérifie si la date est dans le passé (hors aujourd'hui)
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
      1: 'jan.', 2: 'fév.', 3: 'mar.', 4: 'avr.',
      5: 'mai', 6: 'juin', 7: 'juil.', 8: 'août',
      9: 'sep.', 10: 'oct.', 11: 'nov.', 12: 'déc.',
    };
    return '${weekdays[weekday]} $day ${months[month]}';
  }

  // Formate la date en "15/01/2024"
  String toShortDate() {
    return '${day.toString().padLeft(2, '0')}/'
        '${month.toString().padLeft(2, '0')}/'
        '$year';
  }
}