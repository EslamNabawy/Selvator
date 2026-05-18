import 'dart:math';

import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';

class PreferenceEngine {
  const PreferenceEngine();

  UserProfile boostTags({
    required UserProfile profile,
    required Iterable<String> tags,
    required double delta,
  }) {
    final weights = Map<String, double>.from(profile.tagPreferenceWeights);
    for (final tag in tags) {
      final key = tag.toLowerCase();
      weights[key] = ((weights[key] ?? 0) + delta).clamp(-1.0, 3.0).toDouble();
    }
    return profile.copyWith(tagPreferenceWeights: weights);
  }

  UserProfile recordDwellCompleted({
    required UserProfile profile,
    required QuoteEntry quote,
  }) {
    return boostTags(
      profile: profile,
      tags: quote.tags,
      delta: 0.3,
    ).copyWith(frustrationIndex: max(0, profile.frustrationIndex - 1));
  }

  UserProfile recordQuickRefresh({
    required UserProfile profile,
    required QuoteEntry quote,
  }) {
    return boostTags(profile: profile, tags: quote.tags, delta: -0.1).copyWith(
      frustrationIndex: (profile.frustrationIndex + 1).clamp(0, 10).toInt(),
    );
  }
}
