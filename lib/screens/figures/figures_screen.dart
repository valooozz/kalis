import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/figure_model.dart';
import '../../providers/figure_providers.dart';
import '../../widgets/figure_card.dart';
import 'figure_detail_dialog.dart';
import 'figure_form_dialog.dart';

class FiguresScreen extends ConsumerWidget {
  const FiguresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final figuresAsync = ref.watch(figuresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Figures')),
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
              if (learned.isNotEmpty) ...[
                _StickyHeader(label: 'Apprises (${learned.length})'),
                _FigureSliver(figures: learned),
              ],
              if (learning.isNotEmpty) ...[
                _StickyHeader(label: 'En apprentissage (${learning.length})'),
                _FigureSliver(figures: learning),
              ],
              if (toLearn.isNotEmpty) ...[
                _StickyHeader(label: 'À apprendre (${toLearn.length})'),
                _FigureSliver(figures: toLearn),
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

class _FigureSliver extends StatelessWidget {
  final List<FigureModel> figures;

  const _FigureSliver({required this.figures});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final figure = figures[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: FigureCard(
            figure: figure,
            onTap: () => showDialog(
              context: context,
              builder: (_) => FigureDetailDialog(figure: figure),
            ),
          ),
        );
      }, childCount: figures.length),
    );
  }
}

class _EmptyFigures extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyFigures({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            'Aucune figure pour le moment',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une figure'),
          ),
        ],
      ),
    );
  }
}
