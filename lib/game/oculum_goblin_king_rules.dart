import 'dart:math';

const oculumGoblinKingId = 'goblin_king';
const oculumGoblinGuardianKind = 'goblin_king_guardian';
const oculumGoblinVanishEffect = 'goblin_king_vanish';
const oculumGoblinRegalStrikeEffect = 'goblin_king_regal_strike';

int oculumGoblinRegalStrikeBonus(int currentPower, {int percent = 25}) =>
    max(0, currentPower) * max(0, percent) ~/ 100;

({int resilience, int will, int matter}) oculumGoblinGuardianStats({
  required int form,
  required int level,
  required int grade,
}) {
  final tier = form.clamp(1, 3);
  final levelBonus = max(0, level);
  final gradeBonus = max(0, grade);
  return (
    resilience: tier + 1 + levelBonus + gradeBonus,
    will: tier + 2 + levelBonus,
    matter: tier + 2 + levelBonus + gradeBonus,
  );
}

bool oculumGoblinGuardianCanIntercept({
  required bool summon,
  required bool sameOwner,
  required bool sameTeam,
  required bool alive,
  required bool inFight,
  required bool targetedByAttack,
  required int normalReactionsRemaining,
}) =>
    summon &&
    sameOwner &&
    sameTeam &&
    alive &&
    inFight &&
    !targetedByAttack &&
    normalReactionsRemaining > 0;
