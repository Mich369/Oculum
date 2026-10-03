/// Localized vulnerability. Only the Master owns and shares its damage result.
int oculumBlindSpotDamage(int base, int previousHits, int percentPerHit) {
  if (base <= 0) return 0;
  final hits = previousHits < 0 ? 0 : previousHits;
  final percent = percentPerHit < 0 ? 0 : percentPerHit;
  return (base * (100 + (hits + 1) * percent) / 100).round();
}
