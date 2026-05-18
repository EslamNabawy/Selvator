import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/tide_season.dart';

const Object _unset = Object();

enum AppThemeMode {
  system,
  light,
  dark;

  static AppThemeMode fromKey(String? value) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}

enum UserGender {
  male,
  female;

  String get label {
    switch (this) {
      case UserGender.male:
        return 'Male';
      case UserGender.female:
        return 'Female';
    }
  }

  static UserGender? fromKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    for (final gender in UserGender.values) {
      if (gender.name == value) {
        return gender;
      }
    }
    return null;
  }
}

class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.gender,
    required this.preferredMoods,
    required this.recentMoodTrail,
    required this.likedQuoteIds,
    required this.lastShownQuoteIds,
    required this.likedAuthors,
    required this.likedTagCounts,
    required this.widgetMood,
    required this.themeMode,
    required this.textScale,
    required this.authorWeight,
    required this.tagWeight,
    required this.lastShownAtByQuoteId,
    required this.authorLikeEvents7d,
    required this.moodDailyCounts30d,
    required this.consecutiveTagBoostedSkips,
    required this.lastDecayDate,
    required this.tagPreferenceWeights,
    required this.frustrationIndex,
    required this.streak,
    required this.lastOpenAt,
    required this.lastMoodTags,
    required this.tideSeason,
    required this.tideSnapshotStartedAt,
    required this.greetingOverride,
  });

  final String displayName;
  final UserGender? gender;
  final List<MoodType> preferredMoods;
  final List<MoodType> recentMoodTrail;
  final Set<String> likedQuoteIds;
  final List<String> lastShownQuoteIds;
  final Map<String, int> likedAuthors;
  final Map<String, int> likedTagCounts;
  final MoodType widgetMood;
  final AppThemeMode themeMode;
  final double textScale;
  final double authorWeight;
  final double tagWeight;
  final Map<String, int> lastShownAtByQuoteId;
  final Map<String, List<int>> authorLikeEvents7d;
  final Map<String, int> moodDailyCounts30d;
  final int consecutiveTagBoostedSkips;
  final DateTime lastDecayDate;
  final Map<String, double> tagPreferenceWeights;
  final int frustrationIndex;
  final int streak;
  final DateTime lastOpenAt;
  final List<String> lastMoodTags;
  final TideSeason tideSeason;
  final DateTime tideSnapshotStartedAt;
  final String? greetingOverride;

  factory UserProfile.initial() {
    return UserProfile(
      displayName: '',
      gender: null,
      preferredMoods: const [],
      recentMoodTrail: const [],
      likedQuoteIds: const {},
      lastShownQuoteIds: const [],
      likedAuthors: const {},
      likedTagCounts: const {},
      widgetMood: MoodType.happy,
      themeMode: AppThemeMode.system,
      textScale: 1,
      authorWeight: 0.4,
      tagWeight: 0.55,
      lastShownAtByQuoteId: const {},
      authorLikeEvents7d: const {},
      moodDailyCounts30d: const {},
      consecutiveTagBoostedSkips: 0,
      lastDecayDate: DateTime.fromMillisecondsSinceEpoch(0),
      tagPreferenceWeights: const {},
      frustrationIndex: 0,
      streak: 0,
      lastOpenAt: DateTime.fromMillisecondsSinceEpoch(0),
      lastMoodTags: const [],
      tideSeason: TideSeason.still,
      tideSnapshotStartedAt: DateTime.fromMillisecondsSinceEpoch(0),
      greetingOverride: null,
    );
  }

  bool get isOnboarded =>
      displayName.trim().isNotEmpty || preferredMoods.isNotEmpty;

  bool get hasGreetingProfile => isOnboarded && gender != null;

  UserProfile copyWith({
    String? displayName,
    UserGender? gender,
    List<MoodType>? preferredMoods,
    List<MoodType>? recentMoodTrail,
    Set<String>? likedQuoteIds,
    List<String>? lastShownQuoteIds,
    Map<String, int>? likedAuthors,
    Map<String, int>? likedTagCounts,
    MoodType? widgetMood,
    AppThemeMode? themeMode,
    double? textScale,
    double? authorWeight,
    double? tagWeight,
    Map<String, int>? lastShownAtByQuoteId,
    Map<String, List<int>>? authorLikeEvents7d,
    Map<String, int>? moodDailyCounts30d,
    int? consecutiveTagBoostedSkips,
    DateTime? lastDecayDate,
    Map<String, double>? tagPreferenceWeights,
    int? frustrationIndex,
    int? streak,
    DateTime? lastOpenAt,
    List<String>? lastMoodTags,
    TideSeason? tideSeason,
    DateTime? tideSnapshotStartedAt,
    Object? greetingOverride = _unset,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      preferredMoods: preferredMoods ?? this.preferredMoods,
      recentMoodTrail: recentMoodTrail ?? this.recentMoodTrail,
      likedQuoteIds: likedQuoteIds ?? this.likedQuoteIds,
      lastShownQuoteIds: lastShownQuoteIds ?? this.lastShownQuoteIds,
      likedAuthors: likedAuthors ?? this.likedAuthors,
      likedTagCounts: likedTagCounts ?? this.likedTagCounts,
      widgetMood: widgetMood ?? this.widgetMood,
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      authorWeight: authorWeight ?? this.authorWeight,
      tagWeight: tagWeight ?? this.tagWeight,
      lastShownAtByQuoteId: lastShownAtByQuoteId ?? this.lastShownAtByQuoteId,
      authorLikeEvents7d: authorLikeEvents7d ?? this.authorLikeEvents7d,
      moodDailyCounts30d: moodDailyCounts30d ?? this.moodDailyCounts30d,
      consecutiveTagBoostedSkips:
          consecutiveTagBoostedSkips ?? this.consecutiveTagBoostedSkips,
      lastDecayDate: lastDecayDate ?? this.lastDecayDate,
      tagPreferenceWeights: tagPreferenceWeights ?? this.tagPreferenceWeights,
      frustrationIndex: frustrationIndex ?? this.frustrationIndex,
      streak: streak ?? this.streak,
      lastOpenAt: lastOpenAt ?? this.lastOpenAt,
      lastMoodTags: lastMoodTags ?? this.lastMoodTags,
      tideSeason: tideSeason ?? this.tideSeason,
      tideSnapshotStartedAt:
          tideSnapshotStartedAt ?? this.tideSnapshotStartedAt,
      greetingOverride: greetingOverride == _unset
          ? this.greetingOverride
          : greetingOverride as String?,
    );
  }

  UserProfile pruned(Set<String> validQuoteIds) {
    final prunedLastShown = [
      for (final quoteId in lastShownQuoteIds)
        if (validQuoteIds.contains(quoteId)) quoteId,
    ];
    return copyWith(
      likedQuoteIds: likedQuoteIds.where(validQuoteIds.contains).toSet(),
      lastShownQuoteIds: prunedLastShown.take(20).toList(growable: false),
      lastShownAtByQuoteId: {
        for (final entry in lastShownAtByQuoteId.entries)
          if (validQuoteIds.contains(entry.key)) entry.key: entry.value,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'gender': gender?.name,
      'preferredMoods': preferredMoods.map((mood) => mood.name).toList(),
      'recentMoodTrail': recentMoodTrail.map((mood) => mood.name).toList(),
      'likedQuoteIds': likedQuoteIds.toList(),
      'lastShownQuoteIds': lastShownQuoteIds,
      'likedAuthors': likedAuthors,
      'likedTagCounts': likedTagCounts,
      'widgetMood': widgetMood.name,
      'themeMode': themeMode.name,
      'textScale': textScale,
      'authorWeight': authorWeight,
      'tagWeight': tagWeight,
      'lastShownAtByQuoteId': lastShownAtByQuoteId,
      'authorLikeEvents7d': authorLikeEvents7d,
      'moodDailyCounts30d': moodDailyCounts30d,
      'consecutiveTagBoostedSkips': consecutiveTagBoostedSkips,
      'lastDecayDate': lastDecayDate.toIso8601String(),
      'tagPreferenceWeights': tagPreferenceWeights,
      'frustrationIndex': frustrationIndex,
      'streak': streak,
      'lastOpenAt': lastOpenAt.toIso8601String(),
      'lastMoodTags': lastMoodTags,
      'tideSeason': tideSeason.name,
      'tideSnapshotStartedAt': tideSnapshotStartedAt.toIso8601String(),
      'greetingOverride': greetingOverride,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName']?.toString() ?? '',
      gender: UserGender.fromKey(json['gender']?.toString()),
      preferredMoods: (json['preferredMoods'] as List<dynamic>? ?? const [])
          .map((item) => MoodType.fromKey(item.toString()))
          .toList(growable: false),
      recentMoodTrail: (json['recentMoodTrail'] as List<dynamic>? ?? const [])
          .map((item) => MoodType.fromKey(item.toString()))
          .toList(growable: false),
      likedQuoteIds: (json['likedQuoteIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toSet(),
      lastShownQuoteIds:
          (json['lastShownQuoteIds'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(growable: false),
      likedAuthors: _toIntMap(json['likedAuthors']),
      likedTagCounts: _toIntMap(json['likedTagCounts']),
      widgetMood: MoodType.fromKey(json['widgetMood']?.toString() ?? 'happy'),
      themeMode: AppThemeMode.fromKey(json['themeMode']?.toString()),
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1,
      authorWeight: (json['authorWeight'] as num?)?.toDouble() ?? 0.4,
      tagWeight: (json['tagWeight'] as num?)?.toDouble() ?? 0.55,
      lastShownAtByQuoteId: _toIntMap(json['lastShownAtByQuoteId']),
      authorLikeEvents7d: _toListIntMap(
        json['authorLikeEvents7d'] as Map<dynamic, dynamic>?,
      ),
      moodDailyCounts30d: _toIntMap(json['moodDailyCounts30d']),
      consecutiveTagBoostedSkips:
          (json['consecutiveTagBoostedSkips'] as num?)?.round() ?? 0,
      lastDecayDate:
          DateTime.tryParse(json['lastDecayDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      tagPreferenceWeights: _toDoubleMap(json['tagPreferenceWeights']),
      frustrationIndex: (json['frustrationIndex'] as num?)?.round() ?? 0,
      streak: (json['streak'] as num?)?.round() ?? 0,
      lastOpenAt:
          DateTime.tryParse(json['lastOpenAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastMoodTags: (json['lastMoodTags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      tideSeason: TideSeason.fromKey(json['tideSeason']?.toString()),
      tideSnapshotStartedAt:
          DateTime.tryParse(json['tideSnapshotStartedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      greetingOverride: _nullableString(json['greetingOverride']),
    );
  }

  static Map<String, int> _toIntMap(dynamic source) {
    final raw = source as Map<dynamic, dynamic>? ?? const <dynamic, dynamic>{};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): (entry.value as num?)?.round() ?? 0,
    };
  }

  static Map<String, double> _toDoubleMap(dynamic source) {
    final raw = source as Map<dynamic, dynamic>? ?? const <dynamic, dynamic>{};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): (entry.value as num?)?.toDouble() ?? 0,
    };
  }

  static String? _nullableString(dynamic source) {
    final value = source?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static Map<String, List<int>> _toListIntMap(Map<dynamic, dynamic>? source) {
    final raw = source ?? const <dynamic, dynamic>{};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): (entry.value as List<dynamic>? ?? const [])
            .map((item) => (item as num?)?.round() ?? 0)
            .toList(growable: false),
    };
  }
}
