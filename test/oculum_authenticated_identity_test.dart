import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_realtime_service.dart';

void main() {
  test('verified sender matches mixed-case attack and defense references', () {
    const attack = {
      'senderTag': 'ATTACCOOCU:3690FD5G',
      'sourceTag': 'AttaccoOcu:3690FD5G',
      'targetTag': 'DifesaOcu:3690FD5G',
      'authenticatedRole': 'player',
      'sessionId': 'verified-session',
    };
    final delivered = oculumVerifiedPacketIdentity(attack);
    expect(delivered['senderTag'], attack['sourceTag']);
    expect(attack['senderTag'], 'ATTACCOOCU:3690FD5G');
    expect(delivered['authenticatedRole'], 'player');
    expect(delivered['sessionId'], 'verified-session');
    final defense = oculumVerifiedPacketIdentity({
      ...attack,
      'senderTag': 'DIFESAOCU:3690FD5G',
    });
    expect(defense['senderTag'], attack['targetTag']);
  });
  test('foreign packet references cannot impersonate a verified identity', () {
    final delivered = oculumVerifiedPacketIdentity({
      'senderTag': 'ATTACCOOCU:3690FD5G',
      'sourceTag': 'MasterOcu:3690FD5G',
      'targetTag': 'DifesaOcu:3690FD5G',
      'authenticatedUserId': 'verified-user',
      'senderRole': 'player',
    });
    expect(delivered['senderTag'], 'ATTACCOOCU:3690FD5G');
    expect(delivered['authenticatedUserId'], 'verified-user');
    expect(delivered['senderRole'], 'player');
  });
  test(
    'sheet chunks retain saved spelling and require a nonempty identity',
    () {
      expect(
        oculumSameSheetIdentity('AttaccoOcu:3690FD5G', 'ATTACCOOCU:3690FD5G'),
        isTrue,
      );
      expect(
        oculumSameSheetIdentity('AttaccoOcu:3690FD5G', 'DIFESAOCU:3690FD5G'),
        isFalse,
      );
      expect(oculumSameSheetIdentity(null, ''), isFalse);
    },
  );
}
