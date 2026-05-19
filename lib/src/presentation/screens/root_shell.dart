import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:wisely/src/application/state/wisely_controller.dart';
import 'package:wisely/src/domain/entities/decompress_state.dart';
import 'package:wisely/src/domain/entities/emotional_weather_point.dart';
import 'package:wisely/src/domain/entities/journal_entry_filter.dart';
import 'package:wisely/src/domain/entities/mood_journal_entry.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/personalized_greeting.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/quote_feed_filter.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/presentation/branding/silvator_mascot.dart';
import 'package:wisely/src/presentation/theme/wisely_theme.dart';
import 'package:wisely/src/presentation/widgets/mood_chip_row.dart';
import 'package:wisely/src/presentation/widgets/mood_heatmap.dart';
import 'package:wisely/src/presentation/widgets/quote_card.dart';
import 'package:wisely/src/presentation/widgets/silvator_mascot_avatar.dart';

String _moodSelectionLabel(List<MoodType> moods) {
  final unique = <MoodType>[];
  for (final mood in moods) {
    if (!unique.contains(mood)) {
      unique.add(mood);
    }
  }
  if (unique.isEmpty) {
    return MoodType.happy.label;
  }
  if (unique.length <= 2) {
    return unique.map((mood) => mood.label).join(' + ');
  }
  return '${unique.first.label} + ${unique.length - 1} more';
}

class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wiselyControllerProvider);
    final controller = ref.read(wiselyControllerProvider.notifier);
    if (state.initializationError != null) {
      return _InitializationErrorView(message: state.initializationError!);
    }
    if (state.isLoading || !state.isInitialized) {
      return const _LoadingView();
    }
    if (!state.profile.isOnboarded) {
      return const OnboardingScreen();
    }
    if (!state.profile.hasGreetingProfile) {
      return const ProfilePersonalizationScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final desktop = width > 1024;
        final tablet = width > 680 && width <= 1024;
        final dark = context.isDarkMode;
        final scheme = Theme.of(context).colorScheme;
        final backgroundColors = dark
            ? [
                Theme.of(context).scaffoldBackgroundColor,
                Color.lerp(scheme.surface, scheme.primary, 0.10)!,
                Color.lerp(scheme.surface, scheme.tertiary, 0.08)!,
              ]
            : [
                Theme.of(context).scaffoldBackgroundColor,
                Color.lerp(scheme.surface, scheme.primary, 0.12)!,
                Color.lerp(scheme.surface, scheme.tertiary, 0.08)!,
              ];

        return CallbackShortcuts(
          bindings: _keyboardBindings(controller),
          child: Focus(
            autofocus: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: backgroundColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  if (desktop)
                    _DesktopShell(controller: controller)
                  else
                    _MobileShell(controller: controller, tablet: tablet),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Map<ShortcutActivator, VoidCallback> _keyboardBindings(
    WiselyController controller,
  ) {
    return {
      const SingleActivator(LogicalKeyboardKey.space): controller.refreshQuote,
      const SingleActivator(LogicalKeyboardKey.keyL): controller.toggleLike,
      const SingleActivator(LogicalKeyboardKey.keyC): controller.copyQuote,
      const SingleActivator(LogicalKeyboardKey.keyS): controller.shareQuote,
      const SingleActivator(LogicalKeyboardKey.slash): () {
        controller.searchFocusNode.requestFocus();
      },
      const SingleActivator(LogicalKeyboardKey.escape):
          controller.closeRightPanel,
      const SingleActivator(LogicalKeyboardKey.digit1): () =>
          controller.selectMood(MoodType.happy),
      const SingleActivator(LogicalKeyboardKey.digit2): () =>
          controller.selectMood(MoodType.calm),
      const SingleActivator(LogicalKeyboardKey.digit3): () =>
          controller.selectMood(MoodType.motivated),
      const SingleActivator(LogicalKeyboardKey.digit4): () =>
          controller.selectMood(MoodType.love),
      const SingleActivator(LogicalKeyboardKey.digit5): () =>
          controller.selectMood(MoodType.hopeful),
      const SingleActivator(LogicalKeyboardKey.digit6): () =>
          controller.selectMood(MoodType.reflective),
      const SingleActivator(LogicalKeyboardKey.digit7): () =>
          controller.selectMood(MoodType.confident),
      const SingleActivator(LogicalKeyboardKey.digit8): () =>
          controller.selectMood(MoodType.grateful),
      const SingleActivator(LogicalKeyboardKey.digit9): () =>
          controller.selectMood(MoodType.focused),
    };
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  UserGender? _selectedGender;
  final Set<MoodType> _selectedMoods = {
    MoodType.happy,
    MoodType.calm,
    MoodType.focused,
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(wiselyControllerProvider.notifier);
    final theme = Theme.of(context);
    final dark = context.isDarkMode;
    final phone = MediaQuery.sizeOf(context).width < 420;
    final widgetCopy = controller.supportsHomeWidgets
        ? 'quotes, favorites, Android widgets, and future recommendations'
        : 'quotes, favorites, and future recommendations';
    final canEnter =
        _selectedGender != null && _nameController.text.trim().isNotEmpty;
    final canSkip = _selectedGender != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: LinearGradient(
                    colors: [
                      context.glassSurfaceHigh(
                        lightAlpha: 0.9,
                        darkAlpha: 0.94,
                      ),
                      dark
                          ? const Color(0xFF18232B).withValues(alpha: 0.92)
                          : const Color(0xFFE1EBEE).withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: dark
                          ? Colors.black.withValues(alpha: 0.34)
                          : const Color(0xFF7FE6DB).withValues(alpha: 0.16),
                      blurRadius: 56,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(phone ? 20 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF2A3147)
                                : const Color(0xFFDDE7F7),
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: const SilvatorMascotAvatar(
                            mood: MoodType.calm,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            semanticLabel: 'Selvator mascot',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Selvator',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: context.brandInk(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Build your sanctuary.',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: phone ? 34 : 40,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose the moods you want Selvator to understand first. The app will use them to personalize $widgetCopy.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        hintText: 'How should Selvator greet you?',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your greeting style',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<UserGender>(
                        emptySelectionAllowed: true,
                        segments: const [
                          ButtonSegment(
                            value: UserGender.male,
                            icon: Icon(Icons.male_rounded),
                            label: Text('Male'),
                          ),
                          ButtonSegment(
                            value: UserGender.female,
                            icon: Icon(Icons.female_rounded),
                            label: Text('Female'),
                          ),
                        ],
                        selected: _selectedGender == null
                            ? const <UserGender>{}
                            : {_selectedGender!},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _selectedGender = selection.isEmpty
                                ? null
                                : selection.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your opening moods (up to 3)',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final mood in MoodType.values) ...[
                          Builder(
                            builder: (context) {
                              final selected = _selectedMoods.contains(mood);
                              final enabled =
                                  selected ||
                                  _selectedMoods.length <
                                      maxSelectedMoodSelections;
                              return FilterChip(
                                avatar: SilvatorMascotAvatar(
                                  mood: mood,
                                  width: 22,
                                  height: 22,
                                ),
                                label: Text(mood.label),
                                selected: selected,
                                tooltip: enabled ? null : 'Pick up to 3 moods',
                                onSelected: enabled
                                    ? (selected) {
                                        setState(() {
                                          if (selected &&
                                              _selectedMoods.length <
                                                  maxSelectedMoodSelections) {
                                            _selectedMoods.add(mood);
                                          } else if (!selected &&
                                              _selectedMoods.length > 1) {
                                            _selectedMoods.remove(mood);
                                          }
                                        });
                                      }
                                    : null,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: canEnter
                              ? () {
                                  controller.completeOnboarding(
                                    displayName: _nameController.text,
                                    gender: _selectedGender!,
                                    preferredMoods: _selectedMoods.toList(
                                      growable: false,
                                    ),
                                  );
                                }
                              : null,
                          child: const Text('Enter the sanctuary'),
                        ),
                        TextButton(
                          onPressed: canSkip
                              ? () {
                                  controller.completeOnboarding(
                                    displayName: _nameController.text,
                                    gender: _selectedGender!,
                                    preferredMoods: const [],
                                    skipped: true,
                                  );
                                }
                              : null,
                          child: const Text('Skip and show me a quote'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePersonalizationScreen extends ConsumerStatefulWidget {
  const ProfilePersonalizationScreen({super.key});

  @override
  ConsumerState<ProfilePersonalizationScreen> createState() =>
      _ProfilePersonalizationScreenState();
}

class _ProfilePersonalizationScreenState
    extends ConsumerState<ProfilePersonalizationScreen> {
  late final TextEditingController _nameController;
  UserGender? _selectedGender;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(wiselyControllerProvider).profile;
    _nameController = TextEditingController(text: profile.displayName);
    _selectedGender = profile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(wiselyControllerProvider.notifier);
    final theme = Theme.of(context);
    final dark = context.isDarkMode;
    final phone = MediaQuery.sizeOf(context).width < 420;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: [
                      context.glassSurfaceHigh(
                        lightAlpha: 0.92,
                        darkAlpha: 0.94,
                      ),
                      dark
                          ? const Color(0xFF18232B).withValues(alpha: 0.92)
                          : const Color(0xFFE1EBEE).withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: dark
                          ? Colors.black.withValues(alpha: 0.32)
                          : const Color(0xFF7FE6DB).withValues(alpha: 0.16),
                      blurRadius: 44,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(phone ? 20 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipOval(
                          child: SilvatorMascotAvatar(
                            mood: ref
                                .watch(wiselyControllerProvider)
                                .selectedMood,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            semanticLabel: 'Selvator mascot',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Help Selvator greet you right.',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: context.brandInk(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Choose the greeting style Selvator should use for you.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        hintText: 'Leave blank to use friend',
                      ),
                    ),
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<UserGender>(
                        emptySelectionAllowed: true,
                        segments: const [
                          ButtonSegment(
                            value: UserGender.male,
                            icon: Icon(Icons.male_rounded),
                            label: Text('Male'),
                          ),
                          ButtonSegment(
                            value: UserGender.female,
                            icon: Icon(Icons.female_rounded),
                            label: Text('Female'),
                          ),
                        ],
                        selected: _selectedGender == null
                            ? const <UserGender>{}
                            : {_selectedGender!},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _selectedGender = selection.isEmpty
                                ? null
                                : selection.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _selectedGender == null
                          ? null
                          : () {
                              controller.completeProfilePersonalization(
                                displayName: _nameController.text,
                                gender: _selectedGender!,
                              );
                            },
                      child: const Text('Save greeting style'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.controller, required this.tablet});

  final WiselyController controller;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: controller.isDecompressing
              ? DecompressScreen(controller: controller)
              : IndexedStack(
                  index: controller.selectedTab,
                  children: [
                    HomeScreen(
                      controller: controller,
                      showDesktopSearch: false,
                      tablet: tablet,
                      onOpenDetails: (quote) => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => QuoteDetailRoute(quote: quote),
                        ),
                      ),
                    ),
                    JournalScreen(controller: controller),
                    FavoritesHistoryScreen(
                      controller: controller,
                      onOpenDetails: (quote) => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => QuoteDetailRoute(quote: quote),
                        ),
                      ),
                    ),
                    SettingsProfileScreen(controller: controller),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _BottomDock(
        selectedIndex: controller.selectedTab,
        onDestinationSelected: controller.setSelectedTab,
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.controller});

  final WiselyController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Row(
          children: [
            _DesktopSidebar(controller: controller),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 18, 18, 18),
                child: controller.isDecompressing
                    ? DecompressScreen(controller: controller)
                    : IndexedStack(
                        index: controller.selectedTab,
                        children: [
                          HomeScreen(
                            controller: controller,
                            showDesktopSearch: true,
                            tablet: true,
                            onOpenDetails: controller.openQuoteDetail,
                          ),
                          JournalScreen(controller: controller),
                          FavoritesHistoryScreen(
                            controller: controller,
                            onOpenDetails: controller.openQuoteDetail,
                          ),
                          SettingsProfileScreen(controller: controller),
                        ],
                      ),
              ),
            ),
            if (controller.hasRightPanel)
              SizedBox(
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 18, 18, 18),
                  child: _DesktopRightPanel(controller: controller),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.showDesktopSearch,
    required this.tablet,
    required this.onOpenDetails,
  });

  final WiselyController controller;
  final bool showDesktopSearch;
  final bool tablet;
  final ValueChanged<QuoteEntry> onOpenDetails;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  QuoteFeedFilter _feedFilter = QuoteFeedFilter.recommended;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final profile = controller.profile;
    final quoteOfDay = controller.quoteOfDay;
    final accent = moodColors[controller.selectedMood]!;
    final selectedMoodLabel = _moodSelectionLabel(controller.selectedMoods);
    final feedQuotes = controller.quoteFeed(
      filter: _feedFilter,
      limit: widget.showDesktopSearch ? 18 : 12,
    );
    final phone = MediaQuery.sizeOf(context).width < 420;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        widget.showDesktopSearch ? 24 : (phone ? 16 : 20),
        widget.showDesktopSearch ? 20 : 16,
        widget.showDesktopSearch ? 24 : (phone ? 16 : 20),
        widget.showDesktopSearch ? 28 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.showDesktopSearch)
            const _ScreenTopBar(
              title: 'Selvator',
              subtitle: '',
              icon: Icons.settings_rounded,
            ),
          _HeroStatement(
            greeting: controller.homeGreeting,
            greetingOverride: controller.greetingOverride,
            selectedMood: controller.selectedMood,
          ),
          SizedBox(height: widget.showDesktopSearch ? 18 : 24),
          MoodChipRow(
            selectedMood: controller.selectedMood,
            selectedMoods: controller.selectedMoods,
            maxSelectedMoods: maxSelectedMoodSelections,
            onMoodSelected: controller.toggleMoodSelection,
          ),
          SizedBox(height: widget.showDesktopSearch ? 22 : 28),
          _HomeQuoteFeed(
            quotes: feedQuotes,
            filter: _feedFilter,
            selectedMoodLabel: selectedMoodLabel,
            profile: profile,
            controller: controller,
            compact: widget.showDesktopSearch,
            onFilterChanged: (filter) => setState(() => _feedFilter = filter),
            onOpenDetails: widget.onOpenDetails,
          ),
          if (!widget.showDesktopSearch) ...[
            const SizedBox(height: 22),
            _InsightGrid(
              tablet: widget.tablet,
              accent: accent,
              quoteOfDay: quoteOfDay,
              quoteOfDayLiked:
                  quoteOfDay != null &&
                  profile.likedQuoteIds.contains(quoteOfDay.id),
              selectedMood: controller.selectedMood,
              savedCount: controller.profile.likedQuoteIds.length,
              avgRefreshRate: controller.sessionAggregates.avgRefreshRate,
              onLikeQuote: controller.toggleLike,
              onCopyQuote: controller.copyQuote,
              onShareQuote: controller.shareQuote,
              onOpenQuoteOfDay: quoteOfDay == null
                  ? null
                  : () => widget.onOpenDetails(quoteOfDay),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeQuoteFeed extends StatelessWidget {
  const _HomeQuoteFeed({
    required this.quotes,
    required this.filter,
    required this.selectedMoodLabel,
    required this.profile,
    required this.controller,
    required this.compact,
    required this.onFilterChanged,
    required this.onOpenDetails,
  });

  final List<QuoteEntry> quotes;
  final QuoteFeedFilter filter;
  final String selectedMoodLabel;
  final UserProfile profile;
  final WiselyController controller;
  final bool compact;
  final ValueChanged<QuoteFeedFilter> onFilterChanged;
  final ValueChanged<QuoteEntry> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentQuote = controller.currentQuote;
    final phone = MediaQuery.sizeOf(context).width < 420;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: phone ? 360 : 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$selectedMoodLabel quotes',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _quoteFeedFilterDescription(filter),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: controller.refreshQuote,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('New quote'),
            ),
            if (controller.supportsHomeWidgets && currentQuote != null)
              Tooltip(
                message: 'Update Android home widget',
                child: OutlinedButton.icon(
                  onPressed: controller.sendCurrentQuoteToWidget,
                  icon: const Icon(Icons.widgets_rounded),
                  label: const Text('Update widget'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in QuoteFeedFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_quoteFeedFilterLabel(option)),
                    selected: filter == option,
                    onSelected: (_) => onFilterChanged(option),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (quotes.isEmpty)
          const _EmptyCard(
            title: 'No quote yet',
            message:
                'Pick one or more moods and Selvator will bring the right words forward.',
          )
        else
          for (var index = 0; index < quotes.length; index++) ...[
            _QuoteFeedTile(
              quote: quotes[index],
              mood: controller.displayMoodForQuote(quotes[index]),
              index: index,
              filter: filter,
              compact: compact,
              isLiked: profile.likedQuoteIds.contains(quotes[index].id),
              onLike: () => controller.toggleLike(quotes[index]),
              onCopy: () => controller.copyQuote(quotes[index]),
              onShare: () => controller.shareQuote(quotes[index]),
              onShowDetails: () => onOpenDetails(quotes[index]),
            ),
            if (index != quotes.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _QuoteFeedTile extends StatelessWidget {
  const _QuoteFeedTile({
    required this.quote,
    required this.mood,
    required this.index,
    required this.filter,
    required this.compact,
    required this.isLiked,
    required this.onLike,
    required this.onCopy,
    required this.onShare,
    required this.onShowDetails,
  });

  final QuoteEntry quote;
  final MoodType mood;
  final int index;
  final QuoteFeedFilter filter;
  final bool compact;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onShowDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = moodColors[mood]!;
    final dark = context.isDarkMode;
    final phone = MediaQuery.sizeOf(context).width < 420;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassSurfaceHigh(lightAlpha: 0.78, darkAlpha: 0.82),
        borderRadius: BorderRadius.circular(phone ? 20 : 24),
        border: Border.all(
          color: index == 0
              ? accent.withValues(alpha: dark ? 0.36 : 0.42)
              : context.surfaceStroke(),
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.16)
                : accent.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(phone ? 20 : 24),
          onTap: onShowDetails,
          child: Padding(
            padding: EdgeInsets.all(phone ? 16 : (compact ? 18 : 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SilvatorMascotAvatar(mood: mood, width: 34, height: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _TinyPill(
                            label: index == 0 ? 'Now' : mood.label,
                            color: accent,
                          ),
                          _TinyPill(
                            label: _quoteFeedMetaLabel(quote, mood, filter),
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: isLiked ? 'Unsave quote' : 'Save quote',
                      onPressed: onLike,
                      icon: Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isLiked
                            ? const Color(0xFFDA5677)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"${quote.text}"',
                  maxLines: phone ? 5 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lora(
                    textStyle: theme.textTheme.titleLarge,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quote.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy quote',
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_rounded),
                    ),
                    IconButton(
                      tooltip: 'Share quote',
                      onPressed: onShare,
                      icon: const Icon(Icons.share_rounded),
                    ),
                    IconButton(
                      tooltip: 'Quote details',
                      onPressed: onShowDetails,
                      icon: const Icon(Icons.open_in_new_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDarkMode ? 0.2 : 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: context.isDarkMode ? 0.28 : 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

String _quoteFeedFilterLabel(QuoteFeedFilter filter) => switch (filter) {
  QuoteFeedFilter.recommended => 'Recommended',
  QuoteFeedFilter.popular => 'Popular',
  QuoteFeedFilter.fresh => 'Fresh',
  QuoteFeedFilter.short => 'Short',
  QuoteFeedFilter.deep => 'Deep',
};

String _quoteFeedFilterDescription(QuoteFeedFilter filter) => switch (filter) {
  QuoteFeedFilter.recommended => 'Matched to your mood mix and recent taste.',
  QuoteFeedFilter.popular => 'Highest popularity first.',
  QuoteFeedFilter.fresh => 'Quotes you have seen least recently.',
  QuoteFeedFilter.short => 'Quick reads for low-friction scrolling.',
  QuoteFeedFilter.deep => 'More reflective lines for sitting with the mood.',
};

String _quoteFeedMetaLabel(
  QuoteEntry quote,
  MoodType mood,
  QuoteFeedFilter filter,
) {
  return switch (filter) {
    QuoteFeedFilter.popular =>
      'Popularity ${NumberFormat.compact().format(quote.popularity)}',
    QuoteFeedFilter.fresh => 'Fresh pick',
    QuoteFeedFilter.short => '${quote.text.length} chars',
    QuoteFeedFilter.deep =>
      '${quote.effectiveArcTier(mood).name} · rhythm ${quote.rhythmScore}',
    QuoteFeedFilter.recommended =>
      '${quote.effectiveArcTier(mood).name} · ${mood.label}',
  };
}

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key, required this.controller});

  final WiselyController controller;

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 420;
    return ListView(
      padding: EdgeInsets.fromLTRB(phone ? 16 : 20, 16, phone ? 16 : 20, 16),
      children: [
        const _ScreenTopBar(
          title: 'Safe Space',
          subtitle: 'Private reflections for what you are carrying',
          icon: Icons.edit_note_rounded,
        ),
        const SizedBox(height: 18),
        _JournalSafeSpaceHeader(
          selectedMoods: controller.selectedMoods,
          selectedMood: controller.selectedMood,
        ),
        const SizedBox(height: 18),
        _GuidedJournalComposer(
          selectedMood: controller.selectedMood,
          selectedMoods: controller.selectedMoods,
          onSave: controller.saveMoodJournalEntry,
        ),
        const SizedBox(height: 18),
        _JournalTimelineFilters(
          filter: controller.journalFilter,
          moodFilter: controller.journalMoodFilter,
          discreetMode: controller.journalDiscreetMode,
          onFilterChanged: controller.setJournalFilter,
          onMoodFilterChanged: controller.setJournalMoodFilter,
          onDiscreetChanged: controller.setJournalDiscreetMode,
        ),
        const SizedBox(height: 18),
        _JournalTimeline(
          entries: controller.journalEntries,
          discreetMode: controller.journalDiscreetMode,
          onDelete: controller.deleteMoodJournalEntry,
        ),
        const SizedBox(height: 18),
        _EmotionalWeatherChart(points: controller.emotionalWeather),
      ],
    );
  }
}

class DecompressScreen extends StatefulWidget {
  const DecompressScreen({super.key, required this.controller});

  final WiselyController controller;

  @override
  State<DecompressScreen> createState() => _DecompressScreenState();
}

class _DecompressScreenState extends State<DecompressScreen>
    with TickerProviderStateMixin {
  static const _totalSeconds = 18;
  static const _cycleSeconds = 6;

  late final AnimationController _breathController;
  Timer? _timer;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _cycleSeconds),
    )..repeat(reverse: true);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _start() {
    _setPhase(DecompressState.inhale);
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += 1;
      if (_elapsed >= _totalSeconds) {
        _timer?.cancel();
        widget.controller.updateDecompressionState(DecompressState.complete);
        widget.controller.completeDecompression();
        return;
      }
      final cycleSecond = _elapsed % _cycleSeconds;
      final next = cycleSecond < 3
          ? DecompressState.inhale
          : cycleSecond == 3
          ? DecompressState.hold
          : DecompressState.exhale;
      if (next == DecompressState.inhale &&
          widget.controller.decompressState != DecompressState.inhale) {
        HapticFeedback.heavyImpact();
      }
      _setPhase(next);
    });
  }

  void _setPhase(DecompressState state) {
    widget.controller.updateDecompressionState(state);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _skipBreathing() async {
    _timer?.cancel();
    _breathController.stop();
    unawaited(HapticFeedback.selectionClick());
    await widget.controller.completeDecompression();
  }

  @override
  Widget build(BuildContext context) {
    final mood =
        widget.controller.pendingQuoteMood ?? widget.controller.selectedMood;
    final phase = widget.controller.decompressState;
    final progress = (_elapsed / _totalSeconds).clamp(0.0, 1.0);
    final accent = moodColors[mood]!;
    final phaseLabel = switch (phase) {
      DecompressState.hold => 'Hold',
      DecompressState.exhale => 'Exhale',
      DecompressState.complete => 'Ready',
      _ => 'Inhale',
    };
    final phaseTitle = switch (phase) {
      DecompressState.hold => 'Hold the quiet',
      DecompressState.exhale => 'Let the weight leave',
      DecompressState.complete => 'Quote is ready',
      _ => 'Draw the air in',
    };
    final phaseBody = switch (phase) {
      DecompressState.hold => 'Stay still for a beat. Nothing needs fixing.',
      DecompressState.exhale => 'Drop your shoulders and let the day loosen.',
      DecompressState.complete => 'Selvator has the quote waiting for you.',
      _ => 'Slow breath through the nose. Give yourself room first.',
    };
    final cycle = (_elapsed ~/ _cycleSeconds).clamp(0, 2) + 1;
    final secondsLeft = (_totalSeconds - _elapsed).clamp(0, _totalSeconds);
    final phone = MediaQuery.sizeOf(context).width < 420;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(phone ? 16 : 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            padding: EdgeInsets.all(phone ? 20 : 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.glassSurfaceHigh(lightAlpha: 0.92, darkAlpha: 0.94),
                  accent.withValues(alpha: context.isDarkMode ? 0.18 : 0.24),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(phone ? 28 : 34),
              border: Border.all(color: context.surfaceStroke()),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(
                    alpha: context.isDarkMode ? 0.14 : 0.18,
                  ),
                  blurRadius: 44,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: context.accentSurface(accent),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.surfaceStroke()),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SilvatorMascotAvatar(
                        mood: mood,
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                        semanticLabel: '${mood.label} decompression mascot',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Decompression',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cycle $cycle of 3',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _skipBreathing,
                      icon: const Icon(Icons.close_rounded),
                      label: Text(phone ? 'Skip' : 'Skip breathing'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _BreathingStage(
                  animation: _breathController,
                  phase: phase,
                  phaseLabel: phaseLabel,
                  mood: mood,
                  accent: accent,
                  size: phone ? 224 : 264,
                ),
                const SizedBox(height: 22),
                _BreathCycleDots(cycle: cycle, accent: accent),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    color: accent,
                    backgroundColor: context.surfaceStroke(),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  phaseTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: context.brandInk(),
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$phaseBody Stay with the breath. $secondsLeft seconds left.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _skipBreathing,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Show quote now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingStage extends StatelessWidget {
  const _BreathingStage({
    required this.animation,
    required this.phase,
    required this.phaseLabel,
    required this.mood,
    required this.accent,
    required this.size,
  });

  final Animation<double> animation;
  final DecompressState phase;
  final String phaseLabel;
  final MoodType mood;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final motionDisabled = MediaQuery.disableAnimationsOf(context);
    if (motionDisabled) {
      return _BreathingStageFrame(
        phase: phase,
        phaseLabel: phaseLabel,
        mood: mood,
        accent: accent,
        size: size,
        value: 0.65,
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return _BreathingStageFrame(
          phase: phase,
          phaseLabel: phaseLabel,
          mood: mood,
          accent: accent,
          size: size,
          value: animation.value,
          lottie: Lottie.asset(
            'assets/animations/breathing_circle.json',
            controller: animation,
          ),
        );
      },
    );
  }
}

class _BreathingStageFrame extends StatelessWidget {
  const _BreathingStageFrame({
    required this.phase,
    required this.phaseLabel,
    required this.mood,
    required this.accent,
    required this.size,
    required this.value,
    this.lottie,
  });

  final DecompressState phase;
  final String phaseLabel;
  final MoodType mood;
  final Color accent;
  final double size;
  final double value;
  final Widget? lottie;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final phaseScale = switch (phase) {
      DecompressState.hold => 1.03,
      DecompressState.exhale => 1.08 - (value * 0.14),
      DecompressState.complete => 1.0,
      _ => 0.92 + (value * 0.14),
    };
    final ringAlpha = switch (phase) {
      DecompressState.exhale => 0.12 + (value * 0.08),
      DecompressState.hold => 0.18,
      _ => 0.16 + (value * 0.10),
    };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: phaseScale,
            child: Container(
              width: size * 0.96,
              height: size * 0.96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: dark ? 0.24 : 0.34),
                  width: 1.4,
                ),
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: ringAlpha),
                    accent.withValues(alpha: ringAlpha * 0.44),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.58, 1.0],
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.88 + (phaseScale - 1).abs(),
            child: Container(
              width: size * 0.72,
              height: size * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.glassSurface(lightAlpha: 0.52, darkAlpha: 0.54),
                border: Border.all(color: context.surfaceStroke()),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: dark ? 0.16 : 0.20),
                    blurRadius: 34,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
            ),
          ),
          if (lottie != null)
            Opacity(
              opacity: dark ? 0.26 : 0.34,
              child: SizedBox(
                width: size * 0.86,
                height: size * 0.86,
                child: lottie,
              ),
            ),
          Container(
            width: size * 0.44,
            height: size * 0.50,
            decoration: BoxDecoration(
              color: context.accentSurface(accent, lightAlpha: 0.18),
              borderRadius: BorderRadius.circular(size * 0.16),
              border: Border.all(color: context.surfaceStroke()),
            ),
            clipBehavior: Clip.antiAlias,
            child: SilvatorMascotAvatar(
              mood: mood,
              width: size * 0.44,
              height: size * 0.50,
              fit: BoxFit.contain,
              semanticLabel: '${mood.label} breathing mascot',
            ),
          ),
          Positioned(
            bottom: size * 0.12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.glassSurface(lightAlpha: 0.76, darkAlpha: 0.82),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.surfaceStroke()),
              ),
              child: Text(
                phaseLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.brandInk(),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathCycleDots extends StatelessWidget {
  const _BreathCycleDots({required this.cycle, required this.accent});

  final int cycle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 1; index <= 3; index++) ...[
          AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: index == cycle ? 36 : 14,
            height: 10,
            decoration: BoxDecoration(
              color: index <= cycle
                  ? accent.withValues(alpha: index == cycle ? 0.86 : 0.52)
                  : context.surfaceStroke(),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          if (index < 3) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _EmotionalWeatherChart extends StatelessWidget {
  const _EmotionalWeatherChart({required this.points});

  final List<EmotionalWeatherPoint> points;

  @override
  Widget build(BuildContext context) {
    final recent = points.reversed
        .take(14)
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.area_chart_rounded, color: context.brandInk()),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Emotional weather',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 150,
              child: recent.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Your journal weather will appear after a few mood check-ins.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        maxY: 6,
                        minY: 0,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final point = recent[group.x.toInt()];
                              return BarTooltipItem(
                                '${point.mood.label}\n${DateFormat.MMMd().format(point.date)}',
                                Theme.of(context).textTheme.bodySmall ??
                                    const TextStyle(),
                              );
                            },
                          ),
                        ),
                        barGroups: [
                          for (var index = 0; index < recent.length; index++)
                            BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: recent[index].count
                                      .clamp(1, 6)
                                      .toDouble(),
                                  width: 12,
                                  borderRadius: BorderRadius.circular(999),
                                  color: moodColors[recent[index].mood],
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: 6,
                                    color: context.surfaceStroke(),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalSafeSpaceHeader extends StatelessWidget {
  const _JournalSafeSpaceHeader({
    required this.selectedMoods,
    required this.selectedMood,
  });

  final List<MoodType> selectedMoods;
  final MoodType selectedMood;

  @override
  Widget build(BuildContext context) {
    final accent = moodColors[selectedMood]!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.glassSurfaceHigh(lightAlpha: 0.86, darkAlpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: context.surfaceStroke()),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: SilvatorMascotAvatar(
              mood: selectedMood,
              width: 72,
              height: 72,
              semanticLabel: '${selectedMood.label} journal mascot',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write it without cleaning it up first.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This stays on this device. Selvator will hold the page softly while you name what happened, what you felt, and what helped.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final mood in selectedMoods)
                      _JournalMoodPill(mood: mood, selected: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidedJournalComposer extends StatefulWidget {
  const _GuidedJournalComposer({
    required this.selectedMood,
    required this.selectedMoods,
    required this.onSave,
  });

  final MoodType selectedMood;
  final List<MoodType> selectedMoods;
  final Future<void> Function({
    required String note,
    String situation,
    String feelings,
    String handledWith,
    String needNow,
    String kindSelfTalk,
  })
  onSave;

  @override
  State<_GuidedJournalComposer> createState() => _GuidedJournalComposerState();
}

class _GuidedJournalComposerState extends State<_GuidedJournalComposer> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _situationController = TextEditingController();
  final TextEditingController _feelingsController = TextEditingController();
  final TextEditingController _handledWithController = TextEditingController();
  final TextEditingController _needNowController = TextEditingController();
  final TextEditingController _kindSelfTalkController = TextEditingController();
  final Set<_JournalPrompt> _visiblePrompts = {};
  bool _saving = false;

  bool get _hasAnyText {
    return [
      _noteController,
      _situationController,
      _feelingsController,
      _handledWithController,
      _needNowController,
      _kindSelfTalkController,
    ].any((controller) => controller.text.trim().isNotEmpty);
  }

  bool get _canSave => _hasAnyText && !_saving;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_handleChanged);
    }
  }

  Iterable<TextEditingController> get _controllers sync* {
    yield _noteController;
    yield _situationController;
    yield _feelingsController;
    yield _handledWithController;
    yield _needNowController;
    yield _kindSelfTalkController;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_handleChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _handleChanged() {
    setState(() {});
  }

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(
      note: _noteController.text,
      situation: _situationController.text,
      feelings: _feelingsController.text,
      handledWith: _handledWithController.text,
      needNow: _needNowController.text,
      kindSelfTalk: _kindSelfTalkController.text,
    );
    if (!mounted) {
      return;
    }
    for (final controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _saving = false;
      _visiblePrompts.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = moodColors[widget.selectedMood]!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Safe-space entry', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Start anywhere. Use the prompts only if they help.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('mood-journal-note-field'),
              controller: _noteController,
              maxLength: 1200,
              maxLines: 7,
              minLines: 5,
              inputFormatters: [LengthLimitingTextInputFormatter(1200)],
              decoration: const InputDecoration(
                labelText: 'Let it out',
                hintText:
                    'Say the messy part, the quiet part, or just a few words.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final prompt in _JournalPrompt.values)
                  FilterChip(
                    label: Text(prompt.label),
                    selected: _visiblePrompts.contains(prompt),
                    onSelected: (_) {
                      setState(() {
                        if (!_visiblePrompts.add(prompt)) {
                          _visiblePrompts.remove(prompt);
                        }
                      });
                    },
                  ),
              ],
            ),
            if (_visiblePrompts.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final prompt in _JournalPrompt.values)
                if (_visiblePrompts.contains(prompt)) ...[
                  _JournalPromptField(
                    prompt: prompt,
                    controller: _controllerForPrompt(prompt),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _canSave ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: context.isDarkMode
                      ? const Color(0xFFE8C877)
                      : accent,
                  foregroundColor: context.isDarkMode
                      ? const Color(0xFF1A1A14)
                      : Colors.white,
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.lock_rounded, size: 18),
                label: const Text('Save note'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextEditingController _controllerForPrompt(_JournalPrompt prompt) {
    return switch (prompt) {
      _JournalPrompt.situation => _situationController,
      _JournalPrompt.feelings => _feelingsController,
      _JournalPrompt.handledWith => _handledWithController,
      _JournalPrompt.needNow => _needNowController,
      _JournalPrompt.kindSelfTalk => _kindSelfTalkController,
    };
  }
}

class _JournalPromptField extends StatelessWidget {
  const _JournalPromptField({required this.prompt, required this.controller});

  final _JournalPrompt prompt;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: Key('journal-prompt-${prompt.name}'),
      controller: controller,
      maxLength: 360,
      maxLines: 3,
      minLines: 2,
      inputFormatters: [LengthLimitingTextInputFormatter(360)],
      decoration: InputDecoration(
        labelText: prompt.fieldLabel,
        hintText: prompt.hint,
        alignLabelWithHint: true,
      ),
    );
  }
}

class _JournalTimelineFilters extends StatelessWidget {
  const _JournalTimelineFilters({
    required this.filter,
    required this.moodFilter,
    required this.discreetMode,
    required this.onFilterChanged,
    required this.onMoodFilterChanged,
    required this.onDiscreetChanged,
  });

  final JournalEntryFilter filter;
  final MoodType? moodFilter;
  final bool discreetMode;
  final ValueChanged<JournalEntryFilter> onFilterChanged;
  final ValueChanged<MoodType?> onMoodFilterChanged;
  final ValueChanged<bool> onDiscreetChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Journal timeline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Tooltip(
                  message: 'Hide journal previews on cards',
                  child: Switch.adaptive(
                    value: discreetMode,
                    onChanged: onDiscreetChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in JournalEntryFilter.values)
                  ChoiceChip(
                    label: Text(_journalFilterLabel(option)),
                    selected: filter == option,
                    onSelected: (_) => onFilterChanged(option),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All moods'),
                      selected: moodFilter == null,
                      onSelected: (_) => onMoodFilterChanged(null),
                    ),
                  ),
                  for (final mood in MoodType.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: SilvatorMascotAvatar(
                          mood: mood,
                          width: 22,
                          height: 22,
                        ),
                        label: Text(mood.label),
                        selected: moodFilter == mood,
                        onSelected: (_) => onMoodFilterChanged(mood),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalTimeline extends StatefulWidget {
  const _JournalTimeline({
    required this.entries,
    required this.discreetMode,
    required this.onDelete,
  });

  final List<MoodJournalEntry> entries;
  final bool discreetMode;
  final Future<void> Function(String id) onDelete;

  @override
  State<_JournalTimeline> createState() => _JournalTimelineState();
}

class _JournalTimelineState extends State<_JournalTimeline> {
  final Set<String> _revealedEntryIds = {};
  final Set<String> _hiddenEntryIds = {};

  @override
  void didUpdateWidget(covariant _JournalTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.entries.map((entry) => entry.id).toSet();
    _revealedEntryIds.removeWhere((id) => !currentIds.contains(id));
    _hiddenEntryIds.removeWhere((id) => !currentIds.contains(id));
  }

  Future<void> _delete(String id) async {
    setState(() {
      _hiddenEntryIds.add(id);
      _revealedEntryIds.remove(id);
    });
    await widget.onDelete(id);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries
        .where((entry) => !_hiddenEntryIds.contains(entry.id))
        .toList(growable: false);
    if (entries.isEmpty) {
      return const _EmptyCard(
        title: 'No reflections here yet',
        message: 'When you save something, it will appear here softly.',
      );
    }
    return Column(
      children: [
        for (final entry in entries) ...[
          _JournalEntryCard(
            entry: entry,
            revealed:
                !widget.discreetMode || _revealedEntryIds.contains(entry.id),
            onToggleReveal: () {
              setState(() {
                if (!_revealedEntryIds.add(entry.id)) {
                  _revealedEntryIds.remove(entry.id);
                }
              });
            },
            onDelete: () => _delete(entry.id),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.entry,
    required this.revealed,
    required this.onToggleReveal,
    required this.onDelete,
  });

  final MoodJournalEntry entry;
  final bool revealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = moodColors[entry.primaryMood]!;
    final timestamp = DateFormat('MMM d, h:mm a').format(entry.createdAt);
    return Container(
      decoration: BoxDecoration(
        color: context.glassSurfaceHigh(lightAlpha: 0.82, darkAlpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.surfaceStroke()),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onToggleReveal,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SilvatorMascotAvatar(
                        mood: entry.primaryMood,
                        width: 42,
                        height: 42,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _moodSelectionLabel(entry.moods),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(timestamp, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: revealed
                          ? 'Hide reflection'
                          : 'Reveal reflection',
                      onPressed: onToggleReveal,
                      icon: Icon(
                        revealed
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete note',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!revealed)
                  Text(
                    'Private reflection saved',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  _JournalEntryDetails(entry: entry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JournalEntryDetails extends StatelessWidget {
  const _JournalEntryDetails({required this.entry});

  final MoodJournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final sections = [
      if (entry.note.trim().isNotEmpty)
        (label: 'What I needed to say', text: entry.note),
      if (entry.situation.trim().isNotEmpty)
        (label: 'What happened', text: entry.situation),
      if (entry.feelings.trim().isNotEmpty)
        (label: 'What it made me feel', text: entry.feelings),
      if (entry.handledWith.trim().isNotEmpty)
        (label: 'How I dealt with it', text: entry.handledWith),
      if (entry.needNow.trim().isNotEmpty)
        (label: 'What I need now', text: entry.needNow),
      if (entry.kindSelfTalk.trim().isNotEmpty)
        (label: 'Kind words back', text: entry.kindSelfTalk),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          Text(
            section.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            section.text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _JournalMoodPill extends StatelessWidget {
  const _JournalMoodPill({required this.mood, required this.selected});

  final MoodType mood;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = moodColors[mood]!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: selected ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SilvatorMascotAvatar(mood: mood, width: 20, height: 20),
            const SizedBox(width: 6),
            Text(
              mood.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 0,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _JournalPrompt { situation, feelings, handledWith, needNow, kindSelfTalk }

extension _JournalPromptText on _JournalPrompt {
  String get label {
    return switch (this) {
      _JournalPrompt.situation => 'What happened?',
      _JournalPrompt.feelings => 'What did it make you feel?',
      _JournalPrompt.handledWith => 'How did you deal with it?',
      _JournalPrompt.needNow => 'What do you need now?',
      _JournalPrompt.kindSelfTalk => 'Kind words back',
    };
  }

  String get fieldLabel {
    return switch (this) {
      _JournalPrompt.situation => 'What happened?',
      _JournalPrompt.feelings => 'What did it make you feel?',
      _JournalPrompt.handledWith => 'How did you deal with it?',
      _JournalPrompt.needNow => 'What do you need now?',
      _JournalPrompt.kindSelfTalk => 'What would you tell yourself kindly?',
    };
  }

  String get hint {
    return switch (this) {
      _JournalPrompt.situation => 'Name the moment without judging it.',
      _JournalPrompt.feelings =>
        'A word, a sentence, or a messy list is enough.',
      _JournalPrompt.handledWith => 'What did you do, avoid, try, or survive?',
      _JournalPrompt.needNow => 'Rest, space, courage, help, food, a plan...',
      _JournalPrompt.kindSelfTalk =>
        'Say it like you would to someone you love.',
    };
  }
}

String _journalFilterLabel(JournalEntryFilter filter) {
  return switch (filter) {
    JournalEntryFilter.recent => 'Recent',
    JournalEntryFilter.needNow => 'Need now',
    JournalEntryFilter.handledWith => 'Handled with',
  };
}

class FavoritesHistoryScreen extends StatefulWidget {
  const FavoritesHistoryScreen({
    super.key,
    required this.controller,
    required this.onOpenDetails,
  });

  final WiselyController controller;
  final ValueChanged<QuoteEntry> onOpenDetails;

  @override
  State<FavoritesHistoryScreen> createState() => _FavoritesHistoryScreenState();
}

class _FavoritesHistoryScreenState extends State<FavoritesHistoryScreen> {
  MoodType? _filterMood;

  @override
  Widget build(BuildContext context) {
    final favorites = widget.controller.favorites(mood: _filterMood);
    final phone = MediaQuery.sizeOf(context).width < 420;
    return ListView(
      padding: EdgeInsets.fromLTRB(phone ? 16 : 20, 16, phone ? 16 : 20, 16),
      children: [
        const _ScreenTopBar(
          title: 'Sacred Insights',
          subtitle: 'Your saved sanctuary moments',
          icon: Icons.tune_rounded,
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: MoodHeatmap(
              entries: widget.controller.profile.moodDailyCounts30d,
              filterMood: _filterMood,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All moods'),
                  selected: _filterMood == null,
                  onSelected: (_) => setState(() => _filterMood = null),
                ),
              ),
              for (final mood in MoodType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: SilvatorMascotAvatar(
                      mood: mood,
                      width: 22,
                      height: 22,
                    ),
                    label: Text(mood.label),
                    selected: _filterMood == mood,
                    onSelected: (_) => setState(() => _filterMood = mood),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (favorites.isEmpty)
          const _EmptyCard(
            title: 'Nothing saved yet',
            message:
                'Like a few quotes and Selvator will keep them in your sanctuary collection.',
          )
        else
          for (final quote in favorites) ...[
            QuoteCard(
              quote: quote,
              mood: _filterMood ?? widget.controller.selectedMood,
              isLiked: widget.controller.profile.likedQuoteIds.contains(
                quote.id,
              ),
              onLike: () => widget.controller.toggleLike(quote),
              onCopy: () => widget.controller.copyQuote(quote),
              onShare: () => widget.controller.shareQuote(quote),
              onShowDetails: () => widget.onOpenDetails(quote),
              compact: true,
              title: _filterMood?.label ?? 'Saved quote',
              subtitle: 'Kept close for the days you need it again.',
            ),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

class SettingsProfileScreen extends StatefulWidget {
  const SettingsProfileScreen({super.key, required this.controller});

  final WiselyController controller;

  @override
  State<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends State<SettingsProfileScreen> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.controller.profile.displayName,
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile;
    final phone = MediaQuery.sizeOf(context).width < 420;
    return ListView(
      padding: EdgeInsets.fromLTRB(phone ? 16 : 20, 16, phone ? 16 : 20, 16),
      children: [
        const _ScreenTopBar(
          title: 'Settings',
          subtitle: 'Refine your sanctuary experience',
          icon: Icons.settings_rounded,
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: EdgeInsets.all(phone ? 18 : 22),
            child: Row(
              children: [
                Container(
                  width: phone ? 58 : 72,
                  height: phone ? 58 : 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        moodColors[profile.widgetMood]!,
                        moodColors[moodAdjacencyMap[profile.widgetMood]!
                            .first]!,
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    profile.displayName.isEmpty
                        ? 'W'
                        : profile.displayName.characters.first.toUpperCase(),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName.isEmpty
                            ? 'Selvator companion'
                            : profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current sanctuary mood: ${profile.widgetMood.label}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Greeting style: ${profile.gender?.label ?? 'Choose style'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: EdgeInsets.all(phone ? 18 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  onSubmitted: widget.controller.updateDisplayName,
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<UserGender>(
                    segments: const [
                      ButtonSegment(
                        value: UserGender.male,
                        icon: Icon(Icons.male_rounded),
                        label: Text('Male'),
                      ),
                      ButtonSegment(
                        value: UserGender.female,
                        icon: Icon(Icons.female_rounded),
                        label: Text('Female'),
                      ),
                    ],
                    selected: {profile.gender ?? UserGender.male},
                    onSelectionChanged: (selection) {
                      widget.controller.updateGender(selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.tonal(
                  onPressed: () =>
                      widget.controller.updateDisplayName(_nameController.text),
                  child: const Text('Save name'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: EdgeInsets.all(phone ? 18 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<AppThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: AppThemeMode.system,
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.dark,
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {profile.themeMode},
                    onSelectionChanged: (selection) {
                      widget.controller.updateThemeMode(selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text('Text scale: ${profile.textScale.toStringAsFixed(2)}'),
                Slider(
                  min: 0.9,
                  max: 1.35,
                  divisions: 9,
                  value: profile.textScale,
                  onChanged: widget.controller.updateTextScale,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: EdgeInsets.all(phone ? 18 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood engine',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _MetricLine(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Author weight',
                  value: profile.authorWeight.toStringAsFixed(2),
                ),
                const SizedBox(height: 12),
                _MetricLine(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Tag weight',
                  value: profile.tagWeight.toStringAsFixed(2),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: widget.controller.resetAdaptiveWeights,
                  child: const Text('Reset adaptive weights'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: widget.controller.clearUserData,
                  child: const Text('Clear cache and local data'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF5C51EA), Color(0xFF6B59F7)],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need help?',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Selvator v1.0.0+1 for Android and Windows. Offline-first, local-only, mood-aware.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class QuoteDetailRoute extends ConsumerWidget {
  const QuoteDetailRoute({super.key, required this.quote});

  final QuoteEntry quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(wiselyControllerProvider.notifier);
    final mood = quote.moods.isEmpty ? MoodType.happy : quote.moods.first;
    final accent = moodColors[mood]!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('${mood.label} detail'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  context.glassSurfaceHigh(lightAlpha: 0.84, darkAlpha: 0.92),
                  accent.withValues(alpha: context.isDarkMode ? 0.18 : 0.12),
                ],
              ),
              border: Border.all(color: context.surfaceStroke()),
            ),
            child: _DetailBody(
              controller: controller,
              quote: quote,
              onOpenQuote: (nextQuote) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => QuoteDetailRoute(quote: nextQuote),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final dockSurface = context.glassSurface(lightAlpha: 0.78, darkAlpha: 0.9);
    final selectedSurface = context.selectedSurface();
    final selectedInk = context.brandInk();
    final idleInk = context.isDarkMode
        ? const Color(0xFF9FA9B8)
        : const Color(0xFF9AA0A9);

    const items = [
      (label: 'Sanctuary', icon: Icons.spa_rounded),
      (label: 'Journal', icon: Icons.edit_note_rounded),
      (label: 'Saved', icon: Icons.auto_awesome_rounded),
      (label: 'Profile', icon: Icons.person_rounded),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: dockSurface,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: context.surfaceStroke()),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
                  ? Colors.black.withValues(alpha: 0.22)
                  : const Color(0xFF5C51EA).withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedScale(
                    scale: selectedIndex == index ? 1.04 : 1,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onDestinationSelected(index),
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedIndex == index
                              ? selectedSurface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              items[index].icon,
                              color: selectedIndex == index
                                  ? selectedInk
                                  : idleInk,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              items[index].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: selectedIndex == index
                                        ? selectedInk
                                        : idleInk,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.controller});

  final WiselyController controller;

  @override
  Widget build(BuildContext context) {
    final moodTrail = controller.profile.recentMoodTrail.reversed
        .take(4)
        .toList();
    final selectedSurface = context.selectedSurface();
    final brandInk = context.brandInk();
    final idleInk = context.mutedInk();

    return Container(
      width: 246,
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.glassSurface(lightAlpha: 0.72, darkAlpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.surfaceStroke()),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: selectedSurface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.bubble_chart_rounded,
                            color: brandInk,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Selvator',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: brandInk),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: controller.searchController,
                      focusNode: controller.searchFocusNode,
                      onChanged: controller.updateSearchQuery,
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search_rounded),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (final entry in [
                      (index: 0, label: 'Sanctuary', icon: Icons.spa_rounded),
                      (
                        index: 1,
                        label: 'Journal',
                        icon: Icons.edit_note_rounded,
                      ),
                      (
                        index: 2,
                        label: 'Saved',
                        icon: Icons.auto_awesome_rounded,
                      ),
                      (index: 3, label: 'Profile', icon: Icons.person_rounded),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => controller.setSelectedTab(entry.index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: controller.selectedTab == entry.index
                                  ? selectedSurface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  entry.icon,
                                  color: controller.selectedTab == entry.index
                                      ? brandInk
                                      : idleInk,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  entry.label,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color:
                                            controller.selectedTab ==
                                                entry.index
                                            ? brandInk
                                            : idleInk,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Recent moods',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final mood in moodTrail)
                          Chip(
                            avatar: SilvatorMascotAvatar(
                              mood: mood,
                              width: 22,
                              height: 22,
                            ),
                            label: Text(mood.label),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Favorites',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${controller.profile.likedQuoteIds.length} saved quotes',
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Refresh pace ${controller.sessionAggregates.avgRefreshRate.toStringAsFixed(1)}/min',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DesktopRightPanel extends StatelessWidget {
  const _DesktopRightPanel({required this.controller});

  final WiselyController controller;

  @override
  Widget build(BuildContext context) {
    final detailQuote =
        controller.selectedDetailQuote ??
        (controller.searchResults.isNotEmpty
            ? controller.searchResults.first
            : null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Details', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  onPressed: controller.closeRightPanel,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (controller.searchResults.isNotEmpty) ...[
              Text(
                'Search results',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    for (final quote in controller.searchResults)
                      ListTile(
                        title: Text(
                          quote.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(quote.author),
                        onTap: () => controller.openQuoteDetail(quote),
                      ),
                    if (detailQuote != null) const Divider(height: 28),
                    if (detailQuote != null)
                      SizedBox(
                        height: 420,
                        child: _DetailBody(
                          controller: controller,
                          quote: detailQuote,
                          onOpenQuote: controller.openQuoteDetail,
                        ),
                      ),
                  ],
                ),
              ),
            ] else if (detailQuote != null) ...[
              Expanded(
                child: _DetailBody(
                  controller: controller,
                  quote: detailQuote,
                  onOpenQuote: controller.openQuoteDetail,
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text('Search for a quote or open a detail card.'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.controller,
    required this.quote,
    required this.onOpenQuote,
  });

  final WiselyController controller;
  final QuoteEntry quote;
  final ValueChanged<QuoteEntry> onOpenQuote;

  @override
  Widget build(BuildContext context) {
    final authorQuotes = controller.authorQuotes(quote.author);
    final likeCount = controller.profile.likedAuthors[quote.author] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          quote.text,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 14),
        Text(quote.author, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Text(
          'You liked this author $likeCount time${likeCount == 1 ? '' : 's'}.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mood in quote.moods)
              Chip(
                avatar: SilvatorMascotAvatar(mood: mood, width: 22, height: 22),
                label: Text(mood.label),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'More from this author',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        for (final authorQuote in authorQuotes.take(8))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              authorQuote.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              onPressed: () => controller.toggleLike(authorQuote),
              icon: Icon(
                controller.profile.likedQuoteIds.contains(authorQuote.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
            ),
            onTap: () => onOpenQuote(authorQuote),
          ),
      ],
    );
  }
}

class _ScreenTopBar extends StatelessWidget {
  const _ScreenTopBar({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final brandInk = context.brandInk();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.glassSurface(lightAlpha: 0.75, darkAlpha: 0.86),
            shape: BoxShape.circle,
            border: Border.all(color: context.surfaceStroke()),
          ),
          child: Icon(icon, color: brandInk),
        ),
      ],
    );
  }
}

class _HeroStatement extends StatelessWidget {
  const _HeroStatement({
    required this.greeting,
    required this.greetingOverride,
    required this.selectedMood,
  });

  final PersonalizedGreeting greeting;
  final String? greetingOverride;
  final MoodType selectedMood;

  @override
  Widget build(BuildContext context) {
    final accent = moodColors[selectedMood]!;

    Widget greetingText() {
      final width = MediaQuery.sizeOf(context).width;
      final phone = width < 420;
      final wide = width >= 1100;
      final theme = Theme.of(context);
      final headlineSize = phone ? 34.0 : (wide ? 50.0 : 42.0);
      final panelHeight = phone ? 214.0 : (wide ? 244.0 : 226.0);
      final salutationColor = context.isDarkMode
          ? const Color(0xFFF4D887)
          : const Color(0xFF8F6313);
      return SizedBox(
        width: double.infinity,
        height: panelHeight,
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<String>(
              '${greeting.salutation}-${greeting.headline}-${greetingOverride ?? ''}-${selectedMood.name}',
            ),
            child: AnimatedContainer(
              width: double.infinity,
              height: panelHeight,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.fromLTRB(
                phone ? 18 : 24,
                phone ? 18 : 22,
                phone ? 18 : 26,
                phone ? 20 : 26,
              ),
              decoration: BoxDecoration(
                color: context.glassSurface(lightAlpha: 0.5, darkAlpha: 0.34),
                borderRadius: BorderRadius.circular(phone ? 28 : 36),
                border: Border.all(
                  color: accent.withValues(
                    alpha: context.isDarkMode ? 0.28 : 0.32,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(
                      alpha: context.isDarkMode ? 0.08 : 0.16,
                    ),
                    blurRadius: phone ? 26 : 42,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: phone ? 38 : 42,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.accentSurface(accent, lightAlpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: accent.withValues(
                            alpha: context.isDarkMode ? 0.26 : 0.22,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: phone ? 12 : 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.42),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                greeting.salutation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: salutationColor,
                                  fontSize: phone ? 17 : 19,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: phone ? 14 : 16),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        greeting.headline,
                        maxLines: phone ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontSize: headlineSize,
                          fontWeight: FontWeight.w800,
                          height: 1.04,
                          letterSpacing: 0,
                          color: context.isDarkMode
                              ? const Color(0xFFF4F1F7)
                              : const Color(0xFF24272C),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final stage = _HeroMascotStage(
          selectedMood: selectedMood,
          accent: accent,
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(alignment: Alignment.centerRight, child: stage),
              const SizedBox(height: 14),
              greetingText(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: greetingText()),
            const SizedBox(width: 18),
            stage,
          ],
        );
      },
    );
  }
}

class _HeroMascotStage extends StatelessWidget {
  const _HeroMascotStage({required this.selectedMood, required this.accent});

  final MoodType selectedMood;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final motionDisabled = MediaQuery.disableAnimationsOf(context);
    final stage = AnimatedContainer(
      duration: motionDisabled
          ? Duration.zero
          : const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      width: 98,
      height: 112,
      decoration: BoxDecoration(
        color: context.accentSurface(accent, lightAlpha: 0.22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.surfaceStroke()),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: context.isDarkMode ? 0.14 : 0.22),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: motionDisabled
            ? Duration.zero
            : const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<String>('home-hero-mascot-stage-${selectedMood.name}'),
          child: SilvatorMascotAvatar(
            key: const Key('home-hero-mascot'),
            mood: selectedMood,
            width: 98,
            height: 112,
            fit: BoxFit.contain,
            semanticLabel: '${selectedMood.label} hero mascot',
          ),
        ),
      ),
    );

    if (motionDisabled) {
      return stage;
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey<MoodType>(selectedMood),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 640),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: Transform.scale(scale: 0.94 + (value * 0.06), child: child),
          ),
        );
      },
      child: stage,
    );
  }
}

class _InsightGrid extends StatelessWidget {
  const _InsightGrid({
    required this.tablet,
    required this.accent,
    required this.quoteOfDay,
    required this.quoteOfDayLiked,
    required this.selectedMood,
    required this.savedCount,
    required this.avgRefreshRate,
    required this.onLikeQuote,
    required this.onCopyQuote,
    required this.onShareQuote,
    this.onOpenQuoteOfDay,
  });

  final bool tablet;
  final Color accent;
  final QuoteEntry? quoteOfDay;
  final bool quoteOfDayLiked;
  final MoodType selectedMood;
  final int savedCount;
  final double avgRefreshRate;
  final ValueChanged<QuoteEntry> onLikeQuote;
  final ValueChanged<QuoteEntry> onCopyQuote;
  final ValueChanged<QuoteEntry> onShareQuote;
  final VoidCallback? onOpenQuoteOfDay;

  @override
  Widget build(BuildContext context) {
    final smallCards = [
      _MiniGlassTile(
        title: 'Saved insights',
        subtitle: '$savedCount quotes in your collection',
        icon: Icons.favorite_rounded,
        accent: const Color(0xFFFF9BB6),
      ),
      _MiniGlassTile(
        title: 'Weekly peace',
        subtitle: '${avgRefreshRate.toStringAsFixed(1)} taps per minute',
        icon: Icons.query_stats_rounded,
        accent: const Color(0xFF7FE6DB),
      ),
    ];

    if (!tablet) {
      return Column(
        children: [
          if (quoteOfDay != null)
            QuoteCard(
              quote: quoteOfDay!,
              mood: selectedMood,
              isLiked: quoteOfDayLiked,
              onLike: () => onLikeQuote(quoteOfDay!),
              onCopy: () => onCopyQuote(quoteOfDay!),
              onShare: () => onShareQuote(quoteOfDay!),
              onShowDetails: onOpenQuoteOfDay ?? () {},
              compact: true,
              title: 'Quote of the day',
              subtitle: 'A steady anchor from today’s curated pool.',
            ),
          if (quoteOfDay != null) const SizedBox(height: 16),
          for (final tile in smallCards) ...[tile, const SizedBox(height: 16)],
          _MoodOrbCard(
            selectedMood: selectedMood,
            accent: accent,
            compact: true,
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: quoteOfDay == null
                  ? const SizedBox.shrink()
                  : QuoteCard(
                      quote: quoteOfDay!,
                      mood: selectedMood,
                      isLiked: quoteOfDayLiked,
                      onLike: () => onLikeQuote(quoteOfDay!),
                      onCopy: () => onCopyQuote(quoteOfDay!),
                      onShare: () => onShareQuote(quoteOfDay!),
                      onShowDetails: onOpenQuoteOfDay ?? () {},
                      compact: true,
                      title: 'Featured activity',
                      subtitle: 'Today’s deterministic sanctuary anchor.',
                    ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                children: [
                  for (var index = 0; index < smallCards.length; index++) ...[
                    smallCards[index],
                    if (index < smallCards.length - 1)
                      const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _MoodOrbCard(selectedMood: selectedMood, accent: accent),
      ],
    );
  }
}

class _MiniGlassTile extends StatelessWidget {
  const _MiniGlassTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.glassSurface(lightAlpha: 0.72, darkAlpha: 0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.surfaceStroke()),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.accentSurface(accent, lightAlpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodOrbCard extends StatelessWidget {
  const _MoodOrbCard({
    required this.selectedMood,
    required this.accent,
    this.compact = false,
  });

  final MoodType selectedMood;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final companion = moodAdjacencyMap[selectedMood]!.first;
    final mascot = silvatorMascotProfileFor(selectedMood);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 22),
      decoration: BoxDecoration(
        color: context.glassSurface(lightAlpha: 0.6, darkAlpha: 0.78),
        borderRadius: BorderRadius.circular(compact ? 24 : 30),
        border: Border.all(color: context.surfaceStroke()),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 64 : 86,
            height: compact ? 72 : 96,
            decoration: BoxDecoration(
              color: context.accentSurface(accent),
              borderRadius: BorderRadius.circular(compact ? 22 : 28),
            ),
            clipBehavior: Clip.antiAlias,
            child: SilvatorMascotAvatar(
              key: const Key('mood-insight-mascot'),
              mood: selectedMood,
              width: compact ? 64 : 86,
              height: compact ? 72 : 96,
              fit: BoxFit.contain,
              semanticLabel: '${selectedMood.label} insight mascot',
            ),
          ),
          SizedBox(width: compact ? 12 : 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood insight',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${mascot.name}: ${mascot.symbol}',
                  style:
                      (compact
                              ? Theme.of(context).textTheme.titleMedium
                              : Theme.of(context).textTheme.titleLarge)
                          ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${mascot.description} Pair it with ${companion.label.toLowerCase()} to widen the emotional lens.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final brandInk = context.brandInk();
    return Row(
      children: [
        Icon(icon, color: brandInk),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: brandInk),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

class _InitializationErrorView extends StatelessWidget {
  const _InitializationErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selvator could not finish startup',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Restart after a full rebuild. If it still fails, this message shows the exact initialization step that broke.',
                    ),
                    const SizedBox(height: 16),
                    SelectableText(message),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}
