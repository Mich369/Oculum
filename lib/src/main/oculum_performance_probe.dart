part of '../../main.dart';

/// Exercises production paths against an isolated fixture in automated tests.
/// No listeners, storage, or work are installed unless a test creates a probe.
@visibleForTesting
class OculumPerformanceProbe {
  OculumPerformanceProbe(State state) : _state = state as _OculumHomePageState;
  final _OculumHomePageState _state;

  void openDice() => _state.openReferenceDetail(
    'Sessione Dadi',
    'sheet_dice',
    _state.sheetDiceRollPanel,
  );
  void openResistances() => _state.openResistanceDetails();
  void openSubtraits() => _state.openReferenceDetail(
    'Sottotratti',
    'sheet_subtraits',
    _state.referenceSubtraitsPanel,
  );
  Widget resistancePanel() => _state.resistanceDetailsPanel();
  Widget dicePanel() => _state.sheetDiceRollPanel(dense: true);
  Widget subtraitsPanel() => _state.referenceSubtraitsPanel();
  void resetEncounter() => _state.resetMasterInitiativeRound();
  void reportedTurn(int value) =>
      _state.setPlayerReportedTurn(value, broadcast: false);
  void removeParticipant(int index) =>
      _state.removeMasterInitiativeTokenAt(index);
  void damage(int amount) => _state.applicaDannoSubito(dannoEsplicito: amount);
  String activateForce(String id) {
    _state.statoForzaAttivo = id;
    return _state.applicaEffettoImmediatoStatoForza(id);
  }

  void endForce() =>
      _state.terminaStatoForzaAttivo(applicaEsitoEsplosione: false);
  void loseResilienceBuff(int amount) =>
      _state.rimarginaHpDaAumentoResilienza(-amount);
  int currentHp() => _state.hpCorrenti();
  Map<String, int> coreStats() => {
    'resilienza': _state.resilienzaTotale(),
    'volonta': _state.volontaTotale(),
    'materia': _state.materiaTotale(),
    'oculum': _state.oculumTotale(),
  };
  Map<String, dynamic> snapshot() => _state.statoCorrenteJson();
  Future<OculumHumanoidChoice?> humanoidCreationDialog() =>
      _state.askHumanoidRole(
        4,
        initialName: 'NPC',
        initialLevel: 0,
        budgetAtLevel: (level) => 4 + level * 4,
      );
  Future<void> useOpen(int index) => _state.usaOpenArt(index);
  Future<void> useOpenSkill(int index) => _state.usaSkillOpenMostro(index);
  void enterEncounter(String id) => _state.enterLocalReferenceEncounter(id);
  void ensureEncounters() => _state.ensureMasterInitiativeGroups();
  void selectEncounter(String id) => _state.selectMasterInitiativeGroup(id);
  Map<String, dynamic> initiativeSnapshot() =>
      _state.buildRealtimeInitiativeSnapshot();
  void receiveInitiative(Map<String, dynamic> payload) =>
      _state.receiveRealtimeInitiativeSnapshot(payload);
  int attackBonus() => _state.bonusAttaccoRapido();
  void selectArt(int index) => _state.selectIncorporatedArt(_state.arti[index]);
  void advanceArtTurn() => _state.advanceArtSwitchTurn();
  void hitDuringArtAwakening() => _state.interruptArtAwakening();
  Map<String, int> artBonuses() => {
    for (final key in ['resilienza', 'volonta', 'materia', 'oculum'])
      key: _state.artQuickBonus(key),
  };
  String artCostResource(int index) => _state.effectiveArtCostResource(
    _state.arti[index],
    _state.arti[index].skills.first,
    1,
  );
  int spendArtResource(String resource, int amount) =>
      _state.spendArtSkillCostResource(resource, amount);
  int attackVc() => _state.vc();
  int levelGradeBonus() => _state.bonusLivelloGrado();
  int defenseCm() => _state.cm();
  int hpMultiplier() => _state.moltiplicatoreHp();
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
  void activateInitiative(int index) =>
      _state.setMasterInitiativeActiveIndex(index);
  void normalizeInitiative() => _state.normalizeMasterInitiativeTokens();
  void showTutorial() => _state.mostraTutorial();
  void sortInitiative() =>
      _state.sortMasterInitiativeTokens(forceInitiative: true);
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
