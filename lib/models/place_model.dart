class PlaceModel {
  final String id;
  final String name;
  final List<String> figureIds;

  const PlaceModel({
    required this.id,
    required this.name,
    this.figureIds = const [],
  });

  factory PlaceModel.fromFirestore(Map<String, dynamic> data, String id) {
    final raw = data['figureIds'] as List<dynamic>?;
    return PlaceModel(
      id: id,
      name: data['name'] as String? ?? '',
      figureIds: raw == null ? [] : raw.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'figureIds': figureIds};
  }

  PlaceModel copyWith({String? id, String? name, List<String>? figureIds}) {
    return PlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      figureIds: figureIds ?? List<String>.from(this.figureIds),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PlaceModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
