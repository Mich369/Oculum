import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('JSON snapshots detach mutable children and preserve original images', () {
    final original = base64Encode(Uint8List(1024 * 1024));
    final sheet = <String,dynamic>{'image':original,'unknown':{'rows':[1,2,3]},'hp':10};
    final copy = oculumCopyJsonTree(sheet) as Map<String,dynamic>;
    expect(identical(copy['image'], original), isTrue);
    expect(oculumJsonContentEquals(sheet, copy), isTrue);
    ((sheet['unknown'] as Map)['rows'] as List)[0]=99;
    expect((copy['unknown'] as Map)['rows'],[1,2,3]);
    expect(oculumJsonContentEquals(sheet,copy),isFalse);
    expect(jsonDecode(jsonEncode(copy)),copy);
    expect(oculumJsonContentEquals({'x':null},{'y':null}),isFalse);
    expect(oculumJsonContentEquals({'x':1},{'x':1.0}),isFalse);
  });
  test('image cache distinguishes equal sampled signatures', () {
    final a=Uint8List(8192);
    final b=Uint8List(8192)..[300]=31;
    final cache=OculumDecodedImageCache();
    expect(cache.decode(base64Encode(a)),a);
    expect(cache.decode(base64Encode(b)),b);
    expect(cache.length,2);
  });
  test('only equipped Open is automatic, multiple Opens retain user choice', () {
    OculumTitle title(String name, bool evolved) => OculumTitle.fromJson({
      'nome':name, 'evoluto':evolved, 'equipaggiato':true,
    });
    final normal=title('Normal',false)..sempreVisibile=true;
    final first=title('First Open',true);
    final second=title('Second Open',true)..equipaggiato=false;
    final all=[normal,first,second];
    oculumNormalizeAlwaysVisibleTitles(all);
    expect(oculumAlwaysVisibleTitle(all),same(first));
    expect(first.sempreVisibile,isTrue);
    expect(normal.sempreVisibile,isFalse);
    second.equipaggiato=true;
    first.sempreVisibile=false;
    second.sempreVisibile=true;
    oculumNormalizeAlwaysVisibleTitles(all);
    expect(oculumAlwaysVisibleTitle(all),same(second));
    second.equipaggiato=false;
    oculumNormalizeAlwaysVisibleTitles(all);
    expect(oculumAlwaysVisibleTitle(all),same(first));
    expect(second.sempreVisibile,isFalse);
    expect(OculumTitle.fromJson(first.toJson()).sempreVisibile,isTrue);
  });
}
