import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wisely/src/data/repositories/hive_mood_journal_repository.dart';
import 'package:wisely/src/domain/entities/journal_entry_filter.dart';
import 'package:wisely/src/domain/entities/mood_journal_entry.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';

void main() {
  late Directory tempDirectory;
  late HiveMoodJournalRepository repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'wisely_mood_journal_test_',
    );
    Hive.init(tempDirectory.path);
    repository = HiveMoodJournalRepository();
    await repository.initialize();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('saves an entry with mood and trimmed note', () async {
    await repository.saveEntry(
      mood: MoodType.calm,
      note: '  I took a slower breath.  ',
    );

    final entries = repository.recentEntries(mood: MoodType.calm);

    expect(entries, hasLength(1));
    expect(entries.single.mood, MoodType.calm);
    expect(entries.single.primaryMood, MoodType.calm);
    expect(entries.single.moods, [MoodType.calm]);
    expect(entries.single.note, 'I took a slower breath.');
    expect(entries.single.id, isNotEmpty);
    expect(entries.single.updatedAt, entries.single.createdAt);
  });

  test('saves structured entry with mood mix and trimmed fields', () async {
    await repository.saveEntry(
      mood: MoodType.sad,
      moods: const [MoodType.sad, MoodType.calm],
      note: '  Main thought  ',
      situation: '  Hard conversation  ',
      feelings: '  heavy  ',
      handledWith: '  walked away  ',
      needNow: '  rest  ',
      kindSelfTalk: '  you tried  ',
    );

    final entry = repository.recentEntries(mood: MoodType.calm).single;

    expect(entry.primaryMood, MoodType.sad);
    expect(entry.moods, [MoodType.sad, MoodType.calm]);
    expect(entry.note, 'Main thought');
    expect(entry.situation, 'Hard conversation');
    expect(entry.feelings, 'heavy');
    expect(entry.handledWith, 'walked away');
    expect(entry.needNow, 'rest');
    expect(entry.kindSelfTalk, 'you tried');
  });

  test('filters structured entries by need and handled fields', () async {
    await repository.saveEntry(mood: MoodType.sad, note: 'plain');
    await repository.saveEntry(mood: MoodType.calm, note: '', needNow: 'space');
    await repository.saveEntry(
      mood: MoodType.focused,
      note: '',
      handledWith: 'called a friend',
    );

    expect(
      repository
          .entries(filter: JournalEntryFilter.needNow)
          .map((entry) => entry.needNow),
      ['space'],
    );
    expect(
      repository
          .entries(filter: JournalEntryFilter.handledWith)
          .map((entry) => entry.handledWith),
      ['called a friend'],
    );
  });

  test('old journal json migrates to structured defaults', () {
    final entry = MoodJournalEntry.fromJson({
      'id': 'old-entry',
      'mood': 'lonely',
      'note': 'old note',
      'createdAt': DateTime(2026, 5, 17).toIso8601String(),
    });

    expect(entry.primaryMood, MoodType.lonely);
    expect(entry.moods, [MoodType.lonely]);
    expect(entry.note, 'old note');
    expect(entry.situation, isEmpty);
    expect(entry.handledWith, isEmpty);
    expect(entry.updatedAt, entry.createdAt);
  });

  test('returns recent entries newest first and filters by mood', () async {
    await repository.saveEntry(mood: MoodType.happy, note: 'first');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repository.saveEntry(mood: MoodType.calm, note: 'second');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repository.saveEntry(mood: MoodType.happy, note: 'third');

    expect(repository.recentEntries(limit: 10).map((entry) => entry.note), [
      'third',
      'second',
      'first',
    ]);
    expect(
      repository.recentEntries(mood: MoodType.happy).map((entry) => entry.note),
      ['third', 'first'],
    );
  });

  test('deletes an entry', () async {
    await repository.saveEntry(mood: MoodType.focused, note: 'ship it');
    final entry = repository.recentEntries().single;

    await repository.deleteEntry(entry.id);

    expect(repository.recentEntries(), isEmpty);
  });

  test('clears entries for user data reset', () async {
    await repository.saveEntry(mood: MoodType.focused, note: 'one');
    await repository.saveEntry(mood: MoodType.grateful, note: 'two');

    await repository.clearEntries();

    expect(repository.recentEntries(), isEmpty);
  });
}
