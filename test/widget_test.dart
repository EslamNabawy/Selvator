import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisely/src/application/ports/platform_ports.dart';
import 'package:wisely/src/application/state/wisely_controller.dart';
import 'package:wisely/src/domain/entities/catalog_version.dart';
import 'package:wisely/src/domain/entities/decompress_state.dart';
import 'package:wisely/src/domain/entities/emotional_weather_point.dart';
import 'package:wisely/src/domain/entities/mood_journal_entry.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/personalized_greeting.dart';
import 'package:wisely/src/domain/entities/pool_tier.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/session_models.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/domain/repositories/mood_journal_repository.dart';
import 'package:wisely/src/domain/repositories/quote_repository.dart';
import 'package:wisely/src/presentation/screens/root_shell.dart';
import 'package:wisely/src/presentation/theme/wisely_theme.dart';
import 'package:wisely/src/presentation/widgets/mood_chip_row.dart';
import 'package:wisely/src/presentation/widgets/quote_card.dart';
import 'package:wisely/src/presentation/widgets/silvator_mascot_avatar.dart';

void main() {
  testWidgets('onboarding renders male and female greeting style choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          quoteRepositoryProvider.overrideWithValue(_NoopQuoteRepository()),
          moodJournalRepositoryProvider.overrideWithValue(
            _NoopMoodJournalRepository(),
          ),
          quoteWidgetPortProvider.overrideWithValue(_NoopQuoteWidget()),
          trayPortProvider.overrideWithValue(_NoopTray()),
          quoteActionsPortProvider.overrideWithValue(_NoopQuoteActions()),
          appExitPortProvider.overrideWithValue(_NoopAppExit()),
        ],
        child: MaterialApp(
          theme: WiselyTheme.light(),
          home: const OnboardingScreen(),
        ),
      ),
    );

    expect(find.text('Your greeting style'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
  });

  testWidgets('mood chip row renders expanded mood catalog', (tester) async {
    MoodType? selectedMood;
    await tester.pumpWidget(
      MaterialApp(
        theme: WiselyTheme.light(),
        home: Scaffold(
          body: MoodChipRow(
            selectedMood: MoodType.happy,
            selectedMoods: const [MoodType.happy],
            maxSelectedMoods: maxSelectedMoodSelections,
            onMoodSelected: (mood) => selectedMood = mood,
          ),
        ),
      ),
    );

    expect(find.text('Happy'), findsWidgets);
    expect(find.text('Calm'), findsWidgets);
    expect(find.text('Grateful'), findsWidgets);
    expect(find.byKey(const Key('silvator-mascot-happy')), findsWidgets);

    await tester.tap(find.text('Calm').first);
    expect(selectedMood, MoodType.calm);
  });

  testWidgets('desktop mood chip row exposes carousel arrows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WiselyTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 760,
            child: MoodChipRow(
              selectedMood: MoodType.happy,
              selectedMoods: const [MoodType.happy],
              maxSelectedMoods: maxSelectedMoodSelections,
              onMoodSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('More moods'), findsOneWidget);

    await tester.tap(find.byTooltip('More moods'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Previous moods'), findsOneWidget);
  });

  testWidgets('home hero renders selected mood mascot and updates on rebuild', (
    tester,
  ) async {
    final controller = _FakeWiselyController(
      currentQuote: _quote(id: 'current'),
      quoteOfDay: null,
    );
    addTearDown(controller.dispose);

    await _pumpHome(tester, controller);
    expect(find.text('Hey legend, test'), findsOneWidget);
    expect(find.text('How is the mood landing today?'), findsOneWidget);
    expect(
      tester
          .widget<SilvatorMascotAvatar>(
            find.byKey(const Key('home-hero-mascot')),
          )
          .mood,
      MoodType.happy,
    );

    controller
      ..selectedMood = MoodType.calm
      ..selectedMoods = [MoodType.calm]
      ..homeGreeting = const PersonalizedGreeting(
        salutation: 'Easy now, test',
        headline: 'Calm gets the front seat.',
        body: 'Selvator is keeping the page soft.',
      );
    await _pumpHome(tester, controller);

    expect(find.text('Easy now, test'), findsOneWidget);
    expect(find.text('Calm gets the front seat.'), findsOneWidget);
    expect(
      tester
          .widget<SilvatorMascotAvatar>(
            find.byKey(const Key('home-hero-mascot')),
          )
          .mood,
      MoodType.calm,
    );
  });

  testWidgets('quote of the day actions target the quote of the day', (
    tester,
  ) async {
    final currentQuote = _quote(id: 'current');
    final quoteOfDay = _quote(id: 'daily');
    final controller = _FakeWiselyController(
      currentQuote: currentQuote,
      quoteOfDay: quoteOfDay,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: WiselyTheme.light(),
        home: Scaffold(
          body: HomeScreen(
            controller: controller,
            showDesktopSearch: false,
            tablet: false,
            onOpenDetails: (_) {},
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Quote of the day'));
    final quoteOfDayCard = find.ancestor(
      of: find.text('Quote of the day'),
      matching: find.byType(QuoteCard),
    );

    await tester.tap(
      find.descendant(
        of: quoteOfDayCard,
        matching: find.byIcon(Icons.favorite_border_rounded),
      ),
    );
    await tester.tap(
      find.descendant(
        of: quoteOfDayCard,
        matching: find.widgetWithText(OutlinedButton, 'Copy'),
      ),
    );
    await tester.tap(
      find.descendant(
        of: quoteOfDayCard,
        matching: find.widgetWithText(OutlinedButton, 'Share'),
      ),
    );

    expect(controller.likedQuote, same(quoteOfDay));
    expect(controller.copiedQuote, same(quoteOfDay));
    expect(controller.sharedQuote, same(quoteOfDay));
  });

  testWidgets('home supports multi-mood selection and quote refresh', (
    tester,
  ) async {
    final controller = _FakeWiselyController(
      currentQuote: _quote(id: 'current'),
      quoteOfDay: null,
    );
    addTearDown(controller.dispose);

    await _pumpHome(tester, controller);

    await tester.tap(find.text('Calm').first);
    await tester.pump();

    expect(controller.selectedMoods, contains(MoodType.calm));
    expect(controller.selectedMood, MoodType.calm);

    final refreshButton = find.widgetWithText(OutlinedButton, 'New quote');
    await tester.ensureVisible(refreshButton);
    await tester.tap(refreshButton);
    await tester.pump();

    expect(controller.refreshed, isTrue);
  });

  testWidgets('home hides Android widget action when widgets are unsupported', (
    tester,
  ) async {
    final controller = _FakeWiselyController(
      currentQuote: _quote(id: 'current'),
      quoteOfDay: null,
      supportsHomeWidgets: false,
    );
    addTearDown(controller.dispose);

    await _pumpHome(tester, controller);

    expect(find.text('Update widget'), findsNothing);
  });

  testWidgets('home mood selection stops at the mood limit', (tester) async {
    final controller = _FakeWiselyController(
      currentQuote: _quote(id: 'current'),
      quoteOfDay: null,
    );
    addTearDown(controller.dispose);

    await _pumpHome(tester, controller);

    await tester.tap(find.text('Calm').first);
    await tester.tap(find.text('Motivated').first);
    await tester.pump();

    expect(controller.selectedMoods, hasLength(maxSelectedMoodSelections));

    await tester.tap(find.text('Love').first);
    await tester.pump();

    expect(controller.selectedMoods, hasLength(maxSelectedMoodSelections));
    expect(controller.selectedMoods, isNot(contains(MoodType.love)));
  });

  testWidgets('journal page saves and deletes notes', (tester) async {
    final entry = MoodJournalEntry(
      id: 'journal-1',
      mood: MoodType.happy,
      note: 'Existing happy note',
      createdAt: DateTime(2026, 5, 17, 9),
      updatedAt: DateTime(2026, 5, 17, 9),
    );
    final controller = _FakeWiselyController(
      currentQuote: _quote(id: 'current'),
      quoteOfDay: null,
      recentJournalEntries: [entry],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: WiselyTheme.light(),
        home: Scaffold(
          body: HomeScreen(
            controller: controller,
            showDesktopSearch: false,
            tablet: false,
            onOpenDetails: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Mood journal'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: WiselyTheme.light(),
        home: Scaffold(body: JournalScreen(controller: controller)),
      ),
    );

    expect(find.text('Mood journal'), findsOneWidget);
    expect(find.text('Existing happy note'), findsOneWidget);

    final saveButton = find.text('Save note');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pump();
    expect(controller.savedNote, isNull);

    await tester.enterText(
      find.byKey(const Key('mood-journal-note-field')),
      '  New happy note  ',
    );
    await tester.pump();
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pump();

    expect(controller.savedNote, '  New happy note  ');
    expect(find.text('New happy note'), findsOneWidget);

    final deleteButton = find.byTooltip('Delete note').last;
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pump();

    expect(controller.deletedEntryId, 'journal-1');
    expect(find.text('Existing happy note'), findsNothing);
  });

  testWidgets('decompression screen hides pending quote until completion', (
    tester,
  ) async {
    final controller = _FakeWiselyController(
      currentQuote: null,
      quoteOfDay: null,
      isDecompressing: true,
      pendingQuote: _quote(id: 'pending'),
      pendingQuoteMood: MoodType.sad,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: WiselyTheme.light(),
        home: Scaffold(body: DecompressScreen(controller: controller)),
      ),
    );

    expect(find.textContaining('Stay with the breath'), findsOneWidget);
    expect(find.text('Skip breathing'), findsOneWidget);
    expect(
      find.text('A steady quote designed for widget testing action callbacks.'),
      findsNothing,
    );

    await tester.tap(find.text('Skip breathing'));
    await tester.pump();

    expect(controller.decompressionCompleted, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('journal renders emotional weather chart', (tester) async {
    final controller = _FakeWiselyController(
      currentQuote: _quote(id: 'current'),
      quoteOfDay: null,
      emotionalWeather: [
        EmotionalWeatherPoint(
          date: DateTime(2026, 5, 18),
          mood: MoodType.happy,
          count: 2,
          intensity: 0.4,
        ),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: WiselyTheme.light(),
        home: Scaffold(body: JournalScreen(controller: controller)),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Emotional weather'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Emotional weather'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('mobile home renders mascot layout without overflow', (
    tester,
  ) async {
    final controller = _FakeWiselyController(
      currentQuote: _quote(id: 'current'),
      quoteOfDay: _quote(id: 'daily'),
    );
    addTearDown(controller.dispose);
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;

    await _pumpHome(tester, controller);

    expect(find.byKey(const Key('home-hero-mascot')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile app surfaces render at phone width without overflow', (
    tester,
  ) async {
    final controller = _FakeWiselyController(
      currentQuote: _quote(id: 'current'),
      quoteOfDay: _quote(id: 'daily'),
      recentJournalEntries: [
        MoodJournalEntry(
          id: 'mobile-entry',
          mood: MoodType.happy,
          note:
              'A longer mobile journal note that should wrap cleanly inside the card.',
          createdAt: DateTime(2026, 5, 17, 9),
          updatedAt: DateTime(2026, 5, 17, 9),
        ),
      ],
    );
    addTearDown(controller.dispose);
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;

    await _pumpPhoneSurface(
      tester,
      HomeScreen(
        controller: controller,
        showDesktopSearch: false,
        tablet: false,
        onOpenDetails: (_) {},
      ),
    );
    expect(tester.takeException(), isNull);

    await _pumpPhoneSurface(tester, JournalScreen(controller: controller));
    expect(tester.takeException(), isNull);

    await _pumpPhoneSurface(
      tester,
      FavoritesHistoryScreen(controller: controller, onOpenDetails: (_) {}),
    );
    expect(tester.takeException(), isNull);

    await _pumpPhoneSurface(
      tester,
      SettingsProfileScreen(controller: controller),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mobile onboarding and profile completion render without overflow',
    (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            quoteRepositoryProvider.overrideWithValue(_NoopQuoteRepository()),
            moodJournalRepositoryProvider.overrideWithValue(
              _NoopMoodJournalRepository(),
            ),
            quoteWidgetPortProvider.overrideWithValue(_NoopQuoteWidget()),
            trayPortProvider.overrideWithValue(_NoopTray()),
            quoteActionsPortProvider.overrideWithValue(_NoopQuoteActions()),
            appExitPortProvider.overrideWithValue(_NoopAppExit()),
          ],
          child: MaterialApp(
            theme: WiselyTheme.light(),
            home: const OnboardingScreen(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quoteRepositoryProvider.overrideWithValue(_NoopQuoteRepository()),
            moodJournalRepositoryProvider.overrideWithValue(
              _NoopMoodJournalRepository(),
            ),
            quoteWidgetPortProvider.overrideWithValue(_NoopQuoteWidget()),
            trayPortProvider.overrideWithValue(_NoopTray()),
            quoteActionsPortProvider.overrideWithValue(_NoopQuoteActions()),
            appExitPortProvider.overrideWithValue(_NoopAppExit()),
          ],
          child: MaterialApp(
            theme: WiselyTheme.light(),
            home: const ProfilePersonalizationScreen(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dark home renders without overflow', (tester) async {
    final controller = _FakeWiselyController(
      currentQuote: _quote(id: 'current'),
      quoteOfDay: _quote(id: 'daily'),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: WiselyTheme.light(),
        darkTheme: WiselyTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: HomeScreen(
            controller: controller,
            showDesktopSearch: false,
            tablet: false,
            onOpenDetails: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPhoneSurface(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: WiselyTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

Future<void> _pumpHome(
  WidgetTester tester,
  _FakeWiselyController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: WiselyTheme.light(),
      home: Scaffold(
        body: HomeScreen(
          controller: controller,
          showDesktopSearch: false,
          tablet: false,
          onOpenDetails: (_) {},
        ),
      ),
    ),
  );
}

QuoteEntry _quote({required String id}) {
  return QuoteEntry(
    id: id,
    text: 'A steady quote designed for widget testing action callbacks.',
    author: 'Test Author',
    popularity: 100,
    categories: const ['happy'],
    tags: const ['joy'],
    moods: const [MoodType.happy],
    moodStrength: const {MoodType.happy: 1},
    poolTier: const {MoodType.happy: PoolTier.core},
  );
}

class _FakeWiselyController implements WiselyController {
  _FakeWiselyController({
    required this.currentQuote,
    required this.quoteOfDay,
    List<MoodJournalEntry>? recentJournalEntries,
    List<EmotionalWeatherPoint>? emotionalWeather,
    this.isDecompressing = false,
    this.pendingQuote,
    this.pendingQuoteMood,
    this.supportsHomeWidgets = true,
  }) : searchController = TextEditingController(),
       searchFocusNode = FocusNode(debugLabel: 'fake-search'),
       profile = UserProfile.initial().copyWith(
         displayName: 'Test',
         gender: UserGender.male,
         preferredMoods: const [MoodType.happy],
       ),
       homeGreeting = const PersonalizedGreeting(
         salutation: 'Hey legend, test',
         headline: 'How is the mood landing today?',
         body: 'Selvator brought a warm check-in.',
       ),
       recentJournalEntries = recentJournalEntries ?? <MoodJournalEntry>[],
       emotionalWeather = emotionalWeather ?? <EmotionalWeatherPoint>[];

  @override
  final QuoteEntry? currentQuote;

  @override
  final QuoteEntry? quoteOfDay;

  @override
  final TextEditingController searchController;

  @override
  final FocusNode searchFocusNode;

  @override
  final UserProfile profile;

  @override
  PersonalizedGreeting homeGreeting;

  @override
  final bool supportsHomeWidgets;

  @override
  final bool isDecompressing;

  @override
  final QuoteEntry? pendingQuote;

  @override
  final MoodType? pendingQuoteMood;

  @override
  DecompressState decompressState = DecompressState.inhale;

  @override
  final String? greetingOverride = null;

  @override
  final SessionAggregates sessionAggregates = SessionAggregates.initial();

  @override
  MoodType selectedMood = MoodType.happy;

  @override
  List<MoodType> selectedMoods = [MoodType.happy];

  @override
  final List<MoodJournalEntry> recentJournalEntries;

  @override
  final List<EmotionalWeatherPoint> emotionalWeather;

  QuoteEntry? likedQuote;
  QuoteEntry? copiedQuote;
  QuoteEntry? sharedQuote;
  String? savedNote;
  String? deletedEntryId;
  bool refreshed = false;
  bool decompressionCompleted = false;

  @override
  Future<void> refreshQuote() async {
    refreshed = true;
  }

  @override
  Future<void> selectMood(MoodType mood) async {
    selectedMood = mood;
    selectedMoods = [mood];
  }

  @override
  Future<void> toggleMoodSelection(MoodType mood) async {
    if (selectedMoods.contains(mood) && selectedMoods.length > 1) {
      selectedMoods = selectedMoods
          .where((selectedMood) => selectedMood != mood)
          .toList(growable: false);
      selectedMood = selectedMoods.first;
      return;
    }
    if (!selectedMoods.contains(mood) &&
        selectedMoods.length >= maxSelectedMoodSelections) {
      return;
    }
    if (!selectedMoods.contains(mood)) {
      selectedMoods = [...selectedMoods, mood];
    }
    selectedMood = mood;
  }

  @override
  MoodType displayMoodForQuote(QuoteEntry quote) {
    for (final mood in selectedMoods) {
      if (quote.belongsToMood(mood)) {
        return mood;
      }
    }
    return quote.moods.isEmpty ? selectedMood : quote.moods.first;
  }

  @override
  List<QuoteEntry> favorites({MoodType? mood}) {
    final quote = currentQuote;
    if (quote == null) {
      return const [];
    }
    if (mood != null && !quote.belongsToMood(mood)) {
      return const [];
    }
    return [quote];
  }

  @override
  Future<void> toggleLike([QuoteEntry? target]) async {
    likedQuote = target;
  }

  @override
  Future<void> copyQuote([QuoteEntry? target]) async {
    copiedQuote = target;
  }

  @override
  Future<void> shareQuote([QuoteEntry? target]) async {
    sharedQuote = target;
  }

  @override
  Future<void> sendCurrentQuoteToWidget() async {}

  @override
  void updateDecompressionState(DecompressState decompressState) {
    this.decompressState = decompressState;
  }

  @override
  Future<void> completeDecompression() async {
    decompressionCompleted = true;
  }

  @override
  Future<void> saveMoodJournalNote(String note) async {
    savedNote = note;
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final now = DateTime(2026, 5, 17, 10, recentJournalEntries.length);
    recentJournalEntries.insert(
      0,
      MoodJournalEntry(
        id: 'saved-${recentJournalEntries.length}',
        mood: selectedMood,
        note: trimmed,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> deleteMoodJournalEntry(String id) async {
    deletedEntryId = id;
    recentJournalEntries.removeWhere((entry) => entry.id == id);
  }

  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopQuoteRepository implements QuoteRepository {
  UserProfile _profile = UserProfile.initial();

  @override
  UserProfile get profile => _profile;

  @override
  SessionAggregates get sessionAggregates => SessionAggregates.initial();

  @override
  CatalogVersion? get catalogVersion => null;

  @override
  List<QuoteEntry> get allQuotes => const [];

  @override
  Future<void> initialize() async {}

  @override
  QuoteEntry? quoteById(String id) => null;

  @override
  List<QuoteEntry> quotesByIds(Iterable<String> ids) => const [];

  @override
  List<String> moodPoolIds(MoodType mood, PoolTier tier) => const [];

  @override
  List<String> globalTopIds() => const [];

  @override
  List<QuoteEntry> quotesByAuthor(String author) => const [];

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

class _NoopMoodJournalRepository implements MoodJournalRepository {
  @override
  Future<void> initialize() async {}

  @override
  List<MoodJournalEntry> recentEntries({MoodType? mood, int limit = 5}) {
    return const [];
  }

  @override
  Future<void> saveEntry({
    required MoodType mood,
    required String note,
  }) async {}

  @override
  Future<void> deleteEntry(String id) async {}

  @override
  Future<void> clearEntries() async {}
}

class _NoopQuoteWidget implements QuoteWidgetPort {
  @override
  bool get isSupported => true;

  @override
  Future<void> syncQuote({
    required QuoteEntry quote,
    required MoodType mood,
  }) async {}
}

class _NoopTray implements TrayPort {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> update({
    required String previewText,
    required MoodType selectedMood,
  }) async {}

  @override
  Future<void> dispose() async {}
}

class _NoopQuoteActions implements QuoteActionsPort {
  @override
  Future<void> copyQuote(QuoteEntry quote) async {}

  @override
  Future<void> shareQuote(QuoteEntry quote) async {}
}

class _NoopAppExit implements AppExitPort {
  @override
  Never quit() => throw StateError('quit not expected');
}
