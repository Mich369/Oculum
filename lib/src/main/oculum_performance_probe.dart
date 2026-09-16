part of '../../main.dart';

/// Exercises production paths against an isolated fixture in automated tests.
/// No listeners, storage, or work are installed unless a test creates a probe.
@visibleForTesting
class OculumPerformanceProbe {
  OculumPerformanceProbe(State state) : _state = state as _OculumHomePageState;
  final _OculumHomePageState _state;

  Map<String, dynamic> snapshot() => _state.statoCorrenteJson();
  void load(Map<String, dynamic> sheet) => _state.caricaStatoDaJson(sheet);
  void saveSheet() => _state.salvaSchedaCorrenteInMemoria();
  Future<void> save() => _state.salvaDatiSoloLocale();
  void hp(int index) => _state.applyMasterEnemyQuickHpAction(index, damage: 1);
  void turn() => _state.nextMasterInitiativeTurn();
  void longRest() => _state.riposoLungo();
  void shortRest() => _state.riposoBreve();
  String ownerTag() => _state.sheetTagAt(_state.schedaCorrente);
  Widget fallenEyesPage() => _state.fallenEyesPage();
  MonsterBookEntry? lookup(String id) => monsterBookEntryById(id);
  void undo() => _state.annullaUltimaModifica();
  void redo() => _state.ripristinaModificaAnnullata();
  Widget hpConditionTile() => _state.quickStatTile(
    label: 'HP',
    value: '${_state.hpCorrenti()}/${_state.maxHp()}',
    icon: Icons.favorite,
    color: Colors.red,
  );
  void cancelPendingSave() {
    _state.autosaveTimer?.cancel();
    _state.inputUiRefreshTimer?.cancel();
  }
}
