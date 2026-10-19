part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool oculumWitheredLarvaMonster(MonsterBookEntry monster) =>
    monster.id == 'costrutto_rinsecchito' || monster.id == 'larva_bianca';

List<OculumStructuredEffect> oculumWitheredLarvaEffects(String id, int form) {
  OculumStructuredEffect effect(
    String type,
    String value, {
    String target = '',
    String duration = '',
    String mode = 'immediato',
    String recipient = 'se_stesso',
    String option = '',
    String resource = '',
  }) => OculumStructuredEffect(
    id: '${id}_${form}_$type$option',
    type: type,
    valueExpression: value,
    target: target,
    appliedState: type == 'stato' ? target : '',
    resource: resource,
    duration: duration,
    mode: mode,
    recipient: recipient,
    activationOption: option,
    elementType: type == 'danno' ? 'fisico' : '',
  );
  return switch (id) {
    'withered_shield' => [
      effect('scudo', ['5+materia*2', '12+materia*3', '24+materia*4'][form]),
    ],
    'withered_memory' => [
      effect(
        'stato',
        '1',
        target: 'ricordo_vitale',
        duration: 'oculum+oculum_spent',
        resource: 'oculum_upkeep',
      ),
    ],
    'withered_strike' => [
      effect(
        'danno',
        ['4+oculum', 'floor((12+oculum)*1.5)', '(34+oculum)*2'][form],
        mode: 'prossima_azione',
      ),
    ],
    'white_larva_assault' => [
      effect(
        'danno',
        ['5+oculum', '15+floor(oculum*1.5)', '45+oculum*2'][form],
        mode: 'prossima_azione',
      ),
    ],
    'white_larva_brood' => [
      effect(
        'costrutto',
        ['1d100', '1d200+20', '1d250+100'][form],
        target: 'Nidiata di larve',
        mode: 'nidiata',
        duration: '-1',
      ),
    ],
    'white_larva_burrow' => [
      effect('tiro_sottotratto', '0', target: 'velo', option: 'Fuga'),
      effect(
        'stato',
        '1',
        target: 'scavata_svantaggio_alto',
        duration: '1',
        recipient: 'bersaglio',
        option: 'Attacco',
      )..durationUnit = 'tiri',
    ],
    _ => [],
  };
}

List<CharacterSkill> oculumWitheredLarvaSkills(MonsterBookEntry monster) => [
  for (final id in monster.skillIds)
    CharacterSkill(
      nome: switch (id) {
        'withered_shield' => 'Scudo di rami',
        'withered_memory' => 'Ricordo del nucleo',
        'withered_strike' => 'Ramo spezzato',
        'white_larva_assault' => 'Assalto',
        'white_larva_brood' => 'Infestazione · Nidiata',
        _ => 'Scavata',
      },
      tipo: 'Skill naturale mostro',
      costo: '',
      cooldown: '',
      descrizione: monsterBookSkillText(id),
      equipaggiata: true,
      forme: [
        for (var f = 0; f < 3; f++)
          CharacterSkillForm(
            nome: const ['I', 'II', 'III'][f],
            tipo: 'Skill naturale mostro',
            livello: '${f * 3}',
            descrizione: monsterBookSkillText(id),
            // Costs are authored below; CD and damage fractions in the prose
            // must not be reinterpreted as an Oculum spending range on reload.
            oculumLimitiConfiguratiManualmente: true,
            oculumMinimoUtilizzabile: id == 'withered_memory' ? 1 : 0,
            oculumMassimoUtilizzabile: id == 'withered_memory' ? 1 : 0,
            costo: id.startsWith('white_larva')
                ? 'Nessun costo'
                : id == 'withered_memory'
                ? '1 Oculum, poi 1 per turno'
                : id == 'withered_shield'
                ? '1 Materia'
                : '${f + 1} Volontà',
            costoStrutturato: OculumSkillCost(
              resource: id.startsWith('white_larva')
                  ? 'nessuna'
                  : id == 'withered_memory'
                  ? 'oculum'
                  : id == 'withered_shield'
                  ? 'materia'
                  : 'volonta',
              amountExpression: id.startsWith('white_larva')
                  ? '0'
                  : id == 'withered_strike'
                  ? '${f + 1}'
                  : '1',
            ),
            cooldown: '${oculumWitheredLarvaCooldown(id, f)} turni',
            cooldownStrutturato: OculumAbilityCooldown(
              amount: oculumWitheredLarvaCooldown(id, f),
            ),
            effettiStrutturati: oculumWitheredLarvaEffects(id, f),
          ),
      ],
    ),
];

int oculumWitheredLarvaCooldown(String id, int form) => switch (id) {
  'white_larva_brood' => [4, 6, 8][form],
  'white_larva_burrow' => [3, 4, 5][form],
  'white_larva_assault' || 'withered_shield' => [2, 3, 4][form],
  'withered_memory' => [3, 3, 3][form],
  _ => [1, 2, 3][form],
};

CharacterArt oculumWitheredLarvaArt(MonsterBookEntry monster) {
  final skills = oculumWitheredLarvaSkills(monster);
  return CharacterArt(
    nome: 'Tecniche — ${monster.nameIt}',
    tipo: 'Tecniche naturali',
    descrizione: monster.descIt,
    hasIntegrity: false,
    skills: [
      for (final skill in skills)
        ArtSkill(
          nome: skill.nome,
          evo1: 'Richiede livello 0. ${skill.forme[0].descrizione}',
          evo2: 'Richiede livello 3. ${skill.forme[1].descrizione}',
          evo3: 'Richiede livello 6. ${skill.forme[2].descrizione}',
          effettiPerLivello: skill.forme.map((f) => f.effettiStrutturati),
          cooldownPerLivello: skill.forme.map((f) => f.cooldownStrutturato!),
          risorseCostoPerLivello: skill.forme
              .map((f) => f.costoStrutturato!.resource)
              .toList(),
          oculumMinimiPerLivello: skill.forme
              .map((f) => int.parse(f.costoStrutturato!.amountExpression))
              .toList(),
          oculumMassimiPerLivello: skill.forme
              .map((f) => int.parse(f.costoStrutturato!.amountExpression))
              .toList(),
        ),
    ],
  );
}

extension _OculumWitheredLarvaRuntime on _OculumHomePageState {
  int broodRemainingHp() => activeStructuredEffects
      .where((e) => e['type'] == 'costrutto' && e['mode'] == 'nidiata')
      .fold(0, (total, brood) => total + max(0, readIntValue(brood['hp'])));

  int absorbLarvalBroodDamage(int incoming) {
    var damage = max(0, incoming);
    if (damage == 0 || broodRemainingHp() == 0) return damage;
    for (final brood in activeStructuredEffects.where(
      (e) => e['type'] == 'costrutto' && e['mode'] == 'nidiata',
    )) {
      final hp = max(0, readIntValue(brood['hp']));
      final absorbed = min(hp, damage);
      brood['hp'] = hp - absorbed;
      damage -= absorbed;
      if (absorbed > 0) {
        aggiungiLog(
          '[NIDIATA] $absorbed larve sacrificate, ${brood['hp']} rimaste.',
        );
      }
    }
    activeStructuredEffects.removeWhere(
      (e) => e['mode'] == 'nidiata' && readIntValue(e['hp']) <= 0,
    );
    return damage;
  }

  void useWitheredHeart(InventoryItem item) {
    final healing = (maxHp() * .9).floor();
    final turns = Random.secure().nextInt(9) + 1;
    item.quantita--;
    if (item.quantita <= 0) inventario.remove(item);
    applyStructuredHealing('vita', healing);
    applyCondition(
      'ricordo_vitale',
      duration: turns,
      durationType: OculumConditionDurationType.turns,
      source: item.nome,
      metadata: {'oculumUpkeep': 0},
    );
    aggiungiLog(
      '[CUORE RINSECCHITO] Cura $healing entro il massimo; Ricordo Vitale per $turns turni.',
    );
    programmaSalvataggio();
  }
}
