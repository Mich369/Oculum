part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

typedef _FightTeam = ({String id, String name, Color color});

extension _OculumFightTeams on _OculumHomePageState {
  Iterable<Map> _fightTeamRecords(Map<String, dynamic>? group) {
    final records = group?['fightTeams'];
    return records is List ? records.whereType<Map>() : const [];
  }

  List<_FightTeam> _fightTeamsFrom(Map<String, dynamic>? group) {
    final teams = <String, _FightTeam>{
      'ally': (
        id: 'ally',
        name: t('Alleati', 'Allies'),
        color: Colors.greenAccent,
      ),
      'enemy': (
        id: 'enemy',
        name: t('Nemici', 'Enemies'),
        color: Colors.redAccent,
      ),
      'neutral': (
        id: 'neutral',
        name: t('Neutrali', 'Neutrals'),
        color: Colors.orangeAccent,
      ),
    };
    for (final record in _fightTeamRecords(group)) {
      final id = '${record['id'] ?? ''}';
      final name = '${record['name'] ?? ''}'.trim();
      final color = readIntValue(record['colorArgb']);
      if ((teams.containsKey(id) || id.startsWith('team:')) &&
          name.isNotEmpty &&
          color >= 0xFF000000 &&
          color <= 0xFFFFFFFF) {
        teams[id] = (id: id, name: name, color: Color(color));
      }
    }
    return teams.values.toList(growable: false);
  }

  List<_FightTeam> fightTeams(String encounterId) =>
      _fightTeamsFrom(masterParticipantGroup(encounterId));

  bool canManageFightTeams(String encounterId) =>
      mounted &&
      haPermessiMaster &&
      referenceUsesLocalTurnState &&
      encounterId.isNotEmpty &&
      masterParticipantGroup(encounterId) != null;

  Map<String, dynamic> fightTeamTokenFields(
    Map<String, dynamic> group,
    Map token,
  ) {
    final id = combatParticipantTeamId(token);
    final assigned = '${token['fightTeamId'] ?? ''}'.isNotEmpty;
    final hasColor = _fightTeamRecords(
      group,
    ).any((record) => record['id'] == id);
    if (!assigned && !hasColor) return const {};
    final team = _fightTeamsFrom(
      group,
    ).where((value) => value.id == id).firstOrNull;
    if (team == null) return const {};
    return {
      if (assigned) 'fightTeamId': id,
      'teamName': team.name,
      'fightTeamColorArgb': team.color.toARGB32(),
    };
  }

  void refreshFightTeamToken(
    Map<String, dynamic> group,
    Map<String, dynamic> token,
  ) {
    token
      ..remove('fightTeamColorArgb')
      ..remove('teamName')
      ..addAll(fightTeamTokenFields(group, token));
  }

  bool saveFightTeam(
    String encounterId, {
    String? teamId,
    required String name,
    required Color color,
    required String expectedFightId,
  }) {
    if (!canManageFightTeams(encounterId) ||
        masterParticipantFightId(encounterId) != expectedFightId) {
      return false;
    }
    final group = masterParticipantGroup(encounterId)!;
    final label = cleanUiText(name).trim();
    final argb = color.toARGB32();
    if (label.isEmpty || label.length > 40 || (argb >>> 24) != 0xFF) {
      return false;
    }
    final teams = _fightTeamsFrom(group);
    if (teamId != null && !teams.any((team) => team.id == teamId)) return false;
    if (teams.any(
      (team) =>
          team.id != teamId &&
          (team.name.toLowerCase() == label.toLowerCase() ||
              team.color.toARGB32() == argb),
    )) {
      return false;
    }
    final id =
        teamId ??
        'team:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 31)}';
    setState(() {
      group['fightTeams'] = [
        for (final record in _fightTeamRecords(group))
          if (record['id'] != id) record,
        {'id': id, 'name': label, 'colorArgb': argb},
      ];
      for (final token in masterParticipantTokens(encounterId)) {
        refreshFightTeamToken(group, token);
      }
    });
    saveMasterParticipantChange(encounterId);
    return true;
  }

  bool assignFightTeam(
    String encounterId,
    String tokenId,
    String teamId, {
    required String expectedFightId,
  }) {
    if (!canManageFightTeams(encounterId) ||
        masterParticipantFightId(encounterId) != expectedFightId) {
      return false;
    }
    final group = masterParticipantGroup(encounterId)!;
    if (!_fightTeamsFrom(group).any((team) => team.id == teamId)) return false;
    final tokens = masterParticipantTokens(encounterId);
    final token = tokens
        .where((item) => '${item['id'] ?? item['sheetTag']}' == tokenId)
        .firstOrNull;
    if (token == null || masterInitiativeTokenIsTemporary(token)) return false;
    setState(() {
      for (final member in tokens) {
        if (!identical(member, token) && member['sourceTokenId'] != tokenId) {
          continue;
        }
        member['fightTeamId'] = teamId;
        refreshFightTeamToken(group, member);
      }
    });
    saveMasterParticipantChange(encounterId);
    return true;
  }

  Map<String, dynamic> fightTokenAffiliations(Map<String, dynamic> token) {
    final tag = publicInitiativeSourceTag(token);
    final index = localSheetIndexForOculumTag(tag);
    final shared = realtimeSharedSheets.reversed
        .where((record) => oculumSameSheetIdentity(record['sheetId'], tag))
        .firstOrNull?['sheet'];
    final sheet = index >= 0 ? schedePersonaggio[index] : shared;
    if (sheet is! Map) return const {};
    final planar = sheet['planarRuntime'];
    return {
      'fightChaos': planar is Map && planar['identityFateChaos'] == 'Chaos',
      'fightCelestial': oculumCelestialAllegiance(sheet),
    };
  }
}
