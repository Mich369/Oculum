part of 'monster_book.dart';

final _faunaVariantEntries = <MonsterBookEntry>[
  for (final parent in ['scostubanditi', 'granscostumato'])
    (() {
      final base =
          (parent == 'scostubanditi'
                  ? _stormAndBanditEntries
                  : _rebirthRageEvergreenEntries)
              .firstWhere((e) => e.id == parent);
      final small = parent == 'scostubanditi';
      final description =
          'Questa variante condivide l’aspetto della specie comune: ${small ? 'piccolo roditore con cappuccio di feltro e fucile d’ottone' : 'grande bandito dal muso da tasso, pelo grigio ferro e cannone corto'}. Porta una benda color salvia al polso e abbassa l’arma davanti a chi non può più combattere. Ha +6 Empatia. Tutti i suoi colpi sono non letali, anche quelli del cannone: lascia la vittima a una Vita e sottrae soltanto il 50% degli Obser personali. Se viene uccisa, chi la abbatte PERDE 10 + 3×livello del mostro Obser personali, una sola volta e fino a zero. La cassa comune è esclusa. La turnistica non rivela la sua indole.';
      return base.copyWith(
        id: '${parent}_empatico',
        nameIt: small ? 'Scostubandito Empatico' : 'GranScostumato Empatico',
        nameEn: small ? 'Empathic Scostubandit' : 'Empathic GranScostumato',
        descIt: description,
        descEn: description,
        encounterRules: {
          ...base.encounterRules,
          'canonicalVariantOf': parent,
          'empathic': true,
          'empathyBonus': 6,
          'spawnChancePercent': 10,
          'robberyPercent': 50,
          'killerObserBase': 10,
          'killerObserPerLevel': 3,
          'nonLethal': true,
          'initiativeName': small ? 'Scostubandito' : 'GranScostumato',
        },
      );
    })(),
  (() {
    final base = _rebirthRageEvergreenEntries.firstWhere(
      (e) => e.id == 'feralis',
    );
    const description =
        'Feralis Ancestrale è un enorme predatore bipede dalla criniera blu notte, più folta e rigida di quella della specie comune. Placche color rame scuro proteggono spalle e avambracci; spirali di luce turchese pulsano tra le scaglie come un respiro antico. Gli artigli sono consumati sulle punte, il petto avorio è segnato da vecchie cicatrici e due creste spezzate incorniciano gli occhi luminosi. Veglia sui sentieri più vecchi della Foresta Elementale e lascia cortecce incise intorno al proprio territorio. È un Mini Boss più forte del Feralis comune: conserva Furia Primordiale e l’adattamento separato agli elementi, ma usa Artigli ancestrali e un ruggito che rafforza la guardia. L’Oblio resta la sua debolezza.';
    return base.copyWith(
      id: 'feralis_ancestrale',
      nameIt: 'Feralis Ancestrale',
      nameEn: 'Ancestral Feralis',
      descIt: description,
      descEn: description,
      stats: {
        ...base.stats,
        'level': 10,
        'resilienza': 13,
        'volonta': 10,
        'materia': 12,
        'oculum': 9,
      },
      skillIds: [
        'feralis_ancestral_claw',
        'feralis_ancestral_guard',
        ...base.skillIds.where((s) => s != 'feralis_claw'),
      ],
      dropIds: ['placca_ancestrale_feralis'],
      dropChances: {'placca_ancestrale_feralis': 50},
      encounterRules: {
        ...base.encounterRules,
        'canonicalVariantOf': 'feralis',
        'minimumLevel': 10,
      },
    );
  })(),
];

final _faunaVariantTechniques = <String, MonsterConcreteTechnique>{
  'feralis_ancestral_claw': _planarMove(
    'Artigli ancestrali',
    'Le placche delle dita si aprono e gli artigli incidono una traccia luminosa. Un bersaglio, un tiro; potenza e costo crescono con la forma.',
    'taglio',
    'danno',
    [
      for (final n in [12, 19, 28])
        [
          MonsterTechniqueEffect(
            'danno',
            '$n',
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
    ],
    costResource: 'volonta',
    minimums: [2, 3, 4],
    maximums: [2, 3, 4],
    cd: [3, 3, 3],
  ),
  'feralis_ancestral_guard': _planarMove(
    'Ruggito del guardiano',
    'Il ruggito irrigidisce le placche e avvolge il petto di luce turchese: +8/12/16 Difesa per due turni.',
    'natura',
    'difesa',
    [
      for (final n in [8, 12, 16])
        [MonsterTechniqueEffect('difesa', '$n', duration: '2')],
    ],
    minimums: [2, 3, 4],
    maximums: [2, 3, 4],
    cd: [4, 4, 4],
  ),
};
