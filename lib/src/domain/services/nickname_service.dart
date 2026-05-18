import 'package:wisely/src/domain/entities/user_profile.dart';

class NicknameService {
  const NicknameService();

  static const List<String> _vowels = ['a', 'e', 'i', 'o', 'u'];
  static const List<String> _strongVowels = ['a', 'i', 'o', 'u'];
  static const Map<String, String> _vowelSwap = {
    'a': 'e',
    'e': 'o',
    'o': 'e',
    'i': 'a',
    'u': 'o',
  };

  String nickname(String name, {required UserGender gender}) {
    final normalized = name.toLowerCase().trim();
    if (normalized == 'nour' && gender == UserGender.female) {
      return 'nourindty';
    }

    if (gender == UserGender.female &&
        normalized.isNotEmpty &&
        _vowels.contains(_last(normalized))) {
      return _femaleTransform(normalized);
    }

    return _stretchName(normalized);
  }

  String _stretchName(String name) {
    final mid = name.length ~/ 2;
    final vowelIndices = _getVowelIndices(name);

    if (vowelIndices.isEmpty) {
      return name;
    }

    final secondHalf = vowelIndices.where((index) => index >= mid).toList();
    final firstHalf = vowelIndices.where((index) => index < mid).toList();

    final primary =
        _lastStrongVowel(secondHalf, name) ??
        _lastStrongVowel(vowelIndices, name) ??
        vowelIndices.last;

    final stretchBoth =
        name.length >= 6 && firstHalf.isNotEmpty && secondHalf.isNotEmpty;

    var targets = [primary];

    if (stretchBoth) {
      final secondaryTarget = firstHalf.last;
      if (secondaryTarget != primary) {
        targets = [secondaryTarget, primary];
      }
    }

    return _applyStretch(name, targets);
  }

  String _applyStretch(String name, List<int> targets) {
    final buffer = StringBuffer();
    for (var index = 0; index < name.length; index++) {
      final char = name[index];
      buffer.write(char);
      if (targets.contains(index)) {
        buffer.write(List.filled(_reps(char, name.length), char).join());
      }
    }
    return buffer.toString();
  }

  int _reps(String vowel, int nameLength) {
    if (vowel == 'i') {
      return nameLength >= 5 ? 3 : 4;
    }
    return nameLength >= 5 ? 1 : 2;
  }

  String _femaleTransform(String name) {
    final vowelPositions = _getVowelIndices(name);
    final result = name.split('');

    for (var order = 0; order < vowelPositions.length; order++) {
      final index = vowelPositions[order];
      final isLast = order == vowelPositions.length - 1;
      result[index] = isLast ? 'o' : _vowelSwap[name[index]] ?? name[index];
    }

    return result.join();
  }

  List<int> _getVowelIndices(String name) {
    final indices = <int>[];
    for (var index = 0; index < name.length; index++) {
      if (_vowels.contains(name[index])) {
        indices.add(index);
      }
    }
    return indices;
  }

  int? _lastStrongVowel(List<int> indices, String name) {
    final strong = indices
        .where((index) => _strongVowels.contains(name[index]))
        .toList();
    return strong.isEmpty ? null : strong.last;
  }

  String _last(String value) => value[value.length - 1];
}
