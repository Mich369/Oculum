part of '../../main.dart';

const _monsterWeakOpenType = 'Open innata';
const _monsterWeakOpenLevel = 3;
const _monsterWeakOpenPower = 'monster_weak_open_power';

bool oculumIsMonsterWeakOpen(CharacterArt art) =>
    art.tipo == _monsterWeakOpenType;

int _oculumScaleMonsterWeakOpenValue(int value, int grade) =>
    oculumRoundFormulaResult(value * (100 + 10 * max(0, grade)) / 400);

const _monsterWeakOpenNumericTypes = {
  'danno',
  'danno_percentuale',
  'cura',
  'scudo',
  'difesa',
  'velocita',
  'hp_temporanei',
  'modifica_statistica',
  'modifica_sottotratto',
};

CharacterArt? oculumMonsterWeakOpen(CharacterArt primary) {
  if (primary.openName.trim().isEmpty ||
      !primary.openDescriptionEffects.any(
        (effect) => effect.id.startsWith('monster_open_ultimate_'),
      )) {
    return null;
  }
  final allEffects = [
    ...primary.openDescriptionEffects,
    ...primary.openBuffEffects,
    ...primary.openSkillEffects,
  ];
  if (!allEffects.any(
        (effect) =>
            effect.enabled &&
            _monsterWeakOpenNumericTypes.contains(effect.type) &&
            !const {
              'monster_open_marker',
              'monster_open_power',
            }.contains(effect.target),
      ) ||
      allEffects.any(
        (effect) =>
            effect.enabled &&
            !_monsterWeakOpenNumericTypes.contains(effect.type) &&
            effect.type != 'stato',
      )) {
    return null;
  }

  List<OculumStructuredEffect> copy(List<OculumStructuredEffect> effects) => [
    for (final effect in effects)
      OculumStructuredEffect.fromJson(effect.toJson())
        ..target = effect.target == 'monster_open_power'
            ? _monsterWeakOpenPower
            : effect.target
        ..scaleMonsterWeakOpen =
            _monsterWeakOpenNumericTypes.contains(effect.type) &&
            !const {
              'monster_open_marker',
              'monster_open_power',
            }.contains(effect.target)
        ..customDisplayText = '',
  ];
  OculumAbilityCooldown? cooldown(OculumAbilityCooldown? original) =>
      original == null
      ? null
      : (OculumAbilityCooldown.fromJson(original.toJson())..remaining = 0);
  final cost = oculumParseAbilityCost(primary.openSkill);
  return CharacterArt(
    nome: _monsterWeakOpenType,
    tipo: _monsterWeakOpenType,
    descrizione: 'Open debole della creatura.',
    skills: [],
    hasIntegrity: false,
    openName: 'Open debole · ${primary.openName}',
    openDescription:
        'Richiede livello $_monsterWeakOpenLevel. Gli effetti numerici '
        'valgono il 25% della Open principale, aumentato del 10% per Grado.',
    openDescriptionType: primary.openDescriptionType,
    openDescriptionEffects: copy(primary.openDescriptionEffects),
    openDescriptionCooldown: cooldown(primary.openDescriptionCooldown),
    openBuff: primary.openBuffEffects.isEmpty
        ? ''
        : 'Applica gli effetti ridotti del Buff della Open principale.',
    openBuffType: primary.openBuffType,
    openBuffEffects: copy(primary.openBuffEffects),
    openBuffCooldown: cooldown(primary.openBuffCooldown),
    openSkill: primary.openSkillEffects.isEmpty
        ? ''
        : 'Applica gli effetti ridotti della Skill Open.'
              '${cost == null ? '' : '\nCosto: ${cost.minimum}${cost.maximum == cost.minimum ? '' : '/${cost.maximum}'} ${cost.resource}.'}',
    openSkillType: primary.openSkillType,
    openSkillEffects: copy(primary.openSkillEffects),
    openSkillCooldown: cooldown(primary.openSkillCooldown),
    monsterOpenSkill: true,
  );
}
