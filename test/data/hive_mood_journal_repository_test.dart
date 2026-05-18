import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wisely/src/data/repositories/hive_mood_journal_repository.dart';
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
    expect(entries.single.note, 'I took a slower breath.');
    expect(entries.single.id, isNotEmpty);
    expect(entries.single.updatedAt, entries.single.createdAt);
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
