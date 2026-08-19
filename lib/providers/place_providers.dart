import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/place_model.dart';
import 'core_providers.dart';

final placesProvider = StreamProvider<List<PlaceModel>>((ref) {
  final repository = ref.watch(placeRepositoryProvider);
  if (repository == null) return const Stream.empty();
  return repository.watchAll().map((places) {
    final sorted = List<PlaceModel>.from(places);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  });
});

final placeByIdProvider = Provider.family<AsyncValue<PlaceModel?>, String>((
  ref,
  id,
) {
  return ref
      .watch(placesProvider)
      .whenData((places) => places.where((p) => p.id == id).firstOrNull);
});
