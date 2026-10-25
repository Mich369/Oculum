part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumPlanes =
    <
      ({
        String id,
        String name,
        String folder,
        int minimumGrade,
        double price,
        List<String> elements,
      })
    >[
      (
        id: 'mezzano',
        name: 'Regno mezzano',
        folder: 'Piani naturali',
        minimumGrade: 0,
        price: 1,
        elements: ['fisico'],
      ),
      (
        id: 'sacro',
        name: 'Regno sacro',
        folder: 'Piani naturali',
        minimumGrade: 3,
        price: 3,
        elements: ['solare', 'angelico'],
      ),
      (
        id: 'angelico',
        name: 'Regno angelico',
        folder: 'Piani naturali',
        minimumGrade: 0,
        price: 1.2,
        elements: ['angelico'],
      ),
      (
        id: 'oblio',
        name: 'Oblio',
        folder: 'Piani naturali',
        minimumGrade: 0,
        price: 1.5,
        elements: ['oblio'],
      ),
      (
        id: 'isole',
        name: 'Isole volanti',
        folder: 'Piani naturali',
        minimumGrade: 0,
        price: 1,
        elements: [
          'fulmine',
          'fulmine',
          'fulmine',
          'nuvola',
          'acqua',
          'ghiaccio',
        ],
      ),
      (
        id: 'affogato',
        name: 'Regno affogato',
        folder: 'Piani naturali',
        minimumGrade: 0,
        price: 1,
        elements: ['acqua'],
      ),
      (
        id: 'sotterraneo',
        name: 'Regno sotterraneo',
        folder: 'Piani naturali',
        minimumGrade: 0,
        price: 1,
        elements: ['roccia', 'terra', 'buio'],
      ),
      (
        id: 'sotterraneo_maggiore',
        name: 'Regno sotterraneo maggiore',
        folder: 'Piani naturali',
        minimumGrade: 1,
        price: 1.3,
        elements: ['roccia', 'terra', 'buio'],
      ),
      (
        id: 'demoniaco',
        name: 'Regno demoniaco',
        folder: 'Piani naturali',
        minimumGrade: 0,
        price: 1.2,
        elements: ['demoniaco', 'fuoco', 'lava', 'fisico'],
      ),
      (
        id: 'shadow_hell',
        name: 'Shadow Hell',
        folder: 'Piani naturali',
        minimumGrade: 4,
        price: 2.5,
        elements: ['diabolico', 'oblio'],
      ),
      (
        id: 'diabolico',
        name: 'Regno diabolico',
        folder: 'Piani naturali',
        minimumGrade: 3,
        price: 2,
        elements: ['diabolico', 'fuoco', 'lava', 'fisico'],
      ),
      (
        id: 'vero_inferno',
        name: 'Il vero inferno',
        folder: 'Piani naturali',
        minimumGrade: 9,
        price: 4,
        elements: ['diabolico', 'fuoco', 'lava'],
      ),
      (
        id: 'postea',
        name: 'Postea',
        folder: 'Micro realtà',
        minimumGrade: 0,
        price: 1,
        elements: ['fisico'],
      ),
      (
        id: 'caramella',
        name: 'Regno Caramella',
        folder: 'Micro realtà',
        minimumGrade: 0,
        price: 1.1,
        elements: ['fisico'],
      ),
      (
        id: 'foresta_elementale',
        name: 'Foresta elementale',
        folder: 'Micro realtà',
        minimumGrade: 0,
        price: 1.1,
        elements: [
          'fisico',
          'fuoco',
          'acqua',
          'ghiaccio',
          'terra',
          'roccia',
          'fulmine',
          'vento',
          'nuvola',
          'buio',
          'luce',
          'solare',
          'lunare',
          'angelico',
          'demoniaco',
          'diabolico',
          'oblio',
          'slime',
          'veleno',
        ],
      ),
      (
        id: 'morti',
        name: 'Regno dei Morti',
        folder: 'Micro realtà',
        minimumGrade: 0,
        price: 1.2,
        elements: ['buio', 'fisico'],
      ),
      (
        id: 'ghiaccio',
        name: 'Terre di ghiaccio',
        folder: 'Micro realtà',
        minimumGrade: 0,
        price: 1,
        elements: ['ghiaccio'],
      ),
      (
        id: 'nuvole_rocciose',
        name: 'Nuvole rocciose',
        folder: 'Micro realtà',
        minimumGrade: 0,
        price: 1,
        elements: ['roccia', 'fulmine', 'nuvola', 'vento'],
      ),
    ];

int oculumPlanePressurePenalty({
  required int total,
  required int natural,
  required int areaGrade,
}) {
  if (natural == 1) return 20;
  final dt = 18 + max(0, areaGrade);
  if (total > dt) return 0;
  if (natural >= 18 || total >= dt - 3) return 5;
  return 10;
}

extension _OculumPlanes on _OculumHomePageState {
  bool get planeNeedsAdaptation =>
      selectedPlane.minimumGrade > 0 &&
      leggiNumero(gradoController) <= selectedPlane.minimumGrade - 2;
  int get planePressurePenalty => !planeNeedsAdaptation
      ? 0
      : max(
          0,
          readIntValue(
            schedePersonaggio[schedaCorrente]['planePressurePenalty'],
          ),
        );

  Future<void> rollPlaneAdaptation() async {
    if (!planeNeedsAdaptation) return;
    final origin = currentSheetScrollId();
    final plane = selectedPlaneId;
    final grade = selectedPlane.minimumGrade;
    final stat = hiddenEyeStats.where((s) => s.id == 'adattamento').firstOrNull;
    if (stat == null) return;
    await tiraSottotrattoOcchio(
      stat,
      actionLabel: 'Adattamento · pressione ${selectedPlane.name}',
      onResolved: (natural, total) {
        if (currentSheetScrollId() != origin || selectedPlaneId != plane) {
          return;
        }
        final penalty = oculumPlanePressurePenalty(
          total: total,
          natural: natural,
          areaGrade: grade,
        );
        schedePersonaggio[schedaCorrente]['planePressurePenalty'] = penalty;
        schedePersonaggio[schedaCorrente]['planePressureRolled'] = true;
        aggiungiLog(
          '[PRESSIONE] ${nomeController.text}: Adattamento $total (dado $natural), DT ${18 + grade} da superare → ${penalty == 0 ? 'nessun malus' : '−$penalty a tutte le statistiche fino all’uscita dal piano'}.',
        );
        invalidateDerivedDataCaches();
        programmaSalvataggio();
      },
    );
  }

  void recoverPlanePressureCritical({
    bool doubleCritical = false,
    String receiptId = '',
  }) {
    if (!currentCombatIsActive() ||
        !planeNeedsAdaptation ||
        planePressurePenalty <= 0) {
      return;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    if (doubleCritical) {
      final seen = (sheet['planePressureDoubleCriticalIds'] as List? ?? [])
          .map((e) => '$e')
          .toSet();
      if (receiptId.isEmpty || !seen.add(receiptId)) return;
      sheet['planePressureDoubleCriticalIds'] = seen.toList();
    }
    // The natural critical already recovered three at roll time. A confirmed
    // opposed double critical supplies the other three, once per attack group.
    final before = planePressurePenalty;
    sheet['planePressurePenalty'] = max(0, before - 3);
    aggiungiLog(
      '[PRESSIONE] ${doubleCritical ? 'Doppio critico: recupero totale 6' : 'Critico positivo: recupero 3'} · malus area −$before → −${sheet['planePressurePenalty']}.',
    );
    invalidateDerivedDataCaches();
    programmaSalvataggio();
  }

  bool get planeColdUnprotected =>
      selectedPlaneId == 'ghiaccio' &&
      !inventario.any(
        (item) =>
            item.quantita > 0 &&
            item.equipaggiata &&
            (item.craftData['heavyClothing'] == true ||
                RegExp(
                  r'pesant|termic|pelliccia',
                  caseSensitive: false,
                ).hasMatch('${item.nome} ${item.note}')),
      );

  String get selectedPlaneId =>
      schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length
      ? 'mezzano'
      : '${schedePersonaggio[schedaCorrente]['selectedPlaneId'] ?? 'mezzano'}';
  ({
    String id,
    String name,
    String folder,
    int minimumGrade,
    double price,
    List<String> elements,
  })
  get selectedPlane =>
      oculumPlanes.where((p) => p.id == selectedPlaneId).firstOrNull ??
      oculumPlanes.first;

  Future<void> selectCurrentPlane() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('Piano attuale'),
        children: [
          for (final folder in ['Piani naturali', 'Micro realtà'])
            ExpansionTile(
              title: Text(folder),
              initiallyExpanded: oculumPlanes.any(
                (p) => p.folder == folder && p.id == selectedPlaneId,
              ),
              children: [
                for (final plane in oculumPlanes.where(
                  (p) => p.folder == folder,
                ))
                  ListTile(
                    title: Text(plane.name),
                    selected: plane.id == selectedPlaneId,
                    subtitle: Text(
                      'Grado minimo ${plane.minimumGrade} · ${plane.elements.toSet().join(', ')}',
                    ),
                    onTap: () => Navigator.pop(dialog, plane.id),
                  ),
              ],
            ),
        ],
      ),
    );
    if (selected == null || !mounted || selected == selectedPlaneId) return;
    _saveActiveMerchantProfileStock();
    schedePersonaggio[schedaCorrente]['selectedPlaneId'] = selected;
    restoreMonsterAppearance(schedePersonaggio[schedaCorrente]);
    schedePersonaggio[schedaCorrente]['planePressurePenalty'] = 0;
    schedePersonaggio[schedaCorrente]['planePressureRolled'] = false;
    ensurePlaneOffers();
    if (selected == 'postea') {
      selectMerchantShop('postea');
    } else if (selected == 'oblio') {
      selectMerchantShop('mercato_nero');
    } else if (merchantShopType == 'postea') {
      selectMerchantShop('tutti');
    }
    final profile = _activeMerchantProfile();
    profile['offerSelections'] = <String, dynamic>{};
    _ensureMerchantOfferSelection();
    aggiungiLog('[PIANO] ${selectedPlane.name}. Mercati aggiornati.');
    programmaSalvataggio();
    setState(() {});
    if (planeNeedsAdaptation) await rollPlaneAdaptation();
  }

  bool merchantOfferMatchesPlane(Map<String, dynamic> offer) {
    if (offer['planeId'] != null) return offer['planeId'] == selectedPlaneId;
    final kind = '${offer['kind']}';
    if (kind.startsWith('postea_')) return selectedPlaneId == 'postea';
    if (readIntValue(offer['grade']) < selectedPlane.minimumGrade) return false;
    if (const {
      'gear',
      'clothing',
      'title_item',
      'black_market_weapon',
      'black_market_fallen_eye',
      'fallen_eye',
    }.contains(kind)) {
      return const {'mezzano', 'postea'}.contains(selectedPlaneId);
    }
    return true;
  }

  void ensurePlaneOffers() {
    final plane = selectedPlane;
    final elements = plane.id == 'foresta_elementale'
        ? allDamageElementIds()
        : plane.elements;
    if (const {'mezzano', 'postea'}.contains(plane.id)) return;
    final level = max(0, leggiNumero(livelloController));
    final realmScrollId = switch (plane.id) {
      'angelico' || 'sacro' => 'raggio_angelico',
      'affogato' => 'richiamo_piranha',
      _ => '',
    };
    if (realmScrollId.isNotEmpty) {
      final profile = oculumTechniqueScrolls.firstWhere(
        (profile) => profile.id == realmScrollId,
      );
      final grade = max(
        plane.minimumGrade,
        leggiNumero(gradoController),
      ).clamp(0, 12);
      final id = 'plane_${plane.id}_scroll_${profile.id}_$grade';
      if (!merchantStock.any((offer) => offer['id'] == id)) {
        merchantStock.add({
          'id': id,
          'planeId': plane.id,
          'kind': 'technique_scroll',
          'name': 'Pergamena ${profile.name} · Grado $grade',
          'grade': grade,
          'scrollProfileId': profile.id,
          'scrollGrade': grade,
          'cost': (oculumScrollValue(grade) * plane.price).ceil(),
          'desc':
              '${profile.effects.first.narrativeText} Monouso e apprendibile con le normali regole delle pergamene. Costo ${oculumScrollWillCost(grade)} Volontà; CD ${oculumScrollCooldown(grade)} turni; DT ${oculumScrollDifficulty(grade)}.',
        });
      }
    }
    if (plane.id == 'morti') {
      final grade = max(0, leggiNumero(gradoController));
      for (final kind in ['skull_amulet', 'undead_summon']) {
        final id = 'plane_morti_${kind}_$grade';
        if (!merchantStock.any((o) => o['id'] == id)) {
          merchantStock.add({
            'id': id,
            'planeId': 'morti',
            'kind': 'gear',
            'necromancyKind': kind,
            'name': kind == 'skull_amulet'
                ? 'Amuleto Teschio'
                : 'Sigillo di evocazione necromantica',
            'level': level,
            'grade': grade,
            'weapon': false,
            'protection': true,
            'cost': kind == 'skull_amulet' ? 120 + grade * 10 : 90 + grade * 10,
            'desc': kind == 'skull_amulet'
                ? 'Un teschio d’avorio annerito avvolge una gemma funeraria. Un’Azione ti trasforma in un non morto casuale del tuo livello, con Vita, Oculum e abilità separate. Dura livello/10 attacchi subiti (per difetto, minimo 1); schivati esclusi. Nessun danno in eccesso passa alla forma originale. Recupero: Riposo Lungo.'
                : 'Tre ossicini e filo d’argento racchiudono un richiamo dei morti. Evoca un alleato non morto del tuo livello per 3 tuoi turni, con iniziativa e abilità proprie. Prezzo proposto modificabile.',
          });
        }
      }
    }
    final baseGrade = max(
      plane.minimumGrade,
      leggiNumero(gradoController),
    ).clamp(0, 12);
    for (var i = 0; i < max(9, elements.length); i++) {
      final id = 'plane_${plane.id}_${baseGrade}_$i';
      if (merchantStock.any((o) => o['id'] == id)) continue;
      final grade = min(12, baseGrade + (i >= 6 ? 1 : 0));
      final element = elements[i % elements.length];
      final weapon = i % 3 == 0;
      final clothing = i % 3 == 2;
      final noun = weapon
          ? 'Arma'
          : clothing
          ? 'Vestiario'
          : 'Armatura';
      final visual = switch (plane.id) {
        'foresta_elementale' =>
          'Corteccia viva, cristalli e fili di foglia intrecciano rune di ogni elemento della foresta.',
        'morti' =>
          'Osso levigato, sudari cuciti con argento e sigilli funerari custodiscono conoscenze di necromanzia e richiamo dei defunti.',
        'ghiaccio' =>
          'Spessa pelliccia etica, lana infeltrita e cuciture termiche proteggono dal vento gelido; i cristalli del bordo trattengono rune di ghiaccio.',
        'nuvole_rocciose' =>
          'Scaglie di roccia leggera e tessuti sospesi tra le nubi ospitano conduttori di fulmine e nastri mossi dal vento.',
        'sacro' =>
          'Oro pallido, incisioni liturgiche e tessuto bianco iridescente custodiscono rune di luce consacrata.',
        'angelico' =>
          'Piume stilizzate in argento, lino celeste e fili luminosi ricordano ali angeliche senza ostacolare i movimenti.',
        'isole' =>
          'Fibra leggera, conduttori azzurri e cristalli sospesi raccolgono il vento delle isole e scariche di fulmine.',
        'affogato' =>
          'Scaglie madreperlacee, giunti flessibili e nastri di alghe lasciano muoversi in acqua. Qui si respira normalmente.',
        'sotterraneo' || 'sotterraneo_maggiore' =>
          'Basalto inciso, cuoio scuro e trame minerali opache resistono ai cunicoli; riflessi di mica guidano le mani nel buio.',
        'caramella' =>
          'Cioccolato temprato, costole di candy cane e fili di zucchero filato formano un equipaggiamento appena più forte di quello mezzano.',
        'oblio' =>
          'Materia nera incrinata e lembi senza riflesso provengono da creature dell’Oblio, trattati dal Mercante Nero.',
        'shadow_hell' =>
          'Acciaio infernale percorso da vene d’Oblio e sigilli di quarantena: il riflesso corrotto del regno diabolico.',
        _ =>
          'Piastre brunite, filamenti incandescenti e cuoio inciso di sigilli infernali contengono il calore senza nascondere il carattere del regno.',
      };
      final name = '$noun di ${plane.name} · $element · G$grade';
      merchantStock.add({
        'id': id,
        'planeId': plane.id,
        'kind': 'gear',
        'name': name,
        'level': level,
        'grade': grade,
        'element': element,
        if (plane.id == 'ghiaccio' && !weapon) 'heavyClothing': true,
        'weapon': weapon,
        'protection': !weapon,
        'authored': true,
        'damage': weapon
            ? 6 + grade * 8 + (plane.id == 'caramella' ? 1 : 0)
            : 0,
        'defence': weapon
            ? 0
            : 5 + grade * 3 + (plane.id == 'caramella' ? 1 : 0),
        'shield': weapon ? 0 : 10 + grade * 10,
        'cost': ((30 + grade * 90 + level * 5) * plane.price).ceil(),
        'desc':
            '$visual Elemento $element. Livello $level, Grado $grade. Skill e bonus modificabili.',
      });
    }
    for (final element in elements.toSet()) {
      final id = 'plane_${plane.id}_resistance_$element';
      if (merchantStock.any((o) => o['id'] == id)) continue;
      merchantStock.add({
        'id': id,
        'planeId': plane.id,
        'kind': 'food',
        'name': 'Sigillo temporaneo · $element',
        'grade': plane.minimumGrade,
        'cost': (15 * plane.price).ceil(),
        'resistanceElement': element,
        'resistancePreset': 'Resistenza',
        'desc':
            'Runa consumabile di ${plane.name}: Resistenza temporanea a $element secondo la durata modificabile dei consumabili.',
      });
    }
    if (plane.id == 'shadow_hell') {
      final id = 'plane_shadow_hell_pendant';
      if (!merchantStock.any((o) => o['id'] == id)) {
        merchantStock.add({
          'id': id,
          'planeId': plane.id,
          'kind': 'gear',
          'name': 'Pendaglio della Soglia Integra',
          'grade': baseGrade,
          'level': level,
          'weapon': false,
          'protection': true,
          'element': 'diabolico',
          'cost': 600 + baseGrade * 100,
          'defence': 5 + baseGrade,
          'desc':
              'Tre anelli d’argento sigillano un frammento di specchio nero. Runa protettiva contro l’Oblio, effetto e durata modificabili.',
          'planeResistance': 'oblio',
        });
      }
    }
    if (const {'sacro', 'oblio'}.contains(plane.id)) {
      final candidates = monsterBookEntries
          .where(
            (m) =>
                !m.isNpc &&
                (plane.id == 'sacro'
                    ? oculumNormalizeText(
                        '${m.nameIt} ${m.presetType}',
                      ).contains('aberraz')
                    : oculumNormalizeText(
                        '${m.nameIt} ${m.descIt} ${m.elementId}',
                      ).contains('oblio')),
          )
          .take(3);
      for (final monster in candidates) {
        final id = 'plane_${plane.id}_eye_${monster.id}_$level';
        if (merchantStock.any((o) => o['id'] == id)) continue;
        merchantStock.add({
          'id': id,
          'planeId': plane.id,
          'kind': 'fallen_eye',
          'grade': baseGrade,
          'level': level,
          'cost': ((150 + level * 10 + baseGrade * 100) * plane.price).ceil(),
          'name': 'Occhio dei Caduti · ${monster.nameIt}',
          'rarity': 'raro',
          'sourceSheet': _fallenEyeSourceFromMonsterBook(
            monster,
            name: monster.nameIt,
            level: level,
          ),
          'desc':
              'Creatura di ${plane.name} dal Monster Book; scheda, livello e abilità conservati.',
        });
      }
    }
  }
}

extension _OculumNecromancyEquipment on _OculumHomePageState {
  Future<void> useNecromancyEquipment(InventoryItem item) async {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    if (!inventario.contains(item) ||
        !item.equipaggiata ||
        item.quantita <= 0) {
      return;
    }
    final amulet = item.craftData['necromancyKind'] == 'skull_amulet';
    if (!amulet &&
        item.ability?.forme.firstOrNull?.cooldownStrutturato?.ready == false) {
      return;
    }
    if (amulet &&
        (item.craftData['usedSinceLongRest'] == true ||
            schedePersonaggio[schedaCorrente]['skullFormOriginal'] is Map)) {
      return;
    }
    final candidates = monsterBookEntries
        .where(
          (m) =>
              !m.isNpc &&
              RegExp(
                r'non morto|non-morto|scheletr|zombie|undead|lich|spettro',
              ).hasMatch(
                oculumNormalizeText('${m.nameIt} ${m.presetType} ${m.descIt}'),
              ),
        )
        .toList();
    if (candidates.isEmpty) {
      aggiungiLog('Nessuna forma non morta disponibile nel Monster Book.');
      return;
    }
    if (currentCombatIsActive()) {
      final tokens = _writableOnlineCombatTokens();
      final active = _usesLocalMasterInitiative
          ? masterInitiativeActiveIndex
          : readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex']);
      if (active < 0 ||
          active >= tokens.length ||
          onlineCombatTokenTag(tokens[active]) != sheetTagAt(schedaCorrente) ||
          readBoolValue(tokens[active]['actionUsed'])) {
        aggiungiLog('[NECROMANZIA] Richiede la tua Azione nel tuo turno.');
        return;
      }
      if (!await requestUtilitySpend('azione')) return;
    }
    final level = max(0, leggiNumero(livelloController));
    final monster = candidates[Random.secure().nextInt(candidates.length)];
    final source = _fallenEyeSourceFromMonsterBook(
      monster,
      name: monster.nameIt,
      level: level,
    );
    if (!amulet) {
      final index = createShadowCloneSheet(
        hp: max(1, readIntValue(source['currentHp'], fallback: 20)),
        duration: 3,
        source: item.nome,
        displayName: '${monster.nameIt} evocato',
        asSummon: true,
        summonKind: 'necromancy',
        summonDescription: item.note,
      );
      if (index < 0) return;
      final summon = schedePersonaggio[index];
      for (final key in [
        'resilienza',
        'volonta',
        'materia',
        'oculum',
        'currentResilienza',
        'currentVolonta',
        'currentMateria',
        'currentOculum',
        'skills',
        'arti',
        'derivedMaxHp',
        'currentHp',
      ]) {
        if (source.containsKey(key)) {
          summon[key] = oculumCopyJsonTree(source[key]);
        }
      }
      summon['necromancyOwnerTurnExpires'] =
          playerReportedTurn +
          max(1, readIntValue(item.craftData['duration'], fallback: 3));
      aggiungiLog(
        '[EVOCAZIONE] ${monster.nameIt}: alleato con iniziativa propria, durata 3 tuoi turni.',
      );
      item.ability?.forme.firstOrNull?.cooldownStrutturato?.activate();
      programmaSalvataggio();
      return;
    }
    item.craftData = {...item.craftData, 'usedSinceLongRest': true};
    salvaSchedaCorrenteInMemoria();
    final original = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(schedePersonaggio[schedaCorrente])) as Map,
    );
    final transformed = {...original};
    for (final key in [
      'resilienza',
      'volonta',
      'materia',
      'oculum',
      'currentResilienza',
      'currentVolonta',
      'currentMateria',
      'currentOculum',
      'maxOculum',
      'normalCurrentOculum',
      'skills',
      'arti',
      'derivedMaxHp',
      'currentHp',
      'manualHpMaximumAdjustment',
    ]) {
      if (source.containsKey(key)) {
        transformed[key] = oculumCopyJsonTree(source[key]);
      }
    }
    transformed.addAll({
      'skullFormOriginal': original,
      'skullFormHitsRemaining': max(1, level ~/ 10),
      'skullFormName': monster.nameIt,
      'hpTemp': '0',
      'scudo': '0',
      'scudoOculum': '0',
    });
    final global = catturaImpostazioniGlobali();
    schedePersonaggio[schedaCorrente] = transformed;
    caricaStatoDaJson(transformed);
    ripristinaImpostazioniGlobali(global);
    aggiungiLog(
      '[AMULETO TESCHIO] ${monster.nameIt}: Vita/Oculum/abilità separati, ${max(1, level ~/ 10)} attacchi subiti; nessun danno eccedente passa alla forma originale.',
    );
    programmaSalvataggio();
    sendRealtimeHpChanged();
  }

  void advanceSkullFormHit() {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    if (sheet['skullFormOriginal'] is! Map) return;
    final remaining = max(0, readIntValue(sheet['skullFormHitsRemaining']) - 1);
    sheet['skullFormHitsRemaining'] = remaining;
    if (remaining > 0 && hpCorrenti() > 0) {
      aggiungiLog('[AMULETO TESCHIO] $remaining attacchi subiti rimanenti.');
      return;
    }
    final original = Map<String, dynamic>.from(
      sheet['skullFormOriginal'] as Map,
    );
    final global = catturaImpostazioniGlobali();
    schedePersonaggio[schedaCorrente] = original;
    caricaStatoDaJson(original);
    ripristinaImpostazioniGlobali(global);
    aggiungiLog(
      '[AMULETO TESCHIO] Forma originale ripristinata; danni eccedenti annullati.',
    );
    programmaSalvataggio();
    sendRealtimeHpChanged();
  }

  void advanceNecromancySummons(int turn) {
    final owner = sheetTagAt(schedaCorrente);
    for (var i = 0; i < schedePersonaggio.length; i++) {
      final sheet = schedePersonaggio[i];
      if (sheet['summonKind'] != 'necromancy' ||
          sheet['summonerTag'] != owner ||
          sheet['summonExpired'] == true ||
          readIntValue(sheet['necromancyOwnerTurnExpires']) > turn) {
        continue;
      }
      sheet['summonExpired'] = true;
      sheet['currentHp'] = '0';
      for (final token in masterInitiativeTokens.where(
        (t) => publicInitiativeSourceTag(t) == sheetTagAt(i),
      )) {
        token['status'] = 'expired';
        token['currentHp'] = 0;
        token['summonExpired'] = true;
      }
      aggiungiLog(
        '[EVOCAZIONE] ${nomeSchedaPersonaggio(i)} svanisce dopo i turni del proprietario.',
      );
      if (realtimeService?.isConnected == true && !realtimeIsMasterRole) {
        unawaited(
          realtimeService!.sendInitiativeTurnAdjusted(
            senderRole: 'player',
            campaignId: permissionCampaignId,
            campaignName: activeCampaignName(),
            sheetTag: sheetTagAt(i),
            turn: turn,
            encounterId: onlineCombatEncounterId,
            leaveEncounter: true,
          ),
        );
      }
    }
  }
}
