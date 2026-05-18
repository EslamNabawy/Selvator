import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/tide_season.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';

class TideEvaluation {
  const TideEvaluation({required this.profile, required this.season});

  final UserProfile profile;
  final TideSeason season;
}

class TideService {
  const TideService();

  TideEvaluation checkSnapshot(UserProfile profile, DateTime now) {
    final snapshotStart =
        profile.tideSnapshotStartedAt.millisecondsSinceEpoch == 0
        ? DateTime(now.year, now.month, now.day)
        : profile.tideSnapshotStartedAt;
    final shouldRotate = now.difference(snapshotStart).inDays >= 30;
    final season = _seasonFor(profile.moodDailyCounts30d, now);
    return TideEvaluation(
      profile: profile.copyWith(
        tideSeason: season,
        tideSnapshotStartedAt: shouldRotate
            ? DateTime(now.year, now.month, now.day)
            : snapshotStart,
      ),
      season: season,
    );
  }

  TideSeason _seasonFor(Map<String, int> counts, DateTime now) {
    if (counts.isEmpty) {
      return TideSeason.still;
    }
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 30));
    var low = 0;
    var high = 0;
    var calm = 0;
    for (final entry in counts.entries) {
      final parts = entry.key.split('|');
      if (parts.length != 2) {
        continue;
      }
      final day = DateTime.tryParse(parts.first);
      if (day == null || day.isBefore(cutoff)) {
        continue;
      }
      final mood = MoodType.fromKey(parts.last);
      if ({
        MoodType.anxious,
        MoodType.stressed,
        MoodType.sad,
        MoodType.lonely,
      }.contains(mood)) {
        low += entry.value;
      } else if ({
        MoodType.happy,
        MoodType.motivated,
        MoodType.confident,
      }.contains(mood)) {
        high += entry.value;
      } else {
        calm += entry.value;
      }
    }
    if (low >= high + calm) {
      return TideSeason.stormy;
    }
    if (high > low + calm ~/ 2) {
      return TideSeason.bright;
    }
    if (low > 0 && high > 0) {
      return TideSeason.thawing;
    }
    return TideSeason.still;
  }
}
