part of 'monster_book.dart';

final _deadlySinsEntry =
    _canonicalCreature(
      'deadly_sins',
      'DeadlySins',
      '',
      ['diabolico', 'shadow_hell'],
      'taglio',
      [5, 6, 5, 13],
      0,
      'Un Boss guerriero dalla corazza scura, alta e spigolosa, con una sola sottile fessura cremisi sul volto. Due corna di ferro spezzate si piegano in direzioni diverse; cordoni di stoffa cenere sostituiscono il mantello e pendono da un collare di placche chiare. Le mani hanno guanti stretti, non artigli, e una corta lama segnata da tre rune resta agganciata al polso con una catena. È quella lama a mutare fra spada corta, katana e spadone. Il suo passaggio lascia fenditure opache sul terreno. Ha 13 Oculum di base anche al livello zero: può usare soltanto la prima forma di Colpo potenziato fino a raggiungere i livelli delle altre.',
      'La catena che collega il polso alla lama quando cambia forma.',
      ['deadly_strike', 'deadly_empowered', 'deadly_regen', 'deadly_weapon'],
      'catena_deadly_sins',
    ).copyWith(
      isBoss: true,
      encounterRules: {
        'authoredCanonical': true,
        'baseOculum': 13,
        'naturalScrollDrops': {
          'deadly_empowered': {'minimum': 1, 'maximum': 10},
          'deadly_regen': {'minimum': 11, 'maximum': 19},
        },
        'transformingWeaponNatural': 20,
      },
    );

final _deadlySinsTechniques = <String, MonsterConcreteTechnique>{
  'deadly_strike': _canonicalAttack(
    'Fendente della catena',
    'Un colpo della lama controllata dalla catena.',
    'taglio',
    [5, 10, 16],
  ),
  'deadly_empowered': _planarMove(
    'Colpo potenziato',
    'Attiva, Azione o Reazione. Per tre turni gli attacchi base aggiungono Forza nella forma I, due volte Forza nelle forme II/III. Costi confermati 9/13/16 Oculum; cooldown condiviso 9 turni.',
    'taglio',
    'utility',
    [
      for (var f = 1; f <= 3; f++)
        [
          MonsterTechniqueEffect(
            'planar',
            '$f',
            target: 'deadly_empowered',
            duration: '3',
            mode: 'immediato',
          ),
        ],
    ],
    minimums: [9, 13, 16],
    maximums: [9, 13, 16],
    cd: [9, 9, 9],
  ),
  'deadly_regen': _planarMove(
    'Regen del DeadlySins',
    'Una tua Azione, nessun costo statistico, CD 4 turni. Tira Resistenza: con tiro positivo recupera metà della Vita realmente persa nell’ultimo attacco ricevuto, con critico positivo O negativo recupera tutta quella perdita. Non recupera Scudi o HP temporanei; lo stesso attacco non può essere recuperato due volte.',
    'vita',
    'cura',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '1',
            target: 'deadly_regen',
            mode: 'immediato',
          ),
        ],
    ],
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cd: [4, 4, 4],
  ),
  'deadly_weapon': _planarMove(
    'DeadlySins · forma dell’arma',
    'I Spada corta: +6 ai tiri per colpire, +3 Difesa. II Katana: ogni attacco eseguito, anche schivato, aggiunge +1 Danno; a fine sessione un terzo del guadagno diventa permanente, per difetto. III Spadone: ogni colpo riuscito scatena un’onda che può colpire fino a dieci nemici vicini, con danno crescente secondo quanti ne colpisce. Cambio forma: 1 Oculum, CD condiviso 1 turno. Le tre forme sono modi dell’arma, non evoluzioni di potenza. Dopo nove Riposi Lunghi con uso effettivo l’arma si adatta al portatore e ottiene +3 Danni.',
    'taglio',
    'utility',
    [
      for (var f = 1; f <= 3; f++)
        [
          MonsterTechniqueEffect(
            'planar',
            '$f',
            target: 'deadly_weapon',
            mode: 'immediato',
          ),
        ],
    ],
    minimums: [1, 1, 1],
    maximums: [1, 1, 1],
    cd: [1, 1, 1],
  ),
};
