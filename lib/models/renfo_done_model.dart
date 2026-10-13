class RenfoDoneModel {
  final String renfoId;
  final DateTime date;

  const RenfoDoneModel({required this.renfoId, required this.date});

  factory RenfoDoneModel.fromFirestore(Map<String, dynamic> data) {
    return RenfoDoneModel(
      renfoId: data['renfoId'] as String,
      date: DateTime.parse(data['date'] as String),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'renfoId': renfoId, 'date': date.toIso8601String()};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenfoDoneModel &&
          other.renfoId == renfoId &&
          other.date.year == date.year &&
          other.date.month == date.month &&
          other.date.day == date.day;

  @override
  int get hashCode => Object.hash(renfoId, date.year, date.month, date.day);
}
