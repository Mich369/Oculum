part of 'monster_book.dart';

const oculumBunnysHealSkill = 'bunny_heal';
const oculumBunnysDeathHealSkill = 'bunny_death_heal';

const _bunnysTechniques = <String, MonsterConcreteTechnique>{
  oculumBunnysHealSkill: MonsterConcreteTechnique(
    name: 'Leccata dei Bunnys',
    action:
        'Cura un avversario scelto del 25% della sua Vita attuale. '
        'Il costo in Oculum è pari al livello del bersaglio',
    element: 'natura',
    kind: 'cura',
    requiredLevel: 0,
    costResource: 'oculum',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    costDescription: 'Costo Oculum pari al livello del bersaglio.',
    forms: [
      [_bunnysHealEffect],
      [_bunnysHealEffect],
      [_bunnysHealEffect],
    ],
  ),
  oculumBunnysDeathHealSkill: MonsterConcreteTechnique(
    name: 'Pelo sulla ferita',
    action:
        'Passiva automatica alla morte confermata: cura ogni alleato '
        'del 50% della Vita attuale di quell’alleato',
    element: 'natura',
    kind: 'cura',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    forms: [
      [_bunnysDeathHealEffect],
      [_bunnysDeathHealEffect],
      [_bunnysDeathHealEffect],
    ],
  ),
};

const _bunnysHealEffect = MonsterTechniqueEffect(
  'planar',
  '25',
  target: oculumBunnysHealSkill,
  recipient: 'nemico',
  maximumTargets: 1,
);

const _bunnysDeathHealEffect = MonsterTechniqueEffect(
  'planar',
  '50',
  target: oculumBunnysDeathHealSkill,
  recipient: 'alleato',
);
