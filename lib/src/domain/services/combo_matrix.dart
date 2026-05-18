import 'package:wisely/src/domain/curation/quote_curation.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';

class MoodTagTarget {
  const MoodTagTarget({required this.moods, required this.tags});

  final List<MoodType> moods;
  final Set<String> tags;
}

class ComboMatrix {
  const ComboMatrix();

  MoodTagTarget resolve(List<MoodType> selectedMoods) {
    final moods = _normalize(selectedMoods);
    final tags = <String>{};
    for (final mood in moods) {
      tags.addAll(moodKeywordMap[mood] ?? const []);
    }
    if (moods.contains(MoodType.anxious) && moods.contains(MoodType.hopeful)) {
      tags.addAll(['courage', 'optimism']);
    }
    if (moods.contains(MoodType.tired) && moods.contains(MoodType.calm)) {
      tags.addAll(['rest', 'peace']);
    }
    if (moods.contains(MoodType.sad) && moods.contains(MoodType.love)) {
      tags.addAll(['belonging', 'connection']);
    }
    if (moods.contains(MoodType.motivated) &&
        moods.contains(MoodType.focused)) {
      tags.addAll(['discipline', 'purpose']);
    }
    return MoodTagTarget(moods: moods, tags: tags);
  }

  List<MoodType> _normalize(List<MoodType> moods) {
    final unique = moods.toSet().toList(growable: false);
    return unique.isEmpty ? const [MoodType.happy] : unique;
  }
}
