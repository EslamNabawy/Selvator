import 'dart:convert';

import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/pool_tier.dart';
import 'package:wisely/src/domain/entities/quote_arc_tier.dart';

class QuoteEntry {
  const QuoteEntry({
    required this.id,
    required this.text,
    required this.author,
    required this.popularity,
    required this.categories,
    required this.tags,
    required this.moods,
    required this.moodStrength,
    required this.poolTier,
    this.rhythmScore = 45,
    this.arcTierByMood = const {},
  });

  final String id;
  final String text;
  final String author;
  final int popularity;
  final List<String> categories;
  final List<String> tags;
  final List<MoodType> moods;
  final Map<MoodType, double> moodStrength;
  final Map<MoodType, PoolTier> poolTier;
  final int rhythmScore;
  final Map<MoodType, QuoteArcTier> arcTierByMood;

  bool belongsToMood(MoodType mood) => moods.contains(mood);

  double effectiveMoodStrength(MoodType mood) =>
      moodStrength[mood] ?? moodStrength.values.fold(0.5, _maxDouble);

  PoolTier effectivePoolTier(MoodType mood) =>
      poolTier[mood] ?? PoolTier.wildcard;

  QuoteArcTier effectiveArcTier(MoodType mood) =>
      arcTierByMood[mood] ?? QuoteArcTier.bridge;

  QuoteEntry copyWith({
    String? id,
    String? text,
    String? author,
    int? popularity,
    List<String>? categories,
    List<String>? tags,
    List<MoodType>? moods,
    Map<MoodType, double>? moodStrength,
    Map<MoodType, PoolTier>? poolTier,
    int? rhythmScore,
    Map<MoodType, QuoteArcTier>? arcTierByMood,
  }) {
    return QuoteEntry(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      popularity: popularity ?? this.popularity,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      moods: moods ?? this.moods,
      moodStrength: moodStrength ?? this.moodStrength,
      poolTier: poolTier ?? this.poolTier,
      rhythmScore: rhythmScore ?? this.rhythmScore,
      arcTierByMood: arcTierByMood ?? this.arcTierByMood,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'popularity': popularity,
      'categories': categories,
      'tags': tags,
      'moods': moods.map((mood) => mood.name).toList(),
      'moodStrength': {
        for (final entry in moodStrength.entries) entry.key.name: entry.value,
      },
      'poolTier': {
        for (final entry in poolTier.entries) entry.key.name: entry.value.name,
      },
      'rhythmScore': rhythmScore,
      'arcTierByMood': {
        for (final entry in arcTierByMood.entries)
          entry.key.name: entry.value.name,
      },
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory QuoteEntry.fromJson(Map<String, dynamic> json) {
    final moods = (json['moods'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => MoodType.fromKey(value.toString()))
        .toList(growable: false);
    final moodStrengthJson =
        (json['moodStrength'] as Map<dynamic, dynamic>? ??
        const <dynamic, dynamic>{});
    final poolTierJson =
        (json['poolTier'] as Map<dynamic, dynamic>? ??
        const <dynamic, dynamic>{});
    final arcTierJson =
        (json['arcTierByMood'] as Map<dynamic, dynamic>? ??
        const <dynamic, dynamic>{});

    return QuoteEntry(
      id: json['id'].toString(),
      text: json['text'].toString(),
      author: json['author'].toString(),
      popularity: (json['popularity'] as num?)?.round() ?? 0,
      categories: (json['categories'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(growable: false),
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(growable: false),
      moods: moods,
      moodStrength: {
        for (final entry in moodStrengthJson.entries)
          MoodType.fromKey(entry.key.toString()):
              (entry.value as num?)?.toDouble() ?? 0.5,
      },
      poolTier: {
        for (final entry in poolTierJson.entries)
          MoodType.fromKey(entry.key.toString()): PoolTier.fromKey(
            entry.value.toString(),
          ),
      },
      rhythmScore: ((json['rhythmScore'] as num?)?.round() ?? 45)
          .clamp(0, 100)
          .toInt(),
      arcTierByMood: {
        for (final entry in arcTierJson.entries)
          MoodType.fromKey(entry.key.toString()): QuoteArcTier.fromKey(
            entry.value.toString(),
          ),
      },
    );
  }

  static double _maxDouble(double current, double next) =>
      current > next ? current : next;
}
