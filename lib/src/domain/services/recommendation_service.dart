import 'dart:math';

import 'package:intl/intl.dart';
import 'package:wisely/src/domain/curation/quote_curation.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/time_bucket.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/domain/repositories/quote_repository.dart';
import 'package:wisely/src/domain/services/clock_service.dart';
import 'package:wisely/src/domain/services/quote_engine.dart';

class RecommendationResult {
  const RecommendationResult({
    required this.quote,
    required this.usedFallback,
    required this.resetHistory,
    this.gradientArc = const [],
  });

  final QuoteEntry quote;
  final bool usedFallback;
  final bool resetHistory;
  final List<QuoteEntry> gradientArc;
}

class RecommendationService {
  RecommendationService({required QuoteRepository repository, Random? random})
    : _repository = repository,
      _quoteEngine = QuoteEngine(repository: repository, random: random);

  final QuoteRepository _repository;
  final QuoteEngine _quoteEngine;
  final ClockService _clockService = const ClockService();

  RecommendationResult nextQuote({
    required MoodType mood,
    required UserProfile profile,
    required double refreshRate,
    TimeBucket? timeBucket,
  }) {
    return nextQuoteForMoods(
      moods: [mood],
      profile: profile,
      refreshRate: refreshRate,
      timeBucket: timeBucket,
    );
  }

  RecommendationResult nextQuoteForMoods({
    required List<MoodType> moods,
    required UserProfile profile,
    required double refreshRate,
    TimeBucket? timeBucket,
  }) {
    final result = _quoteEngine.getQuotes(
      selectedMoods: moods,
      profile: profile,
      refreshRate: refreshRate,
      timeBucket: timeBucket ?? _clockService.bucketFor(DateTime.now()),
    );
    return RecommendationResult(
      quote: result.quote,
      gradientArc: result.gradientArc,
      usedFallback: result.usedFallback,
      resetHistory: result.resetHistory,
    );
  }

  QuoteEntry quoteOfTheDay({required MoodType mood, required DateTime now}) {
    final moodQuotes = _repository.allQuotes
        .where((quote) => quote.belongsToMood(mood))
        .toList(growable: false);
    if (moodQuotes.isEmpty) {
      return _repository.allQuotes.first;
    }
    final hash = now.year * 10000 + now.month * 100 + now.day;
    return moodQuotes[hash % moodQuotes.length];
  }

  UserProfile applyDailyDecay(UserProfile profile, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (profile.lastDecayDate.millisecondsSinceEpoch == 0) {
      return _pruneRollingHistory(profile.copyWith(lastDecayDate: today));
    }

    final lastDecay = DateTime(
      profile.lastDecayDate.year,
      profile.lastDecayDate.month,
      profile.lastDecayDate.day,
    );
    final days = today.difference(lastDecay).inDays;
    if (days <= 0) {
      return _pruneRollingHistory(profile);
    }

    var authorWeight = profile.authorWeight;
    var tagWeight = profile.tagWeight;
    var preferenceWeights = Map<String, double>.from(
      profile.tagPreferenceWeights,
    );
    for (var index = 0; index < days; index++) {
      authorWeight = (authorWeight * 0.98).clamp(0.1, 1.0).toDouble();
      tagWeight = (tagWeight * 0.99).clamp(0.1, 1.0).toDouble();
      preferenceWeights = {
        for (final entry in preferenceWeights.entries)
          if ((entry.value * 0.97).abs() >= 0.02) entry.key: entry.value * 0.97,
      };
    }

    return _pruneRollingHistory(
      profile.copyWith(
        authorWeight: authorWeight,
        tagWeight: tagWeight,
        tagPreferenceWeights: preferenceWeights,
        lastDecayDate: today,
      ),
    );
  }

  UserProfile registerMoodSelection({
    required UserProfile profile,
    required MoodType mood,
    required DateTime now,
  }) {
    final moodTrail = [...profile.recentMoodTrail, mood].reversed
        .take(20)
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    final dayKey = '${DateFormat('yyyy-MM-dd').format(now)}|${mood.name}';
    final daily = Map<String, int>.from(profile.moodDailyCounts30d)
      ..update(dayKey, (count) => count + 1, ifAbsent: () => 1);
    final lastMoodTags = [
      mood.name,
      ...(moodKeywordMap[mood] ?? const <String>[]),
    ];

    return _pruneRollingHistory(
      profile.copyWith(
        recentMoodTrail: moodTrail,
        widgetMood: mood,
        moodDailyCounts30d: daily,
        lastMoodTags: lastMoodTags,
      ),
    );
  }

  UserProfile registerQuoteShown({
    required UserProfile profile,
    required QuoteEntry quote,
    required DateTime now,
    required bool resetHistory,
  }) {
    final lastShownIds =
        [
              ...(resetHistory ? const <String>[] : profile.lastShownQuoteIds),
              quote.id,
            ].reversed
            .take(20)
            .toList(growable: false)
            .reversed
            .toList(growable: false);
    final timestamps = Map<String, int>.from(
      resetHistory ? const <String, int>{} : profile.lastShownAtByQuoteId,
    )..[quote.id] = now.millisecondsSinceEpoch;

    return profile.copyWith(
      lastShownQuoteIds: lastShownIds,
      lastShownAtByQuoteId: timestamps,
    );
  }

  UserProfile toggleLike({
    required UserProfile profile,
    required QuoteEntry quote,
    required DateTime now,
  }) {
    final likedQuotes = Set<String>.from(profile.likedQuoteIds);
    final likedAuthors = Map<String, int>.from(profile.likedAuthors);
    final likedTags = Map<String, int>.from(profile.likedTagCounts);
    final authorEvents = {
      for (final entry in profile.authorLikeEvents7d.entries)
        entry.key: [...entry.value],
    };
    var authorWeight = profile.authorWeight;

    if (likedQuotes.contains(quote.id)) {
      likedQuotes.remove(quote.id);
      likedAuthors.update(
        quote.author,
        (count) => max(0, count - 1),
        ifAbsent: () => 0,
      );
      likedAuthors.removeWhere((_, count) => count <= 0);
      for (final tag in quote.tags) {
        likedTags.update(tag, (count) => max(0, count - 1), ifAbsent: () => 0);
      }
      likedTags.removeWhere((_, count) => count <= 0);
    } else {
      likedQuotes.add(quote.id);
      likedAuthors.update(
        quote.author,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      for (final tag in quote.tags) {
        likedTags.update(tag, (count) => count + 1, ifAbsent: () => 1);
      }
      final updatedEvents = [
        ...(authorEvents[quote.author] ?? const <int>[]),
        now.millisecondsSinceEpoch,
      ];
      final cutoff = now
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      final recentEvents = updatedEvents
          .where((stamp) => stamp >= cutoff)
          .toList(growable: false);
      authorEvents[quote.author] = recentEvents;
      if (recentEvents.length >= 3 && recentEvents.length % 3 == 0) {
        authorWeight = (authorWeight + 0.05).clamp(0.1, 1.0).toDouble();
      }
    }

    return _pruneRollingHistory(
      profile.copyWith(
        likedQuoteIds: likedQuotes,
        likedAuthors: likedAuthors,
        likedTagCounts: likedTags,
        authorLikeEvents7d: authorEvents,
        authorWeight: authorWeight,
        consecutiveTagBoostedSkips: 0,
      ),
    );
  }

  UserProfile recordSkip({
    required UserProfile profile,
    required QuoteEntry quote,
    required MoodType mood,
  }) {
    final boosted = _tagOverlapRatio(quote, profile) > 0;
    var consecutive = boosted ? profile.consecutiveTagBoostedSkips + 1 : 0;
    var tagWeight = profile.tagWeight;
    if (boosted && consecutive >= 5) {
      tagWeight = (tagWeight - 0.03).clamp(0.1, 1.0).toDouble();
      consecutive = 0;
    }
    return profile.copyWith(
      consecutiveTagBoostedSkips: consecutive,
      tagWeight: tagWeight,
      widgetMood: mood,
    );
  }

  double calculateRefreshRate(List<DateTime> refreshTimestamps, DateTime now) {
    if (refreshTimestamps.isEmpty) {
      return 0;
    }
    final cutoff = now.subtract(const Duration(minutes: 1));
    return refreshTimestamps
        .where((stamp) => stamp.isAfter(cutoff))
        .length
        .toDouble();
  }

  double _tagOverlapRatio(QuoteEntry quote, UserProfile profile) {
    if (quote.tags.isEmpty || profile.likedTagCounts.isEmpty) {
      return 0;
    }
    final overlap = quote.tags.where(profile.likedTagCounts.containsKey).length;
    return overlap == 0 ? 0 : overlap / quote.tags.length;
  }

  UserProfile _pruneRollingHistory(UserProfile profile) {
    final cutoff7 = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    final cutoff30 = DateTime.now().subtract(const Duration(days: 30));
    final recentAuthorEvents = <String, List<int>>{};
    for (final entry in profile.authorLikeEvents7d.entries) {
      final retained = entry.value
          .where((stamp) => stamp >= cutoff7)
          .toList(growable: false);
      if (retained.isNotEmpty) {
        recentAuthorEvents[entry.key] = retained;
      }
    }

    final recentMoodCounts = <String, int>{};
    for (final entry in profile.moodDailyCounts30d.entries) {
      final parts = entry.key.split('|');
      if (parts.isEmpty) {
        continue;
      }
      final parsed = DateTime.tryParse(parts.first);
      if (parsed != null && !parsed.isBefore(cutoff30)) {
        recentMoodCounts[entry.key] = entry.value;
      }
    }

    return profile.copyWith(
      authorLikeEvents7d: recentAuthorEvents,
      moodDailyCounts30d: recentMoodCounts,
    );
  }
}
