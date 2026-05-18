import 'package:wisely/src/domain/entities/mood_type.dart';

class EmotionalWeatherPoint {
  const EmotionalWeatherPoint({
    required this.date,
    required this.mood,
    required this.count,
    required this.intensity,
  });

  final DateTime date;
  final MoodType mood;
  final int count;
  final double intensity;
}
