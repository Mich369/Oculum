// Run only as a separate web build with OculumSaveProfile=live-ui-verification.
// Four browser profiles provide independent application state and Supabase Auth.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: oculumConfiguredSupabaseUrl,
    publishableKey: oculumConfiguredSupabasePublishableKey,
  );
  OculumRealtimeService.supabaseAvailable = true;
  runApp(const _LiveUiApp());
}

class _LiveUiApp extends StatefulWidget {
  const _LiveUiApp();
  @override
  State<_LiveUiApp> createState() => _LiveUiAppState();
}

class _LiveUiAppState extends State<_LiveUiApp> {
  final sheetKey = GlobalKey();
  late final Timer refresh;
  bool configured = false;
  bool busy = false;
  late final int role =
      int.tryParse(Uri.base.queryParameters['role'] ?? '') ?? 0;
  late final String room =
      Uri.base.queryParameters['room'] ?? 'ui-verification-20261026';
  static const names = [
    'Master verifica',
    'Attaccante verifica',
    'Difensore verifica',
    'Aiutante verifica',
  ];
  static const tags = [
    'MasterOcu:3690FD5G',
    'AttaccoOcu:3690FD5G',
    'DifesaOcu:3690FD5G',
    'AiutoOcu:3690FD5G',
  ];
  dynamic get sheet => sheetKey.currentState;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dynamic s = sheet;
      if (s != null) {
        s.tutorialDialogPending = true;
        s.sceltaRuoloSessioneMostrata = true;
      }
    });
    refresh = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    refresh.cancel();
    super.dispose();
  }

  void configure() {
    final dynamic s = sheet;
    if (s == null || configured) return;
    final p = OculumPerformanceProbe(s);
    s.tutorialDialogPending = true;
    s.tutorialCompletato = true;
    s.modalitaMaster = role == 0;
    s.isMasterHost = role == 0;
    s.sonoCoMaster = false;
    s.realtimeAutoReconnectEnabled = false;
    final json = p.snapshot();
    json.addAll({
      'id': tags[role],
      'sheetTag': tags[role],
      'nome': names[role],
      'tipoScheda': 'Personaggio',
      'livello': 10,
      'grado': 1,
      'resilienza': 30,
      'volonta': 20,
      'materia': 10,
      'oculum': 20,
      'currentResilienza': 30,
      'currentVolonta': 20,
      'currentMateria': 10,
      'currentOculum': 20,
      'currentHp': 1000,
      'planarRuntime': <String, dynamic>{},
      'inventario': [],
      'arti': [],
      'skills': [],
      'titoli': [],
      'trattiRazziali': [],
    });
    s.schedePersonaggio
      ..clear()
      ..add(json);
    s.schedaCorrente = 0;
    p.load(json);
    final aura = s.hiddenEyeStats.firstWhere(
      (dynamic stat) => stat.id == 'lettura_aura',
    );
    aura.unlocked = true;
    aura.valore = 20;
    p.invalidateDerivedCaches();
    s.currentHpController.text = '1000';
    s.currentOculumController.text = '20';
    s.tutorialCompletato = true;
    s.tutorialDialogPending = true;
    s.modalitaMaster = role == 0;
    s.isMasterHost = role == 0;
    s.activeCampaignId = room;
    s.realtimeRoomController.text = room;
    s.realtimeNameController.text = names[role];
    s.masterInitiativeGroups.clear();
    s.masterInitiativeTokens
      ..clear()
      ..addAll([
        for (var i = 0; i < 4; i++)
          <String, dynamic>{
            'id': tags[i],
            'sheetTag': tags[i],
            'name': names[i],
            'side': i == 2 ? 'enemy' : 'party',
            'status': i == 1 ? 'active' : 'ready',
            'currentHp': 1000,
            'maxHp': 1000,
            'level': 10,
            'grade': 1,
            'reactionMax': 2,
            'reactionUsed': 0,
            'reactionFastMax': 1,
            'actionUsed': false,
          },
      ]);
    s.selectedMasterInitiativeGroupId = 'encounter_1';
    s.masterInitiativeActiveIndex = 1;
    s.masterInitiativeRound = 2;
    p.ensureEncounters();
    p.recordCurrentEncounter();
    s.masterInitiativeGroups.first['fightStarted'] = true;
    s.masterInitiativeGroups.first['published'] = role == 0;
    s.masterInitiativePublished = role == 0;
    s.datiCaricati = true;
    s.updateOculumHomeUi(() {
      s.paginaCorrente = 17;
    });
    setState(() => configured = true);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Oculum · ${names[role]}',
    theme: oculumBaseTheme,
    home: Column(
      children: [
        Material(
          color: Colors.black,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Text(
                    'PROVA ISOLATA · ${names[role]}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: configured ? null : configure,
                    child: const Text('Prepara profilo'),
                  ),
                  TextButton(
                    onPressed: configured && !busy
                        ? () async {
                            setState(() => busy = true);
                            try {
                              await OculumPerformanceProbe(
                                sheet,
                              ).connectOnline();
                            } finally {
                              if (mounted) setState(() => busy = false);
                            }
                          }
                        : null,
                    child: const Text('Connetti'),
                  ),
                  if (role == 0)
                    TextButton(
                      onPressed: configured
                          ? () =>
                                OculumPerformanceProbe(sheet).publishTurnOrder()
                          : null,
                      child: const Text('Pubblica fight'),
                    ),
                  Expanded(
                    child: Text(
                      configured
                          ? '${sheet.realtimeStatus}'
                          : 'Solo schede sintetiche. Nessun archivio personale.',
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: OculumHomePage(key: sheetKey)),
      ],
    ),
  );
}
