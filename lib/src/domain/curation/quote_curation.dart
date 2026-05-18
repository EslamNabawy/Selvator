import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:wisely/src/domain/entities/catalog_version.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/pool_tier.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/quote_arc_tier.dart';

class RawQuote {
  const RawQuote({
    required this.text,
    required this.author,
    required this.tags,
    required this.category,
    required this.popularity,
  });

  final String text;
  final String author;
  final List<String> tags;
  final String category;
  final double popularity;

  factory RawQuote.fromJson(Map<String, dynamic> json) {
    return RawQuote(
      text: json['Quote']?.toString() ?? '',
      author: json['Author']?.toString() ?? '',
      tags: (json['Tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((tag) => tag.toString())
          .toList(growable: false),
      category: json['Category']?.toString() ?? '',
      popularity: (json['Popularity'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CuratedCatalog {
  const CuratedCatalog({required this.quotes, required this.version});

  final List<QuoteEntry> quotes;
  final CatalogVersion version;
}

class MoodCoverage {
  const MoodCoverage({
    required this.core,
    required this.extended,
    required this.coldEligible,
  });

  final int core;
  final int extended;
  final int coldEligible;
}

class CatalogValidationResult {
  const CatalogValidationResult({
    required this.coverage,
    required this.authorDistribution,
    required this.issues,
  });

  final Map<MoodType, MoodCoverage> coverage;
  final Map<MoodType, Map<String, int>> authorDistribution;
  final List<String> issues;
}

class _PreparedQuote {
  _PreparedQuote({
    required this.raw,
    required this.normalizedText,
    required this.normalizedAuthor,
    required this.tokens,
    required this.moodStrength,
  });

  final RawQuote raw;
  final String normalizedText;
  final String normalizedAuthor;
  final Set<String> tokens;
  final Map<MoodType, double> moodStrength;

  int get popularityScore => max(0, (raw.popularity * 1000000).round());
}

const int corePoolLimit = 150;
const int extendedPoolLimit = 400;
const double duplicateJaccardThreshold = 0.85;

const Map<MoodType, List<String>> moodKeywordMap = {
  MoodType.happy: ['happiness', 'joy', 'positive'],
  MoodType.calm: ['mind', 'soul', 'peace'],
  MoodType.motivated: ['inspiration', 'motivation', 'success', 'purpose'],
  MoodType.love: ['love', 'relationship'],
  MoodType.hopeful: ['hope', 'optimism', 'positive'],
  MoodType.reflective: ['life', 'philosophy', 'wisdom', 'truth', 'knowledge'],
  MoodType.confident: ['confidence', 'courage', 'strength', 'bold', 'fearless'],
  MoodType.grateful: [
    'gratitude',
    'grateful',
    'thankful',
    'appreciation',
    'blessed',
  ],
  MoodType.tired: [
    'rest',
    'sleep',
    'tired',
    'exhaustion',
    'recharge',
    'boredom',
    'bored',
    'apathy',
  ],
  MoodType.focused: [
    'focus',
    'discipline',
    'clarity',
    'concentration',
    'productivity',
  ],
  MoodType.anxious: [
    'anxiety',
    'anxious',
    'worry',
    'fear',
    'fearful',
    'panic',
    'uncertainty',
  ],
  MoodType.stressed: [
    'stress',
    'stressed',
    'overwhelm',
    'pressure',
    'burnout',
    'anger',
    'angry',
    'rage',
    'frustration',
  ],
  MoodType.nostalgic: [
    'nostalgia',
    'memory',
    'childhood',
    'past',
    'reminiscence',
  ],
  MoodType.sad: ['sadness', 'grief', 'loss', 'sorrow', 'melancholy'],
  MoodType.lonely: [
    'loneliness',
    'alone',
    'solitude',
    'belonging',
    'connection',
  ],
};

final Set<String> _stopWords = {
  'a',
  'an',
  'and',
  'are',
  'as',
  'at',
  'be',
  'but',
  'by',
  'for',
  'from',
  'has',
  'have',
  'he',
  'her',
  'his',
  'i',
  'if',
  'in',
  'into',
  'is',
  'it',
  'its',
  'me',
  'my',
  'of',
  'on',
  'or',
  'our',
  'she',
  'that',
  'the',
  'their',
  'them',
  'there',
  'they',
  'this',
  'to',
  'was',
  'we',
  'were',
  'will',
  'with',
  'you',
  'your',
};

CuratedCatalog curateQuotes(List<RawQuote> rawQuotes) {
  final prepared = <_PreparedQuote>[];
  for (final rawQuote in rawQuotes) {
    final normalizedText = _normalizeSpacing(rawQuote.text);
    final normalizedAuthor = _normalizeSpacing(rawQuote.author);
    if (normalizedText.isEmpty || normalizedAuthor.isEmpty) {
      continue;
    }
    if (normalizedText.length < 30 || normalizedText.length > 400) {
      continue;
    }
    final tokenSet = _tokenizeForSimilarity(normalizedText);
    if (tokenSet.isEmpty) {
      continue;
    }
    final moodStrength = _mapMoodStrength(
      category: rawQuote.category,
      tags: rawQuote.tags,
    );
    if (moodStrength.isEmpty) {
      continue;
    }
    prepared.add(
      _PreparedQuote(
        raw: RawQuote(
          text: normalizedText,
          author: normalizedAuthor,
          tags: rawQuote.tags
              .map(_normalizeSpacing)
              .where((tag) => tag.isNotEmpty)
              .toList(),
          category: _normalizeSpacing(rawQuote.category),
          popularity: rawQuote.popularity,
        ),
        normalizedText: _normalizeForComparison(normalizedText),
        normalizedAuthor: _normalizeForComparison(normalizedAuthor),
        tokens: tokenSet,
        moodStrength: moodStrength,
      ),
    );
  }

  prepared.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

  final survivors = <_PreparedQuote>[];
  final bucketMap = <String, List<_PreparedQuote>>{};

  for (final candidate in prepared) {
    if (_isDuplicate(candidate, bucketMap)) {
      continue;
    }
    survivors.add(candidate);
    for (final key in _bucketKeys(candidate)) {
      bucketMap.putIfAbsent(key, () => <_PreparedQuote>[]).add(candidate);
    }
  }

  final perMoodSelections = <MoodType, List<_PreparedQuote>>{
    for (final mood in MoodType.values) mood: <_PreparedQuote>[],
  };

  for (final mood in MoodType.values) {
    final authorCount = <String, int>{};
    final matching =
        survivors
            .where((quote) => quote.moodStrength.containsKey(mood))
            .toList(growable: false)
          ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
    final selected = perMoodSelections[mood]!;
    for (final quote in matching) {
      final count = authorCount[quote.normalizedAuthor] ?? 0;
      if (count >= 3) {
        continue;
      }
      selected.add(quote);
      authorCount[quote.normalizedAuthor] = count + 1;
      if (selected.length >= extendedPoolLimit) {
        break;
      }
    }
  }

  final quoteMap = <String, QuoteEntry>{};
  for (final mood in MoodType.values) {
    final selected = perMoodSelections[mood]!;
    for (var index = 0; index < selected.length; index++) {
      final preparedQuote = selected[index];
      final id = _deterministicUuid(
        '${preparedQuote.normalizedText}|${preparedQuote.normalizedAuthor}',
      );
      final existing = quoteMap[id];
      final nextTier = index < corePoolLimit
          ? PoolTier.core
          : PoolTier.extended;
      final arcTier = deriveQuoteArcTier(
        mood: mood,
        text: preparedQuote.raw.text,
        tags: preparedQuote.raw.tags,
        category: preparedQuote.raw.category,
        popularityScore: preparedQuote.popularityScore,
      );
      final nextEntry =
          (existing ??
                  QuoteEntry(
                    id: id,
                    text: preparedQuote.raw.text,
                    author: preparedQuote.raw.author,
                    popularity: preparedQuote.popularityScore,
                    categories: preparedQuote.raw.category.isEmpty
                        ? const []
                        : [preparedQuote.raw.category.toLowerCase()],
                    tags: preparedQuote.raw.tags
                        .map((tag) => tag.toLowerCase())
                        .toSet()
                        .toList(growable: false),
                    moods: preparedQuote.moodStrength.keys.toList(
                      growable: false,
                    ),
                    moodStrength: Map<MoodType, double>.from(
                      preparedQuote.moodStrength,
                    ),
                    poolTier: const {},
                    rhythmScore: deriveRhythmScore(
                      text: preparedQuote.raw.text,
                      tags: preparedQuote.raw.tags,
                    ),
                    arcTierByMood: const {},
                  ))
              .copyWith(
                poolTier: {...?existing?.poolTier, mood: nextTier},
                arcTierByMood: {...?existing?.arcTierByMood, mood: arcTier},
              );
      quoteMap[id] = nextEntry;
    }
  }

  final curatedQuotes = quoteMap.values.toList(growable: false)
    ..sort((a, b) => b.popularity.compareTo(a.popularity));
  final version = _buildCatalogVersion(curatedQuotes);

  return CuratedCatalog(quotes: curatedQuotes, version: version);
}

CatalogValidationResult validateCatalog(List<QuoteEntry> quotes) {
  final coverage = <MoodType, MoodCoverage>{};
  final authorDistribution = <MoodType, Map<String, int>>{};
  final issues = <String>[];

  for (final mood in MoodType.values) {
    final moodQuotes = quotes
        .where((quote) => quote.poolTier.containsKey(mood))
        .toList();
    final core = moodQuotes
        .where((quote) => quote.poolTier[mood] == PoolTier.core)
        .toList();
    final extended = moodQuotes
        .where((quote) => quote.poolTier[mood] == PoolTier.extended)
        .toList();
    final coldEligible = moodQuotes
        .where((quote) => quote.poolTier[mood] != PoolTier.wildcard)
        .toList();
    coverage[mood] = MoodCoverage(
      core: core.length,
      extended: extended.length,
      coldEligible: coldEligible.length,
    );
    final authors = <String, int>{};
    for (final quote in moodQuotes) {
      authors.update(quote.author, (count) => count + 1, ifAbsent: () => 1);
    }
    authorDistribution[mood] = Map<String, int>.fromEntries(
      authors.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..removeRange(min(10, authors.length), authors.length),
    );

    if (core.length < 30) {
      issues.add('${mood.name}: core pool below 30');
    }
    final authorViolation = authors.entries
        .where((entry) => entry.value > 3)
        .map((entry) => entry.key)
        .toList();
    if (authorViolation.isNotEmpty) {
      issues.add(
        '${mood.name}: author cap exceeded by ${authorViolation.join(', ')}',
      );
    }
  }

  final lowStrengthQuote = quotes.firstWhere(
    (quote) => quote.moodStrength.values.any((strength) => strength < 0.5),
    orElse: () => const QuoteEntry(
      id: '',
      text: '',
      author: '',
      popularity: 0,
      categories: [],
      tags: [],
      moods: [],
      moodStrength: {},
      poolTier: {},
    ),
  );
  if (lowStrengthQuote.id.isNotEmpty) {
    issues.add('Quote ${lowStrengthQuote.id} has mood strength below 0.5');
  }

  return CatalogValidationResult(
    coverage: coverage,
    authorDistribution: authorDistribution,
    issues: issues,
  );
}

List<RawQuote> parseRawQuotes(String rawJson) {
  final decoded = jsonDecode(rawJson) as List<dynamic>;
  return decoded
      .map((item) => RawQuote.fromJson(item as Map<String, dynamic>))
      .toList(growable: false);
}

String encodeCuratedQuotes(List<QuoteEntry> quotes) {
  return const JsonEncoder.withIndent(
    '  ',
  ).convert(quotes.map((quote) => quote.toJson()).toList(growable: false));
}

String encodeCatalogVersion(CatalogVersion version) {
  return const JsonEncoder.withIndent('  ').convert(version.toJson());
}

CatalogVersion _buildCatalogVersion(List<QuoteEntry> quotes) {
  final payload = jsonEncode(
    quotes.map((quote) => quote.toJson()).toList(growable: false),
  );
  final digest = sha1.convert(utf8.encode(payload)).toString();
  final version = int.parse(digest.substring(0, 8), radix: 16) & 0x7fffffff;
  final moodCounts = <MoodType, int>{
    for (final mood in MoodType.values)
      mood: quotes.where((quote) => quote.poolTier.containsKey(mood)).length,
  };
  return CatalogVersion(
    version: max(version, 1),
    generatedAt: DateTime.now().toUtc(),
    moodCounts: moodCounts,
  );
}

Map<MoodType, double> _mapMoodStrength({
  required String category,
  required List<String> tags,
}) {
  final tokens = <String>{
    ..._normalizeForComparison(category).split(' '),
    for (final tag in tags) ..._normalizeForComparison(tag).split(' '),
  }..removeWhere((token) => token.isEmpty);
  final moodStrength = <MoodType, double>{};
  for (final entry in moodKeywordMap.entries) {
    final matchedKeywords = entry.value
        .where((keyword) => tokens.contains(_normalizeForComparison(keyword)))
        .length;
    if (matchedKeywords == 0) {
      continue;
    }
    final ratio = matchedKeywords / entry.value.length;
    moodStrength[entry.key] = ratio < 0.5 ? 0.5 : ratio.clamp(0.5, 1.0);
  }
  return moodStrength;
}

int deriveRhythmScore({required String text, required List<String> tags}) {
  final wordCount = _normalizeForComparison(
    text,
  ).split(' ').where((word) => word.isNotEmpty).length;
  var score = 45;
  if (wordCount <= 8) {
    score += 18;
  } else if (wordCount <= 18) {
    score += 10;
  } else if (wordCount >= 35) {
    score -= 14;
  }
  if (text.contains('!')) {
    score += 10;
  }
  if (text.contains('?')) {
    score += 4;
  }
  if (text.contains(';') || text.contains(':')) {
    score -= 3;
  }

  final normalizedTags = tags
      .map(_normalizeForComparison)
      .where((tag) => tag.isNotEmpty)
      .toSet();
  const highEnergyTags = {
    'motivation',
    'success',
    'courage',
    'strength',
    'action',
    'confidence',
    'purpose',
  };
  const lowEnergyTags = {
    'sadness',
    'grief',
    'loneliness',
    'peace',
    'patience',
    'rest',
    'sleep',
  };
  if (normalizedTags.any(highEnergyTags.contains)) {
    score += 12;
  }
  if (normalizedTags.any(lowEnergyTags.contains)) {
    score -= 8;
  }
  return score.clamp(0, 100);
}

QuoteArcTier deriveQuoteArcTier({
  required MoodType mood,
  required String text,
  required List<String> tags,
  required String category,
  required int popularityScore,
}) {
  final tokens = <String>{
    ..._normalizeForComparison(text).split(' '),
    ..._normalizeForComparison(category).split(' '),
    for (final tag in tags) ..._normalizeForComparison(tag).split(' '),
  }..removeWhere((token) => token.isEmpty);

  const mirrorTokens = {
    'sadness',
    'sad',
    'fear',
    'anxiety',
    'worry',
    'grief',
    'loss',
    'sorrow',
    'loneliness',
    'alone',
    'pain',
    'cry',
    'crying',
    'stress',
    'pressure',
    'burnout',
  };
  const bridgeTokens = {
    'life',
    'truth',
    'wisdom',
    'philosophy',
    'change',
    'time',
    'patience',
    'growth',
    'learn',
    'healing',
  };
  const windowTokens = {
    'hope',
    'optimism',
    'positive',
    'happiness',
    'joy',
    'inspiration',
    'success',
    'courage',
    'strength',
    'future',
    'gratitude',
  };

  final mirror = tokens.any(mirrorTokens.contains);
  final bridge = tokens.any(bridgeTokens.contains);
  final window = tokens.any(windowTokens.contains) || popularityScore >= 650000;
  final lowMood = {
    MoodType.tired,
    MoodType.anxious,
    MoodType.stressed,
    MoodType.sad,
    MoodType.lonely,
  }.contains(mood);

  if (lowMood && mirror) {
    return QuoteArcTier.mirror;
  }
  if (window) {
    return QuoteArcTier.window;
  }
  if (mirror && !lowMood) {
    return QuoteArcTier.bridge;
  }
  if (bridge || text.length > 160) {
    return QuoteArcTier.bridge;
  }
  return QuoteArcTier.mirror;
}

bool _isDuplicate(
  _PreparedQuote candidate,
  Map<String, List<_PreparedQuote>> bucketMap,
) {
  final seen = <_PreparedQuote>{};
  for (final key in _bucketKeys(candidate)) {
    final possibleMatches = bucketMap[key];
    if (possibleMatches == null) {
      continue;
    }
    for (final other in possibleMatches) {
      if (!seen.add(other)) {
        continue;
      }
      if (candidate.normalizedText == other.normalizedText &&
          candidate.normalizedAuthor == other.normalizedAuthor) {
        return true;
      }
      if (_jaccard(candidate.tokens, other.tokens) >
          duplicateJaccardThreshold) {
        return true;
      }
    }
  }
  return false;
}

Iterable<String> _bucketKeys(_PreparedQuote quote) sync* {
  final sortedTokens = quote.tokens.toList(growable: false)..sort();
  final tokenCount = sortedTokens.length;
  final prefix = sortedTokens.take(min(6, tokenCount)).toList(growable: false);
  if (prefix.isEmpty) {
    return;
  }
  yield '${quote.normalizedAuthor}|$tokenCount|${prefix.take(min(3, prefix.length)).join('_')}';
  yield '$tokenCount|${prefix.join('_')}';
  yield '${prefix.first}|${prefix.last}|$tokenCount';
  for (final token in prefix.take(4)) {
    yield '$token|${tokenCount ~/ 2}';
  }
}

double _jaccard(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) {
    return 0;
  }
  final intersection = a.intersection(b).length;
  final union = a.union(b).length;
  if (union == 0) {
    return 0;
  }
  return intersection / union;
}

Set<String> _tokenizeForSimilarity(String value) {
  return _normalizeForComparison(value)
      .split(' ')
      .where((token) => token.isNotEmpty && !_stopWords.contains(token))
      .toSet();
}

String _normalizeSpacing(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _normalizeForComparison(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _deterministicUuid(String value) {
  final digest = sha1.convert(utf8.encode(value)).toString();
  return '${digest.substring(0, 8)}-'
      '${digest.substring(8, 12)}-'
      '${digest.substring(12, 16)}-'
      '${digest.substring(16, 20)}-'
      '${digest.substring(20, 32)}';
}
