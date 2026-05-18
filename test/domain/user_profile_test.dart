import 'package:flutter_test/flutter_test.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/tide_season.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';

void main() {
  test('user profile serializes and restores gender', () {
    final profile = UserProfile.initial().copyWith(
      displayName: 'Eslam',
      gender: UserGender.male,
      preferredMoods: const [MoodType.happy],
    );

    final restored = UserProfile.fromJson(profile.toJson());

    expect(restored.gender, UserGender.male);
    expect(restored.hasGreetingProfile, isTrue);
  });

  test('old profile json without gender remains onboarded but incomplete', () {
    final restored = UserProfile.fromJson({
      'displayName': 'Eslam',
      'preferredMoods': ['happy'],
    });

    expect(restored.isOnboarded, isTrue);
    expect(restored.gender, isNull);
    expect(restored.hasGreetingProfile, isFalse);
  });

  test('unknown gender json is treated as missing', () {
    final restored = UserProfile.fromJson({
      'displayName': 'Eslam',
      'gender': 'unknown',
      'preferredMoods': ['happy'],
    });

    expect(restored.gender, isNull);
    expect(restored.hasGreetingProfile, isFalse);
  });

  test('serializes sophisticated engine state with old-profile defaults', () {
    final restored = UserProfile.fromJson({
      'displayName': 'Eslam',
      'gender': 'male',
      'preferredMoods': ['happy'],
      'tagPreferenceWeights': {'hope': 0.6},
      'frustrationIndex': 5,
      'streak': 4,
      'lastOpenAt': DateTime(2026, 5, 18).toIso8601String(),
      'lastMoodTags': ['sad', 'grief'],
      'tideSeason': 'stormy',
      'tideSnapshotStartedAt': DateTime(2026, 5, 1).toIso8601String(),
      'greetingOverride': 'Welcome back.',
    });

    expect(restored.tagPreferenceWeights['hope'], 0.6);
    expect(restored.frustrationIndex, 5);
    expect(restored.streak, 4);
    expect(restored.lastMoodTags, contains('grief'));
    expect(restored.tideSeason, TideSeason.stormy);
    expect(restored.greetingOverride, 'Welcome back.');

    final old = UserProfile.fromJson({'displayName': 'Old'});
    expect(old.tagPreferenceWeights, isEmpty);
    expect(old.frustrationIndex, 0);
    expect(old.tideSeason, TideSeason.still);
  });
}
