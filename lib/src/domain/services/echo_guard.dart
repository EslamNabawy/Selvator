import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';

class EchoGuardResult {
  const EchoGuardResult({required this.shouldDecompress});

  final bool shouldDecompress;
}

class EchoGuard {
  const EchoGuard();

  EchoGuardResult evaluate(UserProfile profile) {
    final trail = profile.recentMoodTrail.reversed.take(4).toList();
    final heavyCount = trail
        .where(
          {
            MoodType.tired,
            MoodType.anxious,
            MoodType.stressed,
            MoodType.sad,
            MoodType.lonely,
          }.contains,
        )
        .length;
    return EchoGuardResult(shouldDecompress: heavyCount >= 3);
  }
}
