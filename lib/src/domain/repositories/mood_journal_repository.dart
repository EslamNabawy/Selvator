import 'package:wisely/src/domain/entities/mood_journal_entry.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';

abstract class MoodJournalRepository {
  Future<void> initialize();

  List<MoodJournalEntry> recentEntries({MoodType? mood, int limit = 5});

  Future<void> saveEntry({required MoodType mood, required String note});

  Future<void> deleteEntry(String id);

  Future<void> clearEntries();
}
