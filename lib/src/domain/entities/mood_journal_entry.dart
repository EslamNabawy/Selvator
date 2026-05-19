import 'package:wisely/src/domain/entities/mood_type.dart';

class MoodJournalEntry {
  MoodJournalEntry({
    required this.id,
    MoodType? mood,
    MoodType? primaryMood,
    List<MoodType>? moods,
    required this.note,
    this.situation = '',
    this.feelings = '',
    this.handledWith = '',
    this.needNow = '',
    this.kindSelfTalk = '',
    required this.createdAt,
    required this.updatedAt,
  }) : primaryMood = primaryMood ?? mood ?? MoodType.happy,
       moods = _normalizeMoods(moods, primaryMood ?? mood ?? MoodType.happy);

  final String id;
  final MoodType primaryMood;
  final List<MoodType> moods;
  final String note;
  final String situation;
  final String feelings;
  final String handledWith;
  final String needNow;
  final String kindSelfTalk;
  final DateTime createdAt;
  final DateTime updatedAt;

  MoodType get mood => primaryMood;

  bool get hasNeedNow => needNow.trim().isNotEmpty;
  bool get hasHandledWith => handledWith.trim().isNotEmpty;
  bool get isBlank =>
      note.trim().isEmpty &&
      situation.trim().isEmpty &&
      feelings.trim().isEmpty &&
      handledWith.trim().isEmpty &&
      needNow.trim().isEmpty &&
      kindSelfTalk.trim().isEmpty;

  MoodJournalEntry copyWith({
    String? id,
    MoodType? primaryMood,
    List<MoodType>? moods,
    String? note,
    String? situation,
    String? feelings,
    String? handledWith,
    String? needNow,
    String? kindSelfTalk,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoodJournalEntry(
      id: id ?? this.id,
      primaryMood: primaryMood ?? this.primaryMood,
      moods: moods ?? this.moods,
      note: note ?? this.note,
      situation: situation ?? this.situation,
      feelings: feelings ?? this.feelings,
      handledWith: handledWith ?? this.handledWith,
      needNow: needNow ?? this.needNow,
      kindSelfTalk: kindSelfTalk ?? this.kindSelfTalk,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood': primaryMood.name,
      'primaryMood': primaryMood.name,
      'moods': moods.map((mood) => mood.name).toList(),
      'note': note,
      'situation': situation,
      'feelings': feelings,
      'handledWith': handledWith,
      'needNow': needNow,
      'kindSelfTalk': kindSelfTalk,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MoodJournalEntry.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final primaryMood = MoodType.fromKey(
      (json['primaryMood'] ?? json['mood'] ?? MoodType.happy.name).toString(),
    );
    final decodedMoods = (json['moods'] as List<dynamic>? ?? const [])
        .map((value) => MoodType.fromKey(value.toString()))
        .toList(growable: false);
    return MoodJournalEntry(
      id: json['id'] as String,
      primaryMood: primaryMood,
      moods: decodedMoods.isEmpty ? [primaryMood] : decodedMoods,
      note: json['note']?.toString() ?? '',
      situation: json['situation']?.toString() ?? '',
      feelings: json['feelings']?.toString() ?? '',
      handledWith: json['handledWith']?.toString() ?? '',
      needNow: json['needNow']?.toString() ?? '',
      kindSelfTalk: json['kindSelfTalk']?.toString() ?? '',
      createdAt: createdAt,
      updatedAt: DateTime.parse(
        (json['updatedAt'] as String?) ?? createdAt.toIso8601String(),
      ),
    );
  }

  static List<MoodType> _normalizeMoods(
    List<MoodType>? moods,
    MoodType primaryMood,
  ) {
    final unique = <MoodType>[primaryMood];
    for (final mood in moods ?? const <MoodType>[]) {
      if (!unique.contains(mood)) {
        unique.add(mood);
      }
    }
    return List.unmodifiable(unique);
  }
}
