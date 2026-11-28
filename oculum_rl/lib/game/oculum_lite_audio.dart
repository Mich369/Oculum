import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/oculum_save_profile.dart';
import 'oculum_lite_alert_dialogue.dart';
import 'oculum_lite_run.dart';

enum _AlertAudioPriority { dialogue, spotting, boss }

class LiteAdaptiveSoundtrack {
  final _banditIntroductions = <String>{};
  int? _seed;
  double _time = 0;

  ({String track, bool banditIntro}) cue(LiteRun run) {
    if (run.seed != _seed || run.time < _time) {
      reset();
      _seed = run.seed;
    }
    _time = run.time;

    var combat = false;
    var banditIntroReady = false;
    String? bossTrack;
    var bossPriority = 0;
    for (final enemy in run.enemies) {
      if (!run.enemyEngagedForMusic(enemy)) continue;
      combat = true;
      final (track, priority) = switch (enemy.kind) {
        LiteEnemyKind.veyrth => ('veyrth', 4),
        LiteEnemyKind.granScostumato
            when enemy.errato == null &&
                (!run.inBanditEscape || enemy.banditWarden) =>
          ('boss-banda', 3),
        LiteEnemyKind.luce => ('luce', 2),
        LiteEnemyKind.ombra => ('ombra', 2),
        _ when enemy.kind.elite || enemy.kind.boss => ('elite', 1),
        _ => (null, 0),
      };
      if (track == 'boss-banda' && run.banditBossIntroReady(enemy)) {
        banditIntroReady = true;
      }
      if (priority > bossPriority) {
        bossTrack = track;
        bossPriority = priority;
      }
    }

    final biome = (run.goblinCamp || run.inBanditEscape)
        ? LiteBiome.campo
        : switch (run.thirdEncounter?.region) {
            LiteThirdRegion.oblio ||
            LiteThirdRegion.sommerso => LiteBiome.dungeon,
            LiteThirdRegion.nuvole => LiteBiome.postea,
            null when run.realm == LiteRealm.postea => LiteBiome.postea,
            _ => run.biome,
          };
    return (
      track: bossTrack ?? '${combat ? 'scontro' : 'quiete'}-${biome.name}',
      banditIntro:
          bossTrack == 'boss-banda' &&
          banditIntroReady &&
          _banditIntroductions.add(run.inputArena),
    );
  }

  void reset() {
    _seed = null;
    _time = 0;
    _banditIntroductions.clear();
  }
}

class OculumLiteAudio {
  static const _prefix = 'oculum/lite/audio/';
  static const defaultMusicVolume = .35;
  static const defaultEffectsVolume = .50;
  AudioPlayer? _music;
  AudioPlayer? _merchantVoice;
  AudioPlayer? _alertVoice;
  AudioPlayer? _shadowRay;
  Future<void> _rayTransition = Future.value();
  bool _rayWanted = false;
  final _effects = <String, AudioPlayer>{};
  Future<void> _transition = Future.value();
  Future<void> _voiceTransition = Future.value();
  int _voiceRequest = 0;
  Future<void> _alertTransition = Future.value();
  int _alertRequest = 0;
  bool _alertPreparing = false;
  _AlertAudioPriority? _alertPriority;
  final _soundtrack = LiteAdaptiveSoundtrack();
  (int, String)? _audioArena;
  Future<Set<String>>? _bundledAssets;
  String? _wantedTrack;
  String? _loadedTrack;
  bool _closed = false;
  bool muted = false;
  double musicVolume = defaultMusicVolume;
  double effectsVolume = defaultEffectsVolume;
  LiteRun? _run;
  LiteCombatImpact? _lastImpact;
  double _lastEffectTime = -1;
  (int, int, double, LiteBurstKind)? _lastBurst;
  (int, String, int)? _spottingScope;
  final _lastSpotting = <LiteEnemyKind, double>{};
  double _spottingTime = 0;

  static String preferenceKey(String name) =>
      oculumProfiledStorageKey('oculum_lite_audio_$name');

  void restorePreferences(SharedPreferences? preferences) {
    double read(String name, double fallback) {
      final value = preferences?.get(preferenceKey(name));
      return value is num && value.isFinite
          ? value.toDouble().clamp(0.0, 1.0)
          : fallback;
    }

    musicVolume = read('musica', defaultMusicVolume);
    effectsVolume = read('effetti', defaultEffectsVolume);
    muted = preferences?.get(preferenceKey('muto')) == true;
    applyVolumes();
  }

  void update(LiteRun? run, {required bool playing}) {
    if (!identical(run, _run)) {
      _run = run;
      _lastImpact = null;
      _lastEffectTime = -1;
    }
    _updateRay(playing && run?.shadowRays.isNotEmpty == true);
    _useAudioArena(run == null ? null : (run.seed, run.inputArena));
    if (!playing) _stopEncounterClip();
    if (run == null) _soundtrack.reset();
    final cue = playing && run != null ? _soundtrack.cue(run) : null;
    if (cue?.banditIntro == true) {
      _playAlertClip(
        () async => 'boss-gran-scostumato.mp3',
        _AlertAudioPriority.boss,
      );
    }
    final wanted = muted || musicVolume == 0 ? null : cue?.track;
    if (wanted == _wantedTrack) return;
    _wantedTrack = wanted;
    _transition = _transition.then((_) => _applyTrack(wanted));
  }

  void _useAudioArena((int, String)? arena) {
    if (arena == _audioArena) return;
    _audioArena = arena;
    _stopEncounterClip();
  }

  void _stopEncounterClip() {
    if (_alertPriority == _AlertAudioPriority.spotting ||
        _alertPriority == _AlertAudioPriority.boss) {
      _stopAlertChannel();
    }
  }

  Future<void> _applyTrack(String? track) => _try(() async {
    if (_closed || track != _wantedTrack) return;
    if (track == null) {
      await _music?.pause();
      return;
    }
    final player = _music ??= AudioPlayer();
    await player.setVolume(musicVolume);
    if (track != _wantedTrack || _closed) return;
    if (_loadedTrack == track) {
      await player.resume();
    } else {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      if (track != _wantedTrack || _closed) return;
      await player.play(AssetSource('$_prefix$track.wav'), volume: musicVolume);
      _loadedTrack = track;
    }
  });

  void applyVolumes() {
    final player = _music;
    if (player != null) {
      unawaited(_try(() => player.setVolume(muted ? 0 : musicVolume)));
    }
    for (final effect in _effects.values) {
      unawaited(_try(() => effect.setVolume(muted ? 0 : effectsVolume)));
    }
    final ray = _shadowRay;
    if (ray != null) {
      unawaited(_try(() => ray.setVolume(muted ? 0 : effectsVolume * .54)));
    }
    final voice = _merchantVoice;
    if (voice != null) {
      unawaited(_try(() => voice.setVolume(muted ? 0 : effectsVolume)));
    }
    final alert = _alertVoice;
    if (muted || effectsVolume == 0) {
      _stopAlertChannel();
    } else if (alert != null) {
      unawaited(_try(() => alert.setVolume(effectsVolume * .86)));
    }
  }

  void _updateRay(bool active) {
    final wanted = active && !muted && effectsVolume > 0 && !_closed;
    if (wanted == _rayWanted) return;
    _rayWanted = wanted;
    _rayTransition = _rayTransition.then(
      (_) => _try(() async {
        if (_closed || wanted != _rayWanted) return;
        if (!wanted) {
          await _shadowRay?.stop();
          return;
        }
        final player = _shadowRay ??= AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        if (_closed || !_rayWanted) return;
        await player.play(
          AssetSource('${_prefix}filo-ombra.wav'),
          volume: effectsVolume * .54,
        );
      }),
    );
  }

  void combatSounds(LiteRun run) {
    _updateRay(run.shadowRays.isNotEmpty);
    String? sound;
    var highest = 0;
    final impacts = run.combatImpacts;
    final previous = _lastImpact;
    final hasPrevious = previous != null && impacts.contains(previous);
    var afterPrevious = !hasPrevious;
    for (final impact in impacts) {
      if (identical(impact, previous)) {
        afterPrevious = true;
      } else if (afterPrevious &&
          !impact.silent &&
          run.time - impact.time <= .1) {
        final (name, priority) = switch (impact.target) {
          LiteImpactTarget.clash => ('clash', 5),
          LiteImpactTarget.verdict => ('sentenza', 4),
          LiteImpactTarget.fissure => ('colpo', 2),
          LiteImpactTarget.explosion => ('clash', 4),
          LiteImpactTarget.emberRebirth => ('sentenza', 4),
          LiteImpactTarget.artCast => ('colpo', 2),
          LiteImpactTarget.chamberStrike => ('sentenza', 4),
          LiteImpactTarget.bunnysHeal => ('', 0),
          LiteImpactTarget.materiaDodge => ('scatto-arcano', 2),
          LiteImpactTarget.bestiaryCast when impact.life == 1 => (
            'sentenza',
            2,
          ),
          LiteImpactTarget.bestiaryCast => ('scatto-inchiostro', 2),
          LiteImpactTarget.frontierCast when impact.life == 5 => ('scudo', 2),
          LiteImpactTarget.frontierCast => ('scatto-arcano', 2),
          LiteImpactTarget.player when impact.life > 0 => ('ferita', 3),
          _ when impact.shield > 0 => ('scudo', 2),
          _ when impact.life > 0 => ('colpo', 1),
          _ => ('', 0),
        };
        if (priority > highest) {
          sound = name;
          highest = priority;
        }
      }
    }
    if (impacts.isNotEmpty) _lastImpact = impacts.last;
    if (sound != null && (highest >= 4 || run.time - _lastEffectTime >= .075)) {
      _lastEffectTime = run.time;
      playEffect(sound);
    }
  }

  void burstSound(LiteRun run, int fighterId) {
    final trace = run.burstTraceFor(fighterId);
    // World time accelerates with the floor, but co-op frames arrive on real time.
    if (trace == null || run.time - trace.startedAt > .24 * run.arenaSpeed) {
      return;
    }
    final key = (run.seed, fighterId, trace.startedAt, trace.kind);
    if (_lastBurst == key) return;
    _lastBurst = key;
    switch (trace.kind) {
      case LiteBurstKind.dash:
        playEffect('scatto-inchiostro');
      case LiteBurstKind.phase || LiteBurstKind.open || LiteBurstKind.veil:
        playEffect('scatto-arcano');
      case LiteBurstKind.clash:
        break;
    }
  }

  void banditSpottingSound(LiteRun run, int fighterId) {
    if (run.finished) return;
    final arena = run.inputArena;
    _useAudioArena((run.seed, arena));
    final scope = (run.seed, arena, fighterId);
    if (_spottingScope != scope || run.time < _spottingTime) {
      _spottingScope = scope;
      _lastSpotting.clear();
    }
    _spottingTime = run.time;
    for (final impact in run.combatImpacts) {
      if (impact.target != LiteImpactTarget.banditSpotted ||
          impact.subjectId != fighterId ||
          run.time - impact.time > .36 * run.arenaSpeed) {
        continue;
      }
      final kind = impact.enemyKind;
      final file = switch (kind) {
        LiteEnemyKind.scostubandito => 'avvistamento-scostubandito',
        LiteEnemyKind.granScostumato => 'avvistamento-gran-scostumato',
        _ => null,
      };
      if (kind == null ||
          file == null ||
          impact.time <= (_lastSpotting[kind] ?? -1)) {
        continue;
      }
      _lastSpotting[kind] = impact.time;
      _playAlertClip(() async => '$file.mp3', _AlertAudioPriority.spotting);
    }
  }

  void playEffect(String name) => _playEffect(name);

  void _playEffect(String name) {
    if (_closed || muted || effectsVolume == 0) return;
    unawaited(
      _try(() async {
        final player = _effects.putIfAbsent(name, AudioPlayer.new);
        await player.stop();
        if (_closed || muted) return;
        await player.play(
          AssetSource('$_prefix$name.wav'),
          volume: effectsVolume,
        );
      }),
    );
  }

  bool get alertSpeaking =>
      !_closed &&
      !muted &&
      effectsVolume > 0 &&
      (_alertPreparing || _alertVoice?.state == PlayerState.playing);

  void playAlert(LiteAlertDialogue line) => _playAlertClip(
    () async => '${await _alertAsset(line)}.wav',
    _AlertAudioPriority.dialogue,
  );

  void _playAlertClip(
    Future<String> Function() resolveAsset,
    _AlertAudioPriority priority,
  ) {
    if (_closed ||
        muted ||
        effectsVolume == 0 ||
        alertSpeaking && (_alertPriority?.index ?? -1) > priority.index) {
      return;
    }
    final request = ++_alertRequest;
    _alertPriority = priority;
    _alertPreparing = true;
    _alertTransition = _alertTransition.then((_) async {
      try {
        await _try(() async {
          if (!_acceptAlert(request)) return;
          final asset = await resolveAsset();
          if (!_acceptAlert(request)) return;
          final player = _alertVoice ??= AudioPlayer();
          await player.stop();
          if (!_acceptAlert(request)) return;
          await player.play(
            AssetSource('$_prefix$asset'),
            volume: effectsVolume * .86,
          );
        });
      } finally {
        if (request == _alertRequest) _alertPreparing = false;
      }
    });
  }

  bool _acceptAlert(int request) =>
      !_closed && !muted && effectsVolume > 0 && request == _alertRequest;

  Future<String> _alertAsset(LiteAlertDialogue line) async {
    final key = line.spokenKey;
    if (key == null) return line.sound.asset;
    final voice = 'alert-lines/$key';
    try {
      final assets = await (_bundledAssets ??=
          AssetManifest.loadFromAssetBundle(rootBundle)
              .then((manifest) => manifest.listAssets().toSet()));
      if (assets.contains('assets/$_prefix$voice.wav')) return voice;
    } catch (_) {
      // A build without the offline speech bank still has every sound motif.
    }
    return line.sound.asset;
  }

  void stopAlert() {
    if (_alertPriority == _AlertAudioPriority.dialogue) _stopAlertChannel();
  }

  void _stopAlertChannel() {
    _alertRequest++;
    _alertPriority = null;
    _alertPreparing = false;
    if (_alertVoice != null) {
      _alertTransition = _alertTransition.then(
        (_) => _try(() async => _alertVoice?.stop()),
      );
    }
  }

  void playMerchantGreeting(String name) {
    final request = ++_voiceRequest;
    if (_closed || muted || effectsVolume == 0) return;
    _voiceTransition = _voiceTransition.then(
      (_) => _try(() async {
        if (_closed || request != _voiceRequest) return;
        final voice = _merchantVoice ??= AudioPlayer();
        await voice.stop();
        if (_closed ||
            request != _voiceRequest ||
            muted ||
            effectsVolume == 0) {
          return;
        }
        await voice.play(
          AssetSource('$_prefix$name.wav'),
          volume: effectsVolume,
        );
      }),
    );
  }

  void stopMerchantGreeting() {
    _voiceRequest++;
    _voiceTransition = _voiceTransition.then(
      (_) => _try(() async => _merchantVoice?.stop()),
    );
  }

  void dispose() {
    _closed = true;
    unawaited(
      _alertTransition.then((_) => _try(() async => _alertVoice?.dispose())),
    );
    unawaited(
      _rayTransition.then(
        (_) => _try(() async {
          await _shadowRay?.dispose();
        }),
      ),
    );
    unawaited(
      _voiceTransition.then(
        (_) => _try(() async {
          await _merchantVoice?.dispose();
        }),
      ),
    );
    unawaited(
      _transition.then(
        (_) => _try(() async {
          await _music?.dispose();
          for (final effect in _effects.values) {
            await effect.dispose();
          }
        }),
      ),
    );
  }

  static Future<void> _try(Future<void> Function() operation) async {
    try {
      await operation();
    } on MissingPluginException {
      // The combat loop remains usable on hosts without an audio output.
    } on Exception {
      // A missing, suspended or busy output must never stop the run.
    } on StateError {
      // The page can close while a platform player is still preparing.
    }
  }
}
