part of '../../main.dart';

/// A fully saved starting choice. The four core bonuses are applied when the
/// tutorial is confirmed; the prose is also retained on the generated title
/// or racial trait so the Master can always inspect its origin.
class OculumStarterChoice {
  const OculumStarterChoice({
    required this.id,
    required this.nome,
    required this.descrizione,
    this.resilienza = 0,
    this.volonta = 0,
    this.materia = 0,
    this.oculum = 0,
    this.obser = 0,
    this.puntoCieco = '',
    this.conMaster = false,
  });

  final String id;
  final String nome;
  final String descrizione;
  final int resilienza;
  final int volonta;
  final int materia;
  final int oculum;
  final int obser;
  final String puntoCieco;
  final bool conMaster;
}

/// Initial experience is deliberately unpredictable but never exceeds the
/// creation cap requested for a new sheet.
int oculumStarterInitialExperience(Random random) => random.nextInt(121);

int oculumStarterMartialBonus(Random random) => random.nextInt(10) + 3;

/// Ogni creatura cresce con il suo rango: Mostro 9, Mini-Boss 12 e Boss 18
/// punti statistica liberamente distribuibili per livello.
int oculumMonsterStatPointsPerLevel(String type) {
  final normalized = type.toLowerCase();
  if (normalized.contains('mini') && normalized.contains('boss')) return 12;
  if (normalized.contains('boss')) return 18;
  return 9;
}

/// Il contatore di creazione usa solo le quattro statistiche reali del
/// mostro: ogni livello vale il suo rango e ogni grado aggiunge 10×grado.
int oculumMonsterMissingStatPoints({
  required String type,
  required int level,
  required int grade,
  required int resilienza,
  required int volonta,
  required int materia,
  required int oculum,
}) {
  final required =
      max(0, level) * oculumMonsterStatPointsPerLevel(type) +
      max(0, grade) * 10;
  final assigned =
      max(0, resilienza) + max(0, volonta) + max(0, materia) + max(0, oculum);
  return max(0, required - assigned).toInt();
}

/// Punti che il creatore può assegnare liberamente oltre alla distribuzione
/// umanoide 3/2/1/1. I mostri ricevono nove punti per livello e dieci per
/// grado: un Mostro livello 10, grado I, parte quindi da 100 punti liberi.
int oculumStarterFreeStatPoints({
  required bool monster,
  required int level,
  required int grade,
}) {
  final safeLevel = max(0, level);
  final safeGrade = max(0, grade);
  return (monster ? safeLevel * 9 : safeLevel) + safeGrade * 10;
}

CharacterArt oculumStarterMartialArt(CharacterArt art, String resource) {
  for (final skill in art.skills) {
    skill.oculumMinimiPerLivello = <int>[1, 4, 7, 0, 0];
    skill.oculumMassimiPerLivello = <int>[3, 6, 9, 0, 0];
    skill.oculumMassimiInizialiPerLivello = <int>[3, 6, 9, 0, 0];
    skill.risorseCostoPerLivello = <String>[
      resource,
      resource,
      resource,
      '',
      '',
    ];
    skill.costoOculumDisabilitatoPerLivello = <bool>[
      true,
      true,
      true,
      false,
      false,
    ];
  }
  return art;
}

const List<OculumStarterChoice> oculumStarterBackgrounds = [
  OculumStarterChoice(
    id: 'contatto_naturale',
    nome: 'Nato tra le Radici',
    descrizione:
        'Contatto naturale: +1 Percezione, +1 RES, +2 Sopravvivenza, +1 Adattamento.',
    resilienza: 1,
    puntoCieco:
        'Non sai bene come conversare con chi vive lontano dalla natura.',
  ),
  OculumStarterChoice(
    id: 'povero_citta',
    nome: 'Figlio dei Vicoli',
    descrizione:
        'Povero di città: 1d4 Obser, +2 Velo, +1 VOL, +1 MAT, +2 Adattamento.',
    volonta: 1,
    materia: 1,
    obser: 2,
    puntoCieco: 'Per molti sarai sempre un lurido scarafaggio.',
  ),
  OculumStarterChoice(
    id: 'benestante',
    nome: 'Erede delle Torri',
    descrizione:
        'Benestante: 1d50+20 Obser, +1 Oculum, +1 Sopravvivenza, +1 RES.',
    resilienza: 1,
    oculum: 1,
    obser: 45,
    puntoCieco: 'Non puoi mentire.',
  ),
  OculumStarterChoice(
    id: 'umano_postea',
    nome: 'Umano di Postea',
    descrizione:
        'Figlio di Postea: +2 RES, +2 VOL, +2 MAT; il sangue umano è stato temprato dalle rovine.',
    resilienza: 2,
    volonta: 2,
    materia: 2,
    puntoCieco: 'Non riesci a ignorare chi viene lasciato indietro.',
  ),
  OculumStarterChoice(
    id: 'bocciolo_angelico',
    nome: 'Bocciolo Angelico',
    descrizione:
        'Una promessa di ali: +1 RES, +1 VOL e una sensibilità innata agli echi.',
    resilienza: 1,
    volonta: 1,
    puntoCieco: 'Le richieste di aiuto ti feriscono più di quanto ammetti.',
  ),
  OculumStarterChoice(
    id: 'crea_master',
    nome: 'Crea con il Master',
    descrizione:
        'Nessun bonus automatico: definisci passato e punto cieco al tavolo.',
    conMaster: true,
  ),
];

const List<OculumStarterChoice> oculumStarterRaces = [
  OculumStarterChoice(
    id: 'demone_maggiore',
    nome: 'Demone Maggiore',
    descrizione:
        'Intelletto demoniaco: +3 punti alle statistiche, +5 Difesa Fuoco.',
    resilienza: 1,
    volonta: 1,
    materia: 1,
  ),
  OculumStarterChoice(
    id: 'angelo',
    nome: 'Angelo',
    descrizione:
        'Ali grandi, percorse da occhi: puoi planare; con un tiro Echo positivo puoi volare. +2 statistiche, +3 Fortuna.',
    resilienza: 1,
    volonta: 1,
  ),
  OculumStarterChoice(
    id: 'mhunan',
    nome: 'Mhuman',
    descrizione: 'Umano della luna: visione al buio, +1 statistica, +2 Velo.',
    materia: 1,
  ),
  OculumStarterChoice(
    id: 'ceneride',
    nome: 'Ceneride',
    descrizione:
        'Nato dalla cenere: +1 RES, resiste al calore e lascia poche tracce.',
    resilienza: 1,
  ),
  OculumStarterChoice(
    id: 'silvano_rovine',
    nome: 'Silvano delle Rovine',
    descrizione:
        'Occhi del bosco spezzato: +1 MAT, riconosci sentieri e piante ostili.',
    materia: 1,
  ),
  OculumStarterChoice(
    id: 'crea_master',
    nome: 'Crea con il Master',
    descrizione:
        'Razza, sottorazza e tratti vengono fissati insieme al Master.',
    conMaster: true,
  ),
];

const List<OculumStarterChoice> oculumStarterFateTitles = [
  OculumStarterChoice(
    id: 'vendetta',
    nome: 'Vendetta',
    descrizione:
        '+1 VOL: quando insegui chi ti ha ferito, non arretri facilmente.',
    volonta: 1,
  ),
  OculumStarterChoice(
    id: 'odio',
    nome: 'Odio',
    descrizione: '+1 MAT: il rancore rende il tuo corpo difficile da spezzare.',
    materia: 1,
  ),
  OculumStarterChoice(
    id: 'amore',
    nome: 'Amore',
    descrizione: '+1 RES: proteggere qualcuno ti mantiene in piedi.',
    resilienza: 1,
  ),
  OculumStarterChoice(
    id: 'avventura',
    nome: 'Avventura',
    descrizione: '+1 Oculum: l’ignoto chiama il tuo Occhio.',
    oculum: 1,
  ),
  OculumStarterChoice(
    id: 'grandezza',
    nome: 'Grandezza',
    descrizione: '+1 RES e +1 VOL: pretendi di superare i limiti.',
    resilienza: 1,
    volonta: 1,
  ),
  OculumStarterChoice(
    id: 'crea_master',
    nome: 'Crea con il Master',
    descrizione: 'Il Fato verrà scritto durante la prima sessione.',
    conMaster: true,
  ),
];

List<CharacterArt> oculumStarterArtChoices() => [
  oculumStarterWaterArt(),
  oculumStarterRockArt(),
  oculumStarterMartialArt(
    CharacterArt(
      nome: 'Zanna del Drago',
      tipo: 'Martial Art',
      descrizione: 'Palmi, respiro e fiamma disciplinata.',
      skills: [
        ArtSkill(
          nome: 'Morso di Brace',
          livello: 1,
          evo1:
              'I — Con 18 naturale crei una bocca di fiamme: +20 danni (1–3 VOL).',
          evo2: 'II — Richiede 15 naturale: +20 danni (4–6 VOL).',
          evo3: 'III — Richiede 12 naturale: +60 danni e bruciatura (7–9 VOL).',
        ),
        ArtSkill(
          nome: 'Passo del Wyrm',
          livello: 1,
          evo1: 'I — Avanzi senza reazioni (1–3 VOL).',
          evo2: 'II — Colpisci con +20 danni dopo il passo (4–6 VOL).',
          evo3: 'III — Attraversi una linea di nemici: +60 danni (7–9 VOL).',
        ),
        ArtSkill(
          nome: 'Ruggito dei Palmi',
          livello: 1,
          evo1: 'I — Spingi un bersaglio (1–3 VOL).',
          evo2: 'II — +20 danni e sbilanciamento (4–6 VOL).',
          evo3: 'III — Onda ardente da +60 danni in area breve (7–9 VOL).',
        ),
      ],
    ),
    'materia',
  ),
  oculumStarterMartialArt(
    CharacterArt(
      nome: 'Berserk',
      tipo: 'Martial Art',
      descrizione: 'Furia controllata e colpi che spezzano la guardia.',
      skills: [
        ArtSkill(
          nome: 'Furia Vincolata',
          livello: 1,
          evo1:
              'I — Consumi 2 VOL a turno: +10 VOL temporanea; ogni punto speso aggiunge +2 danni.',
          evo2: 'II — +20 danni mentre la furia resta attiva (4–6 VOL).',
          evo3: 'III — +60 danni e non puoi essere sbilanciato (7–9 VOL).',
        ),
        ArtSkill(
          nome: 'Spalla dell’Orso',
          livello: 1,
          evo1: 'I — Carica e spinta (1–3 VOL).',
          evo2: 'II — +20 danni e rompi la guardia (4–6 VOL).',
          evo3: 'III — +60 danni, travolgi fino a due bersagli (7–9 VOL).',
        ),
        ArtSkill(
          nome: 'Ultimo Ruggito',
          livello: 1,
          evo1: 'I — Ignori un dolore per un turno (1–3 VOL).',
          evo2: 'II — Contrattacco da +20 danni (4–6 VOL).',
          evo3:
              'III — Contrattacco da +60 danni e recuperi posizione (7–9 VOL).',
        ),
      ],
    ),
    'volonta',
  ),
];

/// Starter Arts used by the guided character creation. Costs are real per-form
/// Oculum bounds, while the prose remains visible in the normal Art editor.
CharacterArt oculumStarterWaterArt() => CharacterArt(
  nome: 'Oculum Art Acquatica',
  tipo: 'Oculum Art',
  descrizione:
      'L’Oculum prende la forma dell’acqua: pressione, prigione e caccia.',
  skills: [
    ArtSkill(
      nome: 'Getto Distruttivo',
      livello: 1,
      evo1: 'I — Supera lo Scudo: +25% danni Oculum (costo 1–4 Oculum).',
      evo2:
          'II — Supera lo Scudo: +20 danni + danni Oculum (costo 5–10 Oculum).',
      evo3: 'III — Supera Scudo e Difesa: +100 danni (costo 11–60 Oculum).',
      oculumMinimiPerLivello: [1, 5, 11],
      oculumMassimiPerLivello: [4, 10, 60],
      effettiPerLivello: [
        [
          OculumStructuredEffect(
            type: 'danno',
            valueExpression: 'oculum*25%',
            bypassShields: true,
            elementType: 'Acqua',
          ),
        ],
        [
          OculumStructuredEffect(
            type: 'danno',
            valueExpression: '20+oculum',
            bypassShields: true,
            elementType: 'Acqua',
          ),
        ],
        [
          OculumStructuredEffect(
            type: 'danno',
            valueExpression: '100',
            bypassShields: true,
            bypassDefense: true,
            elementType: 'Acqua',
          ),
        ],
      ],
    ),
    ArtSkill(
      nome: 'Raggio Segugio',
      livello: 1,
      evo1:
          'I — Tre raggi d’acqua infliggono metà dei tuoi danni; un tiro con +3 VC (2 Oculum).',
      evo2: 'II — Il tiro riceve +6 VC (3 Oculum).',
      evo3: 'III — Il tiro riceve +9 VC (5 Oculum).',
      oculumMinimiPerLivello: [2, 3, 5],
      oculumMassimiPerLivello: [2, 3, 5],
      effettiPerLivello: [
        [
          for (var raggio = 0; raggio < 3; raggio++)
            OculumStructuredEffect(
              type: 'danno',
              valueExpression: 'danni*50%',
              elementType: 'Acqua',
              customDisplayText:
                  'Raggio ${raggio + 1}/3: metà dei danni; tiro VC +3',
            ),
        ],
        [
          for (var raggio = 0; raggio < 3; raggio++)
            OculumStructuredEffect(
              type: 'danno',
              valueExpression: 'danni*50%',
              elementType: 'Acqua',
              customDisplayText:
                  'Raggio ${raggio + 1}/3: metà dei danni; tiro VC +6',
            ),
        ],
        [
          for (var raggio = 0; raggio < 3; raggio++)
            OculumStructuredEffect(
              type: 'danno',
              valueExpression: 'danni*50%',
              elementType: 'Acqua',
              customDisplayText:
                  'Raggio ${raggio + 1}/3: metà dei danni; tiro VC +9',
            ),
        ],
      ],
    ),
    ArtSkill(
      nome: 'Bolla Magica',
      livello: 1,
      evo1:
          'I — Imprigioni una creatura: deve superare il tuo tiro Manifestazione del Potere (1 Oculum).',
      evo2:
          'II — +3 + Oculum a Manifestazione; puoi creare due bolle (2–3 Oculum).',
      evo3:
          'III — +6 + Oculum; puoi intrappolare creature Oculum (4–20 Oculum).',
      oculumMinimiPerLivello: [1, 2, 4],
      oculumMassimiPerLivello: [1, 3, 20],
      effettiPerLivello: [
        [
          OculumStructuredEffect(
            type: 'stato',
            appliedState: 'Intrappolato nella Bolla Magica',
            duration: '1',
            narrativeText:
                'La creatura deve superare la Manifestazione del Potere.',
          ),
        ],
        [
          OculumStructuredEffect(
            type: 'stato',
            appliedState: 'Intrappolato nella Bolla Magica',
            duration: '1',
            customDisplayText: 'Due bolle; Manifestazione +3 + Oculum',
          ),
        ],
        [
          OculumStructuredEffect(
            type: 'stato',
            appliedState: 'Intrappolato nella Bolla Magica Oculum',
            duration: '1',
            customDisplayText:
                'Può intrappolare creature Oculum; Manifestazione +6 + Oculum',
          ),
        ],
      ],
    ),
  ],
);

CharacterArt oculumStarterRockArt() => CharacterArt(
  nome: 'Oculum Art Rocciosa',
  tipo: 'Oculum Art',
  descrizione: 'L’Oculum condensa pietra: mura, caccia sotterranea e fratture.',
  skills: [
    ArtSkill(
      nome: 'Muro Roccioso',
      livello: 1,
      evo1: 'I — Crei un muro che resiste a 10 danni (1 Oculum).',
      evo2: 'II — Muro da 35 + Oculum×2 danni (2–5 Oculum).',
      evo3: 'III — Muro da 100 + Oculum×2,5 danni (6–30 Oculum).',
      oculumMinimiPerLivello: [1, 2, 6],
      oculumMassimiPerLivello: [1, 5, 30],
      effettiPerLivello: [
        [
          OculumStructuredEffect(
            type: 'scudo',
            valueExpression: '10',
            customDisplayText: 'Muro roccioso: assorbe 10 danni',
          ),
        ],
        [
          OculumStructuredEffect(
            type: 'scudo',
            valueExpression: '35+oculum*2',
            customDisplayText: 'Muro roccioso: assorbe 35 + Oculum×2 danni',
          ),
        ],
        [
          OculumStructuredEffect(
            type: 'scudo',
            valueExpression: '100+oculum*2.5',
            customDisplayText: 'Muro roccioso: assorbe 100 + Oculum×2,5 danni',
          ),
        ],
      ],
    ),
    ArtSkill(
      nome: 'Spuntoni Rocciosi',
      livello: 1,
      evo1:
          'I — Spuntoni seguono il nemico per 10 metri e ti danno vantaggio (1 Oculum).',
      evo2: 'II — +20 danni e il bersaglio resta ostacolato (4–6 Oculum).',
      evo3:
          'III — +50 danni, due bersagli e terreno spezzato per 2 turni (7–9 Oculum).',
      oculumMinimiPerLivello: [1, 4, 7],
      oculumMassimiPerLivello: [1, 6, 9],
      effettiPerLivello: [
        [
          OculumStructuredEffect(
            type: 'stato',
            appliedState: 'Spuntoni Rocciosi: vantaggio',
            duration: '1',
          ),
        ],
        [
          OculumStructuredEffect(
            type: 'danno',
            valueExpression: '20',
            elementType: 'Roccia',
            customDisplayText: '+20 danni; bersaglio ostacolato',
          ),
        ],
        [
          OculumStructuredEffect(
            type: 'danno',
            valueExpression: '50',
            elementType: 'Roccia',
            customDisplayText: '+50 danni; due bersagli e terreno spezzato',
          ),
        ],
      ],
    ),
    ArtSkill(
      nome: 'Frana del Bastione',
      livello: 1,
      evo1: 'I — Sollevi detriti: +10 danni e copertura leggera (1–3 Oculum).',
      evo2: 'II — +20 danni e il bersaglio perde Velo (4–6 Oculum).',
      evo3:
          'III — Crollo da +50 danni ad area breve; chi fallisce resta bloccato per un turno (7–9 Oculum).',
      oculumMinimiPerLivello: [1, 4, 7],
      oculumMassimiPerLivello: [3, 6, 9],
      effettiPerLivello: [
        [
          OculumStructuredEffect(
            type: 'danno',
            valueExpression: '10',
            elementType: 'Roccia',
          ),
        ],
        [
          OculumStructuredEffect(
            type: 'danno',
            valueExpression: '20',
            elementType: 'Roccia',
          ),
        ],
        [
          OculumStructuredEffect(
            type: 'danno',
            valueExpression: '50',
            elementType: 'Roccia',
          ),
        ],
      ],
    ),
  ],
);
