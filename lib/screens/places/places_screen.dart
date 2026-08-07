import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/providers/place_providers.dart';
import 'package:kalis/widgets/place_card.dart';
import 'place_form_dialog.dart';
import 'place_detail_dialog.dart';

class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbl = AppLocalizations.of(context)!;
    final placesAsync = ref.watch(placesProvider);

    return Scaffold(
      body: placesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (places) {
          if (places.isEmpty) {
            return _EmptyPlaces(onAdd: () => _openAddDialog(context));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(lbl.placesTitle),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                ),
              ),
              SliverList.builder(
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: PlaceCard(
                      place: place,
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => PlaceDetailDialog(place: place),
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
        tooltip: lbl.addPlace,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const PlaceFormDialog());
  }
}

class _EmptyPlaces extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyPlaces({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lbl = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.place_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            lbl.noPlaces,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(lbl.addPlace),
          ),
        ],
      ),
    );
  }
}
