import 'package:wisely/src/domain/entities/mood_type.dart';

class CatalogVersion {
  const CatalogVersion({
    required this.version,
    required this.generatedAt,
    required this.moodCounts,
  });

  final int version;
  final DateTime generatedAt;
  final Map<MoodType, int> moodCounts;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'generatedAt': generatedAt.toIso8601String(),
      'moodCounts': {
        for (final entry in moodCounts.entries) entry.key.name: entry.value,
      },
    };
  }

  factory CatalogVersion.fromJson(Map<String, dynamic> json) {
    final moodCountsJson =
        (json['moodCounts'] as Map<dynamic, dynamic>? ??
        const <dynamic, dynamic>{});
    return CatalogVersion(
      version: (json['version'] as num?)?.round() ?? 1,
      generatedAt:
          DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      moodCounts: {
        for (final entry in moodCountsJson.entries)
          MoodType.fromKey(entry.key.toString()):
              (entry.value as num?)?.round() ?? 0,
      },
    );
  }
}
