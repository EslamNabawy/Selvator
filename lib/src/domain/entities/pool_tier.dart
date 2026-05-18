enum PoolTier {
  core,
  extended,
  wildcard;

  static PoolTier fromKey(String value) {
    return PoolTier.values.firstWhere(
      (tier) => tier.name == value,
      orElse: () => PoolTier.core,
    );
  }
}
