part of 'monster_book.dart';

const oculumAculotideId = 'aculotide';
const oculumAculotideDodgeSkill = 'aculotide_guizzo';
const oculumAculotideDodgeEffect = 'aculotide_guizzo_preparato';
const oculumAculotideCoronaSkill = 'aculotide_corona';
const oculumAculotideCoronaEffect = 'aculotide_corona_preparata';
const oculumAculotideSpineCount = 3;
const oculumAculotideDodgeBonuses = [2, 3, 6];
const oculumAculotideMaximumRise = 2.0;

const _aculotideCoronaForm = [
  MonsterTechniqueEffect(
    'planar',
    '0',
    target: oculumAculotideCoronaEffect,
    recipient: 'nemico',
    maximumTargets: oculumAculotideSpineCount,
  ),
];

double? oculumAculotideRaisedElevation(double elevation, double rise) {
  if (!elevation.isFinite ||
      !rise.isFinite ||
      rise <= 0 ||
      rise > oculumAculotideMaximumRise) {
    return null;
  }
  final result = elevation + rise;
  return result.isFinite ? result : null;
}

double oculumAculotideRestoredElevation({
  required double current,
  required double original,
  required double raised,
}) => current == raised && original.isFinite ? original : current;

int oculumAculotideSpineDamage(int totalDamage, int index) {
  final total = totalDamage < 0 ? 0 : totalDamage;
  final base = total ~/ oculumAculotideSpineCount;
  return base + (index < total % oculumAculotideSpineCount ? 1 : 0);
}

const _aculotideMonster = MonsterBookEntry(
  id: oculumAculotideId,
  nameIt: 'Aculotide',
  nameEn: 'Aculotide',
  descIt:
      'Mostro marino con un solo occhio. Le spine che lancia ricrescono '
      'subito. I fori sul ventre gli permettono di sollevarsi con un guizzo.',
  descEn:
      'A one-eyed sea creature. Its spines immediately regrow when fired. '
      'Openings on its belly let it dart upward.',
  elementId: 'acqua',
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: false,
  isNullFateless: false,
  planeIds: ['affogato'],
  skillIds: [oculumAculotideDodgeSkill, oculumAculotideCoronaSkill],
  encounterRules: {
    'authoredCanonical': true,
    'precisionBodyParts': [
      {'id': 'body', 'group': 'body', 'label': 'Corpo', 'penalty': 0},
      {'id': 'eyes', 'group': 'eyes', 'label': 'Occhio', 'penalty': 0},
    ],
  },
);

final _aculotideTechniques = <String, MonsterConcreteTechnique>{
  oculumAculotideDodgeSkill: MonsterConcreteTechnique(
    name: 'Guizzo',
    action:
        'Prepara +2/+3/+6 al prossimo tiro CM. Se la difesa riesce, '
        'sali fino a 2 metri sopra la quota attuale fino al prossimo turno',
    element: 'acqua',
    kind: 'movimento',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: const [0, 0, 0],
    maximums: const [0, 0, 0],
    cooldownValues: const [0, 0, 0],
    forms: [
      for (final bonus in oculumAculotideDodgeBonuses)
        [
          MonsterTechniqueEffect(
            'planar',
            '$bonus',
            target: oculumAculotideDodgeEffect,
            duration: '2',
          ),
        ],
    ],
  ),
  oculumAculotideCoronaSkill: const MonsterConcreteTechnique(
    name: 'Corona di aculei',
    action:
        'Distribuisci tre spine fisiche perforanti tra uno, due o tre '
        'avversari. Le spine ricrescono immediatamente',
    element: 'perforante',
    kind: 'attacco',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    forms: [_aculotideCoronaForm, _aculotideCoronaForm, _aculotideCoronaForm],
  ),
};
