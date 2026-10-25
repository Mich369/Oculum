part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member
int oculumMechaDifficulty(int robotLevel, int ownerLevel) =>
    (26 + max(0, robotLevel) + max(0, robotLevel - ownerLevel)).toInt();
String oculumMechaBuildOutcome({
  required int natural,
  required int total,
  required int robotLevel,
  required int ownerLevel,
  int attempts = 0,
  bool crafting = false,
}) {
  if (natural <= 1) return 'wreck';
  if (total - (crafting ? 2 : 0) >
      oculumMechaDifficulty(robotLevel, ownerLevel)) {
    return natural >= 20 ? 'critical' : 'built';
  }
  return attempts + 1 >= 3 ? 'wreck' : 'retry';
}

int oculumMechaStat(int source, bool critical) =>
    max(0, (source * (critical ? 1 : .8)).floor());
int oculumMechaSoloDamage(int damage) => max(0, damage) * 2 ~/ 5;
int oculumMechaEscapeTotal({
  required int die,
  required int reflexes,
  required int level,
  String resource = 'none',
}) =>
    (resource == 'none'
            ? die + max(0, reflexes) ~/ 2 + max(0, level) ~/ 3
            : die +
                  max(0, reflexes) +
                  5 +
                  max(0, level) ~/ 2 +
                  (resource == 'reazione_veloce' ? 5 : 0))
        .toInt();
int oculumMechaExplosionDamage(int level, {bool fastReaction = false}) =>
    ((20 + 3 * max(0, level)) * (fastReaction ? 0.75 : 1)).floor();

const _mechaBodyFields = <String>[
  'resilienza',
  'volonta',
  'materia',
  'oculum',
  'currentResilienza',
  'currentVolonta',
  'currentMateria',
  'currentOculum',
  'normalCurrentOculum',
  'temporaryOculum',
  'temporaryOculumRollsRemaining',
  'currentHp',
  'hpTemp',
  'scudo',
  'scudoOculum',
  'scudoOculumMax',
  'skills',
  'arti',
  'hiddenEyeStats',
  'incomingDamagePresets',
  'dannoSubitoPercentPerTipo',
  'buffMalusRapidi',
  'manualHpMaximumAdjustment',
  'activeStructuredEffects',
  'conditions',
  'conditionImmunities',
  'tempResilienza',
  'tempVolonta',
  'tempMateria',
  'tempOculum',
  'attaccoRapido',
  'difesaRapida',
  'cmRapido',
  'vcRapido',
];
Map<String, dynamic> oculumMechaRobotSource(
  MonsterBookEntry monster,
  int level,
  int grade,
) {
  final stats = oculumMonsterCreationStats(monster, level);
  final hp =
      max(1, stats['resilienza'] ?? 1) * oculumHpMultiplierForGrade(grade);
  return {
    'nome': monster.nameIt,
    'livello': '$level',
    'grado': '$grade',
    for (final stat in ['resilienza', 'volonta', 'materia', 'oculum'])
      stat: '${stats[stat] ?? 0}',
    'currentHp': '$hp',
    'mechaMaxHp': hp,
    'incomingDamagePresets': monster.incomingDamageResistancePresets,
    'skills': oculumMonsterBookSkills(monster).map((s) => s.toJson()).toList(),
    'arti': [oculumMonsterBookArt(monster).toJson()],
  };
}

InventoryItem oculumDollRobotScraps(
  MonsterBookEntry monster,
  int level,
  int grade,
  String killId,
) => InventoryItem(
  nome: 'Scarti robotici · ${monster.nameIt}',
  peso: 4,
  quantita: 1,
  livelloOggetto: level,
  gradoOggetto: grade,
  note:
      'Tre tentativi con Meccanica o Crafting −2. Supera DT 26 + livello robot + parte del livello sopra il tuo. Critico negativo: rottami. Un critico positivo deve comunque superare la DT.',
  craftData: {
    'mechaScraps': true,
    'attempts': 0,
    'robotSource': oculumMechaRobotSource(monster, level, grade),
  },
  monsterLoot: {'id': '$killId:robot-scraps', 'monsterId': monster.id},
);
InventoryItem oculumDollCostume(
  MonsterBookEntry monster,
  int level,
  int grade,
  String killId,
  Random random,
) {
  final choices = monster.skillIds
      .where((id) => id != 'clawed_doll_spring')
      .toList();
  final selected = choices[random.nextInt(choices.length)];
  CharacterSkill ability(String id) => oculumEquipmentAbilityFromArt(
    oculumMonsterBookArt(monster.copyWith(skillIds: [id])).skills.first,
  );
  final main = ability(selected);
  return InventoryItem(
    nome: 'Costume del Pupazzo',
    peso: 1.2,
    quantita: 1,
    livelloOggetto: level,
    gradoOggetto: grade,
    note:
        'Abito magico vuoto: equipaggialo per usare ${main.nome} e Scatto a molla. Conserva costi, forme e cooldown delle tecniche. Drop totale ≥43.',
    ability: main,
    craftData: {
      'dollCostume': true,
      'jumpAbility': ability('clawed_doll_spring').toJson(),
    },
    monsterLoot: {
      'id': '$killId:doll-costume',
      'monsterId': monster.id,
      'rareMonsterEquipment': true,
    },
  );
}

extension _OculumMecha on _OculumHomePageState {
  Map<String, dynamic> get mountedMecha =>
      Map<String, dynamic>.from(planarState['mountedMecha'] as Map? ?? {});
  bool get isMountedInMecha => mountedMecha.isNotEmpty;
  bool get isAutonomousMecha =>
      planarState['mechaFrame'] is Map && !isMountedInMecha;
  bool get mechaOccupied =>
      isAutonomousMecha &&
      '${(planarState['mechaFrame'] as Map)['occupiedBy'] ?? ''}'.isNotEmpty;
  int get mechaBodyMaximum => readIntValue(planarState['mechaBodyMaxHp']);

  Future<void> useDollCostumeJump(InventoryItem item) async {
    if (!inventario.contains(item) ||
        !item.equipaggiata ||
        item.craftData['jumpAbility'] is! Map) {
      aggiungiLog('[COSTUME] Equipaggia il costume prima di usare il salto.');
      return;
    }
    final skill = CharacterSkill.fromJson(
      Map<String, dynamic>.from(item.craftData['jumpAbility'] as Map),
    );
    final form = skill.forme.first;
    final used = await useConfiguredAbility(
      source: '${item.nome} · ${skill.nome}',
      effects: form.effettiStrutturati,
      cost: form.costoStrutturato,
      cooldown: form.cooldownStrutturato,
      valid: () => inventario.contains(item) && item.equipaggiata,
    );
    if (used) {
      item.craftData['jumpAbility'] = skill.toJson();
      programmaSalvataggio();
    }
  }

  Future<void> craftMecha(InventoryItem item, {bool crafting = false}) async {
    if (!inventario.contains(item) ||
        item.quantita <= 0 ||
        item.craftData['mechaScraps'] != true) {
      return;
    }
    final origin = currentSheetScrollId();
    final stat = hiddenEyeStats
        .where((s) => s.id == (crafting ? 'crafting' : 'meccanica'))
        .firstOrNull;
    if (stat == null || !await spendCombatRollResource() || !mounted) return;
    int natural = 0, total = 0;
    await tiraSottotrattoOcchio(
      stat,
      resourceAlreadySpent: true,
      actionLabel: 'Costruisci mecha${crafting ? ' · Crafting −2' : ''}',
      onResolved: (d, t) {
        natural = d;
        total = t;
      },
    );
    if (!mounted ||
        natural == 0 ||
        currentSheetScrollId() != origin ||
        !inventario.contains(item)) {
      return;
    }
    resolveMechaConstruction(
      item,
      natural: natural,
      total: total,
      crafting: crafting,
    );
  }

  String resolveMechaConstruction(
    InventoryItem item, {
    required int natural,
    required int total,
    bool crafting = false,
  }) {
    if (!inventario.contains(item) || item.craftData['mechaScraps'] != true) {
      return 'invalid';
    }
    final source = Map<String, dynamic>.from(
      item.craftData['robotSource'] as Map? ?? {},
    );
    final level = readIntValue(
      source['livello'],
      fallback: item.livelloOggetto,
    );
    final ownerLevel = leggiNumero(livelloController);
    final attempts = readIntValue(item.craftData['attempts']);
    final outcome = oculumMechaBuildOutcome(
      natural: natural,
      total: total,
      robotLevel: level,
      ownerLevel: ownerLevel,
      attempts: attempts,
      crafting: crafting,
    );
    item.craftData['attempts'] = attempts + 1;
    aggiungiLog(
      '[MECHA] ${crafting ? 'Crafting' : 'Meccanica'} ${total - (crafting ? 2 : 0)} / DT ${oculumMechaDifficulty(level, ownerLevel)} (serve superarla) · tentativo ${attempts + 1}/3 · $outcome.',
    );
    if (outcome == 'wreck') {
      item.nome = 'Rottami · ${source['nome'] ?? 'Robot'}';
      item.craftData['mechaScraps'] = false;
      item.craftData['mechaWreck'] = true;
    } else if (outcome == 'built' || outcome == 'critical') {
      final critical = outcome == 'critical';
      final tag = 'MechaOcu:3690${DateTime.now().microsecondsSinceEpoch}';
      final sheet = statoVuotoPersonaggio(
        nome: 'Mecha · ${source['nome'] ?? 'Pupazzo Robotico'}',
        tipo: 'NPC',
        livello: level,
        grado: item.gradoOggetto,
      );
      for (final key in _mechaBodyFields) {
        if (source.containsKey(key)) sheet[key] = source[key];
      }
      for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) {
        final value = oculumMechaStat(readIntValue(source[stat]), critical);
        sheet[stat] = '$value';
        sheet['current${stat[0].toUpperCase()}${stat.substring(1)}'] = '$value';
      }
      final hp = max(
        1,
        readIntValue(
          source['mechaMaxHp'],
          fallback: readIntValue(source['currentHp'], fallback: 50),
        ),
      );
      sheet['currentHp'] = '$hp';
      sheet['sheetTag'] = tag;
      sheet['id'] = tag;
      sheet['monsterBookSourceId'] = 'pupazzo_robotico_postea';
      sheet['masterSideOverride'] = 'ally';
      sheet['inMasterParty'] = true;
      sheet['planarRuntime'] = {
        'mechaBodyMaxHp': hp,
        'mechaFrame': {
          'critical': critical,
          'level': level,
          'ownerTag': sheetTagAt(schedaCorrente),
          'occupiedBy': '',
        },
      };
      schedePersonaggio.add(sheet);
      item.nome = sheet['nome'] as String;
      item.craftData = {
        'mechaItem': true,
        'mechaSheetTag': tag,
        'critical': critical,
        'sourceLevel': level,
      };
      item.note =
          'Mecha ${critical ? 'critico (100% statistiche, Reazioni veloci)' : 'standard (80% statistiche, Reazioni normali)'}. Vita propria $hp. Entra/esci con una Azione nel tuo turno; da solo infligge il 40% dei danni. Restano le resistenze del robot.';
      if (modalitaMaster || isMasterHost || realtimeIsMasterRole) {
        addSheetToMasterInitiative(schedePersonaggio.length - 1);
      }
    }
    programmaSalvataggio();
    invalidateDerivedDataCaches();
    return outcome;
  }

  bool destroyMechaWreck(InventoryItem item, {int? percentile}) {
    if (!inventario.contains(item) ||
        item.craftData['mechaWreck'] != true ||
        item.quantita <= 0) {
      return false;
    }
    item.quantita--;
    if (item.quantita <= 0) inventario.remove(item);
    final success = (percentile ?? Random.secure().nextInt(100)) < 65;
    if (success) {
      final core = oculumCreatureCore(
        0,
        broken: true,
        source: Map<String, dynamic>.from(
          item.craftData['robotSource'] as Map? ?? {},
        ),
      );
      core.nome = 'Nucleo rotto · Lv ${item.livelloOggetto}';
      core.livelloOggetto = item.livelloOggetto;
      inventario.add(core);
    }
    aggiungiLog(
      '[ROTTAMI] Distrutti: ${success ? 'nucleo rotto ottenuto' : 'nessun nucleo'} · 65%.',
    );
    programmaSalvataggio();
    return success;
  }

  Future<void> enterMecha(InventoryItem item) async {
    if (isMountedInMecha ||
        !inventario.contains(item) ||
        item.craftData['mechaItem'] != true) {
      return;
    }
    final index = localSheetIndexForOculumTag(
      '${item.craftData['mechaSheetTag']}',
    );
    if (index < 0 || sheetCurrentHpForDeathAt(index) <= 0) {
      aggiungiLog('[MECHA] Corpo del mecha non disponibile o distrutto.');
      return;
    }
    final body = schedePersonaggio[index];
    final frame = (body['planarRuntime'] as Map)['mechaFrame'] as Map;
    if ('${frame['occupiedBy'] ?? ''}'.isNotEmpty) return;
    final origin = currentSheetScrollId();
    if (!await requestUtilitySpend('azione', preferFreeReaction: false) ||
        !mounted ||
        currentSheetScrollId() != origin) {
      return;
    }
    salvaSchedaCorrenteInMemoria();
    final owner = schedaCorrente;
    final backup = _cloneJsonMap(schedePersonaggio[owner]);
    final replacement = _cloneJsonMap(backup);
    for (final key in _mechaBodyFields) {
      if (body.containsKey(key)) {
        replacement[key] = body[key];
      } else {
        replacement.remove(key);
      }
    }
    replacement['planarRuntime'] = {
      ...planarState,
      'plasmaTemporaryMatter': readIntValue(
        (body['planarRuntime'] as Map)['plasmaTemporaryMatter'],
      ),
      'mechaBodyMaxHp': (body['planarRuntime'] as Map)['mechaBodyMaxHp'],
      'mountedMecha': {
        'sheetTag': sheetTagAt(index),
        'critical': frame['critical'] == true,
        'level': frame['level'],
        'pilotBackup': backup,
      },
    };
    final globals = catturaImpostazioniGlobali();
    frame['occupiedBy'] = sheetTagAt(owner);
    schedePersonaggio[owner] = replacement;
    caricaStatoDaJson(replacement);
    ripristinaImpostazioniGlobali(globals);
    for (final token in masterInitiativeTokens) {
      if (publicInitiativeSourceTag(token) == sheetTagAt(index)) {
        token['mechaOccupied'] = true;
      }
      if (publicInitiativeSourceTag(token) == sheetTagAt(owner)) {
        token['mechaPilotCritical'] = frame['critical'] == true;
        token['mechaPilotExtra'] = true;
        if (frame['critical'] == true) {
          token['extraFastReactionCurrent'] =
              readIntValue(token['extraFastReactionCurrent']) + 1;
        } else {
          token['extraNormalReactionCurrent'] =
              readIntValue(token['extraNormalReactionCurrent']) + 1;
        }
      }
    }
    aggiungiLog(
      '[MECHA] Sei nell’abitacolo. Vita e statistiche ora sono del corpo del mecha; il pilota resta protetto.',
    );
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void syncMountedMechaBody() {
    final frame = mountedMecha;
    if (frame.isEmpty) return;
    final index = localSheetIndexForOculumTag('${frame['sheetTag']}');
    if (index < 0) return;
    final snapshot = statoCorrenteJson();
    (schedePersonaggio[index]['planarRuntime']
        as Map)['plasmaTemporaryMatter'] = readIntValue(
      planarState['plasmaTemporaryMatter'],
    );
    for (final key in _mechaBodyFields) {
      if (snapshot.containsKey(key)) {
        schedePersonaggio[index][key] = snapshot[key];
      } else {
        schedePersonaggio[index].remove(key);
      }
    }
  }

  Future<void> exitMecha({
    bool destroyed = false,
    int? explosionPercentile,
  }) async {
    final frame = mountedMecha;
    if (frame.isEmpty) return;
    if (!destroyed &&
        !await requestUtilitySpend('azione', preferFreeReaction: false)) {
      return;
    }
    syncMountedMechaBody();
    final owner = schedaCorrente;
    final current = statoCorrenteJson();
    final backup = Map<String, dynamic>.from(frame['pilotBackup'] as Map);
    final runtime = Map<String, dynamic>.from(planarState)
      ..remove('mountedMecha')
      ..remove('mechaBodyMaxHp');
    for (final key in _mechaBodyFields) {
      if (backup.containsKey(key)) {
        current[key] = backup[key];
      } else {
        current.remove(key);
      }
    }
    runtime['plasmaTemporaryMatter'] = readIntValue(
      (backup['planarRuntime'] as Map?)?['plasmaTemporaryMatter'],
    );
    current['planarRuntime'] = runtime;
    final index = localSheetIndexForOculumTag('${frame['sheetTag']}');
    if (index >= 0) {
      final body = schedePersonaggio[index]['planarRuntime'] as Map;
      (body['mechaFrame'] as Map)['occupiedBy'] = '';
    }
    final globals = catturaImpostazioniGlobali();
    schedePersonaggio[owner] = current;
    caricaStatoDaJson(current);
    ripristinaImpostazioniGlobali(globals);
    for (final token in masterInitiativeTokens) {
      if (publicInitiativeSourceTag(token) == '${frame['sheetTag']}') {
        token['mechaOccupied'] = false;
        if (destroyed) token['status'] = 'dead';
      }
      if (publicInitiativeSourceTag(token) == sheetTagAt(owner) &&
          token['mechaPilotExtra'] == true) {
        final field = token['mechaPilotCritical'] == true
            ? 'extraFastReactionCurrent'
            : 'extraNormalReactionCurrent';
        token[field] = max(0, readIntValue(token[field]) - 1);
        token.remove('mechaPilotExtra');
        token.remove('mechaPilotCritical');
      }
    }
    if (destroyed &&
        (explosionPercentile ?? Random.secure().nextInt(100)) < 30) {
      planarState['mechaExplosion'] = {
        'level': frame['level'],
        'id': '${frame['sheetTag']}:${DateTime.now().microsecondsSinceEpoch}',
      };
      aggiungiLog(
        '[MECHA DISTRUTTO] Esplosione (30%)! In Utility scegli la fuga con Reazione normale, veloce o senza Reazioni.',
      );
      if (explosionPercentile == null) unawaited(showMechaExplosionEscape());
    } else {
      aggiungiLog(
        destroyed
            ? '[MECHA] Corpo del mecha distrutto, nessuna esplosione. Pilota fuori.'
            : '[MECHA] Sei uscito. Statistiche e Vita originali ripristinate.',
      );
    }
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
    sendRealtimeHpChanged();
  }

  Future<void> showMechaExplosionEscape() async {
    if (planarState['mechaExplosion'] is! Map) return;
    final tokens = onlineCombatTokens();
    final token = tokens
        .where((t) => onlineCombatTokenTag(t) == sheetTagAt(schedaCorrente))
        .firstOrNull;
    final normal =
        token != null && masterInitiativeNormalReactionRemaining(token) > 0;
    final fast =
        token != null &&
        masterInitiativeFastReactionMax(token) >
            masterInitiativeFastReactionUsedThisTurn(token);
    final choice = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Fuga dal mecha'),
        content: Text(
          'Supera DT ${16 + readIntValue((planarState['mechaExplosion'] as Map)['level'])}. La veloce dà +5 aggiuntivo e, se fallisci, −25% danni. Esplosivo: +150% danni agli Scudi.',
        ),
        actions: [
          if (normal)
            TextButton(
              onPressed: () => Navigator.pop(dialog, 'reazione'),
              child: const Text('Reazione · 1d20'),
            ),
          if (fast)
            TextButton(
              onPressed: () => Navigator.pop(dialog, 'reazione_veloce'),
              child: const Text('Veloce · 1d20, +5'),
            ),
          if (!normal && !fast)
            TextButton(
              onPressed: () => Navigator.pop(dialog, 'none'),
              child: const Text('Senza Reazioni · 1d24'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Più tardi'),
          ),
        ],
      ),
    );
    if (choice != null && mounted) await resolveMechaEscape(choice);
  }

  Future<bool?> resolveMechaEscape(String resource, {int? natural}) async {
    final pending = planarState['mechaExplosion'];
    if (pending is! Map || pending['resolving'] == true) return null;
    final bonusToken = _writableOnlineCombatTokens()
        .where((t) => onlineCombatTokenTag(t) == sheetTagAt(schedaCorrente))
        .firstOrNull;
    final previousFastBonus = readIntValue(
      bonusToken?['pendingFastReactionRollBonus'],
    );
    final origin = currentSheetScrollId();
    if (resource != 'none' &&
        !await requestUtilitySpend(resource, preferFreeReaction: false)) {
      return null;
    }
    if (!mounted || currentSheetScrollId() != origin) return null;
    if (resource == 'reazione_veloce' && bonusToken != null) {
      final spentBonus = max(
        0,
        readIntValue(bonusToken['pendingFastReactionRollBonus']) -
            previousFastBonus,
      );
      bonusToken['pendingFastReactionRollBonus'] = previousFastBonus;
      if (realtimeService?.isConnected == true && spentBonus > 0) {
        pendingOnlineCombatTurnResourceSpends.add({
          'id': 'mecha-fast:${DateTime.now().microsecondsSinceEpoch}',
          'sheetTag': sheetTagAt(schedaCorrente),
          'resource': 'fast_reaction_roll_bonus',
          'amount': spentBonus,
        });
      }
    }
    pending['resolving'] = true;
    final reflex = hiddenEyeStats.where((s) => s.id == 'riflessi').firstOrNull;
    final faces = resource == 'none' ? 24 : 20;
    final die = natural ?? Random.secure().nextInt(faces) + 1;
    final level = leggiNumero(livelloController);
    final machineLevel = readIntValue(pending['level']);
    final total = oculumMechaEscapeTotal(
      die: die,
      reflexes: reflex == null ? 0 : hiddenEyeTotal(reflex),
      level: level,
      resource: resource,
    );
    final success = total > 16 + machineLevel;
    planarState.remove('mechaExplosion');
    mostraDadoCentrale(
      valore: '$die',
      criticoUno: die == 1,
      criticoVenti: die == faces,
    );
    aggiungiLog(
      '[FUGA MECHA] 1d$faces ($die) + bonus = $total / DT ${16 + machineLevel}: ${success ? 'fuga riuscita' : 'colpito dall’esplosione'}.',
    );
    if (!success) {
      final previous = incomingDamageElement;
      incomingDamageElement = 'esplosivo';
      try {
        await applicaDannoSubito(
          dannoEsplicito: oculumMechaExplosionDamage(
            machineLevel,
            fastReaction: resource == 'reazione_veloce',
          ),
          shieldDamageBonusPercent: 150,
        );
      } finally {
        incomingDamageElement = previous;
      }
    }
    programmaSalvataggio();
    return success;
  }
}
