import 'package:flutter_test/flutter_test.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/personalized_greeting.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/domain/services/greeting_service.dart';

void main() {
  const service = GreetingService();

  UserProfile profile(UserGender gender) {
    return UserProfile.initial().copyWith(
      displayName: 'Karim',
      gender: gender,
      preferredMoods: const [MoodType.happy],
    );
  }

  test('every mood has varied greeting templates', () {
    for (final mood in MoodType.values) {
      final greetings = {
        for (var seed = 1; seed <= 20; seed++)
          _key(
            service.greetingFor(
              profile: profile(UserGender.male),
              mood: mood,
              sessionSeed: seed,
            ),
          ),
      };

      expect(greetings.length, greaterThan(1), reason: mood.name);
    }
  });

  test('gender changes the address style', () {
    final male = service.greetingFor(
      profile: profile(UserGender.male),
      mood: MoodType.confident,
      sessionSeed: 42,
    );
    final female = service.greetingFor(
      profile: profile(UserGender.female),
      mood: MoodType.confident,
      sessionSeed: 42,
    );

    expect(_key(male), isNot(_key(female)));
  });

  test('same session seed is stable', () {
    final first = service.greetingFor(
      profile: profile(UserGender.male),
      mood: MoodType.calm,
      sessionSeed: 99,
    );
    final second = service.greetingFor(
      profile: profile(UserGender.male),
      mood: MoodType.calm,
      sessionSeed: 99,
    );

    expect(_key(first), _key(second));
  });

  test('mood change can produce a different greeting', () {
    final happy = service.greetingFor(
      profile: profile(UserGender.male),
      mood: MoodType.happy,
      sessionSeed: 7,
    );
    final sad = service.greetingFor(
      profile: profile(UserGender.male),
      mood: MoodType.sad,
      sessionSeed: 7,
    );

    expect(_key(happy), isNot(_key(sad)));
  });

  test('missing gender returns fallback greeting', () {
    final greeting = service.greetingFor(
      profile: UserProfile.initial(),
      mood: MoodType.happy,
      sessionSeed: 1,
    );

    expect(greeting, PersonalizedGreeting.fallback);
  });
}

String _key(PersonalizedGreeting greeting) {
  return '${greeting.salutation}|${greeting.headline}|${greeting.body}';
}
