part of '../../main.dart';

/// Exercises production paths against an isolated fixture in automated tests.
/// No listeners, storage, or work are installed unless a test creates a probe.
@visibleForTesting
class OculumPerformanceProbe {
  OculumPerformanceProbe(State state) : _state = state as _OculumHomePageState;
  final _OculumHomePageState _state;

  String currentTag() => _state.sheetTagAt(_state.schedaCorrente);
  String get permissionCampaignId => _state.permissionCampaignId;
  bool partyKnowsMonsterName(String id) => _state.monsterBookPartyKnowsName(id);
  List<Map<String, dynamic>> monsterBookDiscoverySnapshotEntries() =>
      _state.monsterBookPartyDiscoverySnapshotEntries();
  void receiveMonsterBookDiscoverySnapshot(Map<String, dynamic> payload) =>
      _state.receiveMonsterBookPartyDiscoverySnapshot(payload);
  Future<bool> utilitySpend(String resource) =>
      _state.requestUtilitySpend(resource);
  Future<bool> spendCombatRoll() => _state.spendCombatRollResource();
  Map<String, dynamic> turnResourceTestPacket(String id) {
    final tag = currentTag();
    final packet = <String, dynamic>{
      'id': id,
      'kind': 'help',
      'helpMode': 'turn_resource',
      'encounterId': _state.onlineCombatEncounterId,
      'sourceTag': tag,
      'targetTag': tag,
      'sourceName': _state.realtimeDisplayName(),
      'helpBonus': 0,
    };
    _state.attachPendingCombatTurnResources(packet);
    return _state.permissionEnvelope(packet);
  }

  Map<String, int> itemBonuses(InventoryItem item) =>
      _state.itemQuickBonuses(item);
  bool canEquip(InventoryItem item) => _state.canEquipInventoryItem(item);
  void addCondition(String type, {int stage = 1}) =>
      _state.applyCondition(type, stage: stage);
  int willTotal() => _state.volontaTotale();
  int veilSubtraitBonus() => _state.conditionSubtraitBonus('velo');
  int herbalBonus(String stat) => _state.merchantHerbalStatBonus(stat);
  int emblemBonus({bool subtrait = false}) =>
      _state.summoningEmblemBonus('resilienza', subtrait: subtrait);
  void expireEmblems(String encounterId) =>
      _state.expireSummoningEmblems(encounterId);
  void useTitleOpen(OculumTitle title) => _state.usaOpen(title);
  Widget masterCatalog() => _state.masterItemGiftPanel(initiallyExpanded: true);
  List<InventoryItem> masterCatalogItems() => _state._masterGiftCatalog();
  void advanceHerbs(String trigger) => _state.advanceSmokingHerbs(trigger);
  int difficultyRollModifier() => _state.modificatoreDifficoltaTiro();
  void applyHealing(int amount) =>
      _state.applyStructuredHealing('vita', amount);
  Map<String, int> willParts() => {
    'current': _state.currentVolonta(),
    'runtime': _state.runtimeCurrentStatBonus('volonta'),
    'food': _state.nourishmentStatBonus('volonta', _state.currentVolonta()),
    'flat': _state.conditionFlatModifier(OculumConditionTarget.volonta),
  };
  void encounterRewards(List<Map<String, dynamic>> rewards) =>
      _state.receiveEncounterRewards(rewards);
  bool dustExperience(String subtraitId, int die) =>
      _state.useAscensionDustForExperience(subtraitId, die: die);
  List<String> highestDustSubtraits() =>
      _state.dustExperienceHighestSubtraits().map((stat) => stat.id).toList();
  void masterRollRequests(Map<String, dynamic> group) =>
      _state.receiveMasterRollRequests(group);
  void shopType(String type) => _state.selectMerchantShop(type);
  Future<void> buyShopOffer(Map<String, dynamic> offer) =>
      _state.buyMerchantOffer(offer);
  int get dustPrice => _state.merchantDustPrice;
  int shopCost(Map<String, dynamic> offer) => _state.merchantOfferCost(offer);
  List<Map<String, dynamic>> shopOffers() => _state.recommendedMerchantStock();
  List<OculumColorPreset> get themes => List.unmodifiable(_state.colorPresets);
  void applyTheme(String id) => _state.applicaColorPreset(id);
  Future<void> useCharacterSkill(CharacterSkill skill) =>
      _state.usaFormaSkill(skill, _state.skills.indexOf(skill), 0);
  Future<void> useArtSkill(
    int artIndex,
    int skillIndex,
    int form, {
    bool again = false,
  }) => _state.impostaLivelloSkillArt(
    artIndex: artIndex,
    skillIndex: skillIndex,
    nuovoLivello: form,
    riutilizza: again,
  );
  Future<OculumStructuredEffect?> editEffect(OculumStructuredEffect effect) =>
      _state.showStructuredEffectDialog(initial: effect);
  bool tickEffects(String unit) => _state.tickActiveStructuredEffects(unit);
  List<String> applyEffects(
    Iterable<OculumStructuredEffect> effects, {
    String source = 'Test effetto',
    Map<String, num> spentResources = const {},
  }) => _state.applyStructuredEffectsOnActivation(
    effects,
    source: source,
    spentResources: spentResources,
  );
  int movement() => _state.movimento();
  int maximumHp() => _state.maxHp();
  int maximumTemporaryHp() => _state.thresholdTemporaryHpLimit();
  String difficulty() => _state.normalizedCampaignDifficulty();
  int damageTotal() => _state.dannoTotale();
  bool consumeNextAttackEffects() =>
      _state.consumeNextAttackStructuredEffects();
  Future<void> rollSpecial(String name, int bonus) =>
      _state.tiraValoreSpeciale(name, bonus);
  List<OculumConditionInstance> get conditions =>
      List.unmodifiable(_state.activeConditions);
  int subtraitValue(String id) => _state.hiddenEyeTotal(
    _state.hiddenEyeStats.firstWhere((stat) => stat.id == id),
  );
  Future<void> spawnBookCreature(String id) =>
      _state.showMonsterBookQuickSpawnDialog(monsterById(id)!);
  List<OculumPawnGuardian> get pawns => List.unmodifiable(_state.pawnGuardians);
  int interceptPawnDamage(String tag, int amount) =>
      _state.redirectPawnHpDamage(tag, amount);
  Future<void> advancePawn(String id, int turn) =>
      _state.advancePawnTurn(id, turn);

  void openDice() => _state.openReferenceDetail(
    'Sessione Dadi',
    'sheet_dice',
    _state.sheetDiceRollPanel,
  );
  void openResistances() => _state.openResistanceDetails();
  Future<void> showCreateFallenEye({Map<String, dynamic>? editingEye}) =>
      _state._showCreateFallenEyeDialog(editingEye: editingEye);
  Widget skillsPage() => _state.skillsPage();
  Widget contextActionAnchor({
    required Widget child,
    required VoidCallback activate,
    required VoidCallback roll,
  }) => _state.quickContextMenuAnchor(
    label: 'Volontà',
    child: child,
    onActivate: activate,
    onRoll: roll,
    conditionTarget: OculumConditionTarget.volonta,
  );
  void openSubtraits() => _state.openReferenceDetail(
    'Sottotratti',
    'sheet_subtraits',
    _state.referenceSubtraitsPanel,
  );
  Future<void> rollSubtrait(String id) => _state.tiraSottotrattoOcchio(
    _state.hiddenEyeStats.firstWhere((stat) => stat.id == id),
  );
  Widget resistancePanel() => _state.resistanceDetailsPanel();
  Future<void> useScroll(InventoryItem item) =>
      _state.useMerchantConsumable(item);
  int defense() => _state.difesa();
  void refillStatsAndHealth() => _state.refullVita();
  bool activateNurseBuff() => _state.activateHeroicNurseBuffForCurrentBattle();
  List<Map<String, dynamic>> structuredEffects() =>
      List<Map<String, dynamic>>.from(
        _state.activeStructuredEffects.map(
          (effect) => Map<String, dynamic>.from(effect),
        ),
      );
  String incomingDamagePreset(String element) =>
      _state.configuredIncomingDamagePreset(element);
  double corruptionResistance() => _state.currentCorruptionResistancePercent();
  double corruptionResistanceForSheet(Map<String, dynamic> sheet) =>
      _state.oculumCorruptionResistanceInSheet(sheet);
  void queueCorruption({
    required String targetTag,
    required int sourceLevel,
    required int sourceTotal,
    String requestId = 'test-corruption',
  }) => _state.queueCorruptionApplication(
    targetTag: targetTag,
    scrollGrade: 12,
    sourceTag: 'corruption-source',
    sourceName: 'Fonte Corruzione',
    sourceTotal: sourceTotal,
    sourceLevel: sourceLevel,
    requestId: requestId,
  );
  Widget corruptionRequests() => _state.onlineCombatRequestsPanel();
  Future<void> resistCorruption(Map<String, dynamic> request, String choice) =>
      _state.defendCorruptionApplication(request, choice);
  void convertItemTitle(InventoryItem item) =>
      _state.convertInventoryItemToTitle(item);
  int itemShield(InventoryItem item) => _state.itemShieldBonus(item);
  String get planeId => _state.selectedPlaneId;
  Future<void> useNecromancy(InventoryItem item) => _state.useNecromancyEquipment(item);
  void skullHit() => _state.advanceSkullFormHit();
  Widget dicePanel() => _state.sheetDiceRollPanel(dense: true);
  Widget subtraitsPanel() => _state.referenceSubtraitsPanel();
  void resetEncounter() => _state.resetMasterInitiativeRound();
  void reportedTurn(int value) =>
      _state.setPlayerReportedTurn(value, broadcast: false);
  void removeParticipant(int index) =>
      _state.removeMasterInitiativeTokenAt(index);
  void damage(int amount) => _state.applicaDannoSubito(dannoEsplicito: amount);
  Future<void> damageResolved(
    int amount, {
    bool critical = false,
    int criticalMultiplier = 1,
    double defenseMultiplier = 1,
    int enemyLevel = 0,
    String difficulty = 'normale',
    bool resolvedResistance = false,
    bool bypassDefense = false,
    bool bypassShields = false,
    int shieldDamageBonusPercent = 0,
    int resistanceBypassDamage = 0,
  }) => _state.applicaDannoSubito(
    dannoEsplicito: amount,
    critico: critical,
    criticalBonusMultiplier: criticalMultiplier,
    defenseMultiplier: defenseMultiplier,
    enemyDifficulty: difficulty,
    enemyLevel: enemyLevel,
    resolvedResistance: resolvedResistance,
    bypassDefense: bypassDefense,
    bypassShields: bypassShields,
    shieldDamageBonusPercent: shieldDamageBonusPercent,
    resistanceBypassDamage: resistanceBypassDamage,
  );

  bool get masterPermissions => _state.haPermessiMaster;
  bool get canActWithoutApproval => _state.canActWithoutMasterApproval;
  String get permissionScope => _state.permissionScope;
  void receivePermission(String event, Map<String, dynamic> payload) =>
      _state.receivePermissionEvent(event, payload);
  void receiveCombat(String event, Map<String, dynamic> payload) =>
      _state.receiveOnlineCombatEvent(event, payload);
  Future<void> connectOnline() => _state.connectRealtimeOculum();
  Future<void> disconnectOnline() async {
    _state.realtimeAutoReconnectEnabled = false;
    await _state.realtimeService?.disconnect();
  }

  void publishTurnOrder() => _state.publishRealtimeInitiativeSnapshot();
  void syncMasterTurnOrder() =>
      _state.sendRealtimeInitiativeSnapshotIfPublished();
  void shareMasterParty() => _state.sendRealtimeMasterVisiblePartyTokens();
  Future<void> resolveSheetIdentity(String tag) =>
      _state.showRealtimeSheetIdentityConflict(tag);
  void receiveRealtime(String event, Map<String, dynamic> payload) =>
      _state.handleRealtimeEvent(event, payload);
  Future<void> requestPlayerSheets() => _state.requestRealtimePlayerSheets();
  Future<void> sendCurrentSheet() => _state.sendRealtimeCurrentSheetManually();
  void recordCurrentEncounter() => _state.captureActiveMasterInitiativeGroup();
  Future<void> finishEncounter(String id, {Random? random}) =>
      _state.finishEncounter(id, random: random);
  bool ensureSheetTags() => _state.assicuraTagSchede();
  Future<void> syncOwnedStaffSheets() =>
      _state.sendRealtimeActiveSheetToStaff();
  Future<void> joinMasterEncounter(Map<String, dynamic> group) =>
      _state.joinSharedMasterEncounter(group);
  Future<void> retryEncounterJoins() => _state.retryPendingEncounterJoins();
  void receiveEncounterJoin(Map<String, dynamic> payload) =>
      _state.receiveRealtimeReportedTurn(payload);
  void shareStaffTurnOrderSheets() => _state.sendRealtimeStaffTurnOrderSheets();
  bool receiveStaffSheet(Map<String, dynamic> payload) =>
      _state.receiveRealtimeSharedSheet(payload);
  List<String> ownedPresenceTags() => _state.ownedOculumTags();
  Widget combatRequestsPanel() => _state.onlineCombatRequestsPanel();
  void claimVampirism(Map<String, dynamic> request) =>
      _state.claimOnlineVampirism(request);
  bool recordCorruptionHit(Map<String, dynamic> request) =>
      _state.recordCorruptionMasteryHit(request);
  String corruptor(Map<String, dynamic> token) =>
      _state.corruptionOwnerForToken(token);
  int corruptionControlChance(Map<String, dynamic> token) =>
      _state.corruptionControlChanceForToken(token);
  Widget combatAbilityBar() => _state.combatAbilityQuickBar();
  Future<void> openCombatActionPanel(OculumCombatAbilityRole role) =>
      _state.showCombatActionPanel(role);
  Future<void> requestDefenseRetry(Map<String, dynamic> request) =>
      _state.requestDefenseRetry(request);
  Future<void> useCombatRoll(OculumCombatAbilityRole role) =>
      _state.useCombatRoll(role);
  Color combatAbilityColor(String resource) =>
      _state.combatAbilityResourceColor([resource]);
  Future<void> defendCombat(Map<String, dynamic> request, String choice) =>
      _state.defendOnlineAttack(request, choice);
  Future<void> resolveCombatDefense(
    Map<String, dynamic> request,
    String choice,
    int total,
  ) => _state.applyResolvedOnlineDefense(request, choice, total);
  Future<void> applyLocalTargetEffect(Map<String, dynamic> pending) =>
      _state.applyPendingTargetEffectLocally(pending);
  void receiveRole(Map<String, dynamic> payload) =>
      _state.applyRealtimeRoleUpdate(payload);
  void requestAction(String action, String description) =>
      _state.requestMasterAction(action, description);
  Future<void> showRequests() => _state.showMasterRequests();
  Future<void> decideRequest(Map<String, dynamic> request, bool allowed) =>
      _state.decideMasterRequest(request, allowed);
  bool grantThreshold({String? stat, int? variant}) =>
      _state.grantFirstStatThresholdSkill(changedStat: stat, variant: variant);
  Future<void> useThreshold(CharacterSkill skill) =>
      _state.useStatThresholdSkill(skill);
  String activateForce(String id) {
    _state.statoForzaAttivo = id;
    return _state.applicaEffettoImmediatoStatoForza(id);
  }

  void endForce() =>
      _state.terminaStatoForzaAttivo(applicaEsitoEsplosione: false);
  void loseResilienceBuff(int amount) =>
      _state.rimarginaHpDaAumentoResilienza(-amount);
  int currentHp() => _state.hpCorrenti();
  int broodHp() => _state.broodRemainingHp();
  int broodMaxHp() => _state.broodMaximumHp();
  int absorbBroodDamage(int value) => _state.absorbLarvalBroodDamage(value);
  void useWitheredHeart(InventoryItem item) => _state.useWitheredHeart(item);
  void tickConditions(OculumConditionTickTrigger trigger) =>
      _state.processConditionTick(trigger);
  void moveSheetFolderEntry(String tag, String parent, {int? beforeIndex}) =>
      _state.moveSidebarEntry(tag, parent, beforeIndex: beforeIndex);
  Future<void> showSheetFolders() => _state.showSheetFoldersDialog();
  Map<String, dynamic> campaignSnapshot() => _state.currentCampaignSnapshot();
  void loadCampaign(Map<String, dynamic> data) =>
      _state.loadCampaignSnapshot(data);
  int currentTemporaryHp() => _state.hpTemp();
  void increaseBaseStat(String key, int amount) =>
      _state.aumentaStatBaseEAttuale(key, amount);
  void invalidateDerivedCaches() => _state.invalidateDerivedDataCaches();
  int vc() => _state.vc();
  int consumeHelp() => _state.consumeCombatHelp();
  void completeFate(Map<String, dynamic> group) =>
      _state.applyChainedFateCompletion(group);
  int fateExperienceMultiplier() => _state.chainedFateExperienceMultiplier();
  void openReputations() => _state.openReputationManagerSheet();
  Future<void> helpAlly() => _state.tiraAiutaCompagno();
  Future<void> retryCombat() =>
      _state.replayOnlineCombatRequests(retryOnly: true);
  Future<void> planAttack({int minimum = 1, int maximum = 1}) =>
      _state.planOnlineAttack(minimumTargets: minimum, maximumTargets: maximum);
  String gainCoreMastery(String key, int natural, {int faces = 20}) =>
      _state.registraEsperienzaCriticaStat(
        key: key,
        dado: natural,
        totale: natural,
        faces: faces,
      );
  Map<String, int> levelUpBonuses() => {
    for (final name in _state.statsLevelUp)
      name: _state.bonusLevelUpPerStat(name),
  };
  Map<String, int> coreStats() => {
    'resilienza': _state.resilienzaTotale(),
    'volonta': _state.volontaTotale(),
    'materia': _state.materiaTotale(),
    'oculum': _state.oculumTotale(),
  };
  Map<String, dynamic> snapshot() => _state.statoCorrenteJson();
  bool triggerPackLeaderPhase() => _state.applicaFaseCapobrancoSeServe();
  Map<String, dynamic> fallenEyeBodyFromSource(Map<String, dynamic> source) =>
      _state._fallenEyeBodyFromSource(source);
  Future<void> activateFallenEye(Map<String, dynamic> eye) =>
      _state.activateFallenEye(eye);
  Future<void> deactivateFallenEye(Map<String, dynamic> eye) =>
      _state.deactivateFallenEye(eye);
  int repairFallenEyeSheets() => _state.repairMissingFallenEyeSheets();
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
  bool knowsCombatWeakPoint(Map<String, dynamic> token) =>
      _state.combatTokenWeakPointKnown(token);
  void rememberMonsterPage(String monsterId) =>
      _state.rememberMonsterBookPartyDiscovery(monsterId, pagePurchased: true);
  void rememberMonsterDiscovery(
    String monsterId, {
    bool seen = false,
    bool weakPoint = false,
    bool nameKnown = false,
  }) => _state.rememberMonsterBookPartyDiscovery(
    monsterId,
    seen: seen,
    weakPoint: weakPoint,
    nameKnown: nameKnown,
  );
  Future<void> showMonsterBookEntry(String monsterId) =>
      _state.showMonsterBookPartyEntry(monsterById(monsterId)!);
  int combatScoutVeloAt(int index, {String? observerSide}) =>
      _state.sheetCombatScoutVeloAt(index, observerSide: observerSide);
  void refreshEncounterResources(Map<String, dynamic> token) =>
      _state.restoreMasterInitiativeTurnResources(token);
  Map<String, dynamic> publicEncounter(Map<String, dynamic> group) =>
      _state.publicEncounterSnapshot(group);
  String encounterPortrait(Map<String, dynamic> token) =>
      _state.realtimeEncounterPortrait(token);
  void receiveInitiative(Map<String, dynamic> payload) =>
      _state.receiveRealtimeInitiativeSnapshot(payload);
  void receiveEncounterControl(Map<String, dynamic> payload) =>
      _state.receiveEncounterControl(payload);
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
  Map<String, num> formulaContext() => _state.formulaValueContext();
  InventoryItem merchantItem(
    Map<String, dynamic> offer, {
    String titleType = '',
  }) => _state.merchantItemFromOffer(offer, titleType: titleType);
  int shieldBonus(InventoryItem item) => _state.itemShieldBonus(item);
  Future<void> useMerchantItem(InventoryItem item) =>
      _state.useMerchantConsumable(item);
  void createMerchantProfile() => _state.createRandomMerchantProfile();
  void switchMerchantProfile(String id) => _state.switchMerchantProfile(id);
  List<String> merchantOfferIds() =>
      _state.ensureMerchantStock().map((offer) => '${offer['id']}').toList();
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
  void setTurn({required int round, int? activeIndex}) =>
      _state.setMasterInitiativeTurn(round: round, activeIndex: activeIndex);
  int masterRound() => _state.masterInitiativeRound;
  bool canUseInitiativeAction(int index) =>
      _state.masterInitiativeCanToggleAction(index);
  void toggleInitiativeAction(int index) =>
      _state.toggleMasterInitiativeActionUsed(index);
  int dodgeTotal() => _state.schivateOculumTotali();
  void quickEditDodge(int delta) => _state.modificaSchivateOculumRapide(delta);
  void activateInitiative(int index) =>
      _state.setMasterInitiativeActiveIndex(index);
  void normalizeInitiative() => _state.normalizeMasterInitiativeTokens();
  void showTutorial() => _state.mostraTutorial();
  void sortInitiative() =>
      _state.sortMasterInitiativeTokens(forceInitiative: true);
  void longRest() => _state.riposoLungo();
  void recoverLongRestStats() => _state.ripristinaStatsRiposoLungo();
  void restoreStatsAndHp() => _state.ripristinaStatisticheEVita();
  String? changeAsh(int delta, {bool checkFainting = true}) => _state
      .modificaCenereControllata(delta, controllaSvenimento: checkFainting);
  int fatigueRollPenalty() => _state.malusFaticaTiri();
  Future<void> showEnemyCriticalDialog() => _state.mostraCriticoControNemico();
  OculumTitle? visibleTitle() => _state.titoloSempreVisibile;
  int visibleTitleBonus(String stat) => _state.visibleTitleStatBonus(stat);
  int visibleResourceCurrent(String key) => key == 'oculum'
      ? _state.oculumTotale()
      : _state.currentStatWithRuntimeBuffs(key, resourceCurrent(key));
  int visibleResourceMaximum(String key) => _state.statMassimoNaturale(key);
  void selectVisibleTitle(OculumTitle? selected) {
    if (selected != null &&
        !oculumTitleCanBeAlwaysVisible(selected, _state.titoliCalcolabili)) {
      return;
    }
    for (final title in _state.titoliCalcolabili) {
      title.sempreVisibile = identical(title, selected);
      title.visibleSelectionManual = identical(title, selected);
    }
    _state.titoloSempreVisibile;
  }

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
