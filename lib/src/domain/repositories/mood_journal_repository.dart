import 'package:wisely/src/domain/entities/mood_journal_entry.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/journal_entry_filter.dart';

abstract class MoodJournalRepository {
  Future<void> initialize();

  List<MoodJournalEntry> recentEntries({MoodType? mood, int limit = 5});

  List<MoodJournalEntry> entries({
    List<MoodType>? moods,
    JournalEntryFilter filter = JournalEntryFilter.recent,
    int limit = 50,
  });

  Future<void> saveEntry({
    required MoodType mood,
    List<MoodType>? moods,
    required String note,
    String situation = '',
    String feelings = '',
    String handledWith = '',
    String needNow = '',
    String kindSelfTalk = '',
  });

  Future<void> deleteEntry(String id);

  Future<void> clearEntries();
}
