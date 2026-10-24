part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member
const oculumAlchemyPets = <(String, String, String, String, int)>[
  (
    'lumachina_vetro',
    'Lumachina di Vetro',
    'Un piccolo mollusco traslucido; ricostruisce il guscio grazie a una secrezione minerale.',
    'scudo',
    3,
  ),
  (
    'falena_lattea',
    'Falena Lattea',
    'Una falena pallida che deposita polvere curativa sugli alleati.',
    'cura',
    3,
  ),
  (
    'germoglio_cucito',
    'Germoglio Cucito',
    'Un germoglio animato che richiude le proprie ferite con filamenti vegetali.',
    'cura',
    5,
  ),
];

extension _OculumAlchemyPets on _OculumHomePageState {
  Future<void> activateAlchemyPet(InventoryItem item) async {
    if (!inventario.contains(item) || item.quantita <= 0) return;
    final owner = sheetTagAt(schedaCorrente);
    await forzaSalvataggioImmediato(soloLocale: true);
    final id = '${item.craftData['alchemyPet']}';
    final meccanio = id == 'meccanio';
    if (meccanio && ownsMeccanio(owner)) {
      aggiungiLog('Puoi possedere un solo Meccanio. Il compagno non viene consumato.');
      return;
    }
    final spec = meccanio
        ? (
            'meccanio',
            'Meccanio',
            monsterBookEntryById('meccanio')!.descIt,
            'cura',
            0,
          )
        : oculumAlchemyPets.where((p) => p.$1 == id).firstOrNull;
    if (spec == null) return;
    final before = schedePersonaggio
        .map((s) => '${s['id'] ?? s['sheetTag']}')
        .toSet();
    final oldName = quickSheetNameController.text,
        oldDescription = quickSheetDescriptionController.text,
        oldCount = quickSheetCountController.text;
    quickSheetNameController.text = spec.$2;
    quickSheetDescriptionController.text = spec.$3;
    quickSheetCountController.text = '1';
    try {
      await creaSchedaRapidaMaster(
        forcedType: 'NPC',
        fallbackName: spec.$2,
        sideOverride: 'ally',
        forceEnemyProfile: false,
        livelloForzato: 0,
        statsMostroForzate: {
          'resilienza': meccanio ? 4 : 2,
          'volonta': 2,
          'materia': meccanio ? 4 : 1,
          'oculum': meccanio ? 0 : 1,
        },
      );
    } finally {
      quickSheetNameController.text = oldName;
      quickSheetDescriptionController.text = oldDescription;
      quickSheetCountController.text = oldCount;
    }
    final index = schedePersonaggio.indexWhere(
      (s) => !before.contains('${s['id'] ?? s['sheetTag']}'),
    );
    if (index < 0) return;
    final self = id == 'germoglio_cucito';
    final skill = CharacterSkill(
      nome: id == 'lumachina_vetro'
          ? 'Bava ricostruttiva'
          : self
          ? 'Ricucitura vegetale'
          : 'Polvere lattea',
      tipo: 'Supporto',
      costo: '1/1 Volontà',
      cooldown: '3 turni',
      descrizione: spec.$3,
      equipaggiata: true,
      forme: [
        CharacterSkillForm(
          nome: 'I',
          livello: '0',
          tipo: 'Supporto',
          costo: '1/1 Volontà',
          cooldown: '3 turni',
          descrizione: spec.$3,
          costoStrutturato: OculumSkillCost(
            resource: 'volonta',
            amountExpression: '1',
          ),
          effettiStrutturati: [
            OculumStructuredEffect(
              type: spec.$4,
              valueExpression: '${spec.$5}',
              recipient: self ? 'se_stesso' : 'alleato',
              duration: '0',
            ),
          ],
        ),
      ],
    );
    final regeneration = CharacterSkill(
      nome: 'Rigenerazione · ${spec.$2}',
      cooldown: 'Nessuno',
      tipo: 'Passiva',
      equipaggiata: true,
      costo: 'Nessun costo',
      descrizione:
          'All’inizio del proprio turno recupera 1 Vita se ancora vivo. Non rianima.',
      forme: [
        CharacterSkillForm(
          nome: 'I',
          livello: '0',
          tipo: 'Passiva',
          costo: 'Nessun costo',
          descrizione: 'Rigenerazione del corpo alchemico.',
          effettiStrutturati: [
            OculumStructuredEffect(
              type: 'cura',
              valueExpression: '1',
              recipient: 'se_stesso',
            ),
          ],
        ),
      ],
    );
    final sheet = schedePersonaggio[index];
    final savedSkills = meccanio
        ? <dynamic>[]
        : [
            ...(sheet['skills'] as List? ?? []),
            skill.toJson(),
            regeneration.toJson(),
          ];
    sheet['skills'] = savedSkills;
    sheet['inMasterParty'] = true;
    sheet['alchemyPet'] = id;
    if (meccanio) {
      sheet['monsterBookSourceId'] = 'meccanio';
      sheet['meccanioOwnerTag'] = owner;
      configureMeccanio(index);
    }
    if (index == schedaCorrente) {
      if (meccanio) {
        skills..clear()..addAll(meccanioLoadoutSkills(Map<String, dynamic>.from(sheet['meccanio'] as Map)));
      } else {
        skills.addAll([skill, regeneration]);
      }
    }
    if (sheetTagAt(schedaCorrente) == owner) {
      item.quantita--;
      if (item.quantita <= 0) inventario.remove(item);
    } else {
      final ownerIndex = localSheetIndexForOculumTag(owner);
      if (ownerIndex >= 0) {
        final items =
            (schedePersonaggio[ownerIndex]['inventario'] as List? ?? [])
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
        final found = items.indexWhere(
          (e) =>
              e['craftData'] is Map &&
              (e['craftData'] as Map)['alchemyPet'] == id,
        );
        if (found >= 0) {
          final n = readIntValue(items[found]['quantita'], fallback: 1) - 1;
          if (n <= 0) {
            items.removeAt(found);
          } else {
            items[found]['quantita'] = n;
          }
          schedePersonaggio[ownerIndex]['inventario'] = items;
        }
      }
    }
    aggiungiLog(
      '${spec.$2} entra nel Party con ${meccanio ? 'autoriparazione tramite Meccanica' : skill.nome}.',
    );
    programmaSalvataggio();
    setState(() {});
  }
}
