import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/providers/place_providers.dart';
import 'place_form_dialog.dart';
import 'place_detail_dialog.dart';

class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbl = AppLocalizations.of(context)!;
    final placesAsync = ref.watch(placesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(lbl.placesTitle)),
      body: placesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (places) {
          if (places.isEmpty) {
            return Center(child: Text(lbl.noPlaces));
          }
          return ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return ListTile(
                title: Text(place.name),
                subtitle: Text(
                  '${place.figureIds.length} ${lbl.placesFigures}',
                ),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => PlaceDetailDialog(place: place),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const PlaceFormDialog(),
        ),
        tooltip: lbl.addPlace,
        child: const Icon(Icons.add),
      ),
    );
  }
}
