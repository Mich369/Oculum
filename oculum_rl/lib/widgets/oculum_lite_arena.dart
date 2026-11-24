import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../game/oculum_lite_run.dart';

import 'oculum_lite_appearance.dart';

export 'oculum_lite_appearance.dart';

part 'oculum_lite_creator_paint.dart';
part 'oculum_lite_combat_paint.dart';
part 'oculum_lite_actor_paint.dart';
part 'oculum_lite_weapon_paint.dart';

class OculumLiteBlockControl extends StatelessWidget {
  const OculumLiteBlockControl({
    super.key,
    required this.resistance,
    required this.capacity,
    required this.active,
    required this.onHeld,
  });

  final double resistance;
  final int capacity;
  final bool active;
  final ValueChanged<bool> onHeld;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Tieni premuto F o il pulsante. Ogni oggetto curativo restituisce 10 Resistenza.',
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onHeld(true),
      onPointerUp: (_) => onHeld(false),
      onPointerCancel: (_) => onHeld(false),
      child: Chip(
        avatar: Icon(active ? Icons.shield : Icons.shield_outlined, size: 17),
        backgroundColor: active ? const Color(0xff284d5c) : null,
        label: Text('F · Blocco ${resistance.ceil()}/$capacity'),
      ),
    ),
  );
}

/// Live terrain and actors for Oculum RL. Its camera also converts pointer
/// positions to the exact same world coordinates used by the combat engine.
class OculumLiteArena extends StatefulWidget {
  const OculumLiteArena({
    super.key,
    required this.run,
    this.appearance,
    this.guestAppearances = const {},
    this.view,
    this.onAim,
    this.onAttack,
    this.onTalent,
    this.focusAccount,
    this.animationLead = 0,
  });

  final LiteRun run;
  final OculumLiteAppearance? appearance;
  final Map<String, OculumLiteAppearance> guestAppearances;
  final Listenable? view;
  final ValueChanged<math.Point<double>>? onAim;
  final ValueChanged<math.Point<double>>? onAttack;
  final ValueChanged<math.Point<double>>? onTalent;
  final String? focusAccount;
  final double animationLead;

  static const coverArt = ResizeImage(
    AssetImage('assets/oculum/lite/ripari-inchiostro.png'),
    width: 768,
    policy: ResizeImagePolicy.fit,
  );
  static const evasorFrames = AssetImage(
    'assets/oculum/lite/evasore-sprite.png',
  );
  static const duplicatorFrames = AssetImage(
    'assets/oculum/lite/duplicatore-sprite.png',
  );
  static const duplicatorWeaponPoses = AssetImage(
    'assets/oculum/lite/clonatore-armi.png',
  );
  static const femininePoses = AssetImage(
    'assets/oculum/lite/clonatrice-armi.png',
  );
  static const feminineHeads = AssetImage(
    'assets/oculum/lite/clonatrice-volti.png',
  );
  static const ashleyFrames = AssetImage(
    'assets/oculum/lite/ashley-sprite.png',
  );
  static const duplicatorHeads = AssetImage(
    'assets/oculum/lite/clonatore-volti.png',
  );
  static const monsterArt = AssetImage(
    'assets/oculum/lite/mostri-inchiostro.png',
  );
  static const posteaMonsters = AssetImage(
    'assets/oculum/lite/mostri-postea.png',
  );
  static const groundArt = AssetImage(
    'assets/oculum/lite/arene-inchiostro.png',
  );
  static const propArt = AssetImage(
    'assets/oculum/lite/oggetti-inchiostro.png',
  );
  static AssetImage? weaponArt(LiteWeapon weapon) =>
      weapon.isBossLoot || weapon == LiteWeapon.fucileScostubandito
      ? null
      : AssetImage('assets/oculum/lite/arma-${weapon.name}.png');
  static const lootArt = AssetImage('assets/oculum/lite/bottino-ink.png');
  static const infernalArt = AssetImage('assets/oculum/lite/infernali-ink.png');
  static const infernoGround = AssetImage('assets/oculum/lite/inferno.jpg');
  static const caramellaGround = AssetImage(
    'assets/oculum/lite/realm-caramella.jpg',
  );
  static const solarArt = AssetImage('assets/oculum/lite/solari-ink.png');
  static const solarGround = AssetImage(
    'assets/oculum/lite/dungeon-solare.jpg',
  );
  static const faunaArt = AssetImage('assets/oculum/lite/fauna-ink.png');
  static const mechanicalChickenArts = {
    LiteInkFinish.canonica: AssetImage(
      'assets/oculum/lite/pollo-meccanico-ink.png',
    ),
    LiteInkFinish.cremisi: AssetImage(
      'assets/oculum/lite/pollo-meccanico-cremisi.png',
    ),
    LiteInkFinish.patina: AssetImage(
      'assets/oculum/lite/pollo-meccanico-patina.png',
    ),
  };
  static const restGround = AssetImage('assets/oculum/lite/sala-riposo.jpg');
  static const hubArt = AssetImage('assets/oculum/lite/sala-npc.png');
  static const nightActors = AssetImage(
    'assets/oculum/lite/lunari-e-forme.png',
  );
  static const newActors = AssetImage(
    'assets/oculum/lite/curatore-e-combattenti.png',
  );
  static const desertoGround = AssetImage(
    'assets/oculum/lite/arena-deserto.jpg',
  );
  static const oreaGround = AssetImage('assets/oculum/lite/arena-orea.jpg');

  static const finalBossArt = AssetImage(
    'assets/oculum/lite/veyrth-inchiostro.png',
  );

  @override
  State<OculumLiteArena> createState() => _OculumLiteArenaState();
}

class _OculumLiteArenaState extends State<OculumLiteArena> {
  ui.Picture? _floor;
  (int, int, LiteBiome, bool, bool, LiteRealm?, int)? _floorKey;
  ImageStream? _coverStream;
  ImageInfo? _cover;
  ImageStream? _heroStream;
  ImageInfo? _frames;
  ImageStream? _monsterStream;
  ImageInfo? _monsters;
  ImageStream? _posteaMonsterStream;
  ImageInfo? _posteaMonsters;
  ImageStream? _groundStream;
  ImageInfo? _ground;
  ImageStream? _bossStream;
  ImageInfo? _boss;
  ImageStream? _dupPoseStream;
  ImageInfo? _dupPoses;
  ImageStream? _femininePoseStream;
  ImageInfo? _femininePoses;
  ImageStream? _feminineHeadStream;
  ImageInfo? _feminineHeads;
  ImageStream? _propStream;
  ImageInfo? _props;
  ImageStream? _ashleyStream;
  ImageInfo? _ashley;
  ImageStream? _headStream;
  ImageInfo? _heads;
  final _extraStreams = <(ImageStream, ImageStreamListener)>[];
  final _extraImages = <AssetImage, ImageInfo>{};
  final _weaponStreams = <LiteWeapon, (ImageStream, ImageStreamListener)>{};
  final _weapons = <LiteWeapon, ui.Image>{};
  final _weaponInfo = <LiteWeapon, ImageInfo>{};
  late final _coverListener = ImageStreamListener(
    (frame, synchronous) => _receiveArt(frame, synchronous, cover: true),
    onError: (_, _) {},
  );
  late final _heroListener = ImageStreamListener(
    (frame, synchronous) => _receiveArt(frame, synchronous, cover: false),
    onError: (_, _) {},
  );
  late final _monsterListener = ImageStreamListener((frame, synchronous) {
    _applyImage(frame, synchronous, () {
      _monsters?.dispose();
      _monsters = frame;
    });
  }, onError: (_, _) {});
  late final _posteaMonsterListener = ImageStreamListener((frame, synchronous) {
    _applyImage(frame, synchronous, () {
      _posteaMonsters?.dispose();
      _posteaMonsters = frame;
    });
  }, onError: (_, _) {});
  late final _groundListener = ImageStreamListener((frame, synchronous) {
    _applyImage(frame, synchronous, () {
      _ground?.dispose();
      _ground = frame;
      _floorKey = null;
    });
  }, onError: (_, _) {});
  late final _bossListener = ImageStreamListener((frame, synchronous) {
    _applyImage(frame, synchronous, () {
      _boss?.dispose();
      _boss = frame;
    });
  }, onError: (_, _) {});
  late final _femininePoseListener = ImageStreamListener((frame, synchronous) {
    _applyImage(frame, synchronous, () {
      _femininePoses?.dispose();
      _femininePoses = frame;
    });
  }, onError: (_, _) {});
  late final _feminineHeadListener = ImageStreamListener((frame, synchronous) {
    _applyImage(frame, synchronous, () {
      _feminineHeads?.dispose();
      _feminineHeads = frame;
    });
  }, onError: (_, _) {});
  late final _ashleyListener = ImageStreamListener((frame, synchronous) {
    _applyImage(frame, synchronous, () {
      _ashley?.dispose();
      _ashley = frame;
    });
  }, onError: (_, _) {});
  late final _propListener = ImageStreamListener((frame, synchronous) {
    _applyImage(frame, synchronous, () {
      _props?.dispose();
      _props = frame;
    });
  }, onError: (_, _) {});
  late final _dupPoseListener = ImageStreamListener((frame, synchronous) {
    _applyImage(frame, synchronous, () {
      _dupPoses?.dispose();
      _dupPoses = frame;
    });
  }, onError: (_, _) {});
  late final _headListener = ImageStreamListener((frame, synchronous) {
    _applyImage(frame, synchronous, () {
      _heads?.dispose();
      _heads = frame;
    });
  }, onError: (_, _) {});

  void _applyImage(ImageInfo frame, bool synchronous, VoidCallback apply) {
    if (!mounted) {
      frame.dispose();
    } else if (synchronous) {
      apply();
    } else {
      setState(apply);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = OculumLiteArena.coverArt.resolve(
      createLocalImageConfiguration(context),
    );
    if (_coverStream?.key != stream.key) {
      _coverStream?.removeListener(_coverListener);
      _coverStream = stream..addListener(_coverListener);
    }
    _resolveHero();
    final config = createLocalImageConfiguration(context);
    _monsterStream ??= (OculumLiteArena.monsterArt.resolve(config)
      ..addListener(_monsterListener));
    _posteaMonsterStream ??= (OculumLiteArena.posteaMonsters.resolve(config)
      ..addListener(_posteaMonsterListener));
    _dupPoseStream ??= (OculumLiteArena.duplicatorWeaponPoses.resolve(config)
      ..addListener(_dupPoseListener));
    _headStream ??= (OculumLiteArena.duplicatorHeads.resolve(config)
      ..addListener(_headListener));
    _resolveFeminineArt(config);
    _resolveAshleys(config);
    _propStream ??= (OculumLiteArena.propArt.resolve(config)
      ..addListener(_propListener));
    _groundStream?.removeListener(_groundListener);
    _groundStream = OculumLiteArena.groundArt.resolve(config)
      ..addListener(_groundListener);
    _bossStream?.removeListener(_bossListener);
    _bossStream = OculumLiteArena.finalBossArt.resolve(config)
      ..addListener(_bossListener);
    if (_extraStreams.isEmpty) {
      for (final art in [
        OculumLiteArena.newActors,
        OculumLiteArena.nightActors,
        OculumLiteArena.lootArt,
        OculumLiteArena.hubArt,
        OculumLiteArena.restGround,
        OculumLiteArena.faunaArt,
        if (widget.run.hero == LiteHero.polloMeccanico ||
            widget.run.coopFighters.any(
              (fighter) => fighter.hero == LiteHero.polloMeccanico,
            ))
          ...OculumLiteArena.mechanicalChickenArts.values,
        OculumLiteArena.solarArt,
        OculumLiteArena.solarGround,
        OculumLiteArena.infernalArt,
        OculumLiteArena.infernoGround,
        OculumLiteArena.caramellaGround,
        OculumLiteArena.desertoGround,
        OculumLiteArena.oreaGround,
      ]) {
        final stream = art.resolve(config);
        final listener = ImageStreamListener((frame, synchronous) {
          _applyImage(frame, synchronous, () {
            _extraImages[art]?.dispose();
            _extraImages[art] = frame;
            if (art == OculumLiteArena.desertoGround ||
                art == OculumLiteArena.infernoGround ||
                art == OculumLiteArena.caramellaGround ||
                art == OculumLiteArena.solarGround ||
                art == OculumLiteArena.restGround ||
                art == OculumLiteArena.oreaGround)
              _floorKey = null;
          });
        });
        _extraStreams.add((stream, listener));
        stream.addListener(listener);
      }
    }
    if (_weaponStreams.isEmpty) {
      for (final weapon in LiteWeapon.values) {
        final art = OculumLiteArena.weaponArt(weapon);
        if (art == null) continue;
        final listener = ImageStreamListener((frame, synchronous) {
          _applyImage(frame, synchronous, () {
            _weaponInfo[weapon]?.dispose();
            _weaponInfo[weapon] = frame;
            _weapons[weapon] = frame.image;
          });
        }, onError: (_, _) {});
        final stream = art.resolve(config);
        _weaponStreams[weapon] = (stream, listener);
        stream.addListener(listener);
      }
    }
  }

  @override
  void didUpdateWidget(OculumLiteArena oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.run.hero != widget.run.hero) _resolveHero();
    _resolveFeminineArt(createLocalImageConfiguration(context));
    _resolveAshleys(createLocalImageConfiguration(context));
  }

  void _resolveAshleys(ImageConfiguration config) {
    if (!widget.run.coopFighters.any(
      (actor) => actor.hero == LiteHero.ashley,
    )) {
      return;
    }
    _ashleyStream ??= (OculumLiteArena.ashleyFrames.resolve(config)
      ..addListener(_ashleyListener));
  }

  void _resolveFeminineArt(ImageConfiguration config) {
    if (widget.appearance?.usesFeminineAtlas != true &&
        !widget.guestAppearances.values.any((look) => look.usesFeminineAtlas)) {
      return;
    }
    _femininePoseStream ??= (OculumLiteArena.femininePoses.resolve(config)
      ..addListener(_femininePoseListener));
    _feminineHeadStream ??= (OculumLiteArena.feminineHeads.resolve(config)
      ..addListener(_feminineHeadListener));
  }

  void _resolveHero() {
    final provider = switch (widget.run.hero) {
      LiteHero.evasore => OculumLiteArena.evasorFrames,
      LiteHero.duplicatore ||
      LiteHero.scostubandito => OculumLiteArena.duplicatorFrames,
      LiteHero.ashley => OculumLiteArena.ashleyFrames,
      _ => OculumLiteArena.duplicatorFrames,
    };
    final stream = provider.resolve(createLocalImageConfiguration(context));
    if (_heroStream?.key == stream.key) return;
    _heroStream?.removeListener(_heroListener);
    _frames?.dispose();
    _frames = null;
    _heroStream = stream..addListener(_heroListener);
  }

  void _receiveArt(ImageInfo frame, bool synchronous, {required bool cover}) {
    if (!mounted) {
      frame.dispose();
      return;
    }
    void replaceArt() {
      if (cover) {
        _cover?.dispose();
        _cover = frame;
      } else {
        _frames?.dispose();
        _frames = frame;
      }
    }

    if (synchronous) {
      replaceArt();
    } else {
      setState(replaceArt);
    }
  }

  ui.Picture _terrain(LiteRun run) {
    final key = (
      run.seed,
      run.stage,
      run.goblinCamp
          ? LiteBiome.campo
          : run.realm == LiteRealm.postea
          ? LiteBiome.postea
          : run.biome,
      run.restHub,
      run.inSolarDungeon,
      run.realm,
      run.actRoom,
    );
    if (_floorKey != key) {
      _floor?.dispose();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      _paintFloor(
        canvas,
        run.width.toDouble(),
        run.height.toDouble(),
        (key.$1, key.$2, key.$3),
        _ground?.image,
        key.$4
            ? _extraImages[OculumLiteArena.restGround]?.image
            : key.$5
            ? _extraImages[OculumLiteArena.solarGround]?.image
            : key.$6 == LiteRealm.inferno
            ? _extraImages[OculumLiteArena.infernoGround]?.image
            : key.$6 == LiteRealm.caramella
            ? _extraImages[OculumLiteArena.caramellaGround]?.image
            : switch (key.$3) {
                LiteBiome.deserto =>
                  _extraImages[OculumLiteArena.desertoGround]?.image,
                LiteBiome.orea =>
                  _extraImages[OculumLiteArena.oreaGround]?.image,
                _ => null,
              },
      );
      _floor = recorder.endRecording();
      _floorKey = key;
    }
    return _floor!;
  }

  @override
  void dispose() {
    _floor?.dispose();
    _coverStream?.removeListener(_coverListener);
    _cover?.dispose();
    _heroStream?.removeListener(_heroListener);
    _frames?.dispose();
    _monsterStream?.removeListener(_monsterListener);
    _monsters?.dispose();
    _posteaMonsterStream?.removeListener(_posteaMonsterListener);
    _posteaMonsters?.dispose();
    _groundStream?.removeListener(_groundListener);
    _ground?.dispose();
    _bossStream?.removeListener(_bossListener);
    _boss?.dispose();
    _dupPoseStream?.removeListener(_dupPoseListener);
    _dupPoses?.dispose();
    _femininePoseStream?.removeListener(_femininePoseListener);
    _femininePoses?.dispose();
    _feminineHeadStream?.removeListener(_feminineHeadListener);
    _feminineHeads?.dispose();
    _ashleyStream?.removeListener(_ashleyListener);
    _ashley?.dispose();
    _propStream?.removeListener(_propListener);
    _props?.dispose();
    _headStream?.removeListener(_headListener);
    _heads?.dispose();
    for (final (stream, listener) in _extraStreams) {
      stream.removeListener(listener);
    }
    for (final info in _extraImages.values) {
      info.dispose();
    }
    for (final (stream, listener) in _weaponStreams.values) {
      stream.removeListener(listener);
    }
    for (final info in _weaponInfo.values) {
      info.dispose();
    }
    super.dispose();
  }

  Widget _viewport(BoxConstraints limits) {
    if (!limits.hasBoundedWidth || !limits.hasBoundedHeight) {
      return const SizedBox.shrink();
    }
    final size = limits.biggest;
    if (size.isEmpty) return const SizedBox.shrink();
    final run = widget.run;
    final focus = widget.focusAccount;
    final fighter = focus == null ? null : run.coopFighter(focus);
    math.Point<double> point(Offset offset) => _ArenaCamera(
      size,
      run,
      follow: fighter?.position,
    ).screenToWorld(offset);

    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      onHover: (event) => widget.onAim?.call(point(event.localPosition)),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          final world = point(event.localPosition);
          widget.onAim?.call(world);
          if ((event.buttons & kSecondaryMouseButton) != 0) {
            widget.onTalent?.call(world);
          } else if (event.kind != PointerDeviceKind.mouse ||
              (event.buttons & kPrimaryMouseButton) != 0) {
            widget.onAttack?.call(world);
          }
        },
        onPointerMove: (event) =>
            widget.onAim?.call(point(event.localPosition)),
        child: RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: _ArenaPaint(
              run,
              _terrain,
              widget.appearance ?? oculumLiteDefaultAppearance(run.hero),
              cover: _cover?.image,
              heroFrames: _frames?.image,
              ashleyFrames: _ashley?.image,
              props: _props?.image,
              monsters: _monsters?.image,
              posteaMonsters: _posteaMonsters?.image,
              bossArt: _boss?.image,
              newActors: _extraImages[OculumLiteArena.newActors]?.image,
              nightActors: _extraImages[OculumLiteArena.nightActors]?.image,
              lootArt: _extraImages[OculumLiteArena.lootArt]?.image,
              hubArt: _extraImages[OculumLiteArena.hubArt]?.image,
              faunaArt: _extraImages[OculumLiteArena.faunaArt]?.image,
              mechanicalChickenArt: {
                for (final entry
                    in OculumLiteArena.mechanicalChickenArts.entries)
                  entry.key: _extraImages[entry.value]?.image,
              },
              solarArt: _extraImages[OculumLiteArena.solarArt]?.image,
              infernalArt: _extraImages[OculumLiteArena.infernalArt]?.image,
              duplicatorPoses: _dupPoses?.image,
              duplicatorHeads: _heads?.image,
              femininePoses: _femininePoses?.image,
              feminineHeads: _feminineHeads?.image,
              guestAppearances: widget.guestAppearances,
              weapons: _weapons,
              follow: fighter?.position,
              followedFighterId: fighter?.id,
              animationLead: widget.animationLead,
              repaint: widget.view,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, limits) => _viewport(limits));
}

/// Uses the gameplay renderer so clothing and equipped weapon match the run.
class OculumLiteHeroPreview extends StatefulWidget {
  const OculumLiteHeroPreview({
    super.key,
    required this.hero,
    required this.weapon,
    this.appearance,
    this.showClone = false,
  });

  final LiteHero hero;
  final LiteWeapon weapon;
  final OculumLiteAppearance? appearance;
  final bool showClone;

  @override
  State<OculumLiteHeroPreview> createState() => _OculumLiteHeroPreviewState();
}

class _OculumLiteHeroPreviewState extends State<OculumLiteHeroPreview> {
  ImageStream? _toolStream;
  ImageStream? _figureStream;
  ImageInfo? _tool;
  ImageInfo? _figure;
  ImageStream? _headStream;
  ImageInfo? _head;
  late final _headListener = ImageStreamListener((frame, synchronous) {
    if (!mounted) {
      frame.dispose();
      return;
    }
    void accept() {
      _head?.dispose();
      _head = frame;
    }

    if (synchronous) {
      accept();
    } else {
      setState(accept);
    }
  }, onError: (_, _) {});
  late final _toolListener = ImageStreamListener(
    (frame, synchronous) => _update(frame, synchronous, true),
    onError: (_, _) {},
  );
  late final _figureListener = ImageStreamListener(
    (frame, synchronous) => _update(frame, synchronous, false),
    onError: (_, _) {},
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribe();
  }

  @override
  void didUpdateWidget(OculumLiteHeroPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hero != widget.hero ||
        oldWidget.weapon != widget.weapon ||
        oldWidget.appearance?.inkFinish != widget.appearance?.inkFinish ||
        oldWidget.appearance?.usesFeminineAtlas !=
            widget.appearance?.usesFeminineAtlas) {
      _subscribe();
    }
  }

  void _subscribe() {
    final config = createLocalImageConfiguration(context);
    final feminine = widget.appearance?.usesFeminineAtlas == true;
    if (widget.hero == LiteHero.duplicatore) {
      final heads =
          (feminine
                  ? OculumLiteArena.feminineHeads
                  : OculumLiteArena.duplicatorHeads)
              .resolve(config);
      if (_headStream?.key != heads.key) {
        _headStream?.removeListener(_headListener);
        _head?.dispose();
        _head = null;
        _headStream = heads..addListener(_headListener);
      }
    }
    final tool = OculumLiteArena.weaponArt(widget.weapon)?.resolve(config);
    final body = (switch (widget.hero) {
      LiteHero.evasore => OculumLiteArena.evasorFrames,
      LiteHero.ashley => OculumLiteArena.ashleyFrames,
      LiteHero.scostubandito => OculumLiteArena.monsterArt,
      LiteHero.granScostumato ||
      LiteHero.sentinella ||
      LiteHero.babyForestDemon => OculumLiteArena.monsterArt,
      LiteHero.dronePostea => OculumLiteArena.posteaMonsters,
      LiteHero.curatorePeste ||
      LiteHero.pyrel ||
      LiteHero.lithra ||
      LiteHero.luce ||
      LiteHero.ombra ||
      LiteHero.doppelganger => OculumLiteArena.newActors,
      LiteHero.veyrth => OculumLiteArena.finalBossArt,
      LiteHero.cavaliereLunare ||
      LiteHero.slimeBlu ||
      LiteHero.vampiro ||
      LiteHero.reGoblin => OculumLiteArena.nightActors,
      LiteHero.pollo ||
      LiteHero.raganella ||
      LiteHero.pipistrello => OculumLiteArena.faunaArt,
      LiteHero.polloMeccanico =>
        OculumLiteArena.mechanicalChickenArts[widget.appearance?.inkFinish ??
            LiteInkFinish.canonica]!,
      LiteHero.guardiaSolare ||
      LiteHero.eliteSolare ||
      LiteHero.guardianoSolare ||
      LiteHero.aberrazioneSolare => OculumLiteArena.solarArt,
      LiteHero.demoneMinore ||
      LiteHero.demoneIntermedio ||
      LiteHero.demoneMaggiore ||
      LiteHero.diavolo => OculumLiteArena.infernalArt,
      LiteHero.duplicatore =>
        feminine
            ? OculumLiteArena.femininePoses
            : OculumLiteArena.duplicatorWeaponPoses,
    }).resolve(config);
    if (_toolStream?.key != tool?.key) {
      _toolStream?.removeListener(_toolListener);
      _tool?.dispose();
      _tool = null;
      _toolStream = tool?..addListener(_toolListener);
    }
    if (_figureStream?.key != body.key) {
      _figureStream?.removeListener(_figureListener);
      _figure?.dispose();
      _figure = null;
      _figureStream = body..addListener(_figureListener);
    }
  }

  void _update(ImageInfo frame, bool synchronous, bool tool) {
    if (!mounted) {
      frame.dispose();
      return;
    }
    void accept() {
      if (tool) {
        _tool?.dispose();
        _tool = frame;
      } else {
        _figure?.dispose();
        _figure = frame;
      }
    }

    if (synchronous) {
      accept();
    } else {
      setState(accept);
    }
  }

  @override
  void dispose() {
    _toolStream?.removeListener(_toolListener);
    _figureStream?.removeListener(_figureListener);
    _tool?.dispose();
    _figure?.dispose();
    _headStream?.removeListener(_headListener);
    _head?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.45,
    child: CustomPaint(
      painter: _HeroPreviewPaint(
        widget.appearance ?? oculumLiteDefaultAppearance(widget.hero),
        widget.hero,
        widget.weapon,
        widget.showClone,
        _tool?.image,
        _figure?.image,
        _head?.image,
      ),
    ),
  );
}

OculumLiteAppearance oculumLiteDefaultAppearance(LiteHero hero) =>
    switch (hero) {
      LiteHero.evasore => OculumLiteAppearance.evasore,
      LiteHero.scostubandito => OculumLiteAppearance.scostubandito,
      _ => const OculumLiteAppearance(),
    };

const _ink = Color(0xff100d17);
const _sand = Color(0xffe6b976);
const _violet = Color(0xffa58bdf);
const _active = Color(0xff83dfbd);
const _ember = Color(0xffff9667);
const _isometricY = .79;

Offset _offset(math.Point<double> point) => Offset(point.x, point.y);

class _ArenaCamera {
  _ArenaCamera(this.size, LiteRun run, {math.Point<double>? follow}) {
    final target = _offset(follow ?? run.position);
    final compact = size.width < 580;
    metresToPixels = compact
        ? math.max(size.width / 16.5, size.height / (run.height * _isometricY))
        : math.max(size.width / 30, size.height / (19 * _isometricY));
    final halfWidth = size.width / (2 * metresToPixels);
    final halfHeight = size.height / (2 * metresToPixels * _isometricY);
    center = Offset(
      _follow(target.dx, halfWidth, run.width.toDouble()),
      _follow(target.dy, halfHeight, run.height.toDouble()),
    );
  }

  final Size size;
  late final double metresToPixels;
  late final Offset center;

  Rect get visible => Rect.fromCenter(
    center: center,
    width: size.width / metresToPixels,
    height: size.height / (metresToPixels * _isometricY),
  );

  static double _follow(double target, double halfSpan, double limit) =>
      halfSpan * 2 >= limit
      ? limit / 2
      : target.clamp(halfSpan, limit - halfSpan).toDouble();

  math.Point<double> screenToWorld(Offset at) {
    final local = at - size.center(Offset.zero);
    return math.Point(
      center.dx + local.dx / metresToPixels,
      center.dy + local.dy / (metresToPixels * _isometricY),
    );
  }

  Offset worldToScreen(Offset at) {
    final local = at - center;
    return size.center(Offset.zero) +
        Offset(
          local.dx * metresToPixels,
          local.dy * metresToPixels * _isometricY,
        );
  }

  void apply(Canvas canvas) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(metresToPixels, metresToPixels * _isometricY);
    canvas.translate(-center.dx, -center.dy);
  }
}

class _Palette {
  const _Palette(this.ground, this.fleck, this.rubble, this.edge, this.light);
  final Color ground;
  final Color fleck;
  final Color rubble;
  final Color edge;
  final Color light;
}

const _camp = _Palette(
  Color(0xff332331),
  Color(0xff563846),
  Color(0xff624435),
  Color(0xff915f4d),
  Color(0xffb88a61),
);
const _forest = _Palette(
  Color(0xff263232),
  Color(0xff374f40),
  Color(0xff463c38),
  Color(0xff645b42),
  Color(0xff879461),
);
const _crypt = _Palette(
  Color(0xff282538),
  Color(0xff35314a),
  Color(0xff494257),
  Color(0xff65617b),
  Color(0xff817f96),
);
const _postea = _Palette(
  Color(0xff242a38),
  Color(0xff3c4c57),
  Color(0xff35434f),
  Color(0xff646976),
  Color(0xff79b4ad),
);

_Palette _palette(LiteBiome biome) => switch (biome) {
  LiteBiome.campo => _camp,
  LiteBiome.foresta => _forest,
  LiteBiome.dungeon => _crypt,
  LiteBiome.postea => _postea,
  LiteBiome.deserto => const _Palette(
    Color(0xff457289),
    Color(0xff81a6ba),
    Color(0xff253f57),
    Color(0xff87afc7),
    Color(0xffcee3e8),
  ),
  LiteBiome.orea => const _Palette(
    Color(0xff552743),
    Color(0xff9e506f),
    Color(0xff462540),
    Color(0xffa76898),
    Color(0xff7cddc7),
  ),
};

void _paintFloor(
  Canvas canvas,
  double width,
  double height,
  (int, int, LiteBiome) key,
  ui.Image? brush,
  ui.Image? scene,
) {
  final palette = _palette(key.$3);
  final random = math.Random(key.$1 ^ (key.$2 * 9176) ^ key.$3.index);
  final room = Rect.fromLTWH(0, 0, width, height);
  canvas.drawRect(room.inflate(.5), Paint()..color = _ink);
  canvas.drawRRect(
    RRect.fromRectAndRadius(room, const Radius.circular(.22)),
    Paint()..color = palette.ground,
  );
  canvas.save();
  canvas.clipRect(room);
  if (scene != null) {
    canvas.drawImageRect(
      scene,
      Rect.fromLTWH(0, 0, scene.width.toDouble(), scene.height.toDouble()),
      room,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.drawRect(room, Paint()..color = const Color(0x32140e18));
  } else if (brush != null) {
    _paintBrushedGround(canvas, brush, room, key);
  }

  // Wide painted patches establish depth underneath readable silhouettes.
  for (var i = 0; i < 35; i++) {
    final x = random.nextDouble() * width;
    final y = random.nextDouble() * height;
    final length = .7 + random.nextDouble() * 4.1;
    _poly(
      canvas,
      [
        Offset(x - length, y + .3),
        Offset(x - length * .32, y - .38),
        Offset(x + length * .61, y - .31),
        Offset(x + length, y - .53),
        Offset(x + length * .28, y + .39),
        Offset(x - length * .8, y + .56),
      ],
      (i.isEven ? palette.fleck : _ink).withValues(
        alpha: brush == null ? .24 : .10,
      ),
    );
  }
  if (brush == null) {
    switch (key.$3) {
      case LiteBiome.dungeon:
        _paving(canvas, width, height, palette, random);
      case LiteBiome.postea:
        _posteaFloor(canvas, width, height, palette);
      case LiteBiome.campo:
      case LiteBiome.foresta:
      case LiteBiome.deserto:
      case LiteBiome.orea:
        _land(
          canvas,
          width,
          height,
          palette,
          random,
          key.$3 == LiteBiome.foresta,
        );
    }
  }
  _rimDetails(canvas, room, key.$3, palette, random);
  final rim = Paint()
    ..color = palette.edge.withValues(alpha: .7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = .085;
  canvas.drawRect(room.deflate(.12), rim);
  for (var i = 0; i * 1.5 < width; i++) {
    final x = i * 1.5;
    _edgeMarks(canvas, Offset(x, .45), palette, (i % 3) * .08);
    _edgeMarks(canvas, Offset(x + .65, height - .19), palette, .12);
  }
  for (var i = 0; i * 1.2 < height; i++) {
    final y = i * 1.2;
    _edgeMarks(canvas, Offset(.2, y), palette, .08);
    _edgeMarks(canvas, Offset(width - .3, y + .3), palette, .11);
  }
  canvas.restore();
}

void _paintBrushedGround(
  Canvas canvas,
  ui.Image atlas,
  Rect bounds,
  (int, int, LiteBiome) key,
) {
  final cellWidth = atlas.width / 2;
  final cellHeight = atlas.height / 2;
  final index = _terrainCell(key.$3);
  canvas.drawImageRect(
    atlas,
    Rect.fromLTWH(
      index % 2 * cellWidth + 2,
      index ~/ 2 * cellHeight + 2,
      cellWidth - 4,
      cellHeight - 4,
    ),
    bounds,
    Paint()..filterQuality = FilterQuality.medium,
  );
  canvas.drawRect(bounds, Paint()..color = const Color(0x29140e18));
}

int _terrainCell(LiteBiome biome) => switch (biome) {
  LiteBiome.campo => 0,
  LiteBiome.foresta => 1,
  LiteBiome.dungeon => 2,
  LiteBiome.postea => 3,
  LiteBiome.deserto => 2,
  LiteBiome.orea => 1,
};

void _posteaFloor(
  Canvas canvas,
  double width,
  double height,
  _Palette palette,
) {
  for (var y = 0.0; y < height; y += 2.2) {
    for (var x = -1.0; x < width; x += 3.7) {
      final left = x + ((y / 2.2).round().isEven ? 1.85 : 0);
      final g = Offset(left, y);
      _poly(
        canvas,
        [
          g + const Offset(.12, .06),
          g + const Offset(3.44, .12),
          g + const Offset(3.63, .43),
          g + const Offset(3.51, 2.02),
          g + const Offset(.43, 2.11),
          g + const Offset(.08, 1.74),
        ],
        palette.rubble,
        stroke: _ink,
        width: .094,
      );
      _poly(canvas, [
        g + const Offset(.18, .21),
        g + const Offset(3.33, .19),
        g + const Offset(2.95, .52),
        g + const Offset(1.75, .41),
        g + const Offset(.14, 1.18),
      ], palette.fleck.withValues(alpha: .70));
      _lines(
        canvas,
        [
          g + const Offset(.24, 1.61),
          g + const Offset(.55, 1.89),
          g + const Offset(1.43, 1.89),
          g + const Offset(1.67, 1.68),
          g + const Offset(2.29, 1.66),
        ],
        palette.light.withValues(alpha: .35),
        .044,
      );
      _dryBrush(
        canvas,
        g + const Offset(.69, .66),
        const Offset(.16, .06),
        const Offset(-.22, .29),
        _ink.withValues(alpha: .51),
        7,
        width: .045,
      );
      if (((left / 3.7).round() + (y / 2.2).round()) % 4 == 0) {
        _poly(
          canvas,
          [
            g + const Offset(1.60, .63),
            g + const Offset(2.90, .65),
            g + const Offset(3.12, 1.0),
            g + const Offset(2.89, 1.34),
            g + const Offset(1.60, 1.32),
          ],
          palette.ground,
          stroke: _ink,
          width: .061,
        );
        _dryBrush(
          canvas,
          g + const Offset(1.87, .72),
          const Offset(.13, -.004),
          const Offset(-.08, .52),
          const Color(0xff536e77),
          8,
          width: .048,
        );
      }
    }
  }
}

void _rimDetails(
  Canvas canvas,
  Rect room,
  LiteBiome biome,
  _Palette tone,
  math.Random random,
) {
  final groups = (room.width / 3).ceil();
  for (var index = 0; index < groups; index++) {
    final x = index * 3.1 + random.nextDouble() * 1.3;
    final top = Offset(x, .07 + random.nextDouble() * .20);
    final bottom = Offset(x + .23, room.bottom - .1);
    for (final side in [top, bottom]) {
      final lower = side == bottom;
      _actor(canvas, side, 1, lower ? -1 : 1, () {
        final tall = .68 + random.nextDouble() * .39;
        _poly(
          canvas,
          [
            const Offset(-1.08, -.24),
            const Offset(.79, -.27),
            Offset(.48, tall * .55),
            Offset(.23, tall * .38),
            Offset(-.08, tall),
            Offset(-.31, tall * .48),
            Offset(-.70, tall * .7),
          ],
          tone.rubble,
          stroke: _ink,
          width: .067,
        );
        _dryBrush(
          canvas,
          const Offset(-.71, .21),
          const Offset(.18, -.025),
          Offset(.145, tall * .37),
          tone.light.withValues(alpha: .39),
          6,
        );
        if (biome == LiteBiome.foresta) {
          _lines(
            canvas,
            [
              const Offset(-.49, -.29),
              const Offset(-.32, .29),
              Offset(-.63, tall * .92),
              Offset(-.98, tall * .96),
            ],
            _ink,
            .12,
          );
          _lines(
            canvas,
            [
              const Offset(-.33, .24),
              const Offset(.07, .37),
              Offset(.38, tall * .74),
            ],
            tone.edge,
            .074,
          );
        } else if (biome == LiteBiome.postea) {
          _lines(
            canvas,
            const [
              Offset(-.35, .16),
              Offset(-.11, .49),
              Offset(.15, .19),
              Offset(.49, .19),
            ],
            tone.light.withValues(alpha: .52),
            .057,
          );
        }
      });
    }
  }
}

void _paving(
  Canvas canvas,
  double width,
  double height,
  _Palette palette,
  math.Random random,
) {
  for (var y = 0; y * 1.33 < height; y++) {
    for (var x = -1; x * 2.14 < width; x++) {
      final px = x * 2.14 + (y.isOdd ? 1.07 : 0) + random.nextDouble() * .16;
      final py = y * 1.33 + random.nextDouble() * .08;
      final slab = [
        Offset(px, py + .09),
        Offset(px + .17, py),
        Offset(px + 1.97, py + .05),
        Offset(px + 2.11, py + .95),
        Offset(px + 1.93, py + 1.24),
        Offset(px + .17, py + 1.16),
      ];
      _poly(
        canvas,
        slab,
        Color.lerp(palette.ground, palette.fleck, random.nextDouble() * .62)!,
        stroke: _ink.withValues(alpha: .68),
        width: .047,
      );
      if ((x + y) % 4 == 0) {
        _lines(
          canvas,
          [
            Offset(px + 1.01, py + .08),
            Offset(px + .94, py + .35),
            Offset(px + 1.21, py + .52),
            Offset(px + 1.15, py + .79),
          ],
          palette.edge.withValues(alpha: .44),
          .034,
        );
        _dryBrush(
          canvas,
          Offset(px + .31, py + .5),
          const Offset(.083, .047),
          const Offset(.36, -.082),
          palette.edge.withValues(alpha: .49),
          4,
        );
      }
    }
  }
}

void _land(
  Canvas canvas,
  double width,
  double height,
  _Palette palette,
  math.Random random,
  bool forest,
) {
  for (var i = 0; i < 270; i++) {
    final x = random.nextDouble() * width;
    final y = random.nextDouble() * height;
    final length = .10 + random.nextDouble() * .48;
    final origin = Offset(x, y);
    _lines(
      canvas,
      [
        origin - Offset(length, -.14),
        origin + const Offset(.02, -.01),
        origin + Offset(length * .32, -.07),
      ],
      palette.fleck,
      forest ? .04 : .028,
    );
    if (i.isEven && forest) {
      _poly(canvas, [
        origin + const Offset(-.12, 0),
        origin + Offset(-length * .4, -.15),
        origin + const Offset(.05, -.11),
        origin + Offset(length * .5, -.17),
        origin + const Offset(.12, .03),
      ], palette.light.withValues(alpha: .35));
    }
    if (i % 9 == 0) {
      _dryBrush(
        canvas,
        origin + const Offset(-.16, .04),
        const Offset(.08, -.044),
        const Offset(.12, -.30),
        (forest ? palette.light : palette.edge).withValues(alpha: .40),
        5,
        width: .042,
      );
    }
  }
}

void _edgeMarks(Canvas canvas, Offset o, _Palette tone, double lift) {
  _poly(
    canvas,
    [
      o + const Offset(-.34, .08),
      o + Offset(-.15, -.36 - lift),
      o + Offset(.02, -.16 - lift),
      o + Offset(.31, -.33 - lift),
      o + const Offset(.44, .11),
    ],
    tone.rubble,
    stroke: _ink,
    width: .045,
  );
}

class _ArenaPaint extends CustomPainter {
  _ArenaPaint(
    this.run,
    this.floor,
    this.appearance, {
    this.cover,
    this.heroFrames,
    this.ashleyFrames,
    this.props,
    this.monsters,
    this.posteaMonsters,
    this.bossArt,
    this.newActors,
    this.nightActors,
    this.lootArt,
    this.hubArt,
    this.faunaArt,
    this.mechanicalChickenArt = const {},
    this.solarArt,
    this.infernalArt,
    this.duplicatorPoses,
    this.duplicatorHeads,
    this.femininePoses,
    this.feminineHeads,
    required this.guestAppearances,
    required this.weapons,
    this.follow,
    this.followedFighterId,
    this.animationLead = 0,
    super.repaint,
  });

  final LiteRun run;
  final ui.Picture Function(LiteRun) floor;
  final OculumLiteAppearance appearance;
  final ui.Image? cover;
  final ui.Image? heroFrames;
  final ui.Image? ashleyFrames;
  final ui.Image? props;
  final ui.Image? monsters;
  final ui.Image? posteaMonsters;
  final ui.Image? bossArt;
  final ui.Image? newActors;
  final ui.Image? nightActors;
  final ui.Image? lootArt;
  final ui.Image? hubArt;
  final ui.Image? faunaArt;
  final Map<LiteInkFinish, ui.Image?> mechanicalChickenArt;
  final ui.Image? solarArt;
  final ui.Image? infernalArt;
  final ui.Image? duplicatorPoses;
  final ui.Image? duplicatorHeads;
  final ui.Image? femininePoses;
  final ui.Image? feminineHeads;
  final Map<String, OculumLiteAppearance> guestAppearances;
  final Map<LiteWeapon, ui.Image> weapons;
  final math.Point<double>? follow;
  final int? followedFighterId;
  final double animationLead;
  final _jobs = <(double, VoidCallback)>[];

  ui.Image? _poses(OculumLiteAppearance look) =>
      look.usesFeminineAtlas ? femininePoses : duplicatorPoses;

  ui.Image? _heads(OculumLiteAppearance look) =>
      look.usesFeminineAtlas ? feminineHeads : duplicatorHeads;

  @override
  void paint(Canvas canvas, Size size) {
    final camera = _ArenaCamera(size, run, follow: follow);
    final visible = camera.visible.inflate(2.95);
    canvas.drawRect(Offset.zero & size, Paint()..color = _ink);
    final surface = run.goblinCamp ? LiteBiome.campo : run.biome;
    final palette = _palette(surface);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    camera.apply(canvas);
    final terrain = floor(run);
    canvas.drawPicture(terrain);
    for (final ground in run.groundShots) {
      final at = _offset(ground.position);
      if (visible.contains(at)) _paintGroundShot(canvas, at, ground);
    }
    for (final impact in run.combatImpacts) {
      if (impact.target != LiteImpactTarget.fissure || impact.end == null)
        continue;
      _paintFissure(canvas, terrain, impact, run.time);
    }
    if (!run.goblinCamp &&
        (run.secretRoomRevealed ||
            run.obstacles.any((wall) => wall.secretGate))) {
      final at = _offset(LiteRun.secretCache);
      _oval(
        canvas,
        at,
        1.7,
        .9,
        const Color(0x5521192b),
        stroke: palette.edge.withValues(alpha: .72),
        strokeWidth: .035,
      );
      _lines(
        canvas,
        [
          at + const Offset(-.9, 0),
          at - const Offset(0, .66),
          at + const Offset(.9, 0),
          at + const Offset(0, .66),
          at + const Offset(-.9, 0),
        ],
        palette.edge.withValues(alpha: .68),
        .035,
      );
    }

    final jobs = _jobs..clear();
    for (final obstacle in run.obstacles) {
      final rect = Rect.fromLTWH(
        obstacle.left,
        obstacle.top,
        obstacle.width,
        obstacle.height,
      );
      if (!visible.overlaps(rect)) continue;
      _shadow(
        canvas,
        rect.center + const Offset(.24, .19),
        rect.width * .61,
        rect.height * .66,
        alpha: .52,
      );
      jobs.add((
        rect.bottom,
        () {
          final atlas = cover;
          if (obstacle.secretGate) {
            _obstacle(canvas, rect, surface, palette);
            final c = rect.center;
            _lines(
              canvas,
              [
                c + const Offset(-.17, -.40),
                c + const Offset(.19, -.25),
                c + const Offset(.05, -.03),
                c + const Offset(.37, .24),
              ],
              _ink,
              .09,
            );
            _lines(
              canvas,
              [
                c + const Offset(-.17, -.40),
                c + const Offset(.19, -.25),
                c + const Offset(.05, -.03),
                c + const Offset(.37, .24),
              ],
              palette.edge.withValues(alpha: .86),
              .029,
            );
          } else if (atlas == null) {
            _obstacle(canvas, rect, surface, palette);
          } else {
            _illustratedCover(canvas, atlas, rect, surface);
          }
        },
      ));
    }

    final time = run.time + animationLead;
    if (run.solarStairs case final stairs?) {
      final at = _offset(stairs);
      _solarStairPaint(canvas, at, time);
    }
    final objects = props;
    final portal = _offset(run.portalPosition);
    final merchant = _offset(run.shopPosition);
    if (visible.contains(portal)) {
      if (objects != null) {
        _arenaProp(canvas, objects, 1, portal, 2.65, run.stageClear);
      } else {
        _portal(canvas, portal, active: run.stageClear, time: time);
      }
    }
    if (!run.restHub &&
        !run.inSolarDungeon &&
        !run.inActTwo &&
        visible.contains(merchant)) {
      if (objects != null) {
        _arenaProp(canvas, objects, 0, merchant, 2.85, run.stageClear);
      } else {
        _merchant(canvas, merchant, active: run.stageClear, time: time);
      }
    }
    if (hubArt case final ui.Image art when run.restHub) {
      const stations = [
        (0, Offset(9, 9), 'Taverniera'),
        (1, Offset(15, 6.3), 'Fabbro'),
        (2, Offset(22, 9.8), 'Veggente'),
      ];
      final cell = art.width / 4.0;
      for (final (index, at, name) in stations) {
        if (!visible.contains(at)) continue;
        _shadow(canvas, at, .72, .22);
        canvas.drawImageRect(
          art,
          Rect.fromLTWH(index * cell, 0, cell, cell),
          Rect.fromLTWH(at.dx - 1.45, at.dy - 2.9, 2.9, 2.9),
          Paint()..filterQuality = FilterQuality.medium,
        );
        final label = TextPainter(
          text: TextSpan(
            text: name,
            style: const TextStyle(
              fontSize: .39,
              fontWeight: FontWeight.bold,
              color: Color(0xffffe7b5),
              shadows: [Shadow(blurRadius: .12, color: Color(0xff171218))],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, at - Offset(label.width / 2, -.08));
        label.dispose();
      }
      if (objects != null && visible.contains(const Offset(16, 14))) {
        _arenaProp(canvas, objects, 0, const Offset(16, 14), 2.6, true);
      }
    }
    final rest = _offset(run.restPosition);
    if (run.hasRest && visible.contains(rest)) {
      final ready = run.stageClear && !run.restUsed;
      if (objects != null) {
        _arenaProp(canvas, objects, 2, rest, 1.65, ready);
      } else {
        _restShrine(canvas, rest, ready, time);
      }
    }
    for (final item in run.loot) {
      if (visible.contains(_offset(item.position))) {
        _loot(
          canvas,
          item,
          time,
          item.weapon == null ? null : weapons[item.weapon],
          objects,
          lootArt,
        );
      }
    }

    final player = _offset(run.position);
    final aiming = _offset(run.aim);
    final weaponAim = _offset(run.weaponAim);
    _paintWeaponArtPulse(
      canvas,
      player,
      weaponAim,
      run.techniqueWeapon(),
      run.weaponArtCooldown,
    );
    final facing = weaponAim.dx >= 0 ? 1.0 : -1.0;
    final bossIsTangible = run.finalBossTangible;
    final beam = run.activeBeam;
    if (beam != null) _paintBeamFloor(canvas, beam);
    if (faunaArt case final art?) {
      for (final animal in run.fauna) {
        final species = LiteAnimal.forCreature(animal.kind);
        final at = _offset(animal.position);
        if (species == null || !visible.contains(at)) continue;
        _shadow(canvas, at, .46, .17);
        if (run.faunaAggressive) {
          _oval(
            canvas,
            at,
            .78,
            .31,
            const Color(0x49ce6547),
            stroke: const Color(0xffce6547),
            strokeWidth: .04,
          );
        }
        jobs.add((
          at.dy,
          () {
            final dx = animal.attackTarget?.x ?? player.dx;
            final face = dx >= at.dx ? 1.0 : -1.0;
            _actor(canvas, at, face, 1, () {
              _animalSprite(
                canvas,
                art,
                species,
                animal.stride,
                animationLead,
                animal.attacking || animal.strikePose > 0,
                animal.hitFlash > 0,
              );
            });
          },
        ));
      }
    }
    for (final enemy in run.enemies) {
      final at = _offset(enemy.position);
      final onCamera = visible.contains(at);
      final target = enemy.attackTarget;
      if (enemy.burrow case final track?) {
        _burrowWarning(canvas, enemy, track);
        if (!track.exposed) continue;
      }
      if (enemy.attacking && target != null) _astralWarning(canvas, enemy);

      if (enemy.kind == LiteEnemyKind.veyrth &&
          enemy.preparingBeam &&
          enemy.hp > 0) {
        _beamWarning(
          canvas,
          at,
          _offset(run.finalBeamPreviewEnd(enemy)),
          enemy.windup,
        );
      }
      final verdict = enemy.mirror?.chargingVerdict ?? false;
      if (enemy.hp > 0 && verdict && target != null) {
        _verdictMark(canvas, _offset(target), enemy.windup);
      }
      if (enemy.hp > 0 &&
          enemy.attacking &&
          !enemy.preparingBeam &&
          !verdict &&
          (onCamera || (target != null && visible.contains(_offset(target))))) {
        if (!enemy.preparingSpheres) _enemyWarning(canvas, enemy);
      }
      if (!onCamera) continue;
      final size = _enemyScale(enemy.kind);
      _shadow(canvas, at, size * .59, size * .23);
      jobs.add((
        at.dy,
        () {
          final facingTarget = target == null ? player.dx : target.x;
          _actor(canvas, at, size * (facingTarget >= at.dx ? 1 : -1), size, () {
            final phaseBoss =
                enemy.kind == LiteEnemyKind.veyrth ||
                enemy.kind == LiteEnemyKind.minionVeyrth;
            final mirror = enemy.mirror;
            final infernal = _infernalRow(enemy.kind);
            if (infernal != null && infernalArt != null) {
              if (enemy.burrow case final track?) {
                canvas.translate(0, -math.sin(track.progress * math.pi) * 1.42);
              }
              _solarActor(
                canvas,
                infernalArt!,
                infernal,
                animationLead,
                enemy.stride,
                enemy.windup,
                enemy.strikePose,
                enemy.hitFlash,
                columns: 6,
              );
              return;
            }
            final solarRow = _solarRow(enemy.kind);
            if (solarRow != null && solarArt != null) {
              _solarActor(
                canvas,
                solarArt!,
                solarRow,
                animationLead,
                enemy.stride,
                enemy.windup,
                enemy.strikePose,
                enemy.hitFlash,
              );
              return;
            }
            if (phaseBoss) {
              _paintVeyrth(
                canvas,
                bossArt,
                enemy,
                bossIsTangible,
                time,
                animationLead,
              );
              return;
            }
            final nightRow = _nightEnemyRow(enemy.kind);
            if (nightActors != null && nightRow != null) {
              _newActor(
                canvas,
                nightActors!,
                nightRow,
                _newFrame(
                  enemy.stride,
                  animationLead,
                  preparing: enemy.attacking,
                  hitting: enemy.strikePose > 0,
                ),
                height: _enemyHeight(enemy.kind),
                stride: enemy.stride,
                animationLead: animationLead,
                fallen: enemy.hp <= 0,
              );
              return;
            }
            final creature = _newCreatureRow(enemy.kind);
            if (newActors != null && creature != null) {
              _newActor(
                canvas,
                newActors!,
                creature,
                _newFrame(
                  enemy.stride,
                  animationLead,
                  preparing: enemy.attacking,
                  hitting: enemy.strikePose > 0 || enemy.hitFlash > 0,
                ),
                height: _enemyHeight(enemy.kind),
                stride: enemy.stride,
                animationLead: animationLead,
                fallen: enemy.hp <= 0,
              );
              return;
            }
            if (mirror != null) {
              final tone = switch (enemy.kind) {
                LiteEnemyKind.luce => const OculumLiteAppearance(
                  cloth: Color(0xff96876e),
                  accent: Color(0xffefcb7a),
                  hair: Color(0xff875b4f),
                ),
                LiteEnemyKind.ombra => const OculumLiteAppearance(
                  cloth: Color(0xff47304d),
                  accent: Color(0xffbc7fb1),
                  hair: Color(0xff28202a),
                ),
                _ => const OculumLiteAppearance(
                  cloth: Color(0xff514060),
                  accent: Color(0xffac8e7a),
                  hair: Color(0xff393240),
                ),
              };
              final mirrorAppearance = mirror.hero == LiteHero.duplicatore
                  ? appearance.copyWith(cloth: tone.cloth, accent: tone.accent)
                  : tone;
              _hero(
                canvas,
                mirrorAppearance,
                mirror.weapon,
                time,
                hero: mirror.hero,
                banditArt: monsters,
                poseArt: _poses(mirrorAppearance),
                heads: _heads(mirrorAppearance),
                gearArt: weapons[mirror.weapon],
                fallen: enemy.hp <= 0,
                phantom:
                    mirror.intangible > 0 || mirror.shadowVeilRemaining > 0,
                preparingAttack: enemy.attacking,
                stride: enemy.stride,
                animationLead: animationLead,
                moving: enemy.stride.strength > .05,
                attackElapsed: enemy.attacking
                    ? .11
                    : enemy.strikePose > 0
                    ? .24 - enemy.strikePose
                    : null,
              );
              return;
            }
            final atlas = run.biome == LiteBiome.postea
                ? posteaMonsters
                : monsters;
            if (atlas == null ||
                !_paintMonster(
                  canvas,
                  atlas,
                  enemy.kind,
                  enemy.id,
                  enemy.stride,
                  time,
                  animationLead,
                  fallen: enemy.hp <= 0,
                  windup: enemy.attacking ? enemy.windup : null,
                  hitFlash: enemy.hitFlash,
                  strike: enemy.strikePose,
                  clashing: enemy.clashRemaining > 0,
                )) {
              _enemy(
                canvas,
                enemy.kind,
                fallen: enemy.hp <= 0,
                time: time + at.dx * .22,
                cannonRaised: enemy.cannonRaised,
              );
            }
          });
          if (enemy.hp > 0) {
            final leapHeight = enemy.burrow == null
                ? 0.0
                : math.sin(enemy.burrow!.progress * math.pi) * 1.42 * size;
            final barAt =
                at -
                Offset(0, _enemyHeight(enemy.kind) * size + .13 + leapHeight);
            if (enemy.kind == LiteEnemyKind.veyrth && !bossIsTangible) {
              _oval(
                canvas,
                barAt,
                .92 * size,
                .12,
                const Color(0xff473251),
                stroke: _violet,
                strokeWidth: .036,
              );
            } else {
              _health(canvas, barAt, enemy.hp / enemy.maxHp, size);
            }
          }
          if (enemy.hitFlash > 0) {
            _hit(canvas, at - Offset(0, size * .58), size);
          }
          if (enemy.clashRemaining > 0) {
            _clashTrace(canvas, at, _offset(enemy.clashDirection));
          }
        },
      ));
    }
    for (final clone in run.clones) {
      final at = _offset(clone.position);
      if (!visible.contains(at)) continue;
      final companion = clone.companion;
      final guestOwned = clone.ownerId > 0;
      final cloneHero = guestOwned ? LiteHero.duplicatore : run.hero;
      final account = guestOwned
          ? run.coopFighters
                .where((fighter) => fighter.id == clone.ownerId)
                .firstOrNull
                ?.account
          : null;
      final cloneLook = guestOwned
          ? guestAppearances[account] ?? oculumLiteDefaultAppearance(cloneHero)
          : appearance;
      jobs.add((
        at.dy,
        () {
          _shadow(canvas, at, .49, .20, alpha: .36);
          final direction = _offset(clone.poseAim);
          final side = direction.dx < 0 ? -1.0 : 1.0;
          final scale = companion == LiteCompanion.granScostumato ? 1.19 : .89;
          _actor(canvas, at, side * scale, scale, () {
            if (companion != null) {
              if (companion.isSkeleton) {
                final art = newActors;
                if (art == null) {
                  _paintSkeleton(canvas, clone, weapons[clone.weapon], time);
                } else {
                  _newActor(
                    canvas,
                    art,
                    companion == LiteCompanion.scheletroFalce ? 2 : 3,
                    _newFrame(
                      clone.stride,
                      animationLead,
                      hitting: clone.swing > 0,
                    ),
                    height: 2.12,
                    stride: clone.stride,
                    animationLead: animationLead,
                    fallen: clone.down,
                  );
                }
                return;
              }
              final nightRow = _nightEnemyRow(companion.sprite);
              if (nightActors != null && nightRow != null) {
                _newActor(
                  canvas,
                  nightActors!,
                  nightRow,
                  _newFrame(
                    clone.stride,
                    animationLead,
                    hitting: clone.swing > 0,
                  ),
                  height: _enemyHeight(companion.sprite),
                  stride: clone.stride,
                  animationLead: animationLead,
                  fallen: clone.down,
                );
                return;
              }
              final row = _newCreatureRow(companion.sprite);
              if (newActors != null && row != null) {
                _newActor(
                  canvas,
                  newActors!,
                  row,
                  _newFrame(
                    clone.stride,
                    animationLead,
                    hitting: clone.swing > 0,
                  ),
                  height: _enemyHeight(companion.sprite) * .78,
                  stride: clone.stride,
                  animationLead: animationLead,
                  fallen: clone.down,
                );
                return;
              }
              final atlas = companion == LiteCompanion.drone
                  ? posteaMonsters
                  : monsters;
              if (atlas == null ||
                  !_paintMonster(
                    canvas,
                    atlas,
                    companion.sprite,
                    clone.id,
                    clone.stride,
                    time,
                    animationLead,
                    fallen: clone.down,
                    strike: clone.swing,
                    windup:
                        companion == LiteCompanion.granScostumato &&
                            clone.swing > 0
                        ? .12
                        : null,
                  )) {
                _enemy(
                  canvas,
                  companion.sprite,
                  fallen: clone.down,
                  time: time,
                  cannonRaised: false,
                );
              }
              return;
            }
            _hero(
              canvas,
              cloneLook,
              clone.weapon,
              time + at.dx * .3,
              hero: cloneHero,
              banditArt: monsters,
              poseArt: _poses(cloneLook),
              heads: _heads(cloneLook),
              gearArt: weapons[clone.weapon],
              figureArt:
                  !guestOwned && _hasDefaultAppearance(cloneLook, cloneHero)
                  ? heroFrames
                  : null,
              clone: true,
              fallen: clone.down,
              moving: clone.stride.strength > .05,
              stride: clone.stride,
              animationLead: animationLead,
              aiming: direction * side,
              front: direction.dy >= -.25,
              attackElapsed: clone.swing > 0 ? .23 - clone.swing : null,
            );
          });
          if (companion != null && !clone.down) {
            _oval(
              canvas,
              at,
              .54,
              .18,
              const Color(0x0f94cbab),
              stroke: const Color(0xff87d6b0),
              strokeWidth: .038,
            );
            _health(
              canvas,
              at - Offset(0, _enemyHeight(companion.sprite) * scale + .27),
              clone.hp / clone.maxHp,
              .78,
            );
          }
          if (clone.down) {
            final height = at - const Offset(0, .68);
            final ink = Paint()
              ..color = _active
              ..strokeCap = StrokeCap.round
              ..strokeWidth = .055;
            canvas.drawLine(
              height - const Offset(.12, 0),
              height + const Offset(.12, 0),
              ink,
            );
            canvas.drawLine(
              height - const Offset(0, .12),
              height + const Offset(0, .12),
              ink,
            );
          }
        },
      ));
    }
    for (final fighter in run.coopFighters) {
      final at = _offset(fighter.position);
      if (!visible.contains(at)) continue;
      final direction = _offset(fighter.weaponAim);
      final side = direction.dx < 0 ? -1.0 : 1.0;
      jobs.add((
        at.dy,
        () {
          _shadow(canvas, at, .54, .23, alpha: fighter.connected ? .58 : .33);
          _paintDodgeInk(
            canvas,
            at,
            _offset(fighter.burstDirection),
            fighter.burstRemaining,
          );
          _paintOpenPulse(
            canvas,
            at,
            fighter.hero,
            fighter.openCooldown,
            fighter.openGrade,
          );
          _paintInkFinish(
            canvas,
            at,
            guestAppearances[fighter.account]?.inkFinish ??
                LiteInkFinish.canonica,
            fighter.stride.strength,
          );
          if (fighter.blocking)
            _paintBlockGuard(
              canvas,
              at,
              fighter.blockResistance / fighter.maxBlockResistance,
            );
          _actor(canvas, at, side, 1, () {
            final ashley = ashleyFrames;
            if (fighter.hero == LiteHero.ashley && ashley != null) {
              _paintAshley(
                canvas,
                ashley,
                fighter.hp <= 0
                    ? 2
                    : fighter.springPunchActive
                    ? 3
                    : fighter.isMoving
                    ? 1
                    : 0,
                weapons[fighter.weapon],
                fighter.weapon,
                direction * side,
                stride: fighter.stride,
                animationLead: animationLead,
                springRemaining: fighter.springPoseRemaining,
              );
              return;
            }
            final standard =
                guestAppearances[fighter.account] ??
                oculumLiteDefaultAppearance(fighter.hero);
            _hero(
              canvas,
              standard,
              fighter.weapon,
              time,
              hero: fighter.hero,
              banditArt: fighter.hero == LiteHero.dronePostea
                  ? posteaMonsters
                  : monsters,
              giant: fighter.plagueForm,
              newActors: newActors,
              bossArt: bossArt,
              mimic: fighter.mimic,
              nightActors: nightActors,
              faunaActors: faunaArt,
              mechanicalChicken: mechanicalChickenArt[standard.inkFinish],
              solarActors: solarArt,
              infernalActors: infernalArt,
              night: fighter.night,
              preparingTalent: fighter.springPunchActive,
              punchPose: fighter.banditPunchPose,
              poseArt: _poses(standard),
              heads: _heads(standard),
              gearArt: weapons[fighter.weapon],
              fallen: fighter.hp <= 0,
              aiming: direction * side,
              front: direction.dy >= -.25,
              moving: fighter.isMoving,
              stride: fighter.stride,
              animationLead: animationLead,
              preparingAttack: fighter.preparingAttack,
              attackElapsed: fighter.attackCooldown > 0
                  ? fighter.weapon.cooldown - fighter.attackCooldown
                  : null,
            );
          });
          _health(
            canvas,
            at - const Offset(0, 2.45),
            fighter.hp / fighter.maxHp,
            1,
          );
        },
      ));
    }
    _shadow(canvas, player, .56, .23, alpha: run.intangible ? .24 : .65);
    if (run.clashDashing) _clashTrace(canvas, player, -weaponAim);
    if (!run.clashDashing) {
      _paintDodgeInk(
        canvas,
        player,
        _offset(run.burstDirection),
        run.burstRemaining,
      );
    }
    _paintProtection(canvas, player, run.hitProtectionRemaining);
    _paintOpenPulse(canvas, player, run.hero, run.openCooldown, run.openGrade);
    _paintInkFinish(canvas, player, appearance.inkFinish, run.stride.strength);
    if (run.blocking)
      _paintBlockGuard(
        canvas,
        player,
        run.blockResistance / run.maxBlockResistance,
      );
    jobs.add((
      player.dy,
      () {
        _actor(canvas, player, facing, 1, () {
          final strip = heroFrames;
          if (run.hero == LiteHero.ashley && strip != null) {
            _paintAshley(
              canvas,
              strip,
              run.hostDown || run.dead
                  ? 2
                  : run.springPunchActive
                  ? 3
                  : run.isMoving
                  ? 1
                  : 0,
              weapons[run.weapon],
              run.weapon,
              weaponAim * facing,
              stride: run.stride,
              animationLead: animationLead,
              springRemaining: run.springPoseRemaining,
            );
            return;
          }
          final spriteFrame =
              strip != null && _hasDefaultAppearance(appearance, run.hero)
              ? _motionFrame(run, animationLead)
              : null;
          if (strip != null && spriteFrame != null) {
            _heroFrame(
              canvas,
              strip,
              run,
              spriteFrame,
              appearance.accent,
              weapons[run.weapon],
              animationLead,
            );
            return;
          }
          _hero(
            canvas,
            appearance,
            run.weapon,
            time,
            hero: run.hero,
            banditArt: run.hero == LiteHero.dronePostea
                ? posteaMonsters
                : monsters,
            giant: run.plagueForm,
            newActors: newActors,
            bossArt: bossArt,
            mimic: run.mimic,
            nightActors: nightActors,
            faunaActors: faunaArt,
            mechanicalChicken: mechanicalChickenArt[appearance.inkFinish],
            solarActors: solarArt,
            infernalActors: infernalArt,
            night: run.night,
            preparingTalent: run.springPunchActive,
            punchPose: run.banditPunchPose,
            poseArt: _poses(appearance),
            heads: _heads(appearance),
            gearArt: weapons[run.weapon],
            figureArt: _hasDefaultAppearance(appearance, run.hero)
                ? heroFrames
                : null,
            phantom: run.intangible,
            fallen: run.dead || run.hostDown,
            aiming: weaponAim * facing,
            front: weaponAim.dy >= -.25,
            moving: run.isMoving,
            stride: run.stride,
            animationLead: animationLead,
            preparingAttack: run.preparingAttack,
            attackElapsed: run.attackCooldown > 0
                ? math.max(0.0, run.weapon.cooldown - run.attackCooldown)
                : null,
          );
        });
      },
    ));
    jobs.sort((a, b) => a.$1.compareTo(b.$1));
    for (final job in jobs) {
      job.$2();
    }
    jobs.clear();
    _paintNightLink(canvas, run, run.night, run.position, time);
    for (final fighter in run.coopFighters) {
      _paintNightLink(canvas, run, fighter.night, fighter.position, time);
    }

    if (beam != null) _paintBeamContact(canvas, beam);
    if (run.weapon == LiteWeapon.scettro && !run.hostDown && !run.dead) {
      _paintStaffOrbit(canvas, player, time);
    }
    for (final fighter in run.coopFighters) {
      final at = _offset(fighter.position);
      if (fighter.weapon == LiteWeapon.scettro &&
          fighter.hp > 0 &&
          fighter.connected &&
          visible.contains(at)) {
        _paintStaffOrbit(canvas, at, time);
      }
    }
    for (final enemy in run.enemies) {
      final at = _offset(enemy.position);
      if (!visible.contains(at)) continue;
      if (enemy.preparingSpheres) {
        _paintVeyrthSphereRing(canvas, enemy, time, animationLead);
      }
      if (enemy.shockSource case final source?
          when enemy.shockRemaining >
              LiteRun.staffShockSlow - LiteRun.staffShockFlash) {
        _paintStaffDischarge(canvas, _offset(source), at, time);
      }
    }
    if (!run.dead && !run.hostDown && !run.clashDashing) {
      _paintAttackInk(
        canvas,
        player,
        weaponAim,
        run.weapon,
        run.springPunchActive
            ? .28 - run.springPoseRemaining
            : run.attackCooldown,
        preparing: run.preparingAttack,
        spring: run.springPunchActive,
      );
    }
    for (final fighter in run.coopFighters) {
      final at = _offset(fighter.position);
      if (fighter.hp <= 0 || !visible.contains(at)) continue;
      _paintAttackInk(
        canvas,
        at,
        _offset(fighter.weaponAim),
        fighter.weapon,
        fighter.springPunchActive
            ? .28 - fighter.springPoseRemaining
            : fighter.attackCooldown,
        preparing: fighter.preparingAttack,
        spring: fighter.springPunchActive,
        guest: true,
      );
    }
    for (final impact in run.combatImpacts) {
      final at = _offset(impact.position);
      if (!visible.contains(at)) continue;
      if (impact.target == LiteImpactTarget.fissure) continue;
      if (impact.target == LiteImpactTarget.explosion) {
        _bombBurst(canvas, at, time - impact.time);
        continue;
      }
      if (impact.target == LiteImpactTarget.clash ||
          impact.target == LiteImpactTarget.verdict) {
        _collisionBurst(
          canvas,
          at,
          time - impact.time,
          verdict: impact.target == LiteImpactTarget.verdict,
        );
      } else {
        _paintHitInk(canvas, at, impact, time - impact.time);
      }
    }
    for (final projectile in run.projectiles) {
      if (visible.contains(_offset(projectile.position))) {
        var finish = LiteInkFinish.canonica;
        if (projectile.kind == LiteProjectileKind.posteaRay ||
            projectile.kind == LiteProjectileKind.posteaEgg) {
          final owner = projectile.sourceCloneId;
          if (owner == null) {
            finish = appearance.inkFinish;
          } else {
            final fighter = run.coopFighters
                .where((fighter) => fighter.id == owner)
                .firstOrNull;
            finish =
                guestAppearances[fighter?.account]?.inkFinish ??
                LiteInkFinish.canonica;
          }
        }
        _projectile(canvas, projectile, finish: finish);
      }
    }
    if (!run.dead &&
        !run.hostDown &&
        follow == null &&
        aiming.distanceSquared > 0) {
      _reticle(canvas, player + aiming * 1.75, run.weapon);
    }
    canvas.restore();

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          radius: .86,
          colors: [Color(0x00100d17), Color(0x05100d17), Color(0x9e100d17)],
          stops: [0, .52, 1],
        ).createShader(Offset.zero & size),
    );
    _paintCombatImpacts(canvas, camera, run, followedFighterId);
    final localNight = followedFighterId == null
        ? run.night
        : run.coopFighters
              .where((fighter) => fighter.id == followedFighterId)
              .firstOrNull
              ?.night;
    if ((localNight?.mud ?? 0) > 0)
      _paintMudOnScreen(canvas, size, localNight!.mud);
  }

  @override
  bool shouldRepaint(_ArenaPaint oldDelegate) => true;
}

void _clashTrace(Canvas canvas, Offset at, Offset direction) {
  _dryBrush(
    canvas,
    at - direction * .17 - const Offset(0, .08),
    const Offset(.005, -.10),
    -direction * .86,
    const Color(0xaabd9bd5),
    4,
    width: .071,
  );
}

void _collisionBurst(
  Canvas canvas,
  Offset at,
  double age, {
  required bool verdict,
}) {
  final phase = age / .53;
  if (phase >= 1) return;
  final fade = (1 - phase) * (1 - phase);
  final color = verdict ? const Color(0xffffda9e) : const Color(0xffffcea4);
  final size = (verdict ? .95 : .47) + phase * (verdict ? .85 : 1.21);
  final ring = Rect.fromCenter(
    center: at,
    width: size * 2,
    height: size * 1.35,
  );
  canvas.drawOval(
    ring,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .04 + fade * .045
      ..color = color.withValues(alpha: fade * .85),
  );
  for (var i = 0; i < 11; i++) {
    final angle = i * 2 * math.pi / 11 + .40;
    final ray = Offset(math.cos(angle), math.sin(angle) * .78);
    final middle = at + ray * (size * (.37 + (i % 3) * .18));
    final flank = Offset(-ray.dy, ray.dx) * (.025 + fade * .035);
    _poly(canvas, [
      middle - ray * (.22 * fade),
      middle + flank,
      middle + ray * (.29 + phase * .17),
      middle - flank,
    ], Color.lerp(color, _ember, (i % 3) * .18)!.withValues(alpha: fade));
  }
  if (phase < .36) {
    _oval(canvas, at, .30, .18, color.withValues(alpha: fade * .74));
  }
}

void _verdictMark(Canvas canvas, Offset at, double windup) {
  final progress = (1 - windup / .76).clamp(0.0, 1.0);
  const size = LiteRun.verdictRadius * 2;
  const gold = Color(0xffffcb86);
  _oval(
    canvas,
    at,
    size,
    size,
    gold.withValues(alpha: .12 + progress * .21),
    stroke: gold,
    strokeWidth: .045,
  );
  _oval(
    canvas,
    at,
    size * progress,
    size * progress,
    gold.withValues(alpha: .18),
    stroke: gold.withValues(alpha: .6),
  );
}

void _paintProtection(Canvas canvas, Offset at, double remaining) {
  if (remaining <= 0) return;
  final oval = Rect.fromCenter(center: at, width: 1.33, height: .56);
  final fraction = remaining / LiteRun.lifeHitProtection;
  canvas.drawOval(
    oval,
    Paint()
      ..color = const Color(0xff181217)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .13,
  );
  canvas.drawArc(
    oval,
    -math.pi / 2,
    math.pi * 2 * fraction,
    false,
    Paint()
      ..color = _sand
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .069,
  );
}

void _paintCombatImpacts(
  Canvas canvas,
  _ArenaCamera camera,
  LiteRun run,
  int? fighterId,
) {
  if (run.combatImpacts.isEmpty) return;
  final size = camera.size;
  var incomingFlash = 0.0;
  final font = (size.shortestSide * .041).clamp(15.0, 26.0);
  final localMaximum = fighterId == null
      ? run.maxHp
      : run.coopFighters
                .where((fighter) => fighter.id == fighterId)
                .firstOrNull
                ?.maxHp ??
            run.maxHp;
  for (final impact in run.combatImpacts) {
    final age = run.time - impact.time;
    final isMine = fighterId == null
        ? impact.target == LiteImpactTarget.player
        : impact.target == LiteImpactTarget.ally &&
              impact.subjectId == fighterId;
    if (isMine && impact.life > 0) {
      final force = (.19 + impact.life / localMaximum * .85).clamp(.19, .76);
      incomingFlash = math.max(
        incomingFlash,
        force * (1 - age / .34).clamp(0.0, 1.0),
      );
    }
  }
  if (incomingFlash > 0) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          radius: .72,
          colors: [
            Colors.transparent,
            const Color(0xffab2438).withValues(alpha: incomingFlash),
          ],
          stops: const [.33, 1],
        ).createShader(bounds),
    );
  }

  if (size.width < 40 || size.height < 32) return;
  final occupiedLabels = <Rect>[];
  final clashAnchors = <Offset>[];
  final clashSpacing = font * 5;
  // Keep the newest feedback closest to its target. Older labels can move
  // without hiding the most recent hit or painting over another label.
  for (final impact in run.combatImpacts.toList().reversed) {
    final at = _offset(impact.position);
    if (!camera.visible.contains(at)) continue;
    final age = run.time - impact.time;
    final progress = (age / LiteRun.combatImpactDuration).clamp(0.0, 1.0);
    final opacity = ((1 - progress) / .35).clamp(0.0, 1.0);
    if (opacity == 0 ||
        impact.target == LiteImpactTarget.verdict ||
        impact.target == LiteImpactTarget.fissure ||
        impact.target == LiteImpactTarget.explosion)
      continue;
    final clash = impact.target == LiteImpactTarget.clash;
    final kind = impact.enemyKind;
    final height = clash
        ? .48
        : kind == null
        ? 1.65
        : _enemyHeight(kind) * _enemyScale(kind);
    final anchor = camera.worldToScreen(at - Offset(0, height + .34));
    if (clash &&
        clashAnchors.any(
          (previous) =>
              (anchor - previous).distanceSquared < clashSpacing * clashSpacing,
        )) {
      continue;
    }
    final centre = Offset(
      anchor.dx + (impact.target == LiteImpactTarget.player ? -12 : 12),
      (anchor.dy - progress * 24).clamp(9.0, size.height - 9),
    );
    final scale = 1 + .22 * (1 - age / .16).clamp(0.0, 1.0);
    final lifeColor = impact.target == LiteImpactTarget.enemy
        ? const Color(0xffffda9b)
        : const Color(0xffff8d89);
    final painted = _impactLabel(
      canvas,
      size,
      centre,
      font * scale,
      opacity,
      occupiedLabels,
      [
        if (clash) ('Clash', _sand),
        if (impact.intangible) ('Intangibile', _violet),
        if (impact.life > 0) ('−${_damageLabel(impact.life)}', lifeColor),
        if (impact.shield > 0)
          ('Scudo −${_damageLabel(impact.shield)}', const Color(0xffa2ddfd)),
      ],
    );
    if (clash && painted) clashAnchors.add(anchor);
  }
}

String _damageLabel(double amount) {
  if (amount < .1) return '<0,1';
  final decimal = amount.toStringAsFixed(1);
  return decimal.endsWith('.0')
      ? decimal.substring(0, decimal.length - 2)
      : decimal.replaceFirst('.', ',');
}

bool _impactLabel(
  Canvas canvas,
  Size size,
  Offset centre,
  double height,
  double opacity,
  List<Rect> occupiedLabels,
  List<(String, Color)> parts,
) {
  if (parts.isEmpty) return false;
  final painter = TextPainter(
    text: TextSpan(
      style: TextStyle(fontSize: height, fontWeight: FontWeight.w900),
      children: [
        for (var i = 0; i < parts.length; i++)
          TextSpan(
            text: '${i == 0 ? '' : '   '}${parts[i].$1}',
            style: TextStyle(color: parts[i].$2.withValues(alpha: opacity)),
          ),
      ],
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout(maxWidth: size.width - 12);
  final origin = Offset(
    (centre.dx - painter.width / 2).clamp(6.0, size.width - painter.width - 6),
    (centre.dy - painter.height / 2).clamp(
      4.0,
      math.max(4.0, size.height - painter.height - 4),
    ),
  );
  final bounds = (origin & painter.size).inflate(3.5);
  final rowHeight = bounds.height + 3;
  try {
    for (final row in const [0, -1, -2, 1, 2]) {
      final shift = Offset(0, row * rowHeight);
      final slot = bounds.shift(shift);
      if (slot.top < 0 ||
          slot.bottom > size.height ||
          occupiedLabels.any((other) => other.inflate(2).overlaps(slot))) {
        continue;
      }
      occupiedLabels.add(slot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(slot, const Radius.circular(4)),
        Paint()..color = _ink.withValues(alpha: .86 * opacity),
      );
      painter.paint(canvas, origin + shift);
      return true;
    }
    return false;
  } finally {
    painter.dispose();
  }
}

void _paintVeyrth(
  Canvas canvas,
  ui.Image? atlas,
  LiteEnemy enemy,
  bool vulnerable,
  double time,
  double animationLead,
) {
  final minion = enemy.kind == LiteEnemyKind.minionVeyrth;
  final solid = minion || vulnerable;
  const violet = Color(0xffad7cc4);
  if (enemy.hp <= 0) {
    canvas.rotate(1.18);
    canvas.scale(.70);
  } else if (!solid) {
    _oval(
      canvas,
      Offset.zero,
      1.92,
      .54,
      const Color(0x226e4589),
      stroke: violet.withValues(alpha: .78),
      strokeWidth: .061,
    );
    _dryBrush(
      canvas,
      const Offset(-.72, -.46),
      const Offset(.032, -.104),
      const Offset(.213, -.15),
      violet.withValues(alpha: .53),
      11,
      width: .036,
    );
  }
  final height = minion ? 1.07 : 2.33;
  final width = minion ? 1.85 : 2.62;
  final hover = math.sin(time * 4.4 + enemy.id) * (minion ? .11 : .08);
  if (atlas != null) {
    final cell = atlas.width / 2;
    final scale = cell / 448;
    final left = minion ? cell : 0.0;
    final src = Rect.fromLTWH(
      left + 8 * scale,
      (minion ? 244 : 136) * scale,
      432 * scale,
      (minion ? 196 : 304) * scale,
    );
    final draw = Paint()..filterQuality = FilterQuality.medium;
    if (!solid) {
      draw.colorFilter = const ColorFilter.matrix([
        .82,
        0,
        0,
        0,
        14,
        0,
        .60,
        0,
        0,
        0,
        0,
        0,
        .96,
        0,
        18,
        0,
        0,
        0,
        .34,
        0,
      ]);
    }
    final rig = minion ? _inkVeyrthEcho : _inkVeyrth;
    _inkActorSprite(
      canvas,
      atlas,
      src,
      Rect.fromLTWH(-width * .50, -height + hover, width, height),
      draw,
      rig,
      grounded: false,
      phase:
          time * 5.1 +
          _stridePhase(enemy.stride, rig.strideMetres, animationLead),
      strength: minion ? .70 : .56,
      anticipation: enemy.attacking ? .7 : 0,
      strike: enemy.strikePose / .24,
    );
    return;
  }
  _eliteSpecter(canvas, enemy.kind, hover, solid: solid);
}

void _eliteSpecter(
  Canvas canvas,
  LiteEnemyKind kind,
  double hover, {
  bool solid = true,
}) {
  final form = kind == LiteEnemyKind.veyrth ? 1.31 : .88;
  final color = kind == LiteEnemyKind.luce
      ? const Color(0xffc7ac7a)
      : kind == LiteEnemyKind.minionVeyrth
      ? const Color(0xffad7cc4)
      : const Color(0xff6e495f);
  canvas.save();
  canvas.translate(0, hover);
  canvas.scale(form);
  final fabric = Path()
    ..moveTo(-.78, -.13)
    ..lineTo(-.59, -.88)
    ..quadraticBezierTo(-.54, -1.47, -.34, -1.43)
    ..lineTo(-.15, -1.82)
    ..lineTo(.24, -1.74)
    ..lineTo(.40, -1.39)
    ..quadraticBezierTo(.91, -1.22, .76, -.84)
    ..lineTo(.89, -.26)
    ..lineTo(.53, -.34)
    ..lineTo(.40, -.11)
    ..lineTo(.23, -.30)
    ..lineTo(-.13, -.13)
    ..lineTo(-.34, -.27)
    ..lineTo(-.78, -.13)
    ..close();
  _brushShape(
    canvas,
    fabric,
    color.withValues(alpha: solid ? 1 : .48),
    _actorInk,
    .075,
  );
  _poly(canvas, const [
    Offset(-.22, -1.54),
    Offset(.13, -1.57),
    Offset(.34, -1.35),
    Offset(.11, -1.15),
    Offset(-.21, -1.12),
    Offset(-.38, -1.31),
  ], _actorInk);
  _poly(canvas, const [
    Offset(-.21, -1.36),
    Offset(.16, -1.39),
    Offset(.07, -1.24),
    Offset(-.12, -1.26),
  ], const Color(0xffdc9ac4));
  _dryBrush(
    canvas,
    const Offset(.21, -.57),
    const Offset(.06, -.081),
    const Offset(.029, .40),
    _actorInk.withValues(alpha: .73),
    7,
    width: .043,
  );
  canvas.restore();
}

void _beamWarning(Canvas canvas, Offset source, Offset target, double windup) {
  final delta = target - source;
  if (delta.distanceSquared < .01) return;
  final extent = delta.distance;
  final direction = delta / extent;
  final guide = Path();
  for (var position = 0.35; position < extent; position += .95) {
    final a = source + direction * position;
    final b = source + direction * math.min(extent, position + .48);
    guide
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
  }
  final charge = (1 - windup / .75).clamp(0.0, 1.0);
  const alarm = Color(0xffe9a1a7);
  canvas.drawPath(
    guide,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .07 + charge * .072
      ..color = alarm.withValues(alpha: .55 + charge * .41),
  );
  _oval(
    canvas,
    source,
    1.45,
    1.45,
    alarm.withValues(alpha: .15),
    stroke: alarm.withValues(alpha: .86),
    strokeWidth: .055,
  );
}

void _paintBeamFloor(Canvas canvas, LiteBeam beam) {
  final a = _offset(beam.origin);
  final b = _offset(beam.end);
  const outline = Color(0xffa04477);
  _lines(canvas, [a, b], outline.withValues(alpha: .62), .64);
  _lines(canvas, [a, b], const Color(0xfffab2a0), .26);
  _lines(canvas, [a, b], const Color(0xfffae3bf), .084);
}

void _paintBeamContact(Canvas canvas, LiteBeam beam) {
  final point = _offset(beam.end);
  if (beam.coverContact <= 0) return;
  final crack = (beam.coverContact / LiteRun.finalBeamCoverSeconds).clamp(
    0.0,
    1.0,
  );
  final spread = .32 + crack * .65;
  _oval(
    canvas,
    point,
    spread,
    spread * .80,
    const Color(0xaad87863),
    stroke: const Color(0xfff6c79e),
    strokeWidth: .055,
  );
  _dryBrush(
    canvas,
    point - const Offset(.16, .15),
    const Offset(.049, .078),
    Offset(spread, .29),
    const Color(0xffe3a079),
    6,
    width: .043,
  );
}

final _monsterSampler = Paint()..filterQuality = FilterQuality.low;

bool _paintMonster(
  Canvas canvas,
  ui.Image atlas,
  LiteEnemyKind kind,
  int id,
  LiteStride stride,
  double time,
  double animationLead, {
  bool fallen = false,
  double? windup,
  double hitFlash = 0,
  double strike = 0,
  bool clashing = false,
  bool hideRifleBarrel = false,
}) {
  final cell = atlas.width / 3;
  final rows = (atlas.height / cell).round();
  final index = rows == 1
      ? kind.index - LiteEnemyKind.ragnoSaldatore.index
      : kind.index;
  if (index < 0 || index >= rows * 3) return false;

  final original = Rect.fromLTWH(
    index % 3 * cell,
    index ~/ 3 * cell,
    cell,
    cell,
  );
  final height = _enemyHeight(kind) + .38;
  final sway = math.sin(time * 6 + id) * .029;
  final flyer = kind == LiteEnemyKind.dronePostea;
  final hover = flyer ? .20 + math.sin(time * 7 + id) * .083 : 0.0;
  canvas.save();
  if (fallen) {
    canvas.rotate(1.16);
    canvas.scale(.72);
  } else if (windup != null) {
    final tension = (1 - windup / .46).clamp(0.0, 1.0);
    canvas.rotate(
      kind == LiteEnemyKind.granScostumato
          ? -.045 - .075 * tension
          : .03 + .07 * tension,
    );
    canvas.scale(1 + .04 * tension, 1 - .045 * tension);
  } else if (hitFlash > 0) {
    final stagger = (hitFlash / .17).clamp(0.0, 1.0);
    canvas.translate(-.11 * stagger, 0);
    canvas.rotate(-.065 * stagger);
  }
  final pose = Rect.fromLTWH(
    -height * .55,
    -height + sway - hover,
    height * 1.10,
    height,
  );
  if (hideRifleBarrel) {
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(pose.inflate(.45))
        ..addRect(
          Rect.fromLTRB(
            pose.left + pose.width * .74,
            pose.top + pose.height * .43,
            pose.right + .20,
            pose.top + pose.height * .67,
          ),
        ),
    );
  }
  final rig = _inkEnemyRigs[kind];
  if (rig == null || fallen) {
    canvas.drawImageRect(atlas, original, pose, _monsterSampler);
  } else {
    final strength = clashing ? 0.0 : stride.strength;
    final phase = _stridePhase(stride, rig.strideMetres, animationLead);
    final strain = windup != null
        ? (.24 + (1 - windup / .46).clamp(0.0, 1.0) * .76)
        : 0.0;
    final compress = switch (kind) {
      LiteEnemyKind.slime => .055 + math.sin(time * 6 + phase) * .048,
      LiteEnemyKind.babyForestDemon || LiteEnemyKind.forestDemon =>
        (.02 + .034 * math.cos(phase * 2)) * strength,
      _ => 0.0,
    };
    _inkActorSprite(
      canvas,
      atlas,
      original,
      pose,
      _monsterSampler,
      rig,
      phase: flyer ? time * 12 : phase,
      strength: flyer ? .40 : strength,
      anticipation: strain,
      strike: ((strike - animationLead) / .24).clamp(0.0, 1.0),
      compress: compress + (flyer ? 0 : _stepCompression(phase) * strength),
      grounded: !flyer && kind != LiteEnemyKind.slime,
    );
    if (flyer) _paintDroneRotor(canvas, pose, time);
  }
  canvas.restore();
  return true;
}

bool _hasDefaultAppearance(OculumLiteAppearance look, LiteHero hero) =>
    look.sameAs(oculumLiteDefaultAppearance(hero), includeInkFinish: false);

int? _motionFrame(LiteRun run, double animationLead) {
  if (run.hero.specialTalent) return null;
  if (run.dead || !run.isMoving || run.rescuing) return null;
  if (run.hero == LiteHero.evasore && run.intangible) return 3;
  if (run.intangible || run.preparingAttack || run.attackCooldown > 0) {
    return null;
  }
  if (run.stride.speed < 3.4) return null;
  final phase = _stridePhase(
    run.stride,
    _inkRunningFeet.strideMetres,
    animationLead,
  );
  return math.sin(phase) < 0 ? 2 : 1;
}

void _heroFrame(
  Canvas canvas,
  ui.Image strip,
  LiteRun run,
  int frame,
  Color trim,
  ui.Image? gear,
  double animationLead,
) {
  const height = 2.28;
  const width = height * _isometricY;
  final size = strip.width / 2;
  final origin = Offset(size * (frame % 2), size * (frame ~/ 2));
  final contact = frame == 3 ? .59 : .54;
  canvas.save();
  if (frame != 3) {
    _groundedMotion(
      canvas,
      run.stride,
      animationLead,
      strideMetres: _inkRunningFeet.strideMetres,
    );
    // The running drawings leave the hands free. The selected equipment
    // is visible stowed behind the leading shoulder until the next attack.
    _actor(canvas, const Offset(-.13, -1.18), .74, .74, () {
      canvas.rotate(-2.23);
      _holdWeapon(canvas, run.weapon, gear, trim, _actorInk);
    });
  } else {
    _dryBrush(
      canvas,
      const Offset(-.91, -.43),
      const Offset(-.024, -.088),
      const Offset(-.43, .14),
      _active.withValues(alpha: .62),
      7,
      width: .039,
    );
  }
  final phase = _stridePhase(
    run.stride,
    _inkRunningFeet.strideMetres,
    animationLead,
  );
  _inkActorSprite(
    canvas,
    strip,
    origin & Size.square(size),
    Rect.fromLTWH(-width * contact, -height * .971, width, height),
    Paint()..filterQuality = FilterQuality.medium,
    _inkRunningFeet,
    phase: phase,
    strength: frame == 3 ? 0 : run.stride.strength * .38,
    clothFlow: frame == 3 ? 0 : run.stride.strength * .38,
  );
  canvas.restore();
}

// Alpha trim per illustrated cell, measured on the original square atlas.
// The destination is grounded on the collision box's farthest front edge.
const _coverTrims = [
  Rect.fromLTRB(34, 90, 594, 576),
  Rect.fromLTRB(24, 72, 592, 586),
  Rect.fromLTRB(33, 111, 592, 550),
  Rect.fromLTRB(6, 102, 602, 553),
];

void _illustratedCover(
  Canvas canvas,
  ui.Image atlas,
  Rect bounds,
  LiteBiome biome,
) {
  final cell = _terrainCell(biome);
  final trim = _coverTrims[cell];
  final scale = atlas.width / 1254;
  final x = (cell % 2) * 627;
  final y = (cell ~/ 2) * 627;
  final source = Rect.fromLTRB(
    (x + trim.left) * scale,
    (y + trim.top) * scale,
    (x + trim.right) * scale,
    (y + trim.bottom) * scale,
  );
  final width = bounds.width + .12;
  final nativeHeight = width * source.height / source.width / _isometricY;
  final rows = (bounds.height / (width * 1.24)).ceil().clamp(1, 5);
  final stride = bounds.height / rows;
  final height = nativeHeight.clamp(stride + .24, stride + .84);
  final paint = Paint()..filterQuality = FilterQuality.medium;
  for (var row = 0; row < rows; row++) {
    final bottom = bounds.top + stride * (row + 1) + .07;
    canvas.drawImageRect(
      atlas,
      source,
      Rect.fromLTWH(
        bounds.center.dx - width / 2,
        bottom - height,
        width,
        height,
      ),
      paint,
    );
  }
}

void _obstacle(Canvas canvas, Rect r, LiteBiome biome, _Palette tone) {
  final height = r.width > 2.1 ? .65 : .92;
  final top = r.top - height;
  final bottom = r.bottom - height;
  final right = r.right;
  final left = r.left;
  _poly(
    canvas,
    [
      Offset(left, bottom),
      Offset(right, bottom),
      Offset(right, r.bottom),
      Offset(left + .08, r.bottom),
    ],
    tone.rubble,
    stroke: _ink,
  );
  _poly(
    canvas,
    [
      Offset(left, top + .14),
      Offset(left + r.width * .11, top),
      Offset(right - .12, top + .10),
      Offset(right, bottom - .10),
      Offset(right - r.width * .24, bottom + .10),
      Offset(left + .06, bottom - .04),
    ],
    tone.edge,
    stroke: _ink,
  );
  _poly(canvas, [
    Offset(left + .20, top + .24),
    Offset(right - .24, top + .18),
    Offset(left + r.width * .38, top + .37),
    Offset(left + .20, bottom - .10),
  ], tone.light.withValues(alpha: .51));
  final n = math.max(2, (r.width / .48).round());
  for (var i = 1; i < n; i++) {
    final x = left + r.width * i / n;
    _lines(
      canvas,
      [
        Offset(x - .1, top + .11),
        Offset(x + .05, bottom - .08),
        Offset(x, r.bottom - .03),
      ],
      _ink.withValues(alpha: .65),
      .034,
    );
  }
  if (biome == LiteBiome.campo) {
    _campObstacleDetail(canvas, r, bottom, tone);
  } else if (biome == LiteBiome.foresta) {
    _forestObstacleDetail(canvas, r, bottom, tone);
  } else if (biome == LiteBiome.postea) {
    _poly(
      canvas,
      [
        Offset(left + .10, bottom - .07),
        Offset(right - .07, bottom - .05),
        Offset(right - .21, r.bottom - .14),
        Offset(left + .23, r.bottom - .17),
      ],
      const Color(0xff24242f),
      stroke: _ink,
      width: .066,
    );
    _lines(
      canvas,
      [
        Offset(left + .19, bottom + .20),
        Offset(r.center.dx - .18, bottom + .20),
        Offset(r.center.dx + .04, r.bottom - .27),
        Offset(right - .18, r.bottom - .25),
      ],
      tone.light.withValues(alpha: .83),
      .062,
    );
    _dryBrush(
      canvas,
      Offset(left + .25, bottom - .34),
      Offset(r.width * .113, .034),
      const Offset(.143, -.20),
      tone.light.withValues(alpha: .64),
      7,
      width: .031,
    );
  } else {
    for (var x = left + .27; x < right - .11; x += .68) {
      canvas.drawLine(
        Offset(x, bottom + .25),
        Offset(math.min(x + .41, right - .09), bottom + .25),
        Paint()
          ..strokeWidth = .033
          ..color = tone.light.withValues(alpha: .54),
      );
    }
  }
  _dryBrush(
    canvas,
    Offset(left + .20, r.bottom - .14),
    Offset(r.width * .092, -.018),
    Offset(.06, -height * .39),
    _ink.withValues(alpha: .55),
    7,
    width: .046,
  );
}

void _campObstacleDetail(Canvas canvas, Rect r, double bottom, _Palette tone) {
  final long = r.width >= 2.5 || r.height >= 2.5;
  final plankY = r.bottom - .30;
  _lines(
    canvas,
    [Offset(r.left + .11, plankY + .04), Offset(r.right - .08, plankY)],
    _ink,
    .25,
  );
  _lines(
    canvas,
    [Offset(r.left + .11, plankY), Offset(r.right - .08, plankY - .04)],
    tone.light.withValues(alpha: .78),
    .13,
  );
  for (var x = r.left + .37; x < r.right - .09; x += long ? .52 : .88) {
    _poly(
      canvas,
      [
        Offset(x - .21, r.bottom - .09),
        Offset(x - .24, bottom - .36),
        Offset(x - .10, bottom - .63),
        Offset(x + .10, bottom - .43),
        Offset(x + .15, r.bottom - .08),
      ],
      tone.edge,
      stroke: _ink,
      width: .047,
    );
  }
}

void _forestObstacleDetail(
  Canvas canvas,
  Rect r,
  double bottom,
  _Palette tone,
) {
  final center = Offset(r.center.dx, bottom - .25);
  for (var i = -2; i <= 2; i++) {
    _poly(
      canvas,
      [
        center + Offset(i * r.width / 6, -.15),
        center + Offset(i * r.width / 5, -.45 - i.abs() * .09),
        center + Offset(i * r.width / 5 + .35, -.65),
        center + Offset(i * r.width / 6 + .45, .23 - i.abs() * .08),
      ],
      tone.light.withValues(alpha: .65),
      stroke: _ink,
      width: .045,
    );
  }
  _lines(
    canvas,
    [
      center,
      center + const Offset(.33, .40),
      center + Offset(r.width * .32, r.height * .46),
    ],
    tone.rubble,
    .14,
  );
}

void _actor(Canvas canvas, Offset at, double sx, double sy, VoidCallback draw) {
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.scale(sx, sy);
  draw();
  canvas.restore();
}

void _shadow(
  Canvas canvas,
  Offset at,
  double rx,
  double ry, {
  double alpha = .57,
}) {
  canvas.drawOval(
    Rect.fromCenter(center: at, width: rx * 2, height: ry * 2),
    Paint()..color = _ink.withValues(alpha: alpha),
  );
}

void _poly(
  Canvas canvas,
  List<Offset> points,
  Color color, {
  Color? stroke,
  double width = .055,
}) {
  final path = Path()..addPolygon(points, true);
  canvas.drawPath(path, Paint()..color = color);
  if (stroke != null) {
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }
}

void _lines(Canvas canvas, List<Offset> points, Color color, double width) {
  final path = Path()..addPolygon(points, false);
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke,
  );
}

void _dryBrush(
  Canvas canvas,
  Offset first,
  Offset step,
  Offset direction,
  Color color,
  int count, {
  double width = .023,
}) {
  final scratches = Path();
  for (var index = 0; index < count; index++) {
    final at = first + step * index.toDouble();
    final taper = 1 - (index % 4) * .16;
    final end = at + direction * taper;
    final middle = Offset.lerp(at, end, .39)! + const Offset(.005, -.018);
    scratches
      ..moveTo(at.dx, at.dy)
      ..lineTo(middle.dx - width * .58, middle.dy + width * .5)
      ..lineTo(end.dx, end.dy)
      ..lineTo(middle.dx + width * .68, middle.dy - width * .53)
      ..close();
  }
  canvas.drawPath(scratches, Paint()..color = color);
}

void _oval(
  Canvas canvas,
  Offset center,
  double width,
  double height,
  Color color, {
  Color? stroke,
  double strokeWidth = .05,
}) {
  final rect = Rect.fromCenter(center: center, width: width, height: height);
  canvas.drawOval(rect, Paint()..color = color);
  if (stroke != null) {
    canvas.drawOval(
      rect,
      Paint()
        ..color = stroke
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );
  }
}

const _actorInk = Color(0xff171015);
const _bootLeather = Color(0xff795043);
const _rimLeather = Color(0xffaa7658);

class _InkPart {
  _InkPart(this.pivot, this.size, this.rotation, [List<Offset>? cut])
    : mask = cut == null ? null : (Path()..addPolygon(cut, true));
  final Offset pivot;
  final double size;
  final double rotation;
  final Path? mask;
}

final _inkWeapons = <LiteWeapon, _InkPart>{
  LiteWeapon.boomerang: _InkPart(const Offset(51, 142), .010, .68),
  LiteWeapon.spadaScudo: _InkPart(const Offset(38, 145), .010, 1.14, const [
    Offset(0, 0),
    Offset(100, 0),
    Offset(93, 73),
    Offset(73, 115),
    Offset(70, 192),
    Offset(0, 192),
  ]),
  LiteWeapon.guanti: _InkPart(const Offset(71, 83), .0065, -1.89, const [
    Offset(0, 18),
    Offset(116, 18),
    Offset(101, 94),
    Offset(87, 132),
    Offset(84, 191),
    Offset(0, 191),
  ]),
  LiteWeapon.arco: _InkPart(const Offset(75, 102), .007, 2.34, const [
    Offset(0, 0),
    Offset(192, 0),
    Offset(192, 46),
    Offset(158, 56),
    Offset(131, 65),
    Offset(108, 95),
    Offset(72, 133),
    Offset(52, 178),
    Offset(0, 192),
  ]),
  LiteWeapon.scettro: _InkPart(const Offset(76, 119), .010, .96),
  LiteWeapon.falceRunica: _InkPart(const Offset(57, 120), .0103, .81),
  LiteWeapon.doppieLame: _InkPart(const Offset(62, 132), .0083, .98, const [
    Offset(0, 0),
    Offset(135, 0),
    Offset(122, 79),
    Offset(104, 85),
    Offset(88, 100),
    Offset(76, 122),
    Offset(64, 185),
    Offset(0, 191),
  ]),
  LiteWeapon.carabinaImpulsi: _InkPart(const Offset(60, 154), .0102, .37),
};
final _inkShield = _InkPart(const Offset(121, 125), .0084, 0, const [
  Offset(94, 73),
  Offset(180, 73),
  Offset(181, 187),
  Offset(69, 187),
  Offset(73, 115),
]);
final _inkOffGlove = _InkPart(const Offset(140, 84), .0064, -1.92, const [
  Offset(116, 18),
  Offset(191, 18),
  Offset(191, 191),
  Offset(84, 191),
  Offset(87, 132),
  Offset(101, 94),
]);
final _inkOffDagger = _InkPart(const Offset(109, 144), .0083, .98, const [
  Offset(135, 0),
  Offset(192, 0),
  Offset(192, 192),
  Offset(64, 192),
  Offset(76, 122),
  Offset(88, 100),
  Offset(104, 85),
  Offset(122, 79),
]);
final _inkGearSampler = Paint()..filterQuality = FilterQuality.medium;

void _drawInkPart(
  Canvas canvas,
  ui.Image art,
  _InkPart part, {
  Offset at = Offset.zero,
  double angle = 0,
}) {
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(angle + part.rotation);
  canvas.scale(part.size);
  canvas.translate(-part.pivot.dx, -part.pivot.dy);
  final mask = part.mask;
  if (mask != null) canvas.clipPath(mask);
  canvas.drawImageRect(
    art,
    Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()),
    const Rect.fromLTWH(0, 0, 192, 192),
    _inkGearSampler,
  );
  canvas.restore();
}

void _holdWeapon(
  Canvas canvas,
  LiteWeapon weapon,
  ui.Image? art,
  Color trim,
  Color ink,
) {
  if (art == null) {
    if (weapon == LiteWeapon.arco) canvas.translate(-.55, .032);
    _weapon(canvas, weapon, trim, ink);
    return;
  }
  _drawInkPart(canvas, art, _inkWeapons[weapon]!);
}

Offset _inkContact(LiteWeapon weapon, Offset pixel) {
  final part = _inkWeapons[weapon]!;
  return _rotated((pixel - part.pivot) * part.size, part.rotation);
}

void _paintBowDraw(Canvas canvas, Offset draw, {required bool showArrow}) {
  final a = _inkContact(LiteWeapon.arco, const Offset(36, 169));
  final b = _inkContact(LiteWeapon.arco, const Offset(156, 37));
  _lines(canvas, [a, draw, b], const Color(0xffe4c595), .019);
  if (!showArrow) return;
  _lines(
    canvas,
    [draw, const Offset(.61, -.021)],
    const Color(0xffac7b56),
    .027,
  );
  _poly(
    canvas,
    const [Offset(.53, -.062), Offset(.69, -.017), Offset(.53, .025)],
    const Color(0xffd1c7ab),
    stroke: _actorInk,
    width: .016,
  );
}

final _evasorBody = Path()
  ..fillType = PathFillType.evenOdd
  ..addRect(const Rect.fromLTWH(0, 0, 336, 336))
  ..addPolygon(const [
    Offset(98, 139),
    Offset(121, 133),
    Offset(144, 147),
    Offset(145, 182),
    Offset(120, 205),
    Offset(95, 190),
  ], true)
  ..addPolygon(const [
    Offset(199, 129),
    Offset(217, 121),
    Offset(245, 140),
    Offset(261, 183),
    Offset(242, 206),
    Offset(206, 185),
  ], true);
final _duplicatorBody = Path()
  ..fillType = PathFillType.evenOdd
  ..addRect(const Rect.fromLTWH(0, 0, 336, 336))
  ..addPolygon(const [
    Offset(110, 133),
    Offset(144, 131),
    Offset(162, 150),
    Offset(174, 194),
    Offset(148, 213),
    Offset(121, 180),
  ], true)
  ..addPolygon(const [
    Offset(231, 125),
    Offset(264, 127),
    Offset(299, 155),
    Offset(313, 203),
    Offset(276, 221),
    Offset(243, 197),
  ], true);

void _armedFigure(Canvas canvas, ui.Image art, LiteHero hero, bool ghost) {
  const height = 2.28;
  const width = height * _isometricY;
  final cell = art.width / 2;
  canvas.save();
  canvas.translate(-width * .54, -height * .958);
  canvas.scale(width / 336, height / 336);
  canvas.clipPath(hero == LiteHero.evasore ? _evasorBody : _duplicatorBody);
  final paint = Paint()..filterQuality = FilterQuality.medium;
  if (ghost) {
    paint.colorFilter = const ColorFilter.mode(
      Color(0x768f6fc7),
      BlendMode.srcATop,
    );
  }
  canvas.drawImageRect(
    art,
    Rect.fromLTWH(0, 0, cell, cell),
    const Rect.fromLTWH(0, 0, 336, 336),
    paint,
  );
  canvas.restore();
}

void _brushShape(
  Canvas canvas,
  Path path,
  Color fill,
  Color ink,
  double width,
) {
  canvas.drawPath(path, Paint()..color = fill);
  canvas.drawPath(
    path,
    Paint()
      ..color = ink
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..style = PaintingStyle.stroke,
  );
}

Offset _rotated(Offset offset, double angle) {
  final cosine = math.cos(angle);
  final sine = math.sin(angle);
  return Offset(
    offset.dx * cosine - offset.dy * sine,
    offset.dy * cosine + offset.dx * sine,
  );
}

void _paintClonatorePose(
  Canvas canvas,
  ui.Image atlas,
  ui.Image? heads,
  LiteWeapon weapon,
  OculumLiteAppearance appearance, {
  required bool spectral,
  LiteStride? stride,
  double animationLead = 0,
  double? attackElapsed,
}) {
  final frame = switch (weapon) {
    LiteWeapon.spadaScudo => 0,
    LiteWeapon.arco => 1,
    LiteWeapon.guanti => 2,
    LiteWeapon.scettro => 3,
    LiteWeapon.boomerang || LiteWeapon.chakram => 4,
    LiteWeapon.falceRunica || LiteWeapon.piccaOssidiana => 5,
    LiteWeapon.doppieLame => 6,
    LiteWeapon.carabinaImpulsi ||
    LiteWeapon.balestraRunica ||
    LiteWeapon.fucileScostubandito => 7,
  };
  const cell = 384.0;
  final feminine = appearance.usesFeminineAtlas;
  final height = feminine
      ? 3.25
      : frame == 0 || frame == 4
      ? 3.84
      : 3.46;
  final (breadth, stature) = switch (appearance.body) {
    OculumLiteBody.masculine || OculumLiteBody.feminine => (1.0, 1.0),
    OculumLiteBody.androgynous => (.91, 1.04),
    OculumLiteBody.stocky => (1.16, .92),
    OculumLiteBody.longlimbed => (.86, 1.12),
  };
  final spriteHeight = height * stature;
  final width = height * _isometricY * breadth * (.87 + appearance.frame * .26);
  final source = Rect.fromLTWH(frame % 4 * cell, frame ~/ 4 * cell, cell, cell);
  final landed = (attackElapsed ?? .25).clamp(0.0, .25);
  final recoil = attackElapsed == null ? 0.0 : (1 - landed / .25) * .11;
  final rig = _inkHeroFeet[feminine]![frame];
  final phase = _stridePhase(stride, rig.strideMetres, animationLead);
  final strength =
      (stride?.strength ?? 0.0) * (attackElapsed == null ? 1 : .65);
  final contact = (feminine ? 372 : 350) / cell;
  final heightWithWeight =
      spriteHeight * (1 - _stepCompression(phase) * strength);
  final destination = Rect.fromLTWH(
    -width * (183 / cell) + recoil,
    -heightWithWeight * contact,
    width,
    heightWithWeight,
  );
  final ink = Paint()..filterQuality = FilterQuality.medium;
  if (spectral) {
    _oval(
      canvas,
      const Offset(0, .01),
      1.26,
      .32,
      const Color(0x357d5baa),
      stroke: const Color(0xff76588d),
    );
    ink.colorFilter = const ColorFilter.mode(
      Color(0xff9474ba),
      BlendMode.modulate,
    );
  }
  final customHead =
      heads != null && !_hasDefaultAppearance(appearance, LiteHero.duplicatore);
  if (!customHead && !weapon.isBossLoot) {
    _inkActorSprite(
      canvas,
      atlas,
      source,
      destination,
      ink,
      rig,
      phase: phase,
      strength: strength,
      clothFlow: strength,
    );
    return;
  }
  final necks = feminine
      ? const [
          Offset(198, 164),
          Offset(184, 110),
          Offset(238, 107),
          Offset(194, 132),
          Offset(212, 180),
          Offset(182, 174),
          Offset(234, 140),
          Offset(194, 145),
        ]
      : const [
          Offset(231, 205),
          Offset(186, 174),
          Offset(215, 180),
          Offset(184, 179),
          Offset(229, 198),
          Offset(178, 191),
          Offset(235, 180),
          Offset(168, 171),
        ];
  final neck = necks[frame];
  canvas.save();
  canvas.translate(destination.left, destination.top);
  canvas.scale(width / cell, spriteHeight / cell);
  final originalHead = Path()
    ..addPolygon([
      neck + const Offset(-72, -42),
      neck + const Offset(-29, -67),
      neck + const Offset(31, -67),
      neck + const Offset(37, -21),
      neck + const Offset(19, -7),
      neck + const Offset(4, 0),
      neck + const Offset(-9, -6),
      neck + const Offset(-36, -8),
      neck + const Offset(-86, -12),
    ], true);
  if (feminine && frame == 4) {
    // This pose has a loose braid reaching past the regular hair silhouette.
    originalHead.addPolygon(const [
      Offset(73, 171),
      Offset(79, 153),
      Offset(101, 145),
      Offset(133, 143),
      Offset(151, 138),
      Offset(150, 160),
      Offset(132, 165),
      Offset(94, 171),
      Offset(84, 185),
      Offset(73, 184),
    ], true);
  }
  canvas.save();
  canvas.clipPath(
    Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(const Rect.fromLTWH(0, 0, cell, cell))
      ..addPath(customHead ? originalHead : Path(), Offset.zero)
      ..addPath(
        weapon.isBossLoot ? _oldWeaponSilhouette(weapon, feminine) : Path(),
        Offset.zero,
      ),
  );
  _inkActorSprite(
    canvas,
    atlas,
    source,
    const Rect.fromLTWH(0, 0, cell, cell),
    ink,
    rig,
    phase: phase,
    strength: strength,
    clothFlow: strength,
  );
  if (!spectral && appearance.cloth != const OculumLiteAppearance().cloth) {
    _paintCapeDye(
      canvas,
      atlas,
      source,
      neck,
      appearance.cloth,
      cell,
      rig: rig,
      phase: phase,
      strength: strength,
    );
  }
  canvas.restore();
  if (weapon.isBossLoot) _paintBossWeaponAtGrip(canvas, weapon, feminine);
  if (!customHead) {
    canvas.restore();
    return;
  }

  final defaults = const OculumLiteAppearance();
  if (appearance.outfit != defaults.outfit ||
      appearance.cloth != defaults.cloth ||
      appearance.accent != defaults.accent ||
      appearance.emblem != defaults.emblem) {
    _paintCostumeLayers(
      canvas,
      neck + const Offset(-14, 21),
      appearance,
      spectral: spectral,
      compact: frame == 0 || frame == 1 || frame == 7,
    );
  }

  final goblin = appearance.lineage == OculumLiteLineage.goblin;
  final family = goblin ? 1 : 0;
  const headCell = 280.0;
  final hairIndex = feminine
      ? switch (appearance.hairstyle) {
          OculumLiteHair.tied => 0,
          OculumLiteHair.shaggy => 1,
          _ => 2,
        }
      : appearance.hairstyle.needsPaintedSilhouette
      ? OculumLiteHair.cropped.index
      : appearance.hairstyle.index;
  final cut = Rect.fromLTWH(
    hairIndex * headCell,
    family * headCell,
    headCell,
    headCell,
  );
  final (faceWidth, faceHeight) = switch (appearance.face) {
    OculumLiteFace.angular => (1.0, 1.0),
    OculumLiteFace.rounded => (1.08, .92),
    OculumLiteFace.strong => (1.13, 1.03),
    OculumLiteFace.gaunt => (.88, 1.08),
    OculumLiteFace.square => (1.19, .91),
    OculumLiteFace.soft => (.95, .92),
  };
  final headWidth = (goblin ? 69 + appearance.ears * 12 : 68.0) * faceWidth;
  final headHeight = (feminine ? 63 : 61) * faceHeight;
  final head = Rect.fromLTWH(
    neck.dx - headWidth * .64,
    neck.dy - headHeight + 4,
    headWidth,
    headHeight,
  );
  final eyes = switch ((feminine, goblin)) {
    (true, false) => const [
      Offset(.74, .42),
      Offset(.73, .435),
      Offset(.64, .42),
    ],
    (true, true) => const [
      Offset(.74, .44),
      Offset(.68, .445),
      Offset(.66, .44),
    ],
    (false, false) => const [
      Offset(.69, .435),
      Offset(.72, .457),
      Offset(.64, .438),
    ],
    (false, true) => const [
      Offset(.76, .40),
      Offset(.70, .376),
      Offset(.67, .43),
    ],
  };
  _paintFaceLayers(
    canvas,
    heads,
    cut,
    head,
    appearance,
    iris: eyes[hairIndex],
    spectral: spectral,
  );
  canvas.restore();
}

void _paintAshley(
  Canvas canvas,
  ui.Image atlas,
  int frame,
  ui.Image? gear,
  LiteWeapon weapon,
  Offset aim, {
  LiteStride? stride,
  double animationLead = 0,
  double springRemaining = 0,
}) {
  const left = [.086, .52, .039, .441];
  const top = [.015, .020, .56, .515];
  const right = [.393, .868, .372, .957];
  const bottom = [.492, .482, .986, .987];
  final source = Rect.fromLTRB(
    left[frame] * atlas.width,
    top[frame] * atlas.height,
    right[frame] * atlas.width,
    bottom[frame] * atlas.height,
  );
  final width = 2.48 * _isometricY * source.width / source.height;
  final spring = frame == 3;
  final rig = spring ? _inkAshleySpring : _inkAshley;
  final phase = stride == null
      ? 0.0
      : _stridePhase(stride, rig.strideMetres, animationLead);
  _inkActorSprite(
    canvas,
    atlas,
    source,
    Rect.fromLTWH(-width * (frame == 3 ? .42 : .51), -2.48, width, 2.48),
    Paint()..filterQuality = FilterQuality.medium,
    rig,
    phase: phase,
    strength: frame <= 1 ? stride?.strength ?? 0 : 0,
    compress: frame <= 1
        ? _stepCompression(phase) * (stride?.strength ?? 0)
        : 0,
    recoilArm: spring ? (1 - springRemaining / .28).clamp(0.0, 1.0) : 0,
  );
  if (frame <= 1 && weapon != LiteWeapon.guanti) {
    final hand = frame == 0
        ? Offset(-width * .20, -1.15)
        : Offset(-width * .23, -1.60);
    canvas.save();
    canvas.translate(hand.dx, hand.dy);
    canvas.rotate(aim.direction.clamp(-.34, .38));
    canvas.scale(.63);
    _holdWeapon(canvas, weapon, gear, _sand, _ink);
    canvas.restore();
  }
}

void _paintPlagueForm(
  Canvas canvas,
  LiteWeapon weapon,
  ui.Image? gear,
  LiteStride? stride,
  double time,
  bool fallen,
  bool giant,
  Offset aim,
) {
  if (fallen) canvas.rotate(-1.25);
  if (giant) canvas.scale(1.57);
  canvas.translate(0, math.sin(time * 3.4) * .019);
  const cloak = Color(0xff363040);
  const edge = Color(0xff655267);
  const bone = Color(0xffd1b894);
  const glint = Color(0xffaef3ae);
  if (giant) {
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.scale(side, 1);
      canvas.rotate(side * math.sin(time * 8) * .10);
      _poly(
        canvas,
        const [
          Offset(0, -1.21),
          Offset(.68, -2.19),
          Offset(1.49, -2.25),
          Offset(1.20, -1.93),
          Offset(1.79, -2.02),
          Offset(1.36, -1.53),
          Offset(1.74, -1.64),
          Offset(1.22, -1.02),
          Offset(1.52, -1.15),
          Offset(.90, -.70),
          Offset(.27, -.82),
        ],
        cloak,
        stroke: _ink,
      );
      _poly(canvas, const [
        Offset(.27, -1.28),
        Offset(.67, -2.04),
        Offset(1.38, -2.17),
        Offset(.79, -1.85),
        Offset(.65, -1.32),
      ], edge);
      canvas.restore();
    }
  }
  final step =
      math.sin((stride?.distance ?? 0) * 8) * (stride?.strength ?? 0) * .19;
  for (final side in [-1.0, 1.0]) {
    final foot = Offset(side * .23 + side * step, -.03);
    _poly(canvas, [
      Offset(side * .13, -.88),
      Offset(side * .32, -.85),
      foot + const Offset(.16, -.09),
      foot + const Offset(.21, .02),
      foot + const Offset(-.12, .02),
    ], _ink);
  }
  _poly(
    canvas,
    const [
      Offset(-.32, -1.49),
      Offset(.12, -1.58),
      Offset(.44, -1.37),
      Offset(.34, -.87),
      Offset(.55, -.13),
      Offset(.18, -.25),
      Offset(.04, -.09),
      Offset(-.15, -.41),
      Offset(-.55, -.22),
      Offset(-.37, -.79),
      Offset(-.51, -1.11),
    ],
    cloak,
    stroke: _ink,
  );
  _poly(canvas, const [
    Offset(-.39, -1.34),
    Offset(-.21, -1.45),
    Offset(.15, -1.29),
    Offset(.26, -.77),
    Offset(.11, -.86),
    Offset(-.09, -1.19),
    Offset(-.20, -.62),
  ], edge);
  _poly(canvas, const [
    Offset(-.34, -1.62),
    Offset(-.27, -2.06),
    Offset(.02, -2.19),
    Offset(.25, -2.08),
    Offset(.33, -1.84),
    Offset(.14, -1.54),
    Offset(-.18, -1.52),
  ], _ink);
  _poly(
    canvas,
    [
      const Offset(-.08, -1.98),
      const Offset(.21, -2.05),
      const Offset(.33, -1.91),
      Offset(giant ? .77 : .56, -1.71),
      const Offset(.49, -1.65),
      const Offset(.16, -1.71),
      const Offset(-.02, -1.83),
    ],
    bone,
    stroke: _ink,
    width: .043,
  );
  _poly(canvas, const [
    Offset(.12, -1.94),
    Offset(.27, -1.97),
    Offset(.29, -1.86),
    Offset(.14, -1.87),
  ], _ink);
  _oval(canvas, const Offset(.223, -1.917), .038, .024, glint);
  if (fallen) return;
  canvas.save();
  canvas.translate(.38, -.94);
  canvas.rotate(aim.direction.clamp(-.65, .55));
  canvas.scale(.66);
  _holdWeapon(canvas, weapon, gear, glint, cloak);
  canvas.restore();
}

void _paintSkeleton(
  Canvas canvas,
  LiteClone clone,
  ui.Image? gear,
  double time,
) {
  if (clone.down) canvas.rotate(-1.25);
  const bone = Color(0xffdfcd9e);
  const shadow = Color(0xff69555e);
  final step = math.sin(clone.stride.distance * 8) * clone.stride.strength;
  void boneLine(Offset from, Offset to, [double width = .095]) {
    for (final (color, size) in [(_ink, width + .043), (bone, width)]) {
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = color
          ..strokeWidth = size
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  for (final side in [-1.0, 1.0]) {
    final knee = Offset(.18 * side + step * side * .12, -.38);
    boneLine(Offset(.11 * side, -.79), knee);
    boneLine(knee, Offset(.22 * side + step * side * .22, -.07));
  }
  boneLine(const Offset(0, -.75), const Offset(.03, -1.48), .12);
  for (var i = 0; i < 3; i++) {
    final at = -1.38 + i * .14;
    _oval(
      canvas,
      Offset(.026, at),
      .37 - i * .05,
      .12,
      shadow,
      stroke: bone,
      strokeWidth: .049,
    );
  }
  _oval(canvas, const Offset(.08, -1.65), .37, .40, bone, stroke: _ink);
  _oval(canvas, const Offset(.16, -1.68), .13, .08, _ink);
  _oval(canvas, const Offset(.18, -1.68), .048, .033, _active);
  _poly(canvas, const [
    Offset(.04, -1.53),
    Offset(.23, -1.53),
    Offset(.18, -1.46),
    Offset(.06, -1.46),
  ], shadow);
  final hand = Offset(.35 + clone.swing * .39, -1.07 - clone.swing * .48);
  boneLine(const Offset(-.14, -1.35), const Offset(-.25, -1.09));
  boneLine(const Offset(-.25, -1.09), const Offset(.13, -1.04));
  boneLine(const Offset(.13, -1.36), hand);
  canvas.save();
  canvas.translate(hand.dx, hand.dy);
  canvas.rotate(-.26 - clone.swing + math.sin(time * 2) * .025);
  canvas.scale(.72);
  _holdWeapon(canvas, clone.weapon, gear, bone, shadow);
  canvas.restore();
}

int? _nightHeroRow(LiteHero hero, bool unleashed) => switch (hero) {
  LiteHero.cavaliereLunare => 0,
  LiteHero.slimeBlu => 3,
  LiteHero.vampiro => unleashed ? 5 : 4,
  LiteHero.reGoblin => 8,
  _ => null,
};

int? _nightEnemyRow(LiteEnemyKind kind) => switch (kind) {
  LiteEnemyKind.guardiaLunare => 1,
  LiteEnemyKind.guardianoLunare || LiteEnemyKind.custodeLunare => 2,
  LiteEnemyKind.eliteLunare => 0,
  LiteEnemyKind.lupoLunare => 6,
  LiteEnemyKind.gablyn => 7,
  LiteEnemyKind.reGoblin => 8,
  LiteEnemyKind.goblinColtello => 9,
  LiteEnemyKind.goblinFango || LiteEnemyKind.goblinColla => 10,
  _ => null,
};

void _paintNightLink(
  Canvas canvas,
  LiteRun run,
  LiteNightVisual night,
  math.Point<double> at,
  double time,
) {
  if (night.absorb <= 0 || night.targetId == null) return;
  final victim = run.enemies
      .where((enemy) => enemy.id == night.targetId && enemy.hp > 0)
      .firstOrNull;
  if (victim == null) return;
  final origin = _offset(at) - const Offset(0, .72);
  final tip = _offset(victim.position) - const Offset(0, .45);
  final sway = math.sin(time * 12) * .21;
  final bend = Offset.lerp(origin, tip, .55)! + Offset(0, sway - .18);
  _lines(canvas, [origin, bend, tip], const Color(0xdc14374e), .19);
  _lines(canvas, [origin, bend, tip], const Color(0xff81def4), .061);
  for (var i = 0; i < 4; i++) {
    final bead = Offset.lerp(tip, origin, (time * 2.2 + i * .25) % 1)!;
    canvas.drawCircle(bead, .058, Paint()..color = const Color(0xffb2f4ff));
  }
}

void _paintBat(Canvas canvas, double time) {
  final a = math.sin(time * 21) * .32;
  final h = -1.32 + math.sin(time * 10) * .14;
  final at = Offset(0, h);
  for (final side in [-1.0, 1.0]) {
    _poly(
      canvas,
      [
        at,
        Offset(.34 * side, h - .18 - a),
        Offset(.92 * side, h - .41 - a),
        Offset(.64 * side, h + .19),
        Offset(.34 * side, h + .13),
        Offset(.24 * side, h + .28),
      ],
      const Color(0xff692c50),
      stroke: const Color(0xff1b1021),
      width: .055,
    );
  }
  _oval(
    canvas,
    at,
    .23,
    .34,
    const Color(0xff282131),
    stroke: const Color(0xffbd5375),
    strokeWidth: .045,
  );
  canvas.drawCircle(
    at + const Offset(.10, -.10),
    .041,
    Paint()..color = const Color(0xffff627b),
  );
}

int? _newHeroRow(LiteHero hero, bool giant) => switch (hero) {
  LiteHero.curatorePeste => giant ? 1 : 0,
  LiteHero.pyrel => 6,
  LiteHero.lithra => 7,
  LiteHero.luce => 8,
  LiteHero.ombra => 9,
  LiteHero.doppelganger => 10,
  _ => null,
};

int? _newCreatureRow(LiteEnemyKind kind) => switch (kind) {
  LiteEnemyKind.rasvyr => 4,
  LiteEnemyKind.orbryx => 5,
  _ => null,
};

int _newFrame(
  LiteStride? stride,
  double animationLead, {
  bool preparing = false,
  bool hitting = false,
}) {
  if (hitting) return 3;
  if (preparing) return 2;
  return _strideFrame(stride, 1.55, animationLead);
}

int _strideFrame(
  LiteStride? stride,
  double strideMetres,
  double animationLead,
) {
  if ((stride?.speed ?? 0) < .08 || (stride?.strength ?? 0) < .08) {
    return 0;
  }
  final phase = _stridePhase(stride, strideMetres, animationLead);
  return math.cos(phase * 2) < 0 ? 1 : 0;
}

void _newActor(
  Canvas canvas,
  ui.Image art,
  int row,
  int frame, {
  required double height,
  LiteStride? stride,
  double animationLead = 0,
  bool fallen = false,
  bool phantom = false,
}) {
  canvas.save();
  if (fallen) {
    canvas.rotate(1.24);
    canvas.scale(.73);
  } else if (frame <= 1) {
    _groundedMotion(canvas, stride, animationLead, strideMetres: 1.55);
  }
  final dest = Rect.fromLTWH(
    -height * .75,
    -height * .967,
    height * 1.5,
    height,
  );
  canvas.drawImageRect(
    art,
    Rect.fromLTWH(360.0 * frame, 240.0 * row, 360, 240),
    dest,
    Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color(phantom ? 0xc0ffffff : 0xffffffff),
  );
  canvas.restore();
}

void _paintFissure(
  Canvas canvas,
  ui.Picture floor,
  LiteCombatImpact impact,
  double time,
) {
  final from = _offset(impact.position);
  final end = _offset(impact.end!);
  final span = end - from;
  final distance = span.distance;
  if (distance < .1) return;
  final side = Offset(-span.dy, span.dx) / distance;
  final age = time - impact.time;
  final progress = (age / .13).clamp(.10, 1.0);
  final alpha = ((LiteRun.combatImpactDuration - age) / .29).clamp(0.0, 1.0);
  if (alpha == 0) return;
  final random = math.Random(impact.subjectId);
  final rim = <Offset>[];
  final far = <Offset>[];
  for (var i = 0; i <= 12; i++) {
    final t = i / 12;
    final at = from + span * (progress * t);
    final width =
        math.pow(math.sin(math.pi * t), .7) * (.20 + random.nextDouble() * .36);
    rim.add(at + side * width);
    far.add(at - side * (width * .78));
  }
  final gap = [...rim, ...far.reversed];
  _poly(canvas, gap, _ink.withValues(alpha: alpha * .93));
  final edge = [
    for (var i = 0; i < rim.length; i++)
      rim[i] +
          side *
              (i == 0 || i == rim.length - 1
                  ? 0
                  : .13 + random.nextDouble() * .36),
  ];
  final lips = [...rim, ...edge.reversed];
  final cut = Path()..addPolygon(lips, true);
  canvas.save();
  canvas.clipPath(cut);
  canvas.translate(side.dx * .22, side.dy * .22 - .15);
  canvas.drawPicture(floor);
  canvas.restore();
  for (var i = 1; i < rim.length - 1; i++) {
    final seam = Offset.lerp(rim[i], far[i], .72)!;
    final next = Offset.lerp(rim[i + 1], far[i + 1], .43)!;
    _poly(
      canvas,
      [rim[i], rim[i + 1], next, seam],
      (i.isEven ? const Color(0xff352833) : const Color(0xff291c2c)).withValues(
        alpha: alpha * .91,
      ),
    );
    if (i.isEven) {
      _lines(
        canvas,
        [rim[i], Offset.lerp(rim[i], seam, .72)!],
        const Color(0xff7f635c).withValues(alpha: alpha * .72),
        .034,
      );
    }
  }
  _lines(canvas, rim, const Color(0xff4e3d47).withValues(alpha: alpha), .068);
  _lines(
    canvas,
    edge,
    const Color(0xffb3a28d).withValues(alpha: alpha * .70),
    .036,
  );
  for (var i = 2; i < rim.length - 1; i += 2) {
    final at = rim[i];
    _lines(
      canvas,
      [at, at + side * .42 - span / 32, at + side * .71 - span / 28],
      _ink.withValues(alpha: alpha * .81),
      .054,
    );
  }
}

void _bombBurst(Canvas canvas, Offset at, double age) {
  final progress = (age / .44).clamp(0.0, 1.0);
  if (progress >= 1) return;
  final radius = 2.65 * math.sqrt(progress);
  _oval(
    canvas,
    at,
    radius,
    radius,
    _ember.withValues(alpha: .16 * (1 - progress)),
    stroke: _sand.withValues(alpha: .8 * (1 - progress)),
    strokeWidth: .12,
  );
  for (var i = 0; i < 12; i++) {
    final angle = i * math.pi / 6;
    final dir = Offset(math.cos(angle), math.sin(angle));
    _lines(
      canvas,
      [at + dir * (radius * .48), at + dir * (radius * 1.13)],
      _ember.withValues(alpha: .9 * (1 - progress)),
      .06,
    );
  }
}

void _animalSprite(
  Canvas canvas,
  ui.Image art,
  LiteAnimal animal,
  LiteStride? stride,
  double animationLead,
  bool attacking,
  bool talent, {
  bool hero = false,
  bool fallen = false,
}) {
  final side = art.width / 4.0;
  final frame = talent
      ? 3
      : attacking
      ? 2
      : _strideFrame(stride, .92, animationLead);
  final size = hero ? 2.4 : 1.47;
  canvas.save();
  if (fallen) {
    canvas.rotate(-.68);
  } else if (!attacking && !talent) {
    _groundedMotion(canvas, stride, animationLead, strideMetres: .92);
  }
  canvas.drawImageRect(
    art,
    Rect.fromLTWH(frame * side, animal.index * side, side, side),
    Rect.fromLTWH(-size / 2, -size, size, size),
    Paint()..filterQuality = FilterQuality.medium,
  );
  canvas.restore();
}

void _hero(
  Canvas canvas,
  OculumLiteAppearance appearance,
  LiteWeapon weapon,
  double time, {
  required LiteHero hero,
  ui.Image? banditArt,
  ui.Image? newActors,
  ui.Image? bossArt,
  LiteMimicForm? mimic,
  ui.Image? nightActors,
  ui.Image? faunaActors,
  ui.Image? mechanicalChicken,
  ui.Image? solarActors,
  ui.Image? infernalActors,
  LiteNightVisual? night,
  bool preparingTalent = false,
  double punchPose = 0,
  ui.Image? gearArt,
  ui.Image? figureArt,
  ui.Image? poseArt,
  ui.Image? heads,
  bool clone = false,
  bool phantom = false,
  bool fallen = false,
  bool giant = false,
  bool front = true,
  bool moving = false,
  LiteStride? stride,
  double animationLead = 0,
  bool preparingAttack = false,
  double? attackElapsed,
  Offset aiming = const Offset(.9, .08),
}) {
  if ((night?.veil ?? 0) > 0 && hero == LiteHero.slimeBlu) return;
  if ((night?.bat ?? 0) > 0 && hero == LiteHero.vampiro && !fallen) {
    _paintBat(canvas, time);
    return;
  }
  if (hero.infernal && infernalActors != null) {
    final row = hero.index - LiteHero.demoneMinore.index;
    _solarActor(
      canvas,
      infernalActors,
      row,
      animationLead,
      stride,
      preparingAttack || preparingTalent ? .50 : 0,
      attackElapsed == null ? 0 : (.24 - attackElapsed).clamp(0, .24),
      0,
      hero: true,
      fallen: fallen,
      columns: 6,
    );
    return;
  }
  final solar = hero.solar ? hero.index - LiteHero.guardiaSolare.index : null;
  if (solar != null && solarActors != null) {
    _solarActor(
      canvas,
      solarActors,
      solar,
      animationLead,
      stride,
      preparingAttack || preparingTalent ? .5 : 0,
      attackElapsed == null ? 0 : (.24 - attackElapsed).clamp(0, .24),
      0,
      hero: true,
      fallen: fallen,
    );
    if ((night?.solarMace ?? 0) > 0) {
      _inkSlash(
        canvas,
        const Offset(.2, -.86),
        const Offset(.97, -1.64),
        const Color(0xffdfaa59),
        .12,
      );
      _poly(
        canvas,
        const [
          Offset(.86, -1.53),
          Offset(.84, -1.86),
          Offset(1.14, -1.94),
          Offset(1.29, -1.66),
        ],
        const Color(0xffedb96e),
        stroke: _ink,
      );
    }
    return;
  }
  if (hero == LiteHero.polloMeccanico && mechanicalChicken != null) {
    final frame = preparingTalent || punchPose > 0
        ? 3
        : attackElapsed != null
        ? 2
        : _strideFrame(stride, 1.16, animationLead);
    final cellWidth = mechanicalChicken.width / 4;
    final cellHeight = mechanicalChicken.height * .72;
    final source = Rect.fromLTWH(
      cellWidth * frame,
      mechanicalChicken.height * .15,
      cellWidth,
      cellHeight,
    );
    const height = 2.28;
    final width = height * cellWidth / cellHeight;
    canvas.save();
    if (fallen) {
      canvas.rotate(-.68);
    } else if (frame <= 1) {
      _groundedMotion(canvas, stride, animationLead, strideMetres: 1.16);
    }
    canvas.drawImageRect(
      mechanicalChicken,
      source,
      Rect.fromLTWH(-width / 2, -height, width, height),
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
    return;
  }
  final animal = LiteAnimal.forHero(hero);
  final body = mimic == null ? animal : LiteAnimal.forCreature(mimic.kind);
  if (faunaActors != null && body != null) {
    _animalSprite(
      canvas,
      faunaActors,
      body,
      stride,
      animationLead,
      attackElapsed != null,
      preparingTalent || punchPose > 0,
      hero: true,
      fallen: fallen,
    );
    return;
  }
  final nightRow = _nightHeroRow(hero, (night?.sanguine ?? 0) > 0);
  if (nightRow != null && nightActors != null) {
    final inBlood = nightRow == 5;
    if (inBlood) {
      _oval(
        canvas,
        Offset.zero,
        1.65,
        .98,
        const Color(0x49be274c),
        stroke: const Color(0xb6e34d68),
        strokeWidth: .04,
      );
    }
    final frame = _newFrame(
      stride,
      animationLead,
      preparing:
          hero == LiteHero.cavaliereLunare && preparingTalent ||
          preparingAttack,
      hitting:
          (night?.absorb ?? 0) > 0 ||
          attackElapsed != null && attackElapsed < .24,
    );
    _newActor(
      canvas,
      nightActors,
      nightRow,
      frame,
      height: inBlood
          ? 3.24
          : hero == LiteHero.slimeBlu
          ? 1.45
          : 2.58,
      stride: stride,
      animationLead: animationLead,
      fallen: fallen,
      phantom: phantom,
    );
    return;
  }
  if (mimic != null) {
    final copied = _nightEnemyRow(mimic.kind);
    if (copied != null && nightActors != null) {
      _newActor(
        canvas,
        nightActors,
        copied,
        _newFrame(stride, animationLead, hitting: attackElapsed != null),
        height: _enemyHeight(mimic.kind),
        stride: stride,
        animationLead: animationLead,
        fallen: fallen,
      );
      return;
    }
    final row = _newCreatureRow(mimic.kind);
    if (row != null && newActors != null) {
      _newActor(
        canvas,
        newActors,
        row,
        _newFrame(stride, animationLead, hitting: attackElapsed != null),
        height: _enemyHeight(mimic.kind),
        stride: stride,
        animationLead: animationLead,
        fallen: fallen,
      );
    } else if (banditArt == null ||
        !_paintMonster(
          canvas,
          banditArt,
          mimic.kind,
          0,
          stride ?? LiteStride(),
          time,
          animationLead,
          fallen: fallen,
          strike: attackElapsed == null ? 0 : .16,
        )) {
      _enemy(
        canvas,
        mimic.kind,
        fallen: fallen,
        time: time,
        cannonRaised: false,
      );
    }
    return;
  }
  final row = _newHeroRow(hero, giant);
  if (row != null && newActors != null) {
    final striking = attackElapsed != null && attackElapsed < .24;
    final frame = _newFrame(
      stride,
      animationLead,
      preparing: preparingAttack,
      hitting: striking || preparingTalent,
    );
    final height = giant ? 3.67 : 2.46;
    canvas.save();
    if (!fallen && frame <= 1) {
      _groundedMotion(canvas, stride, animationLead, strideMetres: 1.55);
    }
    _newActor(
      canvas,
      newActors,
      row,
      frame,
      height: height,
      fallen: fallen,
      phantom: phantom,
    );
    final kitWeapon =
        hero == LiteHero.curatorePeste ||
        hero == LiteHero.pyrel ||
        (hero != LiteHero.doppelganger && weapon != hero.fixedWeapon);
    if (kitWeapon && !giant && !fallen && !preparingTalent) {
      canvas.save();
      canvas.translate(frame == 3 ? .52 : .31, -.94);
      canvas.rotate(-.21 + aiming.dy.clamp(-1.0, 1.0) * .31);
      canvas.scale(.73);
      _holdWeapon(canvas, weapon, gearArt, const Color(0xffa48d73), _ink);
      canvas.restore();
    }
    canvas.restore();
    return;
  }
  if (hero == LiteHero.veyrth && bossArt != null) {
    final scale = bossArt.width / 896;
    _inkActorSprite(
      canvas,
      bossArt,
      Rect.fromLTWH(8 * scale, 136 * scale, 432 * scale, 304 * scale),
      const Rect.fromLTWH(-1.75, -2.42, 3.5, 2.46),
      Paint()..filterQuality = FilterQuality.medium,
      _inkVeyrth,
      phase: time * 5,
      strength: moving ? .82 : .44,
      grounded: false,
      anticipation: preparingAttack ? .8 : 0,
      strike: attackElapsed != null ? .65 : 0,
    );
    return;
  }
  if (hero == LiteHero.curatorePeste) {
    _paintPlagueForm(
      canvas,
      weapon,
      gearArt,
      stride,
      time,
      fallen,
      giant,
      aiming,
    );
    return;
  }
  if (hero.sprite case final kind?) {
    final isBandit = hero == LiteHero.scostubandito;
    final strike = attackElapsed == null
        ? 0.0
        : math.max(0.0, .24 - attackElapsed);
    final swinging = !fallen && punchPose > 0;
    if (swinging) canvas.translate(.19 * (punchPose / .24), 0);
    if (banditArt == null ||
        !_paintMonster(
          canvas,
          banditArt,
          kind,
          0,
          stride ?? LiteStride(),
          time,
          animationLead,
          fallen: fallen,
          strike: math.max(strike, punchPose),
          windup: hero == LiteHero.granScostumato && preparingAttack
              ? .16
              : null,
          hideRifleBarrel:
              isBandit &&
              !fallen &&
              (swinging || weapon != LiteWeapon.fucileScostubandito),
        )) {
      _enemy(canvas, kind, fallen: fallen, time: time, cannonRaised: false);
    }
    if (!fallen &&
        !swinging &&
        (isBandit
            ? weapon != LiteWeapon.fucileScostubandito
            : weapon != hero.fixedWeapon || hero != LiteHero.granScostumato)) {
      canvas.save();
      canvas.translate(.54, -.86);
      canvas.rotate(aiming.direction.clamp(-.48, .48));
      canvas.scale(.54);
      _holdWeapon(canvas, weapon, gearArt, _sand, _ink);
      canvas.restore();
    }
    return;
  }
  if (fallen) {
    canvas.translate(-.28, -.08);
    canvas.rotate(-1.30);
    canvas.scale(.86);
  } else if (attackElapsed != null && aiming.distanceSquared > .001) {
    final direction = aiming / aiming.distance;
    if (preparingAttack) {
      final hold = (attackElapsed / .42).clamp(0.0, 1.0);
      canvas.translate(-direction.dx * .13 * hold, -direction.dy * .10 * hold);
      canvas.rotate(-.075 * hold);
    } else {
      final release = weapon == LiteWeapon.guanti ? .32 : weapon.chargeSeconds;
      final impulse = (1 - (attackElapsed - release).abs() / .19).clamp(
        0.0,
        1.0,
      );
      final thrust =
          weapon == LiteWeapon.carabinaImpulsi ||
              weapon == LiteWeapon.balestraRunica
          ? -.13
          : .23;
      canvas.translate(
        direction.dx * thrust * impulse,
        direction.dy * thrust * impulse,
      );
      canvas.rotate(.075 * impulse);
    }
  }
  if (poseArt != null && hero == LiteHero.duplicatore) {
    _paintClonatorePose(
      canvas,
      poseArt,
      heads,
      weapon,
      appearance,
      spectral: clone || phantom,
      attackElapsed: attackElapsed,
      stride: stride,
      animationLead: animationLead,
    );
    return;
  }
  final ghost = clone || phantom;
  final lean = hero == LiteHero.evasore;
  final outfit = appearance.outfit;
  final armored = outfit == OculumLiteOutfit.cuirass;
  final cloaked = outfit == OculumLiteOutfit.cloak;
  final cadence = _stridePhase(stride, 1.65, animationLead);
  final pace = fallen ? 0.0 : stride?.strength ?? 0;
  final walkSwing = math.sin(cadence) * pace * .22;
  final breath = fallen
      ? 0.0
      : math.sin(time * 3.4) * .014 * (1 - pace) +
            _stepCompression(cadence) * pace * 1.6;
  final trim = ghost ? const Color(0xffd0b5ee) : appearance.accent;
  Color spirit(Color color) => ghost
      ? Color.lerp(
          color,
          const Color(0xff7b5fa5),
          clone ? .65 : .42,
        )!.withValues(alpha: clone ? .78 : .84)
      : color;
  final edge = ghost ? const Color(0xff423054) : _actorInk;
  final cloth = spirit(
    figureArt == null
        ? appearance.cloth
        : lean
        ? const Color(0xff51524b)
        : const Color(0xff59404d),
  );
  final light = Color.lerp(cloth, trim, .29)!;
  final fold = Color.lerp(cloth, _actorInk, .68)!;
  final skin = spirit(appearance.skin);
  final shadeSkin = Color.lerp(skin, const Color(0xff522b30), .55)!;
  final hair = spirit(appearance.hair);
  final hairGlint = Color.lerp(hair, trim, .25)!;
  final boot = spirit(_bootLeather);
  final bootEdge = spirit(_rimLeather);
  final shoulders = lean
      ? .31
      : armored
      ? .47
      : .40;
  final hip = lean ? -.05 : -.035;
  final shift = lean ? .115 : .018;
  final crown = (lean ? -1.99 : -2.10) + breath;
  final neck = (lean ? -1.43 : -1.51) + breath;
  final nearShoulder = figureArt == null
      ? Offset(shoulders + shift, neck + .23)
      : lean
      ? const Offset(.13, -1.37)
      : const Offset(.27, -1.37);
  final farShoulder = figureArt == null
      ? Offset(-shoulders + shift * .55, neck + .27)
      : lean
      ? const Offset(-.30, -1.40)
      : const Offset(-.26, -1.37);
  final heading = math.atan2(aiming.dy, aiming.dx).clamp(-.57, .48).toDouble();
  final swing = attackElapsed == null
      ? 0.0
      : (1 - attackElapsed / .24).clamp(0.0, 1.0);
  final chargedImpact = attackElapsed == null || preparingAttack
      ? 0.0
      : (1 - (attackElapsed - (weapon == LiteWeapon.guanti ? .32 : .43)) / .20)
            .clamp(0.0, 1.0);
  final bowRelease = weapon == LiteWeapon.arco && swing > .17;
  final bowDraw = Offset(-.55 + swing * .30, -.024 - swing * .05);
  final throwing = weapon.returns && swing > .22;
  final (nearGrip, farGrip, angle, offAngle) = switch (weapon) {
    LiteWeapon.arco => (
      Offset(.87 - swing * .06, -1.29 + breath),
      Offset.zero,
      heading,
      0.0,
    ),
    LiteWeapon.carabinaImpulsi ||
    LiteWeapon.balestraRunica ||
    LiteWeapon.fucileScostubandito => (
      Offset(.14 - chargedImpact * .09, -1.26 + breath),
      Offset.zero,
      heading - (preparingAttack ? .06 : .03) - chargedImpact * .18,
      0.0,
    ),
    LiteWeapon.falceRunica || LiteWeapon.piccaOssidiana => (
      Offset(.26 + swing * .42, -.83 - swing * .16 + breath),
      Offset.zero,
      heading * .45 - .92 + swing * 1.61,
      0.0,
    ),
    LiteWeapon.spadaScudo => (
      Offset(.36 + swing * .48, -.99 - swing * .07 + breath),
      Offset(-.46 + swing * .16, -1.02 + breath),
      heading * .78 - .55 + swing * .97,
      -.12,
    ),
    LiteWeapon.doppieLame => (
      Offset(.54 + swing * .31, -1.10 + swing * .21 + breath),
      Offset(-.35 + (preparingAttack ? 0 : swing * .82), -.81 + breath),
      heading * .60 - .25 + swing * .93,
      preparingAttack ? 2.2 : 2.2 - swing * 1.92,
    ),
    LiteWeapon.guanti => (
      Offset(
        (preparingAttack ? .25 : .47) + chargedImpact * .55,
        (preparingAttack ? -1.00 : -1.24) + breath,
      ),
      Offset(-.22 + chargedImpact * .14, -1.13 + breath),
      heading * .66 - .40 + chargedImpact * .52,
      -2.22,
    ),
    LiteWeapon.scettro => (
      Offset(.45 + swing * .23, -.89 - swing * .36 + breath),
      Offset(-.43, -.87 + breath),
      -1.19 + swing * 1.24 + heading * .62,
      0.0,
    ),
    LiteWeapon.boomerang || LiteWeapon.chakram => (
      Offset(.37 + swing * .52, -1.40 + swing * .28 + breath),
      Offset(-.42, -.90 + breath),
      heading * .64 - .64 + swing * .88,
      0.0,
    ),
  };
  // These contacts use the weapon's own rotated frame, so both hands stay on
  // the bowstring, barrel or shaft when the character aims or changes stance.
  final support = switch (weapon) {
    LiteWeapon.arco =>
      nearGrip +
          _rotated(
            gearArt == null ? bowDraw - const Offset(.14, -.03) : bowDraw,
            angle,
          ),
    LiteWeapon.carabinaImpulsi || LiteWeapon.balestraRunica =>
      nearGrip +
          _rotated(
            gearArt == null
                ? const Offset(.68, .068)
                : _inkContact(weapon, const Offset(125, 129)),
            angle,
          ),
    LiteWeapon.falceRunica || LiteWeapon.piccaOssidiana =>
      nearGrip +
          _rotated(
            gearArt == null
                ? const Offset(-.45, .30)
                : _inkContact(weapon, const Offset(42, 151)),
            angle,
          ),
    _ => farGrip,
  };
  final crossBodyGrip =
      weapon == LiteWeapon.arco ||
      weapon == LiteWeapon.carabinaImpulsi ||
      weapon == LiteWeapon.balestraRunica ||
      weapon == LiteWeapon.falceRunica ||
      weapon == LiteWeapon.piccaOssidiana;

  if (ghost) {
    _oval(
      canvas,
      const Offset(0, .01),
      1.34,
      .42,
      const Color(0x419c73d3),
      stroke: const Color(0xff72549c),
    );
    if (phantom) {
      _dryBrush(
        canvas,
        const Offset(-.82, -.37),
        const Offset(-.04, -.15),
        const Offset(-.43, .12),
        _active.withValues(alpha: .72),
        9,
        width: .047,
      );
    }
  }

  // Boots and ink shadow have support under the same feet seen at game scale.
  final cast = Path()
    ..moveTo(-.62, .08)
    ..quadraticBezierTo(-.43, -.15, -.10, -.13)
    ..lineTo(.25, -.12)
    ..lineTo(.70, -.06)
    ..lineTo(.47, .03)
    ..lineTo(.83, .12)
    ..lineTo(.42, .19)
    ..lineTo(.14, .17)
    ..lineTo(-.06, .25)
    ..quadraticBezierTo(-.48, .22, -.62, .08)
    ..close();
  canvas.drawPath(cast, Paint()..color = edge.withValues(alpha: .82));

  if (figureArt != null) {
    _armedFigure(canvas, figureArt, hero, ghost);
  } else {
    if (cloaked || !lean) {
      final hem = cloaked ? -.06 : -.44;
      final cape = Path()
        ..moveTo(-shoulders + .06, neck + .12)
        ..quadraticBezierTo(-.58, -1.29, -.64, -.94)
        ..quadraticBezierTo(-.78 - walkSwing * .84, -.60, -.98, hem - .09)
        ..lineTo(-.70, hem - .16)
        ..lineTo(-.79, hem + .07)
        ..lineTo(-.39, hem - .11)
        ..lineTo(-.48, hem + .02)
        ..quadraticBezierTo(-.21, -.26, .17, -.44)
        ..lineTo(.36, -1.26)
        ..close();
      _brushShape(canvas, cape, fold, edge, .063);
      _poly(canvas, [
        Offset(-shoulders + .075, neck + .18),
        const Offset(-.55, -1.29),
        const Offset(-.68, -.78),
        Offset(-.92 - walkSwing, hem - .15),
        Offset(-.60, hem - .26),
        const Offset(-.40, -.82),
        const Offset(-.29, -1.15),
      ], cloth);
      _poly(canvas, [
        const Offset(-.56, -.92),
        const Offset(-.61, -.71),
        Offset(-.72, hem - .19),
        Offset(-.55, hem - .30),
        const Offset(-.47, -.82),
      ], light.withValues(alpha: .78));
    }
    final stepBack = lean ? -.40 : -.29;
    final stepFront = lean ? .33 : .31;
    final lift = math.cos(cadence) * pace;
    final ankleBack = Offset(
      stepBack - walkSwing,
      (lean ? -.10 : -.06) - math.max(0, -lift) * .10,
    );
    final ankleFront = Offset(stepFront + walkSwing, -math.max(0, lift) * .10);
    _heroBoot(
      canvas,
      Offset(hip - .17, -.67),
      Offset(stepBack + .04, -.36),
      ankleBack,
      Color.lerp(boot, edge, .33)!,
      bootEdge,
      edge,
      lean,
    );
    _heroBoot(
      canvas,
      Offset(hip + .17, -.66),
      Offset(stepFront - .08, -.34),
      ankleFront,
      boot,
      bootEdge,
      edge,
      lean,
    );

    if (!crossBodyGrip) {
      _heroArm(
        canvas,
        farShoulder,
        Offset(farShoulder.dx - .09, -1.02 + breath),
        support,
        fold,
        trim,
        edge,
        narrow: lean,
      );
    }
    final chest = Path()
      ..moveTo(-shoulders + shift, neck + .11)
      ..quadraticBezierTo(-shoulders - .06, -1.15, -.27, -.79)
      ..lineTo(-.32, -.59)
      ..lineTo(-.15, -.53)
      ..lineTo(hip + .24, -.57)
      ..lineTo(.31, -.81)
      ..lineTo(nearShoulder.dx + .06, neck + .26)
      ..quadraticBezierTo(.28, neck + .06, -.05, neck + .08)
      ..close();
    _brushShape(canvas, chest, cloth, edge, .069);
    _poly(canvas, [
      Offset(nearShoulder.dx + .052, neck + .282),
      const Offset(.20, -.98),
      const Offset(.145, -.82),
      Offset(hip + .23, -.577),
      const Offset(-.12, -.545),
      const Offset(-.01, -.760),
      const Offset(-.28, -.755),
      const Offset(-.15, -.918),
      const Offset(.064, -.994),
    ], fold);
    _poly(canvas, [
      Offset(-shoulders + shift + .02, neck + .183),
      Offset(-.12, neck + .09),
      Offset(.31, neck + .21),
      const Offset(.21, -1.08),
      const Offset(-.19, -1.12),
      const Offset(-.32, -.935),
    ], light);
    if (armored) {
      final cuirass = stateColor(cloth, trim);
      _poly(
        canvas,
        const [
          Offset(-.34, -1.265),
          Offset(-.16, -1.35),
          Offset(.26, -1.31),
          Offset(.36, -1.15),
          Offset(.20, -.835),
          Offset(-.02, -.714),
          Offset(-.235, -.88),
        ],
        cuirass,
        stroke: edge,
        width: .06,
      );
      _poly(canvas, const [
        Offset(-.24, -1.22),
        Offset(.13, -1.266),
        Offset(.02, -1.12),
        Offset(.28, -1.168),
        Offset(.13, -.923),
        Offset(-.058, -.817),
        Offset(-.176, -.937),
        Offset(-.09, -1.094),
      ], fold);
      _lines(
        canvas,
        const [Offset(-.28, -1.25), Offset(-.16, -1.302), Offset(.183, -1.272)],
        trim,
        .033,
      );
      _dryBrush(
        canvas,
        const Offset(-.23, -1.12),
        const Offset(.064, .02),
        const Offset(.13, -.065),
        trim.withValues(alpha: .6),
        4,
      );
    } else {
      final clasp = lean ? const Offset(-.16, -1.23) : const Offset(.09, -1.31);
      final scarf = Path()
        ..moveTo(shift - .17, neck - .03)
        ..quadraticBezierTo(shift - .45, neck + .14, -.67, neck + .33)
        ..lineTo(-.94 + walkSwing * .4, neck + .29)
        ..lineTo(-.79, neck + .46)
        ..lineTo(-1.02 + walkSwing, neck + .58)
        ..lineTo(-.69, neck + .54)
        ..lineTo(-.46, neck + .39)
        ..quadraticBezierTo(-.05, neck + .22, .26, neck + .32)
        ..lineTo(.25, neck + .13)
        ..lineTo(.14, neck - .03)
        ..close();
      _brushShape(canvas, scarf, lean ? light : fold, edge, .06);
      _poly(canvas, [
        Offset(-.87 + walkSwing * .4, neck + .34),
        Offset(-.68, neck + .37),
        Offset(-.41, neck + .25),
        Offset(-.20, neck + .12),
        Offset(-.13, neck + .07),
        Offset(-.24, neck + .28),
        Offset(-.56, neck + .46),
        Offset(-.88, neck + .52),
      ], lean ? cloth : light);
      _oval(canvas, clasp, .149, .142, trim, stroke: edge, strokeWidth: .04);
      _poly(canvas, [
        clasp + const Offset(-.041, .009),
        clasp + const Offset(.009, -.049),
        clasp + const Offset(.05, .018),
        clasp + const Offset(-.013, .049),
      ], fold);
    }
    _poly(
      canvas,
      const [
        Offset(-.28, -.74),
        Offset(.24, -.655),
        Offset(.275, -.567),
        Offset(.12, -.581),
        Offset(-.315, -.642),
      ],
      boot,
      stroke: edge,
      width: .038,
    );
    _poly(
      canvas,
      const [
        Offset(-.065, -.705),
        Offset(.059, -.67),
        Offset(.055, -.584),
        Offset(-.06, -.596),
        Offset(-.097, -.631),
      ],
      trim,
      stroke: edge,
      width: .03,
    );

    _heroHead(
      canvas,
      Offset(shift, crown),
      front,
      lean,
      appearance.hairstyle,
      skin,
      shadeSkin,
      hair,
      hairGlint,
      trim,
      edge,
    );
  }

  if (crossBodyGrip || figureArt != null) {
    final elbow = switch (weapon) {
      LiteWeapon.arco => Offset(-.21, -1.045 + breath),
      LiteWeapon.carabinaImpulsi => Offset(-.10, -.875 + breath),
      LiteWeapon.falceRunica => Offset(-.44, -.855 + breath),
      _ => Offset(farShoulder.dx - .13, -1.08 + breath),
    };
    _heroArm(
      canvas,
      farShoulder,
      elbow,
      support,
      fold,
      trim,
      edge,
      narrow: lean,
    );
  }
  final elbow = switch (weapon) {
    LiteWeapon.carabinaImpulsi => Offset(.24, -.92 + breath),
    LiteWeapon.guanti => Offset(
      nearShoulder.dx + (preparingAttack ? -.11 : .18),
      -.88 - chargedImpact * .23 + breath,
    ),
    LiteWeapon.arco => Offset(
      (nearShoulder.dx + nearGrip.dx) / 2,
      (nearShoulder.dy + nearGrip.dy) / 2 + .035,
    ),
    _ => Offset(
      nearShoulder.dx + .13 + swing * .14,
      (nearShoulder.dy + nearGrip.dy) / 2 + .09,
    ),
  };
  _heroArm(
    canvas,
    nearShoulder,
    elbow,
    nearGrip,
    cloth,
    trim,
    edge,
    narrow: lean,
  );

  if (weapon == LiteWeapon.spadaScudo) {
    if (gearArt == null) {
      _heroShield(canvas, support, offAngle, trim, edge);
    } else {
      _drawInkPart(canvas, gearArt, _inkShield, at: support, angle: offAngle);
    }
  } else if (weapon == LiteWeapon.guanti || weapon == LiteWeapon.doppieLame) {
    if (gearArt == null) {
      _actor(canvas, support, .84, .84, () {
        canvas.rotate(offAngle);
        _weapon(canvas, weapon, trim, edge);
      });
    } else {
      _drawInkPart(
        canvas,
        gearArt,
        weapon == LiteWeapon.guanti ? _inkOffGlove : _inkOffDagger,
        at: support,
        angle: offAngle,
      );
    }
  }
  _actor(canvas, nearGrip, 1, 1, () {
    canvas.rotate(angle);
    if (!throwing) _holdWeapon(canvas, weapon, gearArt, trim, edge);
    if (weapon == LiteWeapon.arco && gearArt != null) {
      _paintBowDraw(canvas, bowDraw, showArrow: !bowRelease);
    }
  });
  if (weapon != LiteWeapon.guanti) {
    _heroGrip(
      canvas,
      nearGrip,
      math.atan2(nearGrip.dy - elbow.dy, nearGrip.dx - elbow.dx),
      skin,
      shadeSkin,
      edge,
      gesture: throwing
          ? _HandGesture.open
          : weapon == LiteWeapon.carabinaImpulsi
          ? _HandGesture.trigger
          : _HandGesture.grip,
    );
  }
  if (weapon != LiteWeapon.guanti && weapon != LiteWeapon.spadaScudo) {
    _heroGrip(
      canvas,
      support,
      weapon == LiteWeapon.arco ? angle - .18 : angle + .27,
      skin,
      shadeSkin,
      edge,
      gesture: switch (weapon) {
        LiteWeapon.arco => bowRelease ? _HandGesture.open : _HandGesture.pinch,
        LiteWeapon.boomerang ||
        LiteWeapon.chakram ||
        LiteWeapon.scettro => _HandGesture.open,
        _ => _HandGesture.grip,
      },
    );
  }
}

Color stateColor(Color cloth, Color trim) =>
    Color.lerp(cloth, Color.lerp(trim, const Color(0xff8b8585), .37), .54)!;

void _heroBoot(
  Canvas canvas,
  Offset hip,
  Offset knee,
  Offset ankle,
  Color leather,
  Color trim,
  Color ink,
  bool slender,
) {
  final w = slender ? .119 : .145;
  final foot = ankle + Offset(slender ? .21 : .26, -.004);
  final shape = Path()
    ..moveTo(hip.dx - w, hip.dy)
    ..quadraticBezierTo(
      knee.dx - w * 1.18,
      knee.dy - .145,
      knee.dx - w,
      knee.dy,
    )
    ..quadraticBezierTo(
      ankle.dx - w,
      ankle.dy - .13,
      ankle.dx - w,
      ankle.dy + .007,
    )
    ..quadraticBezierTo(
      ankle.dx - .025,
      ankle.dy + .042,
      foot.dx,
      foot.dy + .034,
    )
    ..quadraticBezierTo(
      foot.dx + .06,
      foot.dy - .017,
      foot.dx - .012,
      foot.dy - .061,
    )
    ..lineTo(ankle.dx + w * .57, ankle.dy - .095)
    ..lineTo(knee.dx + w, knee.dy - .005)
    ..quadraticBezierTo(
      knee.dx + w * 1.04,
      knee.dy - .14,
      hip.dx + w,
      hip.dy - .009,
    )
    ..close();
  _brushShape(canvas, shape, leather, ink, .063);
  _poly(canvas, [
    hip + Offset(-w * .43, .028),
    knee + Offset(w * .28, -.068),
    ankle + Offset(w * .27, -.09),
    foot + const Offset(0, -.026),
    ankle + Offset(-w * .54, .018),
    knee + Offset(-w * .58, .019),
  ], Color.lerp(leather, ink, .51)!);
  for (var index = 0; index < 3; index++) {
    final at = Offset.lerp(knee, ankle, .16 + index * .25)!;
    _lines(
      canvas,
      [at - Offset(w * .81, .013), at + Offset(w * .77, .036)],
      ink,
      .049,
    );
    _lines(
      canvas,
      [at - Offset(w * .76, .023), at + Offset(w * .46, .008)],
      trim,
      .032,
    );
    if (index < 2 && !slender) {
      _poly(
        canvas,
        [
          at + const Offset(.042, -.014),
          at + const Offset(.109, -.003),
          at + const Offset(.097, .056),
          at + const Offset(.033, .044),
        ],
        trim,
        stroke: ink,
        width: .019,
      );
    }
  }
  _lines(
    canvas,
    [ankle + Offset(-w * .74, .005), foot + const Offset(-.046, .013)],
    trim,
    .031,
  );
}

void _heroArm(
  Canvas canvas,
  Offset shoulder,
  Offset elbow,
  Offset wrist,
  Color cloth,
  Color trim,
  Color ink, {
  required bool narrow,
}) {
  final w = narrow ? .105 : .139;
  final point = wrist - elbow;
  final along = point.distance > .01
      ? point / point.distance
      : const Offset(1, 0);
  final rim = Offset(-along.dy, along.dx);
  final arm = Path()
    ..moveTo(shoulder.dx - w, shoulder.dy - w * .44)
    ..quadraticBezierTo(
      elbow.dx - w,
      elbow.dy - .12,
      elbow.dx - w * .70,
      elbow.dy,
    )
    ..lineTo(wrist.dx + rim.dx * .082, wrist.dy + rim.dy * .082)
    ..lineTo(wrist.dx - rim.dx * .082, wrist.dy - rim.dy * .082)
    ..lineTo(elbow.dx + w * .78, elbow.dy - w * .35)
    ..quadraticBezierTo(
      shoulder.dx + w * .82,
      shoulder.dy + w * .34,
      shoulder.dx + w * .8,
      shoulder.dy - w * .49,
    )
    ..close();
  _brushShape(canvas, arm, cloth, ink, .055);
  _poly(canvas, [
    shoulder + Offset(-w * .53, -.018),
    elbow + Offset(-w * .45, .031),
    wrist + rim * .046,
    elbow + Offset(w * .57, -.083),
    shoulder + Offset(w * .50, .014),
  ], Color.lerp(cloth, ink, .63)!);
  final cuff = wrist - along * .094;
  _poly(
    canvas,
    [
      cuff + rim * .098,
      cuff - rim * .09,
      wrist - rim * .083,
      wrist + rim * .083,
    ],
    Color.lerp(_bootLeather, trim, .29)!,
    stroke: ink,
    width: .033,
  );
  _lines(canvas, [cuff - rim * .058, cuff + rim * .05], trim, .024);
}

enum _HandGesture { grip, open, pinch, trigger }

void _heroGrip(
  Canvas canvas,
  Offset at,
  double angle,
  Color skin,
  Color shadow,
  Color ink, {
  required _HandGesture gesture,
}) {
  _actor(canvas, at, 1, 1, () {
    canvas.rotate(angle);
    final open = gesture == _HandGesture.open;
    final aiming =
        gesture == _HandGesture.pinch || gesture == _HandGesture.trigger;
    final hand = Path()
      ..moveTo(-.095, -.062)
      ..quadraticBezierTo(-.054, -.073, -.025, -.06)
      ..lineTo(.024, -.097)
      ..quadraticBezierTo(.055, -.108, .066, -.082);
    if (open) {
      hand
        ..lineTo(.042, -.047)
        ..quadraticBezierTo(.21, -.096, .162, -.044)
        ..lineTo(.127, -.026)
        ..quadraticBezierTo(.219, -.051, .187, -.002)
        ..lineTo(.136, .015)
        ..quadraticBezierTo(.203, .004, .172, .042)
        ..lineTo(.117, .055)
        ..quadraticBezierTo(.165, .053, .136, .077);
    } else if (aiming) {
      hand
        ..quadraticBezierTo(.157, -.109, .172, -.052)
        ..quadraticBezierTo(.175, -.023, .134, -.014)
        ..lineTo(.095, -.029)
        ..quadraticBezierTo(.141, .025, .109, .052)
        ..quadraticBezierTo(.117, .077, .083, .081);
    } else {
      hand
        ..quadraticBezierTo(.129, -.092, .139, -.044)
        ..quadraticBezierTo(.155, -.020, .129, .003)
        ..quadraticBezierTo(.141, .032, .112, .046)
        ..quadraticBezierTo(.115, .081, .081, .081);
    }
    hand
      ..quadraticBezierTo(-.001, .105, -.048, .070)
      ..lineTo(-.096, .044)
      ..close();
    _brushShape(canvas, hand, skin, ink, .025);
    _poly(canvas, const [
      Offset(-.089, .021),
      Offset(-.025, .035),
      Offset(.039, .058),
      Offset(.092, .044),
      Offset(.077, .073),
      Offset(.011, .082),
      Offset(-.048, .058),
    ], shadow);
    // Thumb overlaps the handle. Short arcs separate the visible curled fingers.
    final thumb = Path()
      ..moveTo(-.031, -.043)
      ..quadraticBezierTo(.004, -.068, .040, -.077)
      ..quadraticBezierTo(.088, -.070, .068, -.042)
      ..lineTo(.020, -.018)
      ..quadraticBezierTo(-.011, -.012, -.031, -.043)
      ..close();
    _brushShape(canvas, thumb, Color.lerp(skin, _sand, .24)!, shadow, .013);
    if (!open) {
      final creases = Path()
        ..moveTo(.076, -.024)
        ..quadraticBezierTo(.102, -.011, .127, -.010)
        ..moveTo(.064, .010)
        ..quadraticBezierTo(.088, .025, .118, .027)
        ..moveTo(.051, .044)
        ..quadraticBezierTo(.069, .054, .098, .058);
      canvas.drawPath(
        creases,
        Paint()
          ..color = shadow
          ..style = PaintingStyle.stroke
          ..strokeWidth = .013
          ..strokeCap = StrokeCap.round,
      );
    }
  });
}

void _heroHead(
  Canvas canvas,
  Offset at,
  bool front,
  bool lean,
  OculumLiteHair style,
  Color skin,
  Color skinShade,
  Color hair,
  Color hairGlint,
  Color trim,
  Color ink,
) {
  _actor(canvas, at, lean ? .91 : 1.03, lean ? .95 : 1.035, () {
    if (style == OculumLiteHair.tied) {
      _poly(
        canvas,
        const [
          Offset(-.14, .18),
          Offset(-.36, .12),
          Offset(-.45, .33),
          Offset(-.43, .48),
          Offset(-.50, .61),
          Offset(-.32, .56),
          Offset(-.24, .43),
          Offset(-.22, .30),
        ],
        hair,
        stroke: ink,
        width: .056,
      );
      _dryBrush(
        canvas,
        const Offset(-.383, .286),
        const Offset(-.011, .049),
        const Offset(-.025, .146),
        hairGlint,
        4,
      );
    }
    final head = Path()
      ..moveTo(-.285, .247)
      ..quadraticBezierTo(-.29, .115, -.15, .069)
      ..quadraticBezierTo(.036, -.034, .222, .078)
      ..lineTo(.282, .232)
      ..lineTo(.27, .321)
      ..lineTo(.347, .38)
      ..lineTo(.286, .415)
      ..lineTo(.261, .495)
      ..lineTo(.199, .59)
      ..quadraticBezierTo(.005, .605, -.163, .513)
      ..quadraticBezierTo(-.298, .454, -.285, .247)
      ..close();
    _brushShape(canvas, head, front ? skin : hair, ink, .060);
    if (front) {
      _poly(canvas, const [
        Offset(-.248, .24),
        Offset(-.09, .183),
        Offset(-.087, .308),
        Offset(-.145, .406),
        Offset(-.042, .505),
        Offset(.157, .538),
        Offset(.241, .50),
        Offset(.198, .57),
        Offset(.064, .574),
        Offset(-.156, .499),
        Offset(-.252, .392),
      ], skinShade);
      _poly(canvas, const [
        Offset(.216, .25),
        Offset(.278, .30),
        Offset(.259, .336),
        Offset(.309, .387),
        Offset(.24, .401),
        Offset(.211, .370),
      ], skinShade);
      _poly(canvas, const [
        Offset(.027, .262),
        Offset(.184, .262),
        Offset(.227, .284),
        Offset(.149, .341),
        Offset(.049, .332),
        Offset(.015, .302),
      ], ink);
      _poly(canvas, const [
        Offset(.073, .292),
        Offset(.167, .289),
        Offset(.142, .320),
        Offset(.087, .319),
      ], Color.lerp(skin, trim, .58)!);
      _lines(
        canvas,
        const [Offset(.156, .478), Offset(.213, .468), Offset(.248, .473)],
        ink,
        .035,
      );
    }
    final ruined = style == OculumLiteHair.shaggy ? -.071 : -.014;
    final fringe = Path()
      ..moveTo(-.303, .32)
      ..quadraticBezierTo(-.345, .17, -.281, .053)
      ..lineTo(-.195, .022)
      ..lineTo(-.243, ruined + .031)
      ..lineTo(-.104, ruined)
      ..lineTo(.036, ruined + .034)
      ..lineTo(.17, ruined + .003)
      ..lineTo(.265, .055)
      ..lineTo(.318, .17)
      ..lineTo(.29, .286)
      ..lineTo(.221, .194)
      ..lineTo(.091, .274)
      ..lineTo(.113, .182)
      ..lineTo(-.053, .316)
      ..lineTo(-.025, .227)
      ..lineTo(-.219, .372)
      ..lineTo(-.19, .243)
      ..lineTo(-.303, .32)
      ..close();
    _brushShape(canvas, fringe, hair, ink, .052);
    if (style.needsPaintedSilhouette) {
      _paintNewHair(
        canvas,
        const Rect.fromLTWH(-.36, -.03, .69, .64),
        style,
        hair,
        trim,
      );
      return;
    }
    _poly(canvas, [
      const Offset(-.246, .142),
      Offset(-.119, ruined + .047),
      Offset(.115, ruined + .068),
      const Offset(.194, .139),
      const Offset(.018, .12),
      const Offset(-.094, .202),
      const Offset(-.067, .131),
      const Offset(-.235, .231),
    ], hairGlint);
    _dryBrush(
      canvas,
      const Offset(-.145, .081),
      const Offset(.067, .006),
      const Offset(-.073, .099),
      ink,
      5,
      width: .026,
    );
  });
}

void _heroShield(
  Canvas canvas,
  Offset hand,
  double angle,
  Color trim,
  Color ink,
) {
  _actor(canvas, hand, 1, 1, () {
    canvas.rotate(angle);
    const face = Color(0xff58666d);
    final shield = Path()
      ..moveTo(-.294, -.168)
      ..lineTo(-.197, -.276)
      ..lineTo(.154, -.314)
      ..lineTo(.293, -.212)
      ..quadraticBezierTo(.32, .16, .063, .374)
      ..lineTo(-.059, .407)
      ..quadraticBezierTo(-.263, .21, -.294, -.168)
      ..close();
    _brushShape(canvas, shield, face, ink, .065);
    _poly(canvas, const [
      Offset(-.238, -.153),
      Offset(-.157, -.223),
      Offset(.146, -.25),
      Offset(.205, -.172),
      Offset(.078, -.171),
      Offset(-.164, -.106),
    ], Color(0xffa6a1a0));
    _poly(canvas, const [
      Offset(.222, -.125),
      Offset(.218, .052),
      Offset(.118, .252),
      Offset(-.044, .348),
      Offset(-.122, .242),
      Offset(.048, .015),
    ], const Color(0xff333447));
    _oval(
      canvas,
      const Offset(.005, .014),
      .159,
      .149,
      trim,
      stroke: ink,
      strokeWidth: .044,
    );
    _dryBrush(
      canvas,
      const Offset(-.19, -.08),
      const Offset(.015, .057),
      const Offset(.127, .043),
      ink,
      5,
    );
  });
}

void _weapon(Canvas canvas, LiteWeapon weapon, Color accent, Color ink) {
  final steel = Color.lerp(accent, const Color(0xffc8c5c0), .71)!;
  final wood = Color.lerp(accent, const Color(0xff743e32), .67)!;
  final glint = Color.lerp(steel, const Color(0xfff2e3c7), .78)!;
  final steelShadow = Color.lerp(steel, const Color(0xff403744), .62)!;
  switch (weapon) {
    case LiteWeapon.chakram:
      canvas.drawCircle(
        Offset.zero,
        .24,
        Paint()
          ..color = const Color(0xffaadacc)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .085,
      );
    case LiteWeapon.boomerang:
      _poly(
        canvas,
        const [
          Offset(-.12, .14),
          Offset(.22, -.26),
          Offset(.34, -.31),
          Offset(.69, -.202),
          Offset(.83, -.102),
          Offset(.48, -.014),
          Offset(.32, .026),
          Offset(.19, .18),
          Offset(.045, .23),
        ],
        wood,
        stroke: ink,
      );
      _lines(
        canvas,
        const [Offset(.02, .11), Offset(.30, -.18), Offset(.66, -.12)],
        accent,
        .039,
      );
      _poly(canvas, const [
        Offset(-.045, .17),
        Offset(.25, -.12),
        Offset(.37, -.164),
        Offset(.65, -.11),
        Offset(.49, -.073),
        Offset(.31, -.043),
        Offset(.16, .15),
        Offset(.04, .21),
      ], const Color(0xff663628));
      _dryBrush(
        canvas,
        const Offset(.19, -.135),
        const Offset(.081, -.018),
        const Offset(.105, .017),
        glint,
        5,
        width: .019,
      );
    case LiteWeapon.spadaScudo:
      _poly(
        canvas,
        const [
          Offset(-.014, -.065),
          Offset(.22, -.112),
          Offset(.35, -.082),
          Offset(.72, -.09),
          Offset(1.06, -.036),
          Offset(.76, .071),
          Offset(.18, .112),
          Offset(.02, .095),
        ],
        steel,
        stroke: ink,
        width: .046,
      );
      _poly(canvas, const [
        Offset(.09, .046),
        Offset(.46, .02),
        Offset(1.02, -.04),
        Offset(.77, .049),
        Offset(.19, .095),
      ], steelShadow);
      _dryBrush(
        canvas,
        const Offset(.29, .006),
        const Offset(.116, -.008),
        const Offset(.116, -.027),
        glint,
        5,
        width: .014,
      );
      _poly(
        canvas,
        const [
          Offset(-.01, -.20),
          Offset(.05, -.25),
          Offset(.114, -.08),
          Offset(.08, .17),
          Offset(.12, .23),
          Offset(.03, .26),
          Offset(-.025, .17),
        ],
        accent,
        stroke: ink,
        width: .041,
      );
    case LiteWeapon.guanti:
      _poly(
        canvas,
        const [
          Offset(-.17, -.14),
          Offset(.04, -.16),
          Offset(.13, -.23),
          Offset(.30, -.206),
          Offset(.46, -.127),
          Offset(.46, .11),
          Offset(.36, .188),
          Offset(.16, .235),
          Offset(-.14, .146),
        ],
        const Color(0xffa6886d),
        stroke: ink,
      );
      _poly(canvas, const [
        Offset(-.12, -.11),
        Offset(.03, -.11),
        Offset(.02, -.08),
        Offset(-.014, .126),
        Offset(-.12, .127),
      ], steelShadow);
      _poly(canvas, const [
        Offset(.085, .102),
        Offset(.433, -.062),
        Offset(.44, .088),
        Offset(.352, .178),
        Offset(.195, .213),
      ], wood);
      for (var i = 0; i < 3; i++) {
        final at = Offset(.39, -.10 + i * .087);
        _poly(
          canvas,
          [
            at + const Offset(-.058, .036),
            at + const Offset(-.024, -.036),
            at + const Offset(.05, -.02),
            at + const Offset(.075, .03),
            at + const Offset(-.03, .051),
          ],
          steel,
          stroke: ink,
          width: .019,
        );
      }
      _dryBrush(
        canvas,
        const Offset(.063, -.10),
        const Offset(.045, -.041),
        const Offset(.047, .154),
        glint,
        4,
        width: .019,
      );
    case LiteWeapon.arco:
      final bow = Path()
        ..moveTo(.03, -.55)
        ..quadraticBezierTo(.48, -.51, .45, -.34)
        ..quadraticBezierTo(.62, -.24, .56, -.032)
        ..quadraticBezierTo(.65, .19, .46, .31)
        ..quadraticBezierTo(.42, .47, .04, .51);
      canvas.drawPath(
        bow,
        Paint()
          ..strokeWidth = .125
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..color = ink,
      );
      canvas.drawPath(
        bow,
        Paint()
          ..strokeWidth = .068
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..color = accent,
      );
      _lines(
        canvas,
        const [Offset(.03, -.55), Offset(-.16, -.03), Offset(.04, .51)],
        steel,
        .025,
      );
      _lines(canvas, const [Offset(-.12, -.03), Offset(.76, -.03)], wood, .045);
      _poly(
        canvas,
        const [Offset(.70, -.085), Offset(.89, -.025), Offset(.71, .018)],
        glint,
        stroke: ink,
        width: .021,
      );
      _dryBrush(
        canvas,
        const Offset(.515, -.231),
        const Offset(.014, .064),
        const Offset(.059, .013),
        ink,
        6,
        width: .019,
      );
    case LiteWeapon.scettro:
      _lines(canvas, const [Offset(-.22, .09), Offset(.70, -.17)], ink, .15);
      _lines(canvas, const [Offset(-.22, .09), Offset(.70, -.17)], wood, .073);
      _poly(
        canvas,
        const [
          Offset(.45, -.116),
          Offset(.54, -.30),
          Offset(.65, -.36),
          Offset(.62, -.234),
          Offset(.72, -.111),
          Offset(.83, -.22),
          Offset(.99, -.257),
          Offset(.90, .026),
          Offset(.73, .11),
          Offset(.51, .045),
        ],
        steelShadow,
        stroke: ink,
        width: .038,
      );
      _poly(
        canvas,
        const [
          Offset(.55, -.16),
          Offset(.67, -.39),
          Offset(.91, -.28),
          Offset(.87, -.03),
          Offset(.69, .04),
        ],
        const Color(0xff8269c9),
        stroke: ink,
      );
      _poly(canvas, const [
        Offset(.67, -.33),
        Offset(.86, -.28),
        Offset(.69, -.13),
      ], const Color(0xffdbccf6));
      _dryBrush(
        canvas,
        const Offset(.01, -.034),
        const Offset(.089, -.028),
        const Offset(.024, .071),
        glint,
        6,
        width: .016,
      );
    case LiteWeapon.falceRunica:
      _lines(canvas, const [Offset(-.63, .42), Offset(.67, -.42)], ink, .146);
      _lines(
        canvas,
        const [Offset(-.63, .42), Offset(.67, -.42)],
        steelShadow,
        .078,
      );
      _poly(
        canvas,
        const [
          Offset(.30, -.26),
          Offset(.55, -.59),
          Offset(.87, -.55),
          Offset(1.12, -.43),
          Offset(1.33, -.17),
          Offset(1.36, .17),
          Offset(1.17, -.105),
          Offset(.99, -.20),
          Offset(.78, -.24),
          Offset(.58, -.13),
        ],
        steel,
        stroke: ink,
      );
      _poly(canvas, const [
        Offset(.61, -.53),
        Offset(.86, -.494),
        Offset(1.07, -.393),
        Offset(1.19, -.239),
        Offset(.98, -.307),
        Offset(.73, -.333),
        Offset(.52, -.245),
      ], steelShadow);
      _dryBrush(
        canvas,
        const Offset(.64, -.435),
        const Offset(.09, .025),
        const Offset(.119, .063),
        const Color(0xff74c5c2),
        5,
        width: .029,
      );
      _dryBrush(
        canvas,
        const Offset(-.22, .229),
        const Offset(.075, -.055),
        const Offset(.014, .076),
        glint,
        5,
        width: .016,
      );
    case LiteWeapon.doppieLame:
      _poly(
        canvas,
        const [
          Offset(-.166, -.043),
          Offset(-.04, -.058),
          Offset(.093, -.076),
          Offset(.29, -.130),
          Offset(.51, -.155),
          Offset(.783, -.294),
          Offset(.70, -.065),
          Offset(.53, .078),
          Offset(.182, .105),
          Offset(.03, .075),
          Offset(-.17, .055),
        ],
        steel,
        stroke: ink,
        width: .055,
      );
      _poly(canvas, const [
        Offset(.181, .051),
        Offset(.458, -.02),
        Offset(.707, -.216),
        Offset(.52, .046),
        Offset(.296, .083),
      ], steelShadow);
      _poly(
        canvas,
        const [
          Offset(.044, -.185),
          Offset(.116, -.129),
          Offset(.12, .117),
          Offset(.068, .178),
          Offset(.036, .105),
        ],
        accent,
        stroke: ink,
        width: .031,
      );
      _dryBrush(
        canvas,
        const Offset(.229, .023),
        const Offset(.078, -.025),
        const Offset(.118, -.052),
        glint,
        4,
        width: .02,
      );
    case LiteWeapon.carabinaImpulsi:
      _poly(
        canvas,
        const [
          Offset(-.44, -.063),
          Offset(-.27, -.173),
          Offset(.16, -.17),
          Offset(.26, -.267),
          Offset(.65, -.239),
          Offset(.72, -.126),
          Offset(1.07, -.09),
          Offset(1.12, .048),
          Offset(.73, .084),
          Offset(.48, .127),
          Offset(.385, .259),
          Offset(.20, .208),
          Offset(.22, .092),
          Offset(-.26, .102),
        ],
        steelShadow,
        stroke: ink,
        width: .057,
      );
      _poly(canvas, const [
        Offset(.214, -.168),
        Offset(.331, -.248),
        Offset(.614, -.208),
        Offset(.66, -.158),
        Offset(.469, -.082),
        Offset(.267, -.088),
      ], steel);
      _lines(
        canvas,
        const [
          Offset(-.24, -.057),
          Offset(.235, -.047),
          Offset(.438, .017),
          Offset(.687, -.035),
          Offset(1.018, -.025),
        ],
        const Color(0xff80d7ce),
        .027,
      );
      _dryBrush(
        canvas,
        const Offset(.39, -.10),
        const Offset(.079, -.01),
        const Offset(-.015, .14),
        glint,
        4,
        width: .025,
      );
    case LiteWeapon.piccaOssidiana || LiteWeapon.balestraRunica:
      _paintBossWeaponItem(canvas, weapon);
    case LiteWeapon.fucileScostubandito:
      _poly(
        canvas,
        const [
          Offset(-.58, .02),
          Offset(-.39, -.13),
          Offset(.29, -.10),
          Offset(.55, -.045),
          Offset(.43, .10),
          Offset(.12, .17),
          Offset(.04, .10),
          Offset(-.48, .19),
        ],
        const Color(0xff875737),
        stroke: ink,
        width: .065,
      );
      _lines(canvas, const [Offset(-.08, -.12), Offset(1.21, -.12)], ink, .15);
      _lines(
        canvas,
        const [Offset(.01, -.13), Offset(1.19, -.13)],
        const Color(0xffc79055),
        .085,
      );
      _lines(
        canvas,
        const [Offset(.11, -.159), Offset(1.13, -.159)],
        const Color(0xfff4cb86),
        .025,
      );
  }
}

double _enemyScale(LiteEnemyKind kind) => switch (kind) {
  LiteEnemyKind.scostubandito => .83,
  LiteEnemyKind.granScostumato => 1.54,
  LiteEnemyKind.babyForestDemon => .70,
  LiteEnemyKind.forestDemon => 1.50,
  LiteEnemyKind.slime => .92,
  LiteEnemyKind.costrutto => 1.04,
  LiteEnemyKind.ragnoSaldatore => .9,
  LiteEnemyKind.miruscyrus => 1.40,
  LiteEnemyKind.dronePostea => .86,
  LiteEnemyKind.luce || LiteEnemyKind.ombra => 1.23,
  LiteEnemyKind.veyrth => 1.48,
  LiteEnemyKind.minionVeyrth || LiteEnemyKind.ecoSpeculare => .76,
  LiteEnemyKind.rasvyr => 1.12,
  LiteEnemyKind.orbryx => .95,
  LiteEnemyKind.lupoLunare => 1.06,
  LiteEnemyKind.gablyn || LiteEnemyKind.guardiaLunare => .92,
  LiteEnemyKind.guardianoLunare => 1.35,
  LiteEnemyKind.goblinColtello ||
  LiteEnemyKind.goblinColla ||
  LiteEnemyKind.goblinFango => .76,
  LiteEnemyKind.reGoblin => 1.33,
  LiteEnemyKind.pollo ||
  LiteEnemyKind.raganella ||
  LiteEnemyKind.pipistrello => .85,
  LiteEnemyKind.guardiaSolare || LiteEnemyKind.eliteLunare => .95,
  LiteEnemyKind.eliteSolare || LiteEnemyKind.aberrazioneSolare => 1.12,
  LiteEnemyKind.guardianoSolare || LiteEnemyKind.custodeLunare => 1.34,
  LiteEnemyKind.demoneMinore => .81,
  LiteEnemyKind.demoneIntermedio || LiteEnemyKind.demoneMaggiore => 1.12,
  LiteEnemyKind.diavolo => 1.40,
  LiteEnemyKind.divoramitu => 1.85,
  LiteEnemyKind.divoramituBoss => 2.68,
};

double _enemyHeight(LiteEnemyKind kind) => switch (kind) {
  LiteEnemyKind.scostubandito => 1.77,
  LiteEnemyKind.granScostumato => 2.12,
  LiteEnemyKind.forestDemon || LiteEnemyKind.babyForestDemon => 1.82,
  LiteEnemyKind.slime => .81,
  LiteEnemyKind.costrutto => 1.52,
  LiteEnemyKind.ragnoSaldatore => 1.35,
  LiteEnemyKind.miruscyrus => 2.19,
  LiteEnemyKind.dronePostea => 1.15,
  LiteEnemyKind.luce ||
  LiteEnemyKind.ombra ||
  LiteEnemyKind.ecoSpeculare => 2.23,
  LiteEnemyKind.veyrth => 2.44,
  LiteEnemyKind.minionVeyrth => 1.49,
  LiteEnemyKind.rasvyr => 1.94,
  LiteEnemyKind.orbryx => 1.67,
  LiteEnemyKind.lupoLunare => 1.69,
  LiteEnemyKind.gablyn => 1.47,
  LiteEnemyKind.guardiaLunare => 2.12,
  LiteEnemyKind.guardianoLunare => 2.85,
  LiteEnemyKind.goblinColtello ||
  LiteEnemyKind.goblinColla ||
  LiteEnemyKind.goblinFango => 1.97,
  LiteEnemyKind.reGoblin => 2.40,
  LiteEnemyKind.pollo ||
  LiteEnemyKind.raganella ||
  LiteEnemyKind.pipistrello => 1.30,
  LiteEnemyKind.guardiaSolare || LiteEnemyKind.eliteLunare => 2.20,
  LiteEnemyKind.eliteSolare || LiteEnemyKind.aberrazioneSolare => 2.47,
  LiteEnemyKind.guardianoSolare || LiteEnemyKind.custodeLunare => 2.94,
  LiteEnemyKind.demoneMinore => 1.78,
  LiteEnemyKind.demoneIntermedio || LiteEnemyKind.demoneMaggiore => 2.47,
  LiteEnemyKind.diavolo => 2.95,
  LiteEnemyKind.divoramitu || LiteEnemyKind.divoramituBoss => 2.25,
};

void _enemy(
  Canvas canvas,
  LiteEnemyKind kind, {
  required bool fallen,
  required double time,
  required bool cannonRaised,
}) {
  if (fallen) {
    canvas.translate(-.10, -.08);
    canvas.rotate(1.33);
    canvas.scale(.64);
  }
  final step = fallen ? 0.0 : math.sin(time * 6.0) * .048;
  switch (kind) {
    case LiteEnemyKind.goblinColtello ||
        LiteEnemyKind.goblinFango ||
        LiteEnemyKind.goblinColla ||
        LiteEnemyKind.reGoblin:
      _bandit(
        canvas,
        kind == LiteEnemyKind.reGoblin,
        step,
        cannonRaised: false,
      );
    case LiteEnemyKind.scostubandito:
    case LiteEnemyKind.granScostumato:
      _bandit(
        canvas,
        kind == LiteEnemyKind.granScostumato,
        step,
        cannonRaised: !fallen && cannonRaised,
      );
    case LiteEnemyKind.rasvyr ||
        LiteEnemyKind.lupoLunare ||
        LiteEnemyKind.gablyn:
      _forestDemon(canvas, true, step);
    case LiteEnemyKind.orbryx ||
        LiteEnemyKind.pollo ||
        LiteEnemyKind.raganella ||
        LiteEnemyKind.pipistrello:
      _slime(canvas, step);
    case LiteEnemyKind.babyForestDemon:
    case LiteEnemyKind.forestDemon:
      _forestDemon(canvas, kind == LiteEnemyKind.babyForestDemon, step);
    case LiteEnemyKind.slime:
      _slime(canvas, step);
    case LiteEnemyKind.costrutto ||
        LiteEnemyKind.guardiaSolare ||
        LiteEnemyKind.eliteSolare ||
        LiteEnemyKind.guardianoSolare ||
        LiteEnemyKind.aberrazioneSolare ||
        LiteEnemyKind.eliteLunare ||
        LiteEnemyKind.custodeLunare ||
        LiteEnemyKind.demoneMinore ||
        LiteEnemyKind.demoneIntermedio ||
        LiteEnemyKind.demoneMaggiore ||
        LiteEnemyKind.diavolo ||
        LiteEnemyKind.divoramitu ||
        LiteEnemyKind.divoramituBoss ||
        LiteEnemyKind.guardianoLunare ||
        LiteEnemyKind.guardiaLunare:
      _construct(canvas, step);
    case LiteEnemyKind.ragnoSaldatore:
      _forgeSpider(canvas, step);
    case LiteEnemyKind.miruscyrus:
      _pistonMantis(canvas, step);
    case LiteEnemyKind.dronePostea:
      _posteaDrone(canvas, step);
    case LiteEnemyKind.luce:
    case LiteEnemyKind.ombra:
    case LiteEnemyKind.veyrth:
    case LiteEnemyKind.minionVeyrth:
    case LiteEnemyKind.ecoSpeculare:
      _eliteSpecter(canvas, kind, step);
  }
}

void _bandit(
  Canvas canvas,
  bool tall,
  double step, {
  required bool cannonRaised,
}) {
  const fur = Color(0xff977068);
  const litFur = Color(0xffddac82);
  const cloth = Color(0xff5c5960);
  const rust = Color(0xff9c4c46);
  final shoulders = tall ? .62 : .44;
  _lines(
    canvas,
    [
      const Offset(-.24, -.24),
      const Offset(-.70, -.21),
      Offset(-1.00, -.37 + step),
      const Offset(-1.05, -.57),
    ],
    fur,
    .087,
  );
  for (final side in [-1.0, 1.0]) {
    final legX = (tall ? .26 : .19) * side;
    _poly(
      canvas,
      [
        Offset(legX - .12, -.61),
        Offset(legX + .13, -.53),
        Offset(legX + .16, -.09 + step * side),
        Offset(legX + .20, .014 + step * side),
        Offset(legX - .15, .004 + step * side),
      ],
      litFur,
      stroke: _ink,
    );
  }
  _poly(
    canvas,
    [
      Offset(-shoulders, -.93),
      const Offset(-.21, -1.18),
      const Offset(.22, -1.13),
      Offset(shoulders, -.91),
      const Offset(.27, -.47),
      const Offset(-.22, -.43),
    ],
    cloth,
    stroke: _ink,
  );
  _poly(
    canvas,
    [
      Offset(-shoulders, -.88),
      const Offset(-.39, -.65),
      const Offset(-.20, -.76),
      const Offset(-.03, -.92),
      const Offset(.26, -.92),
      Offset(shoulders + .06, -.68),
      Offset(shoulders - .01, -.55),
      const Offset(.24, -.63),
      const Offset(.08, -.73),
      const Offset(-.29, -.55),
      Offset(-shoulders - .06, -.71),
    ],
    fur,
    stroke: _ink,
  );
  _dryBrush(
    canvas,
    Offset(-shoulders + .08, -.82),
    const Offset(.079, .049),
    const Offset(.12, -.021),
    litFur.withValues(alpha: .75),
    5,
  );
  _poly(canvas, [
    Offset(shoulders - .24, -.83),
    Offset(shoulders - .06, -.73),
    Offset(shoulders, -.66),
    Offset(shoulders - .04, -.55),
    const Offset(.26, -.64),
    const Offset(.19, -.72),
  ], const Color(0xff593941));
  _poly(
    canvas,
    const [
      Offset(-.33, -.55),
      Offset(-.13, -.48),
      Offset(.25, -.48),
      Offset(.30, -.37),
      Offset(-.38, -.46),
    ],
    const Color(0xffa56b50),
    stroke: _ink,
  );
  _oval(canvas, const Offset(.05, -.47), .14, .12, _sand, stroke: _ink);
  _poly(
    canvas,
    const [
      Offset(-.32, -1.19),
      Offset(.35, -1.18),
      Offset(.27, -1.0),
      Offset(.00, -1.04),
      Offset(-.42, -.87),
      Offset(-.55, -1.10),
    ],
    rust,
    stroke: _ink,
  );

  if (!tall) {
    _poly(
      canvas,
      const [
        Offset(-.43, -1.19),
        Offset(-.40, -1.60),
        Offset(-.17, -1.77),
        Offset(.16, -1.75),
        Offset(.43, -1.55),
        Offset(.47, -1.34),
        Offset(.22, -1.42),
        Offset(-.18, -1.34),
      ],
      const Color(0xff736342),
      stroke: _ink,
    );
    _poly(canvas, const [
      Offset(-.36, -1.58),
      Offset(-.17, -1.70),
      Offset(.14, -1.73),
      Offset(.32, -1.59),
      Offset(.05, -1.57),
      Offset(-.16, -1.53),
    ], const Color(0xffa28a59));
    _dryBrush(
      canvas,
      const Offset(-.20, -1.66),
      const Offset(.071, .005),
      const Offset(.13, .056),
      const Color(0xff4d443b),
      5,
      width: .025,
    );
  }
  for (final x in [-.31, .31]) {
    _oval(canvas, Offset(x, -1.52 + step * .18), .31, .34, fur, stroke: _ink);
    _oval(canvas, Offset(x, -1.51 + step * .18), .185, .207, rust);
  }
  _poly(
    canvas,
    const [
      Offset(-.37, -1.51),
      Offset(-.18, -1.62),
      Offset(.20, -1.62),
      Offset(.40, -1.48),
      Offset(.37, -1.24),
      Offset(.17, -1.13),
      Offset(-.14, -1.14),
      Offset(-.35, -1.20),
    ],
    fur,
    stroke: _ink,
  );
  _oval(canvas, const Offset(.19, -1.25), .40, .23, litFur);
  _dryBrush(
    canvas,
    const Offset(-.17, -1.26),
    const Offset(.052, .016),
    const Offset(-.084, .072),
    const Color(0xff66454a),
    6,
  );
  _oval(canvas, const Offset(.34, -1.28), .118, .088, _ink);
  _lines(canvas, const [Offset(-.04, -1.43), Offset(.12, -1.37)], _ink, .088);
  _lines(canvas, const [Offset(.20, -1.38), Offset(.33, -1.43)], _ink, .081);
  _oval(canvas, const Offset(.11, -1.38), .062, .037, _sand);
  _oval(canvas, const Offset(.25, -1.39), .061, .041, _sand);
  for (var i = 0; i < 2; i++) {
    _lines(
      canvas,
      [const Offset(.33, -1.23), Offset(.50, -1.21 + i * .09)],
      litFur,
      .026,
    );
  }
  _oval(canvas, const Offset(.24, -1.15), .055, .081, const Color(0xfff4e0ae));

  if (cannonRaised) {
    _poly(
      canvas,
      const [
        Offset(.44, -.84),
        Offset(.64, -.93),
        Offset(.69, -1.21),
        Offset(.65, -1.47),
        Offset(.51, -1.49),
        Offset(.48, -1.25),
        Offset(.35, -1.13),
      ],
      fur,
      stroke: _ink,
    );
    _dryBrush(
      canvas,
      const Offset(.60, -1.31),
      const Offset(-.017, .062),
      const Offset(.082, .089),
      litFur,
      4,
    );
  }
  canvas.save();
  if (cannonRaised) {
    canvas.translate(.54, -1.53);
    canvas.rotate(-.30);
    canvas.translate(-.54, .90);
  }
  final gunLength = tall ? 1.28 : .89;
  final gunWidth = tall ? .47 : .145;
  _poly(
    canvas,
    [
      const Offset(-.43, -.72),
      const Offset(-.46, -.86),
      Offset(gunLength, -.90 - gunWidth / 2),
      Offset(gunLength + .08, -.89 + gunWidth / 2),
      const Offset(.30, -.72),
    ],
    const Color(0xff603d38),
    stroke: _ink,
    width: .064,
  );
  _poly(canvas, [
    const Offset(-.36, -.78),
    const Offset(-.13, -.76),
    Offset(gunLength, -.92 + gunWidth * .27),
    Offset(gunLength, -.89 + gunWidth / 2),
    const Offset(.19, -.72),
  ], const Color(0xff382835));
  _lines(
    canvas,
    [const Offset(-.09, -.80), Offset(gunLength, -.90 - gunWidth * .22)],
    (cannonRaised ? _ember : _sand).withValues(alpha: .88),
    tall ? .09 : .046,
  );
  final inkBrass = Color.lerp(_sand, const Color(0xff6e403c), .42)!;
  for (var index = 0; index < (tall ? 3 : 2); index++) {
    final x = .40 + index * .21;
    _lines(
      canvas,
      [
        Offset(x, -.88 - gunWidth * .32),
        Offset(x + .033, -.895 + gunWidth * .27),
      ],
      inkBrass,
      tall ? .086 : .042,
    );
  }
  _oval(
    canvas,
    Offset(gunLength, -.9),
    tall ? .23 : .108,
    gunWidth,
    _ink,
    stroke: _sand,
    strokeWidth: tall ? .071 : .027,
  );
  if (cannonRaised) {
    _oval(canvas, Offset(gunLength + .031, -.9), .11, .17, _ember);
    _dryBrush(
      canvas,
      Offset(gunLength - .03, -1.09),
      const Offset(.039, .063),
      const Offset(.18, -.11),
      _ember.withValues(alpha: .76),
      5,
    );
  }
  canvas.restore();
}

void _forestDemon(Canvas canvas, bool baby, double step) {
  const plates = Color(0xff9a694a);
  const scale = Color(0xff5d5440);
  const horn = Color(0xffd5a678);
  _poly(
    canvas,
    const [
      Offset(-.45, -.67),
      Offset(-.92, -.82),
      Offset(-1.29, -.70),
      Offset(-1.49, -.45),
      Offset(-1.38, -.24),
      Offset(-1.52, -.15),
      Offset(-1.63, -.42),
      Offset(-1.44, -1.01),
      Offset(-.61, -1.04),
    ],
    scale,
    stroke: _ink,
  );
  for (final i in [0, 1, 2, 3]) {
    final foot = -.68 + i * .41;
    final bend = i.isEven ? step : -step;
    _poly(
      canvas,
      [
        Offset(foot - .21, -.82 + bend),
        Offset(foot + .13, -.86),
        Offset(foot + .27, -.16 + bend),
        Offset(foot + .23, -.06 + bend),
        Offset(foot - .16, -.06 + bend),
        Offset(foot - .23, -.30),
      ],
      i.isEven ? scale : plates,
      stroke: _ink,
    );
    _poly(
      canvas,
      [
        Offset(foot + .05, -.11 + bend),
        Offset(foot + .27, -.16 + bend),
        Offset(foot + .19, .03 + bend),
      ],
      horn,
      stroke: _ink,
      width: .035,
    );
  }
  _poly(
    canvas,
    const [
      Offset(-.74, -.66),
      Offset(-.90, -.92),
      Offset(-.65, -1.19),
      Offset(-.23, -1.29),
      Offset(.02, -1.16),
      Offset(.52, -1.34),
      Offset(.73, -1.18),
      Offset(.77, -.77),
      Offset(.34, -.48),
      Offset(-.34, -.57),
    ],
    scale,
    stroke: _ink,
  );
  for (var i = 0; i < 6; i++) {
    final x = -.74 + i * .24;
    _poly(
      canvas,
      [
        Offset(x - .03, -.91),
        Offset(x - .05, -1.22),
        Offset(x + .12, -1.32),
        Offset(x + .35, -1.08),
        Offset(x + .24, -.81),
        Offset(x + .12, -.88),
      ],
      i.isEven ? plates : scale,
      stroke: _ink,
      width: .039,
    );
    _dryBrush(
      canvas,
      Offset(x + .049, -1.122),
      const Offset(.043, .043),
      const Offset(.088, .086),
      const Color(0xff3e302d),
      3,
      width: .027,
    );
  }
  _poly(
    canvas,
    [
      const Offset(.17, -1.28),
      const Offset(.20, -1.55),
      Offset(.49, baby ? -1.55 : -1.64),
      const Offset(.83, -1.51),
      const Offset(1.02, -1.22),
      const Offset(1.00, -.97),
      const Offset(.78, -.87),
      const Offset(.46, -.94),
      const Offset(.32, -1.02),
    ],
    plates,
    stroke: _ink,
  );
  _poly(
    canvas,
    const [
      Offset(.39, -1.52),
      Offset(.20, -1.86),
      Offset(-.01, -1.80),
      Offset(.06, -1.65),
      Offset(.28, -1.40),
    ],
    horn,
    stroke: _ink,
  );
  _poly(
    canvas,
    const [
      Offset(.67, -1.46),
      Offset(.79, -1.83),
      Offset(.99, -1.82),
      Offset(.96, -1.59),
      Offset(.81, -1.41),
    ],
    horn,
    stroke: _ink,
  );
  _poly(
    canvas,
    [
      const Offset(.82, -1.23),
      Offset(1.10, baby ? -1.48 : -1.66),
      const Offset(1.18, -1.59),
      const Offset(1.10, -1.26),
      const Offset(.96, -1.10),
    ],
    horn,
    stroke: _ink,
  );
  _lines(canvas, const [Offset(.56, -1.33), Offset(.72, -1.27)], _ink, .10);
  _oval(canvas, const Offset(.69, -1.29), .095, .054, _sand);
  _lines(canvas, const [Offset(.85, -1.38), Offset(.93, -1.34)], _ink, .084);
  _oval(canvas, const Offset(.907, -1.35), .064, .038, _sand);
  _poly(canvas, const [
    Offset(.35, -1.20),
    Offset(.58, -1.14),
    Offset(.68, -1.14),
    Offset(.83, -1.06),
    Offset(.59, -1.053),
    Offset(.53, -.972),
    Offset(.40, -1.03),
  ], const Color(0xff54372f));
  _dryBrush(
    canvas,
    const Offset(.38, -1.30),
    const Offset(.064, .055),
    const Offset(.07, -.061),
    horn.withValues(alpha: .67),
    5,
  );
  _lines(
    canvas,
    [const Offset(.63, -1.04), Offset(1.0, -1.055 - step)],
    _ink,
    .087,
  );
  _poly(canvas, const [
    Offset(.84, -1.05),
    Offset(.94, -1.06),
    Offset(.91, -.97),
  ], horn);
}

const _copper = Color(0xffa86145);
const _copperEdge = Color(0xffdb915e);
const _posteaSteel = Color(0xff63586a);
const _plasma = Color(0xff87ded1);

void _forgeSpider(Canvas canvas, double step) {
  final tail = [
    const Offset(-.59, -.67),
    const Offset(-1.02, -.71),
    const Offset(-1.24, -1.03),
    const Offset(-1.11, -1.30),
    Offset(-.82, -1.33 + step),
    Offset(-.67, -1.16 + step),
  ];
  _lines(canvas, tail, _ink, .245);
  _lines(canvas, tail, _posteaSteel, .145);
  _dryBrush(
    canvas,
    const Offset(-1.18, -1.12),
    const Offset(.089, -.052),
    const Offset(.076, .136),
    _copperEdge,
    5,
  );
  _oval(canvas, tail.last, .16, .16, _plasma, stroke: _ink);
  for (var i = 0; i < 8; i++) {
    final farSide = i < 4;
    final x = -.62 + i.remainder(4) * .29;
    final s = (i.isEven ? step : -step);
    final link = [
      Offset(x, -.77),
      Offset(x + .105, farSide ? -.54 : -.44),
      Offset(x + (farSide ? -.34 : .03), (farSide ? -.38 : -.04) + s),
    ];
    _lines(canvas, link, _ink, .174);
    _lines(canvas, link, farSide ? _posteaSteel : _copper, .098);
    _oval(
      canvas,
      link[1],
      .145,
      .145,
      farSide ? _copper : _copperEdge,
      stroke: _ink,
      strokeWidth: .037,
    );
  }
  _poly(
    canvas,
    const [
      Offset(-.80, -.72),
      Offset(-.64, -1.04),
      Offset(-.40, -1.15),
      Offset(.26, -1.18),
      Offset(.56, -.99),
      Offset(.54, -.77),
      Offset(.31, -.59),
      Offset(-.47, -.56),
    ],
    _copper,
    stroke: _ink,
    width: .063,
  );
  _lines(
    canvas,
    const [
      Offset(-.65, -.89),
      Offset(-.37, -.98),
      Offset(-.15, -.91),
      Offset(.05, -1.02),
      Offset(.29, -.98),
      Offset(.43, -.88),
    ],
    _ink,
    .137,
  );
  _lines(
    canvas,
    const [
      Offset(-.38, -.98),
      Offset(-.15, -.91),
      Offset(.05, -1.02),
      Offset(.26, -.98),
    ],
    _copperEdge,
    .034,
  );
  _dryBrush(
    canvas,
    const Offset(-.60, -.84),
    const Offset(.122, .019),
    const Offset(.119, .126),
    const Color(0xff54313b),
    8,
    width: .028,
  );
  _poly(
    canvas,
    const [
      Offset(.31, -.94),
      Offset(.64, -1.09),
      Offset(.94, -1.01),
      Offset(.88, -.87),
      Offset(.63, -.84),
      Offset(.72, -.74),
      Offset(.81, -.80),
      Offset(.78, -.64),
      Offset(.55, -.68),
    ],
    _copperEdge,
    stroke: _ink,
  );
  _oval(canvas, const Offset(.76, -.97), .09, .049, _ink);
}

void _pistonMantis(Canvas canvas, double step) {
  for (var i = 0; i < 4; i++) {
    final x = -.64 + i * .22;
    final leg = [
      Offset(x, -.72),
      Offset(x - .17, -.47),
      Offset(x - .37, step * i * .6),
    ];
    _lines(canvas, leg, _ink, .19);
    _lines(canvas, leg, i.isEven ? _posteaSteel : _copper, .094);
    _oval(
      canvas,
      leg[1],
      .14,
      .15,
      _copperEdge,
      stroke: _ink,
      strokeWidth: .035,
    );
  }
  _poly(
    canvas,
    const [
      Offset(-1.01, -.83),
      Offset(-.49, -1.22),
      Offset(-.17, -1.30),
      Offset(.23, -1.67),
      Offset(.60, -1.61),
      Offset(.71, -1.28),
      Offset(.17, -.95),
      Offset(-.38, -.59),
    ],
    _copper,
    stroke: _ink,
    width: .083,
  );
  _poly(
    canvas,
    const [
      Offset(.23, -1.29),
      Offset(-.22, -1.29),
      Offset(-.75, -1.49),
      Offset(-1.37, -1.86),
      Offset(-.63, -1.78),
      Offset(-.09, -1.58),
    ],
    _posteaSteel,
    stroke: _ink,
    width: .062,
  );
  _poly(
    canvas,
    const [
      Offset(.11, -1.31),
      Offset(-.56, -1.25),
      Offset(-1.37, -1.36),
      Offset(-.94, -1.58),
      Offset(-.50, -1.57),
      Offset(-.11, -1.51),
    ],
    _posteaSteel,
    stroke: _ink,
  );
  _dryBrush(
    canvas,
    const Offset(-1.13, -1.37),
    const Offset(.113, -.018),
    const Offset(.18, -.073),
    _copperEdge,
    8,
    width: .027,
  );
  for (var i = 0; i < 2; i++) {
    final lead = Offset(i * .35, -i * .17 + (i.isEven ? step : -step));
    _actor(canvas, lead, 1, 1, () {
      _lines(
        canvas,
        const [Offset(.24, -1.22), Offset(.36, -.77), Offset(.67, -.93)],
        _ink,
        .224,
      );
      _lines(
        canvas,
        const [Offset(.24, -1.22), Offset(.36, -.77), Offset(.67, -.93)],
        _copper,
        .120,
      );
      _poly(
        canvas,
        const [
          Offset(.63, -1.00),
          Offset(.83, -.91),
          Offset(.99, -.67),
          Offset(1.03, -.34),
          Offset(.88, -.11),
          Offset(.90, -.48),
          Offset(.79, -.64),
          Offset(.66, -.68),
          Offset(.72, -.79),
        ],
        _copperEdge,
        stroke: _ink,
      );
    });
  }
  _poly(
    canvas,
    const [
      Offset(.28, -1.71),
      Offset(.59, -1.75),
      Offset(.84, -1.52),
      Offset(.72, -1.31),
      Offset(.46, -1.42),
    ],
    _posteaSteel,
    stroke: _ink,
  );
  _lines(
    canvas,
    const [Offset(.59, -1.60), Offset(.74, -1.52)],
    _copperEdge,
    .058,
  );
  _lines(
    canvas,
    const [Offset(.58, -1.69), Offset(.48, -1.99), Offset(.26, -2.12)],
    _copperEdge,
    .04,
  );
  _lines(
    canvas,
    const [Offset(.65, -1.69), Offset(.79, -1.96), Offset(1.02, -2.05)],
    _copperEdge,
    .038,
  );
}

void _posteaDrone(Canvas canvas, double step) {
  canvas.translate(0, step * 1.7);
  _poly(
    canvas,
    const [
      Offset(-.81, -.60),
      Offset(-.65, -.91),
      Offset(-.30, -.81),
      Offset(-.04, -1.12),
      Offset(.32, -1.10),
      Offset(.57, -.90),
      Offset(.82, -.91),
      Offset(.92, -.66),
      Offset(.74, -.56),
      Offset(.55, -.65),
      Offset(.42, -.45),
      Offset(.10, -.37),
      Offset(-.35, -.51),
    ],
    _posteaSteel,
    stroke: _ink,
    width: .073,
  );
  _poly(
    canvas,
    const [
      Offset(-.41, -.62),
      Offset(-.12, -.75),
      Offset(.34, -.82),
      Offset(.66, -.75),
      Offset(.47, -.55),
      Offset(.11, -.46),
    ],
    _copper,
    stroke: _ink,
  );
  _lines(
    canvas,
    const [
      Offset(-.19, -.67),
      Offset(.09, -.68),
      Offset(.26, -.60),
      Offset(.48, -.67),
    ],
    _plasma,
    .047,
  );
  _dryBrush(
    canvas,
    const Offset(-.53, -.83),
    const Offset(.108, -.025),
    const Offset(.07, .115),
    _copperEdge,
    6,
  );
}

void _slime(Canvas canvas, double step) {
  final horizon = -.50 + step;
  _poly(
    canvas,
    [
      const Offset(-.56, -.10),
      Offset(-.43, horizon),
      Offset(-.23, horizon - .16),
      Offset(.17, horizon - .29),
      Offset(.41, horizon - .12),
      const Offset(.56, -.08),
      const Offset(.37, .01),
      const Offset(-.32, -.01),
    ],
    const Color(0xff655c9c),
    stroke: _ink,
  );
  _poly(canvas, [
    Offset(-.32, horizon),
    Offset(-.15, horizon - .14),
    Offset(.20, horizon - .17),
    Offset(.33, horizon - .09),
    const Offset(.16, -.32),
    const Offset(-.23, -.22),
  ], const Color(0xffa099cf));
  _oval(canvas, const Offset(.16, -.31), .102, .097, _ink);
  _oval(canvas, const Offset(.37, -.29), .102, .097, _ink);
  _lines(canvas, const [Offset(.21, -.18), Offset(.34, -.17)], _ink, .055);
}

void _construct(Canvas canvas, double step) {
  const iron = Color(0xff726779);
  const brass = Color(0xffad8875);
  for (final side in [-1.0, 1.0]) {
    final x = side * .19;
    _poly(
      canvas,
      [
        Offset(x - .15, -.58),
        Offset(x + .13, -.58),
        Offset(x + .16, -.12 + step * side),
        Offset(x + .23, -.01 + step * side),
        Offset(x - .17, -.01 + step * side),
      ],
      iron,
      stroke: _ink,
    );
    _poly(
      canvas,
      [
        Offset(side * .24, -.98),
        Offset(side * .58, -.96),
        Offset(side * .61, -.52 + step * side),
        Offset(side * .42, -.38 + step * side),
        Offset(side * .29, -.64),
      ],
      brass,
      stroke: _ink,
    );
  }
  _poly(
    canvas,
    const [
      Offset(-.39, -1.08),
      Offset(.34, -1.08),
      Offset(.44, -.60),
      Offset(-.34, -.45),
    ],
    iron,
    stroke: _ink,
  );
  _poly(
    canvas,
    const [
      Offset(.00, -.93),
      Offset(.11, -.82),
      Offset(.01, -.67),
      Offset(-.10, -.81),
    ],
    _violet,
    stroke: _ink,
  );
  _poly(
    canvas,
    const [
      Offset(-.25, -1.41),
      Offset(.26, -1.49),
      Offset(.38, -1.26),
      Offset(.25, -1.06),
      Offset(-.23, -1.12),
    ],
    brass,
    stroke: _ink,
  );
  _lines(canvas, const [Offset(-.11, -1.31), Offset(.24, -1.32)], _ink, .093);
  _lines(canvas, const [Offset(.05, -1.30), Offset(.20, -1.31)], _active, .040);
}

void _health(Canvas canvas, Offset at, double value, double size) {
  final r = Rect.fromCenter(center: at, width: .86 * size, height: .07);
  canvas.drawRect(r.inflate(.037), Paint()..color = _ink);
  canvas.drawRect(r, Paint()..color = const Color(0xff4a2536));
  canvas.drawRect(
    Rect.fromLTWH(r.left, r.top, r.width * value.clamp(0, 1), r.height),
    Paint()..color = const Color(0xffe27471),
  );
}

void _hit(Canvas canvas, Offset at, double size) {
  for (var i = -1; i <= 1; i++) {
    final p = at + Offset(i * .16 * size, -.30 * i);
    final end = p + Offset(.28 + (i.isEven ? .18 : 0), -.30 - size * .16);
    _lines(canvas, [p, end], _ink, .12);
    _lines(canvas, [p + const Offset(0, -.028), end], _ember, .045);
  }
}

void _arenaProp(
  Canvas canvas,
  ui.Image atlas,
  int frame,
  Offset at,
  double height,
  bool active, {
  bool shadow = true,
}) {
  final unit = atlas.height / 2;
  final w = height * 1.13;
  if (shadow) _shadow(canvas, at, w * .38, height * .13, alpha: .48);
  final paint = Paint()..filterQuality = FilterQuality.medium;
  if (!active) {
    paint.colorFilter = const ColorFilter.mode(
      Color(0xffa398aa),
      BlendMode.modulate,
    );
  }
  canvas.drawImageRect(
    atlas,
    Rect.fromLTWH((frame % 3) * unit, (frame ~/ 3) * unit, unit, unit),
    Rect.fromLTWH(at.dx - w / 2, at.dy - height * .96, w, height),
    paint,
  );
}

void _loot(
  Canvas canvas,
  LiteLoot loot,
  double time,
  ui.Image? gear,
  ui.Image? props,
  ui.Image? art,
) {
  final at = _offset(loot.position);
  final p = at - Offset(0, .22 + math.sin(time * 4 + at.dx) * .10);
  _shadow(canvas, at, .24, .13, alpha: .47);
  _paintDropSignal(canvas, at, p, loot, time);
  if (art != null) {
    final (index, size) = switch (loot.kind) {
      LiteLootKind.obser => (0, .73),
      LiteLootKind.scroll => (2, 1.04),
      LiteLootKind.greenStone => (1, .78),
      LiteLootKind.refinedGreenGem => (1, 1.17),
      LiteLootKind.lunarSymbol => (4, 1.34),
      _ => (-1, .0),
    };
    if (index >= 0) {
      final cell = art.width / 5.0;
      final target = Rect.fromCenter(
        center: p - Offset(0, size * .24),
        width: size,
        height: size,
      );
      canvas.drawImageRect(
        art,
        Rect.fromLTWH(index * cell, 0, cell, cell),
        target,
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }
  }
  if (props != null) {
    final item = switch (loot.kind) {
      LiteLootKind.healing || LiteLootKind.greenStone => (3, .78),
      LiteLootKind.refinedGreenGem => (4, .99),
      _ => null,
    };
    if (item != null) {
      _arenaProp(canvas, props, item.$1, p, item.$2, true, shadow: false);
      if (loot.weapon == null) return;
    }
  }
  _actor(canvas, p, 1, 1, () {
    switch (loot.kind) {
      case LiteLootKind.lunarSymbol:
        final metal = Paint()
          ..color = const Color(0xffc2c6ed)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .06;
        canvas.drawCircle(Offset.zero, .09, metal);
        canvas.drawArc(
          const Rect.fromLTWH(-.34, -.19, .36, .38),
          1.13,
          4.02,
          false,
          metal,
        );
        canvas.drawArc(
          const Rect.fromLTWH(-.02, -.19, .36, .38),
          -2.02,
          4.02,
          false,
          metal,
        );
      case LiteLootKind.obser:
        _poly(
          canvas,
          const [
            Offset(-.16, 0),
            Offset(0, -.23),
            Offset(.19, -.02),
            Offset(.02, .20),
          ],
          _sand,
          stroke: _ink,
        );
        _lines(
          canvas,
          const [Offset(-.06, .02), Offset(.01, -.12), Offset(.10, .01)],
          const Color(0xffffe5ac),
          .043,
        );
      case LiteLootKind.scroll:
        _poly(
          canvas,
          const [
            Offset(-.22, -.14),
            Offset(.12, -.20),
            Offset(.23, .10),
            Offset(-.13, .20),
            Offset(-.22, .13),
            Offset(-.15, .04),
          ],
          const Color(0xffead3ae),
          stroke: _ink,
        );
        _lines(
          canvas,
          const [Offset(-.09, -.12), Offset(.05, .11), Offset(.14, .01)],
          loot.scroll == LiteScroll.raggioAlPlasma
              ? _plasma
              : const Color(0xff9a5360),
          .065,
        );
      case LiteLootKind.healing:
        _poly(
          canvas,
          const [
            Offset(-.14, .09),
            Offset(-.19, -.04),
            Offset(-.11, -.17),
            Offset(.01, -.16),
            Offset(.16, -.23),
            Offset(.17, -.05),
            Offset(.07, .13),
            Offset(-.04, .20),
          ],
          const Color(0xff567a65),
          stroke: _ink,
        );
        _lines(
          canvas,
          const [Offset(-.10, .09), Offset(.01, -.03), Offset(.09, -.12)],
          _active,
          .067,
        );
      case LiteLootKind.weapon:
        if (loot.weapon?.isBossLoot != true) {
          _poly(
            canvas,
            const [
              Offset(-.31, -.27),
              Offset(.17, -.32),
              Offset(.35, -.01),
              Offset(.21, .23),
              Offset(-.18, .31),
              Offset(-.34, .065),
            ],
            const Color(0xff42384b),
            stroke: _ink,
            width: .046,
          );
        }
        final weapon = loot.weapon;
        if (weapon != null) {
          _actor(
            canvas,
            const Offset(-.105, -.02),
            loot.weapon!.isBossLoot ? .74 : .56,
            loot.weapon!.isBossLoot ? .74 : .56,
            () {
              canvas.rotate(-.30 + math.sin(time * 2.4 + at.dx) * .18);
              _holdWeapon(canvas, weapon, gear, _plasma, _ink);
            },
          );
        }
      case LiteLootKind.greenStone:
      case LiteLootKind.refinedGreenGem:
        _greenCrystal(
          canvas,
          Offset.zero,
          loot.kind == LiteLootKind.refinedGreenGem,
          time,
        );
    }
  });
}

void _greenCrystal(Canvas canvas, Offset at, bool refined, double time) {
  _actor(canvas, at, refined ? 1.45 : 1, refined ? 1.45 : 1, () {
    final luminous = refined
        ? const Color(0xffbcfac9)
        : const Color(0xff62c480);
    _poly(
      canvas,
      const [
        Offset(-.18, -.05),
        Offset(-.092, -.225),
        Offset(.118, -.191),
        Offset(.204, -.016),
        Offset(.013, .22),
      ],
      const Color(0xff254e43),
      stroke: _ink,
      width: .038,
    );
    _poly(canvas, const [
      Offset(-.18, -.05),
      Offset(-.092, -.225),
      Offset(.118, -.191),
      Offset(.044, -.019),
    ], luminous);
    _lines(
      canvas,
      const [Offset(.013, .18), Offset(.044, -.019), Offset(.19, -.02)],
      luminous.withValues(alpha: .55),
      .035,
    );
    if (refined) {
      final gleam = (.61 + math.sin(time * 5) * .23);
      final color = luminous.withValues(alpha: gleam);
      _lines(canvas, const [Offset(.21, -.29), Offset(.43, -.29)], color, .034);
      _lines(canvas, const [Offset(.32, -.42), Offset(.32, -.17)], color, .035);
    }
  });
}

void _restShrine(Canvas canvas, Offset at, bool active, double time) {
  _shadow(canvas, at, .70, .32, alpha: .64);
  _poly(
    canvas,
    [
      at + const Offset(-.72, .05),
      at + const Offset(-.35, -.42),
      at + const Offset(.37, -.43),
      at + const Offset(.68, -.03),
      at + const Offset(.37, .26),
      at + const Offset(-.35, .27),
    ],
    const Color(0xff576151),
    stroke: _ink,
    width: .085,
  );
  _oval(
    canvas,
    at - const Offset(0, .14),
    .88,
    .38,
    active ? const Color(0xff396453) : const Color(0xff28292a),
    stroke: const Color(0xff17211d),
    strokeWidth: .05,
  );
  if (active) {
    _greenCrystal(
      canvas,
      at - Offset(0, .52 + .08 * math.sin(time * 3)),
      true,
      time,
    );
  }
}

void _portal(
  Canvas canvas,
  Offset at, {
  required bool active,
  required double time,
}) {
  _actor(canvas, at, 1, 1, () {
    final stone = active ? const Color(0xff678a85) : const Color(0xff58536e);
    _shadow(canvas, const Offset(0, .03), .96, .31, alpha: .65);
    _poly(
      canvas,
      const [
        Offset(-.76, .1),
        Offset(-.69, -1.21),
        Offset(-.47, -1.58),
        Offset(.41, -1.60),
        Offset(.74, -1.22),
        Offset(.78, .12),
        Offset(.48, .12),
        Offset(.48, -.94),
        Offset(.32, -1.19),
        Offset(-.30, -1.21),
        Offset(-.46, -.94),
        Offset(-.45, .12),
      ],
      stone,
      stroke: _ink,
      width: .08,
    );
    _poly(canvas, const [
      Offset(-.46, .03),
      Offset(-.44, -.90),
      Offset(-.29, -1.19),
      Offset(.32, -1.18),
      Offset(.47, -.94),
      Offset(.48, .03),
    ], active ? const Color(0xff335b61) : _ink);
    _lines(
      canvas,
      const [
        Offset(-.68, -.12),
        Offset(-.62, -1.14),
        Offset(-.40, -1.43),
        Offset(-.10, -1.45),
      ],
      Color.lerp(stone, _sand, .29)!,
      .061,
    );
    _dryBrush(
      canvas,
      const Offset(-.69, -.25),
      const Offset(.013, -.129),
      const Offset(.149, .057),
      _ink.withValues(alpha: .82),
      7,
      width: .035,
    );
    _dryBrush(
      canvas,
      const Offset(.48, -.30),
      const Offset(.014, -.118),
      const Offset(.182, -.039),
      _ink.withValues(alpha: .73),
      7,
      width: .035,
    );
    _poly(
      canvas,
      const [
        Offset(-.12, -1.62),
        Offset(.05, -1.67),
        Offset(.18, -1.57),
        Offset(.11, -1.35),
        Offset(-.04, -1.37),
        Offset(-.16, -1.46),
      ],
      active ? _active : const Color(0xffb0a292),
      stroke: _ink,
      width: .054,
    );
    if (active) {
      for (var i = 0; i < 3; i++) {
        final t = ((time * .44 + i / 3) % 1);
        _oval(
          canvas,
          Offset(0, -.28 - t * .52),
          .24 + t * .49,
          .13 + t * .16,
          _active.withValues(alpha: .19 + (1 - t) * .31),
        );
      }
      _lines(
        canvas,
        const [Offset(-.35, .09), Offset(.37, .09)],
        _active,
        .075,
      );
    }
  });
}

void _merchant(
  Canvas canvas,
  Offset at, {
  required bool active,
  required double time,
}) {
  _actor(canvas, at, 1, 1, () {
    _shadow(canvas, const Offset(0, .04), 1.1, .49, alpha: .66);
    _poly(
      canvas,
      const [
        Offset(-.93, -.17),
        Offset(-.83, -.88),
        Offset(.84, -.87),
        Offset(.94, -.22),
        Offset(.81, .14),
        Offset(-.79, .13),
      ],
      const Color(0xff735242),
      stroke: _ink,
    );
    _poly(
      canvas,
      const [
        Offset(-1.08, -.86),
        Offset(-.71, -1.50),
        Offset(.71, -1.50),
        Offset(1.10, -.86),
        Offset(.79, -.61),
        Offset(.39, -.75),
        Offset(.0, -.59),
        Offset(-.40, -.75),
        Offset(-.78, -.62),
      ],
      const Color(0xff885053),
      stroke: _ink,
      width: .073,
    );
    _lines(
      canvas,
      const [Offset(-.70, -1.34), Offset(.70, -1.34)],
      _sand.withValues(alpha: .70),
      .055,
    );
    _poly(canvas, const [
      Offset(-.68, -1.36),
      Offset(.70, -1.41),
      Offset(.995, -.87),
      Offset(.78, -.76),
      Offset(.365, -.88),
      Offset(-.14, -.82),
      Offset(-.59, -.91),
      Offset(-.86, -.83),
    ], const Color(0xff572f3b));
    _dryBrush(
      canvas,
      const Offset(-.67, -1.25),
      const Offset(.139, -.011),
      const Offset(.143, .342),
      const Color(0xffb87764),
      10,
      width: .045,
    );
    _dryBrush(
      canvas,
      const Offset(-.67, -.21),
      const Offset(.139, .014),
      const Offset(.07, .245),
      const Color(0xff492c31),
      10,
      width: .050,
    );
    _lines(
      canvas,
      const [Offset(-.69, -.44), Offset(.69, -.44)],
      const Color(0xffb38160),
      .16,
    );
    _oval(
      canvas,
      const Offset(-.49, -.48),
      .19,
      .30,
      const Color(0xffb28373),
      stroke: _ink,
    );
    _lines(
      canvas,
      const [Offset(-.55, -.61), Offset(-.49, -.66), Offset(-.44, -.59)],
      _sand,
      .041,
    );
    _lines(
      canvas,
      const [Offset(.24, -.50), Offset(.34, -.47), Offset(.41, -.51)],
      const Color(0xffc4a3ac),
      .031,
    );
    _oval(
      canvas,
      const Offset(.32, -.49),
      .23,
      .33,
      const Color(0xff8e6d91),
      stroke: _ink,
    );
    if (active) {
      final glow = .71 + math.sin(time * 4) * .12;
      _oval(
        canvas,
        const Offset(.79, -.73),
        .49,
        .50,
        _sand.withValues(alpha: glow * .25),
      );
      _oval(canvas, const Offset(.79, -.76), .14, .20, _sand, stroke: _ink);
    }
  });
}

void _reticle(Canvas canvas, Offset at, LiteWeapon weapon) {
  final color = weapon.isPostea
      ? _plasma
      : weapon == LiteWeapon.scettro
      ? const Color(0xffd9c6ff)
      : const Color(0xfff2dec3);
  final lines = [
    [at + const Offset(-.20, 0), at + const Offset(-.07, 0)],
    [at + const Offset(.07, 0), at + const Offset(.20, 0)],
    [at + const Offset(0, -.22), at + const Offset(0, -.08)],
    [at + const Offset(0, .08), at + const Offset(0, .22)],
  ];
  for (final line in lines) {
    _lines(canvas, line, _ink, .08);
    _lines(canvas, line, color, .036);
  }
}

void _paintGroundShot(Canvas canvas, Offset at, LiteGroundShot ground) {
  final alpha = (ground.remaining / .35).clamp(0.0, 1.0);
  final pigment = ground.sticky
      ? const Color(0xffc49245)
      : const Color(0xff523024);
  final light = ground.sticky
      ? const Color(0xfff5d27d)
      : const Color(0xffa36341);
  final path = [
    at + const Offset(-1.36, -.45),
    at + const Offset(-.86, -1.07),
    at + const Offset(-.16, -.96),
    at + const Offset(.71, -1.22),
    at + const Offset(1.31, -.68),
    at + const Offset(1.14, -.1),
    at + const Offset(1.39, .59),
    at + const Offset(.75, 1.03),
    at + const Offset(.08, .84),
    at + const Offset(-.72, 1.05),
    at + const Offset(-1.26, .54),
  ];
  _poly(
    canvas,
    path,
    pigment.withValues(alpha: alpha * .85),
    stroke: _ink.withValues(alpha: alpha * .77),
    width: .10,
  );
  _lines(
    canvas,
    [
      at + const Offset(-.79, -.61),
      at + const Offset(-.29, -.42),
      at + const Offset(.1, -.64),
    ],
    light.withValues(alpha: alpha * .76),
    .08,
  );
  _oval(
    canvas,
    at + const Offset(.56, .22),
    .23,
    .18,
    light.withValues(alpha: alpha * .48),
  );
}

void _paintMudOnScreen(Canvas canvas, Size size, double remaining) {
  final slide = ((.31 - remaining) / .31).clamp(0.0, 1.0);
  canvas.save();
  canvas.scale(size.width, size.height);
  canvas.translate(0, slide * slide * 1.12);
  final coverage = Path()
    ..moveTo(-.06, -.08)
    ..lineTo(1.08, -.08)
    ..lineTo(1.08, .64)
    ..cubicTo(.92, .86, .79, .42, .72, .60)
    ..cubicTo(.57, .96, .53, .58, .45, .71)
    ..cubicTo(.31, .86, .31, .55, .22, .77)
    ..cubicTo(.08, 1.02, .08, .78, -.07, 1.10)
    ..close();
  final opacity = 1 - slide * .32;
  canvas.drawPath(
    coverage,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xff291310), Color(0xf878422a), Color(0xff361b17)],
      ).createShader(const Rect.fromLTRB(0, 0, 1, 1)),
  );
  final dark = Paint()
    ..color = const Color(0xff44241d).withValues(alpha: .78 * opacity);
  final light = Paint()
    ..color = const Color(0xffbc7850).withValues(alpha: .6 * opacity);
  final random = math.Random(376);
  for (var i = 0; i < 22; i++) {
    final x = random.nextDouble();
    final y = random.nextDouble() * .53;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: .018 + random.nextDouble() * .083,
        height: .019 + random.nextDouble() * .23,
      ),
      i % 3 == 0 ? light : dark,
    );
  }
  for (var i = 0; i < 7; i++) {
    final x = .04 + i * .141;
    final y = .72 + random.nextDouble() * .27;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: .015 + random.nextDouble() * .04,
        height: .04 + random.nextDouble() * .07,
      ),
      dark,
    );
  }
  canvas.restore();
}

void _projectile(
  Canvas canvas,
  LiteProjectile projectile, {
  LiteInkFinish finish = LiteInkFinish.canonica,
}) {
  final p = _offset(projectile.position);
  final heading = _offset(projectile.direction);
  switch (projectile.kind) {
    case LiteProjectileKind.chakram:
      final turn = projectile.age * 27;
      final ring = Rect.fromCenter(center: p, width: .50, height: .31);
      final blade = Paint()
        ..color = const Color(0xffb8e3d6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .058;
      canvas.drawArc(ring, turn, 2.45, false, blade);
      canvas.drawArc(ring, turn + math.pi, 2.45, false, blade);
      _inkSlash(canvas, p - heading * .50, p, const Color(0x7890ddd0), .057);
    case LiteProjectileKind.solarBolt || LiteProjectileKind.solarRay:
      final ray = projectile.kind == LiteProjectileKind.solarRay;
      final tail = p - heading * (ray ? 1.9 : .55);
      _inkSlash(
        canvas,
        tail,
        p + heading * .21,
        const Color(0xff693a20),
        ray ? .35 : .12,
      );
      _inkSlash(
        canvas,
        tail + heading * .15,
        p + heading * .18,
        const Color(0xffe6a94a),
        ray ? .21 : .08,
      );
      _inkSlash(
        canvas,
        tail + heading * .35,
        p,
        const Color(0xffffe7a4),
        ray ? .09 : .034,
      );
    case LiteProjectileKind.posteaRay:
      final (edge, light, core) = switch (finish) {
        LiteInkFinish.canonica => (
          const Color(0x9951b3bd),
          const Color(0xff54d9df),
          const Color(0xffdbfff4),
        ),
        LiteInkFinish.cremisi => (
          const Color(0x99ad462a),
          const Color(0xffff9b51),
          const Color(0xffffe1aa),
        ),
        LiteInkFinish.patina => (
          const Color(0x996cab98),
          const Color(0xff86f0bd),
          const Color(0xffdcffe6),
        ),
      };
      final tail = p - heading * .94;
      _inkSlash(canvas, tail, p + heading * .18, edge, .19);
      _inkSlash(canvas, tail + heading * .13, p + heading * .16, light, .095);
      _inkSlash(canvas, tail + heading * .30, p, core, .046);
    case LiteProjectileKind.egg || LiteProjectileKind.posteaEgg:
      final mechanical = projectile.kind == LiteProjectileKind.posteaEgg;
      final planted = projectile.eggFuse;
      final at =
          p -
          Offset(
            0,
            planted == null ? .40 + math.sin(projectile.age * 10) * .14 : .10,
          );
      _shadow(canvas, p, .16, .075);
      _oval(
        canvas,
        at,
        mechanical ? .35 : .29,
        mechanical ? .43 : .36,
        mechanical ? const Color(0xff8e673b) : const Color(0xffdfbd8a),
        stroke: const Color(0xff2b1920),
        strokeWidth: .054,
      );
      _inkSlash(
        canvas,
        at + const Offset(-.06, -.04),
        at + const Offset(.035, -.11),
        planted != null && (projectile.age * 14).floor().isEven
            ? const Color(0xffef8d63)
            : mechanical
            ? const Color(0xff5ce6d8)
            : const Color(0xfff8dda7),
        mechanical ? .060 : .045,
      );
    case LiteProjectileKind.lunarCrescent:
      final sweep = Rect.fromCenter(center: p, width: .4, height: .4);
      final dawn = Paint()
        ..color = const Color(0xffc6c7ff)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .068;
      canvas.drawArc(
        sweep,
        math.atan2(heading.dy, heading.dx) - 1.18,
        2.36,
        false,
        dawn,
      );
      _inkSlash(canvas, p - heading * .55, p, const Color(0x80ba8aee), .09);
    case LiteProjectileKind.spiral:
      _inkSlash(
        canvas,
        p - heading * .38,
        p + heading * .13,
        const Color(0xffb99df9),
        .076,
      );
      canvas.drawCircle(p, .105, Paint()..color = const Color(0xffe5d7ff));
    case LiteProjectileKind.fireball:
      final a = projectile.age * 17;
      final side = Offset(-heading.dy, heading.dx);
      _poly(
        canvas,
        [
          p + heading * .21,
          p + side * .25,
          p - heading * .89 + side * .11,
          p - heading * .52 - side * .06,
          p - side * .25,
        ],
        const Color(0xffee612f),
        stroke: _ink,
        width: .045,
      );
      _poly(canvas, [
        p + heading * .19,
        p + side * .14,
        p - heading * .3,
        p - side * .14,
      ], const Color(0xffffc265));
      canvas.drawCircle(
        p + side * math.sin(a) * .05,
        .085,
        Paint()..color = const Color(0xffffedb4),
      );
    case LiteProjectileKind.mud || LiteProjectileKind.glue:
      final glue = projectile.kind == LiteProjectileKind.glue;
      final colors = glue
          ? (const Color(0xffdca653), const Color(0xffffdf94))
          : (const Color(0xff633825), const Color(0xffbb7548));
      _oval(canvas, p, .21, .15, colors.$1, stroke: _ink, strokeWidth: .04);
      _lines(canvas, [p - heading * .3, p + heading * .05], colors.$2, .065);
    case LiteProjectileKind.bomb:
      final lifted = p - Offset(0, .38 + .18 * math.sin(projectile.age * 6));
      _shadow(canvas, p, .23, .13);
      _oval(
        canvas,
        lifted,
        .28,
        .22,
        const Color(0xff3f2d38),
        stroke: _ink,
        strokeWidth: .06,
      );
      _lines(
        canvas,
        [
          lifted - const Offset(0, .09),
          lifted + const Offset(.09, -.28),
          lifted + const Offset(.16, -.31),
        ],
        _sand,
        .053,
      );
      canvas.drawCircle(
        lifted + const Offset(.16, -.31),
        .089,
        Paint()..color = _ember,
      );
    case LiteProjectileKind.scythe:
      _lines(
        canvas,
        [p - heading * .49, p],
        _plasma.withValues(alpha: .51),
        .12,
      );
      _actor(canvas, p, .68, .68, () {
        canvas.rotate(projectile.age * 15);
        canvas.translate(-.41, .14);
        _weapon(canvas, LiteWeapon.falceRunica, _plasma, _ink);
      });
      return;
    case LiteProjectileKind.pulse:
    case LiteProjectileKind.plasma:
      final plasma = projectile.kind == LiteProjectileKind.plasma;
      final length = plasma ? 1.45 : .92;
      final tail = p - heading * length;
      _lines(
        canvas,
        [tail, p],
        _plasma.withValues(alpha: .31),
        plasma ? .29 : .14,
      );
      _lines(
        canvas,
        [tail + heading * .19, p + heading * .13],
        plasma ? const Color(0xffdef9d3) : _plasma,
        plasma ? .11 : .07,
      );
      _oval(canvas, p, .21, .18, const Color(0xffe9ffd9));
      return;
    case LiteProjectileKind.cannon:
      _lines(
        canvas,
        [p - heading * .74, p],
        _ember.withValues(alpha: .47),
        .22,
      );
      _oval(canvas, p, .66, .63, _ember.withValues(alpha: .44));
      _oval(
        canvas,
        p,
        .45,
        .43,
        const Color(0xff442d32),
        stroke: _ember,
        strokeWidth: .067,
      );
      _oval(canvas, p + heading * .17, .16, .15, _sand);
      return;
    case LiteProjectileKind.frostBolt:
      final tail = p - heading * .83;
      _inkSlash(canvas, tail, p + heading * .18, const Color(0xff2c475b), .115);
      _inkSlash(
        canvas,
        tail + heading * .24,
        p + heading * .21,
        const Color(0xffbfeaf0),
        .072,
      );
      return;
    case LiteProjectileKind.rifleBullet || LiteProjectileKind.rifleCritical:
      final critical = projectile.kind == LiteProjectileKind.rifleCritical;
      _lines(canvas, [p - heading * .87, p], critical ? _violet : _ember, .064);
      _oval(canvas, p, .19, .11, critical ? const Color(0xffe4d2ff) : _sand);
      return;
    case LiteProjectileKind.veyrthSphere:
      _inkSlash(canvas, p - heading * .68, p, const Color(0xff92466b), .16);
      _paintVeyrthSphere(canvas, p, 1, projectile.age * 17);
      return;
    case LiteProjectileKind.normal:
      break;
  }
  final tint = projectile.fromEnemy
      ? _ember
      : projectile.magic
      ? _violet
      : _sand;
  final tail = p - heading * (projectile.magic ? .68 : .34);
  _lines(canvas, [tail, p], tint.withValues(alpha: .37), .11);
  if (projectile.boomerang) {
    _actor(canvas, p, 1, 1, () {
      canvas.rotate(projectile.age * 19);
      _poly(
        canvas,
        const [
          Offset(-.24, .25),
          Offset(-.04, -.29),
          Offset(.29, -.12),
          Offset(.34, -.01),
          Offset(.06, -.08),
          Offset(-.13, .24),
        ],
        tint,
        stroke: _ink,
        width: .047,
      );
    });
    return;
  }
  final size = projectile.fromEnemy || projectile.magic ? .28 : .17;
  _oval(canvas, p, size * 2.0, size * 1.5, tint.withValues(alpha: .24));
  _oval(canvas, p, size, size * .7, tint, stroke: _ink, strokeWidth: .04);
  _oval(
    canvas,
    p - const Offset(.025, .04),
    .06,
    .044,
    const Color(0xfffff2d6),
  );
}

void _paintVeyrthSphereRing(
  Canvas canvas,
  LiteEnemy boss,
  double time,
  double animationLead,
) {
  final charge = (1 - (boss.windup - animationLead) / LiteRun.finalSphereWindup)
      .clamp(0.0, 1.0);
  final center = _offset(boss.position);
  final radius = LiteRun.finalSphereRingRadius * (.48 + .52 * charge);
  _oval(
    canvas,
    center,
    radius * 2,
    radius * 2,
    const Color(0x158f3b64),
    stroke: const Color(0xffac5878).withValues(alpha: .32 + .48 * charge),
    strokeWidth: .034,
  );
  for (var i = 0; i < LiteRun.finalSphereCount; i++) {
    final at = center + _offset(boss.sphereDirection(i)) * radius;
    _paintVeyrthSphere(canvas, at, .4 + .6 * charge, time * 17 + i);
  }
}

const _staffLightning = Color(0xffa7edfc);

void _paintStaffOrbit(Canvas canvas, Offset center, double time) {
  final phase = time * 5.2;
  for (final offset in [0.0, math.pi]) {
    final angle = phase + offset;
    final p = center + Offset(math.cos(angle) * .87, math.sin(angle) * .54);
    final tail =
        center +
        Offset(math.cos(angle - .58) * .87, math.sin(angle - .58) * .54);
    _inkSlash(canvas, tail, p, const Color(0xff486e89), .105);
    _oval(
      canvas,
      p,
      .18,
      .16,
      _staffLightning,
      stroke: _ink,
      strokeWidth: .035,
    );
  }
}

void _paintStaffDischarge(
  Canvas canvas,
  Offset source,
  Offset target,
  double time,
) {
  final delta = target - source;
  if (delta.distanceSquared < .01) return;
  final side = Offset(-delta.dy, delta.dx) / delta.distance;
  final zig = [
    source,
    source + delta * .28 + side * .15,
    source + delta * .46 - side * .12,
    source + delta * .68 + side * .10,
    target,
  ];
  _lines(canvas, zig, const Color(0xff497a9e), .104);
  _lines(canvas, zig, _staffLightning, .045);
  _oval(
    canvas,
    target,
    .23 + .05 * math.sin(time * 28),
    .17,
    const Color(0xffecfbff),
  );
}

void _paintVeyrthSphere(Canvas canvas, Offset p, double scale, double spin) {
  final ball = .38 * scale;
  const plum = Color(0xff3b1838);
  const rose = Color(0xffee9da3);
  final glint = Offset(math.cos(spin), math.sin(spin));
  _oval(canvas, p, ball * 1.55, ball * 1.55, const Color(0x64a64878));
  _oval(canvas, p, ball, ball, plum, stroke: rose, strokeWidth: .038 * scale);
  _oval(
    canvas,
    p + glint * (.083 * scale),
    .14 * scale,
    .12 * scale,
    const Color(0xffffd79e),
  );
}

void _enemyWarning(Canvas canvas, LiteEnemy enemy) {
  final at = _offset(enemy.position);
  final target = enemy.attackTarget;
  final plasmaRanged =
      enemy.kind == LiteEnemyKind.ragnoSaldatore ||
      enemy.kind == LiteEnemyKind.dronePostea;
  final ranged =
      enemy.kind == LiteEnemyKind.scostubandito ||
      enemy.kind == LiteEnemyKind.granScostumato ||
      plasmaRanged;
  final imminent = (1 - enemy.windup / .29).clamp(0.0, 1.0);
  if (ranged && target != null) {
    final end = _offset(target);
    final direction = end - at;
    final segments = (direction.distance / .55).ceil();
    for (var i = 0; i < segments; i++) {
      _lines(
        canvas,
        [
          at + direction * (i / segments),
          at + direction * ((i + .53) / segments),
        ],
        (plasmaRanged ? _plasma : _ember).withValues(
          alpha: .39 + imminent * .53,
        ),
        .029 + imminent * .035,
      );
    }
    if (imminent > .45 && direction.distanceSquared > .1) {
      final front = direction / direction.distance;
      final side = Offset(-front.dy, front.dx);
      _lines(
        canvas,
        [end - front * .35 + side * .20, end, end - front * .35 - side * .20],
        (plasmaRanged ? _plasma : _ember).withValues(alpha: imminent),
        .055,
      );
    }
  } else {
    final reach = 1.35 + enemy.radius;
    _oval(
      canvas,
      at,
      reach * 2,
      reach * 2,
      _ember.withValues(alpha: .07 + imminent * .13),
      stroke: _ember.withValues(alpha: .48 + imminent * .42),
      strokeWidth: .039 + imminent * .025,
    );
  }
}

class _HeroPreviewPaint extends CustomPainter {
  _HeroPreviewPaint(
    this.appearance,
    this.hero,
    this.weapon,
    this.showClone,
    this.gear,
    this.figure,
    this.heads,
  );

  final OculumLiteAppearance appearance;
  final LiteHero hero;
  final LiteWeapon weapon;
  final bool showClone;
  final ui.Image? gear;
  final ui.Image? figure;
  final ui.Image? heads;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = math.min(
      size.height / 4.05,
      size.width / (showClone ? 5.90 : 2.65),
    );
    final center = showClone ? .36 : .48;
    final baseline = size.height * .89;
    canvas.save();
    canvas.translate(size.width * center, baseline);
    canvas.scale(scale);
    if (hero == LiteHero.ashley && figure != null) {
      _shadow(canvas, Offset.zero, .61, .24);
      _paintAshley(canvas, figure!, 0, gear, weapon, const Offset(1, 0));
      canvas.restore();
      return;
    }
    final body = hero == LiteHero.evasore ? figure : null;
    final poses = hero == LiteHero.duplicatore ? figure : null;
    if (showClone) {
      _actor(canvas, const Offset(2.15, -.03), .90, .90, () {
        _shadow(canvas, Offset.zero, .57, .23);
        _hero(
          canvas,
          appearance,
          weapon,
          1,
          hero: hero,
          clone: true,
          gearArt: gear,
          figureArt: body,
          poseArt: poses,
          heads: heads,
        );
      });
    }
    _shadow(canvas, Offset.zero, .61, .24);
    _paintInkFinish(canvas, Offset.zero, appearance.inkFinish, 0);
    _hero(
      canvas,
      appearance,
      weapon,
      0,
      hero: hero,
      banditArt: hero.sprite != null ? figure : null,
      newActors: _newHeroRow(hero, false) != null ? figure : null,
      nightActors: _nightHeroRow(hero, false) != null ? figure : null,
      faunaActors: LiteAnimal.forHero(hero) != null ? figure : null,
      mechanicalChicken: hero == LiteHero.polloMeccanico ? figure : null,
      solarActors: hero.solar ? figure : null,
      infernalActors: hero.infernal ? figure : null,
      bossArt: hero == LiteHero.veyrth ? figure : null,
      gearArt: gear,
      figureArt: body,
      poseArt: poses,
      heads: heads,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeroPreviewPaint oldDelegate) =>
      oldDelegate.appearance != appearance ||
      oldDelegate.hero != hero ||
      oldDelegate.weapon != weapon ||
      oldDelegate.gear != gear ||
      oldDelegate.figure != figure ||
      oldDelegate.heads != heads ||
      oldDelegate.showClone != showClone;
}
