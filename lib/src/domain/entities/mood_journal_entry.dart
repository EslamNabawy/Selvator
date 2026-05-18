import 'package:wisely/src/domain/entities/mood_type.dart';

class MoodJournalEntry {
  const MoodJournalEntry({
    required this.id,
    required this.mood,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final MoodType mood;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  MoodJournalEntry copyWith({
    String? id,
    MoodType? mood,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoodJournalEntry(
      id: id ?? this.id,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood': mood.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MoodJournalEntry.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);
    return MoodJournalEntry(
      id: json['id'] as String,
      mood: MoodType.fromKey(json['mood'] as String),
      note: json['note'] as String,
      createdAt: createdAt,
      updatedAt: DateTime.parse(
        (json['updatedAt'] as String?) ?? createdAt.toIso8601String(),
      ),
    );
  }
}
