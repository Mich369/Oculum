part of 'monster_book.dart';

final _swordPuppetEntry = _canonicalCreature(
  'manichino_spada',
  'Manichino della Spada',
  '',
  ['morti', 'mezzano'],
  'taglio',
  [5, 5, 7, 6],
  4,
  _originalFaunaDescriptions['manichino_spada']!,
  'L’occhio nella guardia della spada che controlla il cadavere.',
  ['sword_puppet_slash', 'sword_puppet_guard', 'sword_puppet_full'],
  'guardia_occhio_manichino',
);
final _laerTurretEntries = <MonsterBookEntry>[
  _swordPuppetEntry,
  _swordPuppetEntry.copyWith(
    id: 'manichino_baghest',
    nameIt: 'Manichino di Baghest',
    descIt:
        'Un cadavere mosso da una lama senziente, coperto da un cappotto blu ardesia con spalle chiuse. Una maschera lignea senza bocca nasconde il volto. Due gambe e due braccia: la lama è nel braccio destro e un solo occhio rosso è incastonato nella sua guardia; il sinistro termina in una mano. È già succube di Baghest tramite Corruzione Rossa dopo tre Notti. Conserva Tagli rapidi, Difesa aumentata e Spada al 100%. Purificato con una Pietra anti-corruzione cade a terra e diventa lentamente parte del terreno, senza contare come uccisione.',
    encounterRules: {
      ..._swordPuppetEntry.encounterRules,
      'canonicalVariantOf': 'manichino_spada',
      'initialCorruptionKind': 'rossa',
      'initialCorruptionNights': 3,
      'purificationKind': 'baghest_stone',
    },
  ),
  _canonicalCreature(
    'laer',
    'Laer',
    '',
    ['morti', 'mezzano'],
    'taglio',
    [5, 7, 6, 4],
    5,
    'Uno spadaccino prodigio dalla figura alta e sottile, chiuso in un’armatura antica di metallo scuro con bordi e incisioni dorate. L’elmo cela il volto dietro una maschera rigida dai denti scolpiti; ciocche chiare sfuggono dietro il collo. Spallacci a piastre, guanti articolati e schinieri appuntiti accompagnano un lungo drappo rosso scuro consumato. Le punte ornamentali si prolungano dietro le spalle. Impugna una spada lunga e stretta, intarsiata d’oro. Sa piegarsi e contorcersi con precisione innaturale: +15 Riflessi. Il suo tiro Spada usa metà Volontà per difetto +10, e il totale del tiro aumenta i Danni. Il +10 è la sua maestria, non un bonus copiato automaticamente dall’arma.',
    'Le giunture dell’armatura durante una torsione.',
    ['laer_sword', 'laer_twist'],
    'acciaio_laer',
  ),
  _canonicalCreature(
    'torretta_oculum',
    'Torretta Oculum',
    '',
    ['postea', 'sotterraneo_maggiore'],
    'oculum',
    [3, 3, 6, 6],
    3,
    'Una torretta sospesa, composta da frammenti irregolari di pietra scura che ruotano lentamente attorno a un nucleo luminoso. Una scheggia appuntita forma la base e due grandi placche aperte proteggono il centro senza chiuderlo. L’energia tiene unite le parti e cade in filamenti sottili verso il suolo. Il nucleo assume sempre il colore dell’elemento della torretta: viola per Oculum, rosso per Fuoco, azzurro per Gelo e così via. Non ha occhi o bocca. Il nucleo esposto è sempre il punto debole. La mira guidata concede +9 al tiro per colpire, ma la struttura rigida impone −9 alla CM.',
    'Nucleo centrale, del colore del suo elemento.',
    ['turret_ray', 'turret_pulse'],
    'scheggia_torretta_oculum',
  ),
];
final _laerTurretTechniques = <String, MonsterConcreteTechnique>{
  'sword_puppet_slash': _planarMove(
    'Tagli rapidi',
    'La spada muove il corpo in un fendente rapidissimo: +8/14/21 Danni Taglio e +2/3/4 al tiro. Un attacco, un bersaglio.',
    'taglio',
    'danno',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${[8, 14, 21][f]}',
            mode: 'prossima_azione',
            duration: '',
          ),
          MonsterTechniqueEffect(
            'planar',
            '${f + 2}',
            target: 'puppet_attack_bonus',
            mode: 'immediato',
          ),
        ],
    ],
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [2, 2, 2],
  ),
  'sword_puppet_guard': _planarMove(
    'Difesa aumentata',
    'La spada incrocia le placche del cadavere: +6/10/15 Difesa per due turni.',
    'osso',
    'difesa',
    [
      for (final n in [6, 10, 15])
        [MonsterTechniqueEffect('difesa', '$n', duration: '2')],
    ],
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [3, 3, 3],
  ),
  'sword_puppet_full': _planarMove(
    'Spada al 100%',
    'Per tre turni: +20% Danni/Difesa, +3 alle quattro statistiche e +4 Riflessi. Nessuna cura automatica della Vita corrente; una riattivazione rinnova senza sommare gli stessi bonus.',
    'taglio',
    'utility',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'danno_percentuale',
            '20',
            target: 'danni_percentuale',
            duration: '3',
          ),
          const MonsterTechniqueEffect(
            'difesa_percentuale',
            '20',
            target: 'difesa_percentuale',
            duration: '3',
          ),
          for (final stat in ['resilienza', 'volonta', 'materia', 'oculum'])
            MonsterTechniqueEffect(
              'modifica_statistica',
              '3',
              target: stat,
              duration: '3',
            ),
          const MonsterTechniqueEffect(
            'modifica_sottotratto',
            '4',
            target: 'riflessi',
            duration: '3',
          ),
        ],
    ],
    minimums: [3, 4, 5],
    maximums: [3, 4, 5],
    cd: [6, 6, 6],
  ),
  'laer_sword': _planarMove(
    'Spada di Laer',
    'Tiro Spada: 1d20 + metà Volontà per difetto; Laer aggiunge anche +10 di maestria. Il totale si somma ai Danni del colpo. Un bersaglio e normali protezioni.',
    'taglio',
    'danno',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '1',
            target: 'laer_sword',
            mode: 'immediato',
          ),
        ],
    ],
    costResource: 'volonta',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [2, 2, 2],
  ),
  'laer_twist': _planarMove(
    'Torsione del prodigio',
    'Laer piega il corpo sotto la lama nemica: +4/6/8 al prossimo tiro di Difesa. La sua agilità innata +15 Riflessi resta separata.',
    'fisico',
    'difesa',
    [
      for (final n in [4, 6, 8])
        [
          MonsterTechniqueEffect(
            'planar',
            '$n',
            target: 'laer_twist',
            mode: 'immediato',
          ),
        ],
    ],
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [3, 3, 3],
  ),
  'turret_ray': _canonicalAttack(
    'Raggio del nucleo',
    'Il nucleo orienta un raggio verso un solo bersaglio. Il danno segue l’elemento della torretta.',
    'oculum',
    [7, 12, 18],
  ),
  'turret_pulse': _planarMove(
    'Impulso difensivo',
    'Le placche si stringono: +10/18/28 Scudo.',
    'oculum',
    'difesa',
    [
      for (final n in [10, 18, 28])
        [MonsterTechniqueEffect('scudo', '$n', mode: 'immediato')],
    ],
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [3, 3, 3],
  ),
};
