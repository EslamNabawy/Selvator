import 'package:wisely/src/domain/entities/time_bucket.dart';

class ClockService {
  const ClockService();

  TimeBucket bucketFor(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      return TimeBucket.morning;
    }
    if (hour >= 12 && hour < 18) {
      return TimeBucket.afternoon;
    }
    if (hour >= 18 && hour < 23) {
      return TimeBucket.night;
    }
    return TimeBucket.lateNight;
  }

  Set<String> adjustTags(Set<String> tags, TimeBucket bucket) {
    return {
      ...tags,
      switch (bucket) {
        TimeBucket.morning => 'clarity',
        TimeBucket.afternoon => 'purpose',
        TimeBucket.night => 'reflection',
        TimeBucket.lateNight => 'rest',
      },
    };
  }
}
