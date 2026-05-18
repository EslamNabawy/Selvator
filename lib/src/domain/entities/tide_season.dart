enum TideSeason {
  stormy,
  thawing,
  bright,
  still;

  static TideSeason fromKey(String? value) {
    return TideSeason.values.firstWhere(
      (season) => season.name == value,
      orElse: () => TideSeason.still,
    );
  }
}
