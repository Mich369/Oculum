part of 'monster_book.dart';

/// Core budgets at level zero, before the existing level/Grade growth.
/// The Devil Moon is the infernal stone variant, not a second duplicate species.
final _lunarGuardEntries = <MonsterBookEntry>[
  for (final seed in const [
    (
      'guardia_lunare',
      'Guardia Lunare',
      [1, 3, 3, 3],
      false,
      false,
      'Una sentinella umanoide pallida e provata dalla vita nei gironi bassi. '
          'L’elmo lunare integrale, la corazza sottile e la lancia sono di argento annerito, '
          'con sottili incisioni #6a4cb0. Il volto resta coperto; il corpo è fragile e il passo guardingo. '
          'Si affida a piccole ombre, alla vista nel buio e alla copertura dei compagni.',
      'Il fianco scoperto sotto il braccio della lancia.',
    ),
    (
      'guardia_lunare_elite',
      'Guardia Lunare Elité',
      [16, 18, 16, 18],
      false,
      false,
      'Umanoide pallido in una corazza di argento annerito più antica e precisa delle uniformi comuni. '
          'L’elmo integrale porta una falce lunare buona, mai un occhio solare. '
          'Il colore #6a4cb0 percorre giunture, lama e bordo dello scudo. '
          'Il potere antico della Luna rende questa Elité più forte dell’Elité Solare, '
          'pur senza cancellare l’usura delle vesti e la povertà dei luoghi che protegge.',
      'L’attacco della spalla quando solleva lo scudo.',
    ),
    (
      'guardiano_lunare',
      'Guardiano Lunare',
      [58, 26, 30, 12],
      true,
      false,
      'Un colosso lento di pietra lunare pallida, con arti massicci e un torace di lastre solide, senza buchi o cavità aperte. '
          'Minime venature emettono una luce #6a4cb0; sottili legature e finiture di argento annerito trattengono '
          'le lastre senza trasformare il corpo in un’armatura metallica. Il nucleo d’ombra resta interno e protetto. La faccia di pietra è chiusa '
          'e segnata dalla falce lunare. Solleva creste, pietre e spuntoni, mentre l’ombra fra le lastre '
          'si estende contro gli aggressori.',
      'Il nucleo d’ombra resta nascosto e non mirabile: occorre distruggere la corazza e poi aprire il petto con un colpo grave.',
    ),
    (
      'guardia_infernale_ik',
      'Guardia Infernale Ik',
      [17, 18, 17, 16],
      false,
      true,
      'Guardia umanoide della famiglia Ik, legata al regno della Regina degli Inferi Iris StarEyes. '
          'Un elmo integrale e placche di argento annerito nascondono il volto e proteggono il corpo; '
          'le finiture #8f1b5b distinguono la sua identità infernale. Porta una lama scura e uno scudo '
          'lunare, dirige l’ombra sul terreno e mantiene la disciplina della formazione. '
          'Il suo essere infernale non equivale a Corruzione Rossa.',
      'La giuntura della caviglia mentre allunga la falcata.',
    ),
    (
      'guardia_infernale_ik_elite',
      'Guardia Infernale Ik Elité',
      [26, 30, 24, 20],
      false,
      true,
      'Umanoide imponente, con elmo integrale, spalliere sovrapposte e un mantello severo. '
          'L’argento annerito dell’armatura custodisce incavi #8f1b5b; il segno lunare è inciso '
          'sullo scudo, mentre la lama sembra trattenere un’ombra densa. '
          'È sensibilmente più forte della Guardia Infernale Ik comune e alterna pressione mentale, '
          'colpi d’ombra e protezione della propria linea.',
      'L’incavo sotto lo sterno quando estende il braccio armato.',
    ),
    (
      'guardian_devil_moon',
      'Guardian Devil Moon',
      [68, 34, 36, 18],
      true,
      true,
      'La variante infernale del Guardiano Lunare è un colosso di pietra diabolica lunare: '
          'massi scuri, spigoli minerali e un torace intero, chiuso e solido attorno al nucleo profondo. '
          'Le minime venature sono #8f1b5b, con legature di argento annerito; il nucleo di ombra diabolica non è visibile né esposto. '
          'la falce lunare rimane leggibile sul petto. La massa resta pietra e non diventa un’armatura '
          'interamente metallica. È lento ma più forte del custode ordinario, e dalle sue creste '
          'si allungano ombre appuntite. Non applica automaticamente alcuna corruzione.',
      'Dopo la distruzione della corazza e un successivo colpo grave al petto, si può mirare al nucleo di ombra diabolica: non ha fragilità elementali.',
    ),
  ])
    _authoredPlanar(
      seed.$1,
      seed.$2,
      seed.$5 ? const ['inferi', 'mezzano'] : const ['mezzano'],
      'luna',
      seed.$6,
      seed.$7,
      seed.$3,
      0,
      false,
      false,
      [for (var slot = 0; slot < 4; slot++) '${seed.$1}_tech_$slot'],
      {
        'authoredCanonical': true,
        'celestialIdentity': 'lunare',
        'lunarGuardFamily': true,
        'lunarGuardian': seed.$4,
        'infernalIk': seed.$5,
        if (seed.$5) 'ikQueen': 'Iris StarEyes',
        if (seed.$5)
          'ikLore':
              'Iris StarEyes domina le stelle, presenti nel cielo grazie a lei, non il Sole. Aiutava la Luna: sognavano accettazione di chiunque, scambio degli averi e ricchezza condivisa per eliminare la povertà. Il Sole favorisce ricchi, potenti e buone famiglie, dando in pasto al Sole i benestanti di categoria inferiore.',
        'canonicalAccent': seed.$5 ? '#8f1b5b' : '#6a4cb0',
        'canonicalMetal': 'argento annerito',
        if (seed.$4)
          'canonicalBodyMaterial': seed.$5
              ? 'pietra diabolica lunare'
              : 'pietra lunare',
        if (seed.$4) 'slowColossus': true,
        if (seed.$4) 'lunarGuardianOpen': true,
        'naturalAttitude': seed.$4
            ? 'Custode paziente e territoriale: protegge i passaggi, avanza lentamente e risponde con pietra e ombra alle minacce.'
            : seed.$5
            ? 'Disciplinata e misurata; protegge la propria formazione e gli interessi della famiglia Ik, senza violenza gratuita.'
            : 'Vigile e protettiva verso i Lunari dei gironi bassi. Non cerca uno scontro inutile, ma difende i compagni dalle aggressioni.',
      },
      const {'luna': 'resistenza', 'buio': 'resistenza'},
    ).copyWith(
      classificationTags: [
        seed.$4 ? 'Costrutto di pietra' : 'Umanoide',
        'Lunare',
        if (seed.$5) 'Infernale Ik',
      ],
      canWieldWeapons: !seed.$4,
      weaponTags: seed.$4 ? const [] : const ['lama', 'lancia'],
      armorTags: seed.$4 ? const [] : const ['argento annerito'],
      inventoryItems: seed.$4
          ? const []
          : [
              {
                'nome': seed.$1 == 'guardia_lunare'
                    ? 'Lancia della Guardia Lunare'
                    : 'Lama di ${seed.$2}',
                'arma': true,
                'equipaggiata': true,
                'quantita': 1,
                'peso': 1.4,
                'livelloOggetto': 0,
                'gradoOggetto': 0,
                'bonusDanno': seed.$1 == 'guardia_lunare'
                    ? 1
                    : seed.$1 == 'guardia_infernale_ik_elite'
                    ? 9
                    : 6,
                'elementoDanno': 'Buio',
                'note':
                    'Lama di argento annerito, con incisioni ${seed.$5 ? '#8f1b5b' : '#6a4cb0'} e una piccola falce lunare. L’ombra segue il filo.',
              },
              {
                'nome': 'Scudo di ${seed.$2}',
                'protegge': true,
                'equipaggiata': true,
                'quantita': 1,
                'peso': 2.2,
                'livelloOggetto': 0,
                'gradoOggetto': 0,
                'bonusDifesa': seed.$1 == 'guardia_lunare'
                    ? 1
                    : seed.$1 == 'guardia_infernale_ik_elite'
                    ? 6
                    : 4,
                'elementoDifesa': 'Luna',
                'note':
                    'Scudo in argento annerito con falce lunare e bordi ${seed.$5 ? '#8f1b5b' : '#6a4cb0'}. Le ammaccature raccontano il servizio del custode.',
              },
            ],
      dropIds: ['frammento_${seed.$1}', 'equip_${seed.$1}'],
      dropChances: {'frammento_${seed.$1}': 45, 'equip_${seed.$1}': 20},
    ),
];

final _lunarGuardTechniques = <String, MonsterConcreteTechnique>{
  for (final entry in _lunarGuardEntries)
    for (var slot = 0; slot < 4; slot++)
      '${entry.id}_tech_$slot': _planarMove(
        slot == 0
            ? entry.encounterRules['lunarGuardian'] == true
                  ? 'Maglio dell’ombra minerale'
                  : 'Fendente della falce scura'
            : slot == 1
            ? 'Presidio della Luna'
            : slot == 2
            ? 'Passo fra le ombre'
            : 'Lettura della penombra',
        slot == 0
            ? entry.encounterRules['lunarGuardian'] == true
                  ? 'Solleva il braccio di pietra e lo abbatte contro un avversario; l’ombra fra le lastre accompagna l’impatto. Bonus ai Danni soltanto per questo attacco.'
                  : 'La lama di argento annerito attraversa una traiettoria breve e controllata. Colpisce un avversario con Danni di Buio aggiuntivi.'
            : slot == 1
            ? 'Chiude la guardia e protegge il punto debole per un turno personale, senza cancellare la Vita già persa.'
            : slot == 2
            ? 'Sfrutta le ombre reali per spostare il peso e mantenere la linea; non concede un teletrasporto o intangibilità non dichiarati.'
            : 'Osserva dal buio e riconosce un movimento vicino: Percezione viene potenziata per un turno personale.',
        slot == 0 ? 'buio' : 'luna',
        slot == 0
            ? 'danno'
            : slot == 1
            ? 'scudo'
            : slot == 2
            ? 'movimento'
            : 'richiamo',
        [
          for (var form = 1; form <= 3; form++)
            [
              if (slot == 0)
                MonsterTechniqueEffect(
                  'danno',
                  '${form * (entry.id == 'guardia_lunare'
                          ? 2
                          : entry.encounterRules['lunarGuardian'] == true
                          ? 12
                          : 6)}',
                  mode: 'prossima_azione',
                  duration: '',
                )
              else if (slot == 1)
                MonsterTechniqueEffect(
                  'difesa',
                  '${form * (entry.id == 'guardia_lunare' ? 2 : 5)}',
                  duration: '1',
                )
              else if (slot == 2)
                MonsterTechniqueEffect('velocita', '$form', duration: '1')
              else
                MonsterTechniqueEffect(
                  'modifica_sottotratto',
                  '${form * 2}',
                  target: 'percezione',
                  duration: '1',
                ),
            ],
        ],
        minimums: const [1, 2, 3],
        maximums: const [1, 2, 3],
        cd: const [2, 3, 4],
      ),
};
