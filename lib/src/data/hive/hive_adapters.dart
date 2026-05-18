import 'package:hive/hive.dart';
import 'package:wisely/src/domain/entities/mood_journal_entry.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/session_models.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';

class QuoteEntryAdapter extends TypeAdapter<QuoteEntry> {
  @override
  final int typeId = 1;

  @override
  QuoteEntry read(BinaryReader reader) {
    return QuoteEntry.fromJson(Map<String, dynamic>.from(reader.readMap()));
  }

  @override
  void write(BinaryWriter writer, QuoteEntry obj) {
    writer.writeMap(obj.toJson());
  }
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    return UserProfile.fromJson(Map<String, dynamic>.from(reader.readMap()));
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeMap(obj.toJson());
  }
}

class SessionAggregatesAdapter extends TypeAdapter<SessionAggregates> {
  @override
  final int typeId = 3;

  @override
  SessionAggregates read(BinaryReader reader) {
    return SessionAggregates.fromJson(
      Map<String, dynamic>.from(reader.readMap()),
    );
  }

  @override
  void write(BinaryWriter writer, SessionAggregates obj) {
    writer.writeMap(obj.toJson());
  }
}

class MoodJournalEntryAdapter extends TypeAdapter<MoodJournalEntry> {
  @override
  final int typeId = 4;

  @override
  MoodJournalEntry read(BinaryReader reader) {
    return MoodJournalEntry.fromJson(
      Map<String, dynamic>.from(reader.readMap()),
    );
  }

  @override
  void write(BinaryWriter writer, MoodJournalEntry obj) {
    writer.writeMap(obj.toJson());
  }
}

void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(QuoteEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(UserProfileAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(SessionAggregatesAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(MoodJournalEntryAdapter());
  }
}
