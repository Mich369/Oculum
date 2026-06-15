import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final url = args.isEmpty ? 'ws://127.0.0.1:8787' : args.first;

  final master = await WebSocket.connect(url);
  final player = await WebSocket.connect(url);
  final waiting = await WebSocket.connect(url);

  final masterMessages = <Map<String, dynamic>>[];
  final playerMessages = <Map<String, dynamic>>[];
  final waitingMessages = <Map<String, dynamic>>[];

  master.listen(
    (message) => masterMessages.add(
      Map<String, dynamic>.from(jsonDecode(message as String)),
    ),
  );
  player.listen(
    (message) => playerMessages.add(
      Map<String, dynamic>.from(jsonDecode(message as String)),
    ),
  );
  waiting.listen(
    (message) => waitingMessages.add(
      Map<String, dynamic>.from(jsonDecode(message as String)),
    ),
  );

  master.add(
    jsonEncode({
      'type': 'HELLO',
      'role': 'master',
      'room': 'OCU-SECURETEST',
      'name': 'Master',
      'sheetId': '369-000001',
    }),
  );
  player.add(
    jsonEncode({
      'type': 'HELLO',
      'role': 'player',
      'room': 'OCU-SECURETEST',
      'name': 'Player',
      'sheetId': '369-000002',
    }),
  );
  waiting.add(
    jsonEncode({
      'type': 'HELLO',
      'role': 'waiting',
      'name': 'Waiting',
      'sheetId': '369-000003',
    }),
  );

  await Future<void>.delayed(const Duration(milliseconds: 450));
  master.add(jsonEncode({'type': 'LIST_PLAYERS'}));
  player.add(jsonEncode({'type': 'LIST_PLAYERS'}));

  await Future<void>.delayed(const Duration(milliseconds: 450));

  final masterReady = masterMessages.any(
    (m) => m['type'] == 'ROOM_READY' && m['role'] == 'master',
  );
  final playerReady = playerMessages.any(
    (m) => m['type'] == 'ROOM_READY' && m['role'] == 'player',
  );
  final waitingReady = waitingMessages.any((m) => m['type'] == 'LOBBY_READY');
  final masterCanList = masterMessages.any((m) => m['type'] == 'LOBBY_PLAYERS');
  final playerDenied = playerMessages.any(
    (m) =>
        m['type'] == 'ERROR' && '${m['message']}'.contains('Only the Master'),
  );

  await master.close();
  await player.close();
  await waiting.close();

  if (!masterReady ||
      !playerReady ||
      !waitingReady ||
      !masterCanList ||
      !playerDenied) {
    throw StateError(
      'relay security smoke failed: '
      'masterReady=$masterReady '
      'playerReady=$playerReady '
      'waitingReady=$waitingReady '
      'masterCanList=$masterCanList '
      'playerDenied=$playerDenied',
    );
  }

  stdout.writeln('relay security smoke ok');
}
