import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wisely/src/domain/entities/catalog_version.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/pool_tier.dart';
import 'package:wisely/src/domain/entities/quote_arc_tier.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/session_models.dart';
import 'package:wisely/src/domain/entities/tide_season.dart';
import 'package:wisely/src/domain/entities/time_bucket.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/domain/repositories/quote_repository.dart';
import 'package:wisely/src/domain/services/clock_service.dart';
import 'package:wisely/src/domain/services/echo_guard.dart';
import 'package:wisely/src/domain/services/preference_engine.dart';
import 'package:wisely/src/domain/services/quote_engine.dart';
import 'package:wisely/src/domain/services/streak_service.dart';
import 'package:wisely/src/domain/services/tide_service.dart';

void main() {
  test('clock service resolves all time buckets', () {
    const service = ClockService();

    expect(service.bucketFor(DateTime(2026, 5, 18, 8)), TimeBucket.morning);
    expect(service.bucketFor(DateTime(2026, 5, 18, 14)), TimeBucket.afternoon);
    expect(service.bucketFor(DateTime(2026, 5, 18, 20)), TimeBucket.night);
    expect(service.bucketFor(DateTime(2026, 5, 18, 2)), TimeBucket.lateNight);
  });

  test('quote engine applies history, mirror mode, and gradient arc', () {
    final mirror = _quote(
      id: 'mirror',
      mood: MoodType.sad,
      tier: QuoteArcTier.mirror,
      rhythmScore: 35,
      tags: const ['sadness', 'grief'],
    );
    final bridge = _quote(
      id: 'bridge',
      mood: MoodType.sad,
      tier: QuoteArcTier.bridge,
      rhythmScore: 40,
      tags: const ['life', 'wisdom'],
    );
    final window = _quote(
      id: 'window',
      mood: MoodType.sad,
      tier: QuoteArcTier.window,
      rhythmScore: 45,
      tags: const ['hope', 'future'],
    );
    final engine = QuoteEngine(
      repository: _FakeQuoteRepository([mirror, bridge, window]),
      random: Random(1),
    );

    final result = engine.getQuotes(
      selectedMoods: const [MoodType.sad],
      profile: UserProfile.initial().copyWith(
        lastShownQuoteIds: const ['bridge'],
        frustrationIndex: 6,
      ),
      timeBucket: TimeBucket.night,
      refreshRate: 0,
    );

    expect(result.quote.effectiveArcTier(MoodType.sad), QuoteArcTier.mirror);
    expect(result.gradientArc, isNotEmpty);
    expect(result.gradientArc.any((quote) => quote.id == 'bridge'), isFalse);
  });

  test('preference engine boosts dwell and penalizes quick refresh', () {
    const service = PreferenceEngine();
    final quote = _quote(
      id: 'q',
      mood: MoodType.hopeful,
      tier: QuoteArcTier.window,
      rhythmScore: 50,
      tags: const ['hope'],
    );

    final boosted = service.recordDwellCompleted(
      profile: UserProfile.initial().copyWith(frustrationIndex: 2),
      quote: quote,
    );
    expect(boosted.tagPreferenceWeights['hope'], closeTo(0.3, 0.0001));
    expect(boosted.frustrationIndex, 1);

    final penalized = service.recordQuickRefresh(
      profile: boosted,
      quote: quote,
    );
    expect(penalized.tagPreferenceWeights['hope'], closeTo(0.2, 0.0001));
    expect(penalized.frustrationIndex, 2);
  });

  test('tide, streak, and echo guard evaluate local profile history', () {
    final now = DateTime(2026, 5, 18, 9);
    final profile = UserProfile.initial().copyWith(
      lastOpenAt: now.subtract(const Duration(days: 3)),
      lastMoodTags: const ['sad', 'grief'],
      recentMoodTrail: const [MoodType.sad, MoodType.lonely, MoodType.stressed],
      moodDailyCounts30d: {'2026-05-17|sad': 3, '2026-05-18|lonely': 2},
    );

    final streak = const StreakService().evaluate(profile, now);
    expect(streak.greetingOverride, contains('streak is safe'));
    expect(streak.profile.streak, 0);

    final tide = const TideService().checkSnapshot(profile, now);
    expect(tide.season, TideSeason.stormy);

    final echo = const EchoGuard().evaluate(profile);
    expect(echo.shouldDecompress, isTrue);
  });
}

QuoteEntry _quote({
  required String id,
  required MoodType mood,
  required QuoteArcTier tier,
  required int rhythmScore,
  required List<String> tags,
}) {
  return QuoteEntry(
    id: id,
    text: 'A steady quote for testing the sophisticated engine.',
    author: 'Test Author',
    popularity: id == 'mirror' ? 120 : 100,
    categories: [mood.name],
    tags: tags,
    moods: [mood],
    moodStrength: {mood: 1},
    poolTier: {mood: PoolTier.core},
    rhythmScore: rhythmScore,
    arcTierByMood: {mood: tier},
  );
}

class _FakeQuoteRepository implements QuoteRepository {
  _FakeQuoteRepository(this._quotes);

  final List<QuoteEntry> _quotes;

  @override
  List<QuoteEntry> get allQuotes => _quotes;

  @override
  UserProfile get profile => UserProfile.initial();

  @override
  SessionAggregates get sessionAggregates => SessionAggregates.initial();

  @override
  CatalogVersion? get catalogVersion => null;

  @override
  Future<void> initialize() async {}

  @override
  QuoteEntry? quoteById(String id) {
    for (final quote in _quotes) {
      if (quote.id == id) {
        return quote;
      }
    }
    return null;
  }

  @override
  List<QuoteEntry> quotesByIds(Iterable<String> ids) {
    final idSet = ids.toSet();
    return _quotes.where((quote) => idSet.contains(quote.id)).toList();
  }

  @override
  List<String> moodPoolIds(MoodType mood, PoolTier tier) {
    return _quotes
        .where((quote) => quote.poolTier[mood] == tier)
        .map((quote) => quote.id)
        .toList();
  }

  @override
  List<String> globalTopIds() => _quotes.map((quote) => quote.id).toList();

  @override
  List<QuoteEntry> quotesByAuthor(String author) => const [];

  @override
  List<QuoteEntry> searchQuotes(String query, {int limit = 24}) => const [];

  @override
  Future<void> saveProfile(UserProfile profile) async {}

  @override
  Future<void> saveSessionAggregates(SessionAggregates aggregates) async {}

  @override
  Future<void> clearUserData() async {}
}
