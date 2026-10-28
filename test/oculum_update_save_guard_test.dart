import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_update_save_guard.dart';

class _SaveFixture {
  bool loaded = true;
  bool blocked = false;
  int failures = 0;
  String? persisted = '{"character":"older snapshot"}';
  String? confirmed = '{"character":"older snapshot"}';
  bool meaningful = true;
  int writes = 0;
  int installerStarts = 0;
  Future<void> Function()? write;
  Future<bool> Function(String)? meaningfulCheck;

  Future<String> prepareAndStart() async {
    final raw = await oculumRequireVerifiedUpdateSave(
      saveLatest: () async {
        writes++;
        if (write != null) await write!();
      },
      readPersisted: () async => persisted,
      dataLoaded: () => loaded,
      writeBlocked: () => blocked,
      writeFailures: () => failures,
      lastConfirmedRaw: () => confirmed,
      looksMeaningful: (raw) async =>
          meaningfulCheck == null ? meaningful : meaningfulCheck!(raw),
    );
    installerStarts++;
    return raw;
  }
}

void main() {
  test('installer receives the latest verified save', () async {
    final save = _SaveFixture();
    save.write = () async {
      save.persisted = '{"character":"latest edits"}';
      save.confirmed = save.persisted;
    };
    expect(await save.prepareAndStart(), '{"character":"latest edits"}');
    expect(save.writes, 1);
    expect(save.installerStarts, 1);
  });

  test(
    'unchanged confirmed save permits update without a redundant write',
    () async {
      final save = _SaveFixture();
      expect(await save.prepareAndStart(), save.persisted);
      expect(save.installerStarts, 1);
    },
  );

  test(
    'silent failed write cannot pass using an older meaningful save',
    () async {
      final save = _SaveFixture();
      save.write = () async => save.failures++;
      await expectLater(save.prepareAndStart(), throwsStateError);
      expect(save.installerStarts, 0);
      expect(save.persisted, '{"character":"older snapshot"}');
    },
  );

  test(
    'protected refusal preserves running app and does not start installer',
    () async {
      final save = _SaveFixture();
      save.write = () async => save.blocked = true;
      await expectLater(save.prepareAndStart(), throwsStateError);
      expect(save.installerStarts, 0);
    },
  );

  test(
    'past write failure is allowed after persistence confirms recovery',
    () async {
      final save = _SaveFixture()..failures = 2;
      save.write = () async {
        save.failures = 0;
        save.persisted = '{"recovered":true}';
        save.confirmed = save.persisted;
      };
      expect(await save.prepareAndStart(), '{"recovered":true}');
      expect(save.installerStarts, 1);
    },
  );

  test(
    'readback mismatch is rejected even when both snapshots are meaningful',
    () async {
      final save = _SaveFixture()..persisted = '{"character":"unexpected"}';
      await expectLater(save.prepareAndStart(), throwsStateError);
      expect(save.installerStarts, 0);
    },
  );

  test('missing save cannot hand off to installer', () async {
    final save = _SaveFixture()..persisted = null;
    await expectLater(save.prepareAndStart(), throwsStateError);
    expect(save.installerStarts, 0);
  });

  test('loading must finish before any update save or handoff', () async {
    final save = _SaveFixture()..loaded = false;
    await expectLater(save.prepareAndStart(), throwsStateError);
    expect(save.writes, 0);
    expect(save.installerStarts, 0);
  });

  test('a thrown persistence error leaves the installer unstarted', () async {
    final save = _SaveFixture();
    save.write = () async => throw StateError('Disk full');
    await expectLater(save.prepareAndStart(), throwsStateError);
    expect(save.installerStarts, 0);
  });

  test(
    'empty or unrecognizable snapshot cannot replace a verified backup',
    () async {
      final save = _SaveFixture()..meaningful = false;
      await expectLater(save.prepareAndStart(), throwsStateError);
      expect(save.installerStarts, 0);
    },
  );

  test(
    'confirmation changes during asynchronous validation prevent handoff',
    () async {
      final save = _SaveFixture();
      save.meaningfulCheck = (_) async {
        save.confirmed = '{"character":"newer concurrent snapshot"}';
        return true;
      };
      await expectLater(save.prepareAndStart(), throwsStateError);
      expect(save.installerStarts, 0);
    },
  );
}
