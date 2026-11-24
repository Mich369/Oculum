import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_audio.dart';
import 'package:oculum_rl/widgets/oculum_lite_merchant_greeting.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh audio settings use 35% music and 50% effects', () async {
    SharedPreferences.setMockInitialValues({});
    final mixer = OculumLiteAudio();
    addTearDown(mixer.dispose);
    mixer.restorePreferences(await SharedPreferences.getInstance());
    expect(mixer.musicVolume, .35);
    expect(mixer.effectsVolume, .50);
    expect(mixer.muted, isFalse);
  });

  test('existing volume and mute preferences are retained', () async {
    SharedPreferences.setMockInitialValues({
      OculumLiteAudio.preferenceKey('musica'): .71,
      OculumLiteAudio.preferenceKey('effetti'): .21,
      OculumLiteAudio.preferenceKey('muto'): true,
    });
    final mixer = OculumLiteAudio();
    addTearDown(mixer.dispose);
    mixer.restorePreferences(await SharedPreferences.getInstance());
    expect(mixer.musicVolume, .71);
    expect(mixer.effectsVolume, .21);
    expect(mixer.muted, isTrue);
  });

  testWidgets('greetings change on request and belong to the visible NPC', (
    tester,
  ) async {
    final voices = <String>[];
    Future<void> show(LiteShopkeeper npc) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiteMerchantGreeting(
            key: ValueKey(npc),
            shopkeeper: npc,
            playVoice: voices.add,
          ),
        ),
      ),
    );

    await show(LiteShopkeeper.goblin);
    String visibleLine() => tester.widget<Text>(find.textContaining('«')).data!;
    final firstLine = visibleLine();
    expect(voices, [startsWith('voce-goblin-')]);
    await tester.tap(find.byIcon(Icons.record_voice_over_outlined));
    await tester.pump();
    expect(visibleLine(), isNot(firstLine));
    expect(voices, hasLength(2));
    expect(voices.last, startsWith('voce-goblin-'));
    await show(LiteShopkeeper.goblin);
    expect(voices, hasLength(2));
    await show(LiteShopkeeper.veggente);
    expect(voices.last, startsWith('voce-veggente-'));
  });

  test('each merchant has six distinct lines and three bundled cues', () async {
    for (final merchant in LiteShopkeeper.values) {
      expect(merchant.greetings.toSet(), hasLength(6));
      for (var variation = 1; variation <= 3; variation++) {
        final voice = await rootBundle.load(
          'assets/oculum/lite/audio/voce-${merchant.name}-$variation.wav',
        );
        expect(voice.lengthInBytes, greaterThan(15000));
        expect(voice.getUint32(0), 0x52494646);
        expect(voice.getUint32(8), 0x57415645);
      }
    }
  });
}
