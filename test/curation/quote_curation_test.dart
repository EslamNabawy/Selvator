import 'package:flutter_test/flutter_test.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/pool_tier.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/quote_arc_tier.dart';
import 'package:wisely/src/domain/curation/quote_curation.dart';

void main() {
  group('quote curation', () {
    test('drops invalid entries and deduplicates overlapping quotes', () {
      final catalog = curateQuotes([
        const RawQuote(
          text:
              'Believe in yourself and keep walking toward the bright future ahead.',
          author: 'Author A',
          tags: ['positive', 'hope'],
          category: 'hope',
          popularity: 0.9,
        ),
        const RawQuote(
          text:
              'Believe in yourself, and keep walking toward the bright future ahead!',
          author: 'Author A',
          tags: ['positive', 'hope'],
          category: 'hope',
          popularity: 0.8,
        ),
        const RawQuote(
          text: 'Too short',
          author: 'Author B',
          tags: ['joy'],
          category: 'happy',
          popularity: 0.7,
        ),
      ]);

      expect(catalog.quotes, hasLength(1));
      expect(catalog.quotes.single.author, 'Author A');
      expect(catalog.quotes.single.moods, contains(MoodType.hopeful));
    });

    test('applies author cap and mood strength floor', () {
      final quotes = [
        const RawQuote(
          text:
              'Keep your courage steady and move through every obstacle with purpose and patience.',
          author: 'Repeat Author',
          tags: ['motivation'],
          category: 'motivation',
          popularity: 0.99,
        ),
        const RawQuote(
          text:
              'A disciplined heart can turn slow progress into remarkable success over time.',
          author: 'Repeat Author',
          tags: ['motivation'],
          category: 'motivation',
          popularity: 0.98,
        ),
        const RawQuote(
          text:
              'Purpose grows when you keep showing up, even on the mornings that feel the heaviest.',
          author: 'Repeat Author',
          tags: ['motivation'],
          category: 'motivation',
          popularity: 0.97,
        ),
        const RawQuote(
          text:
              'Dreams become practical when your daily habits are stronger than your excuses.',
          author: 'Repeat Author',
          tags: ['motivation'],
          category: 'motivation',
          popularity: 0.96,
        ),
        const RawQuote(
          text:
              'Success favors the patient builder who improves a little and learns a lot each day.',
          author: 'Repeat Author',
          tags: ['motivation'],
          category: 'motivation',
          popularity: 0.95,
        ),
      ];
      final catalog = curateQuotes(quotes);
      final motivatedQuotes = catalog.quotes
          .where((quote) => quote.poolTier[MoodType.motivated] != null)
          .toList(growable: false);

      expect(motivatedQuotes, hasLength(3));
      expect(
        motivatedQuotes.every(
          (quote) => quote.moodStrength[MoodType.motivated]! >= 0.5,
        ),
        isTrue,
      );
      expect(
        motivatedQuotes.every(
          (quote) => quote.poolTier[MoodType.motivated] == PoolTier.core,
        ),
        isTrue,
      );
    });

    test('maps silvator mood aliases into existing app moods', () {
      final catalog = curateQuotes([
        const RawQuote(
          text:
              'The angry heart needs room to cool before pressure becomes another fire.',
          author: 'Silvator One',
          tags: ['anger', 'rage'],
          category: 'anger',
          popularity: 0.9,
        ),
        const RawQuote(
          text:
              'Fear gets smaller when one calm breath creates a little space inside the panic.',
          author: 'Silvator Two',
          tags: ['fear', 'panic'],
          category: 'fear',
          popularity: 0.8,
        ),
        const RawQuote(
          text:
              'Boredom can be a quiet signal that the tired mind wants a softer rhythm.',
          author: 'Silvator Three',
          tags: ['boredom', 'apathy'],
          category: 'boredom',
          popularity: 0.7,
        ),
      ]);

      expect(
        catalog.quotes.any(
          (quote) => quote.poolTier.containsKey(MoodType.stressed),
        ),
        isTrue,
      );
      expect(
        catalog.quotes.any(
          (quote) => quote.poolTier.containsKey(MoodType.anxious),
        ),
        isTrue,
      );
      expect(
        catalog.quotes.any(
          (quote) => quote.poolTier.containsKey(MoodType.tired),
        ),
        isTrue,
      );
    });

    test('does not match mood aliases inside unrelated words', () {
      final catalog = curateQuotes([
        const RawQuote(
          text:
              'Courage can turn every dangerous crossing into a careful lesson.',
          author: 'Silvator Four',
          tags: ['danger', 'dangerous'],
          category: 'challenge',
          popularity: 0.9,
        ),
        const RawQuote(
          text:
              'A fearless voice can still stay kind when the room grows loud.',
          author: 'Silvator Five',
          tags: ['fearless', 'bold'],
          category: 'confidence',
          popularity: 0.8,
        ),
      ]);

      expect(
        catalog.quotes.any(
          (quote) => quote.poolTier.containsKey(MoodType.stressed),
        ),
        isFalse,
      );
      expect(
        catalog.quotes.any(
          (quote) => quote.poolTier.containsKey(MoodType.anxious),
        ),
        isFalse,
      );
      expect(
        catalog.quotes.any(
          (quote) => quote.poolTier.containsKey(MoodType.confident),
        ),
        isTrue,
      );
    });

    test('derives rhythm score and arc tier into curated quotes', () {
      final catalog = curateQuotes([
        const RawQuote(
          text:
              'Grief can be held gently while hope opens one quiet window for tomorrow.',
          author: 'Arc Author',
          tags: ['grief', 'hope'],
          category: 'sadness',
          popularity: 0.8,
        ),
      ]);

      final quote = catalog.quotes.single;
      expect(quote.rhythmScore, inInclusiveRange(0, 100));
      expect(quote.arcTierByMood[MoodType.sad], QuoteArcTier.mirror);
      expect(quote.toJson()['rhythmScore'], isA<int>());
      expect(
        QuoteEntry.fromJson(quote.toJson()).arcTierByMood[MoodType.sad],
        QuoteArcTier.mirror,
      );
    });
  });
}
