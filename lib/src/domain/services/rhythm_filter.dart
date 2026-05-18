import 'package:wisely/src/domain/entities/mood_energy.dart';

class RhythmRange {
  const RhythmRange(this.min, this.max);

  final int min;
  final int max;

  bool matches(int score) => score >= min && score <= max;
}

class RhythmFilter {
  const RhythmFilter();

  RhythmRange rangeFor(MoodEnergy energy) {
    switch (energy) {
      case MoodEnergy.low:
        return const RhythmRange(0, 58);
      case MoodEnergy.medium:
        return const RhythmRange(25, 78);
      case MoodEnergy.high:
        return const RhythmRange(42, 100);
    }
  }
}
