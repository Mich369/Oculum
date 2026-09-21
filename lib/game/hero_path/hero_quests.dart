part of 'hero_engine.dart';

/// Quest replacements are consequences, not a failure counter. Both the old
/// objective and the reason are retained; replacements receive rewards once.
extension HeroQuests on HeroRun {
  void replaceQuest(
    String oldId,
    String nextId,
    String objective,
    String reason,
  ) {
    final previous = quests.remove(oldId);
    if (previous == null || completedQuests.containsKey(nextId)) return;
    quests[nextId] = objective;
    questStarted.remove(oldId);
    questStarted[nextId] = scene;
    questHistory.add({
      'from': oldId,
      'to': nextId,
      'previous': previous,
      'objective': objective,
      'reason': reason,
      'scene': scene,
    });
    journal.add('Quest aggiornata: $reason $objective');
    if (journal.length > 60) journal.removeAt(0);
  }

  void reconcileQuests() {
    for (final id in completedQuests.keys) {
      quests.remove(id);
    }
    if (quests.containsKey('guida') &&
        (npcs['viandante'] == 'morto' || flags.contains('viandante_partito'))) {
      replaceQuest(
        'guida',
        'mappa_viandante',
        'Cerca la mappa del viandante in Foresta o al Villaggio.',
        'Il viandante non può più accompagnarti.',
      );
    }
    if (flags.contains('campana_finita')) {
      if (npcs['campanaro'] == 'salvo') {
        if (quests.containsKey('cammino')) {
          completeQuest('cammino', 'Il suono sotto terra');
        }
      } else {
        replaceQuest(
          'cammino',
          'eco_campana',
          'Raccogli l’eco della campana nel Dungeon e restituiscila alla terra.',
          'La corda è spezzata; il vecchio obiettivo non è più raggiungibile.',
        );
        replaceQuest(
          'campana',
          'eco_campana',
          'Raccogli l’eco della campana nel Dungeon e restituiscila alla terra.',
          'Il campanaro non può più essere liberato.',
        );
      }
    }
    if (flags.contains('eiva_caduta') && quests.containsKey('eiva')) {
      replaceQuest(
        'eiva',
        'residuo_eiva',
        'Purifica i resti dell’Eiva nella Città.',
        'La fonte è già caduta, ma la corruzione è rimasta.',
      );
    }
    if (quests.containsKey('memoria') && flags.contains('giardino_chiuso')) {
      replaceQuest(
        'memoria',
        'ritorno_memoria',
        'Porta il ricordo a un focolare del Villaggio.',
        'Il Giardino non risponde più.',
      );
    }
    if (quests.containsKey('vena') && flags.contains('giardino_chiuso')) {
      replaceQuest(
        'vena',
        'ritorno_memoria',
        'Porta il ricordo a un focolare del Villaggio.',
        'La strada del Giardino si è chiusa.',
      );
    }
    for (final id in quests.keys) {
      questStarted.putIfAbsent(id, () => scene);
    }
  }

  /// A required event is guaranteed after a bounded number of eligible scenes.
  /// The player still makes the decision; the RNG cannot orphan an objective.
  String? get dueQuestEvent {
    final routes = <String, String>{
      'cammino': flags.contains('campana_cercata')
          ? 'campanaro'
          : 'quest_campana',
      'campana': 'campanaro',
      'guida': 'ritorno',
      'mappa_viandante': 'mappa_viandante',
      'eco_campana': 'eco_campana',
      'tracce_campana': 'tracce_campana',
      'residuo_eiva': 'residuo_eiva',
      'ritorno_memoria': 'ritorno_memoria',
      'eiva': 'fonte_eiva',
      'sigillo_eiva': 'sigillo_eiva',
      'tracce_citta': 'tracce_citta',
      'memoria': eyes.isEmpty ? 'altare' : 'sogno',
      'vena': 'sogno',
    };
    for (final id in quests.keys) {
      final eventName = routes[id];
      if (eventName == null ||
          scene - (questStarted[id] ?? scene) < OculusRules.questSceneLimit) {
        continue;
      }
      final candidate = heroEvents.where((e) => e.id == eventName).firstOrNull;
      if (candidate != null && eventWeight(candidate) > 0) return candidate.id;
    }
    return null;
  }

  bool resolveQuestEvent(String id, int choice) {
    switch (id) {
      case 'mappa_viandante':
        if (choice == 0) {
          flags.add('citta_aperta');
          completeQuest(id, 'La strada sulla mappa');
          note(
            'La mappa indica la porta della Città. Il viandante aveva mantenuto la promessa.',
          );
        } else {
          replaceQuest(
            id,
            'tracce_citta',
            'Chiedi al carovaniere del Villaggio la strada per la Città.',
            'La mappa è stata lasciata indietro.',
          );
          note('Un carovaniere potrebbe conoscere quella strada.');
        }
        return true;
      case 'tracce_citta':
        flags.add('citta_aperta');
        completeQuest(id, 'La strada del carovaniere');
        note('Il carovaniere traccia il percorso sulla cenere.');
        return true;
      case 'eco_campana':
        completeQuest(id, choice == 0 ? 'L’eco restituita' : 'L’eco custodita');
        flags.add('landa_aperta');
        if (choice == 0) {
          destiny++;
        } else {
          inventory['Eco della campana'] = 1;
        }
        note('La campana non suona più. Il suo ricordo ha trovato un posto.');
        return true;
      case 'tracce_campana':
        completeQuest(id, 'Le tracce ritrovate');
        flags.add('campana_cercata');
        quests['campana'] = 'Trova il campanaro nel Dungeon o nella Landa.';
        note(
          'Le impronte conducono sotto terra. Puoi ancora raggiungere il campanaro.',
        );
        return true;
      case 'residuo_eiva':
        completeQuest(id, 'La città purificata');
        corruption = max(0, corruption - 2);
        npcs['rosso'] = 'salvo';
        note('Per la prima volta le finestre restano aperte.');
        return true;
      case 'ritorno_memoria':
        completeQuest(id, 'Il ricordo affidato');
        flags.add('verita');
        note('Il fuoco accetta il ricordo. La voce non chiede altro.');
        return true;
      case 'fonte_eiva':
        if (choice == 0) {
          encounter(forced: 'eiva');
        } else {
          replaceQuest(
            'eiva',
            'sigillo_eiva',
            'Chiudi il canale della corruzione nella Città.',
            'Hai rinunciato allo scontro diretto con l’Eiva.',
          );
          note('Il canale sotto la piazza alimenta ancora la fonte.');
        }
        return true;
      case 'sigillo_eiva':
        completeQuest(id, 'Il canale sigillato');
        flags.add('eiva_isolata');
        corruption = max(0, corruption - 2);
        note('La creatura vive, ma la città non le appartiene più.');
        return true;
    }
    return false;
  }
}
