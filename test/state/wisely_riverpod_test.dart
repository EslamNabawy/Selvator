import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisely/src/application/ports/platform_ports.dart';
import 'package:wisely/src/application/state/wisely_controller.dart';
import 'package:wisely/src/domain/entities/catalog_version.dart';
import 'package:wisely/src/domain/entities/mood_journal_entry.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/personalized_greeting.dart';
import 'package:wisely/src/domain/entities/pool_tier.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/session_models.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/domain/repositories/mood_journal_repository.dart';
import 'package:wisely/src/domain/repositories/quote_repository.dart';

void main() {
  test('wisely controller is exposed as Riverpod state', () {
    final container = ProviderContainer(
      overrides: [
        quoteRepositoryProvider.overrideWithValue(_FakeQuoteRepository()),
        moodJournalRepositoryProvider.overrideWithValue(
          _FakeMoodJournalRepository(),
        ),
        quoteWidgetPortProvider.overrideWithValue(_FakeQuoteWidget()),
        trayPortProvider.overrideWithValue(_FakeTray()),
        quoteActionsPortProvider.overrideWithValue(_FakeQuoteActions()),
        appExitPortProvider.overrideWithValue(_FakeAppExit()),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(wiselyControllerProvider);

    expect(state.selectedMood, MoodType.happy);
    expect(state.selectedMoods, const [MoodType.happy]);
    expect(state.isInitialized, isFalse);
    expect(state.isLoading, isFalse);
  });

  test(
    'saveMoodJournalNote trims note and refreshes selected mood state',
    () async {
      final journalRepository = _FakeMoodJournalRepository();
      final container = ProviderContainer(
        overrides: [
          quoteRepositoryProvider.overrideWithValue(_FakeQuoteRepository()),
          moodJournalRepositoryProvider.overrideWithValue(journalRepository),
          quoteWidgetPortProvider.overrideWithValue(_FakeQuoteWidget()),
          trayPortProvider.overrideWithValue(_FakeTray()),
          quoteActionsPortProvider.overrideWithValue(_FakeQuoteActions()),
          appExitPortProvider.overrideWithValue(_FakeAppExit()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(wiselyControllerProvider.notifier)
          .saveMoodJournalNote('  Today felt lighter.  ');

      final state = container.read(wiselyControllerProvider);
      expect(journalRepository.entries, hasLength(1));
      expect(journalRepository.entries.single.note, 'Today felt lighter.');
      expect(journalRepository.entries.single.mood, MoodType.happy);
      expect(state.recentJournalEntries, hasLength(1));
      expect(state.recentJournalEntries.single.note, 'Today felt lighter.');
    },
  );

  test('blank journal notes are ignored and delete refreshes state', () async {
    final journalRepository = _FakeMoodJournalRepository();
    final container = ProviderContainer(
      overrides: [
        quoteRepositoryProvider.overrideWithValue(_FakeQuoteRepository()),
        moodJournalRepositoryProvider.overrideWithValue(journalRepository),
        quoteWidgetPortProvider.overrideWithValue(_FakeQuoteWidget()),
        trayPortProvider.overrideWithValue(_FakeTray()),
        quoteActionsPortProvider.overrideWithValue(_FakeQuoteActions()),
        appExitPortProvider.overrideWithValue(_FakeAppExit()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(wiselyControllerProvider.notifier);

    await controller.saveMoodJournalNote('   ');
    expect(journalRepository.entries, isEmpty);

    await controller.saveMoodJournalNote('Keep this');
    final entryId = container
        .read(wiselyControllerProvider)
        .recentJournalEntries
        .single
        .id;

    await controller.deleteMoodJournalEntry(entryId);

    expect(
      container.read(wiselyControllerProvider).recentJournalEntries,
      isEmpty,
    );
  });

  test('toggleMoodSelection caps selected moods', () async {
    final quoteRepository = _FakeQuoteRepository();
    final container = ProviderContainer(
      overrides: [
        quoteRepositoryProvider.overrideWithValue(quoteRepository),
        moodJournalRepositoryProvider.overrideWithValue(
          _FakeMoodJournalRepository(),
        ),
        quoteWidgetPortProvider.overrideWithValue(_FakeQuoteWidget()),
        trayPortProvider.overrideWithValue(_FakeTray()),
        quoteActionsPortProvider.overrideWithValue(_FakeQuoteActions()),
        appExitPortProvider.overrideWithValue(_FakeAppExit()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(wiselyControllerProvider.notifier);

    await controller.toggleMoodSelection(MoodType.calm);
    await controller.toggleMoodSelection(MoodType.motivated);
    await controller.toggleMoodSelection(MoodType.love);

    final state = container.read(wiselyControllerProvider);
    expect(state.selectedMoods, hasLength(maxSelectedMoodSelections));
    expect(state.selectedMoods, isNot(contains(MoodType.love)));
  });

  test('completeOnboarding saves gender and generates greeting', () async {
    final quoteRepository = _FakeQuoteRepository();
    final container = ProviderContainer(
      overrides: [
        quoteRepositoryProvider.overrideWithValue(quoteRepository),
        moodJournalRepositoryProvider.overrideWithValue(
          _FakeMoodJournalRepository(),
        ),
        quoteWidgetPortProvider.overrideWithValue(_FakeQuoteWidget()),
        trayPortProvider.overrideWithValue(_FakeTray()),
        quoteActionsPortProvider.overrideWithValue(_FakeQuoteActions()),
        appExitPortProvider.overrideWithValue(_FakeAppExit()),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(wiselyControllerProvider.notifier)
        .completeOnboarding(
          displayName: 'Karim',
          gender: UserGender.male,
          preferredMoods: const [MoodType.happy],
        );

    final state = container.read(wiselyControllerProvider);
    expect(quoteRepository.profile.gender, UserGender.male);
    expect(state.profile.hasGreetingProfile, isTrue);
    expect(state.homeGreeting, isNot(PersonalizedGreeting.fallback));
  });

  test('existing onboarded profile without gender needs completion', () async {
    final quoteRepository = _FakeQuoteRepository(
      profile: UserProfile.initial().copyWith(
        displayName: 'Existing',
        preferredMoods: const [MoodType.happy],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        quoteRepositoryProvider.overrideWithValue(quoteRepository),
        moodJournalRepositoryProvider.overrideWithValue(
          _FakeMoodJournalRepository(),
        ),
        quoteWidgetPortProvider.overrideWithValue(_FakeQuoteWidget()),
        trayPortProvider.overrideWithValue(_FakeTray()),
        quoteActionsPortProvider.overrideWithValue(_FakeQuoteActions()),
        appExitPortProvider.overrideWithValue(_FakeAppExit()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(wiselyControllerProvider.notifier).initialize();

    final state = container.read(wiselyControllerProvider);
    expect(state.profile.isOnboarded, isTrue);
    expect(state.profile.hasGreetingProfile, isFalse);
    expect(state.homeGreeting, PersonalizedGreeting.fallback);
  });

  test('low mood onboarding stages quote behind decompression', () async {
    final quoteRepository = _FakeQuoteRepository();
    final container = ProviderContainer(
      overrides: [
        quoteRepositoryProvider.overrideWithValue(quoteRepository),
        moodJournalRepositoryProvider.overrideWithValue(
          _FakeMoodJournalRepository(),
        ),
        quoteWidgetPortProvider.overrideWithValue(_FakeQuoteWidget()),
        trayPortProvider.overrideWithValue(_FakeTray()),
        quoteActionsPortProvider.overrideWithValue(_FakeQuoteActions()),
        appExitPortProvider.overrideWithValue(_FakeAppExit()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(wiselyControllerProvider.notifier);
    await controller.completeOnboarding(
      displayName: 'Mona',
      gender: UserGender.female,
      preferredMoods: const [MoodType.tired],
    );

    var state = container.read(wiselyControllerProvider);
    expect(state.isDecompressing, isTrue);
    expect(state.pendingQuote, isNotNull);
    expect(state.currentQuote, isNull);

    await controller.completeDecompression();
    state = container.read(wiselyControllerProvider);
    expect(state.isDecompressing, isFalse);
    expect(state.currentQuote, isNotNull);
  });
}

class _FakeQuoteRepository implements QuoteRepository {
  _FakeQuoteRepository({UserProfile? profile})
    : _quotes = [
        _quote('happy', MoodType.happy),
        _quote('calm', MoodType.calm),
        _quote('motivated', MoodType.motivated),
        _quote('love', MoodType.love),
        _quote('tired', MoodType.tired),
      ],
      _profile = profile ?? UserProfile.initial();

  UserProfile _profile;
  final List<QuoteEntry> _quotes;

  @override
  UserProfile get profile => _profile;

  @override
  SessionAggregates get sessionAggregates => SessionAggregates.initial();

  @override
  CatalogVersion? get catalogVersion => null;

  @override
  List<QuoteEntry> get allQuotes => _quotes;

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
  List<QuoteEntry> quotesByAuthor(String author) {
    return _quotes.where((quote) => quote.author == author).toList();
  }

  @override
  List<QuoteEntry> searchQuotes(String query, {int limit = 24}) => const [];

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
  }

  @override
  Future<void> saveSessionAggregates(SessionAggregates aggregates) async {}

  @override
  Future<void> clearUserData() async {
    _profile = UserProfile.initial();
  }
}

QuoteEntry _quote(String id, MoodType mood) {
  return QuoteEntry(
    id: id,
    text: 'A test quote for ${mood.label}.',
    author: 'Test Author',
    popularity: 100,
    categories: [mood.name],
    tags: [mood.name],
    moods: [mood],
    moodStrength: {mood: 1},
    poolTier: {mood: PoolTier.core},
  );
}

class _FakeMoodJournalRepository implements MoodJournalRepository {
  final List<MoodJournalEntry> entries = [];

  @override
  Future<void> initialize() async {}

  @override
  List<MoodJournalEntry> recentEntries({MoodType? mood, int limit = 5}) {
    final filtered =
        entries.where((entry) => mood == null || entry.mood == mood).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered.take(limit).toList(growable: false);
  }

  @override
  Future<void> saveEntry({required MoodType mood, required String note}) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final now = DateTime.now();
    entries.add(
      MoodJournalEntry(
        id: 'entry-${entries.length}',
        mood: mood,
        note: trimmed,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> deleteEntry(String id) async {
    entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<void> clearEntries() async {
    entries.clear();
  }
}

class _FakeQuoteWidget implements QuoteWidgetPort {
  @override
  bool get isSupported => true;

  @override
  Future<void> syncQuote({
    required QuoteEntry quote,
    required MoodType mood,
  }) async {}
}

class _FakeTray implements TrayPort {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> update({
    required String previewText,
    required MoodType selectedMood,
  }) async {}
}

class _FakeQuoteActions implements QuoteActionsPort {
  @override
  Future<void> copyQuote(QuoteEntry quote) async {}

  @override
  Future<void> shareQuote(QuoteEntry quote) async {}
}

class _FakeAppExit implements AppExitPort {
  @override
  Never quit() => throw StateError('quit not expected');
}
