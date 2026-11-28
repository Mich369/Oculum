import 'oculum_rl_release.dart';

bool get supportsOculumRlUpdates => false;

Future<OculumRlVersion?> findOculumRlUpdate(
  OculumRlVersion current,
  OculumRlEdition edition,
) async => null;

Future<OculumRlVersion?> prepareOculumRlUpdate(
  OculumRlVersion current,
  OculumRlEdition edition, {
  void Function(OculumRlTransfer)? onTransfer,
}) async => null;

Future<bool> startOculumRlUpdate(
  OculumRlVersion version,
  OculumRlEdition edition,
) async => false;

void acknowledgeOculumRlUpdate() {}
void exitForOculumRlUpdate() {}
