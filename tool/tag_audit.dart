import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _rawQuotesPath = 'silvator/quotes.json';
const _curatedQuotesPath = 'assets/data/quotes_curated.json';

const _moodKeys = [
  'happy',
  'calm',
  'motivated',
  'love',
  'hopeful',
  'reflective',
  'confident',
  'grateful',
  'tired',
  'focused',
  'anxious',
  'stressed',
  'nostalgic',
  'sad',
  'lonely',
];

void main(List<String> args) {
  final jsonOut = _readOption(args, '--json-out');
  final report = TagAuditAnalyzer().analyze(
    rawQuotesPath: _readOption(args, '--raw') ?? _rawQuotesPath,
    curatedQuotesPath: _readOption(args, '--curated') ?? _curatedQuotesPath,
  );

  stdout.write(report.toConsoleString());

  if (jsonOut != null) {
    File(jsonOut)
      ..createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(report.toJson()),
      );
  }
}

class TagAuditAnalyzer {
  TagAuditReport analyze({
    required String rawQuotesPath,
    required String curatedQuotesPath,
  }) {
    final rawQuotes = _loadJsonList(rawQuotesPath);
    final curatedQuotes = _loadJsonList(curatedQuotesPath);
    final tagCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    final tagPairs = <String, int>{};

    for (final quote in rawQuotes) {
      final tags = _stringList(quote['Tags']).toSet().toList()..sort();
      for (final tag in tags) {
        tagCounts.update(tag, (count) => count + 1, ifAbsent: () => 1);
      }
      final category = quote['Category']?.toString().trim().toLowerCase();
      if (category != null && category.isNotEmpty) {
        categoryCounts.update(
          category,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      for (var i = 0; i < tags.length; i++) {
        for (var j = i + 1; j < min(tags.length, i + 8); j++) {
          final pair = '${tags[i]} + ${tags[j]}';
          tagPairs.update(pair, (count) => count + 1, ifAbsent: () => 1);
        }
      }
    }

    final moodCoverage = {
      for (final mood in _moodKeys)
        mood: curatedQuotes
            .where((quote) => _stringList(quote['moods']).contains(mood))
            .length,
    };
    final missingMoodPools = [
      for (final entry in moodCoverage.entries)
        if (entry.value == 0) entry.key,
    ];

    final rhythmScores = [
      for (final quote in curatedQuotes)
        _deriveRhythmScore(
          text: quote['text']?.toString() ?? '',
          tags: _stringList(quote['tags']),
        ),
    ];
    rhythmScores.sort();

    final arcCandidates = _arcTierCandidates(curatedQuotes);
    final combos = _comboCandidates(tagPairs);

    return TagAuditReport(
      rawQuoteCount: rawQuotes.length,
      curatedQuoteCount: curatedQuotes.length,
      uniqueTagCount: tagCounts.length,
      topTags: _top(tagCounts, 30),
      rareTags: _rare(tagCounts, 30),
      topCategories: _top(categoryCounts, 16),
      topTagPairs: _top(tagPairs, 30),
      moodCoverage: moodCoverage,
      missingMoodPools: missingMoodPools,
      comboCandidates: combos,
      rhythmDistribution: RhythmDistribution.fromScores(rhythmScores),
      arcTierCandidates: arcCandidates,
    );
  }

  List<dynamic> _loadJsonList(String path) {
    final decoded = jsonDecode(File(path).readAsStringSync());
    if (decoded is! List<dynamic>) {
      throw FormatException('Expected a JSON list in $path.');
    }
    return decoded;
  }
}

class TagAuditReport {
  const TagAuditReport({
    required this.rawQuoteCount,
    required this.curatedQuoteCount,
    required this.uniqueTagCount,
    required this.topTags,
    required this.rareTags,
    required this.topCategories,
    required this.topTagPairs,
    required this.moodCoverage,
    required this.missingMoodPools,
    required this.comboCandidates,
    required this.rhythmDistribution,
    required this.arcTierCandidates,
  });

  final int rawQuoteCount;
  final int curatedQuoteCount;
  final int uniqueTagCount;
  final List<CountedValue> topTags;
  final List<CountedValue> rareTags;
  final List<CountedValue> topCategories;
  final List<CountedValue> topTagPairs;
  final Map<String, int> moodCoverage;
  final List<String> missingMoodPools;
  final List<String> comboCandidates;
  final RhythmDistribution rhythmDistribution;
  final Map<String, Map<String, int>> arcTierCandidates;

  Map<String, dynamic> toJson() {
    return {
      'rawQuoteCount': rawQuoteCount,
      'curatedQuoteCount': curatedQuoteCount,
      'uniqueTagCount': uniqueTagCount,
      'topTags': topTags.map((item) => item.toJson()).toList(),
      'rareTags': rareTags.map((item) => item.toJson()).toList(),
      'topCategories': topCategories.map((item) => item.toJson()).toList(),
      'topTagPairs': topTagPairs.map((item) => item.toJson()).toList(),
      'moodCoverage': moodCoverage,
      'missingMoodPools': missingMoodPools,
      'comboCandidates': comboCandidates,
      'rhythmDistribution': rhythmDistribution.toJson(),
      'arcTierCandidates': arcTierCandidates,
    };
  }

  String toConsoleString() {
    final buffer = StringBuffer()
      ..writeln('Selvator Tag Audit')
      ..writeln('==================')
      ..writeln('Raw quotes: $rawQuoteCount')
      ..writeln('Curated quotes: $curatedQuoteCount')
      ..writeln('Unique raw tags: $uniqueTagCount')
      ..writeln()
      ..writeln('Top tags')
      ..writeln(_formatCounted(topTags))
      ..writeln()
      ..writeln('Rare tags')
      ..writeln(_formatCounted(rareTags))
      ..writeln()
      ..writeln('Top categories')
      ..writeln(_formatCounted(topCategories))
      ..writeln()
      ..writeln('Mood coverage')
      ..writeln(_formatMap(moodCoverage))
      ..writeln()
      ..writeln('Missing mood pools: ${missingMoodPools.join(', ')}')
      ..writeln()
      ..writeln('Top tag co-occurrences')
      ..writeln(_formatCounted(topTagPairs))
      ..writeln()
      ..writeln('Combo candidates')
      ..writeln(comboCandidates.map((item) => '- $item').join('\n'))
      ..writeln()
      ..writeln('Rhythm distribution')
      ..writeln(_formatMap(rhythmDistribution.toJson()))
      ..writeln()
      ..writeln('Mirror / Bridge / Window candidates')
      ..writeln(const JsonEncoder.withIndent('  ').convert(arcTierCandidates));
    return buffer.toString();
  }
}

class RhythmDistribution {
  const RhythmDistribution({
    required this.min,
    required this.p25,
    required this.median,
    required this.p75,
    required this.max,
  });

  final int min;
  final int p25;
  final int median;
  final int p75;
  final int max;

  factory RhythmDistribution.fromScores(List<int> scores) {
    if (scores.isEmpty) {
      return const RhythmDistribution(
        min: 0,
        p25: 0,
        median: 0,
        p75: 0,
        max: 0,
      );
    }
    return RhythmDistribution(
      min: scores.first,
      p25: scores[(scores.length * 0.25).floor()],
      median: scores[(scores.length * 0.5).floor()],
      p75: scores[(scores.length * 0.75).floor()],
      max: scores.last,
    );
  }

  Map<String, int> toJson() {
    return {'min': min, 'p25': p25, 'median': median, 'p75': p75, 'max': max};
  }
}

class CountedValue {
  const CountedValue(this.value, this.count);

  final String value;
  final int count;

  Map<String, dynamic> toJson() => {'value': value, 'count': count};
}

List<String> _stringList(dynamic source) {
  return (source as List<dynamic>? ?? const [])
      .map((item) => item.toString().trim().toLowerCase())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<CountedValue> _top(Map<String, int> counts, int limit) {
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final count = b.value.compareTo(a.value);
      return count == 0 ? a.key.compareTo(b.key) : count;
    });
  return entries
      .take(limit)
      .map((entry) => CountedValue(entry.key, entry.value))
      .toList(growable: false);
}

List<CountedValue> _rare(Map<String, int> counts, int limit) {
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final count = a.value.compareTo(b.value);
      return count == 0 ? a.key.compareTo(b.key) : count;
    });
  return entries
      .take(limit)
      .map((entry) => CountedValue(entry.key, entry.value))
      .toList(growable: false);
}

List<String> _comboCandidates(Map<String, int> tagPairs) {
  const usefulWords = {
    'life',
    'love',
    'hope',
    'happiness',
    'sadness',
    'fear',
    'courage',
    'success',
    'wisdom',
    'loneliness',
    'gratitude',
    'peace',
    'motivation',
    'relationships',
    'truth',
    'time',
    'change',
    'strength',
  };
  return _top(tagPairs, 120)
      .where(
        (pair) =>
            pair.value.split(' + ').any((tag) => usefulWords.any(tag.contains)),
      )
      .take(24)
      .map((pair) => '${pair.value} (${pair.count})')
      .toList(growable: false);
}

Map<String, Map<String, int>> _arcTierCandidates(List<dynamic> quotes) {
  final result = {
    for (final mood in _moodKeys) mood: {'mirror': 0, 'bridge': 0, 'window': 0},
  };
  for (final quote in quotes) {
    final moods = _stringList(quote['moods']);
    final tags = _stringList(quote['tags']);
    final popularity = (quote['popularity'] as num?)?.toDouble() ?? 0;
    final text = quote['text']?.toString() ?? '';
    for (final mood in moods) {
      final tier = _deriveArcTierName(
        mood: mood,
        tags: tags,
        popularity: popularity,
        text: text,
      );
      result[mood]?[tier] = (result[mood]?[tier] ?? 0) + 1;
    }
  }
  return result;
}

int _deriveRhythmScore({required String text, required List<String> tags}) {
  final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final wordCount = words.length;
  var score = 45;
  if (wordCount <= 8) {
    score += 18;
  } else if (wordCount <= 18) {
    score += 10;
  } else if (wordCount >= 35) {
    score -= 14;
  }
  if (text.contains('!')) score += 10;
  if (text.contains('?')) score += 4;
  if (text.contains(';') || text.contains(':')) score -= 3;
  const highEnergy = {'motivation', 'success', 'courage', 'strength', 'action'};
  const lowEnergy = {'sadness', 'grief', 'loneliness', 'peace', 'patience'};
  if (tags.any(highEnergy.contains)) score += 12;
  if (tags.any(lowEnergy.contains)) score -= 8;
  return score.clamp(0, 100);
}

String _deriveArcTierName({
  required String mood,
  required List<String> tags,
  required double popularity,
  required String text,
}) {
  const mirrorTags = {
    'sadness',
    'fear',
    'cry',
    'crying',
    'loneliness',
    'grief',
    'pain',
    'truth',
  };
  const windowTags = {
    'hope',
    'happiness',
    'optimism',
    'inspirational',
    'success',
    'courage',
    'future',
  };
  if (tags.any(mirrorTags.contains) || text.length > 180) {
    return 'mirror';
  }
  if (tags.any(windowTags.contains) || popularity >= 0.65) {
    return 'window';
  }
  return 'bridge';
}

String? _readOption(List<String> args, String option) {
  final equalsPrefix = '$option=';
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith(equalsPrefix)) {
      return arg.substring(equalsPrefix.length);
    }
    if (arg == option && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
}

String _formatCounted(List<CountedValue> values) {
  if (values.isEmpty) {
    return '- none';
  }
  return values.map((item) => '- ${item.value}: ${item.count}').join('\n');
}

String _formatMap(Map<String, Object?> values) {
  if (values.isEmpty) {
    return '- none';
  }
  return values.entries
      .map((entry) => '- ${entry.key}: ${entry.value}')
      .join('\n');
}
