import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../game/oculum_lite_coop.dart';
import '../game/oculum_lite_run.dart';
import '../services/oculum_lite_saves.dart';
import '../services/oculum_rl_cloud_config.dart';
import '../services/oculum_save_profile.dart';
import '../widgets/oculum_lite_appearance.dart';
import '../widgets/oculum_lite_arena.dart';
import '../widgets/oculum_lite_creator.dart';
import '../widgets/oculum_lite_ink_finishes.dart';
import 'oculum_lite_coop_page.dart';
import 'oculum_lite_page.dart' show liteHeroLabels;

Future<Supabase>? _onlineGame;

Future<Supabase> _cloud() => _onlineGame ??=
    Supabase.initialize(
      url: const String.fromEnvironment(
        'OculumSupabaseUrl',
        defaultValue: oculumDefaultSupabaseUrl,
      ),
      publishableKey: const String.fromEnvironment(
        'OculumSupabasePublishableKey',
        defaultValue: oculumDefaultSupabasePublishableKey,
      ),
      authOptions: FlutterAuthClientOptions(
        localStorage: SharedPreferencesLocalStorage(
          persistSessionKey: oculumProfiledStorageKey(
            'oculum-rl-online-session',
          ),
        ),
      ),
    ).onError((error, stack) {
      _onlineGame = null;
      Error.throwWithStackTrace(
        error ?? StateError('Connessione non disponibile'),
        stack,
      );
    });

typedef _Seat = ({
  String name,
  LiteHero hero,
  LiteWeapon weapon,
  OculumLiteAppearance? appearance,
  Map<LitePermanentUpgrade, int> upgrades,
  bool ready,
  bool allowGlue,
  bool allowMechanicalChicken,
  LiteRestMemory? memory,
});

class OculumRlRoomPage extends StatefulWidget {
  const OculumRlRoomPage({super.key});

  @override
  State<OculumRlRoomPage> createState() => _OculumRlRoomPageState();
}

class _OculumRlRoomPageState extends State<OculumRlRoomPage> {
  final _code = TextEditingController();
  final _name = TextEditingController(text: 'Viandante');
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _loginPassword = TextEditingController();
  final _seedInput = TextEditingController();
  final _seats = <String, _Seat>{};
  List<Map<String, dynamic>> _pending = [];
  final _random = Random.secure();
  late final _sessionId =
      'rl-${List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  SupabaseClient? _client;
  RealtimeChannel? _channel;
  Timer? _heartbeat;
  Timer? _admission;
  String? _room;
  String? _role;
  String? _masterSession;
  String? _hostAccount;
  String _status = '';
  String _runId = '';
  bool _busy = false;
  bool _connected = false;
  bool _reading = false;
  LiteHero _hero = LiteHero.evasore;
  OculumLiteAppearance _look = const OculumLiteAppearance();
  LiteInkFinish _inkFinish = LiteInkFinish.canonica;
  OculumLiteAppearance get _selectedLook =>
      (_hero == LiteHero.duplicatore
              ? _look
              : oculumLiteDefaultAppearance(_hero))
          .copyWith(inkFinish: _inkFinish);
  LiteWeapon _weapon = LiteWeapon.arco;
  LiteDifficulty _difficulty = LiteDifficulty.medio;
  LiteBiome _biome = LiteBiome.campo;
  bool _observer = false;
  int _seed = 0;
  OculumLiteCoop? _run;
  final _handledMemoryIds = <String>{};
  OculumLiteProgress _progress = const OculumLiteProgress();
  bool _savingUnlocks = false;
  final _failedPets = <LiteCompanion>{};
  int _failedSlimeCredit = 0;
  final _failedUnlocks = <LiteHero>{};

  String? get _account => _client?.auth.currentUser?.id;
  bool get _master => _role == 'master';
  String get _displayName =>
      _name.text.trim().isEmpty ? 'Viandante' : _name.text.trim();

  @override
  void initState() {
    super.initState();
    _seed = _random.nextInt(0x7fffffff);
    _seedInput.text = '$_seed';
    _biome = LiteBiome.offers(_seed).first;
    unawaited(_loadProgress());
  }

  Future<void> _loadProgress() async {
    try {
      final store = await OculumLiteSaveStore.open();
      final progress = await store.readProgressWithSlots();
      if (mounted) setState(() => _progress = progress);
    } on Object {
      // The online lobby remains available with the three starter characters.
    }
  }

  Future<void> _open({required bool host}) async {
    final code = _code.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9_-]{4,32}$').hasMatch(code)) {
      setState(
        () => _status = 'Inserisci un codice stanza da 4 a 32 caratteri.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Apertura della stanza…';
    });
    try {
      final client = (await _cloud()).client;
      _client = client;
      if (_email.text.trim().isNotEmpty && _loginPassword.text.isNotEmpty) {
        await client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _loginPassword.text,
        );
        _loginPassword.clear();
      } else if (client.auth.currentSession == null) {
        await client.auth.signInAnonymously();
      }
      if (!mounted) return;
      final password = _password.text;
      final result = await client
          .rpc(
            password.isEmpty
                ? 'oculum_open_room'
                : 'oculum_open_room_with_password',
            params: {
              'p_code': code,
              'p_name': _displayName,
              'p_as_master': host,
              if (password.isNotEmpty) 'p_password': password,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (result is! Map || result['roomId'] is! String) {
        throw const FormatException('Risposta della stanza non valida.');
      }
      _room = result['roomId'] as String;
      if (result['status'] == 'approved') {
        await _subscribe('${result['role']}');
      } else if (result['status'] == 'pending') {
        setState(() => _status = 'Ingresso richiesto. Attendi il Master.');
        _admission = Timer.periodic(
          const Duration(seconds: 2),
          (_) => _checkAdmission(),
        );
      } else {
        setState(() => _status = 'Ingresso rifiutato.');
      }
    } on Exception {
      if (mounted) {
        setState(
          () =>
              _status = 'Apertura fallita. Controlla rete, codice o password.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkAdmission() async {
    if (_reading || _client == null || _room == null) return;
    _reading = true;
    try {
      final data = await _client!
          .from('oculum_room_members')
          .select('role,status')
          .eq('room_id', _room!)
          .eq('user_id', _account!)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
      if (!mounted || data == null) return;
      if (data['status'] == 'approved') {
        _admission?.cancel();
        await _subscribe('${data['role']}');
      } else if (data['status'] == 'denied') {
        _admission?.cancel();
        setState(() => _status = 'Ingresso rifiutato.');
      }
    } on Exception {
      if (mounted) {
        setState(() => _status = 'In attesa della risposta della stanza.');
      }
    } finally {
      _reading = false;
    }
  }

  Future<void> _presence() async {
    await _client!
        .rpc(
          'oculum_touch_room_session',
          params: {
            'p_room': _room,
            'p_session': _sessionId,
            'p_presence': {'playerName': _displayName},
          },
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<void> _subscribe(String role) async {
    if (!mounted) return;
    _role = role;
    final channel = _client!.channel(
      'oculum_secure_$_room',
      opts: const RealtimeChannelConfig(private: true, ack: true),
    );
    _channel = channel;
    channel.onBroadcast(
      event: 'oculum_rl_live',
      callback: (data) {
        if (mounted && identical(_channel, channel)) {
          _receive(
            data['payload'] is Map<String, dynamic> ? data['payload'] : data,
          );
        }
      },
    );
    channel.subscribe((state, error) {
      if (!mounted || !identical(_channel, channel)) return;
      if (state == RealtimeSubscribeStatus.subscribed) {
        unawaited(_register());
      } else if (state == RealtimeSubscribeStatus.closed ||
          state == RealtimeSubscribeStatus.channelError ||
          state == RealtimeSubscribeStatus.timedOut) {
        setState(() {
          _connected = false;
          _status = 'Connessione alla stanza interrotta.';
        });
      }
    });
  }

  Future<void> _register() async {
    try {
      await _presence();
      if (!mounted) return;
      if (_master) _masterSession = _sessionId;
      setState(() {
        _connected = true;
        _status = 'Stanza ${_code.text.trim().toUpperCase()} aperta.';
      });
      _heartbeat?.cancel();
      var cycle = 0;
      _heartbeat = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_master) unawaited(_checkPending());
        if (cycle++ % 6 == 0) unawaited(_refreshPresence());
      });
      if (_master) {
        await _announce();
        unawaited(_checkPending());
      } else {
        await _send({'kind': 'lobbyHello'});
      }
    } on Exception {
      if (mounted) {
        setState(() => _status = 'Registrazione alla stanza non riuscita.');
      }
    }
  }

  Future<void> _refreshPresence() async {
    try {
      await _presence();
    } on Exception {
      if (mounted) {
        setState(() => _status = 'Connessione in attesa di ripresa.');
      }
    }
  }

  Future<void> _checkPending() async {
    if (_reading || !_master) return;
    _reading = true;
    try {
      final rows = await _client!
          .from('oculum_room_members')
          .select('user_id,display_name')
          .eq('room_id', _room!)
          .eq('status', 'pending')
          .timeout(const Duration(seconds: 8));
      if (mounted) setState(() => _pending = rows);
    } on Exception {
      // Keep the confirmed roster if polling for pending requests times out.
    } finally {
      _reading = false;
    }
  }

  Future<void> _decide(String uid, bool allow) async {
    try {
      await _client!
          .rpc(
            'oculum_decide_room_member',
            params: {
              'p_room': _room,
              'p_user': uid,
              'p_allow': allow,
              'p_role': 'player',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() => _pending.removeWhere((row) => row['user_id'] == uid));
      }
    } on Exception {
      if (mounted) {
        setState(() => _status = 'Impossibile confermare questa richiesta.');
      }
    }
  }

  Future<bool> _send(Map<String, dynamic> fields) async {
    if (!_connected || !mounted || _room == null) return false;
    try {
      return await _client!
              .rpc(
                'oculum_rl_live',
                params: {
                  'p_room': _room,
                  'p_session': _sessionId,
                  'p_packet': fields,
                },
              )
              .timeout(const Duration(seconds: 3)) ==
          true;
    } on Exception {
      return false;
    }
  }

  static Map<String, dynamic> _seatData(_Seat seat) => {
    'name': seat.name,
    'hero': seat.hero.name,
    'weapon': seat.weapon.name,
    'ready': seat.ready,
    if (seat.allowGlue) 'allowGlue': true,
    if (seat.allowMechanicalChicken) 'allowMechanicalChicken': true,
    if (seat.memory case final memory?) 'restMemory': memory.frame,
    if (seat.upgrades.isNotEmpty)
      'upgrades': LitePermanentUpgrade.encode(seat.upgrades),
    if (seat.appearance case final look?) 'look': look.toJson(),
  };
  static _Seat? _parseSeat(Object? value) {
    if (value is! Map || value['name'] is! String || value['ready'] is! bool) {
      return null;
    }
    final name = value['name'] as String;
    if (name.isEmpty || name.length > 32) return null;
    final hero = LiteHero.values
        .where((item) => item.name == value['hero'])
        .firstOrNull;
    final selectedWeapon = LiteWeapon.starters
        .where((item) => item.name == value['weapon'])
        .firstOrNull;
    if (hero == null) return null;
    if (selectedWeapon == null && value['weapon'] != hero.fixedWeapon?.name) {
      return null;
    }
    return (
      name: name,
      hero: hero,
      weapon: hero.startingWeapon(selectedWeapon ?? LiteWeapon.arco),
      appearance: value['look'] is Map
          ? OculumLiteAppearance.fromJson(value['look'])
          : null,
      ready: value['ready'] as bool,
      allowGlue: value['allowGlue'] == true,
      allowMechanicalChicken: value['allowMechanicalChicken'] == true,
      memory: LiteRestMemory.read(value['restMemory']),
      upgrades: LitePermanentUpgrade.read(value['upgrades']),
    );
  }

  Future<bool> _announce() => _send({
    'kind': 'lobbySnapshot',
    'runId': _runId,
    'seed': _seed,
    'difficulty': _difficulty.name,
    'biome': _biome.name,
    'seats': {
      for (final entry in _seats.entries) entry.key: _seatData(entry.value),
    },
  });

  void _receive(Map<String, dynamic> data) {
    final uid = data['account'], from = data['session'], role = data['role'];
    if (uid is! String || from is! String || from == _sessionId) return;
    final kind = data['kind'];
    if (kind is! String) return;
    if (kind.startsWith('play')) {
      _run?.receive(
        data,
        account: uid,
        sessionId: from,
        verifiedMaster: role == 'master' && from == _masterSession,
      );
      return;
    }
    if (_master && kind == 'lobbyHello') {
      unawaited(_announce());
    } else if (_master && kind == 'lobbySeat' && _runId.isEmpty) {
      final seat = _parseSeat(data['seat']);
      if (data['observer'] == true) {
        setState(() => _seats.remove(uid));
      } else if (seat != null &&
          (_seats.containsKey(uid) || _seats.length < LiteRun.maxCoopPlayers)) {
        setState(() => _seats[uid] = seat);
      }
      unawaited(_announce());
    } else if (!_master && role == 'master' && kind == 'lobbySnapshot') {
      if (_masterSession != null && _masterSession != from) return;
      final seed = data['seed'];
      final runId = data['runId'];
      final seats = data['seats'];
      if (seed is! int ||
          runId is! String ||
          seats is! Map ||
          seats.length > LiteRun.maxCoopPlayers ||
          runId.length > 100) {
        return;
      }
      setState(() {
        _masterSession = from;
        _hostAccount = uid;
        _seed = seed;
        _difficulty =
            LiteDifficulty.values
                .where((item) => item.name == data['difficulty'])
                .firstOrNull ??
            _difficulty;
        _biome =
            LiteBiome.values
                .where((item) => item.name == data['biome'])
                .firstOrNull ??
            _biome;
        if (_runId != runId) {
          _run?.stop();
          _run = null;
        }
        _runId = runId;
        _seats.clear();
        for (final entry in seats.entries) {
          final seat = _parseSeat(entry.value);
          if (entry.key is String && seat != null) {
            _seats[entry.key as String] = seat;
          }
        }
      });
    }
  }

  Future<void> _ready() async {
    final uid = _account;
    if (uid == null) return;
    LiteRestMemory? memory;
    try {
      final store = await OculumLiteSaveStore.open();
      memory = await store.readRestMemory();
    } on Object {
      if (mounted)
        setState(
          () => _status = 'Impossibile leggere il ricordo della Veggente.',
        );
    }
    if (!mounted || _account != uid || _runId.isNotEmpty) return;
    final seat = (
      name: _displayName,
      hero: _hero,
      weapon: _hero.startingWeapon(_weapon),
      appearance:
          _hero == LiteHero.duplicatore || _inkFinish != LiteInkFinish.canonica
          ? _selectedLook
          : null,
      upgrades: _progress.upgrades,
      allowGlue: _progress.discoveredPets.contains(LiteCompanion.goblinColla),
      allowMechanicalChicken: _progress.canPlay(LiteHero.pollo),
      memory: memory,
      ready: _seats[uid]?.ready != true,
    );
    if (_master) {
      setState(() => _seats[uid] = seat);
      await _announce();
    } else if (!await _send({
          'kind': 'lobbySeat',
          'seat': _seatData(seat),
          'observer': _observer,
        }) &&
        mounted) {
      setState(() => _status = 'Impossibile confermare il personaggio.');
    }
  }

  Future<void> _editAppearance() async {
    final selected = await editOculumLiteAppearance(
      context,
      appearance: _look,
      weapon: _weapon,
      name: _displayName,
    );
    if (!mounted || selected == null || _runId.isNotEmpty) return;
    _name.text = selected.name;
    setState(() => _look = selected.appearance);
  }

  Future<void> _start() async {
    final uid = _account;
    final mine = _seats[uid];
    if (!_master ||
        uid == null ||
        mine == null ||
        _seats.length < 2 ||
        _seats.values.any((seat) => !seat.ready)) {
      return;
    }
    _runId = '${_sessionId}_${_random.nextInt(0x7fffffff)}';
    final world = LiteRun(
      seed: _seed,
      progressId: _runId,
      difficulty: _difficulty,
      biome: _biome,
      hero: mine.hero,
      weapon: mine.weapon,
      upgrades: mine.upgrades,
      allowGlue: mine.allowGlue,
      allowMechanicalChicken: mine.allowMechanicalChicken,
      playerCount: _seats.length,
    );
    if (mine.memory case final memory?) world.carryRestMemory(memory);
    for (final entry in _seats.entries) {
      if (entry.key == uid) continue;
      final seat = entry.value;
      world.addCoopFighter(
        entry.key,
        seat.name,
        seat.hero,
        seat.weapon,
        upgrades: seat.upgrades,
        allowGlue: seat.allowGlue,
        allowMechanicalChicken: seat.allowMechanicalChicken,
      );
      if (seat.memory case final memory?) {
        final fighter = world.coopFighter(entry.key);
        if (fighter != null) world.carryRestMemory(memory, fighter: fighter);
      }
    }
    _run = OculumLiteCoop(
      runId: _runId,
      localAccount: uid,
      authority: world,
      send: _send,
    );
    if (!await _announce() || !mounted) {
      _run?.dispose();
      _run = null;
      _runId = '';
      if (mounted) setState(() => _status = 'Avvio online fallito. Riprova.');
      return;
    }
    setState(() {});
    _enterRun();
  }

  void _enterRun() {
    final uid = _account;
    if (uid == null || _runId.isEmpty) return;
    final play = _run ??= OculumLiteCoop(
      runId: _runId,
      localAccount: uid,
      send: _send,
    );
    play
      ..removeListener(_recordRunUnlocks)
      ..addListener(_recordRunUnlocks);
    _failedUnlocks.clear();
    final hostAccount = _master ? uid : _hostAccount;
    final appearances = {
      for (final entry in _seats.entries) entry.key: ?entry.value.appearance,
    };
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => OculumLiteCoopPage(
            session: play,
            hostAppearance: appearances[hostAccount],
            guestAppearances: appearances,
          ),
        ),
      ),
    );
  }

  void _recordRunUnlocks() {
    final play = _run;
    final run = play?.run;
    if (!mounted || _savingUnlocks || play == null || run == null) return;
    final played = play.host ? run.hero : play.localFighter?.hero;
    if (played == null) return;
    final kit = play.host ? run.supply : play.localFighter!.supply;
    final memory = kit.promised;
    final spent = kit.carriedId;
    if (spent != null && _handledMemoryIds.add('spent-$spent')) {
      unawaited(_recordRestMemory(spent, null));
    }
    if (memory != null && _handledMemoryIds.add(memory.id)) {
      unawaited(_recordRestMemory(memory.id, memory));
    }
    final heroes = run.unlockedHeroesFor(
      played,
      guestAccount: play.host ? null : play.localAccount,
    );
    final pets = run.discoveredPets;
    final pendingSlime =
        _progress.slimeKills < 10 &&
        run.slimeKills > (_progress.slimeCounters[run.slimeCreditId] ?? 0) &&
        run.slimeKills > _failedSlimeCredit;
    if (heroes.every(
          (hero) => _progress.canPlay(hero) || _failedUnlocks.contains(hero),
        ) &&
        !pendingSlime &&
        pets.every(
          (pet) =>
              _progress.discoveredPets.contains(pet) ||
              _failedPets.contains(pet),
        ))
      return;
    _savingUnlocks = true;
    unawaited(_saveRunUnlocks(heroes, pets, run.slimeCreditId, run.slimeKills));
  }

  Future<void> _recordRestMemory(String id, LiteRestMemory? memory) async {
    try {
      final store = await OculumLiteSaveStore.open();
      if (memory == null) {
        await store.spendRestMemory(id);
      } else {
        await store.saveRestMemory(memory);
      }
    } on Object {
      if (mounted)
        setState(() => _status = 'Salvataggio del ricordo non riuscito.');
    }
  }

  Future<void> _saveRunUnlocks(
    Set<LiteHero> heroes,
    Set<LiteCompanion> pets,
    String slimeId,
    int slimeKills,
  ) async {
    try {
      final store = await OculumLiteSaveStore.open();
      final current = await store.readProgressWithSlots();
      final progress = current.record(
        current.bestClearedFloor,
        heroes,
        pets: pets,
        slimeCounters: {slimeId: slimeKills},
      );
      await store.writeProgress(progress);
      if (mounted) setState(() => _progress = progress);
    } on Object {
      _failedUnlocks.addAll(heroes);
      _failedPets.addAll(pets);
      _failedSlimeCredit = slimeKills;
      if (mounted) {
        setState(() => _status = 'Impossibile salvare gli eroi sbloccati.');
      }
      return;
    } finally {
      _savingUnlocks = false;
    }
  }

  @override
  void dispose() {
    _admission?.cancel();
    _heartbeat?.cancel();
    _run?.dispose();
    final channel = _channel;
    if (channel != null) unawaited(_client?.removeChannel(channel));
    for (final controller in [
      _code,
      _name,
      _password,
      _email,
      _loginPassword,
      _seedInput,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Oculum RL · Stanza online')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!_connected) ...[
                TextField(
                  controller: _code,
                  decoration: const InputDecoration(labelText: 'Codice stanza'),
                ),
                TextField(
                  controller: _name,
                  maxLength: 32,
                  decoration: const InputDecoration(
                    labelText: 'Nome in partita',
                  ),
                ),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password stanza (facoltativa)',
                  ),
                ),
                ExpansionTile(
                  title: const Text('Usa un account Oculum esistente'),
                  children: [
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: _loginPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password account',
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    FilledButton(
                      onPressed: _busy ? null : () => _open(host: true),
                      child: const Text('Ospita'),
                    ),
                    OutlinedButton(
                      onPressed: _busy ? null : () => _open(host: false),
                      child: const Text('Entra'),
                    ),
                  ],
                ),
              ] else ...[
                Text('${_seats.length}/${LiteRun.maxCoopPlayers} combattenti'),
                for (final row in _pending)
                  ListTile(
                    title: Text('${row['display_name']} chiede di entrare'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Approva',
                          icon: const Icon(Icons.check),
                          onPressed: () => _decide('${row['user_id']}', true),
                        ),
                        IconButton(
                          tooltip: 'Rifiuta',
                          icon: const Icon(Icons.close),
                          onPressed: () => _decide('${row['user_id']}', false),
                        ),
                      ],
                    ),
                  ),
                for (final seat in _seats.values)
                  ListTile(
                    title: Text(seat.name),
                    subtitle: Text(seat.weapon.label),
                    trailing: Text(seat.ready ? 'Pronto' : 'In attesa'),
                  ),
                if (_runId.isEmpty) ...[
                  if (_master) ...[
                    TextField(
                      controller: _seedInput,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Seed'),
                      onChanged: (text) {
                        final seed = int.tryParse(text);
                        if (seed == null) return;
                        setState(() {
                          _seed = seed;
                          final offers = LiteBiome.offers(seed);
                          if (!offers.contains(_biome)) _biome = offers.first;
                        });
                        unawaited(_announce());
                      },
                    ),
                    DropdownButtonFormField<LiteDifficulty>(
                      initialValue: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficoltà',
                      ),
                      items: [
                        for (final item in LiteDifficulty.values)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                      ],
                      onChanged: (item) {
                        if (item != null) setState(() => _difficulty = item);
                        unawaited(_announce());
                      },
                    ),
                    DropdownButtonFormField<LiteBiome>(
                      key: ValueKey(_seed),
                      initialValue: _biome,
                      decoration: const InputDecoration(
                        labelText: 'Zona iniziale',
                      ),
                      items: [
                        for (final item in LiteBiome.offers(_seed))
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                      ],
                      onChanged: (item) {
                        if (item != null) setState(() => _biome = item);
                        unawaited(_announce());
                      },
                    ),
                  ],
                  if (!_master)
                    SwitchListTile(
                      title: const Text('Osserva senza combattere'),
                      value: _observer,
                      onChanged: (value) => setState(() => _observer = value),
                    ),
                  DropdownButtonFormField<LiteHero>(
                    initialValue: _hero,
                    decoration: const InputDecoration(labelText: 'Personaggio'),
                    items: [
                      for (final hero in LiteHero.values.where(
                        _progress.canPlay,
                      ))
                        DropdownMenuItem(
                          value: hero,
                          child: Text(liteHeroLabels[hero]!),
                        ),
                    ],
                    onChanged: (item) {
                      if (item != null) setState(() => _hero = item);
                    },
                  ),
                  if (_hero.fixedWeapon case final fixed?)
                    ListTile(
                      title: Text(fixed.label),
                      subtitle: const Text('Arma iniziale'),
                    )
                  else
                    DropdownButtonFormField<LiteWeapon>(
                      initialValue: _weapon,
                      decoration: const InputDecoration(
                        labelText: 'Arma iniziale',
                      ),
                      items: [
                        for (final item in LiteWeapon.starters)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                      ],
                      onChanged: (item) {
                        if (item != null) setState(() => _weapon = item);
                      },
                    ),
                  if (_hero == LiteHero.duplicatore)
                    OutlinedButton.icon(
                      onPressed: _seats[_account]?.ready == true
                          ? null
                          : _editAppearance,
                      icon: const Icon(Icons.brush_outlined),
                      label: const Text('Personalizza in 2D'),
                    ),
                  if (!_observer) ...[
                    OculumLiteInkFinishPicker(
                      selected: _inkFinish,
                      onChanged: _seats[_account]?.ready == true
                          ? null
                          : (finish) => setState(() => _inkFinish = finish),
                    ),
                    SizedBox(
                      height: 112,
                      child: OculumLiteHeroPreview(
                        hero: _hero,
                        weapon: _hero.startingWeapon(_weapon),
                        appearance: _selectedLook,
                      ),
                    ),
                  ],
                  OutlinedButton(
                    onPressed: _ready,
                    child: Text(
                      _observer
                          ? 'Conferma osservatore'
                          : _seats[_account]?.ready == true
                          ? 'Annulla Pronto'
                          : 'Pronto',
                    ),
                  ),
                  if (_master)
                    FilledButton(
                      onPressed:
                          _seats[_account]?.ready == true &&
                              _seats.length >= 2 &&
                              _seats.values.every((seat) => seat.ready)
                          ? _start
                          : null,
                      child: const Text('Avvia partita insieme'),
                    ),
                ] else
                  FilledButton(
                    onPressed: _enterRun,
                    child: const Text('Entra nella partita'),
                  ),
              ],
              if (_status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_status),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
