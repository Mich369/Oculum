part of 'monster_book.dart';

List<MonsterBookEntry> get _confirmedInkEntries {
  final armadillo = _armadilloCreatureEntries.firstWhere(
    (entry) => entry.id == 'armadillo_corazzato',
  );
  final construct = _octoberCreatureEntries.firstWhere(
    (entry) => entry.id == 'costrutto_minore',
  );
  final bell = _manualMonsterBookEntries.firstWhere(
    (entry) => entry.id == 'mosca_campana',
  );
  final larva = _weakHorrorMonsterBookEntries.firstWhere(
    (entry) => entry.id == 'weak_horror_larva',
  );
  return [
    _inkVariant(
      armadillo,
      suffix: 'placche_scolpite',
      it: 'Armadillo corazzato dalle placche scolpite',
      en: 'Carved-plate Armored Armadillo',
      description:
          'Le placche color cannella si incastrano sulle spalle. '
          'Serra le giunture della corazza per recuperare Scudo.',
      descriptionEn:
          'Cinnamon plates interlock across its shoulders. Bracing the plates restores Shield.',
      stats: {'level': 2, 'resilienza': 7, 'volonta': 3, 'materia': 4},
      skills: ['ink_armadillo_carved_guard'],
    ),
    _inkVariant(
      armadillo,
      suffix: 'scaglie_larghe',
      it: 'Armadillo corazzato a scaglie larghe',
      en: 'Broad-scale Armored Armadillo',
      description:
          'Le grandi scaglie color ardesia dai margini d’ocra proteggono i fianchi. '
          'Ruota a terra e colpisce di taglio con la corazza.',
      descriptionEn:
          'Broad, ochre-rimmed slate scales protect its flanks. It twists low and strikes with their edge.',
      stats: {'level': 3, 'resilienza': 5, 'volonta': 3, 'materia': 7},
      skills: ['ink_armadillo_broad_impact'],
    ),
    _inkVariant(
      construct,
      suffix: 'trapezoidale',
      it: 'Costrutto Minore dallo scudo trapezoidale',
      en: 'Trapezoid Shield Minor Construct',
      description:
          'Una scatola rivettata color verderame cela il nucleo. '
          'Lo scudo trapezoidale gli dà +6 CM e +3 Resistenza per ogni 12 livelli completi.',
      descriptionEn:
          'A riveted verdigris box hides its core. The trapezoid shield grants +6 CM and +3 Resistance per full 12 levels.',
      skills: ['ink_construct_trapezoid_brace'],
      rules: {'variantShieldCm': 6, 'variantShieldResistancePerTwelve': 3},
    ),
    _inkVariant(
      construct,
      suffix: 'rapido',
      it: 'Costrutto Minore Rapido',
      en: 'Quick Minor Construct',
      description:
          'Una scatola fragile cela il nucleo. Ha più Materia, meno Vita e '
          'meno Movimento del Costrutto Minore. Le molle anticipano la risposta del braccio.',
      descriptionEn:
          'Its fragile box hides the core. It has more Matter and lower Life and Movement. Arm springs let it react faster.',
      stats: {'materia': (construct.stats['materia'] ?? 1) + 2},
      skills: ['ink_construct_quick_springs'],
      rules: {'variantHpPercent': 65, 'variantMovementPercent': 50},
    ),
    _inkVariant(
      bell,
      suffix: 'oculum_ametista',
      it: 'Campana di Oculum Ametista',
      en: 'Amethyst Oculum Bell',
      description:
          'Una Mosca Campana incantatrice con sei zampe, quattro ali e una '
          'campana d’ametista. Concentra l’Oculum nel battaglio e scarica raggi d’energia.',
      descriptionEn:
          'Six legs and four wings carry an amethyst bell. It focuses Oculum power in the clapper and fires energy rays.',
      element: 'oculum',
      stats: {'level': 2, 'resilienza': 8, 'oculum': 7},
      skills: ['ink_bell_amethyst_ray', 'ink_bell_amethyst_refraction'],
      inheritSkills: false,
    ),
    _inkVariant(
      larva,
      suffix: 'potenziata',
      it: 'Larva del Pozzo Potenziata',
      en: 'Greater Well Larva',
      description:
          'Ha un corpo nero come il petrolio, una larga maschera d’ambra e '
          'setole color rame-verde. Inarca la corazza per colpire con la maschera.',
      descriptionEn:
          'The oil-black body sports copper-green bristles and a broad amber mask. It arches its shell and strikes with the mask.',
      stats: {
        'level': 2,
        'resilienza': 5,
        'volonta': 3,
        'materia': 5,
        'oculum': 3,
      },
      skills: ['ink_larva_amber_twist'],
    ),
    _inkVariant(
      larva,
      suffix: 'velenosa',
      it: 'Larva del Pozzo Velenosa',
      en: 'Venomous Well Larva',
      description:
          'Ha un lungo corpo color vino e malva, una maschera affusolata '
          'd’avorio e filamenti violetti. Inocula Veleno quando il getto va a segno.',
      descriptionEn:
          'A long wine-and-mauve body bears a tapered ivory mask and violet filaments. The spray inflicts Poison on a hit.',
      element: 'veleno',
      stats: {'level': 1, 'volonta': 2, 'oculum': 4},
      skills: ['ink_larva_venom_filaments'],
    ),
  ];
}

MonsterBookEntry _inkVariant(
  MonsterBookEntry base, {
  required String suffix,
  required String it,
  required String en,
  required String description,
  required String descriptionEn,
  String? element,
  Map<String, int> stats = const {},
  required List<String> skills,
  bool inheritSkills = true,
  Map<String, dynamic> rules = const {},
}) => base.copyWith(
  id: '${base.id}_variante_$suffix',
  nameIt: it,
  nameEn: en,
  descIt: description,
  descEn: descriptionEn,
  elementId: element,
  stats: {...base.stats, ...stats},
  skillIds: [if (inheritSkills) ...base.skillIds, ...skills],
  encounterRules: {
    ...base.encounterRules,
    ...rules,
    'canonicalVariantOf': base.id,
    'authoredCanonical': true,
    'authoredSkillPool': true,
    'fixedInkLoadout': true,
  },
);

int oculumConfirmedConstructResistanceBonus(int level, int bonusPerTwelve) =>
    (level < 0 ? 0 : level ~/ 12) * bonusPerTwelve;

bool oculumIsMinorConstructSpecies(String? id) => const {
  'costrutto_minore',
  'costrutto_minore_variante_trapezoidale',
  'costrutto_minore_variante_rapido',
}.contains(id);

final _confirmedInkTechniques = <String, MonsterConcreteTechnique>{
  'ink_armadillo_carved_guard': _inkTechnique(
    'Serratura delle placche',
    'Incastri le giunture della corazza.',
    'terra',
    'scudo',
    2,
    'materia',
    [
      for (final value in ['6', '10', '14'])
        [
          MonsterTechniqueEffect(
            'scudo',
            value,
            mode: 'immediato',
            duration: '',
          ),
        ],
    ],
  ),
  'ink_armadillo_broad_impact': _inkStrike(
    'Urto di scaglie',
    'Porti avanti il margine della corazza con una rotazione bassa.',
    'contundente',
    3,
    'materia',
    ['5', '9', '14'],
  ),
  'ink_construct_trapezoid_brace': _inkTechnique(
    'Piantare lo scudo',
    'Blocchi a terra il bordo dello scudo trapezoidale.',
    'fisico',
    'difesa',
    1,
    'materia',
    [
      for (final value in ['4', '7', '10'])
        [MonsterTechniqueEffect('difesa', value)],
    ],
  ),
  'ink_construct_quick_springs': _inkTechnique(
    'Scatto a molla',
    'Tendi le molle del braccio e anticipi il prossimo gesto.',
    'fisico',
    'difesa',
    1,
    'materia',
    [
      for (final duration in ['1', '2', '2'])
        [
          MonsterTechniqueEffect(
            'aggiungi_reazioni_rapide',
            '1',
            target: 'reazione_veloce',
            mode: 'temporaneo',
            duration: duration,
          ),
        ],
    ],
  ),
  'ink_bell_amethyst_ray': _inkStrike(
    'Raggio ametista',
    'Concentri Oculum nel battaglio e irraggi il bersaglio.',
    'oculum',
    2,
    'oculum',
    ['4 + oculum_spent', '7 + oculum_spent * 2', '10 + oculum_spent * 3'],
  ),
  'ink_bell_amethyst_refraction': _inkTechnique(
    'Rifrazione ametista',
    'La campana divide l’energia in riflessi protettivi.',
    'oculum',
    'difesa',
    2,
    'oculum',
    [
      for (final value in [
        '3 + oculum_spent',
        '5 + oculum_spent',
        '8 + oculum_spent',
      ])
        [MonsterTechniqueEffect('difesa', value)],
    ],
  ),
  'ink_larva_amber_twist': _inkStrike(
    'Torsione d’ambra',
    'Inarchi la corazza e colpisci con la larga maschera.',
    'contundente',
    2,
    'materia',
    ['4', '7', '11'],
  ),
  'ink_larva_venom_filaments': _inkStrike(
    'Getto dei filamenti',
    'I filamenti viola inoculano il Veleno.',
    'veleno',
    1,
    'oculum',
    ['3', '5', '8'],
    poison: true,
  ),
};

MonsterConcreteTechnique _inkTechnique(
  String name,
  String action,
  String element,
  String kind,
  int level,
  String resource,
  List<List<MonsterTechniqueEffect>> forms,
) => MonsterConcreteTechnique(
  name: name,
  action: action,
  element: element,
  kind: kind,
  requiredLevel: level,
  costResource: resource,
  minimums: const [1, 2, 3],
  maximums: const [1, 2, 3],
  cooldownValues: const [2, 2, 3],
  forms: forms,
);

MonsterConcreteTechnique _inkStrike(
  String name,
  String action,
  String element,
  int level,
  String resource,
  List<String> damages, {
  bool poison = false,
}) => _inkTechnique(name, action, element, 'danno', level, resource, [
  for (var form = 0; form < damages.length; form++)
    [
      MonsterTechniqueEffect(
        'danno',
        damages[form],
        mode: 'prossima_azione',
        duration: '',
      ),
      if (poison)
        MonsterTechniqueEffect(
          'stato',
          (form + 1).toString(),
          target: 'avvelenato',
          mode: 'prossima_azione',
          duration: '2',
          recipient: 'nemico',
        ),
    ],
]);
