import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wisely/src/application/ports/platform_ports.dart';
import 'package:wisely/src/domain/entities/decompress_state.dart';
import 'package:wisely/src/domain/entities/emotional_weather_point.dart';
import 'package:wisely/src/domain/entities/journal_entry_filter.dart';
import 'package:wisely/src/domain/entities/mood_energy.dart';
import 'package:wisely/src/domain/entities/mood_journal_entry.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/personalized_greeting.dart';
import 'package:wisely/src/domain/entities/quote_arc_tier.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/quote_feed_filter.dart';
import 'package:wisely/src/domain/entities/session_models.dart';
import 'package:wisely/src/domain/entities/tide_season.dart';
import 'package:wisely/src/domain/entities/time_bucket.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/domain/repositories/mood_journal_repository.dart';
import 'package:wisely/src/domain/repositories/quote_repository.dart';
import 'package:wisely/src/domain/services/clock_service.dart';
import 'package:wisely/src/domain/services/echo_guard.dart';
import 'package:wisely/src/domain/services/greeting_service.dart';
import 'package:wisely/src/domain/services/preference_engine.dart';
import 'package:wisely/src/domain/services/recommendation_service.dart';
import 'package:wisely/src/domain/services/streak_service.dart';
import 'package:wisely/src/domain/services/tide_service.dart';

final quoteRepositoryProvider = Provider<QuoteRepository>(
  (ref) => throw UnimplementedError('QuoteRepository provider not configured'),
);

final moodJournalRepositoryProvider = Provider<MoodJournalRepository>(
  (ref) =>
      throw UnimplementedError('MoodJournalRepository provider not configured'),
);

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService(repository: ref.watch(quoteRepositoryProvider));
});

final greetingServiceProvider = Provider<GreetingService>((ref) {
  return const GreetingService();
});

final clockServiceProvider = Provider<ClockService>((ref) {
  return const ClockService();
});

final preferenceEngineProvider = Provider<PreferenceEngine>((ref) {
  return const PreferenceEngine();
});

final tideServiceProvider = Provider<TideService>((ref) {
  return const TideService();
});

final streakServiceProvider = Provider<StreakService>((ref) {
  return const StreakService();
});

final echoGuardProvider = Provider<EchoGuard>((ref) {
  return const EchoGuard();
});

final quoteWidgetPortProvider = Provider<QuoteWidgetPort>(
  (ref) => throw UnimplementedError('QuoteWidgetPort provider not configured'),
);

final trayPortProvider = Provider<TrayPort>(
  (ref) => throw UnimplementedError('TrayPort provider not configured'),
);

final quoteActionsPortProvider = Provider<QuoteActionsPort>(
  (ref) => throw UnimplementedError('QuoteActionsPort provider not configured'),
);

final appExitPortProvider = Provider<AppExitPort>(
  (ref) => throw UnimplementedError('AppExitPort provider not configured'),
);

final wiselyControllerProvider =
    NotifierProvider<WiselyController, WiselyState>(WiselyController.new);

const int maxSelectedMoodSelections = 3;

const Object _unset = Object();

class WiselyState {
  const WiselyState({
    required this.isLoading,
    required this.isInitialized,
    required this.initializationError,
    required this.selectedTab,
    required this.selectedMood,
    required this.selectedMoods,
    required this.currentQuote,
    required this.quoteOfDay,
    required this.selectedDetailQuote,
    required this.searchQuery,
    required this.searchResults,
    required this.profile,
    required this.homeGreeting,
    required this.greetingOverride,
    required this.greetingSessionSeed,
    required this.timeBucket,
    required this.tideSeason,
    required this.sessionState,
    required this.sessionAggregates,
    required this.recentJournalEntries,
    required this.journalEntries,
    required this.journalFilter,
    required this.journalMoodFilter,
    required this.journalDiscreetMode,
    required this.pendingQuote,
    required this.pendingQuoteMood,
    required this.pendingQuoteSyncWidget,
    required this.decompressState,
    required this.echoDecompressionRequired,
    required this.currentQuoteShownAt,
    required this.currentQuoteArc,
    required this.emotionalWeather,
  });

  final bool isLoading;
  final bool isInitialized;
  final String? initializationError;
  final int selectedTab;
  final MoodType selectedMood;
  final List<MoodType> selectedMoods;
  final QuoteEntry? currentQuote;
  final QuoteEntry? quoteOfDay;
  final QuoteEntry? selectedDetailQuote;
  final String searchQuery;
  final List<QuoteEntry> searchResults;
  final UserProfile profile;
  final PersonalizedGreeting homeGreeting;
  final String? greetingOverride;
  final int greetingSessionSeed;
  final TimeBucket timeBucket;
  final TideSeason tideSeason;
  final SessionState sessionState;
  final SessionAggregates sessionAggregates;
  final List<MoodJournalEntry> recentJournalEntries;
  final List<MoodJournalEntry> journalEntries;
  final JournalEntryFilter journalFilter;
  final MoodType? journalMoodFilter;
  final bool journalDiscreetMode;
  final QuoteEntry? pendingQuote;
  final MoodType? pendingQuoteMood;
  final bool pendingQuoteSyncWidget;
  final DecompressState decompressState;
  final bool echoDecompressionRequired;
  final DateTime? currentQuoteShownAt;
  final List<QuoteEntry> currentQuoteArc;
  final List<EmotionalWeatherPoint> emotionalWeather;

  bool get hasRightPanel =>
      selectedDetailQuote != null || searchQuery.trim().isNotEmpty;

  bool get isDecompressing =>
      pendingQuote != null && decompressState != DecompressState.idle;

  factory WiselyState.initial(DateTime now) {
    return WiselyState(
      isLoading: false,
      isInitialized: false,
      initializationError: null,
      selectedTab: 0,
      selectedMood: MoodType.happy,
      selectedMoods: const [MoodType.happy],
      currentQuote: null,
      quoteOfDay: null,
      selectedDetailQuote: null,
      searchQuery: '',
      searchResults: const [],
      profile: UserProfile.initial(),
      homeGreeting: PersonalizedGreeting.fallback,
      greetingOverride: null,
      greetingSessionSeed: now.millisecondsSinceEpoch,
      timeBucket: TimeBucket.morning,
      tideSeason: TideSeason.still,
      sessionState: SessionState.initial(MoodType.happy, now),
      sessionAggregates: SessionAggregates.initial(),
      recentJournalEntries: const [],
      journalEntries: const [],
      journalFilter: JournalEntryFilter.recent,
      journalMoodFilter: null,
      journalDiscreetMode: true,
      pendingQuote: null,
      pendingQuoteMood: null,
      pendingQuoteSyncWidget: false,
      decompressState: DecompressState.idle,
      echoDecompressionRequired: false,
      currentQuoteShownAt: null,
      currentQuoteArc: const [],
      emotionalWeather: const [],
    );
  }

  WiselyState copyWith({
    bool? isLoading,
    bool? isInitialized,
    Object? initializationError = _unset,
    int? selectedTab,
    MoodType? selectedMood,
    List<MoodType>? selectedMoods,
    Object? currentQuote = _unset,
    Object? quoteOfDay = _unset,
    Object? selectedDetailQuote = _unset,
    String? searchQuery,
    List<QuoteEntry>? searchResults,
    UserProfile? profile,
    PersonalizedGreeting? homeGreeting,
    Object? greetingOverride = _unset,
    int? greetingSessionSeed,
    TimeBucket? timeBucket,
    TideSeason? tideSeason,
    SessionState? sessionState,
    SessionAggregates? sessionAggregates,
    List<MoodJournalEntry>? recentJournalEntries,
    List<MoodJournalEntry>? journalEntries,
    JournalEntryFilter? journalFilter,
    Object? journalMoodFilter = _unset,
    bool? journalDiscreetMode,
    Object? pendingQuote = _unset,
    Object? pendingQuoteMood = _unset,
    bool? pendingQuoteSyncWidget,
    DecompressState? decompressState,
    bool? echoDecompressionRequired,
    Object? currentQuoteShownAt = _unset,
    List<QuoteEntry>? currentQuoteArc,
    List<EmotionalWeatherPoint>? emotionalWeather,
  }) {
    return WiselyState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      initializationError: initializationError == _unset
          ? this.initializationError
          : initializationError as String?,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedMood: selectedMood ?? this.selectedMood,
      selectedMoods: selectedMoods ?? this.selectedMoods,
      currentQuote: currentQuote == _unset
          ? this.currentQuote
          : currentQuote as QuoteEntry?,
      quoteOfDay: quoteOfDay == _unset
          ? this.quoteOfDay
          : quoteOfDay as QuoteEntry?,
      selectedDetailQuote: selectedDetailQuote == _unset
          ? this.selectedDetailQuote
          : selectedDetailQuote as QuoteEntry?,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      profile: profile ?? this.profile,
      homeGreeting: homeGreeting ?? this.homeGreeting,
      greetingOverride: greetingOverride == _unset
          ? this.greetingOverride
          : greetingOverride as String?,
      greetingSessionSeed: greetingSessionSeed ?? this.greetingSessionSeed,
      timeBucket: timeBucket ?? this.timeBucket,
      tideSeason: tideSeason ?? this.tideSeason,
      sessionState: sessionState ?? this.sessionState,
      sessionAggregates: sessionAggregates ?? this.sessionAggregates,
      recentJournalEntries: recentJournalEntries ?? this.recentJournalEntries,
      journalEntries: journalEntries ?? this.journalEntries,
      journalFilter: journalFilter ?? this.journalFilter,
      journalMoodFilter: journalMoodFilter == _unset
          ? this.journalMoodFilter
          : journalMoodFilter as MoodType?,
      journalDiscreetMode: journalDiscreetMode ?? this.journalDiscreetMode,
      pendingQuote: pendingQuote == _unset
          ? this.pendingQuote
          : pendingQuote as QuoteEntry?,
      pendingQuoteMood: pendingQuoteMood == _unset
          ? this.pendingQuoteMood
          : pendingQuoteMood as MoodType?,
      pendingQuoteSyncWidget:
          pendingQuoteSyncWidget ?? this.pendingQuoteSyncWidget,
      decompressState: decompressState ?? this.decompressState,
      echoDecompressionRequired:
          echoDecompressionRequired ?? this.echoDecompressionRequired,
      currentQuoteShownAt: currentQuoteShownAt == _unset
          ? this.currentQuoteShownAt
          : currentQuoteShownAt as DateTime?,
      currentQuoteArc: currentQuoteArc ?? this.currentQuoteArc,
      emotionalWeather: emotionalWeather ?? this.emotionalWeather,
    );
  }
}

class WiselyController extends Notifier<WiselyState> {
  late final QuoteRepository _repository;
  late final MoodJournalRepository _moodJournalRepository;
  late final RecommendationService _recommendationService;
  late final GreetingService _greetingService;
  late final ClockService _clockService;
  late final PreferenceEngine _preferenceEngine;
  late final TideService _tideService;
  late final StreakService _streakService;
  late final EchoGuard _echoGuard;
  late final QuoteWidgetPort _quoteWidget;
  late final TrayPort _tray;
  late final QuoteActionsPort _quoteActions;
  late final AppExitPort _appExit;

  late final FocusNode searchFocusNode;
  late final TextEditingController searchController;
  Timer? _dwellTimer;
  String? _dwellQuoteId;

  bool get isLoading => state.isLoading;
  bool get isInitialized => state.isInitialized;
  String? get initializationError => state.initializationError;
  int get selectedTab => state.selectedTab;
  MoodType get selectedMood => state.selectedMood;
  List<MoodType> get selectedMoods => state.selectedMoods;
  QuoteEntry? get currentQuote => state.currentQuote;
  QuoteEntry? get quoteOfDay => state.quoteOfDay;
  QuoteEntry? get selectedDetailQuote => state.selectedDetailQuote;
  List<QuoteEntry> get searchResults => state.searchResults;
  UserProfile get profile => state.profile;
  PersonalizedGreeting get homeGreeting => state.homeGreeting;
  String? get greetingOverride => state.greetingOverride;
  bool get supportsHomeWidgets => _quoteWidget.isSupported;
  TimeBucket get timeBucket => state.timeBucket;
  TideSeason get tideSeason => state.tideSeason;
  SessionState get sessionState => state.sessionState;
  SessionAggregates get sessionAggregates => state.sessionAggregates;
  List<MoodJournalEntry> get recentJournalEntries => state.recentJournalEntries;
  List<MoodJournalEntry> get journalEntries => state.journalEntries;
  JournalEntryFilter get journalFilter => state.journalFilter;
  MoodType? get journalMoodFilter => state.journalMoodFilter;
  bool get journalDiscreetMode => state.journalDiscreetMode;
  bool get isDecompressing => state.isDecompressing;
  QuoteEntry? get pendingQuote => state.pendingQuote;
  MoodType? get pendingQuoteMood => state.pendingQuoteMood;
  DecompressState get decompressState => state.decompressState;
  List<EmotionalWeatherPoint> get emotionalWeather => state.emotionalWeather;
  bool get hasRightPanel => state.hasRightPanel;

  @override
  WiselyState build() {
    _repository = ref.watch(quoteRepositoryProvider);
    _moodJournalRepository = ref.watch(moodJournalRepositoryProvider);
    _recommendationService = ref.watch(recommendationServiceProvider);
    _greetingService = ref.watch(greetingServiceProvider);
    _clockService = ref.watch(clockServiceProvider);
    _preferenceEngine = ref.watch(preferenceEngineProvider);
    _tideService = ref.watch(tideServiceProvider);
    _streakService = ref.watch(streakServiceProvider);
    _echoGuard = ref.watch(echoGuardProvider);
    _quoteWidget = ref.watch(quoteWidgetPortProvider);
    _tray = ref.watch(trayPortProvider);
    _quoteActions = ref.watch(quoteActionsPortProvider);
    _appExit = ref.watch(appExitPortProvider);
    searchFocusNode = FocusNode(debugLabel: 'wisely-search');
    searchController = TextEditingController();

    ref.onDispose(() {
      _dwellTimer?.cancel();
      _tray.dispose();
      searchFocusNode.dispose();
      searchController.dispose();
    });

    return WiselyState.initial(DateTime.now());
  }

  Future<void> initialize() async {
    if (state.isInitialized || state.isLoading) {
      return;
    }
    state = state.copyWith(isLoading: true, initializationError: null);

    try {
      final now = DateTime.now();
      await _repository.initialize();
      await _moodJournalRepository.initialize();
      var profile = _recommendationService.applyDailyDecay(
        _repository.profile,
        now,
      );
      final streak = _streakService.evaluate(profile, now);
      profile = streak.profile;
      final tide = _tideService.checkSnapshot(profile, now);
      profile = tide.profile;
      final echo = _echoGuard.evaluate(profile);
      await _repository.saveProfile(profile);
      final selectedMoods = _normalizeMoodSelection(
        profile.preferredMoods.isNotEmpty
            ? profile.preferredMoods
            : [profile.widgetMood],
      );
      final selectedMood = selectedMoods.first;
      state = state.copyWith(
        profile: profile,
        selectedMood: selectedMood,
        selectedMoods: selectedMoods,
        homeGreeting: _greetingFor(profile, selectedMood),
        greetingOverride: streak.greetingOverride ?? profile.greetingOverride,
        timeBucket: _clockService.bucketFor(now),
        tideSeason: tide.season,
        echoDecompressionRequired: echo.shouldDecompress,
        sessionState: SessionState.initial(selectedMood, now),
        sessionAggregates: _repository.sessionAggregates,
        recentJournalEntries: _recentJournalEntries(selectedMoods),
        journalEntries: _journalEntries(
          filter: state.journalFilter,
          mood: state.journalMoodFilter,
        ),
        emotionalWeather: _emotionalWeather(profile),
      );

      if (profile.isOnboarded) {
        state = state.copyWith(
          quoteOfDay: _recommendationService.quoteOfTheDay(
            mood: selectedMood,
            now: now,
          ),
        );
        await _selectQuote(
          userTriggered: false,
          recordMood: false,
          syncWidget: true,
        );
        profile = state.profile;
      }

      await _tray.initialize();
      await _refreshTray();

      state = state.copyWith(
        profile: profile,
        isInitialized: true,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        initializationError: error.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> completeOnboarding({
    required String displayName,
    required UserGender gender,
    required List<MoodType> preferredMoods,
    bool skipped = false,
  }) async {
    final now = DateTime.now();
    final normalizedName = displayName.trim().isEmpty
        ? (skipped ? 'Friend' : '')
        : displayName.trim();
    final normalizedPreferences = _normalizeMoodSelection(
      preferredMoods.isEmpty
          ? MoodType.values.take(3).toList()
          : preferredMoods,
    );
    final selectedMood = normalizedPreferences.first;
    var profile = state.profile.copyWith(
      displayName: normalizedName,
      gender: gender,
      preferredMoods: normalizedPreferences,
      widgetMood: selectedMood,
    );
    profile = _recommendationService.registerMoodSelection(
      profile: profile,
      mood: selectedMood,
      now: now,
    );
    profile = _tideService.checkSnapshot(profile, now).profile;
    await _repository.saveProfile(profile);
    state = state.copyWith(
      profile: profile,
      selectedMood: selectedMood,
      selectedMoods: normalizedPreferences,
      homeGreeting: _greetingFor(profile, selectedMood),
      timeBucket: _clockService.bucketFor(now),
      tideSeason: profile.tideSeason,
      quoteOfDay: _recommendationService.quoteOfTheDay(
        mood: selectedMood,
        now: now,
      ),
      recentJournalEntries: _recentJournalEntries(normalizedPreferences),
      journalEntries: _journalEntries(
        filter: state.journalFilter,
        mood: state.journalMoodFilter,
      ),
      emotionalWeather: _emotionalWeather(profile),
    );
    await _selectQuote(
      userTriggered: skipped,
      recordMood: false,
      syncWidget: true,
      forceGlobalTop: skipped,
    );
  }

  Future<void> refreshQuote() async {
    await _selectQuote(
      userTriggered: true,
      recordMood: false,
      syncWidget: true,
    );
  }

  Future<void> selectMood(MoodType mood) async {
    final now = DateTime.now();
    var profile = _recommendationService.registerMoodSelection(
      profile: state.profile,
      mood: mood,
      now: now,
    );
    profile = _tideService.checkSnapshot(profile, now).profile;
    await _repository.saveProfile(profile);
    state = state.copyWith(
      profile: profile,
      selectedMood: mood,
      selectedMoods: [mood],
      homeGreeting: _greetingFor(profile, mood),
      timeBucket: _clockService.bucketFor(now),
      tideSeason: profile.tideSeason,
      echoDecompressionRequired: _echoGuard.evaluate(profile).shouldDecompress,
      recentJournalEntries: _recentJournalEntries([mood]),
      journalEntries: _journalEntries(
        filter: state.journalFilter,
        mood: state.journalMoodFilter,
      ),
      emotionalWeather: _emotionalWeather(profile),
    );
    await _selectQuote(
      userTriggered: true,
      recordMood: false,
      syncWidget: true,
    );
  }

  Future<void> toggleMoodSelection(MoodType mood) async {
    final now = DateTime.now();
    final currentMoods = _activeMoodSelection();
    final selected = currentMoods.contains(mood);
    if (!selected && currentMoods.length >= maxSelectedMoodSelections) {
      return;
    }
    final nextMoods = selected
        ? currentMoods.where((item) => item != mood).toList(growable: false)
        : [...currentMoods, mood];
    final normalizedMoods = _normalizeMoodSelection(
      nextMoods.isEmpty ? currentMoods : nextMoods,
    );
    final primaryMood = selected ? normalizedMoods.first : mood;
    final orderedMoods = _normalizeMoodSelection([
      primaryMood,
      ...normalizedMoods,
    ]);
    var profile = _recommendationService.registerMoodSelection(
      profile: state.profile,
      mood: primaryMood,
      now: now,
    );
    profile = _tideService.checkSnapshot(profile, now).profile;
    await _repository.saveProfile(profile);
    state = state.copyWith(
      profile: profile,
      selectedMood: primaryMood,
      selectedMoods: orderedMoods,
      homeGreeting: _greetingFor(profile, primaryMood),
      timeBucket: _clockService.bucketFor(now),
      tideSeason: profile.tideSeason,
      echoDecompressionRequired: _echoGuard.evaluate(profile).shouldDecompress,
      recentJournalEntries: _recentJournalEntries(orderedMoods),
      journalEntries: _journalEntries(
        filter: state.journalFilter,
        mood: state.journalMoodFilter,
      ),
      emotionalWeather: _emotionalWeather(profile),
    );
    await _selectQuote(
      userTriggered: true,
      recordMood: false,
      syncWidget: true,
    );
  }

  Future<void> toggleLike([QuoteEntry? target]) async {
    final quote = target ?? state.currentQuote;
    if (quote == null) {
      return;
    }
    final profile = _recommendationService.toggleLike(
      profile: state.profile,
      quote: quote,
      now: DateTime.now(),
    );
    await _repository.saveProfile(profile);
    state = state.copyWith(profile: profile);
  }

  Future<void> copyQuote([QuoteEntry? target]) async {
    final quote = target ?? state.currentQuote;
    if (quote == null) {
      return;
    }
    await _quoteActions.copyQuote(quote);
  }

  Future<void> shareQuote([QuoteEntry? target]) async {
    final quote = target ?? state.currentQuote;
    if (quote == null) {
      return;
    }
    await _quoteActions.shareQuote(quote);
  }

  Future<void> sendCurrentQuoteToWidget() async {
    final quote = state.currentQuote;
    if (quote == null) {
      return;
    }
    await _quoteWidget.syncQuote(
      quote: quote,
      mood: displayMoodForQuote(quote),
    );
  }

  Future<void> updateDisplayName(String value) async {
    final profile = state.profile.copyWith(displayName: value.trim());
    await _repository.saveProfile(profile);
    state = state.copyWith(
      profile: profile,
      homeGreeting: _greetingFor(profile, state.selectedMood),
    );
  }

  Future<void> updateGender(UserGender gender) async {
    final profile = state.profile.copyWith(gender: gender);
    await _repository.saveProfile(profile);
    state = state.copyWith(
      profile: profile,
      homeGreeting: _greetingFor(profile, state.selectedMood),
    );
  }

  Future<void> completeProfilePersonalization({
    required String displayName,
    required UserGender gender,
  }) async {
    final trimmedName = displayName.trim();
    final profile = state.profile.copyWith(
      displayName: trimmedName.isEmpty
          ? state.profile.displayName
          : trimmedName,
      gender: gender,
    );
    await _repository.saveProfile(profile);
    state = state.copyWith(
      profile: profile,
      homeGreeting: _greetingFor(profile, state.selectedMood),
    );
  }

  Future<void> updateThemeMode(AppThemeMode mode) async {
    final profile = state.profile.copyWith(themeMode: mode);
    await _repository.saveProfile(profile);
    state = state.copyWith(profile: profile);
  }

  Future<void> updateTextScale(double value) async {
    final profile = state.profile.copyWith(textScale: value.clamp(0.9, 1.35));
    await _repository.saveProfile(profile);
    state = state.copyWith(profile: profile);
  }

  Future<void> resetAdaptiveWeights() async {
    final profile = state.profile.copyWith(
      authorWeight: 0.4,
      tagWeight: 0.55,
      tagPreferenceWeights: const {},
      frustrationIndex: 0,
      authorLikeEvents7d: const {},
      consecutiveTagBoostedSkips: 0,
    );
    await _repository.saveProfile(profile);
    state = state.copyWith(profile: profile);
  }

  Future<void> clearUserData() async {
    await _repository.clearUserData();
    await _moodJournalRepository.clearEntries();
    searchController.clear();
    final selectedMood = MoodType.happy;
    state = state.copyWith(
      profile: _repository.profile,
      selectedMood: selectedMood,
      selectedMoods: const [MoodType.happy],
      homeGreeting: PersonalizedGreeting.fallback,
      greetingOverride: null,
      currentQuote: null,
      quoteOfDay: null,
      selectedDetailQuote: null,
      searchQuery: '',
      searchResults: const [],
      sessionState: SessionState.initial(selectedMood, DateTime.now()),
      sessionAggregates: _repository.sessionAggregates,
      recentJournalEntries: const [],
      journalEntries: const [],
      journalFilter: JournalEntryFilter.recent,
      journalMoodFilter: null,
      journalDiscreetMode: true,
      timeBucket: _clockService.bucketFor(DateTime.now()),
      tideSeason: TideSeason.still,
      pendingQuote: null,
      pendingQuoteMood: null,
      pendingQuoteSyncWidget: false,
      decompressState: DecompressState.idle,
      echoDecompressionRequired: false,
      currentQuoteShownAt: null,
      currentQuoteArc: const [],
      emotionalWeather: const [],
    );
    await _refreshTray();
  }

  Future<void> saveMoodJournalNote(String note) async {
    await saveMoodJournalEntry(note: note);
  }

  Future<void> saveMoodJournalEntry({
    required String note,
    String situation = '',
    String feelings = '',
    String handledWith = '',
    String needNow = '',
    String kindSelfTalk = '',
  }) async {
    final trimmedFields = [
      note,
      situation,
      feelings,
      handledWith,
      needNow,
      kindSelfTalk,
    ].map((value) => value.trim()).toList(growable: false);
    if (trimmedFields.every((value) => value.isEmpty)) {
      return;
    }
    final selectedMoods = _activeMoodSelection();
    await _moodJournalRepository.saveEntry(
      mood: selectedMoods.first,
      moods: selectedMoods,
      note: trimmedFields[0],
      situation: trimmedFields[1],
      feelings: trimmedFields[2],
      handledWith: trimmedFields[3],
      needNow: trimmedFields[4],
      kindSelfTalk: trimmedFields[5],
    );
    _refreshJournalEntries();
  }

  Future<void> deleteMoodJournalEntry(String id) async {
    await _moodJournalRepository.deleteEntry(id);
    _refreshJournalEntries();
  }

  void setJournalFilter(JournalEntryFilter filter) {
    state = state.copyWith(
      journalFilter: filter,
      journalEntries: _journalEntries(
        filter: filter,
        mood: state.journalMoodFilter,
      ),
    );
  }

  void setJournalMoodFilter(MoodType? mood) {
    state = state.copyWith(
      journalMoodFilter: mood,
      journalEntries: _journalEntries(filter: state.journalFilter, mood: mood),
    );
  }

  void setJournalDiscreetMode(bool value) {
    state = state.copyWith(journalDiscreetMode: value);
  }

  Future<void> setSelectedTab(int index) async {
    state = state.copyWith(selectedTab: index);
  }

  void updateSearchQuery(String value) {
    state = state.copyWith(
      searchQuery: value,
      searchResults: _repository.searchQuotes(value),
      selectedDetailQuote: value.trim().isEmpty
          ? null
          : state.selectedDetailQuote,
    );
  }

  void openQuoteDetail(QuoteEntry quote) {
    state = state.copyWith(selectedDetailQuote: quote);
  }

  void closeRightPanel() {
    searchController.clear();
    state = state.copyWith(
      selectedDetailQuote: null,
      searchQuery: '',
      searchResults: const [],
    );
  }

  List<QuoteEntry> favorites({MoodType? mood}) {
    final liked =
        _repository
            .quotesByIds(state.profile.likedQuoteIds)
            .where((quote) => mood == null || quote.belongsToMood(mood))
            .toList()
          ..sort((a, b) => b.popularity.compareTo(a.popularity));
    return liked;
  }

  List<QuoteEntry> quoteFeed({
    QuoteFeedFilter filter = QuoteFeedFilter.recommended,
    int limit = 18,
  }) {
    final selectedMoods = _activeMoodSelection();
    final candidates = _repository.allQuotes
        .where((quote) => _quoteMatchesAnyMood(quote, selectedMoods))
        .toList();

    if (candidates.isEmpty) {
      final fallback = <QuoteEntry>[
        ?state.currentQuote,
        ..._repository.allQuotes.take(limit),
      ];
      return _uniqueQuotes(fallback).take(limit).toList(growable: false);
    }

    switch (filter) {
      case QuoteFeedFilter.recommended:
        candidates.sort(
          (a, b) => _feedRecommendationScore(
            b,
            selectedMoods,
          ).compareTo(_feedRecommendationScore(a, selectedMoods)),
        );
        return _uniqueQuotes([
          ?state.currentQuote,
          ...state.currentQuoteArc,
          ...candidates,
        ]).take(limit).toList(growable: false);
      case QuoteFeedFilter.popular:
        candidates.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
      case QuoteFeedFilter.fresh:
        candidates.sort((a, b) {
          final aSeen = state.profile.lastShownAtByQuoteId[a.id];
          final bSeen = state.profile.lastShownAtByQuoteId[b.id];
          if (aSeen == null && bSeen != null) {
            return -1;
          }
          if (aSeen != null && bSeen == null) {
            return 1;
          }
          if (aSeen != null && bSeen != null && aSeen != bSeen) {
            return aSeen.compareTo(bSeen);
          }
          return b.popularity.compareTo(a.popularity);
        });
        break;
      case QuoteFeedFilter.short:
        candidates.sort((a, b) {
          final lengthCompare = a.text.length.compareTo(b.text.length);
          if (lengthCompare != 0) {
            return lengthCompare;
          }
          return b.popularity.compareTo(a.popularity);
        });
        break;
      case QuoteFeedFilter.deep:
        candidates.sort((a, b) {
          final tierCompare = _deepTierRank(
            a,
            selectedMoods,
          ).compareTo(_deepTierRank(b, selectedMoods));
          if (tierCompare != 0) {
            return tierCompare;
          }
          final rhythmCompare = a.rhythmScore.compareTo(b.rhythmScore);
          if (rhythmCompare != 0) {
            return rhythmCompare;
          }
          final lengthCompare = b.text.length.compareTo(a.text.length);
          if (lengthCompare != 0) {
            return lengthCompare;
          }
          return b.popularity.compareTo(a.popularity);
        });
        break;
    }

    return _uniqueQuotes(candidates).take(limit).toList(growable: false);
  }

  List<QuoteEntry> authorQuotes(String author) =>
      _repository.quotesByAuthor(author);

  MoodType displayMoodForQuote(QuoteEntry quote) {
    for (final mood in _activeMoodSelection()) {
      if (quote.belongsToMood(mood)) {
        return mood;
      }
    }
    return quote.moods.isEmpty ? state.selectedMood : quote.moods.first;
  }

  Future<void> handleLifecycleChange(AppLifecyclePhase phase) async {
    if (phase == AppLifecyclePhase.inactive ||
        phase == AppLifecyclePhase.paused ||
        phase == AppLifecyclePhase.detached) {
      await _persistSession();
    }
  }

  Future<void> handleTrayAction(TrayAction action) async {
    switch (action) {
      case TrayAction.nextQuote:
        await refreshQuote();
        return;
      case TrayAction.copyQuote:
        await copyQuote();
        return;
      case TrayAction.openApp:
        return;
      case TrayAction.quitApp:
        await _persistSession();
        await _tray.dispose();
        _appExit.quit();
    }
  }

  void updateDecompressionState(DecompressState decompressState) {
    if (!state.isDecompressing) {
      return;
    }
    state = state.copyWith(decompressState: decompressState);
  }

  Future<void> completeDecompression() async {
    final quote = state.pendingQuote;
    if (quote == null) {
      state = state.copyWith(decompressState: DecompressState.idle);
      return;
    }
    final mood = state.pendingQuoteMood ?? displayMoodForQuote(quote);
    final syncWidget = state.pendingQuoteSyncWidget;
    state = state.copyWith(
      currentQuote: quote,
      pendingQuote: null,
      pendingQuoteMood: null,
      pendingQuoteSyncWidget: false,
      decompressState: DecompressState.idle,
      currentQuoteShownAt: DateTime.now(),
    );
    _startDwellTimer(quote);
    if (syncWidget) {
      await _quoteWidget.syncQuote(quote: quote, mood: mood);
    }
    await _refreshTray();
  }

  void _refreshJournalEntries() {
    state = state.copyWith(
      recentJournalEntries: _recentJournalEntries(_activeMoodSelection()),
      journalEntries: _journalEntries(
        filter: state.journalFilter,
        mood: state.journalMoodFilter,
      ),
    );
  }

  List<MoodJournalEntry> _recentJournalEntries(List<MoodType> moods) {
    return _moodJournalRepository.entries(moods: moods, limit: 5);
  }

  List<MoodJournalEntry> _journalEntries({
    required JournalEntryFilter filter,
    MoodType? mood,
  }) {
    return _moodJournalRepository.entries(
      moods: mood == null ? null : [mood],
      filter: filter,
      limit: 80,
    );
  }

  bool _quoteMatchesAnyMood(QuoteEntry quote, List<MoodType> moods) {
    return moods.any(
      (mood) =>
          quote.belongsToMood(mood) || (quote.moodStrength[mood] ?? 0) > 0.25,
    );
  }

  Iterable<QuoteEntry> _uniqueQuotes(Iterable<QuoteEntry> quotes) sync* {
    final seen = <String>{};
    for (final quote in quotes) {
      if (seen.add(quote.id)) {
        yield quote;
      }
    }
  }

  double _feedRecommendationScore(QuoteEntry quote, List<MoodType> moods) {
    final moodStrength = moods
        .map((mood) => quote.moodStrength[mood] ?? 0.0)
        .fold<double>(0, max);
    final likedTagOverlap = quote.tags
        .where(state.profile.likedTagCounts.containsKey)
        .length
        .toDouble();
    final preferenceScore = quote.tags.fold<double>(
      0,
      (sum, tag) => sum + (state.profile.tagPreferenceWeights[tag] ?? 0),
    );
    final freshnessBoost = state.profile.lastShownQuoteIds.contains(quote.id)
        ? -25.0
        : 35.0;
    final tierBoost = moods
        .map(
          (mood) => switch (quote.effectiveArcTier(mood)) {
            QuoteArcTier.mirror => 18.0,
            QuoteArcTier.bridge => 26.0,
            QuoteArcTier.window => 22.0,
          },
        )
        .fold<double>(0, max);

    return (moodStrength * 900) +
        (quote.popularity / 10000) +
        (likedTagOverlap * 28) +
        (preferenceScore.clamp(-0.4, 1.2) * 70) +
        freshnessBoost +
        tierBoost;
  }

  int _deepTierRank(QuoteEntry quote, List<MoodType> moods) {
    return moods
        .map(
          (mood) => switch (quote.effectiveArcTier(mood)) {
            QuoteArcTier.mirror => 0,
            QuoteArcTier.bridge => 1,
            QuoteArcTier.window => 2,
          },
        )
        .fold<int>(2, min);
  }

  PersonalizedGreeting _greetingFor(UserProfile profile, MoodType mood) {
    return _greetingService.greetingFor(
      profile: profile,
      mood: mood,
      sessionSeed: state.greetingSessionSeed,
    );
  }

  Future<void> _selectQuote({
    required bool userTriggered,
    required bool recordMood,
    required bool syncWidget,
    bool forceGlobalTop = false,
  }) async {
    final now = DateTime.now();
    var profile = state.profile;
    final selectedMoods = _activeMoodSelection();
    final selectedMood = selectedMoods.first;
    final currentQuote = state.currentQuote;
    if (currentQuote != null && userTriggered) {
      profile = await _recordQuickRefreshIfNeeded(profile, currentQuote, now);
      profile = _recommendationService.recordSkip(
        profile: profile,
        quote: currentQuote,
        mood: selectedMood,
      );
    }
    if (recordMood) {
      profile = _recommendationService.registerMoodSelection(
        profile: profile,
        mood: selectedMood,
        now: now,
      );
    }

    var refreshTimestamps = state.sessionState.refreshTimestamps;
    if (userTriggered) {
      refreshTimestamps = [...refreshTimestamps, now];
    }
    final refreshRate = _recommendationService.calculateRefreshRate(
      refreshTimestamps,
      now,
    );

    RecommendationResult? result;
    if (!forceGlobalTop) {
      result = _recommendationService.nextQuoteForMoods(
        moods: selectedMoods,
        profile: profile,
        refreshRate: refreshRate,
        timeBucket: _clockService.bucketFor(now),
      );
    }
    final quote = forceGlobalTop
        ? _repository.quotesByIds(_repository.globalTopIds()).first
        : result!.quote;

    final quoteMood = displayMoodForQuote(quote);
    profile = _recommendationService.registerQuoteShown(
      profile: profile,
      quote: quote,
      now: now,
      resetHistory: result?.resetHistory ?? false,
    );
    await _repository.saveProfile(profile);

    final sessionState = state.sessionState.copyWith(
      lastMood: selectedMood,
      quotesShownCount: state.sessionState.quotesShownCount + 1,
      refreshRate: refreshRate,
      refreshTimestamps: refreshTimestamps,
    );
    final shouldDecompress =
        !forceGlobalTop &&
        _requiresDecompression(
          primaryMood: selectedMood,
          echoRequired: state.echoDecompressionRequired,
        );
    state = state.copyWith(
      profile: profile,
      currentQuote: shouldDecompress ? null : quote,
      pendingQuote: shouldDecompress ? quote : null,
      pendingQuoteMood: shouldDecompress ? quoteMood : null,
      pendingQuoteSyncWidget: shouldDecompress ? syncWidget : false,
      decompressState: shouldDecompress
          ? DecompressState.inhale
          : DecompressState.idle,
      quoteOfDay: _recommendationService.quoteOfTheDay(
        mood: selectedMood,
        now: now,
      ),
      sessionState: sessionState,
      timeBucket: _clockService.bucketFor(now),
      tideSeason: profile.tideSeason,
      currentQuoteShownAt: shouldDecompress ? null : now,
      currentQuoteArc: result?.gradientArc ?? [quote],
      emotionalWeather: _emotionalWeather(profile),
    );

    if (!shouldDecompress) {
      _startDwellTimer(quote);
    }
    if (syncWidget && !shouldDecompress) {
      await _quoteWidget.syncQuote(quote: quote, mood: quoteMood);
    }
    await _refreshTray();
  }

  Future<UserProfile> _recordQuickRefreshIfNeeded(
    UserProfile profile,
    QuoteEntry quote,
    DateTime now,
  ) async {
    final shownAt = state.currentQuoteShownAt;
    if (shownAt == null || now.difference(shownAt).inSeconds >= 2) {
      return profile;
    }
    return _preferenceEngine.recordQuickRefresh(profile: profile, quote: quote);
  }

  void _startDwellTimer(QuoteEntry quote) {
    _dwellTimer?.cancel();
    _dwellQuoteId = quote.id;
    _dwellTimer = Timer(const Duration(seconds: 15), () async {
      if (state.currentQuote?.id != _dwellQuoteId) {
        return;
      }
      final profile = _preferenceEngine.recordDwellCompleted(
        profile: state.profile,
        quote: quote,
      );
      await _repository.saveProfile(profile);
      if (state.currentQuote?.id == quote.id) {
        state = state.copyWith(profile: profile);
      }
    });
  }

  bool _requiresDecompression({
    required MoodType primaryMood,
    required bool echoRequired,
  }) {
    return echoRequired || primaryMood.requiresDecompression;
  }

  List<EmotionalWeatherPoint> _emotionalWeather(UserProfile profile) {
    final points = <EmotionalWeatherPoint>[];
    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 30));
    for (final entry in profile.moodDailyCounts30d.entries) {
      final parts = entry.key.split('|');
      if (parts.length != 2) {
        continue;
      }
      final date = DateTime.tryParse(parts.first);
      if (date == null || date.isBefore(cutoff)) {
        continue;
      }
      final mood = MoodType.fromKey(parts.last);
      points.add(
        EmotionalWeatherPoint(
          date: date,
          mood: mood,
          count: entry.value,
          intensity: entry.value.clamp(1, 6) / 6,
        ),
      );
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  List<MoodType> _activeMoodSelection() {
    return _normalizeMoodSelection([
      state.selectedMood,
      ...(state.selectedMoods.isEmpty
          ? const <MoodType>[]
          : state.selectedMoods),
    ]);
  }

  List<MoodType> _normalizeMoodSelection(List<MoodType> moods) {
    final unique = <MoodType>[];
    for (final mood in moods) {
      if (!unique.contains(mood)) {
        unique.add(mood);
      }
    }
    if (unique.isEmpty) {
      return const [MoodType.happy];
    }
    return List.unmodifiable(unique.take(maxSelectedMoodSelections));
  }

  Future<void> _refreshTray() async {
    final previewText = state.currentQuote == null
        ? 'Open Selvator to load a quote.'
        : _truncate(
            '"${state.currentQuote!.text}" - ${state.currentQuote!.author}',
            120,
          );
    await _tray.update(
      previewText: previewText,
      selectedMood: state.selectedMood,
    );
  }

  Future<void> _persistSession() async {
    final now = DateTime.now();
    final sessionLength = now
        .difference(state.sessionState.startTime)
        .inMinutes
        .toDouble();
    if (state.sessionState.quotesShownCount == 0 && sessionLength <= 0) {
      return;
    }
    final next = state.sessionAggregates.merge(
      refreshRate: state.sessionState.refreshRate,
      sessionLengthMinutes: sessionLength,
    );
    await _repository.saveSessionAggregates(next);
    state = state.copyWith(
      sessionAggregates: next,
      sessionState: SessionState.initial(state.selectedMood, now),
    );
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength - 1)}…';
  }
}
