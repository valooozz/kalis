class JournalEntryModel {
  final String id;
  final String figureId;
  final DateTime date;
  final String text;

  const JournalEntryModel({
    required this.id,
    required this.figureId,
    required this.date,
    required this.text,
  });

  factory JournalEntryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return JournalEntryModel(
      id: id,
      figureId: data['figureId'] as String,
      date: DateTime.parse(data['date'] as String),
      text: data['text'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'figureId': figureId,
      'date': date.toIso8601String(),
      'text': text,
    };
  }

  JournalEntryModel copyWith({
    String? id,
    String? figureId,
    DateTime? date,
    String? text,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      figureId: figureId ?? this.figureId,
      date: date ?? this.date,
      text: text ?? this.text,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is JournalEntryModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}