import 'dart:async';
import 'dart:math';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/oculum_lite_audio.dart';
import '../game/oculum_lite_run.dart';
import '../services/oculum_lite_saves.dart';
import '../services/oculum_rl_release.dart';
import '../services/oculum_rl_updates.dart';
import '../widgets/oculum_lite_arena.dart';
import '../widgets/oculum_lite_creator.dart';
import '../widgets/oculum_lite_ink_finishes.dart';
import '../widgets/oculum_lite_merchant_greeting.dart';
import '../widgets/oculum_lite_routes.dart';
import '../widgets/oculum_lite_rest_panel.dart';
import '../widgets/oculum_rl_merchant.dart';

const liteHeroLabels = {
  LiteHero.evasore: 'Schivata intangibile',
  LiteHero.duplicatore: 'Duplicatore',
  LiteHero.ashley: 'Ashley',
  LiteHero.scostubandito: 'Scostubandito',
  LiteHero.granScostumato: 'Gran Scostumato',
  LiteHero.dronePostea: 'Drone di Postea',
  LiteHero.sentinella: 'Sentinella di Pietra',
  LiteHero.babyForestDemon: 'Baby Forest Demon',
  LiteHero.curatorePeste: 'Curatore della Peste',
  LiteHero.pyrel: 'Pyrel',
  LiteHero.lithra: 'Lithra',
  LiteHero.luce: 'La tua Luce',
  LiteHero.ombra: 'La tua Ombra',
  LiteHero.veyrth: 'Veyrth',
  LiteHero.doppelganger: 'Doppelganger',
  LiteHero.cavaliereLunare: 'Cavaliere Elité Lunare',
  LiteHero.slimeBlu: 'Slime Blu',
  LiteHero.vampiro: 'Vampiro',
  LiteHero.reGoblin: 'Re Goblin',
  LiteHero.pollo: 'Pollo di Brace',
  LiteHero.polloMeccanico: 'Pollo Meccanico',
  LiteHero.vesanybel: 'Vesanybel',
  LiteHero.aerovyr: 'Aerovyr',
  LiteHero.vedettaEiva: 'Vedetta Eiva',
  LiteHero.raganella: 'Raganella del Muschio',
  LiteHero.pipistrello: 'Pipistrello di Pece',
  LiteHero.guardiaSolare: 'Guardia Solare',
  LiteHero.eliteSolare: 'Guardia Elité Solare',
  LiteHero.guardianoSolare: 'Guardiano Solare',
  LiteHero.aberrazioneSolare: 'Aberrazione d’Oro e Marmo',
  LiteHero.demoneMinore: 'Demone Minore',
  LiteHero.demoneIntermedio: 'Demone Intermedio',
  LiteHero.demoneMaggiore: 'Demone Maggiore Prediletto',
  LiteHero.diavolo: 'Diavolo del Patto',
};
const liteWeaponLabels = {
  LiteWeapon.boomerang: 'Boomerang in legno',
  LiteWeapon.chakram: 'Chakram d’Iridio',
  LiteWeapon.spadaScudo: 'Spada e scudo',
  LiteWeapon.guanti: 'Guanti d’arme giganti',
  LiteWeapon.arco: 'Arco iniziale',
  LiteWeapon.scettro: 'Scettro magico',
  LiteWeapon.falceRunica: 'Falce runica',
  LiteWeapon.doppieLame: 'Doppie lame',
  LiteWeapon.carabinaImpulsi: 'Carabina a impulsi',
  LiteWeapon.piccaOssidiana: 'Picca d’ossidiana',
  LiteWeapon.balestraRunica: 'Balestra runica',
  LiteWeapon.fucileScostubandito: 'Fucile Scostubandito',
};
const liteBiomeLabels = {
  LiteBiome.campo: 'Campo Scostubanditi',
  LiteBiome.foresta: 'Foresta e radura',
  LiteBiome.dungeon: 'Regno Sotterraneo',
  LiteBiome.postea: 'Postea · Officina runica',
  LiteBiome.deserto: 'Deserto Divoratore',
  LiteBiome.orea: 'Orea Zalira',
};
const _posteaArtwork =
    'assets/oculum/theme_stories/webp/kingi_wrong_future_canon_20261119_f_cd1a4468.webp';
const _heroArtwork = 'assets/oculum/lite/personaggi-inchiostro.png';
const _weaponDetails = {
  LiteWeapon.boomerang: '+5 Danni · andata e ritorno',
  LiteWeapon.chakram: '+9 Danni · 9 m · andata e ritorno · 0,32 s',
  LiteWeapon.spadaScudo: '+6 Danni · +6 Scudo · +1 Difesa',
  LiteWeapon.guanti: '+10 Danni · mischia',
  LiteWeapon.arco: '+3 Danni · 10 m · 12 frecce',
  LiteWeapon.scettro: 'Attacco arcano · +15% ai Danni magici',
  LiteWeapon.falceRunica: 'Mischia · fendente ampio e richiamo',
  LiteWeapon.doppieLame: 'Mischia · due colpi rapidi e spostamento',
  LiteWeapon.carabinaImpulsi: 'Distanza · proiettile di energia runica',
  LiteWeapon.piccaOssidiana: '+9 Danni · affondo stretto da 4,3 m',
  LiteWeapon.balestraRunica: '+12 Danni · quadrello runico da 11 m',
  LiteWeapon.fucileScostubandito:
      '+5 Danni · tiro da 12 m o calcio del fucile da vicino',
};
const _difficultyLabels = {
  LiteDifficulty.moltoFacile: 'Molto facile',
  LiteDifficulty.facile: 'Facile',
  LiteDifficulty.medio: 'Medio',
  LiteDifficulty.difficile: 'Difficile',
  LiteDifficulty.oculum: 'Oculum',
};

class OculumLitePage extends StatefulWidget {
  const OculumLitePage({super.key, this.openRoom, this.suspendUpdates = false});

  final bool suspendUpdates;

  final Future<void> Function()? openRoom;

  @override
  State<OculumLitePage> createState() => _OculumLitePageState();
}

class _OculumLitePageState extends State<OculumLitePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _gameFocus = FocusNode(debugLabel: 'Oculum RL arena');
  final _seed = TextEditingController();
  final _name = TextEditingController(text: 'Duplicatore');
  final _held = <LogicalKeyboardKey>{};
  final _slots = List<OculumLiteSaveSlot?>.filled(
    oculumLiteSaveSlotCount,
    null,
  );
  final _unreadable = <int>{};
  final _recovered = <int>{};
  Future<void> _writes = Future<void>.value();
  SharedPreferences? _preferences;
  OculumLiteSaveStore? _saveStore;
  late final Ticker _ticker;
  final _arenaFrame = ValueNotifier<int>(0);
  bool _wellPreviewOpen = false;
  final _audio = OculumLiteAudio();
  Duration? _lastFrame;
  Duration _lastHudCheck = Duration.zero;
  Object? _shownHud;
  double _saveTime = 0;
  Object? _checkpoint;
  bool _paused = false;
  bool _showSettings = false;
  bool _busy = false;
  bool _openingRoom = false;
  final _updates = OculumRlUpdates();
  bool _restartingForUpdate = false;
  String? _attemptedUpdate;
  int? _activeSlot;
  int? _setupSlot;
  LiteHero _hero = LiteHero.evasore;
  LiteWeapon _weapon = LiteWeapon.arco;
  LiteWeapon get _startingWeapon => _hero.startingWeapon(_weapon);
  LiteDifficulty _difficulty = LiteDifficulty.medio;
  LiteBiome _biome = LiteBiome.campo;
  List<LiteBiome> _startOptions = LiteBiome.offers(0);
  OculumLiteAppearance _look = const OculumLiteAppearance();
  LiteInkFinish _inkFinish = LiteInkFinish.canonica;
  OculumLiteAppearance get _selectedLook =>
      (_hero == LiteHero.duplicatore
              ? _look
              : oculumLiteDefaultAppearance(_hero))
          .copyWith(inkFinish: _inkFinish);
  Point<double> _touchDirection = const Point(0, 0);
  bool _pointerAiding = false;
  Point<double>? _aim;
  String? _storageMessage;
  String? _checkpointMessage;
  bool _saveFailed = false;
  bool _progressSaveFailed = false;
  OculumLiteProgress _progress = const OculumLiteProgress();

  static const _progressSaveWarning =
      'Impossibile aggiornare il profilo dei Sigilli. I salvataggi delle run sono disponibili.';

  static final _gameTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xffc39b68),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xff141117),
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xff1b151d),
      titleTextStyle: TextStyle(
        fontFamily: 'Garamond',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Color(0xffebd2ad),
      ),
    ),
    useMaterial3: true,
  );

  OculumLiteSaveSlot? get _active {
    final index = _activeSlot;
    return index == null ? null : _slots[index];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_step);
    _updates.addListener(_maybeRestartForUpdate);
    unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed || _active == null) return;
    _clearMovement();
    setState(() => _paused = true);
    _syncTicker();
    unawaited(_save());
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    if (_active == null) {
      await _writes;
      return AppExitResponse.exit;
    }
    _clearMovement();
    setState(() => _paused = true);
    _syncTicker();
    return await _save() ? AppExitResponse.exit : AppExitResponse.cancel;
  }

  @override
  void dispose() {
    unawaited(_save());
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _audio.dispose();
    _updates.dispose();
    _arenaFrame.dispose();
    _gameFocus.dispose();
    _seed.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final store = await OculumLiteSaveStore.open();
      final preferences = store.preferences;
      final entries = await Future.wait(
        List.generate(_slots.length, store.read),
      );
      var progress = await store.readProgress();
      if (!mounted) return;
      for (var i = 0; i < _slots.length; i++) {
        final entry = entries[i];
        _slots[i] = entry.save;
        if (entry.unreadable) _unreadable.add(i);
        if (entry.recovered) _recovered.add(i);
        if (entry.save?.run case final run?) progress = progress.recordRun(run);
      }
      setState(() {
        _preferences = preferences;
        _saveStore = store;
        _progress = progress;
        _audio.restorePreferences(preferences);
        _storageMessage = null;
      });
      if (!widget.suspendUpdates) _updates.start(preferences);
    } on Object {
      if (!mounted) return;
      setState(
        () => _storageMessage = 'Impossibile aprire i salvataggi di Oculum RL.',
      );
    }
  }

  Future<bool> _save([int? index]) async {
    final slot = index ?? _activeSlot;
    final store = _saveStore;
    if (slot == null || store == null || _slots[slot] == null) return true;
    try {
      final value = _slots[slot]!.encode();
      final carried = _slots[slot]!.run.supply.carriedId;
      final promised = _slots[slot]!.run.supply.promised;
      final observed = const OculumLiteProgress().recordRun(_slots[slot]!.run);
      final task = _writes.then((_) async {
        await store.write(slot, value);
        final progress = _progress.record(
          observed.bestClearedFloor,
          observed.unlockedHeroes,
          pets: observed.discoveredPets,
          slimeCounters: observed.slimeCounters,
        );
        var progressSaveFailed = false;
        try {
          if (carried != null) await store.spendRestMemory(carried);
          if (promised != null) await store.saveRestMemory(promised);
          if (progress.earned > 0 ||
              progress.unlockedHeroes.isNotEmpty ||
              progress.discoveredPets.isNotEmpty ||
              progress.slimeKills > 0) {
            await store.writeProgress(progress);
          }
        } on Object {
          // The slot has already been verified. Report the separate failure
          // without rolling back a new attempt that is now on disk.
          progressSaveFailed = true;
        }
        if (mounted &&
            (!identical(progress, _progress) ||
                _progressSaveFailed != progressSaveFailed)) {
          setState(() {
            _progress = progress;
            _progressSaveFailed = progressSaveFailed;
          });
        }
      });
      _writes = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
      await task;
      if (mounted && (_recovered.contains(slot) || _saveFailed)) {
        setState(() {
          _recovered.remove(slot);
          _saveFailed = false;
          _storageMessage = null;
        });
      }
      return true;
    } on Object {
      // Leave the last valid slot available if the platform write fails.
    }
    if (mounted) {
      setState(() {
        _saveFailed = true;
        _checkpointMessage = null;
        _storageMessage =
            'Salvataggio non riuscito. Riprova dal menu di pausa.';
      });
    }
    return false;
  }

  Future<void> _saveNow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final saved = await _save();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _checkpointMessage = saved ? 'Partita salvata.' : null;
    });
  }

  void _saveInventoryChange(bool Function() change) {
    if (!change()) return;
    setState(() => _checkpointMessage = null);
    unawaited(_save());
  }

  void _showPets() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Compagni da trovare'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final pet in LiteCompanion.values)
                if (pet.discovery case final condition?)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _progress.discoveredPets.contains(pet)
                          ? Icons.pets
                          : Icons.lock_outline,
                    ),
                    title: Text(pet.label),
                    subtitle: Text(condition),
                  ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProgress() async {
    final store = _saveStore;
    if (store == null) return;
    String? failure;
    var buying = false;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, redraw) => AlertDialog(
          scrollable: true,
          title: const Text('Potenziamenti permanenti'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sigilli disponibili · ${_progress.unspent}'),
              Text(
                'Ottieni un Sigillo al primo completamento di ognuno di questi piani: ${LiteRun.sigilFloors.join(', ')}.',
              ),
              if (failure != null) Text(failure!),
              for (final upgrade in LitePermanentUpgrade.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(upgrade.label),
                  subtitle: Text(
                    'Grado ${_progress.upgrades[upgrade] ?? 0}/${LitePermanentUpgrade.maxRank} · ${upgrade.bonusPerRank} per grado nelle nuove run',
                  ),
                  trailing: TextButton(
                    onPressed: buying || _progress.buy(upgrade) == null
                        ? null
                        : () async {
                            final next = _progress.buy(upgrade);
                            if (buying || next == null) return;
                            redraw(() => buying = true);
                            try {
                              await _writes;
                              await store.writeProgress(next);
                              if (mounted) {
                                setState(() {
                                  _progress = next;
                                  _progressSaveFailed = false;
                                });
                              }
                              failure = null;
                            } on Object {
                              failure = 'Acquisto non salvato.';
                            }
                            if (context.mounted) redraw(() => buying = false);
                          },
                    child: const Text('1 Sigillo'),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: buying ? null : () => Navigator.pop(dialog),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetup(int index) {
    final previous = _slots[index];
    setState(() {
      _activeSlot = null;
      _setupSlot = index;
      _seed.text = (previous?.run.seed ?? Random().nextInt(0x7fffffff))
          .toString();
      _hero = previous?.run.hero ?? LiteHero.evasore;
      _weapon = LiteWeapon.starters.contains(previous?.startingWeapon)
          ? previous!.startingWeapon
          : LiteWeapon.arco;
      _startOptions = LiteBiome.offers(
        int.parse(_seed.text),
        include: previous?.startingBiome,
      );
      _biome = _startOptions.first;
      _difficulty = previous?.run.difficulty ?? LiteDifficulty.medio;
      final wasDuplicator = previous?.run.hero == LiteHero.duplicatore;
      _name.text = wasDuplicator ? previous!.name : 'Duplicatore';
      _inkFinish = previous?.appearance.inkFinish ?? LiteInkFinish.canonica;
      _look = wasDuplicator
          ? previous!.appearance
          : const OculumLiteAppearance();
      _storageMessage = null;
    });
    _syncTicker();
  }

  void _cancelSetup() {
    if (_busy) return;
    setState(() => _setupSlot = null);
  }

  Future<void> _newRun() async {
    final index = _setupSlot;
    if (index == null || _busy || _unreadable.contains(index)) return;
    final previous = _slots[index];
    if (previous != null && !previous.run.finished) return;
    final seed = int.tryParse(_seed.text.trim());
    if (seed == null || seed < 0 || seed > 0x7fffffff) {
      setState(
        () => _storageMessage = 'Inserisci un seed da 0 a 2.147.483.647.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _storageMessage = null;
    });
    LiteRestMemory? memory;
    try {
      memory = await _saveStore?.readRestMemory();
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _storageMessage = 'Impossibile leggere il ricordo della Veggente.';
      });
      return;
    }
    if (!mounted) return;
    _slots[index] = OculumLiteSaveSlot(
      run: LiteRun(
        seed: seed,
        progressId: 'solo-' + DateTime.now().microsecondsSinceEpoch.toString(),
        hero: _hero,
        allowGlue: _progress.discoveredPets.contains(LiteCompanion.goblinColla),
        allowMechanicalChicken: _progress.canPlay(LiteHero.pollo),
        weapon: _startingWeapon,
        difficulty: _difficulty,
        biome: _biome,
        upgrades: _progress.upgrades,
      ),
      name: _hero == LiteHero.duplicatore && _name.text.trim().isNotEmpty
          ? _name.text.trim()
          : liteHeroLabels[_hero]!,
      appearance: _selectedLook,
      attempt: (previous?.attempt ?? 0) + 1,
      startingWeapon: _startingWeapon,
      startingBiome: _biome,
    );
    if (memory != null) _slots[index]!.run.carryRestMemory(memory);
    final saved = await _save(index);
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved) {
      _enter(index);
    } else {
      setState(() => _slots[index] = previous);
    }
  }

  void _enter(int index) {
    if (_progress.canPlay(LiteHero.pollo)) {
      _slots[index]!.run.allowMechanicalChicken = true;
    }
    setState(() {
      _activeSlot = index;
      _setupSlot = null;
      _paused = false;
      _showSettings = false;
      _aim = null;
      _saveTime = 0;
      _checkpoint = _checkpointValues(_slots[index]!.run);
      _checkpointMessage = _recovered.contains(index)
          ? 'Partita recuperata dalla copia di sicurezza.'
          : null;
    });
    _syncTicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _activeSlot != null) _gameFocus.requestFocus();
    });
  }

  Future<void> _leaveRun() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _paused = true;
    });
    _clearMovement();
    _syncTicker();
    final saved = await _save();
    if (!mounted) return;
    if (!saved) {
      setState(() => _busy = false);
      return;
    }
    setState(() {
      _busy = false;
      _activeSlot = null;
    });
    _maybeRestartForUpdate();
  }

  Future<void> _retry() async {
    final old = _active;
    final index = _activeSlot;
    if (old == null || index == null || !old.run.finished || _busy) return;
    setState(() => _busy = true);
    final saved = await _save(index);
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved) _showSetup(index);
  }

  void _step(Duration elapsed) {
    final previous = _lastFrame;
    _lastFrame = elapsed;
    final run = _active?.run;
    if (previous == null ||
        run == null ||
        _paused ||
        _busy ||
        run.shopOpen ||
        run.finished) {
      return;
    }
    final dt = min(
      .05,
      (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond,
    );
    if (dt <= 0) return;
    bool held(LogicalKeyboardKey first, LogicalKeyboardKey second) =>
        _held.contains(first) || _held.contains(second);
    final moveX =
        (held(LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight)
            ? 1.0
            : 0.0) -
        (held(LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft)
            ? 1.0
            : 0.0);
    final moveY =
        (held(LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown)
            ? 1.0
            : 0.0) -
        (held(LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp) ? 1.0 : 0.0);
    final movement = Point<double>(
      moveX + _touchDirection.x,
      moveY + _touchDirection.y,
    );
    run.advanceFrame(
      dt,
      move: movement,
      walk: held(
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.controlRight,
      ),
    );
    _audio.combatSounds(run);
    _audio.burstSound(run, 0);
    _arenaFrame.value++;
    _saveTime += dt;
    if (run.finished || _saveTime >= 5) {
      _saveTime = 0;
      unawaited(_save());
    }
    if (run.finished ||
        elapsed - _lastHudCheck >= const Duration(milliseconds: 83)) {
      _lastHudCheck = elapsed;
      final checkpoint = _checkpointValues(run);
      if (_checkpoint != checkpoint) {
        _checkpoint = checkpoint;
        if (_saveTime > 0) {
          _saveTime = 0;
          unawaited(_save());
        }
      }
      _audio.update(run, playing: !run.finished);
      final hud = _hudValues(run);
      if (_shownHud != hud) {
        _shownHud = hud;
        setState(() {});
      }
    }
    if (run.finished) _syncTicker();
  }

  Object _checkpointValues(LiteRun run) => (
    run.solarPhase,
    run.solarStairs,
    run.realm,
    run.actRoom,
    run.thirdRoom,
    run.powerWellClaimed,
    run.provokedFaunaRooms,
    run.stage,
    run.stageClear,
    run.level,
    run.ownedWeapons.length,
    Object.hashAll(run.clones.map((ally) => (ally.id, ally.down))),
  );

  Object _hudValues(LiteRun run) {
    final quests = run.quests;
    return (
      run.hp.ceil(),
      run.maxHp.ceil(),
      run.oculum.floor(),
      run.maxOculum.ceil(),
      run.shield.ceil(),
      run.obser,
      run.level,
      run.weapon,
      run.dodgeCharges,
      run.message,
      run.finished,
      run.stage,
      run.finalBossPhase,
      run.arenaEvent?.notice,
      run.powerOffers.length,
      run.stageClear && run.hasPortalNearby,
      run.canOpenShop,
      run.arrows,
      run.reloading,
      run.openCooldown.ceil(),
      run.weaponArtCooldown.ceil(),
      run.banditRounds,
      run.banditDodgeReady,
      run.trialSecondsLeft,
      run.blockResistance.ceil(),
      run.blocking,
      run.fallenAllyNearby != null,
      (run.rescueProgress * 20).floor(),
      run.reloadingDuringRescue,
      Object.hashAll(
        run.clones
            .where((ally) => ally.companion != null)
            .map((ally) => (ally.id, ally.hp.ceil(), ally.down)),
      ),
      run.scrolls[run.equippedScrolls[0].index],
      run.scrolls[run.equippedScrolls[1].index],
      run.scrolls[run.equippedScrolls[2].index],
      run.scrolls[run.equippedScrolls[3].index],
      run.learnedScrolls.length,
      quests[0].current,
      quests[1].current,
      quests[2].current,
    );
  }

  void _clearMovement() {
    _held.clear();
    _touchDirection = const Point(0, 0);
    _pointerAiding = false;
    _active?.run.endRescue();
    _active?.run.setBlocking(false);
  }

  void _syncTicker() {
    final run = _active?.run;
    final playing =
        run != null && !_paused && !_busy && !run.finished && !run.shopOpen;
    _audio.update(run, playing: playing);
    if (playing == _ticker.isActive) return;
    _lastFrame = null;
    _lastHudCheck = Duration.zero;
    if (playing) {
      _shownHud = null;
      _ticker.start();
    } else {
      _ticker.stop();
      _arenaFrame.value++;
    }
  }

  Point<double> _targetFor(LiteRun run) =>
      _aim ?? run.position + const Point<double>(1, 0);

  void _closeShop(LiteRun run) {
    _audio.stopMerchantGreeting();
    setState(run.closeShop);
    _syncTicker();
    _gameFocus.requestFocus();
  }

  KeyEventResult _keyEvent(FocusNode _, KeyEvent event) {
    final run = _active?.run;
    if (run == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyF) {
      if (event is KeyUpEvent || event is KeyDownEvent) {
        setState(() => run.setBlocking(event is KeyDownEvent && !_paused));
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR && event is KeyUpEvent) {
      _releaseRescue(run);
      return KeyEventResult.handled;
    }
    const motion = [
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
    ];
    if (motion.contains(key)) {
      if (event is KeyUpEvent) {
        _held.remove(key);
      } else if (!_paused && !run.shopOpen) {
        _held.add(key);
      }
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyE) {
      if (run.shopOpen) {
        _closeShop(run);
        if (key == LogicalKeyboardKey.escape) _togglePause(showSettings: true);
      } else {
        _togglePause(showSettings: key == LogicalKeyboardKey.escape);
      }
      return KeyEventResult.handled;
    }
    if (_paused || run.shopOpen || run.finished) return KeyEventResult.ignored;
    final point = _targetFor(run);
    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      run.dash(point);
    } else if (key == LogicalKeyboardKey.space) {
      _saveInventoryChange(() => run.useOpen(point));
    } else if (key == LogicalKeyboardKey.keyG) {
      _saveInventoryChange(() => run.useWeaponArt(_targetFor(run)));
    } else if (key == LogicalKeyboardKey.keyQ &&
        run.hero == LiteHero.reGoblin) {
      _saveInventoryChange(run.royalCall);
    } else if (key == LogicalKeyboardKey.keyQ &&
        run.hero == LiteHero.slimeBlu) {
      _saveInventoryChange(() => run.slimeDash(point));
    } else if (key == LogicalKeyboardKey.keyV) {
      _saveInventoryChange(() => run.special(point));
    } else if (key == LogicalKeyboardKey.keyB &&
        run.hero == LiteHero.scostubandito) {
      _saveInventoryChange(() => run.throwBanditBomb(point));
    } else if (key == LogicalKeyboardKey.digit4) {
      run.switchWeapon();
    } else if (key == LogicalKeyboardKey.keyR) {
      if (!_tryRescue(run)) unawaited(_interact(run));
    } else {
      const scrollKeys = [
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
      ];
      final which = scrollKeys.indexOf(key);
      if (which < 0) return KeyEventResult.ignored;
      run.castScroll(which, point);
    }
    return KeyEventResult.handled;
  }

  void _togglePause({bool showSettings = false}) {
    _clearMovement();
    setState(() {
      _paused = !_paused;
      _showSettings = showSettings && _paused;
      if (!_paused) _checkpointMessage = null;
    });
    _syncTicker();
    if (_paused) unawaited(_save());
    if (!_paused) _gameFocus.requestFocus();
  }

  void _adjustAudio(VoidCallback apply) {
    setState(apply);
    _audio.applyVolumes();
    _syncTicker();
  }

  void _saveAudio() {
    final settings = _preferences;
    if (settings == null) return;
    unawaited(
      settings.setDouble(
        OculumLiteAudio.preferenceKey('musica'),
        _audio.musicVolume,
      ),
    );
    unawaited(
      settings.setDouble(
        OculumLiteAudio.preferenceKey('effetti'),
        _audio.effectsVolume,
      ),
    );
    unawaited(
      settings.setBool(OculumLiteAudio.preferenceKey('muto'), _audio.muted),
    );
  }

  Future<void> _interact(LiteRun run) async {
    if (_paused || run.finished || run.shopOpen) return;
    if (run.canChooseActTwo) {
      _togglePause();
      final realm = await chooseLiteSecondAct(context);
      if (!mounted) return;
      _togglePause();
      if (realm != null) _saveInventoryChange(() => run.enterSecondAct(realm));
      _gameFocus.requestFocus();
      return;
    }
    if (run.inThirdAct && run.hasPortalNearby) {
      _saveInventoryChange(run.advanceThirdAct);
      _aim = null;
      return;
    }
    if (run.nextActTwoRoom && run.hasPortalNearby) {
      _saveInventoryChange(run.advanceActTwo);
      _aim = null;
      return;
    }
    if (run.canEnterSolarDungeon) {
      _saveInventoryChange(run.enterSolarDungeon);
      _aim = null;
      return;
    }
    if (run.solarBossWaiting && run.hasPortalNearby) {
      _saveInventoryChange(run.enterSolarBoss);
      _aim = null;
      return;
    }
    if (!run.stageClear || !run.hasPortalNearby) {
      final hadRistoro = run.restUsed;
      setState(() => run.interact());
      if (!hadRistoro && run.restUsed) unawaited(_save());
      if (run.shopOpen) _clearMovement();
      _syncTicker();
      return;
    }
    if (run.awaitsRestHub) {
      _saveInventoryChange(run.enterRestHub);
      _aim = null;
      return;
    }
    _togglePause();
    final destination = await chooseOculumLiteRoute(context, run);
    if (!mounted) return;
    final changed = destination != null && run.advance(destination);
    setState(() {
      _aim = null;
      _paused = false;
    });
    _syncTicker();
    _gameFocus.requestFocus();
    if (changed) {
      _checkpoint = _checkpointValues(run);
      _saveTime = 0;
      unawaited(_save());
    }
  }

  Future<void> _openRelics(LiteRun run) async {
    _togglePause();
    await showLiteActRelics(
      context,
      run,
      take: (relic) => _saveInventoryChange(() => run.takeActRelic(relic)),
      move: (index, direction) =>
          _saveInventoryChange(() => run.moveActRelic(index, direction)),
    );
    if (!mounted) return;
    _togglePause();
    _gameFocus.requestFocus();
  }

  Future<void> _openRestHub(LiteRun run) async {
    _togglePause();
    await showLiteRestHub(
      context,
      world: () => run,
      playVoice: _audio.playMerchantGreeting,
      buy: (item) => _saveInventoryChange(() => run.buyRestItem(item)),
      remember: (item) =>
          _saveInventoryChange(() => run.rememberRestItem(item)),
      exchange: () => _saveInventoryChange(run.exchangeLunarPiece),
    );
    _audio.stopMerchantGreeting();
    if (!mounted) return;
    _togglePause();
    _gameFocus.requestFocus();
  }

  bool _tryRescue(LiteRun run) {
    if (_paused ||
        run.finished ||
        run.shopOpen ||
        run.fallenAllyNearby == null) {
      return false;
    }
    setState(() => run.beginRescue());
    return true;
  }

  void _releaseRescue(LiteRun run) {
    if (run.rescuing) setState(run.endRescue);
  }

  Widget? _contextAction(LiteRun run) {
    final String label;
    if (run.rescuing) {
      final progress = (run.rescueProgress * 100).floor();
      label = run.reloadingDuringRescue
          ? 'Soccorso e ricarica $progress%'
          : 'Soccorso $progress%';
    } else if (run.fallenAllyNearby != null) {
      label = 'Tieni R · Soccorri';
    } else if (run.canEnterSolarDungeon) {
      label = 'R · Scendi le scale d’oro';
    } else if (run.solarBossWaiting && run.hasPortalNearby) {
      label = 'R · Sfida il Guardiano Solare';
    } else if (run.canChooseActTwo) {
      label = 'R · Scegli il percorso dell’Atto II';
    } else if (run.inThirdAct && run.hasPortalNearby) {
      label = 'R · Prossima sala dell’Atto III';
    } else if (run.nextActTwoRoom && run.hasPortalNearby) {
      label = 'R · Prosegui nell’Atto II';
    } else if (run.hasPortalNearby) {
      label = run.awaitsRestHub
          ? 'R · Entra nella Sala di ristoro'
          : 'R · Attraversa';
    } else if (run.canRest) {
      label = 'R · Ristoro';
    } else if (run.canOpenShop) {
      label = 'R · Mercante';
    } else if (run.weapon == LiteWeapon.arco &&
        run.arrows < LiteRun.bowCapacity) {
      label = run.reloading ? 'Ricarica…' : 'R · Ricarica';
    } else {
      return null;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pointerAiding = _tryRescue(run),
      onTapCancel: () {
        _releaseRescue(run);
        _pointerAiding = false;
      },
      onTap: () {
        if (!_pointerAiding && run.fallenAllyNearby == null) {
          unawaited(_interact(run));
        }
        _releaseRescue(run);
        _pointerAiding = false;
      },
      child: IgnorePointer(child: _action(label, () {})),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    return Theme(
      data: _gameTheme,
      child: PopScope(
        canPop: active == null && _setupSlot == null,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (active != null) {
            unawaited(_leaveRun());
          } else if (_setupSlot != null) {
            _cancelSetup();
          }
        },
        child: Scaffold(
          appBar: active != null
              ? null
              : AppBar(
                  title: const Text('Oculum RL'),
                  leading: _setupSlot == null
                      ? null
                      : IconButton(
                          onPressed: _busy ? null : _cancelSetup,
                          tooltip: 'Annulla',
                          icon: const Icon(Icons.arrow_back),
                        ),
                  actions: [
                    if (_setupSlot == null &&
                        _updates.supported &&
                        !widget.suspendUpdates)
                      IconButton(
                        tooltip: 'Aggiornamenti',
                        onPressed: _showUpdates,
                        icon: const Icon(Icons.system_update_alt_outlined),
                      ),
                    IconButton(
                      tooltip: 'Impostazioni audio',
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => StatefulBuilder(
                          builder: (context, refresh) => AlertDialog(
                            title: const Text('Audio'),
                            content: _audioSettings(refresh: refresh),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Chiudi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
          body: SafeArea(
            child: active == null
                ? _setupSlot == null
                      ? _lobby()
                      : _setup()
                : Focus(
                    focusNode: _gameFocus,
                    autofocus: true,
                    onKeyEvent: _keyEvent,
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) _clearMovement();
                    },
                    child: _fight(active),
                  ),
          ),
        ),
      ),
    );
  }

  bool get _safeToRestart =>
      _activeSlot == null &&
      _setupSlot == null &&
      !_openingRoom &&
      !_busy &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  void _maybeRestartForUpdate() {
    final ready = _updates.ready;
    if (!mounted ||
        widget.suspendUpdates ||
        !_updates.automatic ||
        ready == null ||
        _attemptedUpdate == '$ready' ||
        !_safeToRestart) {
      return;
    }
    unawaited(_restartForUpdate());
  }

  Future<void> _restartForUpdate() async {
    if (_restartingForUpdate || !_safeToRestart) return;
    _restartingForUpdate = true;
    _attemptedUpdate = '${_updates.ready}';
    final navigator = Navigator.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text('Riavvio Oculum RL'),
            content: Text('Sto verificando l’avvio della nuova versione.'),
          ),
        ),
      ),
    );
    await _writes;
    final started = await _updates.launch();
    if (started) {
      exitForOculumRlUpdate();
      return;
    }
    if (!mounted) return;
    navigator.pop();
    _restartingForUpdate = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La nuova versione non si è avviata. Puoi continuare a giocare.',
        ),
      ),
    );
  }

  Future<void> _showUpdates() async {
    final restart = await showDialog<bool>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: _updates,
        builder: (context, _) => AlertDialog(
          title: const Text('Aggiornamenti'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_updates.edition.label} · $oculumRlVersion'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aggiornamenti automatici'),
                value: _updates.automatic,
                onChanged: _updates.setAutomatic,
              ),
              if (_updates.message case final message?) Text(message),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _updates.checking ? null : _updates.check,
              child: const Text('Controlla ora'),
            ),
            if (_updates.ready != null)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Riavvia ora'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (restart == true) {
      await _restartForUpdate();
    } else {
      _maybeRestartForUpdate();
    }
  }

  Widget _lobby() {
    final firstFree = List.generate(
      _slots.length,
      (i) => i,
    ).where((i) => _slots[i] == null && !_unreadable.contains(i)).firstOrNull;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 208,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _heroArtwork,
                      fit: BoxFit.cover,
                      alignment: const Alignment(.25, -.2),
                      cacheWidth: 1100,
                      excludeFromSemantics: true,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xf1120d16),
                            Color(0x7114111a),
                            Color(0x1514111a),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Oculum RL',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(color: const Color(0xffffe3bb)),
                          ),
                          const Text(
                            'Campagna · ${LiteRun.campaignRooms} stanze',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: const ValueKey('oculum-lite-play'),
                  onPressed: _saveStore == null || firstFree == null
                      ? null
                      : () => _showSetup(firstFree),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Gioca subito'),
                ),
                OutlinedButton(
                  onPressed: _saveStore == null ? null : _showProgress,
                  child: const Text('Potenziamenti permanenti'),
                ),
                OutlinedButton.icon(
                  onPressed: _showPets,
                  icon: const Icon(Icons.pets),
                  label: const Text('Compagni'),
                ),
                if (widget.openRoom != null)
                  OutlinedButton.icon(
                    onPressed: _openingRoom
                        ? null
                        : () async {
                            setState(() => _openingRoom = true);
                            try {
                              await widget.openRoom!();
                            } finally {
                              if (mounted) {
                                setState(() => _openingRoom = false);
                                _maybeRestartForUpdate();
                              }
                            }
                          },
                    icon: const Icon(Icons.groups),
                    label: const Text('Online'),
                  ),
                if (_saveStore == null && _storageMessage != null)
                  TextButton(onPressed: _load, child: const Text('Riprova')),
              ],
            ),
            if (_storageMessage case final String message)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message),
              ),
            if (_progressSaveFailed) const Text(_progressSaveWarning),
            const SizedBox(height: 20),
            if (_saveStore == null && _storageMessage == null)
              const LinearProgressIndicator(),
            Text('Salvataggi', style: Theme.of(context).textTheme.titleLarge),
            for (var i = 0; i < _slots.length; i++) _slotTile(i),
          ],
        ),
      ),
    );
  }

  Widget _slotTile(int index) {
    final slot = _slots[index];
    final protected = _unreadable.contains(index);
    return ListTile(
      leading: Icon(slot == null ? Icons.bookmark_border : Icons.bookmark),
      title: Text(slot == null ? 'Salvataggio ${index + 1}' : slot.name),
      subtitle: Text(
        protected
            ? 'Dati illeggibili. Slot preservato.'
            : slot == null
            ? 'Libero'
            : slot.run.victorious
            ? 'Campagna completata · Tentativo ${slot.attempt}'
            : '${liteBiomeLabels[slot.run.biome]} · Piano ${slot.run.stage} · Tentativo ${slot.attempt}'
                  '${_recovered.contains(index) ? ' · Copia di sicurezza' : ''}',
      ),
      trailing: slot == null
          ? OutlinedButton(
              onPressed: protected || _saveStore == null
                  ? null
                  : () => _showSetup(index),
              child: const Text('Nuova run'),
            )
          : FilledButton.tonal(
              onPressed: () => _enter(index),
              child: const Text('Continua'),
            ),
    );
  }

  Widget _setup() {
    final previous = _slots[_setupSlot!];
    final heading = previous == null
        ? 'Nuova run'
        : 'Tentativo ${previous.attempt + 1}';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Text(
                    '$heading · Salvataggio ${_setupSlot! + 1}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Scegli il personaggio',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final hero in LiteHero.values.where(
                        _progress.canPlay,
                      ))
                        ChoiceChip(
                          label: Text(liteHeroLabels[hero]!),
                          selected: _hero == hero,
                          onSelected: (_) => setState(() => _hero = hero),
                        ),
                    ],
                  ),
                  if (_hero == LiteHero.duplicatore) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _editAppearance,
                      icon: const Icon(Icons.palette_outlined),
                      label: const Text('Personalizza in 2D'),
                    ),
                  ],
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: 202,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(.40, -.2),
                                radius: .95,
                                colors: [
                                  Color(0xff4b343c),
                                  Color(0xff211925),
                                  Color(0xff17131e),
                                ],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            left: 74,
                            child: OculumLiteHeroPreview(
                              hero: _hero,
                              weapon: _startingWeapon,
                              appearance: _selectedLook,
                              showClone: _hero == LiteHero.duplicatore,
                            ),
                          ),
                          Positioned(
                            left: 13,
                            top: 13,
                            right: 13,
                            child: Text(
                              _hero.talentName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: const Color(0xfff6dfbe)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  OculumLiteInkFinishPicker(
                    selected: _inkFinish,
                    onChanged: (finish) => setState(() => _inkFinish = finish),
                  ),
                  Text(switch (_hero) {
                    LiteHero.evasore => 'Destro: schivata intangibile. A ogni uccisione, 50% di recuperare il 6% della Vita massima. Trova più pergamene.',
                    LiteHero.duplicatore => 'Destro: crea un clone. Costa il 2% della Vita massima e puoi tenere due cloni contemporaneamente.',
                    LiteHero.ashley => 'Destro: allunga il braccio a molla e colpisce a 4,2 m. Il pugno infligge 14 Danni base e si ricarica in 3,4 secondi.',
                    LiteHero.scostubandito => 'Clic destro · Pugno con 25% di critico. G · Fucile schivata. B · Lancia una bomba (2 Oculum). Lo Scudo respinge i nemici vicini se resiste e si rigenera alla prima rottura del piano.',
                    LiteHero.pyrel => 'Destro · Palla di fuoco che rimbalza su pareti e nemici.',
                    LiteHero.lithra => 'Destro · Spezza il terreno in linea e colpisce chi ci sta sopra.',
                    LiteHero.luce => 'Destro · Affondo a lunga portata. L’Open rinforza lo Scudo.',
                    LiteHero.ombra => 'Destro · Scatto intangibile. L’Open mantiene il velo per 3 secondi.',
                    LiteHero.veyrth => 'Destro · Sfera cava. Con Spazio lanci un anello di sfere.',
                    LiteHero.cavaliereLunare => 'Destro o V evoca due Guardie Lunari. Spada e scudo raddoppiati, Blocco a 300.',
                    LiteHero.slimeBlu => 'Q rende invisibile durante lo scatto. Mira da vicino e ripeti il clic destro per mantenere l’assorbimento e recuperare Vita e Oculum.',
                    LiteHero.polloMeccanico => 'Tre raggi inseguono i nemici. Clic destro/V spara tre uova meccaniche alle spalle. Spazio ne potenzia le esplosioni.',
                    LiteHero.pollo =>
                      'Click · Beccata. Destro o V · Tre uova alle spalle.',
                    LiteHero.raganella =>
                      'Click · Linguata. Destro o V · Colpo a 4,1 m.',
                    LiteHero.pipistrello =>
                      'Click · Artigli. Destro o V · Ultrasuono respingente.',
                    LiteHero.reGoblin => 'Destro o V · Stordisci con un colpo, recupero 1,8 s. Q · Rialza gli alleati entro 10 m al 50% Vita.',
                    LiteHero.vampiro => 'Ogni colpo respinge. Destro per diventare un pipistrello intangibile per 3 s. Spazio scatena la forma di sangue.',
                    LiteHero.doppelganger => 'A mani nude. Destro · Mira a un nemico a 7 m per copiarlo. Boss ed eco sono esclusi. Se perdi la forma torni con il 65% della Vita che avevi prima.',
                    LiteHero.curatorePeste => 'Destro · Evoca uno scheletro con la falce e uno con l’arco. Le tue uccisioni e quelle degli scheletri recuperano l’8% della Vita massima e 10 Resistenza del blocco.',
                    _ => 'Clic destro · ${_hero.talentName}',
                  }),
                  Text(
                    'Destro o V per la skill. Spazio · ${_hero.openName} · 5 Oculum. ${_hero.openDescription} '
                    'Recupero al livello 1/3/6: 8/7/6 s.',
                  ),
                  const SizedBox(height: 14),
                  if (_hero.fixedWeapon == null)
                    DropdownButtonFormField<LiteWeapon>(
                      isExpanded: true,
                      initialValue: _weapon,
                      decoration: const InputDecoration(
                        labelText: 'Equipaggiamento iniziale',
                      ),
                      items: [
                        for (final weapon in LiteWeapon.starters)
                          DropdownMenuItem(
                            value: weapon,
                            child: Text(liteWeaponLabels[weapon]!),
                          ),
                      ],
                      onChanged: (weapon) {
                        if (weapon != null) setState(() => _weapon = weapon);
                      },
                    ),
                  if (_hero == LiteHero.doppelganger)
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.back_hand_outlined),
                      title: Text('A mani nude'),
                      subtitle: Text(
                        'Clic sinistro per attaccare. Cambia mosse quando copi una creatura.',
                      ),
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _weaponIcon(_startingWeapon),
                      title: Text(_weaponDetails[_startingWeapon]!),
                      subtitle: _hero.fixedWeapon != null
                          ? Text('${_startingWeapon.label} · Arma iniziale')
                          : null,
                    ),
                  DropdownButtonFormField<LiteDifficulty>(
                    initialValue: _difficulty,
                    decoration: const InputDecoration(labelText: 'Difficoltà'),
                    items: [
                      for (final level in LiteDifficulty.values)
                        DropdownMenuItem(
                          value: level,
                          child: Text(_difficultyLabels[level]!),
                        ),
                    ],
                    onChanged: (level) {
                      if (level != null) setState(() => _difficulty = level);
                    },
                  ),
                  DropdownButtonFormField<LiteBiome>(
                    isExpanded: true,
                    key: ValueKey(_startOptions),
                    initialValue: _biome,
                    decoration: const InputDecoration(labelText: 'Primo piano'),
                    items: [
                      for (final biome in _startOptions)
                        DropdownMenuItem(
                          value: biome,
                          child: Text(
                            liteBiomeLabels[biome]!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (biome) {
                      if (biome != null) setState(() => _biome = biome);
                    },
                  ),
                  if (_biome == LiteBiome.postea)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          _posteaArtwork,
                          height: 132,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, .16),
                          cacheWidth: 720,
                          semanticLabel: 'Officine di Postea con motori runici',
                        ),
                      ),
                    ),
                  TextField(
                    controller: _seed,
                    onChanged: (value) {
                      final seed = int.tryParse(value);
                      if (seed == null) return;
                      setState(() {
                        _startOptions = LiteBiome.offers(seed);
                        if (!_startOptions.contains(_biome))
                          _biome = _startOptions.first;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Seed'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  if (LiteHero.values.any((hero) => !_progress.canPlay(hero)))
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Come sbloccare gli altri eroi'),
                      children: [
                        for (final hero in LiteHero.values.where(
                          (hero) => !_progress.canPlay(hero),
                        ))
                          ListTile(
                            title: Text(liteHeroLabels[hero]!),
                            subtitle: Text(
                              hero == LiteHero.slimeBlu
                                  ? '${hero.unlockHint!} ${_progress.slimeKills}/10'
                                  : hero.unlockHint!,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(22, 6, 22, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_storageMessage case final String message) Text(message),
                  if (_progressSaveFailed) const Text(_progressSaveWarning),
                  FilledButton.icon(
                    key: const ValueKey('oculum-lite-start-run'),
                    onPressed: _busy ? null : _newRun,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Inizia la run'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editAppearance() async {
    final selected = await editOculumLiteAppearance(
      context,
      appearance: _look,
      weapon: _weapon,
      name: _name.text,
    );
    if (!mounted || selected == null) return;
    _name.text = selected.name;
    setState(() => _look = selected.appearance);
  }

  void _setActiveInkFinish(LiteInkFinish finish) {
    final slot = _activeSlot;
    final active = _active;
    if (slot == null || active == null || active.appearance.inkFinish == finish)
      return;
    setState(
      () => _slots[slot] = active.withAppearance(
        active.appearance.copyWith(inkFinish: finish),
      ),
    );
    unawaited(_save(slot));
  }

  Widget _fight(OculumLiteSaveSlot active) {
    final run = active.run;
    final blocked = _paused || run.shopOpen || run.finished;
    final contextualAction = blocked ? null : _contextAction(run);
    final encounter = switch (run.encounter) {
      LiteEncounter.ordinary => '',
      LiteEncounter.elite => ' · Élite',
      LiteEncounter.boss => ' · Boss',
      LiteEncounter.finalBoss => ' · Finale',
    };
    final bossPhase = run.bossStatus;
    return LayoutBuilder(
      builder: (context, size) {
        final compact =
            size.maxWidth < 680 ||
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;
        return Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              onPointerSignal: (event) {
                if (!blocked &&
                    event is PointerScrollEvent &&
                    event.scrollDelta.dy != 0) {
                  setState(
                    () => run.switchWeapon(event.scrollDelta.dy > 0 ? 1 : -1),
                  );
                }
              },
              child: OculumLiteArena(
                run: run,
                view: _arenaFrame,
                appearance: run.hero == LiteHero.evasore
                    ? OculumLiteAppearance.evasore
                    : active.appearance,
                onAim: (target) {
                  if (blocked) return;
                  _aim = target;
                  run.lookAt(target);
                },
                onAttack: blocked
                    ? null
                    : (target) {
                        _gameFocus.requestFocus();
                        if (run.powerWellAt(target)) {
                          unawaited(_showWell(run));
                        } else {
                          run.attack(target);
                        }
                      },
                onTalent: blocked
                    ? null
                    : (target) {
                        _gameFocus.requestFocus();
                        run.special(target);
                      },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: const Color(0xe61b151d),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${active.name} · ${liteBiomeLabels[run.biome]}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${run.arenaLabel}$encounter$bossPhase'
                              '${run.arenaSpeed > 1 ? ' · Ritmo +${run.arenaSpeedBonus}%' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Vita ${run.hp.ceil()}/${run.maxHp.ceil()} · Oculum ${run.oculum.floor()}/${run.maxOculum.ceil()} · Scudo ${run.shield.ceil()} · Obser ${run.obser}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (run.arenaEvent case final event?)
                              Text(
                                event.notice,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xfff1c58b),
                                  fontSize: 11,
                                ),
                              ),
                            if (run.weapon == LiteWeapon.arco)
                              Text(
                                'Frecce ${run.arrows}/${LiteRun.bowCapacity}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            OculumLitePlayerLifeBar(value: run.hp / run.maxHp),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Inventario e pausa',
                        onPressed: _togglePause,
                        icon: const Icon(Icons.inventory_2_outlined),
                      ),
                      IconButton(
                        tooltip: 'Impostazioni · Esc',
                        onPressed: () => _togglePause(showSettings: true),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (run.missions.isNotEmpty && !run.finished)
              Positioned(
                top: run.weapon == LiteWeapon.arco ? 92 : 77,
                right: 10,
                child: IgnorePointer(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compact ? size.maxWidth * .52 : 275,
                    ),
                    child: Material(
                      color: const Color(0xc3221921),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final quest in run.missions)
                              Text(
                                '${quest.complete ? '✓ ' : ''}${quest.name}  ${quest.current}/${quest.target}',
                                style: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!blocked)
              Positioned(
                bottom: 2,
                left: 4,
                right: 4,
                child: Column(
                  children: [
                    if (run.powerOffers.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () => _showPowerOffers(run),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Scegli un potenziamento'),
                      ),
                    if (run.hasPowerWell && !run.powerWellClaimed)
                      TextButton.icon(
                        onPressed: () => _showWell(run),
                        icon: const Icon(Icons.water_drop_outlined),
                        label: const Text('Offerte del pozzo'),
                      ),
                    OculumLiteCompanionStatus(run: run),
                    OculumLiteTrialStatus(run: run),
                    if (run.message.isNotEmpty)
                      Material(
                        color: const Color(0xcc1b151d),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Text(
                            run.message,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (compact)
                          _movementPad()
                        else
                          const SizedBox(width: 6),
                        Flexible(
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 3,
                            runSpacing: 2,
                            children: [
                              if (compact)
                                _action(
                                  'Attacco',
                                  () => run.attack(_targetFor(run)),
                                ),
                              if (compact)
                                _action(
                                  run.hero.talentName,
                                  () => run.special(_targetFor(run)),
                                ),
                              _action(
                                run.openCooldown > 0
                                    ? (run.plagueForm
                                          ? 'Forma corvina · ${run.plagueSeconds.toStringAsFixed(1)} s'
                                          : 'Open ${run.openGrade} · ${run.openCooldown.ceil()} s')
                                    : 'Open ${run.openGrade} · ${run.hero.openName}',
                                () => _saveInventoryChange(
                                  () => run.useOpen(_targetFor(run)),
                                ),
                              ),
                              if (run.hero == LiteHero.scostubandito)
                                _action(
                                  run.banditRounds > 0
                                      ? 'Infusi · ${run.banditRounds}'
                                      : 'Fucile schivata · G',
                                  () => _saveInventoryChange(
                                    run.banditRifleSkill,
                                  ),
                                ),
                              if (run.hero == LiteHero.scostubandito)
                                _action(
                                  run.bombCooldown > 0
                                      ? 'Bomba · ${run.bombCooldown.ceil()} s'
                                      : 'Bomba · B',
                                  () => _saveInventoryChange(
                                    () => run.throwBanditBomb(_targetFor(run)),
                                  ),
                                ),
                              OculumLiteBlockControl(
                                resistance: run.blockResistance,
                                capacity: run.maxBlockResistance,
                                active: run.blocking,
                                onHeld: (held) =>
                                    setState(() => run.setBlocking(held)),
                              ),
                              if (compact)
                                _action(
                                  'Scatto',
                                  () => run.dash(_targetFor(run)),
                                ),
                              if (run.hero == LiteHero.reGoblin)
                                _action(
                                  'Richiamo reale · Q',
                                  () => _saveInventoryChange(run.royalCall),
                                ),
                              if (run.hero == LiteHero.slimeBlu)
                                _action(
                                  'Scia invisibile · Q',
                                  () => run.slimeDash(_targetFor(run)),
                                ),
                              if (run.hero != LiteHero.doppelganger)
                                for (
                                  var i =
                                      run.hero == LiteHero.slimeBlu ||
                                          run.hero == LiteHero.reGoblin
                                      ? 1
                                      : 0;
                                  i < 4;
                                  i++
                                )
                                  _scrollAction(run, i),
                              if (run.hasWeaponArt() &&
                                  run.hero != LiteHero.scostubandito)
                                Tooltip(
                                  message: '3 Oculum · recupero 4,2 s',
                                  child: FilledButton.tonal(
                                    onPressed: run.weaponArtCooldown > 0
                                        ? null
                                        : () => _saveInventoryChange(
                                            () => run.useWeaponArt(
                                              _targetFor(run),
                                            ),
                                          ),
                                    child: Text(
                                      run.weaponArtCooldown > 0
                                          ? 'G · ${run.weaponArtCooldown.ceil()} s'
                                          : 'G · ${run.weaponArtLabel()}',
                                    ),
                                  ),
                                ),
                              if (run.restHub)
                                _action('Botteghe', () => _openRestHub(run)),
                              if (run.canClaimActRelic ||
                                  run.actRelics.isNotEmpty)
                                _action('Reliquie', () => _openRelics(run)),
                              ?contextualAction,
                              if (compact && run.hero != LiteHero.doppelganger)
                                _action(
                                  'Cambia arma',
                                  () => run.switchWeapon(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!compact)
                      Text(
                        '${liteWeaponLabels[run.weapon]} · WASD movimento · clic attacco · '
                        'destro/V talento · Spazio Open · F blocco · G arma · Shift scatto · E inventario'
                        '${run.banditDodgeReady ? ' · Prossimo scatto intangibile' : ''}'
                        '${run.hero == LiteHero.evasore ? ' · Schivate ${run.dodgeCharges}' : ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            if (blocked)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                run.victorious
                                    ? 'Campagna completata'
                                    : run.dead
                                    ? 'Fine della run'
                                    : run.shopOpen
                                    ? 'Mercante'
                                    : _showSettings
                                    ? 'Impostazioni'
                                    : 'Inventario',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (_storageMessage case final String message)
                                Text(message),
                              if (_checkpointMessage case final String message)
                                Text(message),
                              if (_progressSaveFailed)
                                const Text(_progressSaveWarning),
                              Text(
                                'Livello ${run.level} · EXP ${run.exp} · Ascension Dust ${run.crystals} · Obser ${run.obser}',
                              ),
                              if (run.finished) ...[
                                Text(run.message),
                                if (run.canEnterThirdAct)
                                  FilledButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _saveInventoryChange(() {
                                            if (!run.enterThirdAct())
                                              return false;
                                            _aim = null;
                                            _syncTicker();
                                            return true;
                                          }),
                                    child: const Text('Entra nell’Atto III'),
                                  ),
                                FilledButton(
                                  onPressed: _busy ? null : _retry,
                                  child: Text(
                                    run.victorious
                                        ? 'Nuova run'
                                        : 'Nuovo tentativo',
                                  ),
                                ),
                              ] else if (run.shopOpen) ...[
                                OculumRlMerchant(
                                  key: ValueKey(run.stage),
                                  goblin: (run.seed + run.stage).isOdd,
                                ),
                                LiteMerchantGreeting(
                                  key: ValueKey((run.seed, run.stage)),
                                  shopkeeper: (run.seed + run.stage).isOdd
                                      ? LiteShopkeeper.goblin
                                      : LiteShopkeeper.armaiola,
                                  playVoice: _audio.playMerchantGreeting,
                                ),
                                Text(run.message),
                                OutlinedButton(
                                  onPressed:
                                      run.obser < LiteRun.potionPrice ||
                                          run.hp >= run.maxHp
                                      ? null
                                      : () =>
                                            _saveInventoryChange(run.buyPotion),
                                  child: const Text(
                                    'Foglia di Linfa Viva · ${LiteRun.potionPrice} Obser',
                                  ),
                                ),
                                if (run.hero == LiteHero.evasore)
                                  OutlinedButton(
                                    onPressed:
                                        run.obser < LiteRun.dodgeUpgradePrice
                                        ? null
                                        : () => _saveInventoryChange(
                                            run.buyDodgeUpgrade,
                                          ),
                                    child: const Text(
                                      'Potenzia la schivata · ${LiteRun.dodgeUpgradePrice} Obser',
                                    ),
                                  ),
                                for (final weapon in run.shopWeapons)
                                  Tooltip(
                                    message: _weaponDetails[weapon]!,
                                    child: OutlinedButton.icon(
                                      onPressed: !run.canBuyWeapon(weapon)
                                          ? null
                                          : () => _saveInventoryChange(
                                              () => run.buyWeapon(weapon),
                                            ),
                                      icon: _weaponIcon(weapon, size: 28),
                                      label: Text(
                                        '${liteWeaponLabels[weapon]} · ${run.priceForWeapon(weapon)} Obser',
                                      ),
                                    ),
                                  ),
                                if (run.supply.lunarPieces > 0)
                                  FilledButton.tonal(
                                    onPressed: () => _saveInventoryChange(
                                      run.exchangeLunarPiece,
                                    ),
                                    child: Text(
                                      'Scambia frammento lunare · 60 Obser (${run.supply.lunarPieces})',
                                    ),
                                  ),
                                FilledButton(
                                  onPressed: () => _closeShop(run),
                                  child: const Text('Torna al piano'),
                                ),
                              ] else if (_showSettings) ...[
                                _audioSettings(),
                                OculumLiteInkFinishPicker(
                                  selected: active.appearance.inkFinish,
                                  onChanged: _setActiveInkFinish,
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _showSettings = false),
                                  child: const Text('Apri inventario'),
                                ),
                                FilledButton(
                                  onPressed: _togglePause,
                                  child: const Text('Riprendi'),
                                ),
                              ] else ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        setState(() => _showSettings = true),
                                    icon: const Icon(Icons.settings_outlined),
                                    label: const Text('Impostazioni'),
                                  ),
                                ),
                                if (run.activePowers.isNotEmpty) ...[
                                  Text(
                                    'Potenziamenti della run',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  for (final power in run.activePowers)
                                    ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        '${power.label} · Grado ${run.powerRank(power)}/3',
                                      ),
                                      subtitle: Text(
                                        power.descriptionAt(
                                          run.powerRank(power),
                                        ),
                                      ),
                                    ),
                                ],
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _weaponIcon(run.weapon),
                                  title: Text(
                                    'In uso: ${liteWeaponLabels[run.weapon]}',
                                  ),
                                  subtitle: Text(
                                    '${_weaponDetails[run.weapon]!}\n'
                                    'Portata con i bonus · ${run.weaponReach(run.weapon).toStringAsFixed(1).replaceFirst('.', ',')} m',
                                  ),
                                ),
                                for (
                                  var i = 0;
                                  i < run.equippedScrolls.length;
                                  i++
                                )
                                  DropdownButtonFormField<LiteScroll>(
                                    isExpanded: true,
                                    initialValue: run.equippedScrolls[i],
                                    decoration: InputDecoration(
                                      labelText: ['Q', '1', '2', '3'][i],
                                    ),
                                    items: [
                                      for (final scroll in LiteScroll.values)
                                        DropdownMenuItem(
                                          value: scroll,
                                          child: Text(
                                            '${scroll.label} · ${run.scrolls[scroll.index]}'
                                            '${run.learnedScrolls.contains(scroll) ? ' · appresa' : ''}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                    onChanged: (scroll) {
                                      if (scroll != null) {
                                        _saveInventoryChange(
                                          () => run.equipScroll(i, scroll),
                                        );
                                      }
                                    },
                                  ),
                                FilledButton(
                                  onPressed: _togglePause,
                                  child: const Text('Riprendi'),
                                ),
                              ],
                              OutlinedButton(
                                onPressed: _busy ? null : _saveNow,
                                child: const Text('Salva ora'),
                              ),
                              TextButton(
                                onPressed: _busy ? null : _leaveRun,
                                child: const Text(
                                  'Salva e torna ai salvataggi',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showWell(LiteRun run) async {
    if (_wellPreviewOpen || !run.hasPowerWell) return;
    _wellPreviewOpen = true;
    _clearMovement();
    final arena = run.inputArena;
    final chosen = await showOculumLiteWell(context, run, canChoose: true);
    _wellPreviewOpen = false;
    if (!mounted || !identical(_active?.run, run)) return;
    if (chosen != null) {
      _saveInventoryChange(() => run.claimPowerWell(chosen, arena: arena));
    }
    _gameFocus.requestFocus();
  }

  Future<void> _showPowerOffers(LiteRun run) async {
    _clearMovement();
    final chosen = await chooseOculumLitePower(context, run);
    if (!mounted || !identical(_active?.run, run) || chosen == null) return;
    if (run.choosePowerUp(chosen)) {
      setState(() {});
      _audio.playEffect('ricompensa');
      unawaited(_save());
    }
    _gameFocus.requestFocus();
  }

  Widget _audioSettings({StateSetter? refresh}) {
    void update(VoidCallback apply) {
      _adjustAudio(apply);
      refresh?.call(() {});
    }

    Widget volume(String label, double current, ValueChanged<double> change) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label ${(100 * current).round()}%'),
            Slider(
              value: current,
              onChanged: _audio.muted ? null : change,
              onChangeEnd: (_) => _saveAudio(),
              semanticFormatterCallback: (value) => '${(100 * value).round()}%',
            ),
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Silenzia tutto'),
          value: _audio.muted,
          onChanged: (value) {
            update(() => _audio.muted = value);
            _saveAudio();
          },
        ),
        volume(
          'Musica',
          _audio.musicVolume,
          (value) => update(() => _audio.musicVolume = value),
        ),
        volume(
          'Effetti sonori',
          _audio.effectsVolume,
          (value) => update(() => _audio.effectsVolume = value),
        ),
        TextButton.icon(
          onPressed: _audio.muted || _audio.effectsVolume == 0
              ? null
              : () => _audio.playEffect('clash'),
          icon: const Icon(Icons.volume_up_outlined),
          label: const Text('Prova effetti'),
        ),
        TextButton(
          onPressed: () {
            update(() {
              _audio.musicVolume = OculumLiteAudio.defaultMusicVolume;
              _audio.effectsVolume = OculumLiteAudio.defaultEffectsVolume;
            });
            _saveAudio();
          },
          child: const Text('Ripristina volumi predefiniti'),
        ),
      ],
    );
  }

  Widget _action(String label, VoidCallback? tap) => FilledButton.tonal(
    style: FilledButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
    onPressed: tap,
    child: Text(label),
  );

  Widget _scrollAction(LiteRun run, int index) {
    final scroll = run.equippedScrolls[index];
    final copies = run.scrolls[scroll.index];
    final isArt =
        run.hero == LiteHero.duplicatore &&
        (index > 0 || copies == 0 && run.learnedScrolls.contains(scroll));
    final available = isArt ? run.learnedScrolls.contains(scroll) : copies > 0;
    return Tooltip(
      message: '${scroll.label} · ${scroll.cost} Oculum',
      child: _action(
        '${['Q', '1', '2', '3'][index]} · ${isArt && available ? 'Art' : copies}',
        available ? () => run.castScroll(index, _targetFor(run)) : null,
      ),
    );
  }

  Widget _weaponIcon(LiteWeapon weapon, {double size = 46}) =>
      OculumLiteWeaponIcon(weapon: weapon, size: size);

  Widget _movementPad() => Semantics(
    label: 'Movimento',
    child: GestureDetector(
      onPanDown: (event) => _movePad(event.localPosition),
      onPanUpdate: (event) => _movePad(event.localPosition),
      onPanEnd: (_) => _touchDirection = const Point(0, 0),
      onPanCancel: () => _touchDirection = const Point(0, 0),
      onTapUp: (_) => _touchDirection = const Point(0, 0),
      child: const SizedBox.square(
        dimension: 78,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xd0453543),
          ),
          child: Icon(Icons.open_with),
        ),
      ),
    ),
  );

  void _movePad(Offset offset) {
    final delta = offset - const Offset(39, 39);
    _touchDirection = delta.distance < 7
        ? const Point(0, 0)
        : Point(delta.dx / delta.distance, delta.dy / delta.distance);
  }
}
