import 'package:wisely/src/domain/entities/mood_type.dart';

enum MoodEnergy { low, medium, high }

extension MoodEnergyForMood on MoodType {
  MoodEnergy get energy {
    switch (this) {
      case MoodType.motivated:
      case MoodType.confident:
      case MoodType.focused:
      case MoodType.happy:
        return MoodEnergy.high;
      case MoodType.tired:
      case MoodType.anxious:
      case MoodType.stressed:
      case MoodType.sad:
      case MoodType.lonely:
        return MoodEnergy.low;
      case MoodType.calm:
      case MoodType.love:
      case MoodType.hopeful:
      case MoodType.reflective:
      case MoodType.grateful:
      case MoodType.nostalgic:
        return MoodEnergy.medium;
    }
  }

  bool get requiresDecompression {
    return {
      MoodType.tired,
      MoodType.anxious,
      MoodType.stressed,
      MoodType.sad,
      MoodType.lonely,
    }.contains(this);
  }
}

MoodEnergy aggregateMoodEnergy(Iterable<MoodType> moods) {
  final energies = moods.map((mood) => mood.energy).toSet();
  if (energies.contains(MoodEnergy.low)) {
    return MoodEnergy.low;
  }
  if (energies.contains(MoodEnergy.high)) {
    return MoodEnergy.high;
  }
  return MoodEnergy.medium;
}
