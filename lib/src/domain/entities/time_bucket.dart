enum TimeBucket {
  morning,
  afternoon,
  night,
  lateNight;

  static TimeBucket fromKey(String? value) {
    return TimeBucket.values.firstWhere(
      (bucket) => bucket.name == value,
      orElse: () => TimeBucket.morning,
    );
  }
}
