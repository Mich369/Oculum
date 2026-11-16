import 'dart:math';

const oculumOculiathId = 'oculiath';
const oculumLesserOculiathId = 'oculiath_minore';
const oculumGreaterOculiathId = 'oculiath_maggiore';
const oculumOculiathRayRule = 'oculiath_ray';
const oculumLesserOculiathRayTechnique = 'oculiath_lesser_ray';
const oculumGreaterOculiathRayRule = 'oculiath_greater_ray';
const oculumOculiathRayDamageRule = 'oculiath_ray_damage';
const oculumOculiathSecondaryRayCount = 4;
const oculumOculiathRayRanges = [16, 25, 30];
const oculumOculiathRayBonuses = [5, 12, 40];
const oculumLesserOculiathRayBonuses = [2, 6, 20];
const oculumGreaterOculiathRayBonuses = [10, 24, 60];
const oculumOculiathSecondaryReduction = [10, 6, 3];

List<int> oculumGreaterOculiathWorkingEyes(Object? parts) => [
  for (var eye = 1; eye <= 1 + oculumOculiathSecondaryRayCount; eye++)
    if (oculumOculiathPartIntact(parts, 'eyes_$eye')) eye,
];

bool oculumOculiathPartIntact(Object? parts, String id) {
  final part = parts is Map ? parts[id] : null;
  if (part is! Map) return true;
  final damage = int.tryParse('${part['damageTaken']}') ?? 0;
  final maximum = int.tryParse('${part['maximumHp']}') ?? 1;
  return damage < maximum;
}

bool oculumOculiathHasOnlyRay(String id) => const {
  oculumOculiathId,
  oculumLesserOculiathId,
  oculumGreaterOculiathId,
}.contains(id.split('_variante_').first);

int oculumOculiathHealthFromResilience(String id, int health) =>
    id.split('_variante_').first == oculumLesserOculiathId
    ? max(1, health * 60 ~/ 100)
    : health;

bool oculumOculiathIsRayEffect(String target) => const {
  oculumOculiathRayRule,
  oculumGreaterOculiathRayRule,
  oculumOculiathRayDamageRule,
}.contains(target);

bool oculumOculiathHasHook(String id) => const {
  oculumOculiathId,
  oculumLesserOculiathId,
}.contains(id.split('_variante_').first);

int oculumOculiathRayDamage(int primaryDamage, {int reduction = 0}) =>
    max(0, primaryDamage) * (100 - reduction.clamp(0, 100)) ~/ 100;

bool oculumOculiathWithinRange({
  required double dxMeters,
  required double dyMeters,
  required double dzMeters,
  required int range,
}) =>
    range > 0 &&
    dxMeters * dxMeters + dyMeters * dyMeters + dzMeters * dzMeters <=
        range * range + 1e-8;

bool oculumOculiathCanGrab({
  required String monsterId,
  required int carrierCurrentWill,
  required int targetCurrentWill,
  required bool inContact,
  required bool hookIntact,
  required bool hasPassenger,
}) =>
    oculumOculiathHasHook(monsterId) &&
    inContact &&
    hookIntact &&
    !hasPassenger &&
    targetCurrentWill >= 0 &&
    targetCurrentWill < carrierCurrentWill;

/// Use the accepted vertical changes from movement during the hold.
/// Positive values ascend and negative values descend.
double? oculumOculiathCarriedElevation({
  required double initialElevationMeters,
  required Iterable<double> verticalMovementMeters,
}) {
  if (!initialElevationMeters.isFinite) return null;
  var elevation = initialElevationMeters;
  for (final change in verticalMovementMeters) {
    elevation += change;
    if (!elevation.isFinite) return null;
  }
  return elevation;
}

/// Heights share the same reference plane, including below-ground surfaces.
double? oculumOculiathFallDistance({
  required double elevationMeters,
  required double surfaceElevationMeters,
}) {
  if (!elevationMeters.isFinite || !surfaceElevationMeters.isFinite) {
    return null;
  }
  final difference = elevationMeters - surfaceElevationMeters;
  return difference.isFinite ? max(0.0, difference) : null;
}
