part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Exact total power is an encounter budget, not a change to a species' base
/// catalogue. Level/Grade growth is retained; spare points keep its own build.
Map<String, dynamic> oculumWorldTravelCreatureBuild(
  MonsterBookEntry monster,
  int targetPower,
) {
  final target = max(1, targetPower).toInt();
  var level = 0;
  for (var candidate = 1; candidate <= 240; candidate++) {
    final stats = oculumMonsterCreationStats(monster, candidate);
    final power =
        stats.values.fold<int>(0, (sum, value) => sum + value) +
        candidate +
        3 * oculumGradeForLevel(candidate) +
        oculumHpTotalPowerBonusForGrade(
          oculumGradeForLevel(candidate),
          level: candidate,
        );
    if (power > target) break;
    level = candidate;
  }
  final grade = oculumGradeForLevel(level);
  final hpPower = oculumHpTotalPowerBonusForGrade(grade, level: level);
  final budget = max(1, target - level - 3 * grade - hpPower).toInt();
  final base = oculumMonsterCreationStats(monster, level);
  final original = base.values.fold<int>(0, (sum, value) => sum + value);
  final stats = <String, int>{
    for (final key in const ['resilienza', 'volonta', 'materia', 'oculum'])
      key: original == 0 ? 0 : (budget * (base[key] ?? 0) / original).floor(),
  };
  var assigned = stats.values.fold<int>(0, (sum, value) => sum + value);
  final ranked = stats.keys.toList()
    ..sort((a, b) => (base[b] ?? 0).compareTo(base[a] ?? 0));
  for (var step = 0; assigned < budget; step++, assigned++) {
    stats[ranked[step % ranked.length]] =
        stats[ranked[step % ranked.length]]! + 1;
  }
  if (stats['resilienza'] == 0) {
    final donor = ranked
        .where((key) => key != 'resilienza' && stats[key]! > 0)
        .firstOrNull;
    if (donor != null) {
      stats[donor] = stats[donor]! - 1;
      stats['resilienza'] = 1;
    }
  }
  return {
    'level': level,
    'grade': grade,
    'stats': stats,
    'power': budget + level + 3 * grade + hpPower,
  };
}

Map<String, dynamic> oculumWorldMimicLoot({
  required int level,
  required int grade,
  required String killId,
  Random? random,
}) {
  final rng = random ?? Random.secure();
  final monster = monsterById('mimic_base');
  final options = monster == null
      ? <InventoryItem>[]
      : oculumMonsterEquipmentCatalogue(
          source: monster,
          level: level,
          grade: grade,
        );
  final die = rng.nextInt(20) + 1;
  final item = options.isEmpty
      ? null
      : InventoryItem.fromJson(options[rng.nextInt(options.length)].toJson());
  if (item != null) {
    item.monsterLoot = {
      ...item.monsterLoot,
      'id': '$killId:mimic-equipment',
      'killId': killId,
      'guaranteedTravelMimicDrop': true,
    };
  }
  return {
    'obser': die + max(0, level) + 5 * max(0, grade),
    'natural': die,
    if (item != null) 'item': item.toJson(),
  };
}

List<Map<String, String>> oculumWorldRealmMerchants(String realm) {
  final (material, alchemist, smith) = switch (realm) {
    'reame_cristallo' => (
      'Cartografo delle Geodi',
      'Risonante dei Cristalli',
      'Fabbro del Prisma',
    ),
    'deserto_divoratore' => (
      'Raccoglitore della Sabbia Umida',
      'Distillatrice di Vetro Azzurro',
      'Fabbro d’Arenaria',
    ),
    'carne_viva' => (
      'Custode dei Bozzoli',
      'Alchimista dei Tessuti Vivi',
      'Intagliatore d’Ossa',
    ),
    'orea_zalira' => (
      'Mercante delle Tasche Morbide',
      'Mescolatrice dei Fiumi Mutevoli',
      'Modellatore delle Forme',
    ),
    'postea' => (
      'Recuperatore Runico',
      'Tecnico delle Essenze',
      'Officina di Rusty',
    ),
    'ghiaccio' => (
      'Raccoglitore di Brina',
      'Distillatore del Ghiaccio',
      'Fabbro del Permafrost',
    ),
    'oblio' || 'shadow_hell' => (
      'Raccoglitore dei Ricordi Vuoti',
      'Alchimista del Crepuscolo',
      'Forgia Senza Riflesso',
    ),
    'sotterraneo' || 'sotterraneo_maggiore' => (
      'Cercatore delle Vene',
      'Speziale dei Funghi',
      'Fabbro delle Gallerie',
    ),
    _ => (
      'Raccoglitore del Luogo',
      'Alchimista Itinerante',
      'Fabbro della Carovana',
    ),
  };
  return [
    {'name': material, 'shopType': 'materiali', 'realm': realm},
    {'name': alchemist, 'shopType': 'alchimista', 'realm': realm},
    {'name': smith, 'shopType': 'fabbro', 'realm': realm},
    {'name': 'Sartoria della Carovana', 'shopType': 'sartoria', 'realm': realm},
    {'name': 'Cuoco del Cammino', 'shopType': 'chef', 'realm': realm},
    if (const {'oblio', 'shadow_hell', 'carne_viva'}.contains(realm))
      {
        'name': 'Banco delle Trattative Nascoste',
        'shopType': 'mercato_nero',
        'realm': realm,
      },
  ];
}

extension _OculumWorldTravel on _OculumHomePageState {
  bool worldTravelMemberChaos(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return false;
    final sheet = schedePersonaggio[index];
    final monster = monsterById('${sheet['monsterBookSourceId'] ?? ''}');
    final values = [
      sheet['razza'],
      sheet['elemento'],
      sheet['elementoDanno'],
      sheet['naturalElements'],
      monster?.elementId,
    ];
    return values.any(
      (value) => RegExp(r'\bchaos\b', caseSensitive: false).hasMatch('$value'),
    );
  }

  Future<void> showWorldTravelDialog() async {
    if (!worldClockAuthority && !realtimeIsCoMasterRole) return;
    final campaign = activeCampaignId, scope = permissionScope;
    final clock = worldClockProgress;
    final originalTags = {
      for (var index = 0; index < schedePersonaggio.length; index++)
        index: sheetTagAt(index),
    };
    final members = questPartyIndices().toSet();
    var mode = '${clock.travelSettings['mode'] ?? 'walk'}';
    if (!const {'walk', 'vehicle'}.contains(mode)) mode = 'walk';
    final distance = TextEditingController();
    final speed = TextEditingController(
      text:
          '${readDoubleValue(clock.travelSettings['totalSpeedPercent'], fallback: 500)}',
    );
    var chaosOverride = members.any(worldTravelMemberChaos);
    final receipt =
        'journey:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 30)}';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, refresh) {
          int? duration;
          String error = '';
          final metres = double.tryParse(distance.text.replaceAll(',', '.'));
          final percent = double.tryParse(speed.text.replaceAll(',', '.'));
          try {
            duration = oculumWorldTravelSeconds(
              metres ?? 0,
              members.map(sheetMovementAt),
              totalSpeedPercent: mode == 'walk' ? 100 : percent ?? 0,
            );
          } on ArgumentError catch (exception) {
            error = '${exception.message}';
          }
          return AlertDialog(
            title: const Text('Viaggio del party'),
            content: SizedBox(
              width: 580,
              height: min(530, MediaQuery.sizeOf(dialog).height * .65),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: mode,
                      decoration: const InputDecoration(
                        labelText: 'Modo di viaggio',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'walk', child: Text('A piedi')),
                        DropdownMenuItem(
                          value: 'vehicle',
                          child: Text('Con un mezzo'),
                        ),
                      ],
                      onChanged: (value) =>
                          refresh(() => mode = value ?? 'walk'),
                    ),
                    TextField(
                      controller: distance,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Distanza in metri',
                      ),
                      onChanged: (_) => refresh(() {}),
                    ),
                    if (mode == 'vehicle') ...[
                      TextField(
                        controller: speed,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Velocità totale rispetto a piedi (%)',
                        ),
                        onChanged: (_) => refresh(() {}),
                      ),
                      const Text(
                        '500% = cinque volte la velocità. Carro, macchina di Postea o altro mezzo: '
                        'il Master decide quello disponibile; nessun oggetto è aggiunto all’inventario.',
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Movimento medio del party: metri percorsi in 10 secondi.',
                    ),
                    for (final index in originalTags.keys.where(
                      (index) =>
                          index < schedePersonaggio.length &&
                          sheetTagAt(index) == originalTags[index],
                    ))
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(nomeSchedaPersonaggio(index)),
                        subtitle: Text('Movimento ${sheetMovementAt(index)}'),
                        value: members.contains(index),
                        onChanged: (value) => refresh(() {
                          value == true
                              ? members.add(index)
                              : members.remove(index);
                          chaosOverride = members.any(worldTravelMemberChaos);
                        }),
                      ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: chaosOverride,
                      title: const Text('Almeno un viaggiatore del Chaos'),
                      subtitle: const Text(
                        'Eventi: 90% anziché 75% ogni 25 minuti di viaggio.',
                      ),
                      onChanged: (value) =>
                          refresh(() => chaosOverride = value ?? false),
                    ),
                    if (duration != null)
                      Text(
                        'Durata: ${oculumWorldDuration(duration)}. '
                        'Il viaggio continua anche quando genera eventi per il Master.',
                      ),
                    if (duration == null) Text(error),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: duration == null
                    ? null
                    : () => Navigator.pop(dialog, true),
                child: Text(
                  worldClockAuthority ? 'Conferma viaggio' : 'Chiedi al Master',
                ),
              ),
            ],
          );
        },
      ),
    );
    final metres = double.tryParse(distance.text.replaceAll(',', '.'));
    final percent = double.tryParse(speed.text.replaceAll(',', '.'));
    distance.dispose();
    speed.dispose();
    if (accepted != true ||
        metres == null ||
        !mounted ||
        activeCampaignId != campaign ||
        permissionScope != scope) {
      return;
    }
    final selectedTags = members
        .map((index) => originalTags[index])
        .whereType<String>()
        .toList();
    final stableMembers = selectedTags
        .map(localSheetIndexForOculumTag)
        .toList();
    if (stableMembers.length != members.length ||
        stableMembers.any((index) => index < 0)) {
      return;
    }
    if (worldClockAuthority) {
      commitWorldTravel(
        receipt: receipt,
        metres: metres,
        members: stableMembers,
        chaos: chaosOverride,
        mode: mode,
        totalSpeedPercent: mode == 'walk' ? 100 : percent ?? 500,
      );
    } else {
      await realtimeService?.sendCombatEvent(
        'initiative_control',
        permissionEnvelope({
          'id': receipt,
          'worldClockCommand': 'travel_request',
          'metres': metres,
          'mode': mode,
          'totalSpeedPercent': mode == 'walk' ? 100 : percent ?? 500,
          'chaos': chaosOverride,
          'memberTags': selectedTags,
        }),
      );
    }
  }

  void receiveWorldTravelRequest(Map<String, dynamic> payload) {
    if (!worldClockAuthority || !validPermissionSender(payload, staff: true)) {
      return;
    }
    final id = '${payload['id'] ?? ''}';
    if (id.isEmpty ||
        id.length > 240 ||
        readDoubleValue(payload['metres']) <= 0 ||
        payload['memberTags'] is! List) {
      return;
    }
    final clock = worldClockProgress;
    if (clock.receipts.contains(id) ||
        clock.events.any((event) => event['id'] == id)) {
      return;
    }
    clock.events.add({
      'id': id,
      'kind': 'travel_request',
      'status': 'pending',
      'request': {
        for (final key in [
          'metres',
          'mode',
          'totalSpeedPercent',
          'chaos',
          'memberTags',
        ])
          key: payload[key],
      },
      'realm': selectedPlaneId,
      'check': 'richiesta Co-Master',
    });
    storeWorldClock(clock, publish: false);
  }

  List<MonsterBookEntry> worldTravelMonsters(String realm) => monsterBookEntries
      .where(
        (monster) =>
            !monster.isNpc &&
            monster.planeIds.contains(realm) &&
            !monster.id.startsWith('pawn_guardiano'),
      )
      .toList();

  bool chooseWorldTravelEvent(
    String id,
    String choice, {
    String? monsterId,
    int enemyCount = 1,
    List<int> merchantIndexes = const [],
    Random? random,
  }) {
    if (!worldClockAuthority ||
        !const {
          'fight',
          'chest',
          'merchant',
          'merchants',
          'resolved',
        }.contains(choice)) {
      return false;
    }
    final clock = worldClockProgress;
    final event = clock.events.where((row) => row['id'] == id).firstOrNull;
    if (event == null || event['kind'] == 'travel_request') return false;
    if (choice == 'resolved') {
      event['status'] = 'resolved';
      storeWorldClock(clock, publish: false);
      return true;
    }
    if (event['choice'] != null) return event['choice'] == choice;
    final rng = random ?? Random.secure();
    final party = (event['party'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final power = party.fold<int>(
      0,
      (sum, member) => sum + readIntValue(member['power']),
    );
    final highest = party.fold<int>(
      0,
      (value, member) => max(value, readIntValue(member['power'])),
    );
    if (choice == 'fight' && power <= 0) return false;
    final realm = '${event['realm']}';
    if (choice == 'fight') {
      final candidates = worldTravelMonsters(realm);
      final monster = candidates
          .where((monster) => monster.id == monsterId)
          .firstOrNull;
      if (monster == null) return false;
      final target = (power * 1.25).ceil();
      final count = enemyCount.clamp(1, min(12, max(1, target))).toInt();
      final creatures = <Map<String, dynamic>>[];
      for (var index = 0; index < count; index++) {
        final budget = target ~/ count + (index < target % count ? 1 : 0);
        creatures.add({
          'monsterId': monster.id,
          ...oculumWorldTravelCreatureBuild(monster, budget),
        });
      }
      event['creatures'] = creatures;
      event['targetPower'] = target;
    } else if (choice == 'chest') {
      final roll = rng.nextInt(100) + 1;
      final mimic = roll <= (realm == 'carne_viva' ? 50 : 10);
      event['mimicRoll'] = roll;
      event['mimic'] = mimic;
      if (mimic) {
        final monster = monsterById('mimic_base');
        if (monster == null) return false;
        event['creatures'] = [
          {
            'monsterId': monster.id,
            ...oculumWorldTravelCreatureBuild(
              monster,
              max(highest + 1, (highest * 1.10).ceil()),
            ),
          },
        ];
      }
    } else {
      final merchants = oculumWorldRealmMerchants(realm);
      final indexes = merchantIndexes
          .where((index) => index >= 0 && index < merchants.length)
          .toSet();
      if (indexes.isEmpty || choice == 'merchant' && indexes.length != 1) {
        return false;
      }
      event['merchants'] = indexes.map((index) => merchants[index]).toList();
    }
    event['choice'] = choice;
    event['status'] = 'prepared';
    storeWorldClock(clock, publish: false);
    return true;
  }

  String prepareWorldTravelEncounter(String eventId) {
    if (!worldClockAuthority) return '';
    final clock = worldClockProgress;
    final event = clock.events.where((row) => row['id'] == eventId).firstOrNull;
    if (event == null || event['creatures'] is! List) return '';
    final old = '${event['encounterId'] ?? ''}';
    if (old.isNotEmpty) return old;
    final creatures = (event['creatures'] as List).whereType<Map>().toList();
    if (creatures.isEmpty ||
        creatures.any(
          (creature) =>
              monsterById('${creature['monsterId']}') == null ||
              creature['stats'] is! Map ||
              readIntValue((creature['stats'] as Map)['resilienza']) <= 0,
        )) {
      return '';
    }
    final id =
        'travel_encounter:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 30)}';
    final tokens = <Map<String, dynamic>>[];
    for (final raw in event['party'] as List? ?? const []) {
      if (raw is! Map) continue;
      final index = localSheetIndexForOculumTag('${raw['tag']}');
      if (index < 0) continue;
      tokens.add({
        'id': sheetTagAt(index),
        'sheetTag': sheetTagAt(index),
        'name': nomeSchedaPersonaggio(index),
        'side': 'party',
        'status': 'ready',
      });
    }
    for (final raw in creatures) {
      final monster = monsterById('${raw['monsterId']}');
      if (monster == null || raw['stats'] is! Map) return '';
      final stats = Map<String, dynamic>.from(raw['stats'] as Map);
      final level = readIntValue(raw['level']),
          grade = readIntValue(raw['grade']);
      final tag = generaTagUnicoScheda(
        schedePersonaggio.length,
        schedePersonaggio
            .map((sheet) => '${sheet['sheetTag'] ?? sheet['id']}'.toUpperCase())
            .toSet(),
      );
      final sheet =
          statoVuotoPersonaggio(
            nome: monster.nameIt,
            tipo: monster.presetType,
            livello: level,
            grado: grade,
          )..addAll({
            'id': tag,
            'sheetTag': tag,
            'monsterBookSourceId': monster.id,
            'monsterBaseStats': {
              for (final key in const [
                'resilienza',
                'volonta',
                'materia',
                'oculum',
              ])
                key: monster.stats[key] ?? 0,
            },
            'monsterStatPoints': '0',
            'worldTravelEventId': eventId,
            'worldTravelPowerOverride': readIntValue(raw['power']),
            'descrizioneCreatura': monster.descIt,
            'puntoDebole': monster.weakPointIt,
            'currentHp':
                '${readIntValue(stats['resilienza']) * oculumHpMultiplierForGrade(grade, level: level)}',
            'skills': oculumMonsterBookSkills(
              monster,
            ).map((skill) => skill.toJson()).toList(),
            'arti': <Map<String, dynamic>>[],
            if (oculumMonsterBookImportArt(monster) case final art?)
              'arti': [art.toJson()],
            for (final key in const [
              'resilienza',
              'volonta',
              'materia',
              'oculum',
            ])
              key: '${stats[key]}',
            'currentResilienza': '${stats['resilienza']}',
            'currentVolonta': '${stats['volonta']}',
            'currentMateria': '${stats['materia']}',
            'currentOculum': '${stats['oculum']}',
            'normalCurrentOculum': stats['oculum'],
            'maxOculum': stats['oculum'],
            if (event['mimic'] == true) 'travelMimic': true,
          });
      schedePersonaggio.add(sheet);
      tokens.add({
        'id': tag,
        'sheetTag': tag,
        'name': monster.nameIt,
        'type': monster.presetType,
        'monsterBookSourceId': monster.id,
        'side': 'enemy',
        'status': 'ready',
        'currentHp':
            readIntValue(stats['resilienza']) *
            oculumHpMultiplierForGrade(grade, level: level),
        'maxHp':
            readIntValue(stats['resilienza']) *
            oculumHpMultiplierForGrade(grade, level: level),
        'level': level,
        'grade': grade,
        'totalPower': readIntValue(raw['power']),
        'manualLevelGradeOverride': true,
        'rewardPermanentCoreStats': stats,
        'statsTotal': stats.values.fold<int>(
          0,
          (sum, value) => sum + readIntValue(value),
        ),
        if (event['mimic'] == true) 'travelMimic': true,
      });
    }
    masterInitiativeGroups.add({
      'id': id,
      'name': event['mimic'] == true
          ? 'Mimic del viaggio'
          : 'Incontro del viaggio',
      'tokens': tokens,
      'round': 0,
      'activeIndex': 0,
      'manualOrder': false,
      'published': false,
      'manualCounter': 0,
      'worldTravelEventId': eventId,
    });
    event['encounterId'] = id;
    storeWorldClock(clock, publish: false);
    return id;
  }

  Future<void> showWorldTravelEventDialog(String id) async {
    if (!worldClockAuthority) return;
    final campaign = activeCampaignId;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, refresh) {
          final event = worldClockProgress.events
              .where((row) => row['id'] == id)
              .firstOrNull;
          if (event == null) return const SizedBox.shrink();
          final realm = '${event['realm']}';
          final candidates = worldTravelMonsters(realm);
          return AlertDialog(
            title: const Text('Evento privato del Master'),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nessun dettaglio di questa coda viene inviato ai giocatori. Il viaggio è già proseguito.',
                    ),
                    if (event['kind'] == 'travel_request') ...[
                      Text('Richiesta Co-Master: ${event['request']}'),
                      FilledButton(
                        onPressed: () {
                          final request = event['request'] as Map;
                          final tags =
                              (request['memberTags'] as List? ?? const [])
                                  .map((tag) => '$tag')
                                  .toList();
                          final indexes = tags
                              .map(localSheetIndexForOculumTag)
                              .where((index) => index >= 0)
                              .toList();
                          if (indexes.length != tags.length) return;
                          if (commitWorldTravel(
                            receipt: id,
                            metres: readDoubleValue(request['metres']),
                            members: indexes,
                            chaos: request['chaos'] == true,
                            mode: '${request['mode']}',
                            totalSpeedPercent: readDoubleValue(
                              request['totalSpeedPercent'],
                              fallback: 100,
                            ),
                          )) {
                            final clock = worldClockProgress;
                            clock.events.firstWhere(
                              (row) => row['id'] == id,
                            )['status'] = 'resolved';
                            storeWorldClock(clock, publish: false);
                            Navigator.pop(dialog);
                          }
                        },
                        child: const Text('Conferma viaggio del party'),
                      ),
                    ] else if (event['choice'] == null) ...[
                      FilledButton(
                        onPressed: candidates.isEmpty
                            ? null
                            : () async {
                                final selected =
                                    await chooseWorldTravelCreature(candidates);
                                if (selected == null ||
                                    !mounted ||
                                    activeCampaignId != campaign) {
                                  return;
                                }
                                chooseWorldTravelEvent(
                                  id,
                                  'fight',
                                  monsterId: selected.$1,
                                  enemyCount: selected.$2,
                                );
                                refresh(() {});
                              },
                        child: const Text('Fight · PT nemica 125% del party'),
                      ),
                      FilledButton(
                        onPressed: () {
                          chooseWorldTravelEvent(id, 'chest');
                          refresh(() {});
                        },
                        child: const Text('Baule'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          final picked = await chooseWorldTravelMerchants(
                            realm,
                          );
                          if (picked.isEmpty ||
                              !mounted ||
                              activeCampaignId != campaign) {
                            return;
                          }
                          chooseWorldTravelEvent(
                            id,
                            picked.length == 1 ? 'merchant' : 'merchants',
                            merchantIndexes: picked,
                          );
                          refresh(() {});
                        },
                        child: const Text('Mercante o carovana'),
                      ),
                    ] else ...[
                      Text('Scelta: ${event['choice']}'),
                      if (event['choice'] == 'chest')
                        Text(
                          event['mimic'] == true
                              ? 'Mimic: il responso resta privato finché lo riveli.'
                              : 'Forziere normale: il Master prepara il contenuto coerente con il luogo.',
                        ),
                      if (event['creatures'] is List) ...[
                        for (final creature
                            in (event['creatures'] as List).whereType<Map>())
                          Text(
                            '${creature['monsterId']} · Lv${creature['level']} · G${creature['grade']} · PT${creature['power']}',
                          ),
                        FilledButton(
                          onPressed: () {
                            prepareWorldTravelEncounter(id);
                            refresh(() {});
                          },
                          child: Text(
                            event['encounterId'] == null
                                ? 'Prepara turnistica una volta'
                                : 'Turnistica già preparata',
                          ),
                        ),
                      ],
                      if (event['merchants'] is List)
                        for (final merchant
                            in (event['merchants'] as List).whereType<Map>())
                          ListTile(
                            title: Text('${merchant['name']}'),
                            subtitle: Text('${merchant['shopType']} · $realm'),
                            onTap: () => openWorldTravelMerchant(
                              id,
                              Map<String, dynamic>.from(merchant),
                            ),
                          ),
                      TextButton(
                        onPressed: () {
                          chooseWorldTravelEvent(id, 'resolved');
                          Navigator.pop(dialog);
                        },
                        child: const Text('Evento gestito'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Chiudi'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<(String, int)?> chooseWorldTravelCreature(
    List<MonsterBookEntry> candidates,
  ) async {
    String selected = candidates.first.id;
    var count = 1;
    return showDialog<(String, int)>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, refresh) => AlertDialog(
          title: const Text('Mostri coerenti con il luogo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                items: [
                  for (final monster in candidates)
                    DropdownMenuItem(
                      value: monster.id,
                      child: Text(
                        monster.nameIt,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) =>
                    refresh(() => selected = value ?? selected),
              ),
              DropdownButtonFormField<int>(
                initialValue: count,
                decoration: const InputDecoration(
                  labelText: 'Numero di creature',
                ),
                items: [
                  for (var value = 1; value <= 8; value++)
                    DropdownMenuItem(value: value, child: Text('$value')),
                ],
                onChanged: (value) => refresh(() => count = value ?? 1),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, (selected, count)),
              child: const Text('Prepara'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<int>> chooseWorldTravelMerchants(String realm) async {
    final selected = <int>{};
    final merchants = oculumWorldRealmMerchants(realm);
    return await showDialog<List<int>>(
          context: context,
          builder: (dialog) => StatefulBuilder(
            builder: (dialog, refresh) => AlertDialog(
              title: const Text('Banchi della carovana'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < merchants.length; index++)
                        CheckboxListTile(
                          value: selected.contains(index),
                          title: Text(merchants[index]['name']!),
                          subtitle: Text(merchants[index]['shopType']!),
                          onChanged: (value) => refresh(
                            () => value == true
                                ? selected.add(index)
                                : selected.remove(index),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(dialog, selected.toList()),
                  child: const Text('Prepara banchi'),
                ),
              ],
            ),
          ),
        ) ??
        [];
  }

  void openWorldTravelMerchant(String eventId, Map<String, dynamic> merchant) {
    if (!worldClockAuthority) return;
    final id = '$eventId:merchant:${merchant['shopType']}';
    if (!merchantProfiles.any((profile) => profile['id'] == id)) {
      merchantProfiles.add({
        'id': id,
        'name': merchant['name'],
        'shopType': merchant['shopType'],
        'realmId': merchant['realm'],
        'stock': <Map<String, dynamic>>[],
        'pricePercent': 100,
        'worldTravelEventId': eventId,
      });
    }
    switchMerchantProfile(id);
    unawaited(showMerchantDialog());
  }
}
