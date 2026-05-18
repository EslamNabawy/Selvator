import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:wisely/src/domain/entities/catalog_version.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/pool_tier.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/session_models.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/domain/repositories/quote_repository.dart';
import 'package:wisely/src/data/hive/hive_adapters.dart';

class HiveQuoteRepository implements QuoteRepository {
  static const String quotesBoxName = 'quotes';
  static const String moodIndexBoxName = 'moodIndex';
  static const String profileBoxName = 'profile';
  static const String sessionLogBoxName = 'sessionLog';
  static const String profileKey = 'profile';
  static const String sessionAggregatesKey = 'aggregates';
  static const String catalogVersionKey = 'catalogVersion';
  late final Box<QuoteEntry> _quotesBox;
  late final Box<List> _moodIndexBox;
  late final Box<UserProfile> _profileBox;
  late final Box<dynamic> _sessionLogBox;

  Map<String, QuoteEntry> _quotesById = const {};
  Map<String, List<String>> _moodIndex = const {};
  List<QuoteEntry> _allQuotes = const [];
  UserProfile _profile = UserProfile.initial();
  SessionAggregates _sessionAggregates = SessionAggregates.initial();
  CatalogVersion? _catalogVersion;

  @override
  UserProfile get profile => _profile;
  @override
  SessionAggregates get sessionAggregates => _sessionAggregates;
  @override
  CatalogVersion? get catalogVersion => _catalogVersion;
  @override
  List<QuoteEntry> get allQuotes => _allQuotes;

  @override
  Future<void> initialize() async {
    registerHiveAdapters();
    _quotesBox = await Hive.openBox<QuoteEntry>(quotesBoxName);
    _moodIndexBox = await Hive.openBox<List>(moodIndexBoxName);
    _profileBox = await Hive.openBox<UserProfile>(profileBoxName);
    _sessionLogBox = await Hive.openBox<dynamic>(sessionLogBoxName);

    await _seedIfNeeded();
    _loadCaches();
  }

  @override
  QuoteEntry? quoteById(String id) => _quotesById[id];

  @override
  List<QuoteEntry> quotesByIds(Iterable<String> ids) {
    return ids
        .map((id) => _quotesById[id])
        .whereType<QuoteEntry>()
        .toList(growable: false);
  }

  @override
  List<String> moodPoolIds(MoodType mood, PoolTier tier) {
    return _moodIndex['${mood.name}_${tier.name}'] ?? const [];
  }

  @override
  List<String> globalTopIds() =>
      _moodIndex[QuoteRepository.globalTopKey] ?? const [];

  @override
  List<QuoteEntry> quotesByAuthor(String author) {
    final normalized = author.trim().toLowerCase();
    final matches =
        _allQuotes
            .where((quote) => quote.author.toLowerCase() == normalized)
            .toList()
          ..sort((a, b) => b.popularity.compareTo(a.popularity));
    return matches;
  }

  @override
  List<QuoteEntry> searchQuotes(String query, {int limit = 24}) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }
    final results = _allQuotes.where((quote) {
      return quote.text.toLowerCase().contains(normalized) ||
          quote.author.toLowerCase().contains(normalized) ||
          quote.tags.any((tag) => tag.contains(normalized));
    }).toList()..sort((a, b) => b.popularity.compareTo(a.popularity));
    return results.take(limit).toList(growable: false);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    await _profileBox.put(profileKey, profile);
  }

  @override
  Future<void> saveSessionAggregates(SessionAggregates aggregates) async {
    _sessionAggregates = aggregates;
    await _sessionLogBox.put(sessionAggregatesKey, aggregates);
  }

  @override
  Future<void> clearUserData() async {
    _profile = UserProfile.initial();
    _sessionAggregates = SessionAggregates.initial();
    await _profileBox.put(profileKey, _profile);
    await _sessionLogBox.put(sessionAggregatesKey, _sessionAggregates);
  }

  Future<void> _seedIfNeeded() async {
    final assetVersion = await _loadCatalogVersionAsset();
    _catalogVersion = assetVersion;
    final storedVersion = _sessionLogBox.get(catalogVersionKey) as int?;
    final shouldSeed =
        storedVersion != assetVersion.version ||
        _quotesBox.isEmpty ||
        _moodIndexBox.isEmpty;

    if (!shouldSeed) {
      _profileBox.put(
        profileKey,
        _profileBox.get(profileKey) ?? UserProfile.initial(),
      );
      _sessionLogBox.put(
        sessionAggregatesKey,
        _sessionLogBox.get(sessionAggregatesKey) ?? SessionAggregates.initial(),
      );
      return;
    }

    final previousProfile =
        _profileBox.get(profileKey) ?? UserProfile.initial();
    final existingLikes = previousProfile.likedQuoteIds;

    final decodedQuotes = await _loadCuratedAsset();
    await _quotesBox.clear();
    await _moodIndexBox.clear();

    await _quotesBox.putAll({
      for (final quote in decodedQuotes) quote.id: quote,
    });

    final moodIndex = <String, List<String>>{};
    for (final mood in MoodType.values) {
      moodIndex['${mood.name}_core'] = decodedQuotes
          .where((quote) => quote.poolTier[mood] == PoolTier.core)
          .map((quote) => quote.id)
          .toList(growable: false);
      moodIndex['${mood.name}_extended'] = decodedQuotes
          .where((quote) => quote.poolTier[mood] == PoolTier.extended)
          .map((quote) => quote.id)
          .toList(growable: false);
    }
    final globalTopQuotes = decodedQuotes.toList()
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    moodIndex[QuoteRepository.globalTopKey] = globalTopQuotes
        .take(200)
        .map((quote) => quote.id)
        .toList(growable: false);

    await _moodIndexBox.putAll(moodIndex);

    final validIds = decodedQuotes.map((quote) => quote.id).toSet();
    final migratedProfile = previousProfile
        .copyWith(likedQuoteIds: existingLikes.where(validIds.contains).toSet())
        .pruned(validIds);
    await _profileBox.put(profileKey, migratedProfile);
    await _sessionLogBox.put(
      sessionAggregatesKey,
      _sessionLogBox.get(sessionAggregatesKey) ?? SessionAggregates.initial(),
    );
    await _sessionLogBox.put(catalogVersionKey, assetVersion.version);
  }

  void _loadCaches() {
    _allQuotes = _quotesBox.values.toList(growable: false)
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    _quotesById = {for (final quote in _allQuotes) quote.id: quote};
    _moodIndex = {
      for (final key in _moodIndexBox.keys.cast<String>())
        key: _moodIndexBox.get(key, defaultValue: const [])!.cast<String>(),
    };
    _profile = _profileBox.get(profileKey) ?? UserProfile.initial();
    _sessionAggregates =
        (_sessionLogBox.get(sessionAggregatesKey) as SessionAggregates?) ??
        SessionAggregates.initial();
  }

  Future<List<QuoteEntry>> _loadCuratedAsset() async {
    final raw = await rootBundle.loadString('assets/data/quotes_curated.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => QuoteEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<CatalogVersion> _loadCatalogVersionAsset() async {
    final raw = await rootBundle.loadString('assets/data/catalog_version.json');
    return CatalogVersion.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
