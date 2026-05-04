import 'package:flutter/material.dart';

enum FigureState { toLearn, learning, learned }

extension FigureStateExtension on FigureState {
  IconData get icon {
    switch (this) {
      case FigureState.toLearn:
        return Icons.bookmark_outline;
      case FigureState.learning:
        return Icons.sports_gymnastics;
      case FigureState.learned:
        return Icons.done_outline;
    }
  }

  String get label {
    switch (this) {
      case FigureState.toLearn:
        return 'À apprendre';
      case FigureState.learning:
        return 'En apprentissage';
      case FigureState.learned:
        return 'Maîtrisée';
    }
  }
}

enum FigureColor { red, orange, yellow, green, blue, purple }

extension FigureColorExtension on FigureColor {
  Color get color {
    switch (this) {
      case FigureColor.red:
        return const Color(0xFFE57373);
      case FigureColor.orange:
        return const Color(0xFFFFB74D);
      case FigureColor.yellow:
        return const Color(0xFFFFF176);
      case FigureColor.green:
        return const Color(0xFF81C784);
      case FigureColor.blue:
        return const Color(0xFF64B5F6);
      case FigureColor.purple:
        return const Color(0xFFBA68C8);
    }
  }
}

enum RecordUnit { reps, seconds }

extension RecordUnitExtension on RecordUnit {
  String getUnit(int? nb) {
    switch (this) {
      case RecordUnit.reps:
        return nb == 1 ? 'répétition' : 'répétitions';
      case RecordUnit.seconds:
        return nb == 1 ? 'seconde' : 'secondes';
    }
  }
}

class FigureModel {
  final String id;
  final String name;
  final FigureColor color;
  final FigureState state;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? recordValue;
  final RecordUnit? recordUnit;

  const FigureModel({
    required this.id,
    required this.name,
    required this.color,
    required this.state,
    this.startDate,
    this.endDate,
    this.recordValue,
    this.recordUnit,
  });

  factory FigureModel.fromFirestore(Map<String, dynamic> data, String id) {
    return FigureModel(
      id: id,
      name: data['name'] as String,
      color: FigureColor.values.firstWhere(
        (e) => e.name == data['color'],
        orElse: () => FigureColor.blue,
      ),
      state: FigureState.values.firstWhere(
        (e) => e.name == data['state'],
        orElse: () => FigureState.toLearn,
      ),
      startDate: data['startDate'] != null
          ? DateTime.parse(data['startDate'] as String)
          : null,
      endDate: data['endDate'] != null
          ? DateTime.parse(data['endDate'] as String)
          : null,
      recordValue: data['recordValue'] as int?,
      recordUnit: data['recordUnit'] != null
          ? RecordUnit.values.firstWhere(
              (e) => e.name == data['recordUnit'],
              orElse: () => RecordUnit.reps,
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'color': color.name,
      'state': state.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'recordValue': recordValue,
      'recordUnit': recordUnit?.name,
    };
  }

  FigureModel copyWith({
    String? id,
    String? name,
    FigureColor? color,
    FigureState? state,
    DateTime? startDate,
    DateTime? endDate,
    int? recordValue,
    RecordUnit? recordUnit,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearRecord = false,
  }) {
    return FigureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      state: state ?? this.state,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      recordValue: clearRecord ? null : recordValue ?? this.recordValue,
      recordUnit: clearRecord ? null : recordUnit ?? this.recordUnit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FigureModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
