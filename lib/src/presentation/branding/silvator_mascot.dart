import 'package:wisely/src/domain/entities/mood_type.dart';

const String silvatorOriginalAssetPath = 'assets/images/silvator/original.webp';

class SilvatorMascotProfile {
  const SilvatorMascotProfile({
    required this.mood,
    required this.name,
    required this.symbol,
    required this.description,
    required this.pose,
    required this.assetPath,
  });

  final MoodType mood;
  final String name;
  final String symbol;
  final String description;
  final String pose;
  final String assetPath;
}

const Map<MoodType, SilvatorMascotProfile> silvatorMascotProfiles = {
  MoodType.happy: SilvatorMascotProfile(
    mood: MoodType.happy,
    name: 'Happiness',
    symbol: 'Solar Milkshake',
    description:
        'Golden light, open posture, and a wide smile shape this mood.',
    pose: 'Open stance with head tilted back in a laugh.',
    assetPath: 'assets/images/silvator/happy.webp',
  ),
  MoodType.calm: SilvatorMascotProfile(
    mood: MoodType.calm,
    name: 'Calm',
    symbol: 'Base companion',
    description:
        'Neutral warmth keeps the app grounded when no strong prop fits.',
    pose: 'Relaxed upright stance with soft attention.',
    assetPath: silvatorOriginalAssetPath,
  ),
  MoodType.motivated: SilvatorMascotProfile(
    mood: MoodType.motivated,
    name: 'Confidence',
    symbol: 'Black Sunglasses',
    description:
        'Upright posture and steady smile make motivation feel decisive.',
    pose: 'Commanding stance with hands resting firmly on hips.',
    assetPath: 'assets/images/silvator/confidence.webp',
  ),
  MoodType.love: SilvatorMascotProfile(
    mood: MoodType.love,
    name: 'Love',
    symbol: 'Ruby-Red Heart Necklace',
    description: 'Warm crimson glow and glossy eyes carry tender affection.',
    pose: 'Gentle head tilt with hands clasped near the chest.',
    assetPath: 'assets/images/silvator/love.webp',
  ),
  MoodType.hopeful: SilvatorMascotProfile(
    mood: MoodType.hopeful,
    name: 'Happiness',
    symbol: 'Solar Milkshake',
    description:
        'Bright gold energy supports optimistic, forward-looking quotes.',
    pose: 'Open stance with lifted chest and a light expression.',
    assetPath: 'assets/images/silvator/happy.webp',
  ),
  MoodType.reflective: SilvatorMascotProfile(
    mood: MoodType.reflective,
    name: 'Reflective',
    symbol: 'Base companion',
    description:
        'Quiet neutral styling keeps reflective moods spacious and readable.',
    pose: 'Still posture with a soft, attentive expression.',
    assetPath: silvatorOriginalAssetPath,
  ),
  MoodType.confident: SilvatorMascotProfile(
    mood: MoodType.confident,
    name: 'Confidence',
    symbol: 'Black Sunglasses',
    description:
        'Dark lenses and a grounded stance create self-assured presence.',
    pose: 'Upright stance with legs planted shoulder-width apart.',
    assetPath: 'assets/images/silvator/confidence.webp',
  ),
  MoodType.grateful: SilvatorMascotProfile(
    mood: MoodType.grateful,
    name: 'Love',
    symbol: 'Ruby-Red Heart Necklace',
    description: 'Warm red light gives gratitude a tender, connected tone.',
    pose: 'Hands held close with a softened, appreciative expression.',
    assetPath: 'assets/images/silvator/love.webp',
  ),
  MoodType.tired: SilvatorMascotProfile(
    mood: MoodType.tired,
    name: 'Boredom',
    symbol: 'Glowing Smartphone',
    description: 'Blue phone light and slumped posture show low-energy drift.',
    pose: 'Slumped into a chair with chin resting in one palm.',
    assetPath: 'assets/images/silvator/bored.webp',
  ),
  MoodType.focused: SilvatorMascotProfile(
    mood: MoodType.focused,
    name: 'Confidence',
    symbol: 'Black Sunglasses',
    description:
        'A grounded silhouette keeps focused moments direct and steady.',
    pose: 'Stable stance with minimal movement and clear intent.',
    assetPath: 'assets/images/silvator/confidence.webp',
  ),
  MoodType.anxious: SilvatorMascotProfile(
    mood: MoodType.anxious,
    name: 'Anxiety',
    symbol: 'Metallic Handcuffs',
    description:
        'Restrained wrists and panicked posture show emotional pressure.',
    pose: 'Wrists pulled inward with shoulders hunched defensively.',
    assetPath: 'assets/images/silvator/anxiety.webp',
  ),
  MoodType.stressed: SilvatorMascotProfile(
    mood: MoodType.stressed,
    name: 'Stress',
    symbol: 'Lit Cigarette',
    description: 'Tense fingers, smoke, and tired eyes communicate overload.',
    pose: 'One hand at the temple with shoulders slumped forward.',
    assetPath: 'assets/images/silvator/stress.webp',
  ),
  MoodType.nostalgic: SilvatorMascotProfile(
    mood: MoodType.nostalgic,
    name: 'Loneliness',
    symbol: 'Fuzzy Brown Bear',
    description: 'Protective posture gives memory-heavy moods a soft ache.',
    pose: 'Closed-off seated posture with an object held close.',
    assetPath: 'assets/images/silvator/lonely.webp',
  ),
  MoodType.sad: SilvatorMascotProfile(
    mood: MoodType.sad,
    name: 'Sadness',
    symbol: 'Crumpled Tissue',
    description: 'Tears, inward shoulders, and a tissue make sadness visible.',
    pose: 'Huddled position with shoulders drawn inward.',
    assetPath: 'assets/images/silvator/sad.webp',
  ),
  MoodType.lonely: SilvatorMascotProfile(
    mood: MoodType.lonely,
    name: 'Loneliness',
    symbol: 'Fuzzy Brown Bear',
    description:
        'A closed-off hug turns isolation into a recognizable app moment.',
    pose: 'Seated fetal posture with both arms wrapped tightly.',
    assetPath: 'assets/images/silvator/lonely.webp',
  ),
};

SilvatorMascotProfile silvatorMascotProfileFor(MoodType mood) {
  return silvatorMascotProfiles[mood]!;
}
