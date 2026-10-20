// Standalone, synthetic desktop playtest. Never used by the shipping entrypoint.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:oculum/services/oculum_save_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const participants = <String, String>{
  'master': '123-PTMASTER',
  'attacker': '124-PTATTACK',
  'defender': '125-PTDEFEND',
};

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (oculumSaveProfile != 'online-playtest' ||
      args.length != 2 ||
      !participants.containsKey(args[0])) {
    throw StateError(
      'Use isolated online-playtest profile, role and room arguments',
    );
  }
  // Each OS process gets its own preferences and guest session in memory.
  SharedPreferences.setMockInitialValues({});
  await Supabase.initialize(
    url: oculumConfiguredSupabaseUrl,
    publishableKey: oculumConfiguredSupabasePublishableKey,
    authOptions: FlutterAuthClientOptions(localStorage: EmptyLocalStorage()),
  );
  OculumRealtimeService.supabaseAvailable = true;
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Playtest(role: args[0], room: args[1]),
    ),
  );
}

class Playtest extends StatefulWidget {
  const Playtest({super.key, required this.role, required this.room});
  final String role;
  final String room;
  @override
  State<Playtest> createState() => _PlaytestState();
}

class _PlaytestState extends State<Playtest> {
  final home = GlobalKey();
  Timer? refresh;
  OculumPerformanceProbe? probe;
  dynamic sheet;
  String error = '';
  bool ready = false;

  @override
  void initState() {
    super.initState();
    refresh = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final dynamic state = home.currentState;
      if (!ready && state != null) {
        state.tutorialDialogPending = true;
        if (state.datiCaricati == true) configure(state);
      }
      setState(() {});
    });
  }

  void configure(dynamic state) {
    sheet = state;
    probe = OculumPerformanceProbe(state);
    state.autosaveTimer?.cancel();
    state.datiCaricati = false;
    state.tutorialCompletato = true;
    state.modalitaMaster = widget.role == 'master';
    state.isMasterHost = widget.role == 'master';
    state.sonoCoMaster = false;
    state.activeCampaignId = widget.room;
    state.nomeController.text = widget.role;
    state.realtimeNameController.text = widget.role;
    state.realtimeRoomController.text = widget.room;
    state.masterAskPublicDiceConfirmation = false;
    state.schedePersonaggio.clear();
    state.schedePersonaggio.add(<String, dynamic>{
      'id': participants[widget.role],
      'sheetTag': participants[widget.role],
      'nome': widget.role,
      'inMasterParty': true,
    });
    state.schedaCorrente = 0;
    state.skills.clear();
    state.arti.clear();
    state.titoli.clear();
    state.inventario.clear();
    state.trattiRazziali.clear();
    state.activeConditions.clear();
    state.activeStructuredEffects.clear();
    for (final controller in [
      state.resilienzaController,
      state.currentResilienzaController,
    ]) {
      controller.text = '20';
    }
    for (final controller in [
      state.volontaController,
      state.currentVolontaController,
      state.materiaController,
      state.currentMateriaController,
      state.oculumController,
      state.currentOculumController,
    ]) {
      controller.text = '10';
    }
    state.currentHpController.text = '200';
    state.scudoOculumMaxController.text = '10';
    state.scudoOculumController.text = '10';
    state.scudoController.text = '20';
    state.hpTempController.text = '20';
    probe!.invalidateDerivedCaches();
    ready = true;
  }

  void turnOrder() {
    probe!.ensureEncounters();
    sheet.masterInitiativeTokens.clear();
    for (final entry in participants.entries) {
      sheet.masterInitiativeTokens.add(<String, dynamic>{
        'id': entry.value,
        'sheetTag': entry.value,
        'name': entry.key,
        'side': 'ally',
        'status': 'ready',
        'initiativeTotal': 20,
      });
    }
    sheet.masterInitiativePublished = true;
    probe!.recordCurrentEncounter();
    probe!.publishTurnOrder();
  }

  Future<void> act(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Text('PROVA ISOLATA · ${widget.role} · ${widget.room}'),
                if (ready)
                  Text(
                    '${sheet.realtimeStatus} · Vita ${probe!.currentHp()} · '
                    'Schede ${sheet.schedePersonaggio.length} · Utenti ${sheet.realtimeUsers.length}',
                  ),
                if (error.isNotEmpty) Text(error),
                Wrap(
                  spacing: 6,
                  children: [
                    TextButton(
                      onPressed: ready ? () => act(probe!.connectOnline) : null,
                      child: const Text('Connetti'),
                    ),
                    TextButton(
                      onPressed: ready
                          ? () => act(probe!.disconnectOnline)
                          : null,
                      child: const Text('Disconnetti'),
                    ),
                    if (widget.role == 'master')
                      TextButton(
                        onPressed: ready ? turnOrder : null,
                        child: const Text('Pubblica turnistica prova'),
                      ),
                    TextButton(
                      onPressed: ready
                          ? () => act(
                              () => probe!.openCombatActionPanel(
                                OculumCombatAbilityRole.attack,
                              ),
                            )
                          : null,
                      child: const Text('Attacco prova'),
                    ),
                    TextButton(
                      onPressed: ready ? () => act(probe!.helpAlly) : null,
                      child: const Text('Aiuta difensore'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(child: OculumHomePage(key: home)),
      ],
    ),
  );
}
