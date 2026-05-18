import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';

enum AppLifecyclePhase { active, inactive, paused, detached }

enum TrayAction { nextQuote, copyQuote, openApp, quitApp }

abstract class QuoteActionsPort {
  Future<void> copyQuote(QuoteEntry quote);

  Future<void> shareQuote(QuoteEntry quote);
}

abstract class QuoteWidgetPort {
  bool get isSupported;

  Future<void> syncQuote({required QuoteEntry quote, required MoodType mood});
}

abstract class TrayPort {
  Future<void> initialize();

  Future<void> dispose();

  Future<void> update({
    required String previewText,
    required MoodType selectedMood,
  });
}

abstract class AppExitPort {
  Never quit();
}
