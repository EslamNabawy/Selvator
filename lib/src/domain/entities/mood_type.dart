enum MoodType {
  happy,
  calm,
  motivated,
  love,
  hopeful,
  reflective,
  confident,
  grateful,
  tired,
  focused,
  anxious,
  stressed,
  nostalgic,
  sad,
  lonely;

  String get label {
    switch (this) {
      case MoodType.happy:
        return 'Happy';
      case MoodType.calm:
        return 'Calm';
      case MoodType.motivated:
        return 'Motivated';
      case MoodType.love:
        return 'Love';
      case MoodType.hopeful:
        return 'Hopeful';
      case MoodType.reflective:
        return 'Reflective';
      case MoodType.confident:
        return 'Confident';
      case MoodType.grateful:
        return 'Grateful';
      case MoodType.tired:
        return 'Tired';
      case MoodType.focused:
        return 'Focused';
      case MoodType.anxious:
        return 'Anxious';
      case MoodType.stressed:
        return 'Stressed';
      case MoodType.nostalgic:
        return 'Nostalgic';
      case MoodType.sad:
        return 'Sad';
      case MoodType.lonely:
        return 'Lonely';
    }
  }

  String get accentKey => name;

  static MoodType fromKey(String value) {
    return MoodType.values.firstWhere(
      (mood) => mood.name == value,
      orElse: () => MoodType.happy,
    );
  }
}

const Map<MoodType, List<MoodType>> moodAdjacencyMap = {
  MoodType.happy: [MoodType.confident, MoodType.grateful, MoodType.hopeful],
  MoodType.calm: [MoodType.focused, MoodType.reflective, MoodType.tired],
  MoodType.motivated: [MoodType.confident, MoodType.focused, MoodType.hopeful],
  MoodType.love: [MoodType.grateful, MoodType.hopeful, MoodType.lonely],
  MoodType.hopeful: [MoodType.happy, MoodType.confident, MoodType.sad],
  MoodType.reflective: [MoodType.calm, MoodType.nostalgic, MoodType.focused],
  MoodType.confident: [MoodType.happy, MoodType.motivated, MoodType.hopeful],
  MoodType.grateful: [MoodType.happy, MoodType.love, MoodType.reflective],
  MoodType.tired: [MoodType.calm, MoodType.stressed, MoodType.sad],
  MoodType.focused: [MoodType.calm, MoodType.motivated, MoodType.confident],
  MoodType.anxious: [MoodType.stressed, MoodType.calm, MoodType.hopeful],
  MoodType.stressed: [MoodType.anxious, MoodType.tired, MoodType.calm],
  MoodType.nostalgic: [MoodType.reflective, MoodType.love, MoodType.sad],
  MoodType.sad: [MoodType.hopeful, MoodType.reflective, MoodType.lonely],
  MoodType.lonely: [MoodType.love, MoodType.grateful, MoodType.hopeful],
};
