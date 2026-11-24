import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'oculum_lite_run.dart';

class OculumLiteAudio {
  static const _prefix = 'oculum/lite/audio/';
  AudioPlayer? _music;
  final _effects = <String, AudioPlayer>{};
  Future<void> _transition = Future.value();
  String? _wantedTrack;
  String? _loadedTrack;
  bool _closed = false;
  bool muted = false;
  double musicVolume = .55;
  double effectsVolume = .72;
  LiteRun? _run;
  LiteCombatImpact? _lastImpact;
  double _lastEffectTime = -1;

  void update(LiteRun? run, {required bool playing}) {
    if (!identical(run, _run)) {
      _run = run;
      _lastImpact = null;
      _lastEffectTime = -1;
    }
    final wanted = !playing || muted || musicVolume == 0 || run == null
        ? null
        : _track(run);
    if (wanted == _wantedTrack) return;
    _wantedTrack = wanted;
    _transition = _transition.then((_) => _applyTrack(wanted));
  }

  static String _track(LiteRun run) {
    for (final enemy in run.enemies) {
      if (enemy.hp <= 0) continue;
      if (enemy.kind.elite) return 'elite';
      switch (enemy.kind) {
        case LiteEnemyKind.luce:
          return 'luce';
        case LiteEnemyKind.ombra:
          return 'ombra';
        case LiteEnemyKind.veyrth:
          return 'veyrth';
        default:
          break;
      }
    }
    return switch (run.biome) {
      LiteBiome.campo => 'campo',
      LiteBiome.foresta => 'foresta',
      LiteBiome.dungeon => 'sotterraneo',
      LiteBiome.postea => 'postea',
      LiteBiome.deserto => 'sotterraneo',
      LiteBiome.orea => 'foresta',
    };
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
      await player.play(AssetSource('$_prefix$track.wav'));
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
  }

  void combatSounds(LiteRun run) {
    String? sound;
    var highest = 0;
    final impacts = run.combatImpacts;
    final previous = _lastImpact;
    final hasPrevious = previous != null && impacts.contains(previous);
    var afterPrevious = !hasPrevious;
    for (final impact in impacts) {
      if (identical(impact, previous)) {
        afterPrevious = true;
      } else if (afterPrevious && run.time - impact.time <= .1) {
        final (name, priority) = switch (impact.target) {
          LiteImpactTarget.clash => ('clash', 5),
          LiteImpactTarget.verdict => ('sentenza', 4),
          LiteImpactTarget.fissure => ('colpo', 2),
          LiteImpactTarget.explosion => ('clash', 4),
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

  void playEffect(String name) {
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

  void dispose() {
    _closed = true;
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
