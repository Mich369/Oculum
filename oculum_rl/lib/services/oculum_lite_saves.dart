import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/oculum_lite_run.dart';
import '../widgets/oculum_lite_appearance.dart';
import 'oculum_lite_grimoire.dart';
import 'oculum_lite_save_files.dart';
import 'oculum_save_profile.dart';

const oculumLiteSaveSlotCount = 6;

String oculumLiteSaveSlotKey(int index) =>
    oculumProfiledStorageKey('oculum_lite_v1_${index + 1}');

class OculumLiteProgress {
  const OculumLiteProgress({
    this.bestClearedFloor = -1,
    this.scostubanditoUnlocked = false,
    this.unlockedHeroes = const {},
    this.discoveredPets = const {},
    this.slimeCounters = const {},
    this.upgrades = const {},
    this.milestoneFloors = const {},
    this.grimoire = const LiteProfileGrimoire.empty(),
  });

  final int bestClearedFloor;
  final bool scostubanditoUnlocked;
  final Set<LiteHero> unlockedHeroes;
  final Map<LiteDifficulty, int> milestoneFloors;
  final LiteProfileGrimoire grimoire;

  /// Record an accepted learning event after settling any applicable cost.
  OculumLiteProgress learnArt(LiteLearnedArt art) =>
      _withGrimoire(grimoire.learn(art));

  OculumLiteProgress equipGrimoire(
    String characterId,
    LiteHero hero,
    int slot,
    LiteGrimoireAction? action,
  ) => _withGrimoire(grimoire.equip(characterId, hero, slot, action));

  OculumLiteProgress _withGrimoire(LiteProfileGrimoire next) {
    if (identical(next, grimoire)) return this;
    return OculumLiteProgress(
      bestClearedFloor: bestClearedFloor,
      scostubanditoUnlocked: scostubanditoUnlocked,
      unlockedHeroes: unlockedHeroes,
      discoveredPets: discoveredPets,
      slimeCounters: slimeCounters,
      upgrades: upgrades,
      milestoneFloors: milestoneFloors,
      grimoire: next,
    );
  }

  int clearedFor(LiteDifficulty minimum) => milestoneFloors.entries
      .where((entry) => entry.key.index >= minimum.index)
      .fold(0, (best, entry) => entry.value > best ? entry.value : best);

  bool unlocked(LiteMilestoneReward reward) =>
      clearedFor(reward.difficulty) >= reward.floors;

  Iterable<LiteWeapon> get startingWeapons sync* {
    yield* LiteWeapon.starters;
    for (final reward in liteMilestoneRewards) {
      if (unlocked(reward) && reward.weapon != null) yield reward.weapon!;
    }
  }

  final Set<LiteCompanion> discoveredPets;
  final Map<String, int> slimeCounters;
  int get slimeKills => slimeCounters.values
      .fold(0, (total, count) => total + count)
      .clamp(0, 10);
  bool canPlay(LiteHero hero) =>
      hero.unlockHint == null ||
      unlockedHeroes.contains(hero) ||
      liteMilestoneRewards.any(
        (reward) => reward.hero == hero && unlocked(reward),
      ) ||
      hero == LiteHero.slimeBlu && slimeKills >= 10 ||
      hero == LiteHero.scostubandito && scostubanditoUnlocked;
  final Map<LitePermanentUpgrade, int> upgrades;

  int get earned =>
      LiteRun.sigilFloors.where((floor) => floor <= bestClearedFloor).length;
  int get unspent =>
      earned - upgrades.values.fold(0, (sum, rank) => sum + rank);

  OculumLiteProgress recordGrimoire(
    Iterable<LiteLearnedArt> arts, {
    String? characterId,
    LiteHero? hero,
    List<LiteGrimoireAction?>? slots,
  }) {
    var next = grimoire;
    for (final art in arts) {
      next = next.learn(art);
    }
    if (characterId != null && hero != null && slots != null) {
      for (var i = 0; i < slots.length; i++) {
        next = next.equip(characterId, hero, i, slots[i]);
      }
    }
    return _withGrimoire(next);
  }

  OculumLiteProgress recordRun(LiteRun run) {
    final cleared = run.stageClear || run.victorious
        ? run.stage
        : run.stage - 1;
    return record(
      cleared,
      run.unlockedHeroesFor(run.hero),
      pets: run.discoveredPets,
      slimeCounters: {run.slimeCreditId: run.slimeKills},
      milestones: {run.difficulty: run.milestoneFloors},
    ).recordGrimoire(run.supply.knownArts);
  }

  OculumLiteProgress record(
    int cleared,
    Set<LiteHero> heroes, {
    Set<LiteCompanion> pets = const {},
    Map<String, int> slimeCounters = const {},
    Map<LiteDifficulty, int> milestones = const {},
  }) {
    final unlocksBandit = heroes.contains(LiteHero.scostubandito);
    final additions = {
      if (slimeKills < 10)
        for (final entry in slimeCounters.entries)
          if (entry.value > (this.slimeCounters[entry.key] ?? 0))
            entry.key: entry.value.clamp(0, 10),
    };
    final improvedMilestones = {
      for (final entry in milestones.entries)
        if (entry.value > (milestoneFloors[entry.key] ?? 0))
          entry.key: entry.value.clamp(0, 36),
    };
    if (cleared <= bestClearedFloor &&
        improvedMilestones.isEmpty &&
        heroes.every(canPlay) &&
        pets.every(discoveredPets.contains) &&
        additions.isEmpty) {
      return this;
    }
    return OculumLiteProgress(
      bestClearedFloor: cleared > bestClearedFloor ? cleared : bestClearedFloor,
      scostubanditoUnlocked: scostubanditoUnlocked || unlocksBandit,
      unlockedHeroes: Set.unmodifiable({...unlockedHeroes, ...heroes}),
      discoveredPets: Set.unmodifiable({...discoveredPets, ...pets}),
      slimeCounters: Map.unmodifiable({...this.slimeCounters, ...additions}),
      milestoneFloors: Map.unmodifiable({
        ...milestoneFloors,
        ...improvedMilestones,
      }),
      upgrades: upgrades,
      grimoire: grimoire,
    );
  }

  OculumLiteProgress? buy(LitePermanentUpgrade upgrade) {
    final rank = upgrades[upgrade] ?? 0;
    if (unspent <= 0 || rank >= LitePermanentUpgrade.maxRank) return null;
    return OculumLiteProgress(
      bestClearedFloor: bestClearedFloor,
      scostubanditoUnlocked: scostubanditoUnlocked,
      unlockedHeroes: unlockedHeroes,
      discoveredPets: discoveredPets,
      slimeCounters: slimeCounters,
      milestoneFloors: milestoneFloors,
      upgrades: Map.unmodifiable({...upgrades, upgrade: rank + 1}),
      grimoire: grimoire,
    );
  }

  String encode() => jsonEncode({
    'schema': 1,
    'floor': bestClearedFloor,
    'scostubandito': scostubanditoUnlocked,
    if (unlockedHeroes.isNotEmpty)
      'heroes': unlockedHeroes.map((hero) => hero.name).toList(growable: false),
    'upgrades': LitePermanentUpgrade.encode(upgrades),
    if (milestoneFloors.isNotEmpty)
      'milestones': {
        for (final entry in milestoneFloors.entries)
          entry.key.name: entry.value,
      },
    if (discoveredPets.isNotEmpty)
      'pets': discoveredPets.map((pet) => pet.name).toList(),
    if (slimeCounters.isNotEmpty) 'slimeCounters': slimeCounters,
    if (!grimoire.isEmpty) 'grimoire': grimoire.toJson(),
  });

  static OculumLiteProgress decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    if (data['schema'] != 1) throw const FormatException('Profilo sconosciuto');
    final counters = data['slimeCounters'];
    final milestones = data['milestones'];
    final profile = OculumLiteProgress(
      slimeCounters: Map.unmodifiable({
        if (counters is Map)
          for (final entry in counters.entries)
            if (entry.key is String &&
                entry.value is int &&
                (entry.value as int) > 0)
              entry.key as String: (entry.value as int).clamp(1, 10),
      }),
      milestoneFloors: Map.unmodifiable({
        if (milestones is Map)
          for (final difficulty in LiteDifficulty.values)
            if (milestones[difficulty.name] case final int count when count > 0)
              difficulty: count.clamp(1, 36),
      }),
      bestClearedFloor: (data['floor'] as int).clamp(-1, LiteRun.finalStage),
      scostubanditoUnlocked: data['scostubandito'] == true,
      unlockedHeroes: Set.unmodifiable({
        for (final hero in LiteHero.values)
          if (hero.unlockHint != null &&
              data['heroes'] is List &&
              (data['heroes'] as List).contains(hero.name))
            hero,
      }),
      discoveredPets: Set.unmodifiable({
        for (final pet in LiteCompanion.values)
          if (pet.discovery != null &&
              data['pets'] is List &&
              (data['pets'] as List).contains(pet.name))
            pet,
      }),
      upgrades: Map.unmodifiable(LitePermanentUpgrade.read(data['upgrades'])),
      grimoire: LiteProfileGrimoire.fromJson(data['grimoire']),
    );
    if (profile.unspent < 0) throw const FormatException('Sigilli non validi');
    return profile;
  }
}

typedef OculumLiteSlotRead = ({
  OculumLiteSaveSlot? save,
  String? encoded,
  bool recovered,
  bool unreadable,
});

OculumLiteSlotRead _readCopies(Object? primary, Object? backup) {
  for (final (value, recovered) in [(primary, false), (backup, true)]) {
    if (value is! String) continue;
    try {
      return (
        save: OculumLiteSaveSlot.decode(value),
        encoded: value,
        recovered: recovered,
        unreadable: false,
      );
    } on Object {
      // The other copy can still recover this slot.
    }
  }
  return (
    save: null,
    encoded: null,
    recovered: false,
    unreadable: primary != null || backup != null,
  );
}

class OculumLiteSaveStore {
  const OculumLiteSaveStore(this.preferences, [this._files]);

  static Future<OculumLiteSaveStore> open() async {
    final files = await openOculumLiteSaveFiles();
    try {
      final preferences = await SharedPreferences.getInstance();
      return OculumLiteSaveStore(preferences, files);
    } on Object {
      if (files == null) rethrow;
      // A damaged legacy settings file must not block the independent slots.
      return OculumLiteSaveStore(null, files);
    }
  }

  final SharedPreferences? preferences;
  final OculumLiteSaveFiles? _files;
  String get _progressKey => oculumProfiledStorageKey('oculum_lite_progress');

  Future<Object?> _read(String key) async {
    final files = _files;
    return files == null ? preferences?.get(key) : await files.read(key);
  }

  OculumLiteSlotRead _legacy(String key) =>
      _readCopies(preferences?.get(key), preferences?.get('$key.backup'));

  Future<OculumLiteSlotRead> read(int index) async {
    final key = oculumLiteSaveSlotKey(index);
    final local = _readCopies(await _read(key), await _read('$key.backup'));
    if (local.save != null || _files == null) return local;
    final legacy = _legacy(key);
    return (
      save: legacy.save,
      encoded: legacy.encoded,
      recovered: legacy.recovered || (local.unreadable && legacy.save != null),
      unreadable:
          legacy.save == null && (local.unreadable || legacy.unreadable),
    );
  }

  Future<void> _replace(String key, String value) async {
    final files = _files;
    if (files != null) {
      await files.replace(key, value);
    } else if (await preferences?.setString(key, value) != true) {
      throw StateError('Scrittura rifiutata');
    }
    if (await _read(key) != value) throw StateError('Scrittura non verificata');
  }

  Future<({OculumLiteProgress progress, String? valid, bool unreadable})>
  _readProgress() async {
    final key = _progressKey;
    final main = await _read(key);
    final backup = await _read('$key.backup');
    for (final value in [main, backup]) {
      if (value is! String) continue;
      try {
        return (
          progress: OculumLiteProgress.decode(value),
          valid: value,
          unreadable: false,
        );
      } on Object {
        // Try the second copy before falling back to progress in the run slots.
      }
    }
    return (
      progress: const OculumLiteProgress(),
      valid: null,
      unreadable: main != null || backup != null,
    );
  }

  Future<OculumLiteProgress> readProgress() async =>
      (await _readProgress()).progress;

  Future<OculumLiteProgress> readProgressWithSlots() async {
    final progress = await readProgress();
    final slots = await Future.wait(
      List.generate(oculumLiteSaveSlotCount, read),
    );
    return slots.fold<OculumLiteProgress>(progress, (current, slot) {
      final run = slot.save?.run;
      return run == null ? current : current.recordRun(run);
    });
  }

  Future<void> writeProgress(OculumLiteProgress progress) async {
    final key = _progressKey;
    final value = progress.encode();
    final current = await _readProgress();
    if (current.unreadable) throw StateError('Profilo illeggibile');
    if (current.valid == value && await _read(key) == value) return;
    if (current.valid case final previous?) {
      if (await _read('$key.backup') != previous) {
        await _replace('$key.backup', previous);
      }
    }
    await _replace(key, value);
  }

  String get _memoryKey => oculumProfiledStorageKey('oculum_rl_oracle_v1');

  Future<Map<String, Object?>> _readOracle() async {
    final raw = await _read(_memoryKey);
    if (raw is! String || raw.isEmpty) return {};
    try {
      final value = jsonDecode(raw);
      return value is Map ? Map<String, Object?>.from(value) : {};
    } on FormatException {
      return {};
    }
  }

  Future<LiteRestMemory?> readRestMemory() async {
    final state = await _readOracle();
    final memory = LiteRestMemory.read(state['memory']);
    if (memory == null) return null;
    final slots = await Future.wait(
      List.generate(oculumLiteSaveSlotCount, read),
    );
    if (slots.any((slot) => slot.save?.run.supply.carriedId == memory.id)) {
      await spendRestMemory(memory.id);
      return null;
    }
    return memory;
  }

  Future<void> saveRestMemory(LiteRestMemory memory) async {
    final state = await _readOracle();
    final used = (state['used'] is List ? state['used'] as List : const [])
        .whereType<String>()
        .toList();
    if (used.contains(memory.id) ||
        LiteRestMemory.read(state['memory'])?.id == memory.id)
      return;
    final previous = LiteRestMemory.read(state['memory']);
    if (previous != null) used.add(previous.id);
    await _replace(
      _memoryKey,
      jsonEncode({
        'memory': memory.frame,
        'used': used.reversed.take(48).toList().reversed.toList(),
      }),
    );
  }

  Future<void> spendRestMemory(String id) async {
    final state = await _readOracle();
    if (LiteRestMemory.read(state['memory'])?.id != id) return;
    final used = {
      ...(state['used'] is List ? state['used'] as List : const [])
          .whereType<String>(),
      id,
    };
    await _replace(
      _memoryKey,
      jsonEncode({
        'used': used.toList().reversed.take(48).toList().reversed.toList(),
      }),
    );
  }

  /// Commit the new snapshot only after keeping the previous readable copy.
  /// Legacy preferences remain a read-only migration source on native builds.
  Future<void> write(int index, String value) async {
    final key = oculumLiteSaveSlotKey(index);
    final primary = await _read(key);
    if (primary == value) return;
    final backup = await _read('$key.backup');
    final local = _readCopies(primary, backup);
    final previous =
        local.encoded ?? (_files == null ? null : _legacy(key).encoded);
    if (previous == null &&
        (local.unreadable || (_files != null && _legacy(key).unreadable))) {
      throw StateError('Le copie dello slot sono illeggibili');
    }
    if (previous != null && previous != backup) {
      await _replace('$key.backup', previous);
    }
    await _replace(key, value);
  }
}

class OculumLiteSaveSlot {
  const OculumLiteSaveSlot({
    required this.run,
    required this.name,
    required this.appearance,
    required this.attempt,
    required this.startingWeapon,
    required this.startingBiome,
  });

  final LiteRun run;
  final String name;
  final OculumLiteAppearance appearance;
  final int attempt;
  final LiteWeapon startingWeapon;
  final LiteBiome startingBiome;

  OculumLiteSaveSlot withAppearance(OculumLiteAppearance look) =>
      OculumLiteSaveSlot(
        run: run,
        name: name,
        appearance: look,
        attempt: attempt,
        startingWeapon: startingWeapon,
        startingBiome: startingBiome,
      );

  static OculumLiteSaveSlot decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    if (data['schema'] != 1) throw const FormatException('Versione ignota');
    final savedRun = data['run'] as Map<String, dynamic>;
    final look = OculumLiteAppearance.fromJson(data['look']);
    if (savedRun['hero'] == LiteHero.duplicatore.name &&
        !savedRun.containsKey('customAttributes')) {
      final name = data['name'] as String;
      savedRun['customAttributes'] =
          (name.trim().isNotEmpty && name.trim() != 'Duplicatore') ||
          !look.sameAs(const OculumLiteAppearance(), includeInkFinish: false);
    }
    if (savedRun['hero'] == LiteHero.assassino.name &&
        !savedRun.containsKey('assassinTactical') &&
        look.inkFinish == LiteInkFinish.tattica) {
      savedRun['assassinTactical'] = true;
    }
    final run = LiteRun.fromJson(savedRun);
    final slotLook = run.assassinTactical
        ? look.copyWith(inkFinish: LiteInkFinish.tattica)
        : look.inkFinish == LiteInkFinish.tattica
        ? look.copyWith(inkFinish: LiteInkFinish.canonica)
        : look;
    final startedWith = LiteWeapon.values
        .where((item) => item.name == data['startingWeapon'])
        .firstOrNull;
    final startingBiome = data['startingBiome'] ?? savedRun['startingBiome'];
    return OculumLiteSaveSlot(
      run: run,
      name: data['name'] as String,
      attempt: data['attempt'] as int,
      startingWeapon: run.hero == LiteHero.assassino
          ? run.hero.startingWeapon(
              startedWith ?? run.weapon,
              assassinTactical: run.assassinTactical,
            )
          : startedWith ?? run.weapon,
      startingBiome:
          LiteBiome.values
              .where((item) => item.name == startingBiome)
              .firstOrNull ??
          run.biome,
      appearance: slotLook,
    );
  }

  String encode() => jsonEncode({
    'schema': 1,
    'name': name,
    'attempt': attempt,
    'startingWeapon': startingWeapon.name,
    'startingBiome': startingBiome.name,
    'run': run.toJson(),
    'look': appearance.toJson(),
  });
}
