import 'package:wisely/src/domain/entities/catalog_version.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/pool_tier.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/session_models.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';

abstract class QuoteRepository {
  static const String globalTopKey = 'global_top_200';

  UserProfile get profile;
  SessionAggregates get sessionAggregates;
  CatalogVersion? get catalogVersion;
  List<QuoteEntry> get allQuotes;

  Future<void> initialize();

  QuoteEntry? quoteById(String id);

  List<QuoteEntry> quotesByIds(Iterable<String> ids);

  List<String> moodPoolIds(MoodType mood, PoolTier tier);

  List<String> globalTopIds();

  List<QuoteEntry> quotesByAuthor(String author);

  List<QuoteEntry> searchQuotes(String query, {int limit = 24});

  Future<void> saveProfile(UserProfile profile);

  Future<void> saveSessionAggregates(SessionAggregates aggregates);

  Future<void> clearUserData();
}
