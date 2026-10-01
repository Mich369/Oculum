part of '../../main.dart';

/// Exercises production paths against an isolated fixture in automated tests.
/// No listeners, storage, or work are installed unless a test creates a probe.
@visibleForTesting
class OculumPerformanceProbe {
  OculumPerformanceProbe(State state) : _state = state as _OculumHomePageState;
  final _OculumHomePageState _state;

  Map<String, dynamic> snapshot() => _state.statoCorrenteJson();
  int attackBonus() => _state.bonusAttaccoRapido();
  int attackVc() => _state.vc();
  int outgoingDamage() => _state.dannoTotale();
  String damageFormula() => _state.formulaDannoDettagliata();
  int maximumHp() => _state.maxHp();
  Map<String, num> formulaContext() => _state.formulaValueContext();
  InventoryItem merchantItem(
    Map<String, dynamic> offer, {
    String titleType = '',
  }) => _state.merchantItemFromOffer(offer, titleType: titleType);
  int shieldBonus(InventoryItem item) => _state.itemShieldBonus(item);
  Future<void> useMerchantItem(InventoryItem item) =>
      _state.useMerchantConsumable(item);
  void load(Map<String, dynamic> sheet) => _state.caricaStatoDaJson(sheet);
  Future<void> reloadSave() => _state.caricaDati();
  void saveSheet() => _state.salvaSchedaCorrenteInMemoria();
  Future<void> save() => _state.salvaDatiSoloLocale();
  Future<String?> savedRaw() async =>
      _state._readSaveBlob(await _state._prefs(), _OculumHomePageState.saveKey);
  Future<bool> writeBlob(String key, String value) async =>
      _state._writeSaveBlob(await _state._prefs(), key, value);
  Future<String?> readBlob(String key) async =>
      _state._readSaveBlob(await _state._prefs(), key);
  Widget storyPage() => _state.backgroundAndSkillsPageEfficient();
  void hp(int index) => _state.applyMasterEnemyQuickHpAction(index, damage: 1);
  void turn() => _state.nextMasterInitiativeTurn();
  void longRest() => _state.riposoLungo();
  void recoverLongRestStats() => _state.ripristinaStatsRiposoLungo();
  void recoverShortRestStats() => _state.recuperaStatsAttualiConRiposoBreve();
  int resourceMaximum(String key) =>
      _state.currentStatNaturalControllerMax(key);
  int resourceCurrent(String key) =>
      readIntValue(_state.currentStatController(key).text);
  void setResourceCurrent(String key, int value) =>
      _state.currentStatController(key).text = '$value';
  int recoverOculum(int value) => _state.addOculum(value, scheduleSave: false);
  void shortRest() => _state.riposoBreve();
  String ownerTag() => _state.sheetTagAt(_state.schedaCorrente);
  Widget fallenEyesPage() => _state.fallenEyesPage();
  Widget diaryEntryTile(int index) => _state.storyDiaryDatabaseTile(index);
  Map<String, int> titleBonuses(OculumTitle title) =>
      _state.titleQuickBonuses(title);
  Future<Uint8List> oculusFilledPdf() => _state.buildOculusFilledSheetPdf();
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
