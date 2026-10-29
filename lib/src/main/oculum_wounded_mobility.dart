part of '../../main.dart';

int oculumWoundedMovementPercent({required int hp, required int maxHp}) {
  if (maxHp <= 0) return 100;
  if (hp * 10 < maxHp) return 50;
  return hp * 2 < maxHp ? 75 : 100;
}

int oculumWoundedInitiativePercent({required int hp, required int maxHp}) {
  if (maxHp <= 0) return 100;
  if (hp * 10 < maxHp) return 60;
  return hp * 2 < maxHp ? 75 : 100;
}

int oculumWoundedMovement(int base, {required int hp, required int maxHp}) =>
    max(0, base) * oculumWoundedMovementPercent(hp: hp, maxHp: maxHp) ~/ 100;

int oculumWoundedInitiative(int base, {required int hp, required int maxHp}) =>
    base <= 0
    ? base
    : base * oculumWoundedInitiativePercent(hp: hp, maxHp: maxHp) ~/ 100;

/// Older saves had no wound multiplier, so their stored total is the raw
/// baseline. New snapshots carry that baseline explicitly and never compound.
bool refreshEncounterWoundedInitiative(
  Map<String, dynamic> token, {
  required int hp,
  required int maxHp,
}) {
  final before = readIntValue(token['initiativeTotal']);
  final raw = readIntValue(token['initiativeUnwoundedTotal'], fallback: before);
  final percent = oculumWoundedInitiativePercent(hp: hp, maxHp: maxHp);
  token['initiativeUnwoundedTotal'] = raw;
  token['initiativeWoundPercent'] = percent;
  token['initiativeTotal'] = oculumWoundedInitiative(raw, hp: hp, maxHp: maxHp);
  return before != token['initiativeTotal'];
}

extension _OculumWoundedMobility on _OculumHomePageState {
  bool refreshWoundedInitiativeToken(
    Map<String, dynamic> token, {
    int? sheetIndex,
  }) {
    final index =
        sheetIndex ??
        localSheetIndexForOculumTag(publicInitiativeSourceTag(token));
    final hp = index >= 0
        ? sheetCurrentHpForDeathAt(index)
        : readIntValue(token['currentHp'] ?? token['hp'], fallback: 1);
    final maximum = index >= 0
        ? sheetMaxHpForDeathAt(index)
        : readIntValue(
            token['maxHp'] ?? token['maximumHp'] ?? token['derivedMaxHp'],
          );
    final changed = refreshEncounterWoundedInitiative(
      token,
      hp: hp,
      maxHp: maximum,
    );
    if (changed) {
      final group = masterInitiativeGroups
          .where((group) => '${group['id']}' == selectedMasterInitiativeGroupId)
          .firstOrNull;
      group?['woundedInitiativeOrderPending'] = true;
    }
    return changed;
  }

  int sheetUnwoundedInitiativeAt(int index) {
    if (index == schedaCorrente) return iniziativaNonFerita();
    final sheet = schedePersonaggio[index];
    return readIntValue(
      sheet['derivedUnwoundedIniziativa'],
      fallback: readIntValue(
        sheet['derivedIniziativa'],
        fallback: max(
          0,
          sheetBonusLivelloGradoAt(index) +
              sheetIntValueAt(index, 'materia') ~/ 5 +
              readIntValue((sheet['coreMasteryPoints'] as Map?)?['iniziativa']),
        ),
      ),
    );
  }
}
