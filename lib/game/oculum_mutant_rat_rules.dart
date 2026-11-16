const oculumMutantRatId = 'topo_mutante';
const oculumMutantRatSummon = 'mutant_rat_summon';
const oculumMutantRatPup = 'mutant_rat_pup';
const oculumMutantRatBite = 'mutant_rat_bite';
const oculumMutantRatPupHp = 1;
const oculumMutantRatBiteDamage = 10;

const oculumMutantRatPupCountFormulas = ['1d4', '1d6+1', '1d9+3'];

String? oculumMutantRatBiteTarget(
  Iterable<String> candidates,
  String? lastAggressor,
  int Function(int count) pick,
) {
  final valid = candidates.where((tag) => tag.isNotEmpty).toSet().toList();
  if (valid.isEmpty) return null;
  if (valid.contains(lastAggressor)) return lastAggressor;
  return valid[pick(valid.length).clamp(0, valid.length - 1).toInt()];
}
