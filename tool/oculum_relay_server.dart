import 'dart:convert';
import 'dart:io';
import 'dart:math';

final rooms = <String, Set<RelayClient>>{};
final roomOwners = <String, String>{};
final roomCoMasters = <String, Set<String>>{};
final roomAllowCoMasterSet = <String, bool>{};
final lobby = <String, RelayClient>{};

const maxMessageBytes = 8 * 1024 * 1024;
const maxRooms = 100;
const maxLobbyClients = 200;
const maxClientsPerRoom = 30;

void main(List<String> args) async {
  final port = readPort(args);
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  stdout.writeln('Oculum relay listening on ws://0.0.0.0:$port');

  await for (final request in server) {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('Oculum relay online')
        ..close();
      continue;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    final client = RelayClient(socket);

    socket.listen(
      (message) => handleMessage(client, message),
      onDone: () => removeClient(client),
      onError: (_) => removeClient(client),
      cancelOnError: true,
    );
  }
}

int readPort(List<String> args) {
  final envPort = Platform.environment['PORT'];
  if (envPort != null) {
    final parsed = int.tryParse(envPort);
    if (parsed != null && parsed > 0) return parsed;
  }

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--port' && i + 1 < args.length) {
      final parsed = int.tryParse(args[i + 1]);
      if (parsed != null && parsed > 0) return parsed;
    }
  }

  return 8787;
}

void handleMessage(RelayClient client, dynamic raw) {
  if (raw is! String) return;
  if (utf8.encode(raw).length > maxMessageBytes) {
    send(client, {'type': 'ERROR', 'message': 'Message too large'});
    removeClient(client);
    return;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    send(client, {'type': 'ERROR', 'message': 'Invalid JSON'});
    return;
  }
  if (decoded is! Map) return;

  final data = Map<String, dynamic>.from(decoded);
  final type = '${data['type'] ?? ''}';

  switch (type) {
    case 'PING':
      send(client, {'type': 'PONG', 'sentAt': data['sentAt']});
      break;
    case 'HELLO':
      registerClient(client, data);
      break;
    case 'JOIN_ROOM':
      joinRoom(client, data);
      break;
    case 'LIST_PLAYERS':
      listLobbyPlayers(client);
      break;
    case 'INVITE_PLAYER':
      invitePlayer(client, data);
      break;
    case 'SHEET_UPDATE':
    case 'SET_COMASTER':
    case 'KICK_PLAYER':
      relayToRoom(client, data);
      break;
    default:
      send(client, {
        'type': 'ERROR',
        'message': 'Unknown relay message: $type',
      });
  }
}

void registerClient(RelayClient client, Map<String, dynamic> data) {
  client
    ..id = cleanId('${data['sheetId'] ?? ''}')
    ..name = cleanName('${data['name'] ?? '???'}')
    ..role = '${data['role'] ?? 'player'}';

  if (client.id.isEmpty) {
    client.id = generateId();
  }

  if (client.role == 'waiting') {
    if (lobby.length >= maxLobbyClients && !lobby.containsKey(client.id)) {
      send(client, {'type': 'ERROR', 'message': 'Relay lobby is full'});
      return;
    }
    removeClient(client, keepSocket: true);
    lobby[client.id] = client;
    send(client, {'type': 'LOBBY_READY', 'id': client.id, 'name': client.name});
    return;
  }

  joinRoom(client, data);
}

void joinRoom(RelayClient client, Map<String, dynamic> data) {
  final room = cleanRoom('${data['room'] ?? ''}');
  final role = '${data['role'] ?? client.role}';
  if (room.isEmpty) {
    send(client, {'type': 'ERROR', 'message': 'Missing room code'});
    return;
  }

  final roomExists = rooms.containsKey(room);

  if (role == 'master') {
    if (!roomExists && rooms.length >= maxRooms) {
      send(client, {'type': 'ERROR', 'message': 'Relay has too many rooms'});
      return;
    }

    final owner = roomOwners[room];
    if (roomExists && owner != null && owner != client.id) {
      send(client, {
        'type': 'ERROR',
        'message': 'Room is already hosted by another Master',
      });
      return;
    }
  } else if (!roomExists) {
    send(client, {'type': 'ERROR', 'message': 'Room not found'});
    return;
  }

  final roomClients = rooms[room];
  if (roomClients != null &&
      !roomClients.contains(client) &&
      roomClients.length >= maxClientsPerRoom) {
    send(client, {'type': 'ERROR', 'message': 'Room is full'});
    return;
  }

  removeClient(client, keepSocket: true);

  client
    ..room = room
    ..role = role;

  rooms.putIfAbsent(room, () => <RelayClient>{}).add(client);
  if (role == 'master') {
    roomOwners[room] = client.id;
  }

  send(client, {
    'type': 'ROOM_READY',
    'room': room,
    'role': client.role,
    'id': client.id,
  });

  broadcastRoom(room, {
    'type': 'PLAYER_JOINED',
    'room': room,
    'id': client.id,
    'name': client.name,
    'role': client.role,
  }, exclude: client);
}

void invitePlayer(RelayClient master, Map<String, dynamic> data) {
  final targetId = cleanId('${data['targetId'] ?? ''}');
  final target = lobby[targetId];
  final room = cleanRoom('${data['room'] ?? master.room ?? ''}');

  if (!isRoomMaster(master, room)) {
    send(master, {'type': 'ERROR', 'message': 'Only the Master can invite'});
    return;
  }

  if (target == null || room.isEmpty) {
    send(master, {
      'type': 'ERROR',
      'message': 'Player not available or room missing',
    });
    return;
  }

  send(target, {
    'type': 'INTERNET_INVITE',
    'room': room,
    'masterName': '${data['masterName'] ?? master.name}',
    'masterId': '${data['masterId'] ?? master.id}',
  });

  send(master, {'type': 'INVITE_SENT', 'targetId': targetId});
}

void listLobbyPlayers(RelayClient client) {
  final room = cleanRoom(client.room ?? '');
  if (!isRoomMaster(client, room)) {
    send(client, {
      'type': 'ERROR',
      'message': 'Only the Master can see waiting players',
    });
    return;
  }

  send(client, {
    'type': 'LOBBY_PLAYERS',
    'players': lobby.values.map((c) => c.publicJson()).toList(),
  });
}

void relayToRoom(RelayClient sender, Map<String, dynamic> data) {
  final room = cleanRoom('${data['room'] ?? sender.room ?? ''}');
  if (room.isEmpty) return;
  if (sender.room != room || !(rooms[room]?.contains(sender) ?? false)) {
    send(sender, {'type': 'ERROR', 'message': 'Not joined to this room'});
    return;
  }

  if (data['type'] == 'SET_COMASTER' && !canSetCoMaster(sender, room, data)) {
    send(sender, {'type': 'ERROR', 'message': 'Only the Master can do that'});
    return;
  }

  if (data['type'] == 'KICK_PLAYER' && !canControlRoom(sender, room)) {
    send(sender, {
      'type': 'ERROR',
      'message': 'Only Master or Co-Master can kick',
    });
    return;
  }

  if (data['type'] == 'SET_COMASTER') {
    applyCoMasterState(sender, room, data);
  }

  data['room'] = room;
  data['fromId'] = sender.id;

  broadcastRoom(room, data, exclude: sender);
}

void broadcastRoom(
  String room,
  Map<String, dynamic> data, {
  RelayClient? exclude,
}) {
  final clients = rooms[room];
  if (clients == null) return;

  for (final client in List<RelayClient>.from(clients)) {
    if (client == exclude) continue;
    send(client, data);
  }
}

void send(RelayClient client, Map<String, dynamic> data) {
  try {
    client.socket.add(jsonEncode(data));
  } catch (_) {
    removeClient(client);
  }
}

void removeClient(RelayClient client, {bool keepSocket = false}) {
  lobby.remove(client.id);

  final room = client.room;
  if (room != null) {
    rooms[room]?.remove(client);
    if (rooms[room]?.isEmpty ?? false) {
      rooms.remove(room);
      roomOwners.remove(room);
      roomCoMasters.remove(room);
      roomAllowCoMasterSet.remove(room);
    } else if (roomOwners[room] == client.id) {
      final newOwner = rooms[room]?.firstWhere(
        (c) => c.role == 'master',
        orElse: () => rooms[room]!.first,
      );
      if (newOwner == null) {
        roomOwners.remove(room);
      } else {
        roomOwners[room] = newOwner.id;
      }
    }
  }

  client.room = null;

  if (!keepSocket) {
    try {
      client.socket.close();
    } catch (_) {
      // Already closed.
    }
  }
}

String cleanRoom(String value) {
  return value
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9-]'), '')
      .replaceAll(RegExp(r'-+'), '-');
}

String cleanId(String value) {
  return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9-]'), '');
}

String cleanName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '???';
  return trimmed.length <= 48 ? trimmed : trimmed.substring(0, 48);
}

String generateId() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random.secure();
  final buffer = StringBuffer('TMP-');
  for (int i = 0; i < 8; i++) {
    buffer.write(chars[random.nextInt(chars.length)]);
  }
  return buffer.toString();
}

bool isRoomMaster(RelayClient client, String room) {
  if (room.isEmpty) return false;
  return client.role == 'master' &&
      client.room == room &&
      roomOwners[room] == client.id;
}

bool canSetCoMaster(
  RelayClient sender,
  String room,
  Map<String, dynamic> data,
) {
  if (isRoomMaster(sender, room)) return true;

  final allow = roomAllowCoMasterSet[room] ?? false;
  final isKnownCoMaster = roomCoMasters[room]?.contains(sender.id) ?? false;
  return allow && isKnownCoMaster;
}

bool canControlRoom(RelayClient sender, String room) {
  if (isRoomMaster(sender, room)) return true;
  return roomCoMasters[room]?.contains(sender.id) ?? false;
}

void applyCoMasterState(
  RelayClient sender,
  String room,
  Map<String, dynamic> data,
) {
  if (isRoomMaster(sender, room)) {
    roomAllowCoMasterSet[room] = readBool(data['allowCoMasterSet']);
  }

  final targetId = cleanId('${data['targetId'] ?? ''}');
  if (targetId.isEmpty) return;

  final status = readBool(data['status']);
  final coMasters = roomCoMasters.putIfAbsent(room, () => <String>{});
  if (status) {
    coMasters.add(targetId);
  } else {
    coMasters.remove(targetId);
  }
}

bool readBool(dynamic value) {
  if (value is bool) return value;
  final normalized = '$value'.trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

class RelayClient {
  RelayClient(this.socket);

  final WebSocket socket;
  String id = '';
  String name = '???';
  String role = 'player';
  String? room;

  Map<String, dynamic> publicJson() {
    return {'id': id, 'name': name, 'role': role};
  }
}
