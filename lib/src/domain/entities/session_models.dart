import 'package:wisely/src/domain/entities/mood_type.dart';

class SessionState {
  const SessionState({
    required this.lastMood,
    required this.startTime,
    required this.quotesShownCount,
    required this.refreshRate,
    required this.refreshTimestamps,
  });

  final MoodType lastMood;
  final DateTime startTime;
  final int quotesShownCount;
  final double refreshRate;
  final List<DateTime> refreshTimestamps;

  factory SessionState.initial(MoodType mood, DateTime now) {
    return SessionState(
      lastMood: mood,
      startTime: now,
      quotesShownCount: 0,
      refreshRate: 0,
      refreshTimestamps: const [],
    );
  }

  SessionState copyWith({
    MoodType? lastMood,
    DateTime? startTime,
    int? quotesShownCount,
    double? refreshRate,
    List<DateTime>? refreshTimestamps,
  }) {
    return SessionState(
      lastMood: lastMood ?? this.lastMood,
      startTime: startTime ?? this.startTime,
      quotesShownCount: quotesShownCount ?? this.quotesShownCount,
      refreshRate: refreshRate ?? this.refreshRate,
      refreshTimestamps: refreshTimestamps ?? this.refreshTimestamps,
    );
  }
}

class SessionAggregates {
  const SessionAggregates({
    required this.avgRefreshRate,
    required this.avgSessionLength,
    required this.sampleCount,
  });

  final double avgRefreshRate;
  final double avgSessionLength;
  final int sampleCount;

  factory SessionAggregates.initial() {
    return const SessionAggregates(
      avgRefreshRate: 0,
      avgSessionLength: 0,
      sampleCount: 0,
    );
  }

  SessionAggregates merge({
    required double refreshRate,
    required double sessionLengthMinutes,
  }) {
    final nextCount = sampleCount + 1;
    return SessionAggregates(
      avgRefreshRate:
          ((avgRefreshRate * sampleCount) + refreshRate) / nextCount,
      avgSessionLength:
          ((avgSessionLength * sampleCount) + sessionLengthMinutes) / nextCount,
      sampleCount: nextCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avgRefreshRate': avgRefreshRate,
      'avgSessionLength': avgSessionLength,
      'sampleCount': sampleCount,
    };
  }

  factory SessionAggregates.fromJson(Map<String, dynamic> json) {
    return SessionAggregates(
      avgRefreshRate: (json['avgRefreshRate'] as num?)?.toDouble() ?? 0,
      avgSessionLength: (json['avgSessionLength'] as num?)?.toDouble() ?? 0,
      sampleCount: (json['sampleCount'] as num?)?.round() ?? 0,
    );
  }
}
