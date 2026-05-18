import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/tag_audit.dart';

void main() {
  test(
    'tag audit reports raw tags, mood coverage, rhythm, and arc candidates',
    () {
      final temp = Directory.systemTemp.createTempSync('selvator_tag_audit_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final raw = File('${temp.path}/raw.json');
      final curated = File('${temp.path}/curated.json');
      raw.writeAsStringSync(
        jsonEncode([
          {
            'Quote': 'Hope is a quiet thing.',
            'Author': 'One',
            'Tags': ['hope', 'life'],
            'Category': 'hope',
            'Popularity': 0.9,
          },
          {
            'Quote': 'Sadness can soften.',
            'Author': 'Two',
            'Tags': ['sadness', 'life'],
            'Category': 'sadness',
            'Popularity': 0.8,
          },
        ]),
      );
      curated.writeAsStringSync(
        jsonEncode([
          {
            'id': 'q1',
            'text': 'Hope is a quiet thing that keeps the window open.',
            'author': 'One',
            'popularity': 90,
            'categories': ['hope'],
            'tags': ['hope', 'life'],
            'moods': ['hopeful'],
            'moodStrength': {'hopeful': 1},
            'poolTier': {'hopeful': 'core'},
          },
        ]),
      );

      final report = TagAuditAnalyzer().analyze(
        rawQuotesPath: raw.path,
        curatedQuotesPath: curated.path,
      );

      expect(report.rawQuoteCount, 2);
      expect(report.curatedQuoteCount, 1);
      expect(report.uniqueTagCount, 3);
      expect(report.moodCoverage['hopeful'], 1);
      expect(report.rhythmDistribution.max, greaterThan(0));
      expect(report.arcTierCandidates['hopeful']!['window'], 1);
      expect(report.toConsoleString(), contains('Selvator Tag Audit'));
    },
  );
}
