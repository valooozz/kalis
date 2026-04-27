import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_entry_model.dart';
import 'core_providers.dart';
import 'today_providers.dart';

// Stream des entrées de journal pour une figure donnée
final journalEntriesForFigureProvider =
    StreamProvider.family<List<JournalEntryModel>, String>((ref, figureId) {
      final repository = ref.watch(journalEntryRepositoryProvider);
      if (repository == null) return const Stream.empty();

      return repository.watchByFigure(figureId);
    });

// Stream de l'entrée de journal pour une figure à une date donnée
final journalEntryForFigureAndDateProvider =
    StreamProvider.family<
      JournalEntryModel?,
      ({String figureId, DateTime date})
    >((ref, params) {
      final repository = ref.watch(journalEntryRepositoryProvider);
      if (repository == null) return const Stream.empty();

      return repository.watchByFigureAndDate(params.figureId, params.date);
    });

// Stream de l'entrée de journal pour une figure aujourd'hui
final todayJournalEntryForFigureProvider =
    StreamProvider.family<JournalEntryModel?, String>((ref, figureId) {
      final repository = ref.watch(journalEntryRepositoryProvider);
      if (repository == null) return const Stream.empty();

      final today = ref.watch(todayProvider);
      return repository.watchByFigureAndDate(figureId, today);
    });
