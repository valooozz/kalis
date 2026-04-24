class TrainingDoneModel {
  final String figureId;
  final DateTime date;

  const TrainingDoneModel({
    required this.figureId,
    required this.date,
  });

  factory TrainingDoneModel.fromFirestore(Map<String, dynamic> data) {
    return TrainingDoneModel(
      figureId: data['figureId'] as String,
      date: DateTime.parse(data['date'] as String),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'figureId': figureId,
      'date': date.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingDoneModel &&
          other.figureId == figureId &&
          other.date.year == date.year &&
          other.date.month == date.month &&
          other.date.day == date.day;

  @override
  int get hashCode => Object.hash(figureId, date.year, date.month, date.day);
}