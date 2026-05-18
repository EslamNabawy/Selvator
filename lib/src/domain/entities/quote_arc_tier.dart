enum QuoteArcTier {
  mirror,
  bridge,
  window;

  static QuoteArcTier fromKey(String? value) {
    return QuoteArcTier.values.firstWhere(
      (tier) => tier.name == value,
      orElse: () => QuoteArcTier.bridge,
    );
  }
}
