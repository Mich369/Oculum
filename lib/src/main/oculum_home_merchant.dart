part of '../../main.dart';

const oculumStatGemNames = <String, String>{
  'resilienza': 'Gemma di Resilienza',
  'volonta': 'Gemma di Volontà',
  'materia': 'Gemma di Materia',
  'oculum': 'Gemma di Oculum',
};
const int oculumStatGemBaseCost = 3;
int oculumStatGemDieFaces(int stat) => max(1, max(0, stat) ~/ 3);
int oculumStatGemPrice(int stat) =>
    oculumStatGemBaseCost + 3 * (max(0, stat) ~/ 10);
bool oculumStatGemAvailable(Random random) => random.nextInt(4) == 0;

int oculumDropObserReward({
  required String subtraitId,
  required int rollTotal,
  required int level,
  required int dropBonus,
  required Random random,
}) {
  if (subtraitId != 'drop' || rollTotal <= 15) return 0;
  // Weights 26, 25, ... 1: low amounts are progressively more common.
  var ticket = random.nextInt(26 * 27 ~/ 2);
  for (var amount = 1; amount <= 26; amount++) {
    final weight = 27 - amount;
    if (ticket < weight) {
      return max(0, level).toInt() + max(0, dropBonus).toInt() + amount;
    }
    ticket -= weight;
  }
  throw StateError('Drop reward ticket outside its weighted range');
}

InventoryItem? oculumCreateTemporaryDropGem({
  required String subtraitId,
  required int naturalRoll,
  required bool usesOculum,
  required Map<String, int> stats,
  required Random random,
}) {
  if (subtraitId != 'drop' || naturalRoll < 19 || naturalRoll > 20) return null;
  final eligible = oculumStatGemNames.keys
      .where((key) => key != 'oculum' || usesOculum)
      .toList();
  final stat = eligible[random.nextInt(eligible.length)];
  final faces = oculumStatGemDieFaces(stats[stat] ?? 0);
  return InventoryItem(
    nome: '${oculumStatGemNames[stat]} temporanea',
    quantita: 1,
    peso: .1,
    statGemStat: stat,
    statGemDieFaces: faces,
    note:
        'Consumabile: recupera 1d$faces punti attuali. '
        'L’eccesso dura fino al riposo lungo. '
        'Resta nell’inventario finché non la usi.',
  );
}

int oculumMerchantShieldValue(int hp, int percent) =>
    (max(0, hp) * percent.clamp(35, 50) / 100).round();

int oculumMerchantDefenseValue(int materia) => 5 + 2 * max(0, materia);

int oculumMerchantAttackValue(int base, int will) =>
    max(0, base) + max(0, will) ~/ 2;

/// Tiro automatico del Vitalium Grezzo. Un 1 naturale e' un critico negativo:
/// puo' ridurre la cura, ma chi usa il risultato la limita sempre a zero.
int oculumRawVitaliumMedicineRoll({required int die, required int medicine}) {
  final total = die + medicine;
  return die == 1 ? -max(1, total.abs()) : total;
}

/// Gradi I-II: meta' del tiro; dal III: tiro intero. Mantiene il segno del
/// critico negativo, cosi' puo' annullare una cura ma non generare danno.
int oculumRawVitaliumMedicineBonus({
  required int grade,
  required int medicineRoll,
}) {
  if (grade >= 3) return medicineRoll;
  if (grade >= 1) return medicineRoll ~/ 2;
  return 0;
}

String oculumRawVitaliumRuleForGrade(int grade) {
  if (grade >= 3) {
    return 'Grado III+: attivo d30 + Medicina, tiro intero. Un 1 naturale può annullare la cura, mai fare danno.';
  }
  if (grade >= 2) {
    return 'Grado II: attivo d20 + Medicina, metà tiro. Un 1 naturale può annullare la cura, mai fare danno.';
  }
  if (grade >= 1) {
    return 'Grado I: attivo d10 + Medicina, metà tiro. Un 1 naturale può annullare la cura, mai fare danno.';
  }
  return 'Richiede Grado I per applicare il tiro automatico di Medicina.';
}

int oculumMerchantWeaponSkillDamage(int grade) => 5 + max(0, grade) * 10;

String oculumMerchantWeaponSkillName(String weaponName) {
  final lower = weaponName.toLowerCase();
  if (lower.contains('arco') || lower.contains('balestra')) {
    return 'Tiro di $weaponName';
  }
  if (lower.contains('martello') || lower.contains('mazza')) {
    return 'Schianto di $weaponName';
  }
  if (lower.contains('lancia') || lower.contains('picca')) {
    return 'Affondo di $weaponName';
  }
  if (lower.contains('ascia')) return 'Fendente di $weaponName';
  return 'Taglio di $weaponName';
}

String oculumMerchantWeaponSkillText(String weaponName, int grade) {
  final damage = oculumMerchantWeaponSkillDamage(grade);
  final nextDamage = damage + 5;
  return 'I/usi $weaponName: @Danni+$damage (1/4).\n'
      'II/@Danni+$nextDamage (2/4), scegli se spostare o esporre il bersaglio.\n'
      'III/@Danni+${nextDamage + 10} (3/4), il Master applica la conseguenza coerente con l arma.\n'
      'Al quarto uso la Skill va in recupero fino al turno successivo.';
}

/// Negoziante locale della scheda. Lo stock usa il salvataggio della scheda,
/// ma il suo identificatore di sessione lo rinnova solo dopo la chiusura e
/// riapertura dell'app: non cambia ad ogni rebuild o apertura del pannello.
extension _OculumHomeMerchant on _OculumHomePageState {
  int merchantGemStatValue(String key) => max(
    0,
    leggiNumero(switch (key) {
      'resilienza' => resilienzaController,
      'volonta' => volontaController,
      'materia' => materiaController,
      _ => oculumController,
    }),
  );

  void updateMerchantGemOffers() {
    for (final offer in merchantStock.where((o) => o['kind'] == 'stat_gem')) {
      final stat = merchantGemStatValue('${offer['stat']}');
      offer['cost'] = oculumStatGemPrice(stat);
      offer['dieFaces'] = oculumStatGemDieFaces(stat);
      offer['baseStat'] = stat;
    }
  }

  int merchantCharacterPower() {
    final stats = [
      leggiNumero(resilienzaController),
      leggiNumero(volontaController),
      leggiNumero(materiaController),
      leggiNumero(oculumController),
    ];
    return stats.fold<int>(0, (sum, value) => sum + max(0, value));
  }

  int merchantScaledValue(int base, {double strength = 1, int level = 0}) {
    final power = merchantCharacterPower();
    final tenStatSteps = power ~/ 10;
    final factor = 1 + tenStatSteps * 0.05 * strength;
    return max(1, (base * factor).round() + max(0, level) * 25);
  }

  int merchantTitleCost(int baseCost, {int level = 0}) =>
      merchantScaledValue(baseCost, level: level);

  Map<String, dynamic> _activeMerchantProfile() {
    for (final profile in merchantProfiles) {
      if ('${profile['id'] ?? ''}' == merchantActiveProfileId) return profile;
    }
    final profile = <String, dynamic>{
      'id': merchantActiveProfileId,
      'name': 'Mercante di fiducia',
      'stock': <Map<String, dynamic>>[],
    };
    merchantProfiles.add(profile);
    return profile;
  }

  void _saveActiveMerchantProfileStock() {
    _activeMerchantProfile()['stock'] = merchantStock
        .map((offer) => Map<String, dynamic>.from(offer))
        .toList(growable: true);
  }

  String get activeMerchantName => '${_activeMerchantProfile()['name']}';

  void switchMerchantProfile(String profileId) {
    if (profileId == merchantActiveProfileId) return;
    _saveActiveMerchantProfileStock();
    Map<String, dynamic>? target;
    for (final profile in merchantProfiles) {
      if ('${profile['id'] ?? ''}' == profileId) {
        target = profile;
        break;
      }
    }
    if (target == null) return;
    merchantActiveProfileId = profileId;
    final stock = target['stock'];
    merchantStock = stock is List
        ? stock
              .whereType<Map>()
              .map((offer) => Map<String, dynamic>.from(offer))
              .toList(growable: true)
        : <Map<String, dynamic>>[];
    merchantStockSessionId = merchantStock.isEmpty
        ? ''
        : merchantRuntimeSessionId;
    ensureMerchantStock();
    _saveActiveMerchantProfileStock();
    // ignore: invalid_use_of_protected_member
    setState(() {});
    programmaSalvataggio();
  }

  void createRandomMerchantProfile() {
    _saveActiveMerchantProfileStock();
    final profileId = 'merchant_${DateTime.now().microsecondsSinceEpoch}';
    merchantActiveProfileId = profileId;
    merchantStock = <Map<String, dynamic>>[];
    merchantStockSessionId = '';
    merchantProfiles.add(<String, dynamic>{
      'id': profileId,
      'name': 'Mercante ${merchantProfiles.length + 1}',
      'stock': <Map<String, dynamic>>[],
    });
    ensureMerchantStock();
    _saveActiveMerchantProfileStock();
    // ignore: invalid_use_of_protected_member
    setState(() {});
    programmaSalvataggio();
  }

  Widget merchantProfileControls() => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      PopupMenuButton<String>(
        tooltip: 'Torna da un mercante già incontrato',
        onSelected: switchMerchantProfile,
        itemBuilder: (context) => [
          for (final profile in merchantProfiles)
            PopupMenuItem<String>(
              value: '${profile['id']}',
              child: Text('${profile['name'] ?? 'Mercante'}'),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz),
              const SizedBox(width: 7),
              Text('Cambia mercante · ${merchantProfiles.length} salvati'),
            ],
          ),
        ),
      ),
      OutlinedButton.icon(
        onPressed: createRandomMerchantProfile,
        icon: const Icon(Icons.casino_outlined),
        label: const Text('Nuovo mercante'),
      ),
    ],
  );

  List<Map<String, dynamic>> ensureMerchantStock() {
    if (merchantStockSessionId == merchantRuntimeSessionId &&
        merchantStock.isNotEmpty) {
      updateMerchantGemOffers();
      ensureMerchantFoodOffers();
      _saveActiveMerchantProfileStock();
      return merchantStock;
    }
    final random = Random(
      monsterSpriteStableSeed(currentSheetScrollId()) ^
          DateTime.now().microsecondsSinceEpoch,
    );
    final rawVitaliumRule = oculumRawVitaliumRuleForGrade(
      max(0, leggiNumero(gradoController)),
    );
    merchantStock = <Map<String, dynamic>>[
      {
        'id': 'raw_vitalium',
        'name': 'Vitalium Grezzo',
        'cost': 13 + random.nextInt(7),
        'kind': 'raw_vitalium',
        'desc':
            'Consumabile: scegli quanto Oculum immettere e recuperi altrettanti HP. Se non hai Oculum, puoi alimentarlo spendendo 2 Materia e 2 Volontà per ogni punto. $rawVitaliumRule',
      },
      {
        'id': 'refined_vitalium',
        'name': 'Vitalium Ridefinito',
        'cost': 100 + random.nextInt(61),
        'kind': 'refined_vitalium',
        'desc':
            'Ripristina HP, integrità delle Art e statistiche attuali fino ai massimali; non crea Oculum se il massimale è zero.',
      },
      {
        'id': 'oculum_vial',
        'name': 'Fiala di Oculum',
        'cost': 6 + random.nextInt(3),
        'kind': 'oculum_vial',
        'desc': 'Consumabile: ricarica 1d4 Oculum.',
      },
      {
        'id': 'title_item',
        'name': 'Item Titolo',
        'cost': merchantTitleCost(75 + random.nextInt(46)),
        'kind': 'title_item',
        'damage': oculumMerchantAttackValue(6, leggiNumero(volontaController)),
        'defence': oculumMerchantDefenseValue(leggiNumero(materiaController)),
        'shield': oculumMerchantShieldValue(maxHp(), 35 + random.nextInt(16)),
        'desc': 'Scegli tu se diventa arma, armatura o scudo.',
      },
    ];
    for (final gem in oculumStatGemNames.entries) {
      if (!oculumStatGemAvailable(random)) continue;
      merchantStock.add(<String, dynamic>{
        'id': 'stat_gem_${gem.key}',
        'name': gem.value,
        'kind': 'stat_gem',
        'stat': gem.key,
        'remaining': 1,
        'desc':
            'Una gemma rara, consumabile. La sua forza è fissata quando la acquisti.',
      });
    }
    updateMerchantGemOffers();
    if (random.nextInt(12) == 0) {
      merchantStock.add(<String, dynamic>{
        'id': 'scroll_bone_prison',
        'name': 'Pergamena della Prigione d Ossa',
        'cost': 160,
        'kind': 'bone_prison_scroll',
        'desc':
            'Rara. Imprigiona il bersaglio, applica Stordito e infligge danno perforante.',
      });
    }
    // Catalogo > 200 oggetti: ogni scheda ne vede solo pochi, ma non pesca
    // sempre dagli stessi dieci nomi. Lo stock salvato resta invariato fino al
    // prossimo avvio dell'app.
    const materials = <String>[
      'bronzo rovinato',
      'ferro opaco',
      'rame freddo',
      'osso levigato',
      'legno nero',
      'acciaio vecchio',
      'vetro fumé',
      'pietra di fiume',
      'cuoio duro',
      'argento annerito',
      'corallo secco',
      'cenere compressa',
      'ottone consumato',
      'salice rosso',
      'sale nero',
      'vetro di luna',
    ];
    const weapons = <String>[
      'coltellino',
      'spada corta',
      'spada lunga',
      'sciabola',
      'stocco',
      'ascia',
      'mazza',
      'martello',
      'lancia',
      'picca',
      'alabarda',
      'falce',
      'frusta',
      'arco',
      'balestra',
      'guanti d arme',
    ];
    const protections = <String>[
      'scudo',
      'brocchiere',
      'mantello',
      'giubba',
      'corazza',
      'piastra',
      'elmo',
      'bracciale',
      'stivali',
      'anello',
      'cappuccio',
      'targa',
    ];
    final catalog = <({String name, bool weapon})>[
      for (final material in materials)
        for (final weapon in weapons)
          (name: '$weapon di $material', weapon: true),
      for (final material in materials)
        for (final protection in protections)
          (name: '$protection di $material', weapon: false),
    ];
    for (var i = 0; i < 8; i++) {
      final source = catalog[random.nextInt(catalog.length)];
      final grade = random.nextInt(40) == 0 ? 1 + random.nextInt(12) : 0;
      final protection = !source.weapon;
      final offensiveShield =
          protection &&
          (source.name.startsWith('scudo ') ||
              source.name.startsWith('brocchiere ')) &&
          random.nextBool();
      final weapon = source.weapon || offensiveShield;
      final damage = offensiveShield
          ? 2 + grade * 8
          : oculumMerchantAttackValue(6, leggiNumero(volontaController));
      final defence = oculumMerchantDefenseValue(
        leggiNumero(materiaController),
      );
      final shieldValue = oculumMerchantShieldValue(
        maxHp(),
        35 + random.nextInt(16),
      );
      final breakEffect = protection && random.nextInt(4) == 0
          ? <String, dynamic>{
              'duration': 2 + random.nextInt(2),
              'buffTarget': random.nextBool() ? 'difesa' : 'danni',
              'buffValue': 4 + grade * 2,
              'condition': random.nextBool() ? 'fortificato' : 'concentrato',
              'element': const [
                'fuoco',
                'cenere',
                'ghiaccio',
                'oblio',
              ][random.nextInt(4)],
              'resistance': 'Resistenza',
            }
          : <String, dynamic>{};
      merchantStock.add(<String, dynamic>{
        'id': 'merchant_${i}_${random.nextInt(1 << 31)}',
        'name': source.name,
        'cost': merchantTitleCost(
          grade == 0
              ? 25 + random.nextInt(51)
              : grade * (100 + random.nextInt(101)),
          level: grade,
        ),
        'kind': 'gear',
        'grade': grade,
        'weapon': weapon,
        'protection': protection,
        'shield': shieldValue,
        'damage': damage,
        'defence': defence,
        'quickReaction': grade > 0 && random.nextInt(9) == 0,
        if (breakEffect.isNotEmpty) 'shieldBreakEffect': breakEffect,
        'desc': grade == 0
            ? (breakEffect.isNotEmpty
                  ? 'Alla rottura dello scudo: ${breakEffect['condition']} e ${breakEffect['resistance']} a ${breakEffect['element']} per ${breakEffect['duration']} turni.'
                  : offensiveShield
                  ? 'Scudo offensivo.'
                  : 'Equipaggiamento del mercante.')
            : 'Oggetto graduato molto raro: richiede Grado $grade per essere equipaggiato.',
      });
    }
    merchantStockSessionId = merchantRuntimeSessionId;
    ensureMerchantFoodOffers();
    _saveActiveMerchantProfileStock();
    return merchantStock;
  }

  void ensureMerchantFoodOffers() {
    if (!merchantStock.any((offer) => offer['id'] == 'pawn')) {
      merchantStock.add(oculumPawnMerchantOffer());
    }
    const foods = <Map<String, dynamic>>[
      {
        'id': 'food_forest_demon',
        'name': 'Carne di Forest Demon',
        'cost': 12,
        'volonta': 2,
        'materia': 1,
      },
      {
        'id': 'food_mammuth',
        'name': 'Carne cotta di Mammuth',
        'cost': 15,
        'resilienza': 2,
        'materia': 1,
      },
      {
        'id': 'food_patalpa',
        'name': 'Patalpa Dolce',
        'cost': 10,
        'resilienza': 1,
        'volonta': 1,
        'materia': 1,
        'oculum': 1,
        'isMaterial': true,
      },
      {
        'id': 'herb_lunar',
        'name': 'Erba Lunare',
        'cost': 8,
        'oculum': 2,
        'volonta': 1,
        'isMaterial': true,
      },
      {
        'id': 'herb_iron',
        'name': 'Erba di Ferro',
        'cost': 8,
        'resilienza': 2,
        'materia': 1,
        'isMaterial': true,
      },
      {
        'id': 'herb_fourfold_root',
        'name': 'Radice delle Quattro Vene',
        'cost': 42,
        'restoreAllStats': true,
        'isMaterial': true,
        'desc':
            'Ripristina Resilienza, Volontà, Materia e Oculum attuali fino ai massimali della scheda. Non assegna Oculum a chi non lo possiede.',
      },
      {
        'id': 'ointment_millefoglie',
        'name': 'Unguento di Millefoglie',
        'cost': 30,
        'healHpPercent': 25,
        'cleanseNegativeConditions': true,
        'isMaterial': true,
        'desc':
            'Cura HP pari al 25% del massimale e rimuove le condizioni negative attive.',
      },
      {
        'id': 'balm_blue_bark',
        'name': 'Balsamo di Corteccia Azzurra',
        'cost': 24,
        'resistanceElement': 'ghiaccio',
        'resistancePreset': 'Resistenza',
        'condition': 'fortificato',
        'isMaterial': true,
        'desc':
            'Resistenza al Ghiaccio e Fortificato fino al Riposo Lungo o dopo 2 Riposi Brevi.',
      },
      {
        'id': 'pollen_reflexes',
        'name': 'Polline dei Riflessi',
        'cost': 18,
        'subtraitId': 'riflessi',
        'subtraitBonus': 2,
        'isMaterial': true,
        'desc':
            'Materiale da crafting utilizzabile: +2 Riflessi fino al Riposo Lungo o dopo 2 Riposi Brevi.',
      },
      {
        'id': 'ointment_focus',
        'name': 'Unguento della Concentrazione',
        'cost': 20,
        'subtraitId': 'concentrazione',
        'subtraitBonus': 2,
        'condition': 'concentrato',
        'isMaterial': true,
        'desc':
            'Materiale da crafting utilizzabile: +2 Concentrazione e Concentrato fino al Riposo Lungo o dopo 2 Riposi Brevi.',
      },
      {
        'id': 'alcohol_ash',
        'name': 'Liquore di Cenere',
        'cost': 6,
        'volonta': -2,
        'materia': 1,
        'oculum': 1,
        'alcohol': true,
      },
    ];
    for (final food in foods) {
      Map<String, dynamic>? existing;
      for (final candidate in merchantStock) {
        if (candidate['id'] == food['id']) {
          existing = candidate;
          break;
        }
      }
      final offer = existing ?? <String, dynamic>{};
      offer.addAll(food);
      offer['kind'] = 'food';
      offer['desc'] = merchantFoodOfferDescription(food);
      if (existing == null) merchantStock.add(offer);
    }
  }

  String merchantFoodOfferDescription(Map<String, dynamic> food) {
    final authored = '${food['desc'] ?? ''}'.trim();
    if (authored.isNotEmpty) return authored;
    final effect = food['isMaterial'] == true
        ? 'Materiale da crafting utilizzabile dall’inventario: gli effetti durano fino al Riposo Lungo o dopo 2 Riposi Brevi.'
        : food['alcohol'] == true
        ? 'Alcolico: ogni dose somma il malus di Volontà e i bonus fino al prossimo riposo.'
        : 'Cibo consumabile: bonus fino al prossimo riposo.';
    final bonuses = ['resilienza', 'volonta', 'materia', 'oculum']
        .where(food.containsKey)
        .map(
          (key) =>
              '$key ${readIntValue(food[key]) >= 0 ? '+' : ''}${food[key]}',
        )
        .join(', ');
    return '$effect${bonuses.isEmpty ? '' : ' $bonuses.'}';
  }

  String merchantOfferDescription(Map<String, dynamic> offer) {
    if (offer['kind'] == 'stat_gem') {
      final stat = '${offer['stat']}';
      final faces = readIntValue(offer['dieFaces'], fallback: 1);
      return '${readIntValue(offer['remaining']) > 0 ? 'Disponibile: 1' : 'Esaurita'} · Consumabile: recupera punti attuali di ${oculumStatGemNames[stat]?.replaceFirst('Gemma di ', '') ?? stat} di 1d$faces. Eccesso fino al riposo lungo. Potenza fissata all acquisto. Prezzo: 3 Obser +3 ogni 10 punti di questa statistica.';
    }
    if ('${offer['kind'] ?? ''}' == 'raw_vitalium') {
      return 'Consumabile: scegli quanto Oculum immettere; recuperi altrettanti HP. Se non hai Oculum, paghi 2 Materia e 2 Volontà per punto. ${oculumRawVitaliumRuleForGrade(max(0, leggiNumero(gradoController)))}';
    }
    if ('${offer['kind'] ?? ''}' == 'gear' && readBoolValue(offer['weapon'])) {
      final grade = readIntValue(offer['grade']);
      return '${offer['desc'] ?? ''}\nSkill: ${oculumMerchantWeaponSkillName('${offer['name'] ?? ''}')} — +${oculumMerchantWeaponSkillDamage(grade)} danni${grade > 0 ? ' (scala +10 per Grado)' : ''}.';
    }
    return '${offer['desc'] ?? ''}';
  }

  CharacterSkill merchantWeaponSkill(InventoryItem item) {
    final grade = max(item.gradoOggetto, item.gradoRichiesto);
    final name = oculumMerchantWeaponSkillName(item.nome);
    final text = oculumMerchantWeaponSkillText(item.nome, grade);
    return CharacterSkill(
      nome: name,
      tipo: 'Skill arma del Negoziante',
      costo: '1 azione',
      cooldown: 'Recupero dopo 4 usi',
      descrizione: text,
      danni: oculumMerchantWeaponSkillDamage(grade),
      equipaggiata: true,
      forme: <CharacterSkillForm>[
        CharacterSkillForm(
          nome: 'Forma I',
          tipo: 'Skill arma del Negoziante',
          costo: '1 azione',
          cooldown: 'Recupero dopo 4 usi',
          descrizione: text,
        ),
      ],
    );
  }

  Widget merchantQuickPanel() {
    final stock = ensureMerchantStock();
    return gothicPanel(
      borderColor: tertiaryColor.withValues(alpha: .7),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedBackgroundColor: const Color(0xFF151019),
          backgroundColor: const Color(0xFF0D1017),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onExpansionChanged: (open) {
            // ignore: invalid_use_of_protected_member
            setState(() => merchantIsOpen = open);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFC4863C), Color(0xFF442315)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFE6D8BD)),
            ),
            child: const Icon(Icons.storefront_outlined, color: Colors.white),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  activeMerchantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),
              Text(
                '${leggiNumero(obserController)} O',
                style: const TextStyle(
                  color: Color(0xFFFFD977),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          subtitle: Text(
            t(
              'Bancarella personale · puoi tornare ai mercanti già incontrati.',
              'Personal stall · revisit merchants you have already met.',
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          children: [
            merchantProfileControls(),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed:
                    merchantDustPurchasedSinceLongRest ||
                        leggiNumero(obserController) < 20
                    ? null
                    : buyAscensionDustFromMerchant,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  merchantDustPurchasedSinceLongRest
                      ? t(
                          'Dust acquistata · disponibile dopo il Riposo Lungo',
                          'Dust purchased · available after a Long Rest',
                        )
                      : t(
                          '20 Obser → 1 Ascension Dust · 1 per Riposo Lungo',
                          '20 Obser → 1 Ascension Dust · 1 per Long Rest',
                        ),
                ),
              ),
            ),
            for (final offer in stock)
              Container(
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF18151C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: readIntValue(offer['grade']) > 0
                        ? const Color(0xFFFFC35B).withValues(alpha: .72)
                        : Colors.white24,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    '${offer['name']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    merchantOfferDescription(offer),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  trailing: FilledButton(
                    onPressed:
                        (offer['kind'] == 'stat_gem' &&
                                readIntValue(offer['remaining']) <= 0) ||
                            leggiNumero(obserController) <
                                readIntValue(offer['cost'])
                        ? null
                        : () => buyMerchantOffer(offer),
                    child: Text('${offer['cost']} O'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> showMerchantDialog() async {
    final stock = ensureMerchantStock();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          backgroundColor: const Color(0xFF0D0C13),
          title: Text('Negoziante', style: TextStyle(color: tertiaryColor)),
          content: SizedBox(
            width: min(620, MediaQuery.sizeOf(context).width * .94),
            height: min(560, MediaQuery.sizeOf(context).height * .68),
            child: ListView.builder(
              itemCount: stock.length,
              itemBuilder: (context, index) {
                final offer = stock[index];
                final cost = readIntValue(offer['cost']);
                return ListTile(
                  title: Text(
                    '${offer['name']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    merchantOfferDescription(offer),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: FilledButton(
                    onPressed:
                        (offer['kind'] == 'stat_gem' &&
                                readIntValue(offer['remaining']) <= 0) ||
                            leggiNumero(obserController) < cost
                        ? null
                        : () async {
                            await buyMerchantOffer(offer);
                            if (mounted) refresh(() {});
                          },
                    child: Text('$cost O'),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Chiudi', 'Close')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> buyMerchantOffer(Map<String, dynamic> offer) async {
    if (offer['kind'] == 'stat_gem') {
      updateMerchantGemOffers();
      if (readIntValue(offer['remaining']) <= 0) return;
    }
    final cost = readIntValue(offer['cost']);
    if (leggiNumero(obserController) < cost) return;
    final kind = '${offer['kind'] ?? ''}';
    String titleType = '';
    InventoryItem? purchasedPawn;
    if (kind == 'title_item') {
      titleType =
          await showDialog<String>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('Scegli il tuo Item Titolo'),
              children: [
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'arma'),
                  child: const Text('Arma'),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'armatura'),
                  child: const Text('Armatura'),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'scudo'),
                  child: const Text('Scudo'),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'scudo_offensivo'),
                  child: const Text('Scudo offensivo'),
                ),
              ],
            ),
          ) ??
          '';
      if (titleType.isEmpty) return;
    }
    // ignore: invalid_use_of_protected_member
    // ignore: invalid_use_of_protected_member
    setState(() {
      obserController.text = (leggiNumero(obserController) - cost).toString();
      final item = merchantItemFromOffer(offer, titleType: titleType);
      if (kind == 'pawn') purchasedPawn = item;
      inventario.add(item);
      if (kind == 'stat_gem') offer['remaining'] = 0;
      if (item.arma) {
        final weaponSkill = merchantWeaponSkill(item);
        if (!skills.any((skill) => skill.nome == weaponSkill.nome)) {
          skills.add(weaponSkill);
        }
      }
      risultato = 'Negoziante: hai speso $cost Obser per ${item.nome}.';
      aggiungiLog(risultato);
    });
    _saveActiveMerchantProfileStock();
    programmaSalvataggio();
    if (purchasedPawn != null) await activatePawnItem(purchasedPawn!);
  }

  /// Il mercante paga circa un sesto del valore stimato: utile, ma spilorcio.
  int merchantSaleValue(InventoryItem item) {
    if (item.craftData['scroll'] is Map) {
      final data = item.craftData['scroll'] as Map;
      return max(1, oculumScrollValue(readIntValue(data['grade'])) ~/ 6) *
          max(1, item.quantita);
    }
    final grade = max(item.gradoOggetto, item.gradoRichiesto);
    final rawValue =
        18 +
        item.bonusDanno * 8 +
        item.bonusDifesa * 10 +
        item.bonusScudo * 3 +
        item.bonusScudoOculum * 12 +
        grade * grade * 90;
    return max(1, rawValue ~/ 6) * max(1, item.quantita);
  }

  void sellInventoryItemToMerchant(InventoryItem item) {
    if (!merchantIsOpen || !inventario.contains(item)) return;
    final payment = merchantSaleValue(item);
    // ignore: invalid_use_of_protected_member
    setState(() {
      if (item.equipaggiata) {
        applicaScudoItemAttuale(item, -1);
        item.equipaggiata = false;
      }
      inventario.remove(item);
      obserController.text = (leggiNumero(obserController) + payment)
          .toString();
      risultato = 'Negoziante: hai venduto ${item.nome} per $payment Obser.';
      aggiungiLog(risultato);
    });
    _saveActiveMerchantProfileStock();
    programmaSalvataggio();
  }

  void buyAscensionDustFromMerchant() {
    if (merchantDustPurchasedSinceLongRest ||
        leggiNumero(obserController) < 20) {
      return;
    }
    // ignore: invalid_use_of_protected_member
    setState(() {
      obserController.text = (leggiNumero(obserController) - 20).toString();
      ascensionDustController.text = (leggiNumero(ascensionDustController) + 1)
          .toString();
      merchantDustPurchasedSinceLongRest = true;
      risultato = 'Negoziante: 20 Obser convertiti in 1 Ascension Dust.';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  InventoryItem merchantItemFromOffer(
    Map<String, dynamic> offer, {
    String titleType = '',
  }) {
    if (offer['kind'] == 'pawn') return oculumPawnInventoryItem();
    final kind = '${offer['kind'] ?? ''}';
    if (kind == 'food') {
      final effects = <String, dynamic>{
        for (final key in [
          'resilienza',
          'volonta',
          'materia',
          'oculum',
          'alcohol',
          'restoreAllStats',
          'healHpPercent',
          'cleanseNegativeConditions',
          'resistanceElement',
          'resistancePreset',
          'subtraitId',
          'subtraitBonus',
          'condition',
        ])
          if (offer.containsKey(key)) key: offer[key],
      };
      return InventoryItem(
        nome: '${offer['name']}',
        peso: offer['isMaterial'] == true ? .05 : .25,
        quantita: 1,
        note: '${offer['desc']}',
        monsterLoot: <String, dynamic>{
          'food': effects,
          if (offer['isMaterial'] == true) 'material': true,
        },
      );
    }
    if (kind == 'stat_gem') {
      final stat = '${offer['stat']}';
      if (!oculumStatGemNames.containsKey(stat)) {
        throw ArgumentError('Statistica della gemma sconosciuta');
      }
      final faces = max(
        1,
        readIntValue(
          offer['dieFaces'],
          fallback: oculumStatGemDieFaces(merchantGemStatValue(stat)),
        ),
      );
      return InventoryItem(
        nome: oculumStatGemNames[stat]!,
        peso: .1,
        quantita: 1,
        statGemStat: stat,
        statGemDieFaces: faces,
        note:
            'Consumabile: recupera punti attuali di ${oculumStatGemNames[stat]!.replaceFirst('Gemma di ', '')} di 1d$faces. Una gemma, un solo tiro. Eccesso fino al riposo lungo.',
      );
    }
    if (kind == 'raw_vitalium') {
      return InventoryItem(
        nome: 'Vitalium Grezzo',
        peso: .1,
        quantita: 1,
        note:
            'Consumabile: scegli quanto Oculum immettere e recuperi altrettanti HP. Se non hai Oculum, paghi 2 Materia e 2 Volontà per punto. ${oculumRawVitaliumRuleForGrade(max(0, leggiNumero(gradoController)))}',
      );
    }
    if (kind == 'refined_vitalium') {
      return InventoryItem(
        nome: 'Vitalium Ridefinito',
        peso: .2,
        quantita: 1,
        note:
            'Consumabile: ripristina HP, Resilienza, Volontà, Materia e Oculum attuali fino ai massimali e l’integrità delle Art. Non crea Oculum se il massimale è zero.',
      );
    }
    if (kind == 'oculum_vial') {
      return InventoryItem(
        nome: 'Fiala di Oculum',
        peso: .1,
        quantita: 1,
        note: 'Consumabile: ricarica 1d4 Oculum.',
      );
    }
    if (kind == 'bone_prison_scroll') {
      return InventoryItem(
        nome: 'Pergamena della Prigione d Ossa',
        peso: .1,
        quantita: 1,
        note:
            'Usabile: infligge 12 danni perforanti e applica Stordito per 1 turno al bersaglio della scheda attiva.',
      );
    }
    final grade = readIntValue(offer['grade']);
    final isTitle = kind == 'title_item';
    final weapon = isTitle
        ? titleType == 'arma' || titleType == 'scudo_offensivo'
        : readBoolValue(offer['weapon']);
    final protects = isTitle
        ? titleType != 'arma'
        : readBoolValue(offer['protection'], fallback: !weapon);
    final shield = isTitle
        ? titleType == 'scudo' || titleType == 'scudo_offensivo'
        : protects;
    return InventoryItem(
      nome: isTitle
          ? 'Item Titolo — ${titleType.replaceAll('_', ' ')}'
          : '${offer['name']}',
      peso: 1.2,
      quantita: 1,
      note: isTitle
          ? 'Oggetto scelto dal Negoziante.'
          : weapon
          ? '${offer['desc']}\nSkill: ${oculumMerchantWeaponSkillName('${offer['name'] ?? ''}')}. ${oculumMerchantWeaponSkillText('${offer['name'] ?? ''}', grade)}'
          : '${offer['desc']}',
      arma: weapon,
      protegge: protects,
      bonusDanno: weapon && protects
          ? (isTitle
                ? 2
                : readIntValue(offer['damage'], fallback: 2 + grade * 8))
          : weapon
          ? max(
              6,
              readIntValue(
                offer['damage'],
                fallback: oculumMerchantAttackValue(
                  6,
                  leggiNumero(volontaController),
                ),
              ),
            )
          : 0,
      bonusDifesa: !protects
          ? 0
          : max(
              5,
              readIntValue(
                offer['defence'],
                fallback: oculumMerchantDefenseValue(
                  leggiNumero(materiaController),
                ),
              ),
            ),
      bonusScudo: protects
          ? readIntValue(
              offer['shield'],
              fallback: oculumMerchantShieldValue(maxHp(), 40),
            )
          : 0,
      bonusScudoIncludeGrado: true,
      bonusScudoOculum: grade >= 3 && shield ? 4 + grade * 3 : 0,
      gradoOggetto: grade,
      gradoRichiesto: grade,
      elementoDanno: grade >= 2 ? 'Oculum' : 'Fisico',
      buff: readBoolValue(offer['quickReaction'])
          ? '@ReazioneVeloce+1'
          : grade >= 3 && shield
          ? '@SchivateOculum+1'
          : '',
      effettoRotturaScudo: offer['shieldBreakEffect'] is Map
          ? Map<String, dynamic>.from(offer['shieldBreakEffect'])
          : <String, dynamic>{},
    );
  }

  int merchantHerbalSubtraitBonus(String subtraitId) => merchantHerbalEffects
      .where(
        (effect) =>
            effect['type'] == 'subtrait_bonus' &&
            effect['subtraitId'] == subtraitId &&
            readIntValue(effect['shortRestsRemaining']) > 0,
      )
      .fold<int>(0, (sum, effect) => sum + readIntValue(effect['value']));

  int merchantHerbalStatBonus(String statId) => merchantHerbalEffects
      .where(
        (effect) =>
            effect['type'] == 'stat_bonus' &&
            effect['statId'] == statId &&
            readIntValue(effect['shortRestsRemaining']) > 0,
      )
      .fold<int>(0, (sum, effect) => sum + readIntValue(effect['value']));

  Map<String, dynamic>? merchantCraftedHerbalOffer(String itemName) {
    final offerId = switch (itemName.trim()) {
      'Radice delle Quattro Vene' => 'herb_fourfold_root',
      'Unguento di Millefoglie' => 'ointment_millefoglie',
      'Balsamo di Corteccia Azzurra' => 'balm_blue_bark',
      'Polline dei Riflessi' => 'pollen_reflexes',
      'Unguento della Concentrazione' => 'ointment_focus',
      _ => '',
    };
    if (offerId.isEmpty) return null;
    for (final offer in ensureMerchantStock()) {
      if (offer['id'] == offerId) return offer;
    }
    return null;
  }

  bool isMerchantConsumable(InventoryItem item) =>
      item.craftData['pawn'] == true ||
      item.craftData['scroll'] is Map ||
      item.monsterLoot['food'] is Map ||
      oculumStatGemNames.containsKey(item.statGemStat) ||
      const <String>{
        'Vitalium Grezzo',
        'Vitalium Ridefinito',
        'Fiala di Oculum',
        'Pergamena della Prigione d Ossa',
        'Pinna di Pesce Alato',
      }.contains(item.nome.trim());

  Future<void> useMerchantConsumable(InventoryItem item) async {
    if (!inventario.contains(item) ||
        !isMerchantConsumable(item) ||
        item.quantita <= 0) {
      return;
    }
    if (item.craftData['pawn'] == true) {
      await activatePawnItem(item);
      return;
    }
    if (item.craftData['scroll'] is Map) {
      await useScrollAbility(
        Map<String, dynamic>.from(item.craftData['scroll'] as Map),
        item: item,
      );
      return;
    }
    if (item.monsterLoot['food'] is Map) {
      final food = item.monsterLoot['food'] as Map;
      final hasTimedHerbalEffect =
          food['resistanceElement'] != null ||
          food['subtraitId'] != null ||
          food['condition'] != null ||
          food['isMaterial'] == true ||
          item.nome.startsWith('Erba ') ||
          item.nome.startsWith('Polline ') ||
          item.nome.startsWith('Unguento ') ||
          item.nome.startsWith('Balsamo ');
      if (food['restoreAllStats'] == true ||
          readIntValue(food['healHpPercent']) > 0 ||
          food['cleanseNegativeConditions'] == true ||
          hasTimedHerbalEffect) {
        final effects = <String>[];
        // ignore: invalid_use_of_protected_member
        setState(() {
          if (food['restoreAllStats'] == true) {
            refullaStatsAttuali();
            effects.add('statistiche attuali ripristinate');
          }
          final healPercent = readIntValue(food['healHpPercent']);
          if (healPercent > 0) {
            final hp = hpCorrenti();
            final recovery = (maxHp() * healPercent / 100).ceil();
            currentHpController.text = min(maxHp(), hp + recovery).toString();
            effects.add('+$recovery HP');
          }
          if (food['cleanseNegativeConditions'] == true) {
            final removed = removeNegativeConditionsForVulnerabilityReset();
            effects.add('$removed condizioni negative rimosse');
          }
          if (food['resistanceElement'] != null) {
            merchantHerbalEffects.add(<String, dynamic>{
              'type': 'resistance',
              'element': oculumNormalizeElementId(
                '${food['resistanceElement']}',
              ),
              'preset': canonicalDamageModifierName(
                '${food['resistancePreset'] ?? 'Resistenza'}',
              ),
              'shortRestsRemaining': 2,
              'source': item.nome,
            });
            effects.add(
              'resistenza a ${elementDisplayName('${food['resistanceElement']}')}',
            );
          }
          for (final statId in ['resilienza', 'volonta', 'materia', 'oculum']) {
            final value = readIntValue(food[statId]);
            if (value == 0 || (statId == 'oculum' && oculumTotale() <= 0)) {
              continue;
            }
            merchantHerbalEffects.add(<String, dynamic>{
              'type': 'stat_bonus',
              'statId': statId,
              'value': value,
              'shortRestsRemaining': 2,
              'source': item.nome,
            });
            effects.add('$statId ${value >= 0 ? '+' : ''}$value');
          }
          final subtraitId = '${food['subtraitId'] ?? ''}'.trim();
          final subtraitBonus = readIntValue(food['subtraitBonus']);
          if (subtraitId.isNotEmpty && subtraitBonus != 0) {
            merchantHerbalEffects.add(<String, dynamic>{
              'type': 'subtrait_bonus',
              'subtraitId': subtraitId,
              'value': subtraitBonus,
              'shortRestsRemaining': 2,
              'source': item.nome,
            });
            effects.add('+$subtraitBonus $subtraitId');
            invalidateHiddenEyeDerivedCaches();
          }
          final condition = '${food['condition'] ?? ''}'.trim();
          if (condition.isNotEmpty) {
            applyCondition(
              condition,
              duration: 2,
              durationType: OculumConditionDurationType.rests,
              tickTrigger: OculumConditionTickTrigger.none,
              source: 'Erba ${item.nome}',
            );
            effects.add(condition);
          }
          item.quantita--;
          if (item.quantita <= 0) inventario.remove(item);
          invalidateDerivedDataCaches();
          risultato =
              '${item.nome}: ${effects.join(', ')}. Gli effetti temporanei durano fino al Riposo Lungo o dopo 2 Riposi Brevi.';
          aggiungiLog(risultato);
        });
        programmaSalvataggio();
        return;
      }
      // ignore: invalid_use_of_protected_member
      setState(() {
        tempResilienza += readIntValue(food['resilienza']);
        tempVolonta += readIntValue(food['volonta']);
        tempMateria += readIntValue(food['materia']);
        final oculumBonus = oculumTotale() > 0
            ? readIntValue(food['oculum'])
            : 0;
        tempOculum += oculumBonus;
        for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
          consumedFoodBonuses[key] =
              (consumedFoodBonuses[key] ?? 0) +
              (key == 'oculum' ? oculumBonus : readIntValue(food[key]));
        }
        item.quantita--;
        if (item.quantita <= 0) inventario.remove(item);
        invalidateDerivedDataCaches();
        risultato =
            '${item.nome}: bonus consumabile applicato; dura fino al prossimo riposo.';
        aggiungiLog(risultato);
      });
      programmaSalvataggio();
      return;
    }
    if (oculumStatGemNames.containsKey(item.statGemStat)) {
      final faces = max(1, item.statGemDieFaces);
      final roll = Random().nextInt(faces) + 1;
      // ignore: invalid_use_of_protected_member
      setState(() {
        final key = item.statGemStat;
        final controller = currentStatController(key);
        final maximum = currentStatNaturalControllerMax(key);
        final normal = key == 'oculum'
            ? currentTemporaryOculumState().normalCurrent
            : readIntValue(controller.text);
        final next = normal + roll;
        statGemOverflow[key] = max(statGemOverflow[key] ?? 0, next - maximum);
        if (key == 'oculum') {
          final current = currentTemporaryOculumState();
          applyTemporaryOculumState(
            TemporaryOculumState(
              normalCurrent: next,
              temporary: current.temporary,
              rollsRemaining: current.rollsRemaining,
            ),
          );
        } else {
          controller.text = next.toString();
          syncVisibleCurrentStatEditor(key);
          invalidateHiddenEyeDerivedCaches();
        }
        item.quantita--;
        if (item.quantita <= 0) inventario.remove(item);
        risultato =
            '${item.nome}: 1d$faces = $roll. Recuperati $roll punti; l’eccesso dura fino al riposo lungo.';
        aggiungiLog(risultato);
      });
      programmaSalvataggio();
      return;
    }
    var amount = 0;
    var payWithCoreStats = false;
    if (item.nome.trim() == 'Vitalium Grezzo') {
      final available = max(0, leggiNumero(currentOculumController));
      payWithCoreStats = available <= 0;
      final affordable = payWithCoreStats
          ? min(
                  leggiNumero(currentMateriaController),
                  leggiNumero(currentVolontaController),
                ) ~/
                2
          : available;
      if (affordable <= 0) {
        risultato = payWithCoreStats
            ? 'Vitalium Grezzo: servono almeno 2 Materia e 2 Volontà per usarlo senza Oculum.'
            : 'Vitalium Grezzo: non hai Oculum da immettere.';
        aggiungiLog(risultato);
        return;
      }
      final input = TextEditingController(text: '1');
      amount =
          await showDialog<int>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Vitalium Grezzo'),
              content: TextField(
                controller: input,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: payWithCoreStats
                      ? 'Unità da alimentare · costo 2 Materia + 2 Volontà ciascuna (1–$affordable)'
                      : 'Oculum da immettere (1–$available)',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    readIntValue(input.text).clamp(1, affordable),
                  ),
                  child: const Text('Usa'),
                ),
              ],
            ),
          ) ??
          0;
      input.dispose();
      if (amount <= 0) return;
    }
    // ignore: invalid_use_of_protected_member
    setState(() {
      switch (item.nome.trim()) {
        case 'Vitalium Grezzo':
          final grade = max(0, leggiNumero(gradoController));
          final medicineDieFaces = grade >= 3
              ? 30
              : grade >= 2
              ? 20
              : 10;
          final medicineDie = Random().nextInt(medicineDieFaces) + 1;
          final medicineRoll = oculumRawVitaliumMedicineRoll(
            die: medicineDie,
            medicine: medicinaAttualeAggiustaNucleo(),
          );
          final medicineBonus = oculumRawVitaliumMedicineBonus(
            grade: grade,
            medicineRoll: medicineRoll,
          );
          final heal = max(0, amount + medicineBonus);
          if (payWithCoreStats) {
            currentMateriaController.text = max(
              0,
              leggiNumero(currentMateriaController) - amount * 2,
            ).toString();
            currentVolontaController.text = max(
              0,
              leggiNumero(currentVolontaController) - amount * 2,
            ).toString();
          } else {
            currentOculumController.text = max(
              0,
              leggiNumero(currentOculumController) - amount,
            ).toString();
          }
          currentHpController.text = min(
            maxHp(),
            leggiNumero(currentHpController) + heal,
          ).toString();
          final medicineDetails = grade < 1
              ? ' d$medicineDieFaces Medicina: $medicineDie, tiro $medicineRoll: nessun bonus prima del Grado I.'
              : grade >= 3
              ? ' d$medicineDieFaces Medicina: $medicineDie, tiro $medicineRoll: ${medicineBonus >= 0 ? '+' : ''}$medicineBonus HP.'
              : ' d$medicineDieFaces Medicina: $medicineDie, tiro $medicineRoll, metà: ${medicineBonus >= 0 ? '+' : ''}$medicineBonus HP.';
          risultato =
              'Vitalium Grezzo: ${payWithCoreStats ? '-${amount * 2} Materia e -${amount * 2} Volontà' : '-$amount Oculum'}, +$heal HP.$medicineDetails${heal == 0 && medicineBonus < 0 ? ' Il critico negativo ha annullato la cura, senza infliggere danno.' : ''}';
          break;
        case 'Vitalium Ridefinito':
          currentHpController.text = maxHp().toString();
          for (final art in arti) {
            art.integritaCorrente = artIntegrityEffectiveMaximum(art);
          }
          refullaStatsAttuali();
          risultato =
              'Vitalium Ridefinito: HP, statistiche attuali e integrità delle Art ripristinati ai massimali.';
          break;
        case 'Fiala di Oculum':
          amount = Random().nextInt(4) + 1;
          currentOculumController.text = min(
            oculumTotale(),
            leggiNumero(currentOculumController) + amount,
          ).toString();
          risultato = 'Fiala di Oculum: +$amount Oculum (1d4).';
          break;
        case 'Pergamena della Prigione d Ossa':
          final before = hpCorrenti();
          currentHpController.text = max(0, before - 12).toString();
          applyCondition(
            'stordito',
            duration: 1,
            source: 'Pergamena della Prigione d Ossa',
          );
          risultato =
              'Pergamena della Prigione d Ossa: 12 danni perforanti e Stordito per 1 turno.';
          break;
        case 'Pinna di Pesce Alato':
          applyCondition(
            'nuoto_aria',
            duration: 3,
            source: 'Pinna di Pesce Alato',
          );
          risultato =
              'Pinna di Pesce Alato: Nuoto nell’Aria attivo per 3 turni.';
          break;
      }
      if (item.quantita > 1) {
        item.quantita--;
      } else {
        inventario.remove(item);
      }
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }
}
