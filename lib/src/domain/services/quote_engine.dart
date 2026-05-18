import 'dart:math';

import 'package:wisely/src/domain/entities/mood_energy.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/quote_arc_tier.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/time_bucket.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/domain/repositories/quote_repository.dart';
import 'package:wisely/src/domain/services/clock_service.dart';
import 'package:wisely/src/domain/services/combo_matrix.dart';
import 'package:wisely/src/domain/services/rhythm_filter.dart';

class QuoteEngineResult {
  const QuoteEngineResult({
    required this.quote,
    required this.gradientArc,
    required this.usedFallback,
    required this.resetHistory,
  });

  final QuoteEntry quote;
  final List<QuoteEntry> gradientArc;
  final bool usedFallback;
  final bool resetHistory;
}

class QuoteEngine {
  QuoteEngine({
    required QuoteRepository repository,
    ComboMatrix comboMatrix = const ComboMatrix(),
    ClockService clockService = const ClockService(),
    RhythmFilter rhythmFilter = const RhythmFilter(),
    Random? random,
  }) : _repository = repository,
       _comboMatrix = comboMatrix,
       _clockService = clockService,
       _rhythmFilter = rhythmFilter,
       _random = random ?? Random();

  final QuoteRepository _repository;
  final ComboMatrix _comboMatrix;
  final ClockService _clockService;
  final RhythmFilter _rhythmFilter;
  final Random _random;

  QuoteEngineResult getQuotes({
    required List<MoodType> selectedMoods,
    required UserProfile profile,
    required TimeBucket timeBucket,
    required double refreshRate,
  }) {
    final target = _comboMatrix.resolve(selectedMoods);
    final adjustedTags = _clockService.adjustTags(target.tags, timeBucket);
    final energy = aggregateMoodEnergy(target.moods);
    final rhythmRange = _rhythmFilter.rangeFor(energy);
    final excludedIds = profile.lastShownQuoteIds.toSet();
    var resetHistory = false;

    var scored = _scoreAll(
      selectedMoods: target.moods,
      targetTags: adjustedTags,
      profile: profile,
      rhythmRange: rhythmRange,
      refreshRate: refreshRate,
      excludedIds: excludedIds,
    );

    if (scored.isEmpty) {
      resetHistory = true;
      scored = _scoreAll(
        selectedMoods: target.moods,
        targetTags: adjustedTags,
        profile: profile.copyWith(
          lastShownQuoteIds: const [],
          lastShownAtByQuoteId: const {},
        ),
        rhythmRange: rhythmRange,
        refreshRate: refreshRate,
        excludedIds: const {},
      );
    }

    var usedFallback = false;
    if (scored.isEmpty) {
      usedFallback = true;
      scored = [
        for (final id in _repository.globalTopIds())
          if (_repository.quoteById(id) case final quote?)
            _ScoredQuote(quote, max(quote.popularity, 1).toDouble()),
      ];
    }

    if (scored.isEmpty) {
      final quote = _repository.allQuotes.first;
      return QuoteEngineResult(
        quote: quote,
        gradientArc: [quote],
        usedFallback: true,
        resetHistory: resetHistory,
      );
    }

    final mirrorMode = profile.frustrationIndex > 4;
    if (mirrorMode) {
      final mirror = scored
          .where(
            (item) => target.moods.any(
              (mood) =>
                  item.quote.effectiveArcTier(mood) == QuoteArcTier.mirror,
            ),
          )
          .toList(growable: false);
      if (mirror.isNotEmpty) {
        scored = mirror;
      }
    }

    final arc = mirrorMode
        ? scored.take(3).map((item) => item.quote).toList(growable: false)
        : _buildGradientArc(scored, target.moods);
    final quote = _weightedPick(
      scored.take(min(12, scored.length)).toList(growable: false),
    );
    return QuoteEngineResult(
      quote: quote,
      gradientArc: arc.isEmpty ? [quote] : arc,
      usedFallback: usedFallback,
      resetHistory: resetHistory,
    );
  }

  List<_ScoredQuote> _scoreAll({
    required List<MoodType> selectedMoods,
    required Set<String> targetTags,
    required UserProfile profile,
    required RhythmRange rhythmRange,
    required double refreshRate,
    required Set<String> excludedIds,
  }) {
    final scored = <_ScoredQuote>[];
    for (final quote in _repository.allQuotes) {
      if (excludedIds.contains(quote.id)) {
        continue;
      }
      if (!rhythmRange.matches(quote.rhythmScore)) {
        continue;
      }
      final moodStrength = _effectiveMoodStrengthForMoods(quote, selectedMoods);
      if (moodStrength <= 0.25) {
        continue;
      }
      final score = _scoreQuote(
        quote: quote,
        selectedMoods: selectedMoods,
        targetTags: targetTags,
        profile: profile,
        refreshRate: refreshRate,
        moodStrength: moodStrength,
      );
      if (score > 0) {
        scored.add(_ScoredQuote(quote, score));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  double _scoreQuote({
    required QuoteEntry quote,
    required List<MoodType> selectedMoods,
    required Set<String> targetTags,
    required UserProfile profile,
    required double refreshRate,
    required double moodStrength,
  }) {
    final popularity = max(quote.popularity, 1).toDouble();
    final quoteTags = quote.tags.map((tag) => tag.toLowerCase()).toSet();
    final targetOverlap = quoteTags.intersection(targetTags).length;
    final targetBoost = targetTags.isEmpty
        ? 0.0
        : targetOverlap / targetTags.length;
    final preferenceBoost = quoteTags.fold<double>(
      0,
      (sum, tag) => sum + (profile.tagPreferenceWeights[tag] ?? 0),
    );
    final likedAuthorBoost = profile.likedAuthors.containsKey(quote.author)
        ? 0.35
        : 0.0;
    final likedTagBoost = _likedTagOverlapRatio(quote, profile);
    final freshness = _freshnessFactor(quote, profile);
    final arcBoost = _arcBoost(quote, selectedMoods);
    final quickRefreshPenalty = refreshRate > 4 ? 0.88 : 1.0;

    return popularity *
        (1 + targetBoost) *
        (1 + likedAuthorBoost * profile.authorWeight) *
        (1 + likedTagBoost * profile.tagWeight) *
        (1 + preferenceBoost.clamp(-0.4, 1.2)) *
        freshness *
        moodStrength *
        arcBoost *
        quickRefreshPenalty;
  }

  List<QuoteEntry> _buildGradientArc(
    List<_ScoredQuote> scored,
    List<MoodType> moods,
  ) {
    final arc = <QuoteEntry>[];
    for (final tier in QuoteArcTier.values) {
      final match = scored
          .where(
            (item) =>
                moods.any((mood) => item.quote.effectiveArcTier(mood) == tier),
          )
          .map((item) => item.quote)
          .firstWhere((quote) => !arc.contains(quote), orElse: () => _empty);
      if (match.id.isNotEmpty) {
        arc.add(match);
      }
    }
    if (arc.isEmpty) {
      return scored.take(3).map((item) => item.quote).toList(growable: false);
    }
    return arc;
  }

  QuoteEntry _weightedPick(List<_ScoredQuote> scored) {
    final total = scored.fold<double>(0, (sum, item) => sum + item.score);
    if (total <= 0) {
      return scored.first.quote;
    }
    var pick = _random.nextDouble() * total;
    for (final item in scored) {
      pick -= item.score;
      if (pick <= 0) {
        return item.quote;
      }
    }
    return scored.last.quote;
  }

  double _effectiveMoodStrengthForMoods(
    QuoteEntry quote,
    List<MoodType> selectedMoods,
  ) {
    return selectedMoods
        .map((mood) => _effectiveMoodStrength(quote, mood))
        .fold<double>(0, max);
  }

  double _effectiveMoodStrength(QuoteEntry quote, MoodType requestedMood) {
    final direct = quote.moodStrength[requestedMood];
    if (direct != null) {
      return direct;
    }
    final adjacent = moodAdjacencyMap[requestedMood] ?? const <MoodType>[];
    final adjacentStrengths = adjacent
        .map((mood) => quote.moodStrength[mood])
        .whereType<double>()
        .toList(growable: false);
    if (adjacentStrengths.isNotEmpty) {
      return adjacentStrengths.reduce(max) * 0.7;
    }
    if (quote.moodStrength.isEmpty) {
      return 0.5;
    }
    return quote.moodStrength.values.reduce(max) * 0.5;
  }

  double _freshnessFactor(QuoteEntry quote, UserProfile profile) {
    final timestamp = profile.lastShownAtByQuoteId[quote.id];
    if (timestamp == null) {
      return 1;
    }
    final lastShown = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final days = DateTime.now().difference(lastShown).inHours / 24;
    return min(1.0, 0.3 + (0.1 * days));
  }

  double _likedTagOverlapRatio(QuoteEntry quote, UserProfile profile) {
    if (quote.tags.isEmpty || profile.likedTagCounts.isEmpty) {
      return 0;
    }
    final overlap = quote.tags.where(profile.likedTagCounts.containsKey).length;
    return overlap == 0 ? 0 : overlap / quote.tags.length;
  }

  double _arcBoost(QuoteEntry quote, List<MoodType> moods) {
    final tiers = moods.map(quote.effectiveArcTier).toSet();
    if (tiers.contains(QuoteArcTier.bridge)) {
      return 1.05;
    }
    if (tiers.contains(QuoteArcTier.window)) {
      return 1.02;
    }
    return 1.0;
  }
}

const _empty = QuoteEntry(
  id: '',
  text: '',
  author: '',
  popularity: 0,
  categories: [],
  tags: [],
  moods: [],
  moodStrength: {},
  poolTier: {},
);

class _ScoredQuote {
  const _ScoredQuote(this.quote, this.score);

  final QuoteEntry quote;
  final double score;
}
