import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/core/utils/date_utils.dart';
import '../models/renfo_model.dart';
import '../models/renfo_done_model.dart';
import 'core_providers.dart';
import 'today_providers.dart';

/// Seuil (en jours) à partir duquel un renfo est affiché en rouge.
const renfoAlertDays = 4;

final renfosProvider = StreamProvider<List<RenfoModel>>((ref) {
  final repository = ref.watch(renfoRepositoryProvider);
  if (repository == null) return const Stream.empty();
  return repository.watchAll().map((renfos) {
    final sorted = List<RenfoModel>.from(renfos);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  });
});

final renfoDoneAllProvider = StreamProvider<List<RenfoDoneModel>>((ref) {
  final repository = ref.watch(renfoDoneRepositoryProvider);
  if (repository == null) return const Stream.empty();
  return repository.watchAll();
});

/// Dernière date de travail (manuel) pour chaque renfo.
final renfoLastDoneDatesProvider = Provider<Map<String, DateTime>>((ref) {
  final done = ref.watch(renfoDoneAllProvider).valueOrNull ?? [];
  final result = <String, DateTime>{};
  for (final d in done) {
    final date = d.date.dateOnly;
    final current = result[d.renfoId];
    if (current == null || date.isAfter(current)) result[d.renfoId] = date;
  }
  return result;
});

/// État d'un renfo pour la séance du jour.
class RenfoTodayItem {
  final RenfoModel renfo;
  final DateTime? lastDone;
  final int? daysSince; // null = jamais travaillé
  final bool doneToday;

  const RenfoTodayItem({
    required this.renfo,
    required this.lastDone,
    required this.daysSince,
    required this.doneToday,
  });

  /// Jamais travaillé = considéré comme infini, donc en alerte.
  bool get isAlert => daysSince == null || daysSince! >= renfoAlertDays;
}

/// Renfos pouvant être effectués aujourd'hui (aucune figure liée planifiée
/// aujourd'hui), triés par nombre de jours décroissant.
final todayRenfoItemsProvider = Provider<List<RenfoTodayItem>>((ref) {
  final renfos = ref.watch(renfosProvider).valueOrNull ?? [];
  final planned = ref.watch(todayPlannedProvider).valueOrNull ?? [];
  final lastDates = ref.watch(renfoLastDoneDatesProvider);
  final today = ref.watch(todayProvider);

  final plannedIds = planned.map((t) => t.figureId).toSet();

  final items = <RenfoTodayItem>[];
  for (final renfo in renfos) {
    if (renfo.figureIds.any(plannedIds.contains)) continue;
    final lastDone = lastDates[renfo.id];
    final days = lastDone == null ? null : today.difference(lastDone).inDays;
    items.add(
      RenfoTodayItem(
        renfo: renfo,
        lastDone: lastDone,
        daysSince: days,
        doneToday: days == 0,
      ),
    );
  }

  items.sort((a, b) {
    final da = a.daysSince;
    final db = b.daysSince;
    if (da == null && db != null) return -1;
    if (da != null && db == null) return 1;
    if (da != null && db != null && da != db) return db.compareTo(da);
    return a.renfo.name.compareTo(b.renfo.name);
  });
  return items;
});

enum RenfoButtonState { hidden, red, green, grey }

final renfoButtonStateProvider = Provider<RenfoButtonState>((ref) {
  final items = ref.watch(todayRenfoItemsProvider);
  if (items.isEmpty) return RenfoButtonState.hidden;
  if (items.any((i) => i.isAlert)) return RenfoButtonState.red;
  if (items.any((i) => i.doneToday)) return RenfoButtonState.green;
  return RenfoButtonState.grey;
});

extension RenfoButtonStateColor on RenfoButtonState {
  Color? colorFor(ThemeData theme) {
    switch (this) {
      case RenfoButtonState.red:
        return theme.colorScheme.error;
      case RenfoButtonState.green:
        return Colors.green.shade700;
      case RenfoButtonState.grey:
        return theme.colorScheme.outline;
      case RenfoButtonState.hidden:
        return null;
    }
  }
}
