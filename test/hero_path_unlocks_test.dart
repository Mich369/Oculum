import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/hero_path/hero_engine.dart';

void main() {
  test('metà catalogo richiede Achievement nuovi, unici e documentati', () {
    expect(heroSkills.length, 42);
    expect(heroSkillAchievements.length, 21);
    expect(heroSkillAchievements.map((a) => a.id).toSet().length, 21);
    expect(heroSkillAchievements.map((a) => a.skillId).toSet().length, 21);
    expect(heroSkills.where((s) => heroSkillAvailable(s.id, {})).length, 21);
    for (final a in heroSkillAchievements) {
      expect(a.requirement, isNotEmpty);
      expect(heroSkills.any((s) => s.id == a.skillId), true);
      expect(heroSkillAvailable(a.skillId, {}), false);
      expect(heroSkillAvailable(a.skillId, {a.id}), true);
    }
  });

  test(
    'nessuna Art predefinita o riempimento automatico, filtra Skill bloccate',
    () {
      final empty = HeroRun(seed: 1, name: 'Iris');
      expect(empty.artSkills, isEmpty);
      expect(empty.cards.keys, ['attack', 'defend']);
      final chosen = HeroRun(
        seed: 1,
        name: 'Iris',
        art: ['brace', 'brace', 'argilla', 'inesistente'],
      );
      expect(chosen.artSkills, ['brace']);
      expect(chosen.cards.keys, ['attack', 'defend', 'brace']);
      final unlocked = HeroRun(
        seed: 1,
        name: 'Iris',
        art: ['argilla'],
        meta: {'art_argilla'},
      );
      expect(unlocked.artSkills, ['argilla']);
    },
  );

  test(
    'le ricompense escludono Skill bloccate e rifiutano offerte obsolete',
    () {
      final run = HeroRun(seed: 17, name: 'Iris');
      for (var i = 0; i < 100; i++) {
        run.offerCards();
        expect(run.cardOffers.every((id) => heroSkillAvailable(id, {})), true);
      }
      run.cardOffers = ['istante'];
      expect(run.chooseCard('istante'), false);
      expect(run.cards.containsKey('istante'), false);
      run.achievements.add('art_istante');
      expect(run.chooseCard('istante'), true);
    },
  );

  test(
    'Quest completata sblocca Art, persiste e abilita la run successiva',
    () {
      final run = HeroRun(seed: 2, name: 'Iris');
      run.completeQuest('cammino', 'La campana tace');
      expect(run.achievements, contains('art_argilla'));
      expect(run.cards.containsKey('argilla'), false);
      final restored = HeroRun.fromJson(jsonDecode(jsonEncode(run.toJson())));
      final next = HeroRun(
        seed: 3,
        name: 'Iris',
        art: ['argilla'],
        meta: restored.achievements,
      );
      expect(next.artSkills, ['argilla']);
      final count = restored.journal.length;
      restored.refreshSkillAchievements();
      expect(restored.journal.length, count);
    },
  );

  test(
    'vittoria da confermare non sblocca Art e Ispirazione non la aggira',
    () {
      final run = HeroRun(seed: 42, name: 'Iris')..kills = 2;
      run.encounter(forced: 'lupo');
      run.enemies.single.hp = 1;
      run.enemies.single.shield = 0;
      run.player.stats['volonta'] = 100;
      run.play('attack');
      expect(run.pendingVictory, true);
      run.refreshSkillAchievements();
      expect(run.achievements.contains('art_istante'), false);
      expect(run.rewind(), true);
      expect(run.achievements.contains('art_istante'), false);
      run.play('attack');
      run.settleCombat();
      expect(run.achievements, contains('art_istante'));
    },
  );

  test('potenziare carte e armi assegna gli Achievement collegati', () {
    final run = HeroRun(seed: 1, name: 'Iris', art: ['brace'])..dust = 10;
    expect(run.upgradeCard('brace'), true);
    expect(run.achievements, contains('art_fenditura'));
    final mineral = heroMinerals.keys.first;
    run.inventory[mineral] = OculusRules.mineralCost;
    expect(run.improveWeapon(mineral), true);
    expect(run.achievements, contains('art_magnete'));
    run.obtainEye();
    expect(run.achievements, contains('art_parassita'));
  });

  test('salvataggi precedenti conservano Art e carte possedute', () {
    final data = HeroRun(seed: 1, name: 'Iris').toJson();
    data['artSkills'] = ['brace', 'argilla', 'aurora'];
    data['cards'] = {
      'attack': 0,
      'defend': 0,
      'brace': 0,
      'argilla': 2,
      'aurora': 0,
    };
    data['cardOffers'] = ['istante', 'gelo'];
    final restored = HeroRun.fromJson(data);
    expect(restored.artSkills, ['brace', 'argilla', 'aurora']);
    expect(restored.cards['argilla'], 2);
    expect(restored.cardOffers, ['gelo']);
    restored.encounter(forced: 'lupo');
    expect(restored.canPlay('argilla'), true);
  });
}
