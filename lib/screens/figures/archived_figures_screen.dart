import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/providers/figure_providers.dart';
import 'package:kalis/widgets/figure_card.dart';

import 'figure_detail_dialog.dart';

class ArchivedFiguresScreen extends ConsumerWidget {
  const ArchivedFiguresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbl = AppLocalizations.of(context)!;
    final figuresAsync = ref.watch(archivedFiguresProvider);

    return Scaffold(
      appBar: AppBar(title: Text(lbl.archivedFiguresTitle)),
      body: figuresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (figures) {
          if (figures.isEmpty) {
            return Center(child: Text(lbl.noArchivedFigures));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: figures.length,
            itemBuilder: (context, index) {
              final figure = figures[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: FigureCard(
                  figure: figure,
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => FigureDetailDialog(figure: figure),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
