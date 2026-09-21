import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/hero_path/hero_engine.dart';

void main() {
  test(
    'la corda recisa trasforma la quest principale in un obiettivo completabile',
    () {
      final r = HeroRun(seed: 1, name: 'Iris');
      r.eventId = 'quest_campana';
      r.choose(1);
      expect(r.quests.containsKey('cammino'), false);
      expect(r.quests.containsKey('eco_campana'), true);
      expect(r.questHistory.single['reason'], contains('spezzata'));
      r.location = 'Dungeon';
      r.scene += OculusRules.questSceneLimit;
      expect(r.dueQuestEvent, 'eco_campana');
      r.nextScene();
      expect(r.eventId, 'eco_campana');
      r.choose(0);
      expect(r.completedQuests, contains('eco_campana'));
      expect(r.quests, isEmpty);
      expect(r.locations, contains('Landa Nera'));
      final dust = r.dust;
      r.reconcileQuests();
      expect(r.dust, dust);
    },
  );
  test(
    'persa la guida: mappa, poi carovaniere, sempre con via praticabile',
    () {
      final r = HeroRun(seed: 2, name: 'Iris');
      r.eventId = 'viandante';
      r.choose(0);
      r.eventId = 'ritorno';
      r.choose(1);
      expect(r.quests, contains('mappa_viandante'));
      expect(r.quests.containsKey('guida'), false);
      r.eventId = 'mappa_viandante';
      r.choose(1);
      expect(r.quests, contains('tracce_citta'));
      r.eventId = 'tracce_citta';
      r.choose(0);
      expect(r.locations, contains('Città'));
      expect(r.completedQuests, contains('tracce_citta'));
      expect(r.quests.containsKey('tracce_citta'), false);
    },
  );
  test(
    'rinuncia allo scontro Eiva crea obiettivo alternativo e lo completa',
    () {
      final r = HeroRun(seed: 3, name: 'Iris');
      r.quests['eiva'] = 'Spezza la fonte';
      r.flags.add('citta_aperta');
      r.location = 'Città';
      r.eventId = 'fonte_eiva';
      r.choose(1);
      expect(r.quests, contains('sigillo_eiva'));
      expect(r.inCombat, false);
      r.eventId = 'sigillo_eiva';
      r.choose(0);
      expect(r.completedQuests, contains('sigillo_eiva'));
      expect(r.flags, contains('eiva_isolata'));
    },
  );
  test(
    'evento necessario garantito, salvataggio e migrazione di quest impossibili',
    () {
      final r = HeroRun(seed: 4, name: 'Iris');
      r.scene = OculusRules.questSceneLimit;
      r.location = 'Dungeon';
      expect(r.dueQuestEvent, 'quest_campana');
      r.nextScene();
      expect(r.eventId, 'quest_campana');
      r.choose(0);
      r.scene += OculusRules.questSceneLimit;
      expect(r.dueQuestEvent, 'campanaro');
      r.nextScene();
      r.choose(0);
      expect(r.completedQuests.keys, containsAll(['cammino', 'campana']));
      final old = HeroRun(seed: 5, name: 'Old')..flags.add('campana_finita');
      final migrated = HeroRun.fromJson(jsonDecode(jsonEncode(old.toJson())));
      expect(migrated.quests, contains('eco_campana'));
      expect(
        HeroRun.fromJson(
          jsonDecode(jsonEncode(migrated.toJson())),
        ).questHistory,
        migrated.questHistory,
      );
    },
  );
  test('saltare il richiamo conserva una catena completabile', () {
    final r = HeroRun(seed: 6, name: 'Iris');
    r.eventId = 'quest_campana';
    r.choose(2);
    expect(r.quests, contains('tracce_campana'));
    r.eventId = 'tracce_campana';
    r.choose(0);
    expect(r.quests, contains('campana'));
    r.eventId = 'campanaro';
    r.choose(0);
    expect(r.quests, isEmpty);
  });
}
