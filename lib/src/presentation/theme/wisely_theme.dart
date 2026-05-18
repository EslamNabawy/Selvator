import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/tide_season.dart';
import 'package:wisely/src/domain/entities/time_bucket.dart';

const Map<MoodType, Color> moodColors = {
  MoodType.happy: Color(0xFFF5B54D),
  MoodType.calm: Color(0xFF7FE6DB),
  MoodType.motivated: Color(0xFFFFB267),
  MoodType.love: Color(0xFFFF8EAF),
  MoodType.hopeful: Color(0xFFA2D77B),
  MoodType.reflective: Color(0xFF9CB4C9),
  MoodType.confident: Color(0xFFF39B3D),
  MoodType.grateful: Color(0xFFE7C96E),
  MoodType.tired: Color(0xFFA7B3C7),
  MoodType.focused: Color(0xFF67C7C0),
  MoodType.anxious: Color(0xFF89C6CC),
  MoodType.stressed: Color(0xFF6FA6A7),
  MoodType.nostalgic: Color(0xFFD9B6A3),
  MoodType.sad: Color(0xFF8FA9C8),
  MoodType.lonely: Color(0xFFB39CCB),
};

const Map<MoodType, IconData> moodIcons = {
  MoodType.happy: Icons.sentiment_very_satisfied_rounded,
  MoodType.calm: Icons.water_drop_rounded,
  MoodType.motivated: Icons.bolt_rounded,
  MoodType.love: Icons.favorite_rounded,
  MoodType.hopeful: Icons.auto_awesome_rounded,
  MoodType.reflective: Icons.psychology_alt_rounded,
  MoodType.confident: Icons.workspace_premium_rounded,
  MoodType.grateful: Icons.wb_sunny_rounded,
  MoodType.tired: Icons.bedtime_rounded,
  MoodType.focused: Icons.center_focus_strong_rounded,
  MoodType.anxious: Icons.flutter_dash_rounded,
  MoodType.stressed: Icons.air_rounded,
  MoodType.nostalgic: Icons.history_edu_rounded,
  MoodType.sad: Icons.cloud_rounded,
  MoodType.lonely: Icons.nightlight_round_rounded,
};

const Map<MoodType, String> moodGlyphs = {
  MoodType.happy: '🙂',
  MoodType.calm: '🌊',
  MoodType.motivated: '⚡',
  MoodType.love: '💗',
  MoodType.hopeful: '✨',
  MoodType.reflective: '🪞',
  MoodType.confident: '🦁',
  MoodType.grateful: '🌞',
  MoodType.tired: '🌙',
  MoodType.focused: '🎯',
  MoodType.anxious: '🫨',
  MoodType.stressed: '😮‍💨',
  MoodType.nostalgic: '📼',
  MoodType.sad: '🌧️',
  MoodType.lonely: '🫧',
};

Color moodSurface(MoodType mood, {double alpha = 0.18}) =>
    moodColors[mood]!.withValues(alpha: alpha);

class SeasonalPalette {
  const SeasonalPalette({
    required this.background,
    required this.surface,
    required this.primary,
  });

  final Color background;
  final Color surface;
  final Color primary;
}

class PaletteConfig {
  const PaletteConfig._();

  static SeasonalPalette resolve({
    required TideSeason season,
    required TimeBucket bucket,
    required Brightness brightness,
  }) {
    final dark = brightness == Brightness.dark;
    final seasonTint = switch (season) {
      TideSeason.stormy => const Color(0xFF6FA6A7),
      TideSeason.thawing => const Color(0xFFA2D77B),
      TideSeason.bright => const Color(0xFFF5B54D),
      TideSeason.still => const Color(0xFF7FE6DB),
    };
    final bucketTint = switch (bucket) {
      TimeBucket.morning => const Color(0xFFE7C96E),
      TimeBucket.afternoon => const Color(0xFF67C7C0),
      TimeBucket.night => const Color(0xFF9CB4C9),
      TimeBucket.lateNight => const Color(0xFFB39CCB),
    };
    return SeasonalPalette(
      background: dark
          ? Color.lerp(const Color(0xFF0F1217), seasonTint, 0.10)!
          : Color.lerp(const Color(0xFFE2EAED), seasonTint, 0.16)!,
      surface: dark
          ? Color.lerp(const Color(0xFF1B2028), bucketTint, 0.10)!
          : Color.lerp(const Color(0xFFEAF0F1), bucketTint, 0.14)!,
      primary: Color.lerp(seasonTint, bucketTint, 0.35)!,
    );
  }
}

extension WiselyThemeTokens on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color glassSurface({double lightAlpha = 0.72, double darkAlpha = 0.78}) =>
      isDarkMode
      ? const Color(0xFF1B1F27).withValues(alpha: darkAlpha)
      : const Color(0xFFE7EEF0).withValues(alpha: lightAlpha);

  Color glassSurfaceHigh({double lightAlpha = 0.84, double darkAlpha = 0.92}) =>
      isDarkMode
      ? const Color(0xFF202530).withValues(alpha: darkAlpha)
      : const Color(0xFFEFF3F4).withValues(alpha: lightAlpha);

  Color selectedSurface() =>
      isDarkMode ? const Color(0xFF2A3147) : const Color(0xFFDDE7F7);

  Color mutedInk() =>
      isDarkMode ? const Color(0xFFAEB7C5) : const Color(0xFF5A6067);

  Color brandInk() =>
      isDarkMode ? const Color(0xFFBAC2FF) : const Color(0xFF564BE5);

  Color surfaceStroke() =>
      isDarkMode ? const Color(0xFF343A45) : const Color(0xFFCCD8DE);

  Color accentSurface(Color accent, {double lightAlpha = 0.18}) =>
      accent.withValues(alpha: isDarkMode ? 0.24 : lightAlpha);
}

class WiselyTheme {
  static ThemeData light({
    TideSeason season = TideSeason.still,
    TimeBucket bucket = TimeBucket.morning,
  }) {
    final palette = PaletteConfig.resolve(
      season: season,
      bucket: bucket,
      brightness: Brightness.light,
    );
    final seed = palette.primary;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: palette.surface,
    );
    final headline = GoogleFonts.dmSansTextTheme();
    final base = GoogleFonts.dmSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: palette.primary,
        secondary: const Color(0xFF006760),
        tertiary: const Color(0xFFB03E67),
        surface: palette.surface,
        surfaceContainerLowest: const Color(0xFFEFF4F4),
        surfaceContainerLow: const Color(0xFFE4ECEE),
        surfaceContainer: const Color(0xFFDDE7EA),
        surfaceContainerHigh: const Color(0xFFD5E1E5),
        outline: const Color(0xFFB9C8CF),
      ),
      scaffoldBackgroundColor: palette.background,
      textTheme: base.copyWith(
        displayLarge: headline.displayLarge?.copyWith(
          color: const Color(0xFF222326),
          fontWeight: FontWeight.w800,
        ),
        displayMedium: headline.displayMedium?.copyWith(
          color: const Color(0xFF222326),
          fontWeight: FontWeight.w800,
        ),
        headlineLarge: headline.headlineLarge?.copyWith(
          color: const Color(0xFF222326),
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: headline.headlineMedium?.copyWith(
          color: const Color(0xFF222326),
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: headline.headlineSmall?.copyWith(
          color: const Color(0xFF222326),
          fontWeight: FontWeight.w700,
        ),
        titleLarge: headline.titleLarge?.copyWith(
          color: const Color(0xFF222326),
          fontWeight: FontWeight.w700,
        ),
        titleMedium: headline.titleMedium?.copyWith(
          color: const Color(0xFF222326),
          fontWeight: FontWeight.w700,
        ),
        titleSmall: headline.titleSmall?.copyWith(
          color: const Color(0xFF222326),
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.bodyLarge?.copyWith(color: const Color(0xFF2B2D31)),
        bodyMedium: base.bodyMedium?.copyWith(color: const Color(0xFF5E6168)),
        bodySmall: base.bodySmall?.copyWith(color: const Color(0xFF7A7E85)),
        labelLarge: base.labelLarge?.copyWith(
          color: const Color(0xFF4B4E54),
          fontWeight: FontWeight.w600,
        ),
        labelMedium: base.labelMedium?.copyWith(
          color: const Color(0xFF6C7077),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFE8EEF0).withValues(alpha: 0.9),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Color(0xFFCFDADF)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: const Color(0xFFDDE7F7),
        backgroundColor: const Color(0xFFE4ECEE).withValues(alpha: 0.92),
        labelTextStyle: WidgetStatePropertyAll(
          base.labelSmall!.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE3ECEF),
        hintStyle: base.bodyMedium?.copyWith(color: const Color(0xFF76808A)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFCBD7DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFCBD7DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF7D83E8)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        selectedColor: const Color(0xFFDDE7F7),
        backgroundColor: const Color(0xFFE3ECEF),
        side: BorderSide.none,
        labelStyle: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFFEAF0F1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
    );
  }

  static ThemeData dark({
    TideSeason season = TideSeason.still,
    TimeBucket bucket = TimeBucket.morning,
  }) {
    final palette = PaletteConfig.resolve(
      season: season,
      bucket: bucket,
      brightness: Brightness.dark,
    );
    final seed = palette.primary;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: palette.surface,
    );
    final headline = GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme);
    final base = GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: palette.primary,
        secondary: const Color(0xFF87DAD0),
        tertiary: const Color(0xFFFF9DB7),
        surface: palette.surface,
        onSurface: const Color(0xFFE8EBF1),
        onSurfaceVariant: const Color(0xFFB4BDCA),
        surfaceContainerLowest: const Color(0xFF0D1015),
        surfaceContainerLow: const Color(0xFF171B22),
        surfaceContainer: const Color(0xFF1B2028),
        surfaceContainerHigh: const Color(0xFF222832),
        surfaceContainerHighest: const Color(0xFF2A313D),
        outline: const Color(0xFF46505F),
      ),
      scaffoldBackgroundColor: palette.background,
      textTheme: base.copyWith(
        displayLarge: headline.displayLarge?.copyWith(
          color: const Color(0xFFF2F4F8),
          fontWeight: FontWeight.w800,
        ),
        displayMedium: headline.displayMedium?.copyWith(
          color: const Color(0xFFF2F4F8),
          fontWeight: FontWeight.w800,
        ),
        headlineLarge: headline.headlineLarge?.copyWith(
          color: const Color(0xFFF2F4F8),
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: headline.headlineMedium?.copyWith(
          color: const Color(0xFFF2F4F8),
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: headline.headlineSmall?.copyWith(
          color: const Color(0xFFF2F4F8),
          fontWeight: FontWeight.w700,
        ),
        titleLarge: headline.titleLarge?.copyWith(
          color: const Color(0xFFE8EBF1),
          fontWeight: FontWeight.w700,
        ),
        titleMedium: headline.titleMedium?.copyWith(
          color: const Color(0xFFE8EBF1),
          fontWeight: FontWeight.w700,
        ),
        titleSmall: headline.titleSmall?.copyWith(
          color: const Color(0xFFE8EBF1),
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.bodyLarge?.copyWith(color: const Color(0xFFDDE2EA)),
        bodyMedium: base.bodyMedium?.copyWith(color: const Color(0xFFB9C2CF)),
        bodySmall: base.bodySmall?.copyWith(color: const Color(0xFF98A3B2)),
        labelLarge: base.labelLarge?.copyWith(
          color: const Color(0xFFDDE2EA),
          fontWeight: FontWeight.w600,
        ),
        labelMedium: base.labelMedium?.copyWith(
          color: const Color(0xFFAEB7C5),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1B1F27).withValues(alpha: 0.86),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF343A45), space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF202530),
        hintStyle: base.bodyMedium?.copyWith(color: const Color(0xFF8994A3)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF343A45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF343A45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFA9B4FF)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        selectedColor: const Color(0xFF2A3147),
        backgroundColor: const Color(0xFF202530),
        side: BorderSide.none,
        labelStyle: base.labelLarge?.copyWith(
          color: const Color(0xFFDDE2EA),
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1B1F27),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
    );
  }
}
