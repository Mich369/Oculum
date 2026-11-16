part of 'monster_book.dart';

const _goblinKingMonster = MonsterBookEntry(
  id: oculumGoblinKingId,
  nameIt: 'Re Goblin',
  nameEn: 'Goblin King',
  descIt:
      'Un piccolo re dalla corona scheggiata e dal mantello scuro. Le sue guardie si frappongono tra lui e chi lo colpisce. Il Re riappare alle spalle di un bersaglio e il suo colpo regale attinge alla Potenza attuale.',
  descEn:
      'A small king with a chipped crown and a dark mantle. His guards intercept attacks. He reappears behind a target and strikes with his current Power.',
  elementId: 'fisico',
  spriteAssetPath: '',
  isMiniBoss: true,
  isBoss: false,
  isNullFateless: false,
  canWieldWeapons: true,
  stats: {'level': 0, 'resilienza': 6, 'volonta': 9, 'materia': 4, 'oculum': 9},
  encounterRules: {'authoredCanonical': true},
  skillIds: [
    oculumGoblinGuardianKind,
    oculumGoblinVanishEffect,
    oculumGoblinRegalStrikeEffect,
  ],
  dropIds: ['zanne_goblin'],
);

const _goblinKingTechniques = <String, MonsterConcreteTechnique>{
  oculumGoblinGuardianKind: MonsterConcreteTechnique(
    name: 'Richiamo della guardia',
    action:
        'Spendi un’Azione per evocare una guardia più forte a ogni forma. La guardia ha una sola Reazione a ogni suo turno personale, dedicata a prendere un colpo al posto dell’evocatore',
    element: 'fisico',
    kind: 'richiamo',
    requiredLevel: 0,
    minimums: [2, 3, 4],
    maximums: [2, 3, 4],
    cooldownValues: [5, 4, 3],
    forms: [
      [
        MonsterTechniqueEffect(
          'evocazione',
          '1',
          target: oculumGoblinGuardianKind,
          mode: 'immediato',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'evocazione',
          '2',
          target: oculumGoblinGuardianKind,
          mode: 'immediato',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'evocazione',
          '3',
          target: oculumGoblinGuardianKind,
          mode: 'immediato',
        ),
      ],
    ],
  ),
  oculumGoblinVanishEffect: MonsterConcreteTechnique(
    name: 'Sparizione del Re',
    action:
        'Prepari senza spendere un’Azione aggiuntiva. Al prossimo attacco appari alle spalle del singolo bersaglio scelto, con il bonus indicato al tiro',
    element: 'fisico',
    kind: 'movimento',
    requiredLevel: 0,
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [2, 2, 2],
    forms: [
      [
        MonsterTechniqueEffect(
          'modifica_sottotratto',
          '12',
          target: oculumGoblinVanishEffect,
          mode: 'prossima_azione',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'modifica_sottotratto',
          '13',
          target: oculumGoblinVanishEffect,
          mode: 'prossima_azione',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'modifica_sottotratto',
          '15',
          target: oculumGoblinVanishEffect,
          mode: 'prossima_azione',
        ),
      ],
    ],
  ),
  oculumGoblinRegalStrikeEffect: MonsterConcreteTechnique(
    name: 'Colpo regale',
    action:
        'Spendi un’Azione per colpire un singolo bersaglio. Aggiungi ai Danni normali un quarto della Potenza attuale, per difetto',
    element: 'fisico',
    kind: 'attacco',
    requiredLevel: 0,
    minimums: [2, 2, 2],
    maximums: [2, 2, 2],
    cooldownValues: [5, 5, 5],
    forms: [
      [
        MonsterTechniqueEffect(
          'modifica_sottotratto',
          '25',
          target: oculumGoblinRegalStrikeEffect,
          mode: 'prossima_azione',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'modifica_sottotratto',
          '25',
          target: oculumGoblinRegalStrikeEffect,
          mode: 'prossima_azione',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'modifica_sottotratto',
          '25',
          target: oculumGoblinRegalStrikeEffect,
          mode: 'prossima_azione',
        ),
      ],
    ],
  ),
};
