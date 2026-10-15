part of 'monster_book.dart';

/// Serializable mechanics used by both the Book prose and the sheet importer.
/// No Flutter state or rolls are owned by this catalogue.
class MonsterTechniqueEffect {
  const MonsterTechniqueEffect(
    this.type,
    this.formula, {
    this.target = '',
    this.mode = 'finche_attivo',
    this.duration = '1',
  });
  final String type, formula, target, mode, duration;
}

class MonsterConcreteTechnique {
  const MonsterConcreteTechnique({
    required this.name,
    required this.action,
    required this.forms,
    required this.element,
    required this.kind,
    required this.requiredLevel,
    this.minimums = const [1, 5, 11],
    this.maximums = const [4, 10, 30],
  });
  final String name, action, element, kind;
  final int requiredLevel;
  final List<int> minimums, maximums;
  final List<List<MonsterTechniqueEffect>> forms;

  /// Recovery is expressed in personal turns, using the existing Art timer.
  /// Persistent resources need a longer recovery than a single attack bonus.
  List<int> get cooldowns => switch (kind) {
    'cura' => const [3, 4, 5],
    'costrutto' => const [3, 4, 5],
    'scudo' => const [2, 3, 4],
    'movimento' || 'richiamo' => const [2, 2, 3],
    _ => const [1, 1, 2],
  };
  String text() =>
      '$name — ${List.generate(3, (i) {
        final mechanics = forms[i].map((e) {
          final value = e.formula.replaceAll('oculum_spent', 'Oculum immesso');
          return switch (e.type) {
            'danno' => '+$value Danni al prossimo attacco; si consuma una sola volta',
            'danno_percentuale' => '+$value% Danni al prossimo attacco; si consuma una sola volta',
            'difesa' => '+$value Difesa per ${e.duration} turno',
            'scudo' => '+$value Scudo, fino a esaurimento',
            'cura' => 'recuperi $value Vita, entro il massimo',
            'costrutto' => 'crei ${e.target} con $value Vita per ${e.duration} turni; la sua Vita si gestisce nella scheda effetti',
            'aggiungi_reazioni' => '+$value Reazione per ${e.duration} turno',
            'modifica_statistica' => '${e.target} ${e.mode == 'diminuzione' ? '-' : '+'}$value per ${e.duration} turno',
            _ => '$value ${e.target}',
          };
        }).join('; ');
        final cost = '${minimums[i]}/${maximums[i]}';
        return '${const ['I', 'II', 'III'][i]}/$action. $mechanics. Richiede livello ${requiredLevel + i * 3}. ($cost Oculum${minimums[i] == maximums[i] ? ', costo fisso' : ''}). CD ${cooldowns[i]} turni personali.';
      }).join(' ')} I bonus della stessa tecnica non si cumulano; Difesa e Scudi del bersaglio restano validi.';
}

final Map<String, MonsterBookEntry> _concreteTechniqueOwners = () {
  final owners = <String, MonsterBookEntry>{};
  final creatures = [
    ..._staticMonsterBookEntries,
    ..._generateMonsterTier(
      count: max(2, targetNormalMonsterCount - _staticNormalMonsterCount),
      tier: _GeneratedMonsterTier.normal,
    ),
    ..._generateMonsterTier(
      count: targetMiniBossMonsterCount - _staticMiniBossMonsterCount,
      tier: _GeneratedMonsterTier.miniBoss,
    ),
    ..._generateMonsterTier(
      count: targetBossMonsterCount - _staticBossMonsterCount,
      tier: _GeneratedMonsterTier.boss,
    ),
  ];
  for (final creature in creatures) {
    final ids =
        creature.skillIds.isEmpty &&
            !creature.formTags.contains('Creatura Minore')
        ? _skillIdsForGeneratedMonster(creature.id, creature.elementId)
        : creature.skillIds;
    for (final id in ids) {
      owners.putIfAbsent(
        id.replaceFirst(RegExp(r'_variante_[a-z]+$'), ''),
        () => creature,
      );
    }
  }
  return owners;
}();

final Map<String, MonsterConcreteTechnique?> _concreteTechniqueCache = {};

MonsterConcreteTechnique? monsterBookConcreteTechnique(String rawId) {
  final id = rawId.replaceFirst(RegExp(r'_variante_[a-z]+$'), '');
  return _concreteTechniqueCache.putIfAbsent(id, () {
    final owner = _concreteTechniqueOwners[id];
    if (owner == null) return null;
    final frost = _frostDemonTechniques[id];
    if (frost != null) {
      return MonsterConcreteTechnique(
        name: frost.$1,
        action: frost.$2,
        element: 'gelo',
        requiredLevel: 0,
        kind: frost.$3,
        forms: List.generate(
          3,
          (form) => switch (frost.$3) {
            'scudo' => [
              MonsterTechniqueEffect(
                'scudo',
                'oculum_spent*${form + 2}',
                mode: 'immediato',
                duration: '',
              ),
              MonsterTechniqueEffect('difesa', '${(form + 1) * 3}'),
            ],
            'costrutto' => [
              MonsterTechniqueEffect(
                'costrutto',
                'oculum_spent*${form + 3}',
                target: frost.$1,
                mode: 'immediato',
                duration: '${form + 1}',
              ),
            ],
            _ => [
              MonsterTechniqueEffect(
                'danno',
                'oculum_spent*${form + 1}+${form * 5}',
                mode: 'prossima_azione',
                duration: '',
              ),
            ],
          },
        ),
      );
    }
    final anatomy = _monsterAnatomy(owner);
    final index = owner.skillIds.indexOf(id);
    final bespoke = _bespokeMonsterMoves[id];
    final kind =
        bespoke?.$3 ??
        (RegExp(
              r'heal|regen|mend|purr|rebirth|repair|reassemble|absolution|growth',
            ).hasMatch(id)
            ? 'cura'
            : RegExp(
                r'web|snare|prison|root|wall|field|pressione|trap|junk|domain|summon|offspring|skeleton|pages',
              ).hasMatch(id)
            ? 'costrutto'
            : RegExp(
                r'dash|step|flight|escape|hop|climb|vanish|risposta|scurry|fuga',
              ).hasMatch(id)
            ? 'movimento'
            : RegExp(
                r'guard|shield|shell|skin|hide|armor|cover|hollow|corazza',
              ).hasMatch(id)
            ? 'scudo'
            : RegExp(
                r'howl|song|roar|order|command|laugh|echo|scream',
              ).hasMatch(id)
            ? 'richiamo'
            : 'colpo');
    final specific = _specificMonsterMotion[id];
    final label =
        bespoke?.$1 ??
        specific?.$1 ??
        switch (kind) {
          'cura' => anatomy.$4,
          'costrutto' => anatomy.$5,
          'movimento' => anatomy.$6,
          'scudo' => anatomy.$2,
          'richiamo' => anatomy.$5,
          _ => anatomy.$1,
        };
    final action =
        bespoke?.$2 ??
        specific?.$2 ??
        switch (kind) {
          'cura' => anatomy.$7,
          'costrutto' => anatomy.$8,
          'movimento' => anatomy.$9,
          'scudo' => anatomy.$10,
          'richiamo' => anatomy.$11,
          _ => anatomy.$3,
        };
    final forms = List.generate(3, (form) {
      final rank = form + 1;
      final tactical = _monsterTacticalForms(id, rank);
      if (tactical != null) return tactical;
      return switch (kind) {
        'cura' => [
          MonsterTechniqueEffect(
            'cura',
            'oculum_spent+${rank * 2}',
            mode: 'immediato',
            duration: '',
          ),
        ],
        'costrutto' => [
          MonsterTechniqueEffect(
            'costrutto',
            'oculum_spent*${rank + 1}',
            target: label,
            mode: 'immediato',
            duration: '${rank + 1}',
          ),
        ],
        'movimento' => [
          MonsterTechniqueEffect(
            'modifica_statistica',
            'oculum_spent/4+$rank',
            target: 'CM',
          ),
          if (form == 2) const MonsterTechniqueEffect('aggiungi_reazioni', '1'),
        ],
        'scudo' => [
          MonsterTechniqueEffect(
            'scudo',
            'oculum_spent+${rank * 3}',
            mode: 'immediato',
            duration: '',
          ),
          if (form > 0) MonsterTechniqueEffect('difesa', '$rank'),
        ],
        'richiamo' => [
          MonsterTechniqueEffect(
            'modifica_statistica',
            'oculum_spent/4+$rank',
            target: 'VC',
          ),
          if (form == 2) const MonsterTechniqueEffect('aggiungi_reazioni', '1'),
        ],
        _ => [
          MonsterTechniqueEffect(
            'danno',
            'oculum_spent+${form * 3}',
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
      };
    });
    return MonsterConcreteTechnique(
      name: '$label · ${owner.nameIt}',
      action: action,
      requiredLevel: monsterBookSkillRequiredLevel(owner, max(0, index)),
      forms: forms,
      element: owner.elementId,
      kind: kind,
    );
  });
}

/// Explicit tactical differences: these are not chosen from an ID hash.
/// Costs still come from the single catalogue definition above.
List<MonsterTechniqueEffect>? _monsterTacticalForms(String id, int rank) {
  MonsterTechniqueEffect damage(String expression) => MonsterTechniqueEffect(
    'danno',
    expression,
    mode: 'prossima_azione',
    duration: '',
  );
  MonsterTechniqueEffect stat(
    String target,
    String value, {
    bool penalty = false,
  }) => MonsterTechniqueEffect(
    'modifica_statistica',
    value,
    target: target,
    mode: penalty ? 'diminuzione' : 'finche_attivo',
  );
  return switch (id) {
    // A dirty opening trades guard for accuracy; the Orc trades it for impact.
    'dirty_strike' => [
      damage('oculum_spent'),
      stat('VC', '$rank'),
      stat('CM', '1', penalty: true),
    ],
    'brutal_charge' || 'maze_charge' => [
      MonsterTechniqueEffect(
        'danno_percentuale',
        '${rank * 20}',
        mode: 'prossima_azione',
        duration: '',
      ),
      damage('oculum_spent'),
      stat('CM', '$rank', penalty: true),
    ],
    'shoulder' => [
      damage('oculum_spent+${rank * 2}'),
      if (rank > 1) stat('VC', '1'),
    ],
    'pack_attack' || 'coordinated_assault' => [
      damage('oculum_spent'),
      stat('VC', '${rank * 2}'),
    ],
    'run_laugh' => [
      stat('CM', 'oculum_spent/4+$rank'),
      stat('VC', '1', penalty: true),
    ],
    'den_move' => [
      stat('CM', '$rank'),
      MonsterTechniqueEffect('difesa', 'oculum_spent+$rank'),
    ],
    'backstab' => [
      damage('oculum_spent+${rank * 3}'),
      stat('CM', '1', penalty: true),
    ],
    'quick_hand' => [
      stat('VC', 'oculum_spent/4+$rank'),
      if (rank == 3)
        const MonsterTechniqueEffect('aggiungi_reazioni_rapide', '1'),
    ],
    'feint' => [stat('VC', '${rank + 1}'), stat('CM', 'oculum_spent/4')],
    'wolf_pack' => [stat('VC', '$rank'), stat('CM', 'oculum_spent/4+$rank')],
    'leg_bite' => [
      damage('oculum_spent+$rank'),
      MonsterTechniqueEffect('difesa', '$rank'),
    ],
    'rend' => [
      damage('oculum_spent+${rank * 4}'),
      stat('CM', '$rank', penalty: true),
    ],
    'dive' || 'dive_claw' => [
      damage('oculum_spent+${rank * 2}'),
      stat('VC', '$rank'),
      stat('CM', '1', penalty: true),
    ],
    'wingbeat' => [
      stat('CM', 'oculum_spent/4+$rank'),
      if (rank > 1) const MonsterTechniqueEffect('aggiungi_reazioni', '1'),
    ],
    'counterattack' => [
      const MonsterTechniqueEffect('aggiungi_reazioni', '1'),
      damage('oculum_spent/2+$rank'),
    ],
    'formation' => [
      MonsterTechniqueEffect('difesa', 'oculum_spent+${rank * 2}'),
      stat('VC', '$rank'),
    ],
    'short_order' => [stat('VC', 'oculum_spent/4+${rank * 2}')],
    'hard_head' => [
      MonsterTechniqueEffect('difesa', 'oculum_spent+${rank * 3}'),
      stat('VC', '1', penalty: true),
    ],
    'hollow' => [
      stat('CM', 'oculum_spent/4+$rank'),
      stat('VC', '1', penalty: true),
    ],
    'reassemble' || 'cracks' => [
      MonsterTechniqueEffect(
        'cura',
        'oculum_spent+${rank * 3}',
        mode: 'immediato',
        duration: '',
      ),
      stat('CM', '1', penalty: true),
    ],
    'massive_body' => [
      MonsterTechniqueEffect(
        'scudo',
        'oculum_spent+${rank * 4}',
        mode: 'immediato',
        duration: '',
      ),
      stat('CM', '1', penalty: true),
    ],
    'seismic_punch' || 'ground_maul' => [
      damage('oculum_spent+${rank * 5}'),
      stat('VC', '1', penalty: true),
    ],
    'defensive_wings' => [
      MonsterTechniqueEffect('difesa', 'oculum_spent+${rank * 2}'),
      if (rank > 1) const MonsterTechniqueEffect('aggiungi_reazioni', '1'),
    ],
    'blind_fury' => [
      MonsterTechniqueEffect(
        'danno_percentuale',
        '${rank * 25}',
        mode: 'prossima_azione',
        duration: '',
      ),
      stat('CM', '$rank', penalty: true),
    ],
    'poison_tongue' => [damage('oculum_spent+$rank'), stat('VC', '$rank')],
    _ => null,
  };
}

/// Anatomy constrains the actual motion: a moth never swings a sword and a
/// stationary wall eye never grows legs merely to obtain a movement bonus.
(
  String,
  String,
  String,
  String,
  String,
  String,
  String,
  String,
  String,
  String,
  String,
)
_monsterAnatomy(MonsterBookEntry monster) {
  final body = '${monster.id} ${monster.nameIt}'.toLowerCase();
  if (RegExp(r'ragno|spider|filo|cucit|thread').hasMatch(body)) {
    return (
      'Zanne sotto la seta',
      'Bozzolo a strati',
      'Affondi i cheliceri dopo aver teso un filo tra le zampe',
      'Sutura di seta',
      'Tela tra due appigli',
      'Discesa sul filo',
      'Cuci la ferita con la seta prodotta dal ventre',
      'Stendi fili tra due appigli e li avvolgi fino a formare una barriera con Vita propria',
      'Ti lasci scendere dal soffitto su un filo e risali fuori dalla linea del colpo',
      'Avvolgi il corpo in strati di seta aderenti',
      'Fai vibrare i fili sotto le zampe per anticipare il colpo',
    );
  }
  if (RegExp(r'slime|plomp|sugo|gel').hasMatch(body)) {
    return (
      'Getto di gel compresso',
      'Crosta gelatinosa',
      'Comprimendo il nucleo, sputi un proiettile denso dalla bocca',
      'Ricucitura del nucleo',
      'Argine di gel',
      'Rimbalzo laterale',
      'Raccogli il gel disperso e lo riassorbi attorno al nucleo',
      'Spalmi il gel sul terreno e lo solidifichi in un argine con Vita propria',
      'Appiattisci il corpo contro il terreno e rimbalzi sul fianco prima dell’impatto',
      'Coaguli la superficie in un guscio viscoso',
      'Fai pulsare il nucleo per sincronizzare compressione e rilascio del corpo',
    );
  }
  if (RegExp(
    r'arpia|grif|corvo|vespa|falena|pipistrello|angelo|seraf|strige|uccel',
  ).hasMatch(body)) {
    return (
      'Picchiata a uncino',
      'Mantello di penne',
      'Chiudi le ali e piombi sul bersaglio con artigli, rostro o pungiglione',
      'Mutazione del piumaggio',
      'Ventaglio di penne',
      'Virata sopra la spalla',
      'Spingi fuori penne e tessuti danneggiati e richiudi la ferita',
      'Incastri penne, scaglie alari e detriti in uno schermo con Vita propria',
      'Batti le ali di taglio e cambi quota mentre il colpo attraversa la posizione appena lasciata',
      'Chiudi le ali sovrapposte davanti a torace e collo',
      'Alterni battiti brevi per scandire attacco e parata',
    );
  }
  if (RegExp(
    r'lupo|warg|cane|mastino|gnoll|gatto|topo|basil|idra|serpent',
  ).hasMatch(body)) {
    return (
      'Morso dietro il ginocchio',
      'Fianco serrato',
      'Scatti basso e stringi le zanne dietro il ginocchio o una giuntura esposta',
      'Leccata sulla ferita',
      'Tana di ossa',
      'Scarto del predatore',
      'Lecchi la ferita e contrai i lembi del tessuto',
      'Ammucchi ossa, pelli e terriccio formando una tana con Vita propria',
      'Punti le zampe, torci il busto e scivoli fuori dalla traiettoria del colpo',
      'Serri le scaglie o il pelo sul fianco esposto',
      'Batti mandibole e zampe per ritmare la risposta al prossimo colpo',
    );
  }
  if (RegExp(
    r'legno|alber|forest|fung|muschio|leaf|radic|patalpa|cervo',
  ).hasMatch(body)) {
    return (
      'Scheggia sotto la corteccia',
      'Scorza sovrapposta',
      'Pieghi un ramo, un corno o una radice e lo rilasci contro il bersaglio',
      'Linfa sul taglio',
      'Palizzata di radici',
      'Passo fra le radici',
      'Fai colare linfa nel taglio e lo richiudi con fibre nuove',
      'Intrecci radici e rami in una palizzata con Vita propria',
      'Ritiri le radici dal suolo e ripieghi il corpo prima del colpo',
      'Sovrapponi placche di corteccia sulle parti esposte',
      'Fai vibrare il legno del corpo e segui le vibrazioni trasmesse dal terreno',
    );
  }
  if (RegExp(r'occhio|eye|specchio|mirror|null|incubo|spirit').hasMatch(body)) {
    return (
      'Pupilla a fessura',
      'Palpebra di vetro',
      'Contrai la pupilla o la superficie riflettente e scagli una scheggia concentrata',
      'Ricomposizione della pupilla',
      'Lastra riflettente',
      'Rotazione della superficie',
      'Riaccosti i frammenti intorno alla pupilla fino a ricomporne il bordo',
      'Espelli una lastra opaca che resta davanti a te con Vita propria',
      'Ruoti il corpo o la superficie sul proprio asse, offrendo il profilo al colpo',
      'Fai scorrere palpebre e frammenti fino a coprire la pupilla',
      'Stringi il campo visivo e segui soltanto le mani dell’avversario',
    );
  }
  if (RegExp(
    r'golem|roccia|rock|mammut|gigante|ogre|minot|toro|rinocer',
  ).hasMatch(body)) {
    return (
      'Schianto della massa',
      'Placche accostate',
      'Carichi con spalla, corno o pugno e scarichi il peso sul punto di contatto',
      'Riassetto delle placche',
      'Muro di macerie',
      'Rotazione del peso',
      'Riposizioni le placche e ricomponi le crepe del corpo',
      'Spingi pietre e macerie una contro l’altra formando un muro con Vita propria',
      'Scarichi il peso sul piede posteriore e ruoti il busto per offrire il fianco corazzato',
      'Accosti le placche del dorso davanti alle parti molli',
      'Batti il piede e fai risuonare il corpo per stabilizzare il prossimo movimento',
    );
  }
  return (
    'Colpo alla giuntura',
    'Guardia sul torace',
    'Fai scivolare l’arma o l’estremità del corpo sotto la guardia e colpisci una giuntura',
    'Bendaggio serrato',
    'Riparo di detriti',
    'Scarto sul tallone',
    'Stringi un lembo del mantello o della pelle sulla ferita',
    'Incastri detriti e parti del tuo equipaggiamento in un riparo con Vita propria',
    'Arretri il tallone e ruoti le spalle mentre il colpo attraversa la posizione lasciata',
    'Incroci l’equipaggiamento o le estremità davanti al torace',
    'Scandisci la respirazione con un segnale secco e prepari la risposta',
  );
}

const _specificMonsterMotion = <String, (String, String)>{
  'dirty_strike': (
    'Sabbia negli occhi',
    'Raschi il terreno col coltello e accompagni la polvere con un affondo basso',
  ),
  'run_laugh': (
    'Risata dietro il sasso',
    'Ridi a bocca spalancata mentre scatti dietro una roccia senza voltare le spalle',
  ),
  'junk': (
    'Barricata di rottami',
    'Ammucchi ferraglia e assi rotte davanti alle ginocchia formando un riparo con Vita propria',
  ),
  'web': (
    'Ragnatela a doppio nodo',
    'Tendi due fili e li annodi in uno schermo di seta con Vita propria',
  ),
  'harpy_song': (
    'Cadenza degli artigli',
    'Canti una nota spezzata e fai coincidere il movimento degli artigli con ogni pausa',
  ),
  'dive': (
    'Picchiata al tendine',
    'Chiudi le ali e agganci il tendine dietro la caviglia con gli artigli posteriori',
  ),
  'wingbeat': (
    'Battito a coltello',
    'Giri sul fianco e colpisci con il bordo rigido dell’ala',
  ),
  'sticky_tongue': (
    'Lingua a ventosa',
    'La lingua adesiva scatta dal bordo del coperchio e si serra sull’equipaggiamento della preda',
  ),
  'scattered_bones': (
    'Costola a boomerang',
    'Stacchi una costola e la scagli di piatto contro il bersaglio',
  ),
  'reassemble': (
    'Sterno ricomposto',
    'Raccogli le tue ossa sparse e le incastri nuovamente nello sterno',
  ),
  'grave_ray': (
    'Raggio dal sigillo funebre',
    'Il sigillo sul palmo si apre e proietta una linea scura attraverso l’aria',
  ),
  'vampire_bite': (
    'Canini sotto la mandibola',
    'Agganci il mento con una mano e affondi i canini nella parte scoperta del collo',
  ),
  'seismic_punch': (
    'Pugno lungo la crepa',
    'Colpisci il terreno e fai correre una crepa fino ai piedi del bersaglio',
  ),
  'breath': (
    'Soffio dalla gola dilatata',
    'Dilati le placche della gola ed espelli il respiro concentrato in una linea',
  ),
  'ground_maul': (
    'Mazza di rimbalzo',
    'Colpisci il suolo e lasci che il rimbalzo della mazza risalga contro il bersaglio',
  ),
  'leg_bite': (
    'Zanne nel polpaccio',
    'Ti abbassi sotto la guardia e chiudi le zanne sul polpaccio della preda',
  ),
  'predator': (
    'Attesa al fianco cieco',
    'Segui i passi della preda senza avanzare finché non scopre il fianco',
  ),
  'rend': (
    'Strappo della iena',
    'Blocchi la stoffa sotto gli artigli e tiri la mandibola all’indietro per lacerarla',
  ),
  'backstab': (
    'Lama sotto la scapola',
    'Scivoli oltre la spalla della vittima e fai risalire la lama sotto la scapola',
  ),
  'feint': (
    'Finta sul polso',
    'Abbassi la punta della lama e risali sul polso che si è mosso per parare',
  ),
  'quick_hand': (
    'Mano tra le fibbie',
    'Infili una mano fra le fibbie avversarie e tiri l’equipaggiamento verso il basso prima dell’affondo',
  ),
  'stone_tail': (
    'Coda di basalto',
    'Ruoti il bacino e fai urtare la coda corazzata contro le tibie del bersaglio',
  ),
  'mineral_skin': (
    'Scaglie incastrate',
    'Serri le scaglie minerali fino a chiudere gli spazi sul ventre',
  ),
  'hard_head': (
    'Fronte contro ferro',
    'Abbassi il mento e presenti la placca frontale all’urto',
  ),
  'hollow': (
    'Costole intrecciate',
    'Ruoti le costole nel torace vuoto fino a intrecciarle in una gabbia protettiva',
  ),
  'not_down': (
    'Fili di carne tesi',
    'Tendi i lembi di carne ancora attaccati e ti risollevi dalla ferita',
  ),
  'rotten_bite': (
    'Morso dei denti marci',
    'Ti aggrappi con entrambe le mani e affondi i denti anneriti nella parte scoperta del braccio',
  ),
  'long_arms': (
    'Manata oltre la guardia',
    'Allunghi il braccio del troll oltre il bordo della guardia e colpisci il fianco',
  ),
  'mutant_flesh': (
    'Noduli sul torace',
    'Fai rigonfiare i noduli della carne fino a coprire i punti scoperti',
  ),
  'blood_scent': (
    'Naso sulla ferita',
    'Inspiri l’odore del sangue e segui il battito della preda attraverso la sua respirazione',
  ),
  'formation': (
    'Scudi sovrapposti',
    'Appoggi il bordo dello scudo a quello della linea e chiudi la fessura davanti al petto',
  ),
  'short_order': (
    'Ordine fra i denti',
    'Batti l’arma sullo scudo e scandisci il momento dell’affondo con una parola',
  ),
  'counterattack': (
    'Risposta sotto la lama',
    'Accompagni il colpo con il bordo dello scudo e prepari l’arma sotto il suo polso',
  ),
  'wing_hit': (
    'Ala sullo sterno',
    'Ruoti il busto del drago e colpisci lo sterno con l’articolazione ossea dell’ala',
  ),
  'coordinated_heads': (
    'Morsi alternati',
    'Una testa dell’idra costringe il bersaglio ad alzare la guardia e la successiva morde più in basso',
  ),
  'head_fury': (
    'Frustata dei colli',
    'Incroci i colli dell’idra e li apri di scatto contro la linea della preda',
  ),
  'controlled_regrowth': (
    'Ricucitura del moncone',
    'Chiudi i vasi del collo reciso e ricomponi la carne attorno al moncone',
  ),
  'growing_anger': (
    'Respiro del gigante',
    'Stringi la presa sull’arma a ogni respiro e prepari un colpo di peso',
  ),
  'grab_throw': (
    'Presa al cinturone',
    'Afferra il cinturone del bersaglio e trascina il suo peso nella traiettoria del pugno',
  ),
  'friendly_purr': (
    'Fusa del nucleo tiepido',
    'Il nucleo del Kitty Slime vibra e riassorbe il gel che si era separato',
  ),
  'soft_bounce': (
    'Rimbalzo sul cuscinetto',
    'Appiattisci il corpo del Kitty Slime come un cuscino e rimbalzi di lato',
  ),
  'tiny_bubble': (
    'Bolla sul muso',
    'Soffi una bolla densa dal muso e la stendi sul nucleo come protezione',
  ),
  'wire_laugh': (
    'Risata delle mandibole appese',
    'Il Giullare tende i fili della mandibola e accompagna la risata con uno scatto delle dita',
  ),
  'reaction_cut': (
    'Filo tra i polsi',
    'Il Giullare lancia un filo teso fra i polsi avversari e lo ritrae come una lama',
  ),
  'puppet_dash': (
    'Strappo dei fili dorsali',
    'Il Giullare tende i fili del dorso e si tira fuori dalla traiettoria del colpo',
  ),
  'shield_reforge': (
    'Ribattitura dello scudo',
    'Il Fabbro colpisce lo scudo dall’interno, riaccostando le lamine separate',
  ),
  'tongueless_hammer': (
    'Martello sulle nocche',
    'Il Fabbro fa scendere il martello sulla mano che regge la guardia',
  ),
  'ash_pounce': (
    'Balzo delle ceneri',
    'Il Cane di Cenere comprime le zampe posteriori e salta al collo della preda',
  ),
  'dust_choke': (
    'Soffio dalla gola secca',
    'Il Cane di Cenere espelle la polvere accumulata nella gola contro il bersaglio',
  ),
  'bone_lantern': (
    'Lanterna fra le costole',
    'Il Lanterniere chiude le costole attorno alla fiamma e solleva il lume davanti al torace',
  ),
  'critical_reflect': (
    'Riflesso inclinato',
    'Inclini lo Specchio Mangiavoce finché la sagoma del colpo scivola sul bordo',
  ),
};

const _frostDemonTechniques = <String, (String, String, String)>{
  'frost_demon_lesser_spur': (
    'Sperone della brina',
    'Il Demone Glaciale Minore fa crescere uno sperone sul gomito e lo conficca sotto la guardia',
    'colpo',
  ),
  'frost_demon_lesser_shell': (
    'Crosta del primo inverno',
    'Il Demone Glaciale Minore congela il vapore sul proprio torace in placche sovrapposte',
    'scudo',
  ),
  'frost_demon_intermediate_ray': (
    'Raggio fra i denti',
    'Il Demone Glaciale Intermedio dischiude la mandibola e concentra il gelo in un raggio rettilineo',
    'colpo',
  ),
  'frost_demon_intermediate_prison': (
    'Gabbia di stalattiti',
    'Il Demone Glaciale Intermedio fa convergere stalattiti sul terreno formando una gabbia con Vita propria',
    'costrutto',
  ),
  'frost_demon_greater_lances': (
    'Lance del cuore immobile',
    'Il Demone Glaciale Maggiore estrae dal torace una lancia di ghiaccio compatto e la scaglia con entrambe le mani',
    'colpo',
  ),
  'frost_demon_greater_mirror': (
    'Specchio dell’inverno nero',
    'Il Demone Glaciale Maggiore fa salire dal terreno una lastra scura e la sovrappone alla propria pelle',
    'scudo',
  ),
};

/// Each legacy verb gets an actual physical action and its own mechanical
/// purpose. These entries override morphology inference, never authored rules.
const _bespokeMonsterMoves = <String, (String, String, String)>{
  'poison_tongue': (
    'Lingua della Fugra',
    'Allunghi la lingua coperta di secrezione irritante e la fai schioccare contro la pelle scoperta del bersaglio',
    'colpo',
  ),
  'tripwire': (
    'Filo fra le caviglie',
    'Il Kobold lega una corda fra due sassi e la rinforza in una trappola con Vita propria',
    'costrutto',
  ),
  'den_move': (
    'Tuffo nella tana',
    'Il Kobold si infila nel cunicolo alle proprie spalle e sporge soltanto l’arma',
    'movimento',
  ),
  'pack_attack': (
    'Punta dal secondo lato',
    'Il Kobold passa sotto il braccio della preda e affonda dalla parte opposta alla sua guardia',
    'colpo',
  ),
  'brutal_charge': (
    'Spallata a mascella aperta',
    'L’Orco prende tre passi di rincorsa e fa impattare la spalla sotto il mento',
    'colpo',
  ),
  'hurt_rage': (
    'Rabbia fra i denti',
    'L’Orco stringe i denti sul bordo della propria benda e irrigidisce il torace',
    'scudo',
  ),
  'shoulder': (
    'Gomito dopo la spallata',
    'L’Orco ruota il busto dopo l’impatto e fa risalire il gomito verso lo sterno',
    'colpo',
  ),
  'innocent_object': (
    'Serratura chiusa',
    'Il Mimic nasconde lingua e denti dietro il coperchio e irrigidisce le assi',
    'scudo',
  ),
  'unstable_form': (
    'Cerniera disossata',
    'Il Mimic piega il corpo lungo la cerniera e ritrae la parte che stava per essere colpita',
    'movimento',
  ),
  'coordinated_assault': (
    'Morso dal lato del branco',
    'Il Warg segue l’apertura lasciata dal branco e affonda i canini nel fianco',
    'colpo',
  ),
  'drag': (
    'Trazione del garrese',
    'Il Warg chiude la bocca sul mantello e arretra usando tutto il peso delle zampe',
    'colpo',
  ),
  'massive_body': (
    'Massa sugli avambracci',
    'Il Golem avvicina i due avambracci di pietra fino a chiudere un muro davanti al nucleo',
    'scudo',
  ),
  'cracks': (
    'Crepe compresse',
    'Il Golem fa scorrere la ghiaia interna dentro le crepe del torace',
    'cura',
  ),
  'temporary_skeleton': (
    'Servitore di tibie',
    'Il Necromante assembla tibie e vertebre in un piccolo servitore osseo con Vita propria',
    'costrutto',
  ),
  'funeral_echo': (
    'Battito del cranio vuoto',
    'Il Necromante batte le dita nel cranio e scandisce il ritmo del proprio incantesimo',
    'richiamo',
  ),
  'dive_claw': (
    'Artigli della picchiata',
    'Il Grifone chiude le ali e porta entrambi gli artigli anteriori contro la spalla della preda',
    'colpo',
  ),
  'carry': (
    'Presa delle zampe posteriori',
    'Il Grifone aggancia il terreno con le zampe posteriori e solleva il petto fuori dalla traiettoria',
    'movimento',
  ),
  'defensive_wings': (
    'Ali sul becco',
    'Il Grifone incrocia le ali sopra il becco e sovrappone le penne più dure',
    'scudo',
  ),
  'maze_charge': (
    'Corna nel corridoio',
    'Il Minotauro allinea le corna al passaggio e carica tenendo i gomiti stretti',
    'colpo',
  ),
  'blind_fury': (
    'Zoccoli inchiodati',
    'Il Minotauro pianta gli zoccoli e tende i muscoli del collo dietro le corna',
    'scudo',
  ),
  'corridor_memory': (
    'Passo contato',
    'Il Minotauro ripercorre con gli zoccoli le distanze già misurate nel corridoio',
    'movimento',
  ),
  'mist_form': (
    'Costole di nebbia',
    'Il Vampiro disperde il bordo del busto in nebbia e lo ricompone sul lato opposto',
    'movimento',
  ),
  'charm': (
    'Voce sotto il respiro',
    'Il Vampiro fa coincidere le proprie parole con il respiro avversario per preparare il movimento',
    'richiamo',
  ),
  'elemental_body': (
    'Strati del nucleo',
    'L’Elementale comprime gli strati esterni attorno al nucleo fino a farne un involucro',
    'scudo',
  ),
  'elemental_blast': (
    'Scarico del nucleo',
    'L’Elementale concentra la propria sostanza in un foro e la espelle verso il bersaglio',
    'colpo',
  ),
  'instability': (
    'Distacco dello strato',
    'L’Elementale stacca una parte della superficie e si ritrae dietro la scia lasciata',
    'movimento',
  ),
  'bound_soul': (
    'Nodo attorno alla falange',
    'Il Lich avvolge un filo d’anima attorno alle proprie falangi e le serra sul bastone',
    'scudo',
  ),
  'death_seal': (
    'Sigillo di falangi',
    'Il Lich dispone falangi sul terreno formando un sigillo solido con Vita propria',
    'costrutto',
  ),
  'cataclysm': (
    'Fauci del cataclisma',
    'Il Drago Antico dilata la gola e scarica il respiro attraverso le fauci spalancate',
    'colpo',
  ),
  'furious_phase': (
    'Serratura delle scaglie',
    'Il Drago Antico contrae il dorso e blocca le scaglie una sopra l’altra',
    'scudo',
  ),
  'embrace_deform': (
    'Abbraccio delle ginocchia',
    'L’Uomo Fetale apre di scatto le braccia dalle ginocchia e colpisce con i gomiti',
    'colpo',
  ),
  'weep_of_fate': (
    'Singhiozzo ritmato',
    'L’Uomo Fetale batte il mento sulle ginocchia seguendo il ritmo dei propri singhiozzi',
    'richiamo',
  ),
  'neck_seal': (
    'Nodo sul collo aperto',
    'L’Uomo Decapitato stringe la pelle attorno al collo fino a chiudere la ferita',
    'cura',
  ),
  'bloody_swarm': (
    'Fiotti dalla gola recisa',
    'L’Uomo Decapitato comprime il torace ed espelle dalla gola una massa di sangue raggrumato',
    'colpo',
  ),
  'oculum_gaze': (
    'Pupille nella maschera',
    'Il Cultista allinea gli occhi viola della maschera e concentra lo sguardo sulla mano armata',
    'richiamo',
  ),
  'fate_pressure': (
    'Palmo del voto viola',
    'Il Cultista chiude le dita sul proprio sigillo e proietta dal palmo un impulso compatto',
    'colpo',
  ),
  'patalpa_generazione': (
    'Nido di polpa',
    'La Patalpa deposita polpa e semi in un nido con Vita propria',
    'costrutto',
  ),
  'patalpa_palata': (
    'Palata di radici',
    'La Patalpa scava sotto il terreno e fa risalire la palata di radici contro le gambe',
    'colpo',
  ),
  'patalpa_rigenerazione': (
    'Polpa sulla fenditura',
    'La Patalpa fa colare polpa fresca nella fenditura del proprio corpo',
    'cura',
  ),
  'backward_dash': (
    'Retromarcia del rinoceronte',
    'Il Rock Rhino spinge con le zampe anteriori e ritrae il petto dietro il corno',
    'movimento',
  ),
  'rocky_dash': (
    'Scatto di ghiaia',
    'Il Rock Rhino gratta il terreno con il corno e spinge in avanti il cumulo di ghiaia',
    'colpo',
  ),
  'backward_dash_i': (
    'Retromarcia del cucciolo',
    'Il Baby Rock Rhino si spinge all’indietro sulle zampe anteriori',
    'movimento',
  ),
  'rocky_dash_i': (
    'Ciottoli dal cornetto',
    'Il Baby Rock Rhino raccoglie ciottoli sul cornetto e li scaglia con uno scatto del collo',
    'colpo',
  ),
  'chorus_shatter': (
    'Denti del coro',
    'Le Facce Spezzate aprono insieme le bocche e proiettano schegge dai bordi delle maschere',
    'colpo',
  ),
  'memory_wail': (
    'Lamento a bocche alternate',
    'Il Coro alterna le bocche aperte per mantenere un ritmo continuo fra i singhiozzi',
    'richiamo',
  ),
  'mirror_birth': (
    'Placenta di vetro',
    'L’Utero di Specchio espelle una lastra chiusa su se stessa con Vita propria',
    'costrutto',
  ),
  'reflected_fear': (
    'Bordo dietro il riflesso',
    'L’Utero di Specchio ruota i frammenti del ventre per nascondere il proprio bordo esposto',
    'movimento',
  ),
  'candle_halo': (
    'Aureola di cera rappresa',
    'Il Santo delle Vene di Candela stende cera rappresa sulle costole',
    'scudo',
  ),
  'vein_benediction': (
    'Vene risaldate',
    'Il Santo fa risalire la cera calda nelle vene e richiude il taglio',
    'cura',
  ),
  'fate_brand': (
    'Marchio della stoppia',
    'Il Santo tende la mano e colpisce con la stoppia irrigidita del palmo',
    'colpo',
  ),
  'swamp_open': (
    'Argine della palude',
    'Opalus spinge fango e radici in un argine con Vita propria',
    'costrutto',
  ),
  'opal_reflect': (
    'Scaglie di opale inclinate',
    'Opalus inclina le placche di opale sul lato esposto',
    'scudo',
  ),
  'cobalt_bite': (
    'Morso di cobalto',
    'Opalus chiude le placche di cobalto della mandibola contro la preda',
    'colpo',
  ),
  'rust_toll': (
    'Rintocco della visiera',
    'Il Cavaliere batte la catena sulla campana della visiera per scandire la risposta',
    'richiamo',
  ),
  'chain_drag': (
    'Catena sotto il ginocchio',
    'Il Cavaliere passa la catena dietro il ginocchio del bersaglio e la ritrae con un colpo di polso',
    'colpo',
  ),
  'postea_vivisection_future': (
    'Bisturi della cicatrice futura',
    'Lo Scienziato di Postea fa scorrere il bisturi lungo il segno della cicatrice che sta osservando',
    'colpo',
  ),
  'postea_gene_leviante': (
    'Innesto sotto la sutura',
    'Lo Scienziato ricompone i lembi del proprio innesto e li serra con la pinza',
    'cura',
  ),
  'plomp_ball': (
    'Pallottola del Plomp',
    'Il Plomp Piccolo gonfia le guance e sputa una pallottola di gel',
    'colpo',
  ),
  'plomp_leech': (
    'Gel di ricucitura',
    'Il Plomp Piccolo raccoglie il gel disperso sotto il ventre e lo riassorbe',
    'cura',
  ),
  'plomp_ball_iii': (
    'Proiettile del Plomp adulto',
    'Il Plomp Adulto comprime il ventre e sputa un proiettile denso dal nucleo',
    'colpo',
  ),
  'plomp_leech_iii': (
    'Nucleo ricomposto',
    'Il Plomp Adulto avvolge il nucleo nel gel raccolto sul terreno',
    'cura',
  ),
  'undertow': (
    'Risacca sotto il tallone',
    'L’Elementale d’Acqua fa risalire un getto ricurvo dal terreno contro il tallone',
    'colpo',
  ),
  'little_tide': (
    'Paratia di risacca',
    'L’Elementale d’Acqua sovrappone ondate compatte in una paratia con Vita propria',
    'costrutto',
  ),
  'stone_cover': (
    'Lastra dal suolo',
    'L’Elementale di Terra stacca una lastra dal suolo e la tiene davanti al nucleo',
    'scudo',
  ),
  'earth_guard': (
    'Argine di terra',
    'L’Elementale di Terra compatta un anello di zolle in una barriera con Vita propria',
    'costrutto',
  ),
  'spark_jump': (
    'Salto della scintilla',
    'L’Elementale del Fulmine interrompe il contatto col terreno e ricompone la scintilla sul lato opposto',
    'movimento',
  ),
  'reaction_static': (
    'Carica fra le dita',
    'L’Elementale del Fulmine accumula una scarica tra due dita e la libera all’affondo',
    'colpo',
  ),
  'one_action_invisible': (
    'Sagoma ripiegata',
    'L’Elementale d’Ombra ripiega la propria sagoma nella zona già oscurata',
    'movimento',
  ),
  'shadow_backstab': (
    'Lama dalla sagoma',
    'L’Elementale d’Ombra allunga il bordo del braccio come una lama e colpisce dal fianco',
    'colpo',
  ),
  'blood_tax': (
    'Laccio di sangue',
    'L’Elementale del Sangue coagula un fiotto in un laccio e lo fa schioccare sul bersaglio',
    'colpo',
  ),
  'open_wound': (
    'Filo dalla ferita',
    'L’Elementale del Sangue tende un filo coagulato fra due dita e lo passa di taglio',
    'colpo',
  ),
  'red_transfer': (
    'Sangue ricondotto al nucleo',
    'L’Elementale del Sangue riassorbe il liquido disperso nel proprio nucleo',
    'cura',
  ),
  'type_switch_bite': (
    'Denti sotto il sorriso',
    'La Pelle Sorridente apre il sorriso in verticale e fa scattare i denti nascosti',
    'colpo',
  ),
  'blood_wrap': (
    'Pelle sul taglio',
    'La Pelle Sorridente sovrappone i lembi del corpo come una benda e chiude il taglio',
    'cura',
  ),
  'holy_rot': (
    'Sigillo della pagina consacrata',
    'Il Mago Zombie piega una pagina consacrata e la scaglia di taglio',
    'colpo',
  ),
  'demonic_decay': (
    'Legatura di carne',
    'Il Mago Zombie stringe sul proprio corpo le legature del grimorio',
    'scudo',
  ),
  'stitched_prayer': (
    'Preghiera fra i punti',
    'Il Monaco fa vibrare il respiro tra i punti della bocca cucita e scandisce il movimento',
    'richiamo',
  ),
  'threaded_curse': (
    'Ago del voto',
    'Il Monaco estrae un ago dal filo della bocca e lo proietta contro il bersaglio',
    'colpo',
  ),
  'dirty_halo': (
    'Aureola di croste',
    'L’Angelo Sporco avvicina le placche dell’aureola fino a schermare la testa',
    'scudo',
  ),
  'eyelid_fall': (
    'Palpebra sul nucleo',
    'L’Angelo Sporco richiude la grande palpebra intorno al nucleo luminoso',
    'cura',
  ),
  'blind_judgement': (
    'Ciglio della sentenza',
    'L’Angelo Sporco stacca un ciglio rigido e lo fa partire dalla palpebra come un dardo',
    'colpo',
  ),
  'greed_poison': (
    'Zanna sotto la moneta',
    'Il Ragno degli Obser Falsi nasconde la zanna sotto una moneta e la spinge dal basso',
    'colpo',
  ),
  'silk_trip': (
    'Nodo fra le monete',
    'Il Ragno lega i suoi Obser falsi con la seta e li dispone in un reticolo con Vita propria',
    'costrutto',
  ),
  'name_tax': (
    'Nome sputato nel palmo',
    'Il Pellegrino Senza Volto disegna un nome sulla mano e lo proietta con un impulso del palmo',
    'colpo',
  ),
  'map_walk': (
    'Passo sulla piega',
    'Il Pellegrino ripercorre col piede una piega della mappa e ritrae il corpo lungo quella linea',
    'movimento',
  ),
  'vapium_cut': (
    'Lama dalla cucitura',
    'La Bambola di Vapium fa uscire una lama sottile dalla cucitura del polso',
    'colpo',
  ),
  'fake_break': (
    'Snodo lasciato vuoto',
    'La Bambola lascia cedere uno snodo e lo ricompone dopo che il colpo lo ha attraversato',
    'movimento',
  ),
  'steam_counter': (
    'Sfiato del torace',
    'La Bambola di Vapium chiude le valvole del torace in preparazione della risposta',
    'richiamo',
  ),
  'oculum_mark': (
    'Incisione della pupilla',
    'L’Occhio Caduto contrae la pupilla e proietta una scheggia luminosa',
    'colpo',
  ),
  'source_sense': (
    'Riflesso sull’iride',
    'L’Occhio Caduto segue i riflessi dell’Oculum sull’iride per ritmare il proprio movimento',
    'richiamo',
  ),
  'gaze_punish': (
    'Scatto della palpebra',
    'L’Occhio Caduto fa scattare il bordo della palpebra contro il punto osservato',
    'colpo',
  ),
  'inverse_parry': (
    'Palmi rivolti al gomito',
    'Il Custode dalle Mani Inverse ruota i palmi verso i gomiti e chiude la guardia',
    'scudo',
  ),
  'grip_turn': (
    'Polso girato al contrario',
    'Il Custode aggancia con la mano inversa e ruota il polso mentre colpisce',
    'colpo',
  ),
  'hollow_blessing': (
    'Respiro nel cavo',
    'Il Santo Vuoto raccoglie il proprio respiro nella cavità del petto e richiude i lembi',
    'cura',
  ),
  'empty_shield': (
    'Bordo del petto vuoto',
    'Il Santo Vuoto avvicina i bordi ossei della cavità toracica fino a schermarla',
    'scudo',
  ),
  'thread_reaction_cut': (
    'Filo della sistole',
    'Cuore Filo tende il filo a ogni battito e lo lascia scattare contro il bersaglio',
    'colpo',
  ),
  'second_pulse': (
    'Seconda sistole',
    'Cuore Filo contrae una seconda camera del cuore e ricuce la membrana lesionata',
    'cura',
  ),
  'fear_light': (
    'Lume sotto il mento',
    'Il Lanterniere alza la lanterna sotto il mento e segue le ombre proiettate dalle braccia avversarie',
    'richiamo',
  ),
  'hidden_reveal': (
    'Luce tra le falangi',
    'Il Lanterniere schiude le dita intorno al lume e ritma l’affondo con i raggi che ne escono',
    'richiamo',
  ),
  'voice_eat': (
    'Parola sul bordo del vetro',
    'Lo Specchio Mangiavoce raccoglie la vibrazione di una parola e la espelle dal bordo come una scheggia',
    'colpo',
  ),
  'mirror_mute': (
    'Vetro senza eco',
    'Lo Specchio Mangiavoce stringe i bordi del vetro intorno alla propria superficie',
    'scudo',
  ),
  'lava_tears': (
    'Lacrime dal mento incandescente',
    'La Sentinella scuote il capo e lancia le lacrime di lava raccolte sotto il mento',
    'colpo',
  ),
  'fire_line': (
    'Fessura della fornace',
    'La Sentinella apre la fessura sul torace e vi concentra un getto rettilineo di fuoco',
    'colpo',
  ),
  'memory_erase': (
    'Bordo del ricordo',
    'L’Obliterato ritrae il contorno della propria sagoma prima dell’impatto',
    'movimento',
  ),
  'existence_cut': (
    'Taglio del contorno',
    'L’Obliterato tende il bordo del braccio fino a farne una lama opaca',
    'colpo',
  ),
  'lava_larva_bite': (
    'Mandibole della scoria',
    'La Larva di Lava apre la crosta sul muso e chiude le mandibole incandescenti',
    'colpo',
  ),
  'lava_larva_splash': (
    'Sputo di scoria liquida',
    'La Larva gonfia il ventre e sputa il materiale liquido custodito sotto la crosta',
    'colpo',
  ),
  'lava_heart_burst': (
    'Battito della caldera',
    'Il Cuore della Caldera comprime le camere interne ed espelle un fiotto di lava',
    'colpo',
  ),
  'lava_heart_fissure': (
    'Crosta della caldera',
    'Il Cuore della Caldera deposita scorie davanti al nucleo in una crosta con Vita propria',
    'costrutto',
  ),
  'necromancer_ash_bind': (
    'Legaccio di ceneri',
    'Il Necromante della Cenere intreccia ceneri e ossicini in un legaccio con Vita propria',
    'costrutto',
  ),
  'necromancer_soul_flame': (
    'Fiamma nel cranio',
    'Il Necromante della Cenere accende una fiamma nel cranio impugnato e la espelle dalle orbite',
    'colpo',
  ),
  'necromancer_obsidian_chain': (
    'Catena di vertebre nere',
    'Il Necromante d’Ossidiana incastra vertebre di vetro nero in una catena con Vita propria',
    'costrutto',
  ),
  'necromancer_black_sun': (
    'Sole dell’orbita cava',
    'Il Necromante d’Ossidiana contrae la sfera nera nella propria orbita e ne proietta un impulso',
    'colpo',
  ),
  'necromancer_hunger_mark': (
    'Unghia della fame',
    'Il Necromante della Fame allunga l’unghia e incide la guardia della preda',
    'colpo',
  ),
  'necromancer_last_feast': (
    'Carne ricucita dal rito',
    'Il Necromante della Fame comprime i lembi del proprio corpo nel cerchio del rito',
    'cura',
  ),
  'chairram_block': (
    'Spalliera sul viso',
    'L’Errante con la Sedia porta la spalliera davanti al viso e blocca le traverse',
    'scudo',
  ),
  'chairram_pin': (
    'Gamba della sedia',
    'L’Errante con la Sedia fa passare una gamba della sedia sotto la guardia e la spinge di punta',
    'colpo',
  ),
  'chairram_fall': (
    'Caduta della seduta',
    'L’Errante inclina la sedia e lascia che il proprio peso cada sopra la seduta contro il bersaglio',
    'colpo',
  ),
  'sewn_hum': (
    'Ronzio della bocca cucita',
    'L’Errante fa vibrare il filo della bocca e scandisce con il ronzio il proprio movimento',
    'richiamo',
  ),
  'sewn_thread': (
    'Filo strappato dal labbro',
    'L’Errante strappa un filo dal labbro e lo annoda in una rete con Vita propria',
    'costrutto',
  ),
  'sewn_open': (
    'Punti serrati',
    'L’Errante tende i punti della bocca e li riaccosta intorno alla ferita',
    'cura',
  ),
  'mirror_hand': (
    'Mano fuori dal bordo',
    'L’Errante Specchio fa sporgere dal bordo una mano piatta di vetro e la lancia in avanti',
    'colpo',
  ),
  'mirror_crack': (
    'Crepa rigirata',
    'L’Errante Specchio ruota il frammento danneggiato dietro quello integro',
    'scudo',
  ),
  'wetdoll_drip': (
    'Gocce dalla cucitura',
    'La Bambola Bagnata strizza il proprio ventre e proietta gocce dense dalla cucitura',
    'colpo',
  ),
  'wetdoll_grab': (
    'Stoffa sulle dita',
    'La Bambola Bagnata avvolge le proprie mani con la stoffa inzuppata',
    'scudo',
  ),
  'wetdoll_spill': (
    'Imbottitura risaldata',
    'La Bambola Bagnata riassorbe il liquido versato e riempie lo strappo nel ventre',
    'cura',
  ),
  'umbrella_thrust': (
    'Punta sotto il bavero',
    'L’Errante con Ombrello passa la punta sotto il bavero e spinge l’asta in avanti',
    'colpo',
  ),
  'umbrella_depart': (
    'Rotazione dell’ombrello',
    'L’Errante apre l’ombrello di lato e ruota dietro la sua tela',
    'movimento',
  ),
  'cap_bump': (
    'Testata del tappo',
    'Il Tappo con Zampe raccoglie le zampette e fa impattare il bordo rigido',
    'colpo',
  ),
  'cap_roll': (
    'Rotolata sul bordo',
    'Il Tappo si mette di taglio e rotola fuori dalla linea del colpo',
    'movimento',
  ),
  'cap_squeak': (
    'Fischio del sughero',
    'Il Tappo comprime il sughero e segue il proprio fischio per coordinare le zampette',
    'richiamo',
  ),
  'shoe_bite': (
    'Morso dalla tomaia',
    'Il Pesce Scarpa spalanca la tomaia e chiude i denti nascosti nella suola',
    'colpo',
  ),
  'shoe_splash': (
    'Spruzzo dal tacco',
    'Il Pesce Scarpa comprime l’acqua nel tacco e la espelle da un foro della suola',
    'colpo',
  ),
  'bowl_spin': (
    'Ciotola di taglio',
    'Il Gatto Ciotola ruota sulla base e colpisce con il bordo della ciotola',
    'colpo',
  ),
  'bowl_crack': (
    'Smaltatura serrata',
    'Il Gatto Ciotola comprime le crepe della ciotola attorno al corpo',
    'scudo',
  ),
  'candle_mark': (
    'Corno di stoppia',
    'Il Cervo Candela abbassa le corna di stoppia e le spinge in avanti',
    'colpo',
  ),
  'candle_run': (
    'Passo della cera',
    'Il Cervo Candela scivola sulla cera depositata dai propri zoccoli',
    'movimento',
  ),
  'candle_burst': (
    'Cera sul fianco',
    'Il Cervo Candela fa colare una fascia di cera sul fianco esposto',
    'scudo',
  ),
  'mud_charge': (
    'Corna di fango compatto',
    'Il Toro di Fango comprime le corna e carica con il collo basso',
    'colpo',
  ),
  'mud_throw': (
    'Zolla dal muso',
    'Il Toro di Fango infila il muso nel terreno e scaglia una zolla con il collo',
    'colpo',
  ),
  'window_bite': (
    'Morso della cornice',
    'Il Serpente Finestra chiude la mandibola lungo il bordo della cornice',
    'colpo',
  ),
  'window_pass': (
    'Passaggio nel proprio vetro',
    'Il Serpente Finestra ritrae le spire attraverso il centro della propria cornice',
    'movimento',
  ),
  'window_reflect': (
    'Vetro sulle spire',
    'Il Serpente Finestra allinea i frammenti della finestra lungo le proprie spire',
    'scudo',
  ),
  'fate_fairy_protection': (
    'Placca della fata',
    'Il Mini Fate Golem chiude la placca centrale davanti al proprio nucleo',
    'scudo',
  ),
  'matter_lance': (
    'Lancia dal braccio corto',
    'Il Mini Fate Golem comprime il braccio fino a farne una lancia e lo protende',
    'colpo',
  ),
  'enhanced_blow': (
    'Pugno della cerniera',
    'Il Mini Fate Golem fa scattare la cerniera del gomito per accelerare il pugno',
    'colpo',
  ),
  'fate_fairy_awaken': (
    'Nucleo della fata vigile',
    'Il Fate Golem allinea le piastre davanti al nucleo luminoso',
    'scudo',
  ),
  'matter_lance_iii': (
    'Lancia del golem adulto',
    'Il Fate Golem estrae una lunga lancia di materia dal proprio avambraccio',
    'colpo',
  ),
  'enhanced_blow_iii': (
    'Pugno a tre snodi',
    'Il Fate Golem fa scattare in sequenza spalla, gomito e polso',
    'colpo',
  ),
  'my_death_a_birth': (
    'Sacca degli eredi',
    'Mother Slime deposita una sacca gelatinosa con Vita propria fuori dal proprio ventre',
    'costrutto',
  ),
  'slime_liquidation_grab': (
    'Colata sulle braccia',
    'Mother Slime avvolge il proprio nucleo nella colata più spessa del ventre',
    'scudo',
  ),
  'ice_stomp': (
    'Zoccolo della brina',
    'Il Mammut Corazzato solleva la zampa e colpisce con lo zoccolo ricoperto di ghiaccio',
    'colpo',
  ),
  'mammoth_charge': (
    'Zanne allineate',
    'Il Mammut Corazzato allinea le zanne al busto della preda e abbassa il collo',
    'colpo',
  ),
  'idrax_molt': (
    'Muta sulle ferite',
    'Idrax abbandona lo strato lacerato della muta e richiude la pelle sottostante',
    'cura',
  ),
  'serpent_coil': (
    'Spire sull’addome',
    'Idrax avvolge le proprie spire intorno alla parte molle del corpo',
    'scudo',
  ),
  'nothing_random_fate_skill': (
    'Palmo del dado vuoto',
    'Notthing richiude il palmo sull’Oculum e lo proietta dalla mano riaperta',
    'colpo',
  ),
  'forgotten_encounter': (
    'Profilo dimenticato',
    'Notthing ritrae il bordo della sagoma lasciando il punto che l’avversario stava osservando',
    'movimento',
  ),
  'null_shift': (
    'Piega del contorno',
    'Notthing ripiega il contorno della sagoma attorno al proprio centro',
    'scudo',
  ),
  'fate_attack': (
    'Spigolo dell’occhio',
    'Il Ciclope del Fato concentra l’Oculum sul bordo della pupilla e lo lancia di taglio',
    'colpo',
  ),
  'fate_defense': (
    'Palpebra del Fato',
    'Il Ciclope del Fato chiude la palpebra corazzata sopra l’occhio',
    'scudo',
  ),
  'ocular_ray': (
    'Raggio dalla pupilla',
    'Il Ciclope del Fato restringe la pupilla e proietta un raggio rettilineo',
    'colpo',
  ),
  'fetal_throw': (
    'Lancio del pugno contratto',
    'Odor Ferroso scaglia in avanti il braccio raccolto contro il petto',
    'colpo',
  ),
  'spectral_claw': (
    'Artiglio fra le costole',
    'Odor Ferroso allunga le dita emerse fra le proprie costole e le richiude sulla preda',
    'colpo',
  ),
  'the_putrid': (
    'Crosta putrida',
    'Odor Ferroso compatta lo strato esterno del proprio corpo intorno alle ferite',
    'scudo',
  ),
  'sound_sight': (
    'Ascolto del cappello',
    'Mutant Fungus inclina il cappello e segue le vibrazioni lungo il gambo',
    'richiamo',
  ),
  'spore_alarm': (
    'Filamenti del sottosuolo',
    'Mutant Fungus intreccia filamenti nel terreno in una rete con Vita propria',
    'costrutto',
  ),
  'mix_illusioni': (
    'Cappello sovrapposto',
    'Psycho Funginius piega i bordi del cappello in strati protettivi',
    'scudo',
  ),
  'scomparire': (
    'Gambo nel micelio',
    'Psycho Funginius contrae il gambo e si ritrae fra i filamenti del micelio',
    'movimento',
  ),
  'percezione_pericoli': (
    'Brivido delle spore',
    'Psycho Funginius segue il tremolio delle spore attorno al cappello',
    'richiamo',
  ),
  'ormai_sei_mio': (
    'Uncino della presa',
    'Mavic protende le dita a uncino verso il fianco della preda',
    'colpo',
  ),
  'taglio_ad_x': (
    'Incrocio a X',
    'Mavic incrocia le braccia e apre le lame lungo due diagonali',
    'colpo',
  ),
  'mavic_blind_sight': (
    'Ascolto del polso',
    'Mavic inclina il capo e segue il ritmo del polso che impugna l’arma',
    'richiamo',
  ),
  'gabli_ball_attack': (
    'Palla dal ventre del Gabli',
    'Il Gabli comprime il ventre e lancia una palla compatta dalla bocca',
    'colpo',
  ),
  'pack_hunter': (
    'Richiamo fra le rocce',
    'Il Gabli batte le zampe sulle rocce e scandisce il momento del proprio affondo',
    'richiamo',
  ),
  'gabli_cry': (
    'Grido del cunicolo',
    'Il Gabli fa risuonare il grido nel cunicolo e si regola sull’eco di ritorno',
    'movimento',
  ),
  'armi_artigianali': (
    'Punta legata del Dooca',
    'Il Dooca serra le legature dell’arma artigianale e porta un affondo corto',
    'colpo',
  ),
  'osso_duro': (
    'Osso sullo sterno',
    'Il Dooca sovrappone le placche ossee davanti allo sterno',
    'scudo',
  ),
  'richiamo_dooca': (
    'Colpo di nocche',
    'Il Dooca batte le nocche sull’arma e segue quel ritmo per preparare la risposta',
    'richiamo',
  ),
  'cyclops_axe': (
    'Ascia dal gomito morto',
    'Il Ciclope Non Morto lascia cadere il gomito e fa risalire la lama dell’ascia',
    'colpo',
  ),
  'dead_eye': (
    'Palpebra sul taglio',
    'Il Ciclope Non Morto stringe la palpebra e ritrae l’occhio dietro l’arcata',
    'scudo',
  ),
  'grisfi_sprint': (
    'Scatto del Grisfi',
    'Il Grisfi allunga la falcata e piega il corpo verso il fianco libero',
    'movimento',
  ),
  'grisfi_endurance': (
    'Muscoli del garrese',
    'Il Grisfi tende il garrese e compatta il mantello sul fianco esposto',
    'scudo',
  ),
  'mount_bond': (
    'Respiro della cavalcatura',
    'Il Grisfi fa coincidere il proprio respiro con il ritmo del movimento',
    'richiamo',
  ),
  'shell_color': (
    'Seta sul guscio',
    'La Lumaca Pelosa intreccia la propria seta sul guscio',
    'scudo',
  ),
  'slow_hide': (
    'Ritiro sotto il guscio',
    'La Lumaca Pelosa ritrae il corpo sotto il bordo del guscio',
    'movimento',
  ),
  'ground_sense': (
    'Ascolto dell’anello',
    'Il Verme dei Fondali appoggia gli anelli anteriori al terreno e ne segue le vibrazioni',
    'richiamo',
  ),
  'deep_ambush': (
    'Mascella dal cunicolo',
    'Il Verme dei Fondali spinge la mandibola fuori dal proprio cunicolo',
    'colpo',
  ),
  'territory_duel': (
    'Argine del verme',
    'Il Verme dei Fondali ammucchia il terreno scavato in un argine con Vita propria',
    'costrutto',
  ),
  'coccodè': (
    'Becco sul sasso',
    'Il Polletto batte il becco su un sasso e scandisce la propria risposta',
    'richiamo',
  ),
  'friendly_follow': (
    'Passetti sotto l’ala',
    'Il Polletto raccoglie le zampette e si sposta dietro l’ala aperta',
    'movimento',
  ),
  'rock_eater': (
    'Crosta di pietre ingerite',
    'Sharp compatta le pietre custodite nel corpo contro la parte esposta',
    'scudo',
  ),
  'kind_mining': (
    'Raschiatura del minerale',
    'Sharp raschia una vena di minerale e la dispone in un riparo con Vita propria',
    'costrutto',
  ),
  'ogle_split': (
    'Sagoma ripiegata dell’Ogle',
    'Ogle ritrae il bordo della propria sagoma lasciando esposto soltanto il profilo',
    'movimento',
  ),
  'psycho_bark': (
    'Latrito dell’Ogle',
    'Ogle fa partire un latrito breve e segue il ritorno della vibrazione',
    'richiamo',
  ),
  'illusion_stun': (
    'Scatto del profilo',
    'Ogle tende il contorno della propria sagoma e lo spinge contro il bersaglio',
    'colpo',
  ),
  'rubber_orb': (
    'Rimbalzo dell’orbita gommosa',
    'Lumin comprime il corpo gommoso e si lascia rimbalzare sul fianco',
    'movimento',
  ),
  'food_share': (
    'Brizze di ricucitura',
    'Lumin riassorbe le briciole gommose staccate dal corpo',
    'cura',
  ),
  'fiaccolata': (
    'Punta della fiaccola',
    'Il Topino Avventuroso allunga la fiaccola sotto il bordo della guardia',
    'colpo',
  ),
  'cura_topesca': (
    'Benda del topino',
    'Il Topino Avventuroso stringe la fascia del proprio zainetto sulla ferita',
    'cura',
  ),
  'bell_fate_paralysis': (
    'Rintocco delle ali',
    'La Mosca Campana chiude le ali sul carapace e segue il rintocco prodotto',
    'richiamo',
  ),
  'critical_stun': (
    'Testata del batacchio',
    'La Mosca Campana fa scattare il capo come il batacchio di una campana',
    'colpo',
  ),
  'obra_element_birth': (
    'Nido dell’Obra',
    'Obra dispone la materia espulsa dal corpo in un nido con Vita propria',
    'costrutto',
  ),
  'obra_double_arrow': (
    'Freccia della seconda mano',
    'Obra tende il braccio posteriore e proietta una freccia dalla mano',
    'colpo',
  ),
  'obra_protective_reaction': (
    'Braccia sovrapposte',
    'Obra sovrappone le braccia davanti al proprio nucleo',
    'scudo',
  ),
  'runic_repulsion': (
    'Placca della runa',
    'Il Forest Rune Golem fa scorrere le piastre fino ad allineare la runa sul torace',
    'scudo',
  ),
  'destructive_punch': (
    'Pugno del sigillo inciso',
    'Il Forest Rune Golem concentra il sigillo sulle nocche e colpisce in avanti',
    'colpo',
  ),
  'grant_reaction': (
    'Ritmo della runa',
    'Il Forest Rune Golem fa pulsare la runa in accordo con il proprio movimento',
    'richiamo',
  ),
  'riproduzione_animalesca': (
    'Sagoma di radici',
    'Il Mistificatore Runico intreccia le radici in una sagoma animale con Vita propria',
    'costrutto',
  ),
  'follia_pura': (
    'Colpo della runa spezzata',
    'Il Mistificatore proietta dal palmo un frammento della runa che ha inciso',
    'colpo',
  ),
  'mistificazione_runica': (
    'Mantello di foglie runiche',
    'Il Mistificatore sovrappone le foglie incise sul proprio torace',
    'scudo',
  ),
  'bunny_death_heal': (
    'Pelo sulla ferita',
    'Bunnys tende il pelo attorno al taglio e ricompone i lembi',
    'cura',
  ),
  'bunny_heal': (
    'Leccata dei Bunnys',
    'Bunnys raccoglie il pelo strappato e lo preme contro la ferita',
    'cura',
  ),
  'knife_flurry_d4': (
    'Coltello dalla pinna',
    'Il Pesce Killer fa scattare il coltello fissato alla pinna contro il bersaglio',
    'colpo',
  ),
  'diminishing_stabs': (
    'Stoccata della coda',
    'Il Pesce Killer accompagna la rotazione della coda con una stoccata corta',
    'colpo',
  ),
  'axe_fin': (
    'Ascia della pinna',
    'Il Pesce Ascia ruota il corpo e colpisce con il bordo affilato della pinna',
    'colpo',
  ),
  'will_current': (
    'Coda controcorrente',
    'Il Pesce Ascia piega la coda contro la corrente e si sposta di lato',
    'movimento',
  ),
  'lettuce_throw': (
    'Foglia arrotolata del Ranu',
    'Ranu arrotola una foglia di lattuga e la scaglia con un colpo delle zampe',
    'colpo',
  ),
  'gentle_croak': (
    'Gracidio del Ranu',
    'Ranu gonfia la gola e segue il ritmo del proprio gracidio',
    'richiamo',
  ),
  'color_shift': (
    'Scaglie sovrapposte',
    'Il Pesce Alato Cromatico allinea le scaglie lungo il lato esposto',
    'scudo',
  ),
  'safe_current': (
    'Virata della pinna alata',
    'Il Pesce Alato Cromatico apre una pinna e vira fuori dalla traiettoria',
    'movimento',
  ),
  'mutated_bite': (
    'Morso della mandibola mutata',
    'Il Pesce Mutato ruota la mandibola storta e stringe i denti sul bersaglio',
    'colpo',
  ),
  'erratic_swim': (
    'Nuoto a scatti',
    'Il Pesce Mutato contrae la coda in due direzioni e ritrae il fianco',
    'movimento',
  ),
  'water_adaptation': (
    'Muco sulle branchie',
    'Il Pesce Mutato compatta il muco attorno alle branchie esposte',
    'scudo',
  ),
  'draconic_splash': (
    'Spruzzo delle scaglie',
    'La Pozzanghera Draconica comprime le scaglie sommerse e lancia uno spruzzo compatto',
    'colpo',
  ),
  'scale_reflection': (
    'Scaglie sull’acqua',
    'La Pozzanghera Draconica sovrappone le scaglie sulla propria superficie',
    'scudo',
  ),
  'crosty_shell': (
    'Bordo del guscio antico',
    'Crosty chiude il bordo del guscio attorno al proprio corpo',
    'scudo',
  ),
  'peaceful_hide': (
    'Ritiro del Crosty',
    'Crosty ritrae le estremità sotto il guscio e ruota il lato esposto',
    'movimento',
  ),
  'old_shell': (
    'Saldatura del guscio',
    'Crosty ricompone le placche consumate lungo il bordo del guscio',
    'cura',
  ),
  'obser_stash': (
    'Nido di Obser',
    'Agla ammucchia gli Obser custoditi in un riparo con Vita propria',
    'costrutto',
  ),
  'small_bite': (
    'Morso dell’Agla',
    'Agla chiude i piccoli denti sulla mano che si avvicina al suo nido',
    'colpo',
  ),
  'paffer_inflate': (
    'Gonfiamento delle branchie',
    'Paffer Axolotl gonfia le branchie e tende la pelle sul proprio fianco',
    'scudo',
  ),
  'water_rest': (
    'Acqua sulle branchie',
    'Paffer Axolotl raccoglie l’acqua fra le branchie e la fa scorrere sulle lesioni',
    'cura',
  ),
};
