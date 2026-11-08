import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('an Open Materia reply requires the authenticated Master role', () {
    const verifiedMaster = {
      'authenticatedUserId': 'owner',
      'authenticatedRole': 'master',
      'senderRole': 'master',
    };
    expect(
      oculumStatOpenMateriaPermissionRole(verifiedMaster, reply: true),
      isTrue,
    );
    expect(
      oculumStatOpenMateriaPermissionRole(verifiedMaster, reply: false),
      isFalse,
    );
    expect(
      oculumStatOpenMateriaPermissionRole({
        ...verifiedMaster,
        'authenticatedRole': 'player',
      }, reply: true),
      isFalse,
    );
    expect(
      oculumStatOpenMateriaPermissionRole({
        ...verifiedMaster,
        'authenticatedUserId': '',
      }, reply: true),
      isFalse,
    );
  });

  test('the same nonce can retry only the same Open Materia request', () {
    const request = {
      'scope': 'room:campaign',
      'campaignId': 'campaign',
      'encounterId': 'encounter_1',
      'fight': 'fight_2',
      'turn': 'round_3:actor',
      'actor': 'ACTOR',
      'target': 'ENEMY',
      'form': 'matter_geometry_100',
      'nonce': 'n1234567',
      'range': 8,
    };
    expect(
      oculumStatOpenMateriaSameRequest(request, {...request, 'phase': 'plan'}),
      isTrue,
    );
    for (final field in request.keys) {
      expect(
        oculumStatOpenMateriaSameRequest(request, {...request, field: 'other'}),
        isFalse,
        reason: field,
      );
    }
    expect(oculumStatOpenMateriaSameRequest(const {}, const {}), isFalse);
  });

  test(
    'staff range follows the saved form, level, and its own active Buff',
    () {
      const form = 'matter_geometry_100';
      final milestones = <String, dynamic>{
        'choices20': {'materia': 'matter_quick_action'},
        'choices': {'materia': 'matter_wind'},
        'parameters': {
          form: {'movement': 7, 'movementBuff': 3},
        },
        'opens': {
          'matter_geometry_50': {'buffActive': true, 'skillEmpowered': true},
        },
      };
      final sheet = {
        'livello': '100',
        'planarRuntime': {'stat35': milestones},
      };
      expect(oculumStatOpenMateriaAuthorizedRange(const {}, form), isNull);
      expect(oculumStatOpenMateriaAuthorizedRange(sheet, form), 7);
      expect(
        oculumStatOpenMateriaAuthorizedRange({...sheet, 'livello': '99'}, form),
        -1,
      );
      milestones['opens'] = {
        form: {'buffActive': true, 'skillEmpowered': true},
      };
      expect(oculumStatOpenMateriaAuthorizedRange(sheet, form), 10);
    },
  );
}
