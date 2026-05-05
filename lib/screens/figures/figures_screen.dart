import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/screens/figures/figure_calendar_dialog.dart';
import 'package:kalis/widgets/global_calendar_dialog.dart';
import '../../models/figure_model.dart';
import '../../providers/figure_providers.dart';
import '../../widgets/figure_card.dart';
import 'figure_detail_dialog.dart';
import 'figure_form_dialog.dart';
import 'package:go_router/go_router.dart';

class FiguresScreen extends ConsumerWidget {
  const FiguresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbl = AppLocalizations.of(context)!;
    final figuresAsync = ref.watch(figuresProvider);

    return Scaffold(
      body: figuresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (figures) {
          if (figures.isEmpty) {
            return _EmptyFigures(onAdd: () => _openAddDialog(context));
          }

          // Groupement par statut
          final learned = figures
              .where((f) => f.state == FigureState.learned)
              .toList();
          final learning = figures
              .where((f) => f.state == FigureState.learning)
              .toList();
          final toLearn = figures
              .where((f) => f.state == FigureState.toLearn)
              .toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => GlobalCalendarDialog(),
                    ),
                    tooltip: lbl.globalCalendarTitle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_events),
                    onPressed: () => context.push('/records'),
                    tooltip: lbl.recordsTitle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => context.push('/settings'),
                    tooltip: lbl.settingsTitle,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(lbl.figuresScreenTitle),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                ),
              ),
              if (learned.isNotEmpty) ...[
                _StickyHeader(label: '${lbl.stateLearned} (${learned.length})'),
                _FigureSliver(figures: learned, state: FigureState.learned),
              ],
              if (learning.isNotEmpty) ...[
                _StickyHeader(
                  label: '${lbl.stateLearning} (${learning.length})',
                ),
                _FigureSliver(figures: learning, state: FigureState.learning),
              ],
              if (toLearn.isNotEmpty) ...[
                _StickyHeader(label: '${lbl.stateToLearn} (${toLearn.length})'),
                _FigureSliver(figures: toLearn, state: FigureState.toLearn),
              ],
              // Padding en bas pour le FAB
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const FigureFormDialog());
  }
}

// Header persistant au scroll
class _StickyHeader extends StatelessWidget {
  final String label;

  const _StickyHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(
        child: Container(
          color: theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

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
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}

class _FigureSliver extends ConsumerStatefulWidget {
  final List<FigureModel> figures;
  final FigureState state;

  const _FigureSliver({required this.figures, required this.state});

  @override
  ConsumerState<_FigureSliver> createState() => _FigureSliverState();
}

class _FigureSliverState extends ConsumerState<_FigureSliver> {
  List<FigureModel>? _localFigures;

  @override
  void didUpdateWidget(covariant _FigureSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    // On accepte la mise à jour du stream seulement si
    // elle ne vient pas d'un reorder local en cours
    if (_localFigures == null) return;
    final localIds = _localFigures!.map((f) => f.id).toList();
    final streamIds = widget.figures.map((f) => f.id).toList();
    if (localIds.join() == streamIds.join()) {
      // Le stream a rattrapé l'état local, on peut l'effacer
      _localFigures = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final figures = _localFigures ?? widget.figures;

    return SliverReorderableList(
      itemCount: figures.length,
      itemBuilder: (context, index) {
        final figure = figures[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(figure.id),
          index: index,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: FigureCard(
              figure: figure,
              onTap: () => showDialog(
                context: context,
                builder: (_) => FigureDetailDialog(figure: figure),
              ),
              onDoubleTap: () => showDialog(
                context: context,
                builder: (_) => FigureCalendarDialog(figure: figure),
              ),
            ),
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final reordered = List<FigureModel>.from(figures);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);

        // Mise à jour locale immédiate
        setState(() => _localFigures = reordered);

        // Mise à jour Firestore en arrière-plan
        ref.read(figureOrderProvider).reorder(reordered);
      },
    );
  }
}

class _EmptyFigures extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyFigures({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.self_improvement,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            lbl.noFigures,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(lbl.addFigure),
          ),
        ],
      ),
    );
  }
}
