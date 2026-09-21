import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/hero_path/hero_engine.dart';

HeroRun battle({
  int seed = 42,
  List<String> art = const ['brace', 'argilla', 'aurora'],
}) {
  final r = HeroRun(
    seed: seed,
    name: 'Iris',
    art: art,
    meta: heroSkillAchievements.map((a) => a.id).toSet(),
  );
  r.encounter(forced: 'lupo');
  r.enemies.first.hp = 1000;
  r.player.hp = 1000;
  return r;
}

void main() {
  test('PG, NPC e mostri: risorse distinte e morte solo PG', () {
    for (final kind in EntityKind.values) {
      final actor = HeroActor(id: kind.name, name: kind.name, kind: kind);
      expect(actor.inspirations, [3, 2, 1]);
      expect(
        OculusRules.deathSuccess(kind, HeroDifficulty.easy, 20),
        kind == EntityKind.player,
      );
      expect(HeroActor.fromJson(actor.toJson()).kind, kind);
    }
  });
  test('soglie e rinascita delle quattro difficoltà', () {
    final stats = {'resilienza': 6, 'volonta': 8, 'materia': 4, 'oculum': 4};
    final expected = [25, 17, 9, 3];
    for (final d in HeroDifficulty.values) {
      final threshold = [8, 10, 12, 15][d.index];
      expect(
        OculusRules.deathSuccess(EntityKind.player, d, threshold - 1),
        false,
      );
      expect(OculusRules.deathSuccess(EntityKind.player, d, threshold), true);
      expect(OculusRules.rebirthLife(d, stats, 3), expected[d.index]);
    }
  });
  test('morte ignora bonus, Potere, ispirazioni ed equipaggiamento', () {
    for (final d in HeroDifficulty.values) {
      final r = HeroRun(seed: 9, name: 'Iris', difficulty: d);
      r.player.stats['volonta'] = 999;
      r.player.titleLevel = 12;
      r.weaponBonus = 999;
      r.player.hp = 0;
      r.pendingDeath = true;
      expect(r.resolveDeath(), false);
      expect(r.rolls.single.faces, 4);
      expect(r.rolls.single.bonus, 0);
      expect(r.rolls.single.power, 0);
      expect(r.finished, true);
      expect(r.player.inspirations, [3, 2, 1]);
    }
  });
  test('rinascita reale d20 per ogni difficoltà e salvataggio', () {
    for (final d in HeroDifficulty.values) {
      var revived = false;
      for (var seed = 1; seed < 100 && !revived; seed++) {
        final r = HeroRun(seed: seed, name: 'Iris', difficulty: d);
        r.player.dice['volonta'] = 20;
        r.player.hp = 0;
        r.pendingDeath = true;
        if (r.resolveDeath()) {
          revived = true;
          expect(r.player.hp, greaterThan(0));
          expect(r.pendingDeath, false);
          expect(HeroRun.fromJson(r.toJson()).player.hp, r.player.hp);
        }
      }
      expect(revived, true);
    }
  });
  test('critico raggiunge almeno doppio tiro nemico', () {
    expect(OculusRules.critical(13, 7), false);
    expect(OculusRules.critical(14, 7), true);
    expect(OculusRules.critical(15, 7), true);
  });
  test('raggio 18 naturale ignora scudo, 20 ignora anche difesa', () {
    int hit(int natural) {
      final r = battle();
      final target = HeroActor(id: 'npc', name: 'NPC', kind: EntityKind.npc)
        ..hp = 100
        ..shield = 50;
      target.stats['materia'] = 3;
      r.brainBeam(target, 10, natural);
      if (natural >= 18) expect(target.shield, 50);
      return 100 - target.hp;
    }

    expect(hit(17), 0);
    expect(hit(18), greaterThan(0));
    expect(hit(19), hit(18));
    expect(hit(20), 20);
    expect(hit(18), lessThan(hit(20)));
  });
  test('crescita normale e bonus mini boss/boss ogni tre livelli', () {
    for (final tier in [0, 1, 2]) {
      final a =
          HeroActor(id: 'monster', name: 'Mostro', kind: EntityKind.monster)
            ..miniBoss = tier == 1
            ..boss = tier == 2;
      for (var level = 1; level <= 12; level++) {
        a.levelUp();
        expect(a.points, level * 3 + level ~/ 3 * [0, 6, 12][tier]);
      }
      a.quickAllocate();
      expect(a.points, 0);
      expect(a.dieSteps, 0);
      expect(a.stats.values.reduce((a, b) => a + b), 36 + 4 * [0, 6, 12][tier]);
    }
  });
  test('Sintonia Oculum: 5 e 10 risultati mutuamente esclusivi su cento', () {
    final values = List.generate(
      100,
      (n) => OculusRules.initialBond(EyeRarity.oculum, n),
    );
    expect(values.where((v) => v == 350).length, 5);
    expect(values.where((v) => v == 250).length, 10);
    expect(values.where((v) => v == 0).length, 85);
    expect(OculusRules.initialBond(EyeRarity.rare, 0), 0);
  });
  test(
    'Dust +20, costo Reforge, fallimento non distrugge, roundtrip Occhi',
    () {
      final r = HeroRun(seed: 81, name: 'Iris')..dust = 30;
      r.obtainEye();
      final e = r.eyes.single;
      e.rarity = EyeRarity.common;
      e.bond = 0;
      expect(r.useDust(e, 1), true);
      expect(r.dust, 29);
      expect(e.bond, 20);
      final before = r.dust;
      expect(r.reforge(e), true);
      expect(r.dust, before - 1);
      expect(r.eyes.single, same(e));
      expect(e.reforgeAttempts, 1);
      final loaded = HeroRun.fromJson(jsonDecode(jsonEncode(r.toJson())));
      expect(loaded.eyes.single.toJson(), e.toJson());
      for (final rarity in EyeRarity.values) {
        expect(OculusRules.reforgeCost(rarity), rarity.index + 1);
      }
      expect(OculusRules.reforge, [
        [70, 50, 30, 0],
        [60, 40, 20, 0],
        [50, 30, 12, 0],
        [40, 20, 7, 0],
      ]);
      e.rarity = EyeRarity.oculum;
      expect(r.reforge(e), false);
      expect(r.useDust(e, 999), false);
      expect(r.useDust(e, -1), false);
    },
  );
  test('carte: due per turno, risorse, nessuna reazione dopo la prima', () {
    final r = battle();
    final hp = r.player.hp;
    expect(r.play('defend'), true);
    expect(r.turn, 0);
    expect(r.actionsLeft, 1);
    expect(r.player.hp, hp);
    expect(r.play('defend'), true);
    expect(r.turn, 1);
    expect(r.actionsLeft, 2);
    r.player.oculum = 0;
    expect(r.play('brace'), false);
  });
  test('carte azione estendono il turno ma non si ripetono all’infinito', () {
    final r = battle(art: ['slancio', 'istante', 'brace']);
    expect(r.play('slancio'), true);
    expect(r.actionsLeft, 3);
    expect(r.player.volonta, 2);
    expect(r.play('slancio'), false);
    expect(r.play('istante'), true);
    expect(r.actionsLeft, 5);
    expect(r.play('istante'), false);
    expect(r.turn, 0);
    final loaded = HeroRun.fromJson(r.toJson());
    expect(loaded.actionsLeft, 5);
    expect(loaded.canPlay('slancio'), false);
    r.endTurn();
    expect(r.turn, 1);
    expect(r.actionsLeft, 2);
  });
  test('Ispirazione ripristina ultima azione, costo, budget e cooldown', () {
    final r = battle(art: ['slancio', 'brace', 'argilla']);
    r.obser = 17;
    r.inventory['Ferro opaco'] = 2;
    final before = r.player.toJson();
    r.play('slancio');
    expect(r.rewind(), true);
    expect(r.player.volonta, before['volonta']);
    expect(r.player.hp, before['hp']);
    expect(r.actionsLeft, 2);
    expect(r.cooldowns, isEmpty);
    expect(r.player.inspirations[0], 2);
    expect(r.rewind(), false);
    expect(r.obser, 17);
    expect(r.inventory['Ferro opaco'], 2);
    expect(r.play('slancio'), true);
  });
  test('rollback combat incluse ferite nemiche, no ricompense duplicate', () {
    final r = battle();
    r.enemies.first.hp = 1;
    r.enemies.first.shield = 0;
    r.player.stats['volonta'] = 100;
    r.play('attack');
    expect(r.pendingVictory, true);
    expect(r.kills, 0);
    final saved = HeroRun.fromJson(jsonDecode(jsonEncode(r.toJson())));
    expect(saved.rewind(), true);
    expect(saved.enemies.single.hp, 1);
    r.settleCombat();
    final loot = r.obser;
    expect(r.rewind(), false);
    r.settleCombat();
    expect(r.obser, loot);
  });
  test('upgrade massimo tre e variazione costo/cooldown', () {
    final r = HeroRun(seed: 1, name: 'Iris', art: ['brace'])..dust = 20;
    for (var i = 0; i < 3; i++) {
      expect(r.upgradeCard('brace'), true);
    }
    expect(r.upgradeCard('brace'), false);
    expect(r.cards['brace'], 3);
    expect(r.dust, 14);
    expect(heroSkills.firstWhere((s) => s.id == 'brace').price(3), 0);
    expect(heroSkills.firstWhere((s) => s.id == 'gelo').cd(2), 1);
  });
  test('Sanguinante, benda, avviso e cura completa', () {
    final r = battle(art: ['lama', 'brace', 'aurora']);
    r.player.conditions['Sanguinante'] = -1;
    r.useItem('Benda improvvisata');
    expect(r.player.conditions.containsKey('Sanguinante'), false);
    expect(r.player.conditions.containsKey('Bendato'), true);
    expect(r.cardWarning('lama'), isNotEmpty);
    expect(r.cardWarning('brace'), isEmpty);
    r.heal(3, fullTreatment: true);
    expect(r.player.conditions.containsKey('Bendato'), false);
    expect(r.player.conditions['Protezione Sanguinante'], 3);
  });
  test('adattamento lento per famiglia, anti farming, cap e trattamento', () {
    final r = battle();
    r.adapt('Fuoco', handled: false);
    final hit = r.adaptation['Fuoco']!;
    r.adapt('Gelo', handled: true);
    expect(r.adaptation['Gelo'], greaterThan(hit));
    for (var i = 0; i < 100; i++) {
      r.adapt('Fuoco', handled: true);
    }
    final limit = r.adaptation['Fuoco'];
    r.adapt('Fuoco', handled: true);
    expect(r.adaptation['Fuoco'], limit);
    for (var scene = 0; scene < 10000; scene++) {
      r.adaptationSamples.clear();
      r.adapt('Fuoco', handled: true);
    }
    expect(r.adaptation['Fuoco'], lessThanOrEqualTo(OculusRules.adaptationCap));
    expect(r.adaptation['Fuoco'], lessThan(1));
    expect(HeroRun.fromJson(r.toJson()).adaptation, r.adaptation);
  });
  test(
    'quest guida: salvataggio NPC sblocca Città, ramo morte incompatibile',
    () {
      final r = HeroRun(seed: 1, name: 'Iris');
      final returnEvent = heroEvents.firstWhere((e) => e.id == 'ritorno');
      expect(r.eventWeight(returnEvent), 0);
      r.eventId = 'viandante';
      r.choose(0);
      expect(r.eventWeight(returnEvent), greaterThan(0));
      r.eventId = 'ritorno';
      r.choose(0);
      expect(r.locations.take(3), ['Villaggio', 'Foresta', 'Dungeon']);
      expect(r.locations, contains('Città'));
      expect(r.completedQuests, contains('guida'));
      expect(r.eventWeight(returnEvent), 0);
    },
  );
  test('weighted random, seed identico e ripresa RNG identica', () {
    final a = HeroRandom(42), b = HeroRandom(42);
    expect(
      List.generate(100, (_) => a.nextInt(100)),
      List.generate(100, (_) => b.nextInt(100)),
    );
    for (var i = 0; i < 20; i++) {
      expect(a.weighted(['a', 'b'], (s) => s == 'a' ? 0 : 1), 'b');
    }
    final run = HeroRun(seed: 314, name: 'Iris');
    run.travel('Dungeon');
    final saved = HeroRun.fromJson(jsonDecode(jsonEncode(run.toJson())));
    expect(saved.rng.nextInt(100), run.rng.nextInt(100));
    expect(saved.eventId, run.eventId);
  });
  test('migrazione aggiunge campi senza cancellare payload storico', () {
    final legacy = {
      'playerNameInRun': 'Old',
      'room': 34,
      'floor': 7,
      'unrecognized': {'x': 3},
      'fallenCompanions': [
        {'id': 'oldEye', 'name': 'Lupo', 'bond': 250, 'oculumRarity': true},
      ],
    };
    final r = HeroRun.fromJson(legacy);
    expect(r.scene, 34);
    expect(r.player.name, 'Old');
    expect(r.actionsLeft, 2);
    expect(r.eyes.single.bond, 250);
    expect(r.toJson()['unrecognized'], {'x': 3});
    expect(r.toJson()['floor'], 7);
    expect(r.player.dice.values, everyElement(4));
  });
  for (final d in HeroDifficulty.values) {
    test('run ${d.name}: Villaggio, Foresta, Dungeon, Città e Landa', () {
      final r = HeroRun(seed: 127, name: 'Iris', difficulty: d);
      expect(r.eat('Zuppa scura'), true);
      expect(r.foodBonuses['resilienza'], 2);
      r.startHunt();
      expect(r.inCombat, true);
      for (final e in r.enemies) {
        e.hp = 0;
      }
      r.pendingVictory = true;
      r.settleCombat();
      expect(r.travel('Foresta'), true);
      expect(r.eventId, isNotEmpty);
      r.eventId = '';
      expect(r.travel('Dungeon'), true);
      expect(r.scenario, isNotEmpty);
      r.eventId = 'campanaro';
      r.choose(0);
      expect(r.locations, contains('Landa Nera'));
      r.eventId = 'viandante';
      r.choose(0);
      r.eventId = 'ritorno';
      r.choose(0);
      expect(r.travel('Città'), true);
      r.eventId = '';
      expect(r.travel('Landa Nera'), true);
      final saved = HeroRun.fromJson(jsonDecode(jsonEncode(r.toJson())));
      expect(saved.toJson(), r.toJson());
    });
  }
  test(
    'Invecchiamento e adattamento Foresta; Normale non muore di vecchiaia',
    () {
      final r = HeroRun(seed: 1, name: 'Iris', mode: HeroMode.aging)
        ..location = 'Foresta';
      for (var i = 0; i < 36; i++) {
        r.eventId = '';
        r.nextScene();
      }
      expect(r.forestSurvival, true);
      expect(r.agePenalty, 2);
      expect(r.bonus('volonta'), 3);
      expect(
        r.bonus('materia'),
        1 - (r.player.conditions.containsKey('Infreddolito') ? 1 : 0),
      );
      r.scene = OculusRules.oldAgeScene - 1;
      r.eventId = '';
      r.nextScene();
      expect(r.finished, true);
      final normal = HeroRun(seed: 1, name: 'Iris')
        ..scene = OculusRules.oldAgeScene;
      normal.nextScene();
      expect(normal.finished, false);
    },
  );
}
