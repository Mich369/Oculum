import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_alert_dialogue.dart';
import 'package:oculum_rl/game/oculum_lite_audio.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/widgets/oculum_lite_alert_subtitle.dart';

Iterable<LiteAlertCall> _calls(List<List<Object?>> cues, {double time = 5}) {
  final run = LiteRun(
    seed: 251,
    hero: LiteHero.evasore,
    weapon: LiteWeapon.arco,
  )..time = time;
  final snapshot = run.toJson(includeEffects: true);
  snapshot['alertSignals'] = {'room': run.inputArena, 'cues': cues};
  return LiteRun.fromJson(snapshot).alertCalls;
}

LiteAlertDialogue _line({
  LiteEnemyKind? enemy,
  LiteHero? hero,
  bool fiveFlames = false,
}) => liteAlertDialogue(
  _calls([
    [1, 4.0, enemy?.name, hero?.name, fiveFlames, null],
  ]).single,
)!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each playable and encounter creature has a named dialogue cue', () {
    final voiced = liteAlertSpokenLines();
    for (final hero in LiteHero.values) {
      final line = _line(hero: hero);
      expect(line.speaker, isNotEmpty);
      expect(line.text, isNotEmpty);
      expect(line.hostile, isFalse);
      if (line.spokenKey case final key?) {
        expect(voiced[key]?.text, line.text);
      }
    }
    for (final enemy in LiteEnemyKind.values) {
      final line = _line(enemy: enemy);
      expect(line.speaker, enemy.label);
      expect(line.text, isNotEmpty);
      expect(line.hostile, isTrue);
      if (line.spokenKey case final key?) {
        expect(voiced[key]?.text, line.text);
      }
    }
  });

  test('canonical Italian, creature roars and knowledgeable mirrors', () {
    expect(_line(hero: LiteHero.evasore).text, 'ops, mi avete visto eheh');
    expect(
      _line(hero: LiteHero.ashley).text,
      'non mi giudicate debole solo per la mia età!',
    );
    expect(
      _line(enemy: LiteEnemyKind.eliteSolare).text,
      'Che il Sole illumini la vostra via',
    );
    expect(
      _line(enemy: LiteEnemyKind.scostubandito).text,
      'Hey stronzo ti faccio rigirare il culo!',
    );
    expect(
      _line(hero: LiteHero.granScostumato).text,
      'Hey non romperti subito',
    );
    final small = _line(enemy: LiteEnemyKind.demoneMinore);
    final large = _line(enemy: LiteEnemyKind.demoneIntermedio);
    expect(small.spokenKey, isNull);
    expect(large.spokenKey, isNull);
    expect(small.sound, isNot(large.sound));
    final devil = _line(enemy: LiteEnemyKind.diavolo);
    final flames = _line(enemy: LiteEnemyKind.diavolo, fiveFlames: true);
    expect(devil.spokenKey, isNot(flames.spokenKey));
    expect(flames.text, contains('stronzo'));
    expect(liteAlertSpokenLines()[flames.spokenKey]?.text, flames.text);

    final echo = _line(enemy: LiteEnemyKind.ombra, hero: LiteHero.ashley);
    expect(echo.speaker, LiteEnemyKind.ombra.label);
    expect(echo.sound, LiteAlertSound.ombra);
    expect(echo.spokenKey, 'ashley');
    expect(echo.text, _line(hero: LiteHero.ashley).text);
  });

  test(
    'all original cue WAVs are bundled, nonempty and individually voiced',
    () async {
      final lengths = <int>{};
      for (final cue in LiteAlertSound.values) {
        final wav = await rootBundle.load(
          'assets/oculum/lite/audio/${cue.asset}.wav',
        );
        final header = String.fromCharCodes(
          wav.buffer.asUint8List(wav.offsetInBytes, 4),
        );
        expect(header, 'RIFF');
        expect(wav.getUint16(22, Endian.little), 1);
        expect(wav.lengthInBytes, inInclusiveRange(6000, 55000));
        lengths.add(wav.lengthInBytes);
      }
      expect(lengths.length, greaterThan(20));
    },
  );

  test('the complete Italian speech bank is bundled as mono PCM WAV', () async {
    final lines = liteAlertSpokenLines();
    expect(lines.length, greaterThan(30));
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = assetManifest.listAssets().toSet();
    final lengths = <int>{};
    for (final key in lines.keys) {
      final path = 'assets/oculum/lite/audio/alert-lines/$key.wav';
      expect(bundled, contains(path));
      final wav = await rootBundle.load(path);
      final header = wav.buffer.asUint8List(wav.offsetInBytes, 12);
      expect(String.fromCharCodes(header.take(4)), 'RIFF');
      expect(String.fromCharCodes(header.skip(8)), 'WAVE');
      expect(wav.getUint16(20, Endian.little), 1);
      expect(wav.getUint16(22, Endian.little), 1);
      expect(wav.lengthInBytes, greaterThan(30000));
      lengths.add(wav.lengthInBytes);
    }
    expect(lengths.length, greaterThan(25));
  });

  test(
    'subtitles follow a playing line without interrupting or overlapping it',
    () {
      final heard = <LiteAlertDialogue>[];
      var clock = Duration.zero;
      var speaking = true;
      final presenter = LiteAlertPresenter(
        play: heard.add,
        stop: () {},
        speaking: () => speaking,
        clock: () => clock,
      );
      addTearDown(presenter.dispose);
      final session = Object();

      void update(Iterable<LiteAlertCall> calls) => presenter.receive(
        calls,
        time: 5,
        session: session,
        scene: 'stage-0',
        viewerId: 0,
        playing: true,
      );

      update(
        _calls([
          [1, 4.7, null, 'ashley', false, 0],
        ]),
      );
      expect(presenter.value?.speaker, 'Ashley');

      clock = const Duration(milliseconds: 4000);
      update(
        _calls([
          [2, 4.9, 'diavolo', null, false, null],
        ]),
      );
      expect(presenter.value?.speaker, 'Ashley');
      expect(heard, hasLength(1));

      speaking = false;
      update(const []);
      expect(presenter.value?.speaker, LiteEnemyKind.diavolo.label);
      expect(heard, hasLength(2));
    },
  );

  test('the muted alert mixer leaves the subtitle available', () {
    final audio = OculumLiteAudio()..muted = true;
    addTearDown(audio.dispose);
    final presenter = LiteAlertPresenter(
      play: audio.playAlert,
      stop: audio.stopAlert,
      speaking: () => audio.alertSpeaking,
    );
    addTearDown(presenter.dispose);
    presenter.receive(
      _calls([
        [1, 4.7, 'demoneMinore', null, false, null],
      ]),
      time: 5,
      session: 'muted',
      viewerId: 0,
      playing: true,
    );
    expect(audio.alertSpeaking, isFalse);
    expect(presenter.value?.speaker, LiteEnemyKind.demoneMinore.label);
  });

  test('audience, age, pacing and duplicated co-op snapshots', () {
    final heard = <LiteAlertDialogue>[];
    var stops = 0;
    var clock = Duration.zero;
    final presenter = LiteAlertPresenter(
      play: heard.add,
      stop: () => stops++,
      clock: () => clock,
    );
    addTearDown(presenter.dispose);
    final session = Object();
    final records = <List<Object?>>[
      [1, 1.5, 'baghest', null, false, null],
      [2, 4.7, null, 'duplicatore', false, 20],
      [3, 4.8, 'forestDemon', null, false, null],
      [4, 4.9, null, 'ashley', false, 10],
    ];
    void update({bool playing = true, String scene = 'stage-0'}) {
      presenter.receive(
        _calls(records),
        time: 5,
        session: session,
        scene: scene,
        viewerId: 10,
        playing: playing,
      );
    }

    update();
    expect(heard.map((x) => x.speaker), ['Ashley']);
    update();
    expect(heard, hasLength(1));
    clock += const Duration(seconds: 4);
    update();
    expect(heard.map((x) => x.speaker), ['Ashley', 'Forest Demon']);
    update();
    expect(heard, hasLength(2));
    update(playing: false);
    expect(presenter.value, isNull);
    expect(stops, 1);
    update(scene: 'stage-1');
    expect(presenter.value, isNull);
    expect(heard, hasLength(2));
  });

  testWidgets(
    'mobile subtitle preserves exact text and leaves controls usable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(350, 660);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final presenter = LiteAlertPresenter(play: (_) {}, stop: () {});
      addTearDown(presenter.dispose);
      var attacks = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.75)),
            child: child!,
          ),
          home: Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OculumLiteAlertSubtitle(presenter: presenter),
                Center(
                  child: TextButton(
                    onPressed: () => attacks++,
                    child: const Text('Attacca'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      presenter.receive(
        _calls([
          [1, 4.8, null, 'ashley', false, 0],
        ]),
        time: 5,
        session: 'simulated',
        viewerId: 0,
        playing: true,
      );
      await tester.pump();
      expect(find.text('Ashley'), findsOneWidget);
      expect(
        find.text('non mi giudicate debole solo per la mia età!'),
        findsOneWidget,
      );
      await tester.tap(find.text('Attacca'));
      expect(attacks, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
