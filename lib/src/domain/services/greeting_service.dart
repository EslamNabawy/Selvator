import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/personalized_greeting.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/domain/services/nickname_service.dart';

class GreetingService {
  const GreetingService({
    NicknameService nicknameService = const NicknameService(),
  }) : _nicknameService = nicknameService;

  final NicknameService _nicknameService;

  PersonalizedGreeting greetingFor({
    required UserProfile profile,
    required MoodType mood,
    required int sessionSeed,
  }) {
    final gender = profile.gender;
    if (gender == null) {
      return PersonalizedGreeting.fallback;
    }

    final nameInput = profile.displayName.trim().isEmpty
        ? 'friend'
        : profile.displayName;
    final nickname = _nicknameService.nickname(nameInput, gender: gender);
    final seed = _stableHash([
      sessionSeed.toString(),
      mood.name,
      gender.name,
      nickname,
      ...profile.recentMoodTrail.map((mood) => mood.name),
    ]);
    final address = _pick(_addresses[gender]!, seed);
    final templates = _templatesByMood[mood] ?? _neutralTemplates;
    final template = _pick(templates, seed ~/ 7);

    return PersonalizedGreeting(
      salutation: _fill(template.salutation, nickname, address, mood),
      headline: _fill(template.headline, nickname, address, mood),
      body: _fill(template.body, nickname, address, mood),
    );
  }

  static const Map<UserGender, List<String>> _addresses = {
    UserGender.male: ['my guy', 'captain', 'legend', 'mate', 'good man'],
    UserGender.female: ['lovely', 'star', 'dear one', 'bright girl', 'wonder'],
  };

  static const List<_GreetingTemplate> _neutralTemplates = [
    _GreetingTemplate(
      salutation: 'Hey {address}, {name}',
      headline: 'What is your heart carrying today?',
      body:
          'Selvator is here with a soft landing and a better quote for the moment.',
    ),
    _GreetingTemplate(
      salutation: 'Hi {name}, glad you are here',
      headline: 'Let us check the weather inside.',
      body:
          'Choose the mood that fits, and Selvator will keep the words close.',
    ),
    _GreetingTemplate(
      salutation: 'Welcome back, {address}',
      headline: 'Tiny check-in, real attention.',
      body: 'Selvator will follow your mood gently, without rushing the day.',
    ),
  ];

  static const Map<MoodType, List<_GreetingTemplate>> _templatesByMood = {
    MoodType.happy: [
      _GreetingTemplate(
        salutation: 'Hey {address}, {name}',
        headline: 'That happy spark looks good on you.',
        body:
            'Selvator found a bright lane for this mood. Let us keep it warm.',
      ),
      _GreetingTemplate(
        salutation: 'Look at you, {name}',
        headline: 'Joy is in the room today.',
        body:
            'Pick the shape of it, and Selvator will match the quote to the glow.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {address}',
        headline: 'Happy energy, clean and shining.',
        body: 'Selvator is keeping the words light, generous, and ready.',
      ),
      _GreetingTemplate(
        salutation: 'Welcome back, {name}',
        headline: 'This mood deserves a little spotlight.',
        body:
            'Stay with the good feeling. Selvator will bring the next line gently.',
      ),
    ],
    MoodType.calm: [
      _GreetingTemplate(
        salutation: 'Easy now, {name}',
        headline: 'Calm can be powerful too.',
        body:
            'Selvator is keeping the page quiet, clear, and close to your pace.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {address}',
        headline: 'Soft breath, steady room.',
        body: 'Let the noise step back. Selvator has calm words ready.',
      ),
      _GreetingTemplate(
        salutation: 'Good to see you, {name}',
        headline: 'Nothing to prove right now.',
        body: 'Selvator is tuned to calm, with space around every quote.',
      ),
      _GreetingTemplate(
        salutation: 'Hey {address}',
        headline: 'Your quiet side gets the front seat.',
        body: 'Stay settled. Selvator will keep this gentle and useful.',
      ),
    ],
    MoodType.motivated: [
      _GreetingTemplate(
        salutation: 'Ready, {name}?',
        headline: 'That motivated mood wants a clean start.',
        body:
            'Selvator is lining up sharp words without turning the volume too high.',
      ),
      _GreetingTemplate(
        salutation: 'Hey {address}',
        headline: 'Small move, strong direction.',
        body: 'Choose the mood mix and Selvator will keep the fire focused.',
      ),
      _GreetingTemplate(
        salutation: 'There you are, {name}',
        headline: 'Momentum is knocking.',
        body: 'Selvator has a quote ready for the next honest step.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {address}',
        headline: 'Let us make the energy useful.',
        body:
            'Motivation works best with aim. Selvator will keep the aim clear.',
      ),
    ],
    MoodType.love: [
      _GreetingTemplate(
        salutation: 'Hey {name}',
        headline: 'Love is taking up space today.',
        body: 'Selvator will keep the words tender, warm, and not too loud.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {address}',
        headline: 'Your heart seems awake.',
        body: 'Stay with the softness. Selvator has something kind lined up.',
      ),
      _GreetingTemplate(
        salutation: 'Welcome back, {name}',
        headline: 'This is a good day to be gentle.',
        body: 'Selvator is tuned to love without making it heavy.',
      ),
      _GreetingTemplate(
        salutation: 'Good to see you, {address}',
        headline: 'Warm mood, open hands.',
        body:
            'Let the feeling breathe. Selvator will bring the matching words.',
      ),
    ],
    MoodType.hopeful: [
      _GreetingTemplate(
        salutation: 'Hey {address}, {name}',
        headline: 'Hope is already doing its quiet work.',
        body: 'Selvator will keep the next quote pointed toward light.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {name}',
        headline: 'There is room for a better turn.',
        body:
            'Stay near that possibility. Selvator is tuned for hopeful words.',
      ),
      _GreetingTemplate(
        salutation: 'Welcome in, {address}',
        headline: 'Tiny hope still counts.',
        body: 'Selvator will not rush it. We will just give it room.',
      ),
      _GreetingTemplate(
        salutation: 'Good to see you, {name}',
        headline: 'The future gets a softer edge today.',
        body: 'Pick your mood mix and Selvator will keep the path warm.',
      ),
    ],
    MoodType.reflective: [
      _GreetingTemplate(
        salutation: 'Hey {name}',
        headline: 'Reflective mode looks thoughtful on you.',
        body: 'Selvator will keep the words spacious enough to think inside.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {address}',
        headline: 'A quiet look inward can still be brave.',
        body:
            'No rush. Selvator has a line ready for the part you are noticing.',
      ),
      _GreetingTemplate(
        salutation: 'Welcome back, {name}',
        headline: 'Let the thought land before it has to become anything.',
        body: 'Selvator is keeping this mood clear, soft, and honest.',
      ),
      _GreetingTemplate(
        salutation: 'Good to see you, {address}',
        headline: 'Your inner room has the lights on.',
        body: 'Stay curious. Selvator will bring words that do not crowd you.',
      ),
    ],
    MoodType.confident: [
      _GreetingTemplate(
        salutation: 'There you are, {name}',
        headline: 'Confidence is standing tall today.',
        body: 'Selvator will keep the next quote clean, direct, and strong.',
      ),
      _GreetingTemplate(
        salutation: 'Hey {address}',
        headline: 'You brought steady energy with you.',
        body: 'Let it lead without forcing it. Selvator has the words ready.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {name}',
        headline: 'That sure-footed mood is showing.',
        body: 'Selvator is tuned for clear lines and no second-guessing.',
      ),
      _GreetingTemplate(
        salutation: 'Welcome back, {address}',
        headline: 'Stand easy. You do not need to overperform.',
        body: 'Confidence can be calm too. Selvator will match that.',
      ),
    ],
    MoodType.grateful: [
      _GreetingTemplate(
        salutation: 'Hey {name}',
        headline: 'Gratitude is making the room warmer.',
        body: 'Selvator will keep today close to what is worth noticing.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {address}',
        headline: 'That grateful mood has a soft shine.',
        body: 'Let it name the good things. Selvator has a quote for that.',
      ),
      _GreetingTemplate(
        salutation: 'Good to see you, {name}',
        headline: 'You are noticing the light without grabbing it.',
        body: 'Selvator will keep the words simple and warm.',
      ),
      _GreetingTemplate(
        salutation: 'Welcome back, {address}',
        headline: 'Some days get better when we count gently.',
        body: 'Stay with what helped. Selvator is listening to that mood.',
      ),
    ],
    MoodType.tired: [
      _GreetingTemplate(
        salutation: 'Easy, {name}',
        headline: 'Tired counts as a real feeling.',
        body: 'Selvator will keep things soft and low-effort for you.',
      ),
      _GreetingTemplate(
        salutation: 'Hey {address}',
        headline: 'No heroic mode required.',
        body:
            'Pick only what fits. Selvator will bring a quote that does not push.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {name}',
        headline: 'Your energy can be small and still valid.',
        body: 'Selvator is tuned for rest, not pressure.',
      ),
      _GreetingTemplate(
        salutation: 'Good to see you, {address}',
        headline: 'Let us make this gentle.',
        body: 'Tired days deserve careful words. Selvator has them ready.',
      ),
    ],
    MoodType.focused: [
      _GreetingTemplate(
        salutation: 'Locked in, {name}',
        headline: 'Focused energy, clean lane.',
        body: 'Selvator will keep the quote sharp enough to stay useful.',
      ),
      _GreetingTemplate(
        salutation: 'Hey {address}',
        headline: 'Your attention has a direction.',
        body: 'Choose the mood mix and Selvator will keep the signal clear.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {name}',
        headline: 'Less noise, more aim.',
        body: 'Selvator is tuned to focused words that do not wander.',
      ),
      _GreetingTemplate(
        salutation: 'Welcome back, {address}',
        headline: 'Steady mind, steady page.',
        body: 'Let us keep this simple. Selvator has the next line ready.',
      ),
    ],
    MoodType.anxious: [
      _GreetingTemplate(
        salutation: 'Hey {name}',
        headline: 'Anxious does not mean alone.',
        body: 'Selvator will keep the words steady and close to the ground.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {address}',
        headline: 'Let us lower the speed a little.',
        body: 'You can check in without solving everything. Selvator is here.',
      ),
      _GreetingTemplate(
        salutation: 'Good to see you, {name}',
        headline: 'Your nervous system gets a softer page.',
        body: 'Pick what feels true. Selvator will keep the quote gentle.',
      ),
      _GreetingTemplate(
        salutation: 'Easy now, {address}',
        headline: 'One breath is enough for the next step.',
        body: 'Selvator is tuned to anxious moments with care, not pressure.',
      ),
    ],
    MoodType.stressed: [
      _GreetingTemplate(
        salutation: 'Hey {address}',
        headline: 'Stress walked in, but it does not get the whole room.',
        body: 'Selvator will keep the words steady while you sort the noise.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {name}',
        headline: 'Let us loosen one knot at a time.',
        body:
            'No rush to fix the whole day. Selvator has a calmer quote ready.',
      ),
      _GreetingTemplate(
        salutation: 'Good to see you, {address}',
        headline: 'You can be overloaded and still cared for.',
        body: 'Selvator is tuned down, warm, and practical right now.',
      ),
      _GreetingTemplate(
        salutation: 'Welcome back, {name}',
        headline: 'The pressure can wait outside for a second.',
        body:
            'Choose your mood mix. Selvator will keep the next words grounded.',
      ),
    ],
    MoodType.nostalgic: [
      _GreetingTemplate(
        salutation: 'Hey {name}',
        headline: 'Memory is sitting beside you today.',
        body: 'Selvator will keep the mood tender without pulling you under.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {address}',
        headline: 'Old feelings can visit softly.',
        body: 'Let the memory have a chair. Selvator has a quote for the ache.',
      ),
      _GreetingTemplate(
        salutation: 'Good to see you, {name}',
        headline: 'Nostalgia has a warm shadow.',
        body: 'Selvator will keep the words honest and gentle.',
      ),
      _GreetingTemplate(
        salutation: 'Welcome back, {address}',
        headline: 'Some memories ask for kindness, not analysis.',
        body: 'Stay close to what matters. Selvator will match the tone.',
      ),
    ],
    MoodType.sad: [
      _GreetingTemplate(
        salutation: 'Hey {name}',
        headline: 'Sadness gets a gentle seat here.',
        body:
            'Selvator will not rush you out of it. The next words can sit with you.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {address}',
        headline: 'You do not have to brighten up on command.',
        body: 'Pick what feels true. Selvator is keeping this soft.',
      ),
      _GreetingTemplate(
        salutation: 'Good to see you, {name}',
        headline: 'Heavy days still deserve careful company.',
        body:
            'Selvator has a quote ready without pretending everything is easy.',
      ),
      _GreetingTemplate(
        salutation: 'Easy now, {address}',
        headline: 'Let the feeling be seen.',
        body: 'No performance today. Selvator is tuned for honest comfort.',
      ),
    ],
    MoodType.lonely: [
      _GreetingTemplate(
        salutation: 'Hey {name}',
        headline: 'Lonely moments deserve extra gentleness.',
        body:
            'Selvator is here with words that keep you company without crowding you.',
      ),
      _GreetingTemplate(
        salutation: 'Hi {address}',
        headline: 'You can feel alone and still be worth warmth.',
        body: 'Choose the mood that fits. Selvator will stay close.',
      ),
      _GreetingTemplate(
        salutation: 'Good to see you, {name}',
        headline: 'Let us make the room feel less empty.',
        body: 'Selvator has a quote ready, soft enough for this feeling.',
      ),
      _GreetingTemplate(
        salutation: 'Welcome back, {address}',
        headline: 'Small company still counts.',
        body: 'Stay a minute. Selvator will bring the next line gently.',
      ),
    ],
  };

  static T _pick<T>(List<T> items, int seed) {
    return items[seed.abs() % items.length];
  }

  static String _fill(
    String value,
    String nickname,
    String address,
    MoodType mood,
  ) {
    return value
        .replaceAll('{name}', nickname)
        .replaceAll('{address}', address)
        .replaceAll('{mood}', mood.label.toLowerCase());
  }

  static int _stableHash(Iterable<String> parts) {
    var hash = 0x811c9dc5;
    for (final part in parts) {
      for (final unit in part.codeUnits) {
        hash ^= unit;
        hash = (hash * 0x01000193) & 0x7fffffff;
      }
      hash ^= 0x2c;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class _GreetingTemplate {
  const _GreetingTemplate({
    required this.salutation,
    required this.headline,
    required this.body,
  });

  final String salutation;
  final String headline;
  final String body;
}
