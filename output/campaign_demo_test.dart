import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_eye_memory_page.dart';
import 'package:oculum/services/oculum_diary_memory.dart';
import 'package:oculum/services/oculum_diary_roles.dart';

void main() {
  testWidgets('Preview a coherent campaign in the actual Eye Map', (tester) async {
    const catalogue = [
      DiaryEntity('bosco', 'Bosco Nero', 'place'),
      DiaryEntity('rovine', 'Rovine della Campana', 'place'),
      DiaryEntity('porto', 'Porto Cenere', 'place'),
      DiaryEntity('arven', 'Arven', 'npc'),
      DiaryEntity('elyra', 'Elyra', 'party'),
      DiaryEntity('kael', 'Kael', 'party'),
      DiaryEntity('demon', 'Forest Demon', 'creature'),
      DiaryEntity('custode', 'Custode del Rovo', 'enemy'),
      DiaryEntity('neris', 'Neris', 'npc'),
      DiaryEntity('mira', 'Mira', 'npc'),
    ];
    const documents = [
      DiaryDocument(id: 's1', author: 'Hoshy', diary: 'La campana senza voce', title: 'La guida e il sentiero', day: 1,
        text: 'Nel Bosco Nero ho incontrato Arven, la guida che ci ha mostrato il sentiero. Nel Bosco Nero ho parlato con Mira, che cerca sua sorella. Nel Bosco Nero ho incontrato Elyra e ci siamo alleati. Nel Bosco Nero ho incontrato Kael, ora nostro alleato.'),
      DiaryDocument(id: 's2', author: 'Hoshy', diary: 'La campana senza voce', title: 'Il demone e le rovine', day: 3,
        text: 'Nel Bosco Nero ho combattuto il Forest Demon. Ho ucciso il Forest Demon. Il sentiero del Bosco Nero conduce alle Rovine della Campana. Abbiamo visitato le Rovine della Campana.'),
      DiaryDocument(id: 's3', author: 'Hoshy', diary: 'La campana senza voce', title: 'Chi è rimasto indietro', day: 4,
        text: 'Nel Bosco Nero Arven è morto mentre ci indicava una via di fuga. Nel Bosco Nero ho affrontato il Custode del Rovo. Il Custode del Rovo è fuggito. Nel Bosco Nero Neris ha scelto l’Oblio ed è diventato un Obliterato.'),
      DiaryDocument(id: 's4', author: 'Hoshy', diary: 'La campana senza voce', title: 'Il ritorno', day: 7,
        text: 'Siamo tornati dal Bosco Nero a Porto Cenere. A Porto Cenere ho incontrato Mira. A Porto Cenere Elyra è rimasta nostra alleata. Nel Bosco Nero il Custode del Rovo è ancora ostile: non lo abbiamo sconfitto.'),
      DiaryDocument(id: 'e1', author: 'Elyra', diary: 'Le cose che restano', title: 'Il nome di Arven', day: 4,
        text: 'Nel Bosco Nero Arven è morto. Nel Bosco Nero ho incontrato Neris: aveva già scelto l’Oblio. Ho visitato le Rovine della Campana.'),
    ];
    final memory = DiaryMemoryBuilder().build(documents, catalogue, campaign: 'La campana senza voce');
    final ledger = DiaryRoleLedger();
    for (final change in {'arven':'dead', 'demon':'dead', 'neris':'obliterated'}.entries) {
      ledger.change(memory.entities[change.key]!, change.value, DateTime(2026,10,1));
    }
    ledger.apply(memory);
    expect(memory.backlinks('bosco').map((r)=> r.from == 'bosco' ? r.to : r.from).toSet(), containsAll(['arven','demon','neris','elyra','kael','custode','mira','rovine','porto']));
    expect(memory.backlinks('custode').where((r)=>r.state=='killed'||r.state=='defeated'), isEmpty);
    final font = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    await (FontLoader('Poppins')..addFont(Future.value(font))).load();
    final icons = File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final capture = GlobalKey();
    await tester.pumpWidget(MaterialApp(theme: ThemeData.dark().copyWith(textTheme: ThemeData.dark().textTheme.apply(fontFamily:'Poppins')),
      home: RepaintBoundary(key:capture, child:OculumEyeMemoryPage(memory:memory, author:'Hoshy', roleHistory:ledger.historyFor))));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future.wait([
        for (final path in ['assets/oculum/icons/oculum_npc_eye.png','assets/icon/oculum_eye.png','assets/oculum/icons/oculum_dead_eye.png','assets/oculum/icons/oculum_obliterated_eye.png'])
          precacheImage(AssetImage(path), capture.currentContext!),
      ]);
    });
    await tester.pumpAndSettle();
    Future<void> take(String name) async {
      await tester.runAsync(() async {
        final boundary=capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final picture=await boundary.toImage();
        final bytes=await picture.toByteData(format:ui.ImageByteFormat.png);
        Directory('build/distribution/anteprima-campagna').createSync(recursive:true);
        File('build/distribution/anteprima-campagna/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        picture.dispose();
      });
      expect(tester.takeException(),isNull);
    }
    await tester.enterText(find.byType(TextField), 'Bosco Nero');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip,'Bosco Nero'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await take('01-bosco-e-legami');
    await tester.enterText(find.byType(TextField), 'Arven');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip,'Arven'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await take('02-arven-memoria');
    await tester.pumpWidget(const SizedBox());
  });
}
