import 'package:wisely/src/domain/entities/user_profile.dart';

class StreakEvaluation {
  const StreakEvaluation({required this.profile, this.greetingOverride});

  final UserProfile profile;
  final String? greetingOverride;
}

class StreakService {
  const StreakService();

  StreakEvaluation evaluate(UserProfile profile, DateTime now) {
    final lastOpen = profile.lastOpenAt;
    if (lastOpen.millisecondsSinceEpoch == 0) {
      final next = profile.copyWith(
        streak: 1,
        lastOpenAt: now,
        greetingOverride: null,
      );
      return StreakEvaluation(profile: next);
    }

    final daysSinceOpen = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(lastOpen.year, lastOpen.month, lastOpen.day)).inDays;
    if (daysSinceOpen <= 0) {
      return StreakEvaluation(profile: profile.copyWith(lastOpenAt: now));
    }
    if (daysSinceOpen <= 1) {
      return StreakEvaluation(
        profile: profile.copyWith(
          streak: profile.streak + 1,
          lastOpenAt: now,
          greetingOverride: null,
        ),
      );
    }

    final wasResting = profile.lastMoodTags.any(
      {'exhausted', 'grief', 'numb', 'empty', 'sad', 'tired'}.contains,
    );
    if (daysSinceOpen <= 4 && wasResting) {
      const override = 'You took some time offline. Your streak is safe.';
      return StreakEvaluation(
        profile: profile.copyWith(lastOpenAt: now, greetingOverride: override),
        greetingOverride: override,
      );
    }
    if (daysSinceOpen > 7) {
      const override = 'Welcome back. No pressure, just a quote for now.';
      return StreakEvaluation(
        profile: profile.copyWith(
          streak: 0,
          lastOpenAt: now,
          greetingOverride: override,
        ),
        greetingOverride: override,
      );
    }
    return StreakEvaluation(
      profile: profile.copyWith(
        streak: profile.streak + 1,
        lastOpenAt: now,
        greetingOverride: null,
      ),
    );
  }
}
