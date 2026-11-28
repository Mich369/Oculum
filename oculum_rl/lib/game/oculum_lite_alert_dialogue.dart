import 'package:flutter/foundation.dart';

import 'oculum_lite_run.dart';

enum LiteAlertSound {
  evasore,
  duplicatore,
  ashley,
  scostubandito,
  granScostumato,
  solare,
  lunare,
  goblin,
  infernoNobile,
  infernoCinque,
  minore,
  intermedio,
  ruggitoForesta,
  cucciolo,
  lupo,
  pipistrello,
  pollo,
  rana,
  liquido,
  roccia,
  metallo,
  zampa,
  eiva,
  campana,
  sibilo,
  pyrel,
  lithra,
  ombra,
  luce,
  fabbro;

  String get asset => 'allerta-$name';
}

typedef LiteAlertDialogue = ({
  String speaker,
  String text,
  LiteAlertSound sound,
  String? spokenKey,
  bool hostile,
});

typedef _AlertLine = (String, String, LiteAlertSound);

const _sunGreeting = 'Che il Sole illumini la vostra via';
const _banditGreeting = 'Hey stronzo ti faccio rigirare il culo!';
const _cannonGreeting = 'Hey non romperti subito';

LiteAlertDialogue? liteAlertDialogue(LiteAlertCall call) {
  final enemy = call.enemy;
  final hero = call.hero;
  if (enemy == null && hero == null) return null;
  final mirror =
      enemy == LiteEnemyKind.luce ||
      enemy == LiteEnemyKind.ombra ||
      enemy == LiteEnemyKind.ecoSpeculare;
  final (speaker, text, sound) = switch ((enemy, hero)) {
    (final enemy?, final source?) when mirror => (
      enemy.label,
      _heroLine(source).$2,
      enemy == LiteEnemyKind.luce ? LiteAlertSound.luce : LiteAlertSound.ombra,
    ),
    (final enemy?, _) => _enemyLine(enemy, call.fiveFlames),
    (_, final hero?) => _heroLine(hero),
    _ => throw StateError('Allerta senza creatura'),
  };
  final spokenKey = enemy != null && !(mirror && hero != null)
      ? _enemyVoiceKey(enemy, call.fiveFlames)
      : _heroVoiceKey(hero!);
  return (
    speaker: speaker,
    text: text,
    sound: sound,
    spokenKey: spokenKey,
    hostile: enemy != null,
  );
}

_AlertLine _heroLine(LiteHero hero) => switch (hero) {
  LiteHero.evasore => (
    'Evasore',
    'ops, mi avete visto eheh',
    LiteAlertSound.evasore,
  ),
  LiteHero.duplicatore => (
    'Duplicatore',
    'Quanti ne contate? Ricominciate.',
    LiteAlertSound.duplicatore,
  ),
  LiteHero.ashley => (
    'Ashley',
    'non mi giudicate debole solo per la mia età!',
    LiteAlertSound.ashley,
  ),
  LiteHero.scostubandito => (
    'Scostubandito',
    _banditGreeting,
    LiteAlertSound.scostubandito,
  ),
  LiteHero.granScostumato => (
    'Gran Scostumato',
    _cannonGreeting,
    LiteAlertSound.granScostumato,
  ),
  LiteHero.dronePostea => (
    'Drone di Postea',
    'Bip. Bip. BZZZRT!',
    LiteAlertSound.metallo,
  ),
  LiteHero.sentinella => (
    'Sentinella di Pietra',
    'Krrrk… THUM.',
    LiteAlertSound.roccia,
  ),
  LiteHero.babyForestDemon => (
    'Baby Forest Demon',
    'Grrr… rràk!',
    LiteAlertSound.cucciolo,
  ),
  LiteHero.curatorePeste => (
    'Curatore della Peste',
    'Ho ancora posto sotto il mantello.',
    LiteAlertSound.ombra,
  ),
  LiteHero.pyrel => (
    'Pyrel',
    'Una scintilla basta se viene da me.',
    LiteAlertSound.pyrel,
  ),
  LiteHero.lithra => (
    'Lithra',
    'Sentite anche voi il terreno tremare?',
    LiteAlertSound.lithra,
  ),
  LiteHero.luce => (
    'La tua Luce',
    'Guardatemi. Vi apro io un varco.',
    LiteAlertSound.luce,
  ),
  LiteHero.ombra => (
    'La tua Ombra',
    'Credete di avermi vista tutta?',
    LiteAlertSound.ombra,
  ),
  LiteHero.veyrth => ('Veyrth', 'Vmm… vrrr-ŪM!', LiteAlertSound.eiva),
  LiteHero.doppelganger => (
    'Doppelganger',
    'Hk… kh-khh!',
    LiteAlertSound.sibilo,
  ),
  LiteHero.cavaliereLunare => (
    'Cavaliere Elité Lunare',
    'Sotto la Luna, nessuno resta indietro.',
    LiteAlertSound.lunare,
  ),
  LiteHero.slimeBlu => ('Slime Blu', 'Plup… GLUP!', LiteAlertSound.liquido),
  LiteHero.vampiro => (
    'Vampiro',
    'Vi sento il cuore da qui.',
    LiteAlertSound.infernoNobile,
  ),
  LiteHero.reGoblin => (
    'Re Goblin',
    'In piedi, goblin. Questa corte è nostra!',
    LiteAlertSound.goblin,
  ),
  LiteHero.pollo => ('Pollo di Brace', 'Co-co-COCCODÈ!', LiteAlertSound.pollo),
  LiteHero.raganella => (
    'Raganella del Muschio',
    'Gràc, gràc… croà!',
    LiteAlertSound.rana,
  ),
  LiteHero.pipistrello => (
    'Pipistrello di Pece',
    'Kii-kii-KII!',
    LiteAlertSound.pipistrello,
  ),
  LiteHero.guardiaSolare => (
    'Guardia Solare',
    _sunGreeting,
    LiteAlertSound.solare,
  ),
  LiteHero.eliteSolare => (
    'Guardia Elité Solare',
    _sunGreeting,
    LiteAlertSound.solare,
  ),
  LiteHero.guardianoSolare => (
    'Guardiano Solare',
    _sunGreeting,
    LiteAlertSound.solare,
  ),
  LiteHero.aberrazioneSolare => (
    'Aberrazione d’Oro e Marmo',
    'Krrraash… krik!',
    LiteAlertSound.roccia,
  ),
  LiteHero.demoneMinore => (
    'Demone Minore',
    'Rrah! Grrah!',
    LiteAlertSound.minore,
  ),
  LiteHero.demoneIntermedio => (
    'Demone Intermedio',
    'RROOAARR!',
    LiteAlertSound.intermedio,
  ),
  LiteHero.demoneMaggiore => (
    'Demone Maggiore Prediletto',
    'Dietro di me. Le corna spaventano loro, non voi.',
    LiteAlertSound.infernoNobile,
  ),
  LiteHero.diavolo => (
    'Diavolo delle Cinque Fiamme',
    'Hai contato fino a cinque, stronzo?',
    LiteAlertSound.infernoCinque,
  ),
  LiteHero.polloMeccanico => (
    'Pollo Meccanico',
    'COC-bip. COC-bip. TZAK!',
    LiteAlertSound.metallo,
  ),
  LiteHero.vesanybel => ('Vesanybel', 'Donnn… DONNN.', LiteAlertSound.campana),
  LiteHero.aerovyr => ('Aerovyr', 'Ssshh… KRRRAAK!', LiteAlertSound.sibilo),
  LiteHero.vedettaEiva => (
    'Vedetta Eiva',
    'Conosco queste correnti. Seguitemi.',
    LiteAlertSound.eiva,
  ),
  LiteHero.ragnoSaldatore => (
    'Ragno Saldatore',
    'Trrr-tak. FZZZZ!',
    LiteAlertSound.metallo,
  ),
  LiteHero.rasvyr => ('Rasvyr', 'KLAK! Krr-tak!', LiteAlertSound.zampa),
  LiteHero.lupoDiVaitern => (
    'Lupo Lunare di Vaitern',
    'Auh… AUUUH!',
    LiteAlertSound.lupo,
  ),
  LiteHero.pysciwarden => (
    'Pysciwarden',
    'Al canale ci penso io. Muovetevi.',
    LiteAlertSound.eiva,
  ),
  LiteHero.lusierTre => ('Lusier III', _sunGreeting, LiteAlertSound.solare),
  LiteHero.fabbro => (
    'Fabbro',
    'Vediamo chi cede prima. Io o il mio martello?',
    LiteAlertSound.fabbro,
  ),
  LiteHero.gablyn => (
    'Gablyn',
    'Il buio di casa mi ha insegnato dove colpire.',
    LiteAlertSound.goblin,
  ),
  LiteHero.funerys => (
    'Funerys',
    'Ascoltate. Persino la cenere si sta alzando.',
    LiteAlertSound.ombra,
  ),
  LiteHero.moscaCampana => (
    'Mosca Campana',
    'Bzzzz… DLINN!',
    LiteAlertSound.campana,
  ),
  LiteHero.scostubanditoErrato || LiteHero.scostubanditoVeteranoErrato => (
    'Scostubandito errato',
    'Fsss…',
    LiteAlertSound.ombra,
  ),
  LiteHero.assassino => (
    'Assassino',
    'Troppo tardi. Avete visto solo l’ombra.',
    LiteAlertSound.ombra,
  ),
  LiteHero.armadilloCorazzato => (
    'Armadillo Corazzato',
    'Trrr-TRAK! Hrff!',
    LiteAlertSound.roccia,
  ),
};

_AlertLine _enemyLine(LiteEnemyKind kind, bool fiveFlames) {
  final (text, sound) = switch (kind) {
    LiteEnemyKind.scostubandito => (
      _banditGreeting,
      LiteAlertSound.scostubandito,
    ),
    LiteEnemyKind.granScostumato => (
      _cannonGreeting,
      LiteAlertSound.granScostumato,
    ),
    LiteEnemyKind.babyForestDemon => ('Grr… rrek!', LiteAlertSound.cucciolo),
    LiteEnemyKind.forestDemon => ('GRRRAAUHH!', LiteAlertSound.ruggitoForesta),
    LiteEnemyKind.slime => ('Sluup! Ploc!', LiteAlertSound.liquido),
    LiteEnemyKind.costrutto => ('KRRR… THUM!', LiteAlertSound.roccia),
    LiteEnemyKind.ragnoSaldatore => ('Tik-tik… FZZZT!', LiteAlertSound.metallo),
    LiteEnemyKind.dronePostea => ('Bip bip. BZZZRT!', LiteAlertSound.metallo),
    LiteEnemyKind.miruscyrus => ('Krik-krik… SSRAK!', LiteAlertSound.zampa),
    LiteEnemyKind.luce => (
      'Eccomi. Vediamo cosa fai della tua Luce.',
      LiteAlertSound.luce,
    ),
    LiteEnemyKind.ombra => (
      'Mi riconosci anche senza la luce?',
      LiteAlertSound.ombra,
    ),
    LiteEnemyKind.veyrth => ('Vrrumm… VŪM!', LiteAlertSound.eiva),
    LiteEnemyKind.minionVeyrth => ('Mm-hvmm!', LiteAlertSound.eiva),
    LiteEnemyKind.ecoSpeculare => ('Hssh… tssh.', LiteAlertSound.ombra),
    LiteEnemyKind.rasvyr => ('KLAK! KLAK!', LiteAlertSound.zampa),
    LiteEnemyKind.orbryx => ('Brrup! PRRÒ!', LiteAlertSound.liquido),
    LiteEnemyKind.lupoLunare => ('Grrr… AUUUH!', LiteAlertSound.lupo),
    LiteEnemyKind.gablyn => (
      'Chi mette piede qui risponde a me!',
      LiteAlertSound.goblin,
    ),
    LiteEnemyKind.guardiaLunare => (
      'Per la Luna, lasciate le armi e passerete.',
      LiteAlertSound.lunare,
    ),
    LiteEnemyKind.guardianoLunare => (
      'Finché reggo il varco, i miei possono riposare.',
      LiteAlertSound.lunare,
    ),
    LiteEnemyKind.goblinColtello => (
      'Ehi, adesso tocca a me!',
      LiteAlertSound.goblin,
    ),
    LiteEnemyKind.goblinFango => (
      'Tieni, ti manca un po’ di fango in faccia!',
      LiteAlertSound.goblin,
    ),
    LiteEnemyKind.goblinColla => (
      'Fermo lì! Tanto tra un attimo lo sarai.',
      LiteAlertSound.scostubandito,
    ),
    LiteEnemyKind.reGoblin => (
      'In piedi, goblin. Difendete la corte!',
      LiteAlertSound.granScostumato,
    ),
    LiteEnemyKind.pollo => ('Co-co-co! COCCODÈ!', LiteAlertSound.pollo),
    LiteEnemyKind.raganella => ('Croà! Gràc!', LiteAlertSound.rana),
    LiteEnemyKind.pipistrello => ('KIK! Skii!', LiteAlertSound.pipistrello),
    LiteEnemyKind.guardiaSolare ||
    LiteEnemyKind.eliteSolare ||
    LiteEnemyKind.guardianoSolare => (_sunGreeting, LiteAlertSound.solare),
    LiteEnemyKind.aberrazioneSolare => (
      'Krrraash… grik!',
      LiteAlertSound.roccia,
    ),
    LiteEnemyKind.eliteLunare => (
      'La Luna veglia su chi sta dietro il mio scudo.',
      LiteAlertSound.lunare,
    ),
    LiteEnemyKind.custodeLunare => (
      'Questo passaggio è sotto la mia custodia.',
      LiteAlertSound.lunare,
    ),
    LiteEnemyKind.demoneMinore => ('Rrah! Grrah!', LiteAlertSound.minore),
    LiteEnemyKind.demoneIntermedio => ('RROOAARR!', LiteAlertSound.intermedio),
    LiteEnemyKind.demoneMaggiore => (
      'Andatevene in pace. Vi concedo ancora il passo.',
      LiteAlertSound.infernoNobile,
    ),
    LiteEnemyKind.diavolo when fiveFlames => (
      'Corri, stronzo. Le mie cinque fiamme ti troveranno.',
      LiteAlertSound.infernoCinque,
    ),
    LiteEnemyKind.diavolo => (
      'Ospiti? Bene. Possiamo ancora parlare.',
      LiteAlertSound.infernoNobile,
    ),
    LiteEnemyKind.divoramitu => (
      'Shrrr… GRUOM!',
      LiteAlertSound.ruggitoForesta,
    ),
    LiteEnemyKind.divoramituBoss => (
      'GRUOOOM… KRRRA!',
      LiteAlertSound.intermedio,
    ),
    LiteEnemyKind.arconte => ('KRRRGH… TUNK!', LiteAlertSound.roccia),
    LiteEnemyKind.funerys => (
      'La cenere ricorda i vostri passi.',
      LiteAlertSound.ombra,
    ),
    LiteEnemyKind.vegliante => ('Clonk… CLANG!', LiteAlertSound.metallo),
    LiteEnemyKind.vesanybel => ('Donnn… DONG!', LiteAlertSound.campana),
    LiteEnemyKind.sacrycrab => ('Krk… KLAK!', LiteAlertSound.zampa),
    LiteEnemyKind.gelycryn => ('Kriik… TAK!', LiteAlertSound.zampa),
    LiteEnemyKind.thalvyr => ('GLRROK! KLAK!', LiteAlertSound.liquido),
    LiteEnemyKind.lapysrieth => ('Fzz… vrrr-TZIT!', LiteAlertSound.eiva),
    LiteEnemyKind.nymboryth => ('Sss-RRAK!', LiteAlertSound.sibilo),
    LiteEnemyKind.aerovyr => ('KSSHH… KRRRAAK!', LiteAlertSound.sibilo),
    LiteEnemyKind.baghest => ('GRROOO-AAGH!', LiteAlertSound.intermedio),
    LiteEnemyKind.corrottoRosso => ('Hrrrk… RRASH!', LiteAlertSound.minore),
    LiteEnemyKind.bunnys => ('Piip piip… BRR!', LiteAlertSound.rana),
    LiteEnemyKind.cuccioloDivoramitu => (
      'Shrr… krrì!',
      LiteAlertSound.cucciolo,
    ),
    LiteEnemyKind.moscaCampana => ('Bzzzz… DLINN!', LiteAlertSound.campana),
    LiteEnemyKind.armadilloCorazzato => ('Trrr… TUNK!', LiteAlertSound.roccia),
  };
  final label = kind == LiteEnemyKind.diavolo && fiveFlames
      ? 'Diavolo delle Cinque Fiamme'
      : kind.label;
  return (label, text, sound);
}

String? _heroVoiceKey(LiteHero hero) => switch (hero) {
  LiteHero.guardiaSolare ||
  LiteHero.eliteSolare ||
  LiteHero.guardianoSolare ||
  LiteHero.lusierTre => 'solare',
  LiteHero.diavolo => 'diavoloCinqueFiammeEroe',
  LiteHero.dronePostea ||
  LiteHero.sentinella ||
  LiteHero.babyForestDemon ||
  LiteHero.veyrth ||
  LiteHero.doppelganger ||
  LiteHero.slimeBlu ||
  LiteHero.pollo ||
  LiteHero.raganella ||
  LiteHero.pipistrello ||
  LiteHero.aberrazioneSolare ||
  LiteHero.demoneMinore ||
  LiteHero.demoneIntermedio ||
  LiteHero.polloMeccanico ||
  LiteHero.vesanybel ||
  LiteHero.aerovyr ||
  LiteHero.ragnoSaldatore ||
  LiteHero.rasvyr ||
  LiteHero.lupoDiVaitern ||
  LiteHero.moscaCampana ||
  LiteHero.armadilloCorazzato ||
  LiteHero.scostubanditoErrato ||
  LiteHero.scostubanditoVeteranoErrato => null,
  _ => hero.name,
};

String? _enemyVoiceKey(LiteEnemyKind kind, bool fiveFlames) => switch (kind) {
  LiteEnemyKind.guardiaSolare ||
  LiteEnemyKind.eliteSolare ||
  LiteEnemyKind.guardianoSolare => 'solare',
  LiteEnemyKind.scostubandito || LiteEnemyKind.granScostumato => kind.name,
  LiteEnemyKind.diavolo when fiveFlames => 'diavoloCinqueFiamme',
  LiteEnemyKind.diavolo ||
  LiteEnemyKind.demoneMaggiore ||
  LiteEnemyKind.luce ||
  LiteEnemyKind.ombra ||
  LiteEnemyKind.gablyn ||
  LiteEnemyKind.guardiaLunare ||
  LiteEnemyKind.guardianoLunare ||
  LiteEnemyKind.eliteLunare ||
  LiteEnemyKind.custodeLunare ||
  LiteEnemyKind.goblinColtello ||
  LiteEnemyKind.goblinColla ||
  LiteEnemyKind.goblinFango ||
  LiteEnemyKind.reGoblin ||
  LiteEnemyKind.funerys => '${kind.name}Nemico',
  _ => null,
};

/// Scriptable inputs for offline Italian audio rendering.
Map<String, ({String text, LiteAlertSound sound})> liteAlertSpokenLines() {
  final lines = <String, ({String text, LiteAlertSound sound})>{};
  void add(String? key, _AlertLine line) {
    if (key != null)
      lines.putIfAbsent(key, () => (text: line.$2, sound: line.$3));
  }

  for (final hero in LiteHero.values) {
    add(_heroVoiceKey(hero), _heroLine(hero));
  }
  for (final kind in LiteEnemyKind.values) {
    add(_enemyVoiceKey(kind, false), _enemyLine(kind, false));
  }
  add(
    _enemyVoiceKey(LiteEnemyKind.diavolo, true),
    _enemyLine(LiteEnemyKind.diavolo, true),
  );
  return lines;
}

/// One local inbox for both a mutable solo run and immutable co-op snapshots.
class LiteAlertPresenter extends ValueNotifier<LiteAlertDialogue?> {
  LiteAlertPresenter({
    required void Function(LiteAlertDialogue) play,
    required VoidCallback stop,
    bool Function()? speaking,
    Duration Function()? clock,
  }) : _play = play,
       _stop = stop,
       _speaking = speaking,
       _clock = clock,
       super(null);

  final void Function(LiteAlertDialogue) _play;
  final VoidCallback _stop;
  final bool Function()? _speaking;
  final Duration Function()? _clock;
  final Stopwatch _elapsed = Stopwatch()..start();
  final List<LiteAlertCall> _waiting = [];
  Object? _session;
  Object? _scene;
  int _seenSequence = -1;
  bool _playing = false;
  Duration _nextCall = Duration.zero;
  Duration _subtitleUntil = Duration.zero;

  void update(
    LiteRun? run, {
    Object? session,
    required int? viewerId,
    required bool playing,
  }) => receive(
    run?.alertCalls ?? const [],
    time: run?.time ?? 0,
    session: session ?? run,
    scene: run?.inputArena,
    viewerId: viewerId,
    playing: playing && run != null,
  );

  void receive(
    Iterable<LiteAlertCall> calls, {
    required double time,
    required Object? session,
    Object? scene,
    required int? viewerId,
    required bool playing,
  }) {
    if (!identical(_session, session)) {
      _session = session;
      _seenSequence = -1;
      _clear();
    } else if (_scene != scene) {
      _clear();
    }
    _scene = scene;
    final previouslySeen = _seenSequence;
    for (final call in calls) {
      if (call.sequence <= previouslySeen) continue;
      if (call.sequence > _seenSequence) _seenSequence = call.sequence;
      if (!playing ||
          call.viewerId != null && call.viewerId != viewerId ||
          !_fresh(call, time) ||
          _waiting.any((entry) => entry.sequence == call.sequence)) {
        continue;
      }
      _waiting.add(call);
    }
    if (!playing) {
      _clear();
      return;
    }
    _playing = true;
    // Own lines stay in the queue first when several enemies shout together.
    _waiting.removeWhere((call) => !_fresh(call, time));
    _waiting.sort((a, b) {
      final personal = (b.viewerId != null ? 1 : 0).compareTo(
        a.viewerId != null ? 1 : 0,
      );
      return personal != 0 ? personal : a.sequence.compareTo(b.sequence);
    });
    if (_waiting.length > 5) _waiting.removeRange(5, _waiting.length);

    final now = _clock?.call() ?? _elapsed.elapsed;
    final speaking =
        value != null &&
        now < _subtitleUntil + const Duration(seconds: 2) &&
        (_speaking?.call() ?? false);
    if (now >= _subtitleUntil && value != null && !speaking) value = null;
    if (now < _nextCall || speaking || _waiting.isEmpty) return;
    final line = liteAlertDialogue(_waiting.removeAt(0));
    if (line == null) return;
    value = line;
    final readingMs = line.spokenKey == null
        ? (910 + line.text.length * 30).clamp(1550, 2800)
        : (850 + line.text.length * 51).clamp(1700, 4250);
    _nextCall = now + Duration(milliseconds: readingMs);
    _subtitleUntil = _nextCall + const Duration(milliseconds: 280);
    _play(line);
  }

  static bool _fresh(LiteAlertCall call, double time) {
    final age = time - call.time;
    return age >= -.05 && age <= 3;
  }

  void _clear() {
    if (_playing) _stop();
    _playing = false;
    _waiting.clear();
    _nextCall = Duration.zero;
    _subtitleUntil = Duration.zero;
    if (value != null) value = null;
  }
}
