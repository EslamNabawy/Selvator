import 'package:hive/hive.dart';
import 'package:wisely/src/data/hive/hive_adapters.dart';
import 'package:wisely/src/domain/entities/journal_entry_filter.dart';
import 'package:wisely/src/domain/entities/mood_journal_entry.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/repositories/mood_journal_repository.dart';

class HiveMoodJournalRepository implements MoodJournalRepository {
  static const String boxName = 'moodJournal';

  late final Box<MoodJournalEntry> _journalBox;
  List<MoodJournalEntry> _entries = const [];
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    registerHiveAdapters();
    _journalBox = await Hive.openBox<MoodJournalEntry>(boxName);
    _loadCache();
    _initialized = true;
  }

  @override
  List<MoodJournalEntry> recentEntries({MoodType? mood, int limit = 5}) {
    final filtered = _entries
        .where((entry) => mood == null || entry.moods.contains(mood))
        .take(limit)
        .toList(growable: false);
    return filtered;
  }

  @override
  List<MoodJournalEntry> entries({
    List<MoodType>? moods,
    JournalEntryFilter filter = JournalEntryFilter.recent,
    int limit = 50,
  }) {
    final moodSet = moods?.toSet() ?? const <MoodType>{};
    final filtered = _entries
        .where((entry) {
          final moodMatches =
              moodSet.isEmpty ||
              entry.moods.any((mood) => moodSet.contains(mood));
          if (!moodMatches) {
            return false;
          }
          return switch (filter) {
            JournalEntryFilter.recent => true,
            JournalEntryFilter.needNow => entry.hasNeedNow,
            JournalEntryFilter.handledWith => entry.hasHandledWith,
          };
        })
        .take(limit)
        .toList(growable: false);
    return filtered;
  }

  @override
  Future<void> saveEntry({
    required MoodType mood,
    List<MoodType>? moods,
    required String note,
    String situation = '',
    String feelings = '',
    String handledWith = '',
    String needNow = '',
    String kindSelfTalk = '',
  }) async {
    final trimmedNote = note.trim();
    final trimmedSituation = situation.trim();
    final trimmedFeelings = feelings.trim();
    final trimmedHandledWith = handledWith.trim();
    final trimmedNeedNow = needNow.trim();
    final trimmedKindSelfTalk = kindSelfTalk.trim();
    final hasAnyText = [
      trimmedNote,
      trimmedSituation,
      trimmedFeelings,
      trimmedHandledWith,
      trimmedNeedNow,
      trimmedKindSelfTalk,
    ].any((value) => value.isNotEmpty);
    if (!hasAnyText) {
      return;
    }
    final now = DateTime.now();
    final entry = MoodJournalEntry(
      id: 'journal-${now.microsecondsSinceEpoch}-${mood.name}',
      primaryMood: mood,
      moods: moods,
      note: trimmedNote,
      situation: trimmedSituation,
      feelings: trimmedFeelings,
      handledWith: trimmedHandledWith,
      needNow: trimmedNeedNow,
      kindSelfTalk: trimmedKindSelfTalk,
      createdAt: now,
      updatedAt: now,
    );
    await _journalBox.put(entry.id, entry);
    _loadCache();
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _journalBox.delete(id);
    _loadCache();
  }

  @override
  Future<void> clearEntries() async {
    await _journalBox.clear();
    _loadCache();
  }

  void _loadCache() {
    _entries = _journalBox.values.toList(growable: false)
      ..sort((a, b) {
        final updatedComparison = b.updatedAt.compareTo(a.updatedAt);
        if (updatedComparison != 0) {
          return updatedComparison;
        }
        final createdComparison = b.createdAt.compareTo(a.createdAt);
        if (createdComparison != 0) {
          return createdComparison;
        }
        return b.id.compareTo(a.id);
      });
  }
}
