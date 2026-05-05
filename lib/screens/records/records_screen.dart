import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/figure_model.dart';
import 'package:kalis/providers/figure_providers.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbl = AppLocalizations.of(context)!;
    final learnedFiguresAsync = ref.read(
      figuresByStateProvider(FigureState.learned),
    );

    return learnedFiguresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur : $e'),
      data: (learnedFigures) {
        return Scaffold(
          appBar: AppBar(title: Text(lbl.recordsTitle)),
          body: CustomScrollView(
            slivers: [_FigureSliver(figures: learnedFigures)],
          ),
        );
      },
    );
  }
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
          child: _RecordCard(figure: figure),
        );
      }, childCount: figures.length),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final FigureModel figure;

  const _RecordCard({required this.figure});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final figureColor = figure.color.color;
    final figureRecordValue = figure.recordValue;
    final figureRecordUnit = figure.recordUnit?.getUnit(figureRecordValue);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: figureColor, width: 10),
              right: BorderSide(color: figureColor, width: 10),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      figure.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$figureRecordValue $figureRecordUnit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
