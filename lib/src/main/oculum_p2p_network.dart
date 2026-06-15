part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumP2PNetwork on _OculumHomePageState {
  static HttpServer? _masterServer;
  static final List<WebSocket> _clientSockets = [];
  static WebSocket? _myClientSocket;
  static WebSocket? _relaySocket;
  static RawDatagramSocket? _udpSocket;
  static const Duration _relayConnectTimeout = Duration(seconds: 5);
  static const Duration _lanConnectTimeout = Duration(seconds: 4);
  static const Duration _relayHeartbeatInterval = Duration(seconds: 8);
  static const Duration _relayLobbyRefreshInterval = Duration(seconds: 3);
  static const Duration _relayReconnectDelay = Duration(seconds: 2);
  static const String _privateRelayInvitePrefix = 'OCULUM-LOCK:';
  static const String _legacyRelayInvitePrefix = 'OCULUM-ONLINE|';

  // ---------------------------------------------------------
  // UDP DISCOVERY
  // ---------------------------------------------------------

  Future<void> startUdpListener() async {
    try {
      _udpSocket?.close();
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4444);
      _udpSocket?.broadcastEnabled = true;

      _udpSocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = _udpSocket?.receive();
          if (datagram != null) {
            String message = utf8.decode(datagram.data);
            String senderIp = datagram.address.address;

            if (message == 'OCULUM_DISCOVER' && !isMasterHost) {
              // Master sta cercando, io sono un giocatore
              String myName = nomeSchedaPersonaggio(schedaCorrente);
              _udpSocket?.send(
                utf8.encode('I_AM_HERE|$myName'),
                datagram.address,
                4444,
              );
            } else if (message.startsWith('I_AM_HERE|') && isMasterHost) {
              // Giocatore ha risposto
              String playerName = message.split('|')[1];
              bool exists = availablePlayers.any((p) => p['ip'] == senderIp);
              if (!exists) {
                setState(() {
                  availablePlayers.add({'name': playerName, 'ip': senderIp});
                });
              }
            } else if (message.startsWith('INVITE|') && !isMasterHost) {
              // Master mi sta invitando
              String masterName = message.split('|')[1];
              _showInviteDialog(masterName, senderIp);
            }
          }
        }
      });
    } catch (e) {
      aggiungiLog('Errore radar online: $e');
    }
  }

  void scanForPlayers() {
    setState(() {
      availablePlayers.clear();
    });
    _udpSocket?.send(
      utf8.encode('OCULUM_DISCOVER'),
      InternetAddress('255.255.255.255'),
      4444,
    );
  }

  void invitePlayer(String ip) {
    final myName = nomeSchedaPersonaggio(schedaCorrente);
    _udpSocket?.send(utf8.encode('INVITE|$myName'), InternetAddress(ip), 4444);
  }

  void _showInviteDialog(String masterName, String masterIp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF10121A),
          title: Text(
            t('Invito al Party', 'Party Invite'),
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            t(
              '$masterName ti ha invitato ad unirti al suo party!\nVuoi accettare e sincronizzare la tua scheda?',
              '$masterName invited you to join their party!\nDo you want to accept and sync your sheet?',
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Rifiuta (ignora)
              },
              child: Text(
                t('No', 'No'),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: tertiaryColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                connectToMaster(masterIp);
              },
              child: Text(t('Sì', 'Yes')),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------
  // MASTER (HOST) LOGIC
  // ---------------------------------------------------------

  Future<void> startHosting() async {
    try {
      _masterServer = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      setState(() {
        usingInternetRelay = false;
        relayConnected = false;
        waitingInternetInvite = false;
        isMasterHost = true;
        isConnectedToMaster = false;
        modalitaMaster = true;
        risultato = t('Server Master avviato.', 'Master server started.');
        aggiungiLog(risultato);
      });

      _masterServer?.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocket socket = await WebSocketTransformer.upgrade(request);
          _clientSockets.add(socket);

          socket.listen(
            (message) {
              _handleMessageFromClient(message, socket);
            },
            onDone: () {
              _clientSockets.remove(socket);
            },
          );
        }
      });

      startUdpListener();
    } catch (e) {
      setState(() {
        risultato = t('Errore avvio server: $e', 'Server start error: $e');
      });
    }
  }

  Map<String, dynamic>? decodeOnlineMessage(dynamic message) {
    if (message is! String) return null;
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (error) {
      aggiungiLog('Messaggio online non valido ignorato: $error');
    }
    return null;
  }

  void _handleMessageFromClient(dynamic message, WebSocket sender) {
    final data = decodeOnlineMessage(message);
    if (data == null) return;

    if (data['type'] == 'SHEET_UPDATE') {
      registraSchedaRemota(data['sheet']);

      final staffMessage = jsonEncode({...data, 'staffOnly': true});
      _broadcastToClients(staffMessage, exclude: sender);
    } else if (data['type'] == 'KICK_PLAYER') {
      _broadcastToClients(message as String, exclude: sender);
    }
  }

  void _broadcastToClients(String message, {WebSocket? exclude}) {
    for (var socket in _clientSockets) {
      if (socket != exclude) {
        socket.add(message);
      }
    }
  }

  void setCoMasterStatus(String playerId, bool status) {
    // Invia al client specifico o in broadcast con l'ID
    final msg = jsonEncode({
      'type': 'SET_COMASTER',
      'targetId': playerId,
      'status': status,
    });
    if (usingInternetRelay && _relaySocket != null) {
      _sendRelay({
        'type': 'SET_COMASTER',
        'room': relayRoomCode,
        'targetId': playerId,
        'status': status,
        'allowCoMasterSet': coMasterCanSetCoMaster,
      });
    }
    _broadcastToClients(msg);
  }

  // ---------------------------------------------------------
  // PLAYER (CLIENT) LOGIC
  // ---------------------------------------------------------

  Future<void> connectToMaster(String ip) async {
    try {
      _myClientSocket = await WebSocket.connect(
        'ws://$ip:8080',
      ).timeout(_lanConnectTimeout);
      _myClientSocket?.pingInterval = const Duration(seconds: 10);
      setState(() {
        usingInternetRelay = false;
        relayConnected = false;
        waitingInternetInvite = false;
        isConnectedToMaster = true;
        connectedMasterIp = ip;
        isMasterHost = false;
        modalitaMaster = false;
        sonoCoMaster = false;
        risultato = t('Connesso al Master.', 'Connected to Master.');
        aggiungiLog(risultato);
      });

      // Invia subito la mia scheda
      sendSheetToMaster();

      _myClientSocket?.listen(
        (message) {
          _handleMessageFromMaster(message);
        },
        onDone: () {
          setState(() {
            isConnectedToMaster = false;
            risultato = t(
              'Disconnesso dal Master.',
              'Disconnected from Master.',
            );
          });
        },
      );
    } catch (e) {
      setState(() {
        risultato = t('Errore connessione: $e', 'Connection error: $e');
      });
    }
  }

  Future<void> disconnectFromLocalMaster() async {
    try {
      await _myClientSocket?.close(WebSocketStatus.goingAway);
    } catch (_) {
      // Socket already closed.
    }

    _myClientSocket = null;
    if (!mounted) return;

    setState(() {
      isConnectedToMaster = false;
      connectedMasterIp = '';
      modalitaMaster = false;
      sonoCoMaster = false;
      risultato = t('Disconnesso dal Master.', 'Disconnected from Master.');
      aggiungiLog(risultato);
    });
  }

  void _handleMessageFromMaster(dynamic message) {
    final data = decodeOnlineMessage(message);
    if (data == null) return;

    if (data['type'] == 'SET_COMASTER') {
      String myId = schedePersonaggio.isNotEmpty
          ? schedePersonaggio[schedaCorrente]['id'] ?? ''
          : '';
      if (data['targetId'] == myId) {
        setState(() {
          sonoCoMaster = readBoolValue(data['status']);
          risultato = sonoCoMaster
              ? t(
                  'Sei stato promosso a Co-Master!',
                  'You have been promoted to Co-Master!',
                )
              : t(
                  'I tuoi poteri da Co-Master sono stati revocati.',
                  'Your Co-Master powers have been revoked.',
                );
          aggiungiLog(risultato);
        });
        unawaited(salvaDatiSoloLocale());
      }
    } else if (data['type'] == 'SHEET_UPDATE') {
      if (sonoCoMaster) {
        registraSchedaRemota(data['sheet']);
      }
    } else if (data['type'] == 'KICK_PLAYER') {
      handleKickFromMaster(data);
    }
  }

  // ---------------------------------------------------------
  // INTERNET RELAY
  // ---------------------------------------------------------

  String normalizedRelayUrl() {
    var url = relayServerController.text.trim();
    if (url.isEmpty) return '';

    if (url.startsWith('https://')) {
      url = 'wss://${url.substring('https://'.length)}';
    } else if (url.startsWith('http://')) {
      url = 'ws://${url.substring('http://'.length)}';
    } else if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
      url = 'wss://$url';
    }

    relayServerController.text = url;
    return url;
  }

  String normalizeRelayRoom(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9-]'), '')
        .replaceAll(RegExp(r'-+'), '-');
  }

  String generateRelayRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final buffer = StringBuffer('OCU-');
    for (int i = 0; i < 10; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  Future<void> startInternetRelayAsMaster() async {
    var room = normalizeRelayRoom(relayRoomController.text);
    if (room.isEmpty) {
      room = generateRelayRoomCode();
    }
    relayRoomController.text = room;
    await _connectInternetRelay(role: 'master', room: room);
  }

  Future<void> joinInternetRelayAsPlayer({String? roomOverride}) async {
    parseRelayInvite(roomOverride ?? relayRoomController.text);
    final room = normalizeRelayRoom(relayRoomController.text);
    if (room.isEmpty) {
      setState(() {
        risultato = t(
          'Inserisci il codice stanza del Master.',
          'Enter the Master room code.',
        );
        relayStatus = risultato;
      });
      return;
    }
    relayRoomController.text = room;
    await _connectInternetRelay(role: 'player', room: room);
  }

  String relayInviteText() {
    final server = normalizedRelayUrl();
    final room = normalizeRelayRoom(
      relayRoomCode.isNotEmpty ? relayRoomCode : relayRoomController.text,
    );
    if (server.isEmpty || room.isEmpty) return '';

    final payload = jsonEncode(<String, Object>{
      'v': 1,
      'server': server,
      'room': room,
    });
    final token = base64UrlEncode(utf8.encode(payload));
    return '$_privateRelayInvitePrefix$token';
  }

  Future<void> copyRelayInvite() async {
    final invite = relayInviteText();
    if (invite.isEmpty) {
      setState(() {
        risultato = t(
          'Crea prima una stanza Internet.',
          'Create an Internet room first.',
        );
        relayStatus = risultato;
      });
      return;
    }

    await Clipboard.setData(ClipboardData(text: invite));
    setState(() {
      risultato = t(
        'Invito privato copiato. Server e IP non sono visibili in chiaro.',
        'Private invite copied. Server and IP are not shown in plain text.',
      );
      relayStatus = risultato;
    });
  }

  Future<void> pasteRelayInviteAndJoin() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      setState(() {
        risultato = t(
          'Non ho trovato un invito negli appunti.',
          'I did not find an invite in the clipboard.',
        );
        relayStatus = risultato;
      });
      return;
    }

    parseRelayInvite(text);
    await joinInternetRelayAsPlayer();
  }

  void parseRelayInvite(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return;

    final upperRaw = raw.toUpperCase();
    final privateInviteIndex = upperRaw.indexOf(_privateRelayInvitePrefix);
    if (privateInviteIndex >= 0) {
      final tokenStart = privateInviteIndex + _privateRelayInvitePrefix.length;
      final token = raw
          .substring(tokenStart)
          .trim()
          .split(RegExp(r'\s+'))
          .first;

      try {
        if (token.isEmpty) {
          throw const FormatException('Missing private invite token');
        }
        final normalizedToken = base64Url.normalize(token);
        final decoded = utf8.decode(base64Url.decode(normalizedToken));
        final payload = jsonDecode(decoded);
        if (payload is! Map) {
          throw const FormatException('Invalid private invite payload');
        }

        final server = '${payload['server'] ?? ''}'.trim();
        final room = normalizeRelayRoom('${payload['room'] ?? ''}');
        if (server.isNotEmpty) {
          relayServerController.text = server;
        }
        if (room.isNotEmpty) {
          relayRoomController.text = room;
        }
      } catch (_) {
        setState(() {
          risultato = t(
            'Invito privato non valido.',
            'Invalid private invite.',
          );
          relayStatus = risultato;
        });
      }
      return;
    }

    if (raw.contains(_legacyRelayInvitePrefix)) {
      final parts = raw.split('|');
      for (final part in parts) {
        final splitIndex = part.indexOf('=');
        if (splitIndex <= 0) continue;
        final key = part.substring(0, splitIndex).trim().toLowerCase();
        final value = part.substring(splitIndex + 1).trim();
        if (key == 'server') {
          relayServerController.text = value;
        } else if (key == 'room') {
          relayRoomController.text = normalizeRelayRoom(value);
        }
      }
      return;
    }

    final parsedUri = Uri.tryParse(raw);
    if (parsedUri != null && parsedUri.queryParameters.isNotEmpty) {
      final server = parsedUri.queryParameters['server'];
      final room = parsedUri.queryParameters['room'];
      if (server != null && server.trim().isNotEmpty) {
        relayServerController.text = server.trim();
      }
      if (room != null && room.trim().isNotEmpty) {
        relayRoomController.text = normalizeRelayRoom(room);
      }
      return;
    }

    final relayMatch = RegExp(
      r'(wss?://[^\s|]+|https?://[^\s|]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    final roomMatch = RegExp(
      r'OCU-[A-Z0-9-]{4,}',
      caseSensitive: false,
    ).firstMatch(raw);

    if (relayMatch != null) {
      relayServerController.text = relayMatch.group(0) ?? '';
    }
    if (roomMatch != null) {
      relayRoomController.text = normalizeRelayRoom(roomMatch.group(0) ?? '');
    } else if (relayMatch == null) {
      relayRoomController.text = normalizeRelayRoom(raw);
    }
  }

  Future<void> waitForInternetInvite() async {
    await _connectInternetRelay(role: 'waiting', room: '');
  }

  Future<void> _connectInternetRelay({
    required String role,
    required String room,
  }) async {
    final url = normalizedRelayUrl();
    if (url.isEmpty) {
      setState(() {
        risultato = t(
          'Inserisci l\'indirizzo del relay Internet.',
          'Enter the Internet relay address.',
        );
        relayStatus = risultato;
      });
      return;
    }

    try {
      setState(() {
        relayConnecting = true;
        relayStatus = t(
          'Connessione relay in corso...',
          'Connecting to relay...',
        );
        risultato = relayStatus;
      });
      await disconnectInternetRelay(silent: true);
      relayLastRole = role;
      relayLastRoom = room;

      final socket = await WebSocket.connect(url).timeout(_relayConnectTimeout);
      socket.pingInterval = const Duration(seconds: 10);
      _relaySocket = socket;

      setState(() {
        relayConnecting = false;
        usingInternetRelay = true;
        relayConnected = true;
        waitingInternetInvite = role == 'waiting';
        relayRoomCode = room;
        relayStatus = role == 'waiting'
            ? t(
                'In attesa di invito tramite relay.',
                'Waiting for an invite through the relay.',
              )
            : t(
                'Connesso al relay Internet.',
                'Connected to the Internet relay.',
              );
        risultato = relayStatus;
        isMasterHost = role == 'master';
        isConnectedToMaster = role == 'player';
        modalitaMaster = role == 'master';
        connectedMasterIp = role == 'player' ? 'Relay $room' : '';
        aggiungiLog(risultato);
      });

      socket.listen(
        _handleRelayMessage,
        onDone: () {
          if (_relaySocket != socket) return;
          if (!mounted) return;
          setState(() {
            _relaySocket = null;
            stopRelayFastTimers();
            relayConnected = false;
            usingInternetRelay = false;
            waitingInternetInvite = false;
            relayConnecting = false;
            isMasterHost = false;
            isConnectedToMaster = false;
            modalitaMaster = false;
            connectedMasterIp = '';
            relayStatus = t(
              'Relay Internet disconnesso.',
              'Internet relay disconnected.',
            );
          });
          scheduleRelayReconnect(role: role, room: room);
        },
        onError: (Object error) {
          if (_relaySocket != socket) return;
          if (!mounted) return;
          setState(() {
            relayStatus = 'Relay error: $error';
            risultato = relayStatus;
            relayConnecting = false;
          });
        },
      );

      _sendRelay({
        'type': 'HELLO',
        'role': role,
        'room': room,
        'name': nomeSchedaPersonaggio(schedaCorrente),
        'sheetId': sheetTagAt(schedaCorrente),
      });

      startRelayFastTimers(role: role, room: room);
    } catch (e) {
      setState(() {
        relayConnecting = false;
        relayConnected = false;
        usingInternetRelay = false;
        relayStatus = t(
          'Errore relay Internet: $e',
          'Internet relay error: $e',
        );
        risultato = relayStatus;
      });
      scheduleRelayReconnect(role: role, room: room);
    }
  }

  Future<void> disconnectInternetRelay({bool silent = false}) async {
    stopRelayFastTimers();
    try {
      await _relaySocket?.close(WebSocketStatus.goingAway);
    } catch (_) {
      // La socket potrebbe essere già chiusa dal sistema operativo.
    }
    _relaySocket = null;

    if (!silent && mounted) {
      setState(() {
        relayConnected = false;
        usingInternetRelay = false;
        waitingInternetInvite = false;
        relayConnecting = false;
        isMasterHost = false;
        isConnectedToMaster = false;
        modalitaMaster = false;
        connectedMasterIp = '';
        relayStatus = t(
          'Relay Internet disconnesso.',
          'Internet relay disconnected.',
        );
        risultato = relayStatus;
      });
    }
  }

  void startRelayFastTimers({required String role, required String room}) {
    stopRelayFastTimers();
    relayLastRole = role;
    relayLastRoom = room;

    relayHeartbeatTimer = Timer.periodic(_relayHeartbeatInterval, (_) {
      sendRelayPing();
    });
    sendRelayPing();

    if (role == 'master') {
      relayLobbyRefreshTimer = Timer.periodic(
        _relayLobbyRefreshInterval,
        (_) => refreshInternetPlayers(),
      );
      refreshInternetPlayers();
    }
  }

  void stopRelayFastTimers() {
    relayHeartbeatTimer?.cancel();
    relayHeartbeatTimer = null;
    relayLobbyRefreshTimer?.cancel();
    relayLobbyRefreshTimer = null;
    relayReconnectTimer?.cancel();
    relayReconnectTimer = null;
  }

  void scheduleRelayReconnect({required String role, required String room}) {
    if (!relayAutoReconnect || role.isEmpty) return;
    if (!mounted) return;

    relayReconnectTimer?.cancel();
    relayReconnectTimer = Timer(_relayReconnectDelay, () {
      if (!mounted || relayConnected || relayConnecting) {
        return;
      }
      _connectInternetRelay(role: role, room: room);
    });
  }

  void sendRelayPing() {
    if (!relayConnected || _relaySocket == null) return;

    relayPingSentAt = DateTime.now();
    _sendRelay({
      'type': 'PING',
      'sentAt': relayPingSentAt!.millisecondsSinceEpoch,
    });
  }

  void refreshInternetPlayers() {
    _sendRelay({'type': 'LIST_PLAYERS'});
  }

  void inviteInternetPlayer(String playerId) {
    final room = normalizeRelayRoom(relayRoomController.text);
    if (room.isEmpty) {
      setState(() {
        risultato = t(
          'Crea prima una stanza Internet come Master.',
          'Create an Internet room as Master first.',
        );
        relayStatus = risultato;
      });
      return;
    }

    _sendRelay({
      'type': 'INVITE_PLAYER',
      'room': room,
      'targetId': playerId,
      'masterName': nomeSchedaPersonaggio(schedaCorrente),
      'masterId': sheetTagAt(schedaCorrente),
    });
  }

  void acceptInternetInvite(String room) {
    final normalizedRoom = normalizeRelayRoom(room);
    relayRoomController.text = normalizedRoom;
    relayRoomCode = normalizedRoom;
    _sendRelay({
      'type': 'JOIN_ROOM',
      'role': 'player',
      'room': normalizedRoom,
      'name': nomeSchedaPersonaggio(schedaCorrente),
      'sheetId': sheetTagAt(schedaCorrente),
    });
  }

  void _sendRelay(Map<String, dynamic> data) {
    final socket = _relaySocket;
    if (socket == null) return;
    try {
      socket.add(jsonEncode(data));
    } catch (error) {
      aggiungiLog('Invio relay fallito: $error');
    }
  }

  void _handleRelayMessage(dynamic message) {
    final data = decodeOnlineMessage(message);
    if (data == null) return;

    final type = '${data['type'] ?? ''}';
    if (type == 'PONG') {
      final sentAt = int.tryParse('${data['sentAt'] ?? ''}');
      if (sentAt != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - sentAt;
        if (mounted) {
          setState(() {
            relayLatencyMs = max(0, elapsed);
          });
        }
      }
    } else if (type == 'ROOM_READY') {
      final room = normalizeRelayRoom('${data['room'] ?? relayRoomCode}');
      final role = '${data['role'] ?? ''}';
      setState(() {
        relayRoomCode = room;
        relayRoomController.text = room;
        waitingInternetInvite = false;
        isMasterHost = role == 'master';
        isConnectedToMaster = role == 'player';
        modalitaMaster = role == 'master';
        connectedMasterIp = role == 'player' ? 'Relay $room' : '';
        relayStatus = role == 'master'
            ? t('Stanza Internet creata: $room', 'Internet room created: $room')
            : t(
                'Unito alla stanza Internet: $room',
                'Joined Internet room: $room',
              );
        risultato = relayStatus;
        aggiungiLog(risultato);
      });
      if (role == 'player') {
        sendSheetToRelay();
      }
      if (role == 'master') {
        unawaited(copyRelayInvite());
      }
    } else if (type == 'LOBBY_READY') {
      setState(() {
        waitingInternetInvite = true;
        relayStatus = t(
          'Sei visibile al Master per gli inviti Internet.',
          'You are visible to the Master for Internet invites.',
        );
        risultato = relayStatus;
        aggiungiLog(risultato);
      });
    } else if (type == 'LOBBY_PLAYERS') {
      final players = data['players'];
      if (players is List) {
        setState(() {
          internetAvailablePlayers = players
              .whereType<Map>()
              .map((p) => Map<String, dynamic>.from(p))
              .toList();
        });
      }
    } else if (type == 'INTERNET_INVITE') {
      _showInternetInviteDialog(data);
    } else if (type == 'INVITE_SENT') {
      setState(() {
        risultato = t('Invito inviato.', 'Invite sent.');
        relayStatus = risultato;
        aggiungiLog(risultato);
      });
    } else if (type == 'PLAYER_JOINED') {
      setState(() {
        risultato = t(
          '${data['name'] ?? 'Giocatore'} è entrato nella stanza.',
          '${data['name'] ?? 'Player'} joined the room.',
        );
        relayStatus = risultato;
        aggiungiLog(risultato);
      });
    } else if (type == 'SHEET_UPDATE') {
      if (isMasterHost || sonoCoMaster) {
        registraSchedaRemota(data['sheet']);
      }
    } else if (type == 'KICK_PLAYER') {
      handleKickFromMaster(data);
    } else if (type == 'SET_COMASTER') {
      final myId = sheetTagAt(schedaCorrente);
      if ('${data['targetId'] ?? ''}' == myId) {
        setState(() {
          sonoCoMaster = readBoolValue(data['status']);
          risultato = sonoCoMaster
              ? t(
                  'Sei stato promosso a Co-Master!',
                  'You have been promoted to Co-Master!',
                )
              : t(
                  'I tuoi poteri da Co-Master sono stati revocati.',
                  'Your Co-Master powers have been revoked.',
                );
          relayStatus = risultato;
          aggiungiLog(risultato);
        });
        unawaited(salvaDatiSoloLocale());
      }
    } else if (type == 'ERROR') {
      setState(() {
        risultato = '${data['message'] ?? 'Relay error'}';
        relayStatus = risultato;
        aggiungiLog(risultato);
      });
    }
  }

  void sendKickPlayer(String targetId) {
    final cleanTarget = targetId.trim();
    if (cleanTarget.isEmpty) return;

    if (usingInternetRelay && relayConnected && _relaySocket != null) {
      _sendRelay({
        'type': 'KICK_PLAYER',
        'room': relayRoomCode,
        'targetId': cleanTarget,
      });
    }

    if (isMasterHost && _clientSockets.isNotEmpty) {
      _broadcastToClients(
        jsonEncode({'type': 'KICK_PLAYER', 'targetId': cleanTarget}),
      );
    }
  }

  void handleKickFromMaster(Map<dynamic, dynamic> data) {
    final targetId = '${data['targetId'] ?? ''}'.trim();
    if (targetId.isEmpty || targetId != sheetTagAt(schedaCorrente)) return;

    unawaited(disconnectInternetRelay(silent: true));
    unawaited(disconnectFromLocalMaster());

    if (!mounted) return;
    setState(() {
      isConnectedToMaster = false;
      isMasterHost = false;
      modalitaMaster = false;
      sonoCoMaster = false;
      relayConnected = false;
      usingInternetRelay = false;
      connectedMasterIp = '';
      risultato = t(
        'Sei stato kickato dalla sessione dal Master.',
        'You were kicked from the session by the Master.',
      );
      relayStatus = risultato;
      aggiungiLog(risultato);
    });
  }

  void _showInternetInviteDialog(Map<dynamic, dynamic> data) {
    final room = normalizeRelayRoom('${data['room'] ?? ''}');
    final masterName = '${data['masterName'] ?? 'Master'}';
    if (room.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF10121A),
          title: Text(
            t('Invito Internet', 'Internet Invite'),
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            t(
              '$masterName ti ha invitato alla stanza $room.\nVuoi unirti al party?',
              '$masterName invited you to room $room.\nDo you want to join the party?',
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                t('No', 'No'),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: tertiaryColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                acceptInternetInvite(room);
              },
              child: Text(t('Sì', 'Yes')),
            ),
          ],
        );
      },
    );
  }

  void registraSchedaRemota(dynamic sheetData) {
    if (sheetData is! Map) return;

    final sheetCopy = Map<String, dynamic>.from(sheetData);
    final sheetId = '${sheetCopy['id'] ?? sheetCopy['sheetTag'] ?? ''}'.trim();
    if (sheetId.isEmpty) return;
    if (sheetId == sheetTagAt(schedaCorrente)) return;

    final idx = partyMembri.indexWhere((p) => p['id'] == sheetId);
    final previous = idx >= 0 ? partyMembri[idx] : <String, dynamic>{};
    final wasCoMaster = readBoolValue(previous['isCoMaster']);

    sheetCopy['id'] = sheetId;
    sheetCopy['sheetTag'] = sheetId;
    sheetCopy['inMasterParty'] = true;
    sheetCopy['isCoMaster'] = wasCoMaster;
    sheetCopy['lastSeenAt'] = DateTime.now().toIso8601String();

    setState(() {
      if (idx >= 0) {
        partyMembri[idx] = sheetCopy;
      } else {
        partyMembri.add(sheetCopy);
      }
    });
    salvaDatiSoloLocale();
  }

  void sendSheetToMaster() {
    if (!isConnectedToMaster || _myClientSocket == null) return;

    if (schedePersonaggio.isNotEmpty) {
      salvaSchedaCorrenteInMemoria();
      final sheetId = sheetTagAt(schedaCorrente);
      schedePersonaggio[schedaCorrente]['id'] = sheetId;
      schedePersonaggio[schedaCorrente]['sheetTag'] = sheetId;
      final payloadHash = jsonEncode(schedePersonaggio[schedaCorrente]);
      final hashKey = 'p2p_master:$sheetId';
      if (realtimeLastSentSheetHashes[hashKey] == payloadHash) return;
      realtimeLastSentSheetHashes[hashKey] = payloadHash;

      final msg = jsonEncode({
        'type': 'SHEET_UPDATE',
        'sheet': schedePersonaggio[schedaCorrente],
      });
      _myClientSocket?.add(msg);
    }
  }

  void sendSheetToRelay() {
    if (!relayConnected || _relaySocket == null) return;
    if (!isConnectedToMaster && !isMasterHost) return;
    if (isMasterHost || modalitaMaster) return;

    if (schedePersonaggio.isNotEmpty) {
      salvaSchedaCorrenteInMemoria();
      final sheetId = sheetTagAt(schedaCorrente);
      schedePersonaggio[schedaCorrente]['id'] = sheetId;
      schedePersonaggio[schedaCorrente]['sheetTag'] = sheetId;
      final payloadHash = jsonEncode(schedePersonaggio[schedaCorrente]);
      final hashKey = 'relay:$sheetId';
      if (realtimeLastSentSheetHashes[hashKey] == payloadHash) return;
      realtimeLastSentSheetHashes[hashKey] = payloadHash;

      _sendRelay({
        'type': 'SHEET_UPDATE',
        'room': relayRoomCode,
        'fromId': sheetId,
        'sheet': schedePersonaggio[schedaCorrente],
      });
    }
  }

  // ---------------------------------------------------------
  // HOOKS AL SALVATAGGIO
  // ---------------------------------------------------------
  // Da chiamare ogni volta che la scheda viene salvata localmente,
  // così da inviare l'update al Master (e lui ai giocatori)
  void p2pSyncOnSave() {
    if (usingInternetRelay && relayConnected) {
      sendSheetToRelay();
    } else if (isConnectedToMaster) {
      sendSheetToMaster();
    }
  }
}
