part of 'monster_book.dart';

const _frutibushCandidates = <(String, String, String, String, String)>[
  (
    'frutibush_polline',
    'Polline vigile',
    'supporto',
    'modifica_statistica',
    'iniziativa',
  ),
  ('frutibush_corteccia', 'Corteccia condivisa', 'difesa', 'scudo', 'scudo'),
  (
    'frutibush_linfa',
    'Linfa coraggiosa',
    'supporto',
    'modifica_statistica',
    'volonta',
  ),
  (
    'frutibush_tralcio',
    'Tralcio d’appiglio',
    'movimento',
    'velocita',
    'movimento',
  ),
  ('frutibush_riparo', 'Foglie di riparo', 'difesa', 'difesa', 'difesa'),
  ('frutibush_radici', 'Radici avvolgenti', 'controllo', 'stato', 'rallentato'),
  ('frutibush_semi', 'Semi pungenti', 'attacco', 'danno', 'danni'),
];

final _frutibushMonster = MonsterBookEntry(
  id: oculumFrutibushId,
  nameIt: 'Frutibush',
  nameEn: 'Frutibush',
  descIt:
      'Ciuffo volante di filamenti d’erba, circondato da foglie appuntite. Conserva il volo anche se viene colpito alla piega del corpo. Usa la propria vegetazione per curare, difendere e sostenere più compagni.',
  descEn:
      'A flying tuft of grass filaments surrounded by sharp leaves. Damage to the body fold does not ground it. It uses its growth to heal, protect and aid several companions.',
  elementId: 'natura',
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: false,
  isNullFateless: false,
  encounterRules: const {
    'authoredCanonical': true,
    'naturalFlight': true,
    'authoredSkillPool': true,
    'fixedSkillIds': [oculumFrutibushHealSkill, oculumFrutibushLeafSkill],
  },
  stats: const {
    'level': 0,
    'resilienza': 7,
    'volonta': 5,
    'materia': 5,
    'oculum': 6,
  },
  skillIds: [
    oculumFrutibushHealSkill,
    oculumFrutibushLeafSkill,
    for (final candidate in _frutibushCandidates) candidate.$1,
  ],
);

final _frutibushTechniques = <String, MonsterConcreteTechnique>{
  oculumFrutibushHealSkill: MonsterConcreteTechnique(
    name: 'Cura',
    action: 'Cura gli alleati scelti con la linfa',
    element: 'natura',
    kind: 'cura',
    requiredLevel: 0,
    minimums: const [2, 3, 4],
    maximums: const [2, 3, 4],
    cooldownValues: const [3, 3, 4],
    forms: [
      for (var form = 1; form <= 3; form++)
        [
          MonsterTechniqueEffect(
            'cura',
            '${form * 6}',
            recipient: 'alleato',
            maximumTargets: form + 1,
          ),
        ],
    ],
  ),
  oculumFrutibushLeafSkill: MonsterConcreteTechnique(
    name: 'Foglie Lama',
    action:
        'Distribuisci le foglie fra i nemici, anche concentrandole su uno. '
        'Dividi Danni totali più il maggiore fra 5 e 25 × Grado fra le foglie. '
        'Aggiungi 10 Danni una sola volta per nemico distinto. Distribuzione in preparazione',
    element: 'natura',
    kind: 'attacco',
    requiredLevel: 0,
    minimums: const [2, 4, 7],
    maximums: const [2, 4, 7],
    cooldownValues: const [3, 3, 4],
    forms: [
      for (final cap in oculumFrutibushLeafCaps)
        [
          MonsterTechniqueEffect(
            'planar',
            '$cap',
            target: oculumFrutibushLeafSkill,
            mode: 'prossima_azione',
            recipient: 'nemico',
            maximumTargets: cap,
          ),
        ],
    ],
  ),
  for (final candidate in _frutibushCandidates)
    candidate.$1: _frutibushCandidate(candidate),
};

MonsterConcreteTechnique _frutibushCandidate(
  (String, String, String, String, String) candidate,
) {
  final (_, name, kind, type, target) = candidate;
  final offensive = kind == 'attacco' || kind == 'controllo';
  final pointsPerForm = switch (type) {
    'scudo' => 5,
    'danno' => 4,
    'difesa' || 'velocita' => 2,
    _ => 1,
  };
  return MonsterConcreteTechnique(
    name: name,
    action: offensive
        ? 'Scegli più nemici'
        : 'Scegli più alleati per il supporto di Natura',
    element: 'natura',
    kind: kind,
    requiredLevel: 0,
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
    cooldownValues: const [2, 3, 4],
    forms: [
      for (var form = 1; form <= 3; form++)
        [
          MonsterTechniqueEffect(
            type,
            '${type == 'stato' ? 1 : form * pointsPerForm}',
            target: target,
            mode: type == 'danno' || type == 'stato'
                ? 'prossima_azione'
                : 'temporaneo',
            recipient: offensive ? 'nemico' : 'alleato',
            maximumTargets: form + 1,
          ),
        ],
    ],
  );
}
