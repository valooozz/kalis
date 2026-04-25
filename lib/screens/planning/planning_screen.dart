import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/figure_model.dart';
import '../../providers/planning_providers.dart';
import '../../providers/today_providers.dart';
import '../../widgets/figure_square_card.dart';
import '../../providers/core_providers.dart';
import '../../core/utils/date_utils.dart';
import 'add_figure_to_day_dialog.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final days = List.generate(14, (i) => today.add(Duration(days: i)));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Planification'),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),
          for (final day in days) ...[
            _DayHeader(date: day),
            _DayContent(date: day),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// Header persistant pour chaque jour
class _DayHeader extends StatelessWidget {
  final DateTime date;

  const _DayHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = date.isToday;

    return SliverPersistentHeader(
      delegate: _DayHeaderDelegate(
        child: Container(
          color: theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                isToday
                    ? 'Aujourd\'hui'
                    : date.toShortLabel(Localizations.localeOf(context)),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    date.toShortDate(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _DayHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  double get maxExtent => 36;

  @override
  double get minExtent => 36;

  @override
  bool shouldRebuild(covariant _DayHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}

// Contenu d'un jour : grille de figures + bouton d'ajout
class _DayContent extends ConsumerWidget {
  final DateTime date;

  const _DayContent({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final figuresAsync = ref.watch(figuresForDayProvider(date));

    return SliverToBoxAdapter(
      child: figuresAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Erreur : $e'),
        data: (figures) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...figures.map(
                  (figure) => SizedBox(
                    width: _cardSize(context),
                    height: _cardSize(context),
                    child: FigureSquareCard(
                      figure: figure,
                      onTap: () {},
                      onLongPress: () => _removeFigure(ref, figure, date),
                    ),
                  ),
                ),
                // Bouton d'ajout
                SizedBox(
                  width: _cardSize(context),
                  height: _cardSize(context),
                  child: _AddFigureButton(date: date),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _cardSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth - 32 - 16) / 3;
  }

  Future<void> _removeFigure(
    WidgetRef ref,
    FigureModel figure,
    DateTime date,
  ) async {
    final plannedRepository = ref.read(trainingPlannedRepositoryProvider);
    final doneRepository = ref.read(trainingDoneRepositoryProvider);
    if (plannedRepository == null || doneRepository == null) return;

    await plannedRepository.remove(figure.id, date);

    // Si la figure a été validée ce jour, on supprime aussi le TrainingDone
    final exists = await doneRepository.exists(figure.id, date);
    if (exists) {
      await doneRepository.remove(figure.id, date);
    }
  }
}

// Bouton "+" pour ajouter une figure à un jour
class _AddFigureButton extends StatelessWidget {
  final DateTime date;

  const _AddFigureButton({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (_) => AddFigureToDayDialog(date: date),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Icon(Icons.add, color: theme.colorScheme.primary, size: 32),
        ),
      ),
    );
  }
}
