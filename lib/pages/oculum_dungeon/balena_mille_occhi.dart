part of 'monster_book.dart';

const oculumBalenaMilleOcchiId = 'balena_dai_mille_occhi';
const oculumBalenaRaySkillId = 'balena_raggio_acqua_compressa';
const oculumBalenaEyesSkillId = 'balena_occhi_della_balena';
const oculumBalenaTeleportSkillId = 'balena_teletrasporto_ad_acqua';
const oculumBalenaRayBaseDamage = 30;
const oculumBalenaRayDamagePerTurn = 30;
const oculumBalenaRayMaximumTurns = 5;
const oculumBalenaRayBaseRange = 18;
const oculumBalenaRayFocusedRange = 27;

final _balenaMilleOcchiEntries = <MonsterBookEntry>[
  MonsterBookEntry(
    id: oculumBalenaMilleOcchiId,
    nameIt: 'Balena Dai Mille Occhi',
    nameEn: 'Thousand-Eyed Whale',
    descIt:
        'Cetaceo enorme dalla pelle verde ardesia, con venti occhi rossi in pieghe irregolari, due pinne pettorali, una pinna dorsale e una coda bilobata. Caccia nel Regno Sommerso e può scomparire in un portale d’acqua. Tutti dimenticano le vittime uccise dalla Balena, mentre le schede e la cronologia della campagna rimangono consultabili.',
    descEn:
        'An enormous slate-green whale with twenty red eyes, two pectoral fins, a dorsal fin and a forked tail. It hunts in the Sunken Realm and can disappear through a water portal. Everyone forgets those it kills, while character sheets and campaign history remain available.',
    elementId: 'acqua',
    planeIds: const ['affogato'],
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: const {
      'level': 12,
      'grade': 1,
      'resilienza': 14,
      'volonta': 11,
      'materia': 10,
      'oculum': 16,
      'criticalShield': 1,
    },
    weakPointIt: 'Gli occhi scoperti nelle pieghe ai lati del capo.',
    weakPointEn: 'The uncovered eyes in the folds along its head.',
    skillIds: const [oculumBalenaRaySkillId, oculumBalenaEyesSkillId],
    encounterRules: {
      'authoredCanonical': true,
      'generationSide': 'enemy',
      'dispositions': const ['ostile'],
      'criticalShields': 1,
      'oculumDodges': 1,
      'signatureSkillId': oculumBalenaRaySkillId,
      'precisionBodyParts': [
        const {'id': 'body', 'group': 'body', 'label': 'Corpo'},
        const {'id': 'head', 'group': 'head', 'label': 'Testa'},
        for (var i = 0; i < 20; i++)
          {
            'id': 'eyes_${i + 1}',
            'group': 'eyes',
            'label': 'Occhio ${i < 10 ? 'destro' : 'sinistro'} ${i % 10 + 1}',
            'side': i < 10 ? 'right' : 'left',
            'sideIndex': i % 10 + 1,
            'weak': true,
          },
        const {
          'id': 'pectoral_fin_right',
          'group': 'fins',
          'label': 'Pinna pettorale destra',
          'side': 'right',
        },
        const {
          'id': 'pectoral_fin_left',
          'group': 'fins',
          'label': 'Pinna pettorale sinistra',
          'side': 'left',
        },
        const {'id': 'dorsal_fin', 'group': 'fins', 'label': 'Pinna dorsale'},
        const {'id': 'tail', 'group': 'tail', 'label': 'Coda bilobata'},
      ],
    },
  ),
];

const _balenaMilleOcchiTechniques = <String, MonsterConcreteTechnique>{
  oculumBalenaRaySkillId: MonsterConcreteTechnique(
    name: 'Raggio d’Acqua Compressa',
    action:
        'Scaglia un sottilissimo raggio perforante d’Acqua da una parte del corpo. Gittata 18 m, 27 m in Concentrazione. +30 Danni iniziali e +30 per turno completo di Concentrazione, fino a cinque turni.',
    element: 'acqua',
    kind: 'attacco',
    requiredLevel: 0,
    minimums: [3, 3, 3],
    maximums: [3, 3, 3],
    cooldownValues: [0, 0, 0],
    forms: [
      [MonsterTechniqueEffect('danno', '30', mode: 'prossima_azione', duration: '')],
      [MonsterTechniqueEffect('danno', '30', mode: 'prossima_azione', duration: '')],
      [MonsterTechniqueEffect('danno', '30', mode: 'prossima_azione', duration: '')],
    ],
  ),
  oculumBalenaEyesSkillId: MonsterConcreteTechnique(
    name: 'Occhi della Balena',
    action: 'Apri gli occhi sul volto per un’Azione e ottieni +12% Danni e Difesa.',
    element: 'acqua',
    kind: 'buff',
    requiredLevel: 0,
    minimums: [5, 5, 5],
    maximums: [5, 5, 5],
    cooldownValues: [0, 0, 0],
    forms: [
      _balenaEyesEffects,
      _balenaEyesEffects,
      _balenaEyesEffects,
    ],
  ),
  oculumBalenaTeleportSkillId: MonsterConcreteTechnique(
    name: 'Teletrasporto ad Acqua',
    action:
        'A contatto con l’acqua ti sposti verso un altro punto d’acqua visibile. Per schivare, sommi al tiro metà del valore più alto fra Riflessi e Canalizzazione.',
    element: 'acqua',
    kind: 'movimento',
    requiredLevel: 0,
    minimums: [6, 6, 6],
    maximums: [6, 6, 6],
    cooldownValues: [0, 0, 0],
    forms: [_balenaTeleportEffects, _balenaTeleportEffects, _balenaTeleportEffects],
  ),
};

const _balenaEyesEffects = <MonsterTechniqueEffect>[
  MonsterTechniqueEffect('danno_percentuale', '12', mode: 'prossima_azione', duration: ''),
  MonsterTechniqueEffect('difesa_percentuale', '12', target: 'difesa_percentuale', mode: 'prossima_azione', duration: ''),
];

const _balenaTeleportEffects = <MonsterTechniqueEffect>[
  MonsterTechniqueEffect('planar', '1', target: 'balena_water_teleport'),
];
