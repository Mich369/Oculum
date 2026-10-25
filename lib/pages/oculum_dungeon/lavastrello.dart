part of 'monster_book.dart';

final _lavastrelloEntry =
    _canonicalCreature(
      'lavastrello',
      'Lavastrello',
      '',
      ['demoniaco', 'sotterraneo', 'foresta_elementale'],
      'fuoco',
      [1, 0, 1, 2],
      0,
      'Un minuscolo pipistrello dal pelo nero fuligginoso e dalle grandi orecchie appuntite. Gli occhi sono due braci arancioni e le sottili membrane delle ali sembrano cuoio annerito, percorso da vene rosse. Vive in una roccia lavica cava e aperta, tiepida al tatto. È molto debole: le ali sono il suo punto debole. Dalla tana esce un esemplare per giro, fino a cinque in totale; distruggere la roccia interrompe le uscite.',
      'Ali sottili e fragili.',
      [
        'lavastrello_fire_attack',
        'lavastrello_hunter',
        'lavastrello_nest_intuition',
      ],
      'membrana_lavastrello',
      resistances: {'fuoco': 'resistenza', 'acqua': 'debolezza'},
    ).copyWith(
      encounterRules: {
        'authoredCanonical': true,
        'difficulty': 'molto_facile',
        'nestMaximumSpawns': 5,
        'nestHpBase': 30,
        'nestHpPerLevel': 5,
        'huntReward': {'kills': 20, 'skillId': 'lavastrello_hunter'},
        'naturalScrollDrops': {
          'lavastrello_fire_attack': {'minimum': 18, 'maximum': 20},
        },
      },
    );

final _lavastrelloTechniques = <String, MonsterConcreteTechnique>{
  'lavastrello_fire_attack': _planarMove(
    'Attacco di Fuoco',
    'Il prossimo colpo arde e aggiunge Manifestazione del Potere ai Danni. Un critico positivo applica Fuoco per un turno. Costo fisso 1 Oculum; una sola Azione/Reazione per l’attacco.',
    'fuoco',
    'danno',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'danno',
            'manifestazione_potere',
            mode: 'prossima_azione',
            duration: '',
          ),
          const MonsterTechniqueEffect(
            'planar',
            '1',
            target: 'lavastrello_critical_fire',
            recipient: 'nemico',
            mode: 'immediato',
          ),
        ],
    ],
    minimums: [1, 1, 1],
    maximums: [1, 1, 1],
    cd: [2, 2, 2],
  ),
  'lavastrello_hunter': _newPassive(
    'Cacciatore di Lavastrelli',
    'Subisci metà dei danni inflitti dai Lavastrelli e dalle loro varianti, dopo le normali protezioni.',
    'lavastrello_hunter',
    [50, 50, 50],
  ),
  'lavastrello_nest_intuition': _newPassive(
    'Intuito lavastrellesco',
    '+3 a Percezione e derivati usati per cercare una tana. Se sai che esiste, Cerca tana usa anche Vantaggio. La lettura dell’area con totale superiore a 15 può rivelarla.',
    'lavastrello_nest_intuition',
    [3, 3, 3],
  ),
};
