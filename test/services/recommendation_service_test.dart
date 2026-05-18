import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/pool_tier.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/domain/repositories/quote_repository.dart';
import 'package:wisely/src/domain/services/recommendation_service.dart';

void main() {
  group('recommendation service', () {
    late QuoteEntry happyCoreA;
    late QuoteEntry happyCoreB;
    late QuoteEntry happyExtended;
    late QuoteEntry calmGlobal;
    late _FakeQuoteRepository repository;
    late RecommendationService service;

    setUp(() {
      happyCoreA = _quote(
        id: 'q1',
        mood: MoodType.happy,
        tier: PoolTier.core,
        popularity: 100,
        author: 'Author One',
      );
      happyCoreB = _quote(
        id: 'q2',
        mood: MoodType.happy,
        tier: PoolTier.core,
        popularity: 90,
        author: 'Author Two',
      );
      happyExtended = _quote(
        id: 'q3',
        mood: MoodType.happy,
        tier: PoolTier.extended,
        popularity: 85,
        author: 'Author Three',
      );
      calmGlobal = _quote(
        id: 'q4',
        mood: MoodType.calm,
        tier: PoolTier.core,
        popularity: 95,
        author: 'Author Four',
      );

      repository = _FakeQuoteRepository(
        allQuotes: [happyCoreA, happyCoreB, happyExtended, calmGlobal],
        moodIndex: {
          'happy_core': ['q1', 'q2'],
          'happy_extended': ['q3'],
          'calm_core': ['q4'],
          'calm_extended': const [],
          QuoteRepository.globalTopKey: ['q4', 'q2', 'q3'],
        },
      );
      service = RecommendationService(
        repository: repository,
        random: Random(3),
      );
    });

    test('excludes the recent history list when choosing the next quote', () {
      final profile = UserProfile.initial().copyWith(
        preferredMoods: const [MoodType.happy],
        lastShownQuoteIds: const ['q1'],
        lastShownAtByQuoteId: {'q1': DateTime.now().millisecondsSinceEpoch},
      );

      final result = service.nextQuote(
        mood: MoodType.happy,
        profile: profile,
        refreshRate: 0,
      );

      expect(result.quote.id, isNot('q1'));
    });

    test(
      'scores outside the direct mood pool when mood history is exhausted',
      () {
        final profile = UserProfile.initial().copyWith(
          preferredMoods: const [MoodType.happy],
          lastShownQuoteIds: const ['q1', 'q2', 'q3'],
          lastShownAtByQuoteId: {
            'q1': DateTime.now().millisecondsSinceEpoch,
            'q2': DateTime.now().millisecondsSinceEpoch,
            'q3': DateTime.now().millisecondsSinceEpoch,
          },
        );

        final result = service.nextQuote(
          mood: MoodType.happy,
          profile: profile,
          refreshRate: 0,
        );

        expect(result.usedFallback, isFalse);
        expect(result.quote.id, 'q4');
      },
    );

    test('accepts multiple selected moods when choosing a quote', () {
      final profile = UserProfile.initial().copyWith(
        preferredMoods: const [MoodType.happy, MoodType.calm],
        lastShownQuoteIds: const ['q1', 'q2', 'q3'],
        lastShownAtByQuoteId: {
          'q1': DateTime.now().millisecondsSinceEpoch,
          'q2': DateTime.now().millisecondsSinceEpoch,
          'q3': DateTime.now().millisecondsSinceEpoch,
        },
      );

      final result = service.nextQuoteForMoods(
        moods: const [MoodType.happy, MoodType.calm],
        profile: profile,
        refreshRate: 0,
      );

      expect(result.quote.id, 'q4');
      expect(result.quote.belongsToMood(MoodType.calm), isTrue);
    });

    test('applies daily decay and clamps adaptive weights', () {
      final profile = UserProfile.initial().copyWith(
        themeMode: AppThemeMode.dark,
        authorWeight: 1,
        tagWeight: 1,
        lastDecayDate: DateTime.now().subtract(const Duration(days: 2)),
      );

      final decayed = service.applyDailyDecay(profile, DateTime.now());

      expect(decayed.authorWeight, closeTo(0.9604, 0.0001));
      expect(decayed.tagWeight, closeTo(0.9801, 0.0001));
    });

    test('does not decay adaptive weights for a fresh profile', () {
      final profile = UserProfile.initial();
      final today = DateTime(2026, 5, 17);

      final decayed = service.applyDailyDecay(profile, today);

      expect(decayed.authorWeight, profile.authorWeight);
      expect(decayed.tagWeight, profile.tagWeight);
      expect(decayed.lastDecayDate, today);
    });

    test('reduces tag weight after five consecutive boosted skips', () {
      var profile = UserProfile.initial().copyWith(
        likedTagCounts: const {'hope': 3},
        tagWeight: 0.55,
      );
      final quote = _quote(
        id: 'tagged',
        mood: MoodType.hopeful,
        tier: PoolTier.core,
        popularity: 100,
        author: 'Tag Author',
        tags: const ['hope'],
      );

      for (var index = 0; index < 5; index++) {
        profile = service.recordSkip(
          profile: profile,
          quote: quote,
          mood: MoodType.hopeful,
        );
      }

      expect(profile.tagWeight, closeTo(0.52, 0.0001));
      expect(profile.consecutiveTagBoostedSkips, 0);
    });
  });
}

QuoteEntry _quote({
  required String id,
  required MoodType mood,
  required PoolTier tier,
  required int popularity,
  required String author,
  List<String> tags = const ['joy'],
}) {
  return QuoteEntry(
    id: id,
    text: 'A steady quote designed for testing recommendation behavior.',
    author: author,
    popularity: popularity,
    categories: [mood.name],
    tags: tags,
    moods: [mood],
    moodStrength: {mood: 1},
    poolTier: {mood: tier},
  );
}

class _FakeQuoteRepository extends QuoteRepository {
  _FakeQuoteRepository({
    required List<QuoteEntry> allQuotes,
    required Map<String, List<String>> moodIndex,
  }) : _allQuotes = allQuotes,
       _moodIndex = moodIndex,
       _quoteById = {for (final quote in allQuotes) quote.id: quote};

  final List<QuoteEntry> _allQuotes;
  final Map<String, List<String>> _moodIndex;
  final Map<String, QuoteEntry> _quoteById;

  @override
  List<QuoteEntry> get allQuotes => _allQuotes;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  List<String> globalTopIds() =>
      _moodIndex[QuoteRepository.globalTopKey] ?? const [];

  @override
  List<String> moodPoolIds(MoodType mood, PoolTier tier) =>
      _moodIndex['${mood.name}_${tier.name}'] ?? const [];

  @override
  QuoteEntry? quoteById(String id) => _quoteById[id];
}
