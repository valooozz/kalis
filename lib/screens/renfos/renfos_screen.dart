import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/providers/renfo_providers.dart';
import 'package:kalis/widgets/renfo_card.dart';
import 'renfo_form_dialog.dart';
import 'renfo_detail_dialog.dart';

class RenfosScreen extends ConsumerWidget {
  const RenfosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbl = AppLocalizations.of(context)!;
    final renfosAsync = ref.watch(renfosProvider);

    return Scaffold(
      body: renfosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (renfos) {
          if (renfos.isEmpty) {
            return _EmptyRenfos(onAdd: () => _openAddDialog(context));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(lbl.renfosTitle),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                ),
              ),
              SliverList.builder(
                itemCount: renfos.length,
                itemBuilder: (context, index) {
                  final renfo = renfos[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: RenfoCard(
                      renfo: renfo,
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => RenfoDetailDialog(renfo: renfo),
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddDialog(context),
        tooltip: lbl.addRenfo,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const RenfoFormDialog());
  }
}

class _EmptyRenfos extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyRenfos({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            lbl.noRenfos,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(lbl.addRenfo),
          ),
        ],
      ),
    );
  }
}
