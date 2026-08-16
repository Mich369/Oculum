part of '../oculum_dungeon_game.dart';

class OculumDungeonRealtimeBridge {
  const OculumDungeonRealtimeBridge({
    required this.isConnected,
    required this.localPlayerId,
    required this.playerIds,
    required this.send,
    required this.messages,
  });

  final bool Function() isConnected;
  final String Function() localPlayerId;
  final List<String> Function() playerIds;
  final void Function(Map<String, dynamic> payload) send;
  final ValueListenable<Map<String, dynamic>?> messages;
}

class _DungeonCoopState {
  String sessionId = '';
  String hostId = '';
  String passwordHash = '';
  bool isHost = false;
  final Set<String> memberIds = <String>{};
  final Map<String, _DungeonCoopMember> members =
      <String, _DungeonCoopMember>{};
  final Map<String, int> votesByPlayer = <String, int>{};
  final Map<String, String> turnActions = <String, String>{};
  List<Map<String, dynamic>> remoteChoices = <Map<String, dynamic>>[];
  String choiceId = '';
  DateTime? choiceDeadline;
  Timer? voteTimer;
  Timer? turnTimer;
  DateTime? turnDeadline;
  String turnId = '';
  bool resolvingTurn = false;
  Map<String, dynamic>? pendingSession;

  bool get active => sessionId.isNotEmpty;
  bool get passwordProtected => passwordHash.isNotEmpty;
  bool get voting => choiceId.isNotEmpty;

  void clearVote() {
    votesByPlayer.clear();
    remoteChoices = <Map<String, dynamic>>[];
    choiceId = '';
    choiceDeadline = null;
    voteTimer?.cancel();
    voteTimer = null;
  }

  void clearTurn() {
    turnActions.clear();
    turnDeadline = null;
    turnId = '';
    turnTimer?.cancel();
    turnTimer = null;
  }

  void dispose() {
    voteTimer?.cancel();
    turnTimer?.cancel();
  }
}

class _DungeonCoopMember {
  const _DungeonCoopMember({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.damage,
    required this.defense,
    required this.vc,
    required this.cm,
    required this.level,
    required this.grade,
  });

  final String id;
  final String name;
  final int maxHp;
  final int damage;
  final int defense;
  final int vc;
  final int cm;
  final int level;
  final int grade;

  factory _DungeonCoopMember.fromMap(Map<dynamic, dynamic> data) {
    int value(String key, {int fallback = 0}) {
      final raw = data[key];
      if (raw is num) return raw.toInt();
      return int.tryParse('${raw ?? ''}') ?? fallback;
    }

    return _DungeonCoopMember(
      id: '${data['id'] ?? ''}',
      name: '${data['name'] ?? 'Alleato online'}',
      maxHp: max(1, value('maxHp', fallback: 30)),
      damage: max(1, value('damage', fallback: 1)),
      defense: max(0, value('defense')),
      vc: max(0, value('vc')),
      cm: max(0, value('cm')),
      level: max(1, value('level', fallback: 1)),
      grade: max(0, value('grade')),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'maxHp': maxHp,
    'damage': damage,
    'defense': defense,
    'vc': vc,
    'cm': cm,
    'level': level,
    'grade': grade,
  };
}

extension _OculumDungeonRealtimeCoop on _OculumDungeonGameDialogState {
  OculumDungeonRealtimeBridge? get _coopBridge => widget.realtimeBridge;

  bool get hasDungeonCoopConnection => _coopBridge?.isConnected() == true;
  bool get isDungeonCoopActive => dungeonCoop.active;
  bool get isDungeonCoopHost => dungeonCoop.active && dungeonCoop.isHost;
  bool get isDungeonCoopClient => dungeonCoop.active && !dungeonCoop.isHost;
  bool get isDungeonCoopTurnOpen =>
      dungeonCoop.turnId.isNotEmpty && !dungeonCoop.resolvingTurn;
  bool get canVoteDungeonCoopChoices =>
      isDungeonCoopActive &&
      !isDungeonCoopTurnOpen &&
      choicePanelMode == 'event' &&
      !dungeonCoop.resolvingTurn;

  int get onlineCompanionCount => max(0, dungeonCoop.members.length - 1);
  int get onlineNpcSlotCost => max(0, dungeonCoop.members.length - 3);
  int get maxRunNpcAllies => max(0, maxActiveAllies - onlineNpcSlotCost);

  String get _coopLocalId {
    final bridge = _coopBridge;
    if (bridge == null) return '';
    final raw = bridge.localPlayerId().trim();
    return raw.isEmpty ? playerNameInRun.trim() : raw;
  }

  _DungeonCoopMember _localCoopMember() => _DungeonCoopMember(
    id: _coopLocalId,
    name: playerNameInRun,
    maxHp: playerMaxHp,
    damage: totalDamage,
    defense: totalDefense,
    vc: totalVc,
    cm: totalCm,
    level: max(1, dungeonLevel > 0 ? dungeonLevel : widget.playerLevel),
    grade: max(0, runGrade > 0 ? runGrade : widget.playerGrade),
  );

  String _coopPasswordHash(String sessionId, String password) {
    final clean = password.trim();
    if (sessionId.trim().isEmpty || clean.isEmpty) return '';
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode('${sessionId.trim()}|$clean')) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<String?> _askDungeonCoopPassword({
    required bool host,
    required String hostName,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF10121A),
        title: Text(
          host
              ? t('Password run online', 'Online run password')
              : t('Run protetta', 'Protected run'),
          style: TextStyle(color: widget.tertiaryColor),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: host
                ? t('Password opzionale', 'Optional password')
                : t('Password di $hostName', '$hostName password'),
            helperText: host
                ? t(
                    'Lascia vuoto per una run libera.',
                    'Leave empty for an open run.',
                  )
                : t(
                    'Serve per entrare nella sessione online.',
                    'Required to join the online session.',
                  ),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: Text(t('Annulla', 'Cancel')),
          ),
          if (host)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: Text(t('Senza password', 'No password')),
            ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            icon: const Icon(Icons.lock_open),
            label: Text(host ? t('Avvia', 'Host') : t('Entra', 'Join')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void initDungeonCoop() {
    _coopBridge?.messages.addListener(_handleDungeonCoopMessage);
  }

  void disposeDungeonCoop() {
    if (isDungeonCoopHost) {
      _sendCoop(<String, dynamic>{'kind': 'session_close'});
    }
    _coopBridge?.messages.removeListener(_handleDungeonCoopMessage);
    dungeonCoop.dispose();
  }

  void _sendCoop(Map<String, dynamic> payload) {
    final bridge = _coopBridge;
    if (bridge == null || !bridge.isConnected()) return;
    bridge.send(<String, dynamic>{
      ...payload,
      'senderId': _coopLocalId,
      'sessionId': dungeonCoop.sessionId,
    });
  }

  void hostDungeonCoopSession() {
    unawaited(_hostDungeonCoopSession());
  }

  Future<void> _hostDungeonCoopSession() async {
    if (!hasDungeonCoopConnection) return;
    final sessionId = '$_coopLocalId-${DateTime.now().microsecondsSinceEpoch}';
    final password = await _askDungeonCoopPassword(
      host: true,
      hostName: playerNameInRun,
    );
    if (password == null || !mounted) return;
    final passwordHash = _coopPasswordHash(sessionId, password);
    refreshDungeonUi(() {
      dungeonCoop.clearTurn();
      dungeonCoop.clearVote();
      dungeonCoop.sessionId = sessionId;
      dungeonCoop.hostId = _coopLocalId;
      dungeonCoop.passwordHash = passwordHash;
      dungeonCoop.isHost = true;
      dungeonCoop.memberIds
        ..clear()
        ..add(_coopLocalId);
      dungeonCoop.members
        ..clear()
        ..[_coopLocalId] = _localCoopMember();
      textIt =
          'Run online aperta${passwordHash.isEmpty ? '' : ' con password'}. Gli altri giocatori possono unirsi dalla loro schermata Dungeon. Fino a 5 personaggi condividono la run.';
      textEn =
          'Online run opened${passwordHash.isEmpty ? '' : ' with password'}. Other players can join from their Dungeon screen. Up to 5 characters share the run.';
    });
    _sendCoop(<String, dynamic>{
      'kind': 'session_open',
      'hostId': _coopLocalId,
      'hostName': playerNameInRun,
      'passwordProtected': passwordHash.isNotEmpty,
      'passwordHash': passwordHash,
    });
    _broadcastDungeonCoopState();
  }

  void joinPendingDungeonCoopSession() {
    unawaited(_joinPendingDungeonCoopSession());
  }

  Future<void> _joinPendingDungeonCoopSession() async {
    final pending = dungeonCoop.pendingSession;
    if (!hasDungeonCoopConnection || pending == null) return;
    final sessionId = '${pending['sessionId'] ?? ''}';
    final hostId = '${pending['hostId'] ?? ''}';
    if (sessionId.isEmpty || hostId.isEmpty) return;
    final expectedHash = '${pending['passwordHash'] ?? ''}'.trim();
    if (expectedHash.isNotEmpty) {
      final hostName = '${pending['hostName'] ?? hostId}';
      final password = await _askDungeonCoopPassword(
        host: false,
        hostName: hostName,
      );
      if (password == null || !mounted) return;
      final typedHash = _coopPasswordHash(sessionId, password);
      if (typedHash != expectedHash) {
        refreshDungeonUi(() {
          textIt = 'Password errata per la run di $hostName.';
          textEn = 'Wrong password for $hostName run.';
        });
        return;
      }
    }

    refreshDungeonUi(() {
      dungeonCoop.clearTurn();
      dungeonCoop.sessionId = sessionId;
      dungeonCoop.hostId = hostId;
      dungeonCoop.passwordHash = expectedHash;
      dungeonCoop.isHost = false;
      dungeonCoop.memberIds
        ..clear()
        ..add(_coopLocalId);
      dungeonCoop.members
        ..clear()
        ..[_coopLocalId] = _localCoopMember();
      textIt =
          'Richiesta inviata alla run di ${pending['hostName'] ?? hostId}.';
      textEn = 'Join request sent to ${pending['hostName'] ?? hostId}.';
    });
    _sendCoop(<String, dynamic>{
      'kind': 'session_join',
      'hostId': hostId,
      'passwordHash': expectedHash,
      'member': _localCoopMember().toMap(),
    });
  }

  void leaveDungeonCoopSession() {
    if (!dungeonCoop.active) return;
    if (isDungeonCoopHost) {
      _sendCoop(<String, dynamic>{'kind': 'session_close'});
    }
    _sendCoop(<String, dynamic>{'kind': 'session_leave'});
    refreshDungeonUi(() {
      dungeonCoop.clearTurn();
      dungeonCoop.clearVote();
      dungeonCoop.sessionId = '';
      dungeonCoop.hostId = '';
      dungeonCoop.passwordHash = '';
      dungeonCoop.isHost = false;
      dungeonCoop.memberIds.clear();
      dungeonCoop.members.clear();
      textIt =
          'Hai lasciato la run online. Il tuo checkpoint locale resta invariato.';
      textEn =
          'You left the online run. Your local checkpoint remains unchanged.';
    });
  }

  void showDungeonCoopPanel() {
    refreshDungeonUi(() {
      clearChoices(mode: 'info');
      if (!hasDungeonCoopConnection) {
        textIt =
            'Realtime non connesso. Connettiti prima di avviare una run online.';
        textEn =
            'Realtime is not connected. Connect before starting an online run.';
        return;
      }

      final members = dungeonCoop.members.values
          .map((member) => member.name)
          .join(', ');
      textIt = isDungeonCoopActive
          ? 'Run online ${isDungeonCoopHost ? 'host' : 'collegata'}${dungeonCoop.passwordProtected ? ' protetta' : ''}.\nPartecipanti (${dungeonCoop.members.length}/5, online $onlineCompanionCount): $members\nSlot NPC disponibili: $maxRunNpcAllies. Oltre tre personaggi, gli extra occupano gli slot NPC della run.'
          : 'Dungeon online. Avvia una run host oppure unisciti a una run aperta ricevuta via realtime.';
      textEn = isDungeonCoopActive
          ? 'Online run ${isDungeonCoopHost ? 'hosted' : 'joined'}${dungeonCoop.passwordProtected ? ' protected' : ''}.\nMembers (${dungeonCoop.members.length}/5, online $onlineCompanionCount): $members\nAvailable NPC slots: $maxRunNpcAllies. Beyond three characters, extras use NPC run slots.'
          : 'Online Dungeon. Host a run or join an open run received through realtime.';

      if (!isDungeonCoopActive) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Avvia run online',
            labelEn: 'Host online run',
            icon: Icons.wifi_tethering,
            color: const Color(0xFF6EE7B7),
            onPressed: hostDungeonCoopSession,
          ),
        );
        if (dungeonCoop.pendingSession != null) {
          eventChoices.add(
            _DungeonChoice(
              labelIt: 'Unisciti a ${dungeonCoop.pendingSession!['hostName']}',
              labelEn: 'Join ${dungeonCoop.pendingSession!['hostName']}',
              icon:
                  '${dungeonCoop.pendingSession!['passwordHash'] ?? ''}'
                      .trim()
                      .isEmpty
                  ? Icons.group_add
                  : Icons.lock,
              color: const Color(0xFF67E8F9),
              onPressed: joinPendingDungeonCoopSession,
            ),
          );
        }
      } else {
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Lascia run online',
            labelEn: 'Leave online run',
            icon: Icons.link_off,
            color: Colors.orangeAccent,
            onPressed: leaveDungeonCoopSession,
          ),
        );
      }
    });
  }

  void _broadcastDungeonCoopState() {
    if (!isDungeonCoopHost) return;
    _sendCoop(<String, dynamic>{
      'kind': 'session_state',
      'hostId': dungeonCoop.hostId,
      'hostName': playerNameInRun,
      'passwordProtected': dungeonCoop.passwordProtected,
      'passwordHash': dungeonCoop.passwordHash,
      'members': dungeonCoop.members.values
          .map((member) => member.toMap())
          .toList(),
      'checkpoint': buildRunCheckpointData(),
    });
  }

  void _broadcastDungeonCoopRewards({required int spentGain}) {
    if (!isDungeonCoopHost) return;
    _sendCoop(<String, dynamic>{
      'kind': 'session_rewards',
      'spentOculum': spentGain,
      'achievementIds': completedAchievementIds.toList(),
    });
  }

  void _handleDungeonCoopMessage() {
    final raw = _coopBridge?.messages.value;
    if (raw == null) return;
    final senderId = '${raw['senderId'] ?? ''}';
    if (senderId.isNotEmpty && senderId == _coopLocalId) return;
    final kind = '${raw['kind'] ?? ''}';
    if (kind.isEmpty) return;

    if (kind == 'session_open') {
      final hostId = '${raw['hostId'] ?? ''}';
      final sessionId = '${raw['sessionId'] ?? ''}';
      if (hostId.isEmpty || sessionId.isEmpty || hostId == _coopLocalId) return;
      if (!mounted) return;
      refreshDungeonUi(() {
        dungeonCoop.pendingSession = <String, dynamic>{
          'hostId': hostId,
          'hostName': raw['hostName'] ?? raw['playerName'] ?? hostId,
          'sessionId': sessionId,
          'passwordProtected': raw['passwordProtected'] == true,
          'passwordHash': '${raw['passwordHash'] ?? ''}',
        };
      });
      return;
    }

    if (kind == 'session_discover') {
      if (!isDungeonCoopHost) return;
      _sendCoop(<String, dynamic>{
        'kind': 'session_open',
        'hostId': dungeonCoop.hostId,
        'hostName': playerNameInRun,
        'passwordProtected': dungeonCoop.passwordProtected,
        'passwordHash': dungeonCoop.passwordHash,
      });
      _broadcastDungeonCoopState();
      return;
    }

    final sessionId = '${raw['sessionId'] ?? ''}';
    final hostId = '${raw['hostId'] ?? ''}';
    if (kind == 'session_state' &&
        !isDungeonCoopActive &&
        sessionId.isNotEmpty &&
        hostId.isNotEmpty &&
        hostId != _coopLocalId) {
      if (!mounted) return;
      refreshDungeonUi(() {
        dungeonCoop.pendingSession = <String, dynamic>{
          'hostId': hostId,
          'hostName': raw['hostName'] ?? raw['playerName'] ?? hostId,
          'sessionId': sessionId,
          'passwordProtected': raw['passwordProtected'] == true,
          'passwordHash': '${raw['passwordHash'] ?? ''}',
        };
      });
      return;
    }
    if (sessionId.isEmpty || sessionId != dungeonCoop.sessionId) return;

    switch (kind) {
      case 'session_join':
        if (!isDungeonCoopHost) return;
        final memberRaw = raw['member'];
        if (memberRaw is! Map) return;
        if (dungeonCoop.passwordProtected &&
            '${raw['passwordHash'] ?? ''}'.trim() != dungeonCoop.passwordHash) {
          return;
        }
        final member = _DungeonCoopMember.fromMap(memberRaw);
        if (member.id.isEmpty || dungeonCoop.members.length >= 5) return;
        refreshDungeonUi(() {
          dungeonCoop.memberIds.add(member.id);
          dungeonCoop.members[member.id] = member;
          textIt = '${member.name} entra nella run online.';
          textEn = '${member.name} joins the online run.';
        });
        _broadcastDungeonCoopState();
        return;
      case 'session_leave':
        if (!isDungeonCoopHost) return;
        refreshDungeonUi(() {
          dungeonCoop.memberIds.remove(senderId);
          dungeonCoop.members.remove(senderId);
          dungeonCoop.turnActions.remove(senderId);
        });
        _broadcastDungeonCoopState();
        return;
      case 'session_state':
        if (isDungeonCoopHost) return;
        final checkpoint = raw['checkpoint'];
        final membersRaw = raw['members'];
        if (checkpoint is! Map) return;
        if (!mounted) return;
        refreshDungeonUi(() {
          dungeonCoop.memberIds.clear();
          dungeonCoop.members.clear();
          if (membersRaw is List) {
            for (final item in membersRaw.whereType<Map>()) {
              final member = _DungeonCoopMember.fromMap(item);
              if (member.id.isEmpty) continue;
              dungeonCoop.memberIds.add(member.id);
              dungeonCoop.members[member.id] = member;
            }
          }
          restoreRunCheckpoint(Map<String, dynamic>.from(checkpoint));
        });
        return;
      case 'turn_open':
        if (isDungeonCoopHost) return;
        final deadlineMs = raw['deadlineMs'];
        final deadline = deadlineMs is num
            ? DateTime.fromMillisecondsSinceEpoch(deadlineMs.toInt())
            : DateTime.now().add(const Duration(seconds: 20));
        if (!mounted) return;
        refreshDungeonUi(() {
          dungeonCoop.clearTurn();
          dungeonCoop.turnId = '${raw['turnId'] ?? ''}';
          dungeonCoop.turnDeadline = deadline;
          textIt = 'Turno online: scegli Attacca o Difendi entro 20 secondi.';
          textEn = 'Online turn: choose Attack or Defend within 20 seconds.';
        });
        return;
      case 'turn_action':
        if (!isDungeonCoopHost ||
            dungeonCoop.turnId != '${raw['turnId'] ?? ''}') {
          return;
        }
        final action = '${raw['action'] ?? ''}';
        final parts = action.split('|').map((part) => part.trim()).toSet();
        if (!parts.contains('attack') && !parts.contains('defend')) return;
        dungeonCoop.turnActions[senderId] = action;
        if (dungeonCoop.turnActions.length >= dungeonCoop.memberIds.length) {
          _resolveDungeonCoopTurn();
        }
        return;
      case 'choice_open':
        if (isDungeonCoopHost) return;
        final choices = raw['choices'];
        final deadlineMs = raw['deadlineMs'];
        final deadline = deadlineMs is num
            ? DateTime.fromMillisecondsSinceEpoch(deadlineMs.toInt())
            : DateTime.now().add(const Duration(seconds: 18));
        if (!mounted || choices is! List) return;
        refreshDungeonUi(() {
          dungeonCoop.clearVote();
          dungeonCoop.choiceId = '${raw['choiceId'] ?? ''}';
          dungeonCoop.choiceDeadline = deadline;
          dungeonCoop.remoteChoices = choices
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          showEventChoices = true;
        });
        return;
      case 'choice_vote':
        if (!isDungeonCoopHost ||
            dungeonCoop.choiceId != '${raw['choiceId'] ?? ''}') {
          return;
        }
        final index = raw['index'];
        if (index is! num) return;
        dungeonCoop.votesByPlayer[senderId] = index.toInt();
        if (dungeonCoop.votesByPlayer.length >= dungeonCoop.memberIds.length) {
          resolveDungeonCoopChoiceVote();
        }
        return;
      case 'choice_resolve':
        if (isDungeonCoopHost) return;
        if (!mounted) return;
        final index = raw['index'];
        refreshDungeonUi(() {
          final label =
              index is num &&
                  index.toInt() >= 0 &&
                  index.toInt() < dungeonCoop.remoteChoices.length
              ? '${dungeonCoop.remoteChoices[index.toInt()]['label'] ?? ''}'
              : '';
          textIt = label.isEmpty
              ? 'Scelta online risolta. Il dungeon avanza con l host.'
              : 'Scelta online risolta: $label.';
          textEn = label.isEmpty
              ? 'Online choice resolved. The dungeon advances with the host.'
              : 'Online choice resolved: $label.';
          dungeonCoop.clearVote();
        });
        return;
      case 'session_rewards':
        if (isDungeonCoopHost) return;
        final earned = raw['spentOculum'] is num
            ? (raw['spentOculum'] as num).toInt()
            : 0;
        final achievements = raw['achievementIds'];
        if (!mounted) return;
        refreshDungeonUi(() {
          oculumSpento += max(0, earned);
          if (achievements is List) {
            completedAchievementIds.addAll(
              achievements.map((value) => value.toString()),
            );
          }
          textIt = 'Ricompense online ricevute: +$earned Oculum Spento.';
          textEn = 'Online rewards received: +$earned Spent Oculum.';
        });
        _savePermanentProgress();
        return;
    }
  }

  void openDungeonCoopTurnWindow() {
    if (!isDungeonCoopHost || !inCombat || enemyTurnPending || gameOver) return;
    dungeonCoop.clearTurn();
    dungeonCoop.turnId = 'turn-${DateTime.now().microsecondsSinceEpoch}';
    dungeonCoop.turnDeadline = DateTime.now().add(const Duration(seconds: 20));
    dungeonCoop.turnTimer = Timer(
      const Duration(seconds: 20),
      _resolveDungeonCoopTurn,
    );
    _sendCoop(<String, dynamic>{
      'kind': 'turn_open',
      'turnId': dungeonCoop.turnId,
      'deadlineMs': dungeonCoop.turnDeadline!.millisecondsSinceEpoch,
    });
    if (mounted) {
      refreshDungeonUi(() {
        textIt +=
            '\n\nTurno online: tutti scelgono Attacca o Difendi entro 20 secondi.';
        textEn +=
            '\n\nOnline turn: everyone chooses Attack or Defend within 20 seconds.';
      });
    }
  }

  bool submitDungeonCoopAction(String action) {
    final parts = action
        .split('|')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet();
    final hasReaction =
        parts.contains('reaction_defend') || parts.contains('reaction_counter');
    final mainAction = parts.contains('attack')
        ? 'attack'
        : parts.contains('defend')
        ? 'defend'
        : '';
    if (!isDungeonCoopTurnOpen || (mainAction.isEmpty && !hasReaction)) {
      return false;
    }
    final id = _coopLocalId;
    if (id.isEmpty) return true;
    final existing = dungeonCoop.turnActions[id];
    late final String storedAction;
    if (existing != null) {
      if (!hasReaction) return true;
      final merged = <String>{
        ...existing.split('|').where((part) => part.trim().isNotEmpty),
        ...parts,
      }.join('|');
      dungeonCoop.turnActions[id] = merged;
      storedAction = merged;
    } else {
      storedAction = mainAction.isEmpty
          ? 'guard_attack|${parts.join('|')}'
          : action;
      dungeonCoop.turnActions[id] = storedAction;
    }
    if (isDungeonCoopHost) {
      if (dungeonCoop.turnActions.length >= dungeonCoop.memberIds.length) {
        _resolveDungeonCoopTurn();
      }
    } else {
      _sendCoop(<String, dynamic>{
        'kind': 'turn_action',
        'turnId': dungeonCoop.turnId,
        'action': storedAction,
      });
    }
    if (mounted) {
      refreshDungeonUi(() {
        textIt = action == 'attack'
            ? 'Azione online inviata: attacca.'
            : action == 'defend'
            ? 'Azione online inviata: difendi.'
            : 'Azione online inviata: ${action.replaceAll('|', ' + ')}.';
        textEn = action == 'attack'
            ? 'Online action sent: attack.'
            : action == 'defend'
            ? 'Online action sent: defend.'
            : 'Online action sent: ${action.replaceAll('|', ' + ')}.';
      });
    }
    return true;
  }

  void _resolveDungeonCoopTurn() {
    if (!isDungeonCoopHost ||
        !isDungeonCoopTurnOpen ||
        dungeonCoop.resolvingTurn) {
      return;
    }
    if (!mounted) return;
    refreshDungeonUi(() {
      dungeonCoop.resolvingTurn = true;
      final target = firstAliveEnemy();
      if (target == null) {
        dungeonCoop.clearTurn();
        dungeonCoop.resolvingTurn = false;
        completeCombatVictory();
        return;
      }

      var totalDamage = 0;
      var totalShield = 0;
      for (final member in dungeonCoop.members.values) {
        final action = dungeonCoop.turnActions[member.id] ?? 'guard_attack';
        final parts = action.split('|').toSet();
        final shouldDefend =
            parts.contains('defend') ||
            parts.contains('reaction_defend') ||
            action == 'guard_attack';
        final shouldAttack =
            parts.contains('attack') ||
            parts.contains('reaction_counter') ||
            action == 'guard_attack';
        if (shouldDefend) {
          final shield = max(2, 5 + member.defense ~/ 3 + member.grade);
          gainPlayerShield(shield);
          totalShield += shield;
        }
        if (shouldAttack && target.hp > 0) {
          final raw =
              member.damage + member.vc ~/ 2 + member.level + member.grade * 2;
          final damage = max(1, raw - target.defense ~/ 2);
          target.hp = max(0, target.hp - damage).toInt();
          totalDamage += damage;
        }
      }
      dungeonCoop.clearTurn();
      dungeonCoop.resolvingTurn = false;
      textIt =
          'Turno online risolto: $totalDamage danni condivisi, +$totalShield Scudo di squadra. Alleati e mostri agiscono ora.';
      textEn =
          'Online turn resolved: $totalDamage shared damage, +$totalShield party Shield. Allies and monsters act now.';
      defeatDeadEnemiesFromParty();
      if (enemyParty.isEmpty) {
        completeCombatVictory();
        return;
      }
      syncPrimaryEnemyFromParty();
      alliesAct();
      if (enemyParty.isEmpty) {
        completeCombatVictory();
        return;
      }
      enemyTurn();
    });
  }

  List<_DungeonChoice> dungeonCoopChoicesForPanel(
    List<_DungeonChoice> localChoices,
  ) {
    if (!canVoteDungeonCoopChoices) return localChoices;

    if (isDungeonCoopHost) {
      publishDungeonCoopChoices(localChoices);
      return [
        for (var i = 0; i < localChoices.length; i++)
          _DungeonChoice(
            labelIt: voteLabelForChoice(localChoices[i], i),
            labelEn: voteLabelForChoice(localChoices[i], i, english: true),
            icon: localChoices[i].icon,
            color: localChoices[i].color,
            onPressed: () => submitDungeonCoopChoiceVote(i),
          ),
      ];
    }

    if (dungeonCoop.remoteChoices.isEmpty) return localChoices;
    return [
      for (var i = 0; i < dungeonCoop.remoteChoices.length; i++)
        _DungeonChoice(
          labelIt: voteLabelForRemoteChoice(i),
          labelEn: voteLabelForRemoteChoice(i),
          icon: Icons.how_to_vote,
          color: const Color(0xFF67E8F9),
          onPressed: () => submitDungeonCoopChoiceVote(i),
        ),
    ];
  }

  String voteLabelForChoice(
    _DungeonChoice choice,
    int index, {
    bool english = false,
  }) {
    final votes = dungeonCoop.votesByPlayer.values
        .where((value) => value == index)
        .length;
    final base = english ? choice.labelEn : choice.labelIt;
    return votes > 0 ? '$base ($votes)' : base;
  }

  String voteLabelForRemoteChoice(int index) {
    final data = dungeonCoop.remoteChoices[index];
    final base =
        '${data[widget.linguaInglese ? 'labelEn' : 'labelIt'] ?? data['label'] ?? '?'}';
    final votes = dungeonCoop.votesByPlayer.values
        .where((value) => value == index)
        .length;
    return votes > 0 ? '$base ($votes)' : base;
  }

  void publishDungeonCoopChoices(List<_DungeonChoice> choices) {
    if (!isDungeonCoopHost || choices.isEmpty) return;
    final signature = choices
        .map((choice) => '${choice.labelIt}/${choice.labelEn}')
        .join('|');
    final nextChoiceId = 'choice-${signature.hashCode}-${choices.length}';
    if (dungeonCoop.choiceId == nextChoiceId) return;
    dungeonCoop.clearVote();
    dungeonCoop.choiceId = nextChoiceId;
    dungeonCoop.choiceDeadline = DateTime.now().add(
      const Duration(seconds: 18),
    );
    dungeonCoop.remoteChoices = [
      for (var i = 0; i < choices.length; i++)
        <String, dynamic>{
          'index': i,
          'labelIt': choices[i].labelIt,
          'labelEn': choices[i].labelEn,
        },
    ];
    dungeonCoop.voteTimer = Timer(
      const Duration(seconds: 18),
      resolveDungeonCoopChoiceVote,
    );
    _sendCoop(<String, dynamic>{
      'kind': 'choice_open',
      'choiceId': dungeonCoop.choiceId,
      'deadlineMs': dungeonCoop.choiceDeadline!.millisecondsSinceEpoch,
      'choices': dungeonCoop.remoteChoices,
    });
  }

  void submitDungeonCoopChoiceVote(int index) {
    if (!canVoteDungeonCoopChoices || index < 0) return;
    final id = _coopLocalId;
    if (id.isEmpty) return;
    refreshDungeonUi(() {
      dungeonCoop.votesByPlayer[id] = index;
      textIt = 'Voto inviato. Il dungeon avanza con la maggioranza.';
      textEn = 'Vote sent. The dungeon advances by majority.';
    });
    if (isDungeonCoopHost) {
      if (dungeonCoop.votesByPlayer.length >= dungeonCoop.memberIds.length) {
        resolveDungeonCoopChoiceVote();
      }
    } else {
      _sendCoop(<String, dynamic>{
        'kind': 'choice_vote',
        'choiceId': dungeonCoop.choiceId,
        'index': index,
      });
    }
  }

  void resolveDungeonCoopChoiceVote() {
    if (!isDungeonCoopHost ||
        dungeonCoop.choiceId.isEmpty ||
        eventChoices.isEmpty) {
      return;
    }
    final counts = <int, int>{};
    for (final vote in dungeonCoop.votesByPlayer.values) {
      if (vote >= 0 && vote < eventChoices.length) {
        counts[vote] = (counts[vote] ?? 0) + 1;
      }
    }
    final candidates = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.compareTo(b.key);
      });
    final resolvedIndex = candidates.isEmpty
        ? _random.nextInt(eventChoices.length)
        : candidates.first.key;
    final callback = eventChoices[resolvedIndex].onPressed;
    _sendCoop(<String, dynamic>{
      'kind': 'choice_resolve',
      'choiceId': dungeonCoop.choiceId,
      'index': resolvedIndex,
    });
    dungeonCoop.clearVote();
    callback();
    _broadcastDungeonCoopState();
  }

  List<Widget> liveOnlineCompanionActors() {
    if (!isDungeonCoopActive) return const <Widget>[];
    return dungeonCoop.members.values
        .where((member) => member.id != _coopLocalId)
        .take(4)
        .map(
          (member) => battleActor(
            label: member.name,
            color: const Color(0xFF67E8F9),
            kind: 'human_oculian',
            seed: stableSpriteSeed('online:${member.id}'),
            faceRight: true,
            layers: 1,
            hp: member.maxHp,
            maxHp: member.maxHp,
            spriteSize: 48,
            eyeColor: const Color(0xFFB6A0FF),
          ),
        )
        .toList(growable: false);
  }
}
