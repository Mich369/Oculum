part of '../../main.dart';

int readIntValue(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

double readDoubleValue(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
  }
  return fallback;
}

bool readBoolValue(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'si') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

int oculumTitleOpenExperienceTarget(int unlockedOpenCount) {
  final count = max(0, unlockedOpenCount);
  if (count == 0) return 0;
  if (count == 1) return 25;
  return 25 + count * 50;
}

int oculumRollExperienceGain({
  required int naturalRoll,
  required int faces,
  required bool rollSucceeded,
}) {
  if (faces != 20 || !rollSucceeded || naturalRoll < 18) return 0;
  if (naturalRoll == faces) {
    return naturalRoll + faces ~/ 2;
  }
  return (naturalRoll + 1) ~/ 2;
}

({int recoveries, int remainder}) oculumExperienceHundredProgress({
  required int previousRemainder,
  required int experienceGained,
}) {
  final total =
      (previousRemainder.clamp(0, 99).toInt() + max(0, experienceGained))
          .toInt();
  return (recoveries: total ~/ 100, remainder: total % 100);
}

int oculumLowResourceDustChance({required int current, required int maximum}) {
  if (maximum <= 0) return 0;
  if (current * 4 >= maximum) return 0;
  final ratio = current / maximum;
  final deficitPercent = ((0.25 - ratio) * 100).ceil();
  return min(90, max(0, 10 + deficitPercent * 4));
}

// =====================================================
// FORMULE SICURE / ELEMENTI / RICERCA FUZZY
// =====================================================

String oculumNormalizeText(String value) {
  final out = StringBuffer();
  for (final rune in value.toLowerCase().trim().runes) {
    final normalized = _oculumNormalizedLatinRune(rune);
    if (normalized != null) {
      out.write(normalized);
    } else if ((rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0x30 && rune <= 0x39)) {
      out.writeCharCode(rune);
    } else {
      out.write(' ');
    }
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String oculumNormalizeFormulaTriggerText(String value) {
  final out = StringBuffer();
  for (final rune in value.toLowerCase().trim().runes) {
    final normalized = _oculumNormalizedLatinRune(rune);
    if (normalized != null) {
      out.write(normalized);
      continue;
    }

    final char = String.fromCharCode(rune);
    if ((rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0x30 && rune <= 0x39) ||
        rune == 0x5F ||
        '+-*/().,%'.contains(char) ||
        _oculumUnicodeFractionValue(char) != null) {
      out.write(char);
    }
  }
  return out.toString();
}

String? _oculumNormalizedLatinRune(int rune) {
  switch (rune) {
    case 0x00E0:
    case 0x00E1:
    case 0x00E2:
    case 0x00E3:
    case 0x00E4:
    case 0x00E5:
    case 0x0101:
    case 0x0103:
    case 0x0105:
      return 'a';
    case 0x00E7:
    case 0x0107:
    case 0x010D:
      return 'c';
    case 0x00E8:
    case 0x00E9:
    case 0x00EA:
    case 0x00EB:
    case 0x0113:
    case 0x0117:
    case 0x0119:
      return 'e';
    case 0x00EC:
    case 0x00ED:
    case 0x00EE:
    case 0x00EF:
    case 0x012B:
    case 0x012F:
      return 'i';
    case 0x00F1:
    case 0x0144:
      return 'n';
    case 0x00F2:
    case 0x00F3:
    case 0x00F4:
    case 0x00F5:
    case 0x00F6:
    case 0x00F8:
    case 0x014D:
      return 'o';
    case 0x00F9:
    case 0x00FA:
    case 0x00FB:
    case 0x00FC:
    case 0x016B:
      return 'u';
  }
  return null;
}

double? _oculumUnicodeFractionValue(String value) {
  if (value.isEmpty) return null;
  switch (value.runes.first) {
    case 0x2153:
      return 1 / 3;
    case 0x2154:
      return 2 / 3;
    case 0x00BC:
      return 1 / 4;
    case 0x00BD:
      return 1 / 2;
    case 0x00BE:
      return 3 / 4;
    case 0x2155:
      return 1 / 5;
    case 0x2156:
      return 2 / 5;
    case 0x2157:
      return 3 / 5;
    case 0x2158:
      return 4 / 5;
  }
  return null;
}

// ignore: unused_element
String _oculumNormalizeTextLegacy(String value) {
  var out = value.toLowerCase().trim();
  const accents = <String, String>{
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  accents.forEach((from, to) => out = out.replaceAll(from, to));
  return out
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

int oculumLevenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final prev = List<int>.generate(b.length + 1, (i) => i);
  final curr = List<int>.filled(b.length + 1, 0);
  for (var i = 0; i < a.length; i++) {
    curr[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
      curr[j + 1] = [
        curr[j] + 1,
        prev[j + 1] + 1,
        prev[j] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    for (var j = 0; j < prev.length; j++) {
      prev[j] = curr[j];
    }
  }
  return prev[b.length];
}

int oculumSearchScore(String query, String text) {
  final q = oculumNormalizeText(query);
  final t = oculumNormalizeText(text);
  if (q.isEmpty || t.isEmpty) return 0;
  if (t == q) return 1000;
  if (t.contains(q)) return 850 - (t.length - q.length).clamp(0, 300);

  final qWords = q.split(' ').where((x) => x.isNotEmpty).toList();
  final tWords = t.split(' ').where((x) => x.isNotEmpty).toList();
  var score = 0;
  for (final qw in qWords) {
    for (final tw in tWords) {
      if (tw == qw) {
        score += 180;
      } else if (tw.contains(qw) || qw.contains(tw)) {
        score += 120;
      } else {
        final dist = oculumLevenshtein(qw, tw);
        final maxLen = qw.length > tw.length ? qw.length : tw.length;
        if (maxLen >= 4 && dist <= 2) score += 90 - dist * 20;
      }
    }
  }
  return score;
}

String oculumStatKey(String value) {
  final raw = oculumNormalizeText(value).replaceAll(' ', '');
  switch (raw) {
    case 'res':
    case 'resilienza':
    case 'resilience':
      return 'resilienza';
    case 'resattuale':
    case 'resattuali':
    case 'resilienzaattuale':
    case 'resilienzaattuali':
    case 'currentres':
    case 'currentresilience':
      return 'resilienza_current';
    case 'vol':
    case 'volonta':
    case 'will':
    case 'volontà':
      return 'volonta';
    case 'volattuale':
    case 'volattuali':
    case 'volontaattuale':
    case 'volontaattuali':
    case 'willattuale':
    case 'willattuali':
    case 'currentwill':
      return 'volonta_current';
    case 'mat':
    case 'materia':
    case 'matter':
      return 'materia';
    case 'matattuale':
    case 'matattuali':
    case 'materiaattuale':
    case 'materiaattuali':
    case 'currentmat':
    case 'currentmatter':
      return 'materia_current';
    case 'ocu':
    case 'oc':
    case 'oculum':
      return 'oculum';
    case 'ocuattuale':
    case 'ocuattuali':
    case 'oculumattuale':
    case 'oculumattuali':
    case 'currentocu':
    case 'currentoculum':
      return 'oculum_current';
    case 'dif':
    case 'def':
    case 'difesa':
    case 'defense':
      return 'difesa';
    case 'reazione':
    case 'reazioni':
    case 'reaction':
    case 'reactions':
    case 'rea':
      return 'reazione';
    case 'reazioneveloce':
    case 'reazioniveloce':
    case 'reazioniveloci':
    case 'reazioeveloce':
    case 'reazioiveloci':
    case 'fastreaction':
    case 'fastreactions':
    case 'quickreaction':
    case 'quickreactions':
      return 'reazione_veloce';
    case 'vc':
      return 'vc';
    case 'cm':
      return 'cm';
    case 'danno':
    case 'danni':
    case 'dmg':
    case 'damage':
      return 'danni';
    case 'hp':
    case 'pv':
    case 'puntivita':
    case 'vita':
    case 'life':
    case 'health':
      return 'hp';
    case 'hpattuale':
    case 'hpattuali':
    case 'pvattuale':
    case 'pvattuali':
    case 'vitaattuale':
    case 'vitaattuali':
    case 'puntivitaattuali':
    case 'currenthp':
    case 'currenthealth':
    case 'currentlife':
      return 'hp_current';
    case 'hptemp':
    case 'hptemporanei':
    case 'hptemporaneo':
    case 'vitatemporanea':
    case 'vitetemporanee':
    case 'temp':
    case 'temphp':
    case 'temporaryhp':
      return 'hp_temp';
    case 'hptempattuale':
    case 'hptempattuali':
    case 'hptemporaneiattuali':
    case 'vitatemporaneaattuale':
    case 'vitetemporaneeattuali':
    case 'currenthptemp':
      return 'hp_temp_current';
    case 'scudo':
    case 'shield':
      return 'scudo';
    case 'scudoattuale':
    case 'scudoattuali':
    case 'shieldcurrent':
    case 'currentshield':
      return 'scudo_current';
    case 'scudooculum':
    case 'scudoocu':
    case 'scudooculare':
    case 'oculumshield':
    case 'eyeshield':
      return 'scudo_oculum';
    case 'scudooculumattuale':
    case 'scudooculumattuali':
    case 'oculumshieldcurrent':
    case 'currentoculumshield':
      return 'scudo_oculum_current';
    case 'schivataoculum':
    case 'schivateoculum':
    case 'schivataocu':
    case 'schivateocu':
    case 'schivataoculare':
    case 'schivateoculari':
    case 'oculumdodge':
    case 'oculumdodges':
    case 'eyedodge':
    case 'eyedodges':
      return 'schivata_oculum';
    case 'iniziativa':
    case 'iniziative':
    case 'initiative':
    case 'ini':
      return 'iniziativa';
    case 'mov':
    case 'move':
    case 'movement':
    case 'movimento':
    case 'metri':
      return 'movimento';
    case 'tiroattacco':
    case 'tirodiattacco':
    case 'tirovc':
    case 'tirovolontacombattiva':
    case 'vcroll':
    case 'attackroll':
    case 'rollattack':
      return 'tiro_attacco';
    case 'tirodifesa':
    case 'tirodifensivo':
    case 'tirocm':
    case 'tirocerchiomagico':
    case 'cmroll':
    case 'defenseroll':
    case 'rolldefense':
      return 'tiro_difesa';
    case 'tirores':
    case 'tiroresilienza':
    case 'tiroresilience':
    case 'resroll':
    case 'resilienceroll':
      return 'tiro_resilienza';
    case 'tirovol':
    case 'tirovolonta':
    case 'tirowill':
    case 'volroll':
    case 'willroll':
      return 'tiro_volonta';
    case 'tiromat':
    case 'tiromateria':
    case 'tiromatter':
    case 'matroll':
    case 'matterroll':
      return 'tiro_materia';
    case 'tiroocu':
    case 'tirooc':
    case 'tirooculum':
    case 'ocuroll':
    case 'oculumroll':
      return 'tiro_oculum';
    case 'tirostat':
    case 'tirostats':
    case 'tiroallstats':
    case 'tirotuttestats':
    case 'tirostatistiche':
    case 'tiristats':
    case 'tiristatistiche':
    case 'statroll':
    case 'statsroll':
    case 'allstatroll':
    case 'allstatsroll':
      return 'tiro_stats';
    case 'tirootherstats':
    case 'tiroaltrestats':
    case 'tiroaltrestatistiche':
    case 'tiroaltristats':
    case 'otherstatroll':
    case 'otherstatsroll':
      return 'tiro_other_stats';
    case 'stats':
    case 'stat':
    case 'allstats':
    case 'tuttestats':
    case 'statistiche':
    case 'statistichebase':
      return 'stats';
    case 'otherstats':
    case 'altrestats':
    case 'altrestatistiche':
    case 'altristats':
      return 'other_stats';
  }
  return '';
}

const Map<String, String> oculumElementAliases = <String, String>{
  'fisico': 'fisico',
  'physical': 'fisico',
  'normale': 'fisico',
  'normal': 'fisico',
  'neutral': 'fisico',
  'neutro': 'fisico',
  'taglio': 'taglio',
  'cutting': 'taglio',
  'lama': 'taglio',
  'blade': 'taglio',
  'slash': 'taglio',
  'lacerazione': 'taglio',
  'perforante': 'perforante',
  'piercing': 'perforante',
  'perforazione': 'perforante',
  'pierce': 'perforante',
  'punta': 'perforante',
  'contundente': 'contundente',
  'blunt': 'contundente',
  'botta': 'contundente',
  'impatto': 'contundente',
  'fuoco': 'fuoco',
  'fiamma': 'fuoco',
  'flame': 'fuoco',
  'bruciatura': 'fuoco',
  'burn': 'fuoco',
  'fire': 'fuoco',
  'gelo': 'gelo',
  'ghiaccio': 'gelo',
  'freddo': 'gelo',
  'frost': 'gelo',
  'cold': 'gelo',
  'ice': 'gelo',
  'acqua': 'acqua',
  'water': 'acqua',
  'fulmine': 'fulmine',
  'elettrico': 'fulmine',
  'electric': 'fulmine',
  'elettro': 'fulmine',
  'tuono': 'fulmine',
  'lightning': 'fulmine',
  'thunder': 'fulmine',
  'terra': 'terra',
  'earth': 'terra',
  'vento': 'vento',
  'wind': 'vento',
  'veleno': 'veleno',
  'tossico': 'veleno',
  'toxic': 'veleno',
  'toxin': 'veleno',
  'poison': 'veleno',
  'acido': 'acido',
  'corrosivo': 'acido',
  'corrosive': 'acido',
  'acid': 'acido',
  'oscuro': 'oscuro',
  'ombra': 'oscuro',
  'tenebra': 'oscuro',
  'dark': 'oscuro',
  'shadow': 'oscuro',
  'sacro': 'sacro',
  'holy': 'sacro',
  'luce': 'sacro',
  'santo': 'sacro',
  'saint': 'sacro',
  'light': 'sacro',
  'lunare': 'lunare',
  'lunar': 'lunare',
  'luna': 'lunare',
  'moon': 'lunare',
  'solare': 'solare',
  'solar': 'solare',
  'sole': 'solare',
  'sun': 'solare',
  'diabolico': 'diabolico',
  'diabolic': 'diabolico',
  'demoniaco': 'diabolico',
  'demon': 'diabolico',
  'demonic': 'diabolico',
  'angelico': 'angelico',
  'angelic': 'angelico',
  'angelo': 'angelico',
  'angel': 'angelico',
  'psichico': 'psichico',
  'psychic': 'psichico',
  'mentale': 'psichico',
  'mind': 'psichico',
  'psico': 'psichico',
  'psyche': 'psichico',
  'spirituale': 'spirituale',
  'spirit': 'spirituale',
  'necrotico': 'necrotico',
  'necrotic': 'necrotico',
  'necrosi': 'necrotico',
  'necrosis': 'necrotico',
  'morte': 'necrotico',
  'death': 'necrotico',
  'sangue': 'sangue',
  'blood': 'sangue',
  'magia': 'magia',
  'magic': 'magia',
  'energia': 'energia',
  'energy': 'energia',
  'esplosivo': 'esplosivo',
  'explosive': 'esplosivo',
  'esplosione': 'esplosivo',
  'sonoro': 'sonoro',
  'suono': 'sonoro',
  'sonico': 'sonoro',
  'sonic': 'sonoro',
  'sound': 'sonoro',
  'rumore': 'sonoro',
  'acustico': 'sonoro',
  'radiazione': 'radiazione',
  'radiation': 'radiazione',
  'plasma': 'plasma',
  'tecnologia': 'tecnologia',
  'technology': 'tecnologia',
  'tech': 'tecnologia',
  'proiettile': 'proiettile',
  'bullet': 'proiettile',
  'laser': 'laser',
  'gravita': 'gravita',
  'gravity': 'gravita',
  'tempo': 'tempo',
  'time': 'tempo',
  'spazio': 'spazio',
  'space': 'spazio',
  'vuoto': 'vuoto',
  'void': 'vuoto',
  'null': 'vuoto',
  'nullum': 'vuoto',
  'niente': 'vuoto',
  'nothing': 'vuoto',
  'caos': 'caos',
  'chaos': 'caos',
  'natura': 'natura',
  'nature': 'natura',
  'radice': 'radice',
  'root': 'radice',
  'flora': 'radice',
  'pianta': 'pianta',
  'plant': 'pianta',
  'bestiale': 'bestiale',
  'beast': 'bestiale',
  'maledizione': 'maledizione',
  'curse': 'maledizione',
  'benedizione': 'benedizione',
  'blessing': 'benedizione',
  'cura': 'cura',
  'healing': 'cura',
  'heal': 'cura',
  'vero': 'vero',
  'true': 'vero',
  'cenere': 'cenere',
  'ash': 'cenere',
  'osso': 'osso',
  'bone': 'osso',
  'cristallo': 'cristallo',
  'crystal': 'cristallo',
  'lava': 'lava',
  'vapium': 'vapium',
  'sogno': 'sogno',
  'dream': 'sogno',
  'metallo': 'metallo',
  'metal': 'metallo',
  'postea': 'postea',
  'slime': 'slime',
  'oculum': 'oculum',
  'stella': 'stella',
  'star': 'stella',
  'corrotto': 'corrotto',
  'corrotta': 'corrotto',
  'corrupted': 'corrotto',
  'nonmorto': 'nonmorto',
  'nonmorta': 'nonmorto',
  'undead': 'nonmorto',
  'sconosciuto': 'sconosciuto',
  'unknown': 'sconosciuto',
};

String oculumNormalizeElementId(String value) {
  final raw = oculumNormalizeText(value).replaceAll(' ', '');
  if (raw.isEmpty) return 'sconosciuto';
  return oculumElementAliases[raw] ?? raw;
}

String oculumElementDisplayIt(String idOrName) {
  switch (oculumNormalizeElementId(idOrName)) {
    case 'fisico':
      return 'Fisico';
    case 'taglio':
      return 'Taglio';
    case 'perforante':
      return 'Perforante';
    case 'contundente':
      return 'Contundente';
    case 'fuoco':
      return 'Fuoco';
    case 'gelo':
      return 'Gelo';
    case 'acqua':
      return 'Acqua';
    case 'fulmine':
      return 'Fulmine';
    case 'terra':
      return 'Terra';
    case 'vento':
      return 'Vento';
    case 'veleno':
      return 'Veleno';
    case 'acido':
      return 'Acido';
    case 'oscuro':
      return 'Oscuro';
    case 'sacro':
      return 'Sacro';
    case 'lunare':
      return 'Lunare';
    case 'solare':
      return 'Solare';
    case 'diabolico':
      return 'Diabolico';
    case 'angelico':
      return 'Angelico';
    case 'psichico':
      return 'Psichico';
    case 'spirituale':
      return 'Spirituale';
    case 'necrotico':
      return 'Necrotico';
    case 'sangue':
      return 'Sangue';
    case 'cenere':
      return 'Cenere';
    case 'osso':
      return 'Osso';
    case 'cristallo':
      return 'Cristallo';
    case 'lava':
      return 'Lava';
    case 'vapium':
      return 'Vapium';
    case 'sogno':
      return 'Sogno';
    case 'metallo':
      return 'Metallo';
    case 'postea':
      return 'Postea';
    case 'radice':
      return 'Radice';
    case 'slime':
      return 'Slime';
    case 'stella':
      return 'Stella';
    case 'corrotto':
      return 'Corrotto';
    case 'nonmorto':
      return 'Non morto';
    case 'magia':
      return 'Magia';
    case 'energia':
      return 'Energia';
    case 'esplosivo':
      return 'Esplosivo';
    case 'sonoro':
      return 'Sonoro';
    case 'radiazione':
      return 'Radiazione';
    case 'plasma':
      return 'Plasma';
    case 'tecnologia':
      return 'Tecnologia';
    case 'proiettile':
      return 'Proiettile';
    case 'laser':
      return 'Laser';
    case 'gravita':
      return 'Gravità';
    case 'tempo':
      return 'Tempo';
    case 'spazio':
      return 'Spazio';
    case 'vuoto':
      return 'Vuoto';
    case 'caos':
      return 'Caos';
    case 'natura':
      return 'Natura';
    case 'pianta':
      return 'Pianta';
    case 'bestiale':
      return 'Bestiale';
    case 'maledizione':
      return 'Maledizione';
    case 'benedizione':
      return 'Benedizione';
    case 'cura':
      return 'Cura';
    case 'vero':
      return 'Vero';
    case 'oculum':
      return 'Oculum';
    case 'sconosciuto':
      return 'Sconosciuto';
  }
  final clean = idOrName.trim();
  return clean.isEmpty ? 'Sconosciuto' : clean;
}

void oculumReconcileElementTotals(
  Map<String, int> result, {
  required int expectedTotal,
  required String fallbackElement,
}) {
  final target = max(0, expectedTotal);
  result.removeWhere((_, value) => value <= 0);

  var mapped = result.values.fold<int>(0, (sum, value) => sum + value);
  final fallback = oculumNormalizeElementId(fallbackElement);
  final delta = target - mapped;

  if (delta > 0) {
    result.update(
      fallback,
      (current) => current + delta,
      ifAbsent: () => delta,
    );
    return;
  }

  if (delta < 0) {
    var remaining = -delta;
    final orderedKeys = <String>[
      if (result.containsKey(fallback)) fallback,
      ...result.keys.where((key) => key != fallback).toList()
        ..sort((a, b) => (result[b] ?? 0).compareTo(result[a] ?? 0)),
    ];

    for (final key in orderedKeys) {
      if (remaining <= 0) break;
      final current = result[key] ?? 0;
      final taken = min(current, remaining);
      final next = current - taken;
      if (next <= 0) {
        result.remove(key);
      } else {
        result[key] = next;
      }
      remaining -= taken;
    }
  }

  result.removeWhere((_, value) => value <= 0);
  mapped = result.values.fold<int>(0, (sum, value) => sum + value);
  if (result.isEmpty && target > 0) {
    result[fallback] = target;
  } else if (mapped < target) {
    result.update(
      fallback,
      (current) => current + target - mapped,
      ifAbsent: () => target - mapped,
    );
  }
}

String oculumElementDisplayEn(String idOrName) {
  switch (oculumNormalizeElementId(idOrName)) {
    case 'fisico':
      return 'Physical';
    case 'taglio':
      return 'Slash';
    case 'perforante':
      return 'Piercing';
    case 'contundente':
      return 'Blunt';
    case 'fuoco':
      return 'Fire';
    case 'gelo':
      return 'Ice';
    case 'acqua':
      return 'Water';
    case 'fulmine':
      return 'Lightning';
    case 'terra':
      return 'Earth';
    case 'vento':
      return 'Wind';
    case 'veleno':
      return 'Poison';
    case 'acido':
      return 'Acid';
    case 'oscuro':
      return 'Shadow';
    case 'sacro':
      return 'Light';
    case 'lunare':
      return 'Moon';
    case 'solare':
      return 'Sun';
    case 'diabolico':
      return 'Demonic';
    case 'angelico':
      return 'Angelic';
    case 'psichico':
      return 'Psyche';
    case 'spirituale':
      return 'Spirit';
    case 'necrotico':
      return 'Necrotic';
    case 'sangue':
      return 'Blood';
    case 'cenere':
      return 'Ash';
    case 'osso':
      return 'Bone';
    case 'cristallo':
      return 'Crystal';
    case 'lava':
      return 'Lava';
    case 'vapium':
      return 'Vapium';
    case 'sogno':
      return 'Dream';
    case 'metallo':
      return 'Metal';
    case 'postea':
      return 'Postea';
    case 'radice':
      return 'Root';
    case 'slime':
      return 'Slime';
    case 'stella':
      return 'Star';
    case 'corrotto':
      return 'Corrupted';
    case 'nonmorto':
      return 'Undead';
    case 'magia':
      return 'Magic';
    case 'energia':
      return 'Energy';
    case 'esplosivo':
      return 'Explosive';
    case 'sonoro':
      return 'Sound';
    case 'radiazione':
      return 'Radiation';
    case 'plasma':
      return 'Plasma';
    case 'tecnologia':
      return 'Technology';
    case 'proiettile':
      return 'Bullet';
    case 'laser':
      return 'Laser';
    case 'gravita':
      return 'Gravity';
    case 'tempo':
      return 'Time';
    case 'spazio':
      return 'Space';
    case 'vuoto':
      return 'Void';
    case 'caos':
      return 'Chaos';
    case 'natura':
      return 'Nature';
    case 'pianta':
      return 'Plant';
    case 'bestiale':
      return 'Beast';
    case 'maledizione':
      return 'Curse';
    case 'benedizione':
      return 'Blessing';
    case 'cura':
      return 'Healing';
    case 'vero':
      return 'True';
    case 'oculum':
      return 'Oculum';
    case 'sconosciuto':
      return 'Unknown';
  }
  final clean = idOrName.trim();
  return clean.isEmpty ? 'Unknown' : clean;
}

const List<String> oculumDefaultElementIds = <String>[
  'fisico',
  'taglio',
  'perforante',
  'contundente',
  'fuoco',
  'vento',
  'acqua',
  'terra',
  'gelo',
  'sonoro',
  'psichico',
  'lava',
  'fulmine',
  'veleno',
  'cenere',
  'sangue',
  'cristallo',
  'oscuro',
  'lunare',
  'solare',
  'vapium',
  'osso',
  'gravita',
  'vuoto',
  'sogno',
  'metallo',
  'postea',
  'radice',
  'slime',
  'oculum',
  'stella',
  'corrotto',
  'nonmorto',
  'acido',
  'sacro',
  'diabolico',
  'angelico',
  'spirituale',
  'necrotico',
  'magia',
  'energia',
  'esplosivo',
  'radiazione',
  'plasma',
  'tecnologia',
  'proiettile',
  'laser',
  'tempo',
  'spazio',
  'caos',
  'natura',
  'pianta',
  'bestiale',
  'maledizione',
  'benedizione',
  'cura',
  'vero',
  'sconosciuto',
];

const List<String> oculumCommandAutocompleteLabels = <String>[
  '@Difesa',
  '@Danni',
  '@TypeSwitch',
  '@HP',
  '@HPAttuali',
  '@Vita',
  '@HPTemp',
  '@HPTempAttuali',
  '@Volonta',
  '@VolontaAttuale',
  '@Vol',
  '@Materia',
  '@MateriaAttuale',
  '@Oculum',
  '@OculumAttuale',
  '@Scudo',
  '@ScudoAttuale',
  '@ScudoOculum',
  '@ScudoOculumAttuale',
  '@Iniziativa',
  '@Movimento',
  '@TiroAttacco',
  '@TiroDifesa',
  '@TiroVC',
  '@TiroCM',
  '@TiroResilienza',
  '@TiroRes',
  '@TiroVolonta',
  '@TiroVolontà',
  '@TiroVol',
  '@TiroMateria',
  '@TiroMat',
  '@TiroOculum',
  '@TiroOcu',
  '@TiroStats',
  '@VC',
  '@CM',
  '@Stats',
  '@AllStats',
  '@OtherStats',
  '@AltreStats',
  '@Resilienza',
  '@ResilienzaAttuale',
  '@Mat',
  '@Ocu',
  '@Res',
];

String _oculumAutocompleteKey(String value) {
  return oculumNormalizeText(value).replaceAll(' ', '').replaceAll('@', '');
}

bool _oculumIsLatinLetter(String char) {
  if (char.isEmpty) return false;
  final code = char.codeUnitAt(0);
  return (code >= 0x41 && code <= 0x5A) ||
      (code >= 0x61 && code <= 0x7A) ||
      (code >= 0x00C0 && code <= 0x024F) ||
      (code >= 0x1E00 && code <= 0x1EFF);
}

String? oculumBestCommandCompletion(String fragment) {
  final query = _oculumAutocompleteKey(fragment);
  if (query.isEmpty) return null;

  for (final label in oculumCommandAutocompleteLabels) {
    final key = _oculumAutocompleteKey(label);
    if (key == query) return null;
    if (key.startsWith(query)) return label;
  }

  return null;
}

String? oculumBestElementCompletion(
  String fragment, {
  required bool linguaInglese,
}) {
  final query = _oculumAutocompleteKey(fragment);
  if (query.isEmpty) return null;

  var bestId = '';
  var bestScore = -1;

  for (final id in oculumDefaultElementIds) {
    final labels = <String>{
      id,
      oculumElementDisplayIt(id),
      oculumElementDisplayEn(id),
      for (final entry in oculumElementAliases.entries)
        if (entry.value == id) entry.key,
    };

    for (final label in labels) {
      final key = _oculumAutocompleteKey(label);
      if (key == query) return null;

      var score = 0;
      if (key.startsWith(query)) {
        score = 1000 - key.length;
      } else if (query.length >= 4) {
        final fuzzy = oculumSearchScore(query, key);
        if (fuzzy >= 120) score = fuzzy;
      }

      if (score > bestScore) {
        bestScore = score;
        bestId = id;
      }
    }
  }

  if (bestId.isEmpty || bestScore <= 0) return null;
  return linguaInglese
      ? oculumElementDisplayEn(bestId)
      : oculumElementDisplayIt(bestId);
}

bool oculumApplyCommandAutocomplete(
  TextEditingController controller, {
  required bool linguaInglese,
}) {
  final value = controller.value;
  final cursor = value.selection.baseOffset;
  final text = value.text;
  if (cursor < 0 || cursor > text.length) return false;

  void replaceRange(int start, int end, String replacement) {
    final nextText = text.replaceRange(start, end, replacement);
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
      composing: TextRange.empty,
    );
  }

  final beforeCursor = text.substring(0, cursor);
  final commandNameMatch = RegExp(
    r'@([^\s@+\-*/(),;]*)$',
  ).firstMatch(beforeCursor);

  if (commandNameMatch != null) {
    final completion = oculumBestCommandCompletion(
      commandNameMatch.group(1) ?? '',
    );
    if (completion != null) {
      replaceRange(commandNameMatch.start, cursor, completion);
      return true;
    }
  }

  final atIndex = beforeCursor.lastIndexOf('@');
  if (atIndex < 0) return false;

  final commandSegment = beforeCursor.substring(atIndex);
  final commandMatch = RegExp(
    r'^@([^\s@+\-*/(),;]+)\s*[+-]',
  ).firstMatch(commandSegment);
  final commandKey = oculumStatKey(commandMatch?.group(1) ?? '');
  if (commandKey != 'danni' && commandKey != 'difesa') return false;

  final elementMatch = RegExp(
    r'([^\d@+\-*/(),;]+)$',
  ).firstMatch(commandSegment);
  if (elementMatch == null) return false;

  final fragment = (elementMatch.group(1) ?? '').trim();
  if (fragment.isEmpty) return false;
  if (!fragment.contains(RegExp(r'\s')) && oculumStatKey(fragment).isNotEmpty) {
    return false;
  }

  final completion = oculumBestElementCompletion(
    fragment,
    linguaInglese: linguaInglese,
  );
  if (completion == null) return false;

  var start = atIndex + elementMatch.start;
  while (start < cursor && text[start].trim().isEmpty) {
    start++;
  }
  replaceRange(start, cursor, completion);
  return true;
}

class OculumDamagePart {
  const OculumDamagePart({required this.value, required this.elementId});
  final int value;
  final String elementId;
}

class OculumFormulaCommand {
  const OculumFormulaCommand({
    required this.key,
    required this.value,
    this.elementId = '',
    this.triggerRaw = '',
    this.valid = true,
    this.error = '',
  });
  final String key;
  final int value;
  final String elementId;
  final String triggerRaw;
  final bool valid;
  final String error;

  bool get hasTrigger => triggerRaw.trim().isNotEmpty;
}

class OculumEveryTriggerSpec {
  const OculumEveryTriggerSpec({
    required this.divisor,
    required this.sourceKey,
    required this.sourceRaw,
  });

  final int divisor;
  final String sourceKey;
  final String sourceRaw;
}

String oculumEventTriggerCanonical(String rawTrigger) {
  final normalized = oculumNormalizeFormulaTriggerText(rawTrigger);
  if (normalized.isEmpty) return '';

  switch (normalized) {
    case 'onhit':
    case 'adognicolpo':
    case 'ognicolpo':
    case 'quandocolpisci':
    case 'colpo':
      return 'OnHit';
    case 'oncrit':
    case 'critico':
    case 'sucritico':
    case 'quando critico':
    case 'quandocritico':
      return 'OnCrit';
    case 'onmaxcrit':
    case 'criticomassimo':
    case 'criticopositivo':
    case 'criticosuccesso':
    case 'sucriticomassimo':
    case 'sucriticopositivo':
      return 'OnMaxCrit';
    case 'on1crit':
    case 'ononecrit':
    case 'critico1':
    case 'criticouno':
    case 'criticonegativo':
    case 'fallimentocritico':
    case 'sucriticonegativo':
      return 'On1Crit';
    case 'onshieldbreaks':
    case 'onshieldbreak':
    case 'scudospezzato':
    case 'scudorotto':
    case 'quandoscudospezza':
    case 'quandosispezzaloscudo':
    case 'quandoscudorotto':
      return 'OnShieldBreaks';
  }

  return '';
}

({String expression, String triggerRaw}) oculumExtractEventTrigger(
  String rawExpression,
) {
  final expression = rawExpression.trim();
  if (expression.isEmpty) return (expression: expression, triggerRaw: '');

  final spacedMatch = RegExp(
    r'(?:^|\s)(ad\s+ogni\s+colpo|ogni\s+colpo|quando\s+colpisci|quando\s+critico|su\s+critico(?:\s+(?:massimo|positivo|negativo))?|critico\s+(?:massimo|positivo|negativo|uno|1)|fallimento\s+critico|scudo\s+(?:spezzato|rotto)|quando\s+(?:si\s+)?spezza\s+lo\s+scudo)$',
    caseSensitive: false,
  ).firstMatch(expression);
  if (spacedMatch != null) {
    final canonical = oculumEventTriggerCanonical(spacedMatch.group(1) ?? '');
    if (canonical.isNotEmpty) {
      return (
        expression: expression.substring(0, spacedMatch.start).trim(),
        triggerRaw: canonical,
      );
    }
  }

  final compactAliases = <String>[
    'OnShieldBreaks',
    'OnShieldBreak',
    'QuandoSiSpezzaLoScudo',
    'QuandoScudoSpezza',
    'QuandoScudoRotto',
    'ScudoSpezzato',
    'ScudoRotto',
    'OnMaxCrit',
    'CriticoMassimo',
    'CriticoPositivo',
    'CriticoSuccesso',
    'SuCriticoMassimo',
    'SuCriticoPositivo',
    'On1Crit',
    'OnOneCrit',
    'CriticoNegativo',
    'FallimentoCritico',
    'CriticoUno',
    'Critico1',
    'SuCriticoNegativo',
    'OnCrit',
    'QuandoCritico',
    'SuCritico',
    'Critico',
    'OnHit',
    'AdOgniColpo',
    'OgniColpo',
    'QuandoColpisci',
    'Colpo',
  ];

  for (final alias in compactAliases) {
    final pattern = RegExp('${RegExp.escape(alias)}\$', caseSensitive: false);
    final match = pattern.firstMatch(expression);
    if (match == null) continue;
    final canonical = oculumEventTriggerCanonical(match.group(0) ?? '');
    if (canonical.isEmpty) continue;
    return (
      expression: expression.substring(0, match.start).trim(),
      triggerRaw: canonical,
    );
  }

  return (expression: expression, triggerRaw: '');
}

({String key, String expression})? oculumSplitTrailingStatTarget(
  String rawExpression,
) {
  final expression = rawExpression.trim();
  if (expression.isEmpty) return null;

  var tailStart = expression.length;
  while (tailStart > 0 && _oculumIsLatinLetter(expression[tailStart - 1])) {
    tailStart--;
  }
  if (tailStart >= expression.length) return null;

  final tailWord = expression.substring(tailStart);
  for (var offset = 0; offset < tailWord.length; offset++) {
    final rawTarget = tailWord.substring(offset);
    final targetKey = oculumStatKey(rawTarget);
    if (targetKey.isEmpty) continue;

    final formula = expression.substring(0, tailStart + offset);
    if (formula.trim().isEmpty) continue;
    return (key: targetKey, expression: formula.trim());
  }

  return null;
}

String oculumEveryTriggerSourceKey(String rawSource) {
  final source = oculumNormalizeText(rawSource).replaceAll(' ', '');
  if (source.isEmpty) return '';

  String normalizeBase(String rawBase) {
    final base = rawBase.trim();
    if (base.isEmpty) return '';
    return oculumStatKey(base);
  }

  for (final suffix in const <String>[
    'sacrificati',
    'sacrificate',
    'sacrificato',
    'sacrificata',
    'consumati',
    'consumate',
    'consumato',
    'consumata',
    'spesi',
    'spese',
    'speso',
    'spesa',
    'persi',
    'perse',
    'perso',
    'persa',
    'usati',
    'usate',
    'usato',
    'usata',
  ]) {
    if (!source.endsWith(suffix)) continue;
    final baseKey = normalizeBase(
      source.substring(0, source.length - suffix.length),
    );
    if (baseKey.isNotEmpty) return '${baseKey}_spent';
  }

  for (final suffix in const <String>['totale', 'totali', 'total']) {
    if (!source.endsWith(suffix)) continue;
    final baseKey = normalizeBase(
      source.substring(0, source.length - suffix.length),
    );
    if (baseKey.isNotEmpty) return '${baseKey}_total';
  }

  for (final suffix in const <String>[
    'attuali',
    'attuale',
    'correnti',
    'corrente',
    'current',
  ]) {
    if (!source.endsWith(suffix)) continue;
    final baseKey = normalizeBase(
      source.substring(0, source.length - suffix.length),
    );
    if (baseKey.isEmpty) continue;
    if (baseKey.endsWith('_current')) return baseKey;
    return '${baseKey}_current';
  }

  return '';
}

OculumEveryTriggerSpec? oculumParseEveryTriggerSpec(String rawTrigger) {
  final normalized = oculumNormalizeFormulaTriggerText(rawTrigger);
  final match = RegExp(
    r'^(?:ogni|every)([0-9]+(?:[,.][0-9]+)?)([a-z_]+)$',
  ).firstMatch(normalized);
  if (match == null) return null;

  final divisorValue = double.tryParse(
    (match.group(1) ?? '1').replaceAll(',', '.'),
  );
  if (divisorValue == null || divisorValue <= 0) return null;
  final divisor = max(1, divisorValue.round());
  final sourceRaw = match.group(2) ?? '';
  final sourceKey = oculumEveryTriggerSourceKey(sourceRaw);
  if (sourceKey.isEmpty) return null;

  return OculumEveryTriggerSpec(
    divisor: divisor,
    sourceKey: sourceKey,
    sourceRaw: sourceRaw,
  );
}

const List<String> oculumBaseStatKeys = <String>[
  'resilienza',
  'volonta',
  'materia',
  'oculum',
];

const List<String> oculumBaseRollStatKeys = <String>[
  'tiro_resilienza',
  'tiro_volonta',
  'tiro_materia',
  'tiro_oculum',
];

String oculumBaseKeyForRollStat(String key) {
  return key.startsWith('tiro_') ? key.substring('tiro_'.length) : key;
}

String oculumObservationStatKey(String value, {bool allowEmpty = false}) {
  final key = oculumStatKey(value);
  if (oculumBaseStatKeys.contains(key)) return key;
  return allowEmpty ? '' : 'resilienza';
}

Map<String, int> oculumNormalizeObservationAssignedCounts(
  dynamic raw, {
  String legacyAssigned = '',
}) {
  final counts = <String, int>{for (final key in oculumBaseStatKeys) key: 0};

  void add(String rawKey, dynamic rawValue) {
    final key = oculumObservationStatKey(rawKey, allowEmpty: true);
    if (key.isEmpty) return;
    final value = max(0, readIntValue(rawValue));
    counts[key] = max(0, counts[key] ?? 0) + value;
  }

  if (raw is Map) {
    for (final entry in raw.entries) {
      add('${entry.key}', entry.value);
    }
  } else if (raw is List) {
    for (final entry in raw) {
      if (entry is Map) {
        add('${entry['stat'] ?? entry['key'] ?? ''}', entry['count'] ?? 1);
      }
    }
  }

  if (counts.values.every((value) => value <= 0)) {
    final legacyKey = oculumObservationStatKey(
      legacyAssigned,
      allowEmpty: true,
    );
    if (legacyKey.isNotEmpty) counts[legacyKey] = 1;
  }

  return counts;
}

int oculumObservationAssignedTotal(Map<String, int> assigned) {
  return assigned.values.fold<int>(0, (sum, value) => sum + max(0, value));
}

int oculumObservationTheoreticalPoints({
  required bool observed,
  required int level,
}) {
  if (!observed) return 0;
  return max(0, level);
}

int oculumObservationAvailablePoints({
  required bool observed,
  required int level,
  required Map<String, int> assigned,
}) {
  final theoretical = oculumObservationTheoreticalPoints(
    observed: observed,
    level: level,
  );
  return max(0, theoretical - oculumObservationAssignedTotal(assigned));
}

bool oculumIsGroupedStatKey(String key) {
  return key == 'stats' ||
      key == 'other_stats' ||
      key == 'tiro_stats' ||
      key == 'tiro_other_stats';
}

List<String> oculumGroupedFormulaTargetKeys(
  String key, {
  String triggerRaw = '',
}) {
  if (!oculumIsGroupedStatKey(key)) return <String>[key];
  final excluded = oculumExcludedStatsForTrigger(triggerRaw);
  final groupedKeys = key == 'tiro_stats' || key == 'tiro_other_stats'
      ? oculumBaseRollStatKeys
      : oculumBaseStatKeys;
  return <String>[
    for (final groupedKey in groupedKeys)
      if (!excluded.contains(groupedKey) &&
          !excluded.contains(oculumBaseKeyForRollStat(groupedKey)))
        groupedKey,
  ];
}

String oculumFormulaTriggerSourceKey(String rawTrigger) {
  final normalized = oculumNormalizeFormulaTriggerText(rawTrigger);
  if (normalized.isEmpty) return '';

  final keyThenDelta = RegExp(
    r'^([A-Za-zÀ-ÖØ-öø-ÿ_]+)([+-])(.+)$',
  ).firstMatch(normalized);
  if (keyThenDelta != null) {
    return oculumStatKey(keyThenDelta.group(1) ?? '');
  }

  final deltaThenKey = RegExp(
    r'^([+-])(.+?)([A-Za-zÀ-ÖØ-öø-ÿ_]+)$',
  ).firstMatch(normalized);
  if (deltaThenKey != null) {
    return oculumStatKey(deltaThenKey.group(3) ?? '');
  }

  return '';
}

Set<String> oculumExcludedStatsForTrigger(String rawTrigger) {
  final trimmed = rawTrigger.trim();
  if (trimmed.isEmpty) return const <String>{};

  // I trigger "ogni" hanno una sorgente normalizzata separata
  // (es. HPSpesi -> hp_spent, MatTotale -> materia_total).
  // Devono essere gestiti qui, prima dei trigger classici con =Stat-Numero,
  // altrimenti Stats/OtherStats puo ridare Resilienza da HP e creare loop.
  final everySpec = oculumParseEveryTriggerSpec(trimmed);
  if (everySpec != null) {
    var source = everySpec.sourceKey;
    final isSpent = source.endsWith('_spent');
    if (source.endsWith('_spent')) {
      source = source.substring(0, source.length - '_spent'.length);
    } else if (source.endsWith('_total')) {
      source = source.substring(0, source.length - '_total'.length);
    }

    // HP/Vita/PV non devono mai rigenerare Resilienza tramite Stats,
    // perche Resilienza aumenta gli HP e puo causare ricorsione/StackOverflow.
    if (source == 'hp' || source == 'hp_temp') return {'resilienza'};

    // Se una statistica base viene spesa/consumata/sacrificata, non ridarla
    // nello stesso comando raggruppato: Volonta spesa non puo ridare Volonta,
    // Materia spesa non puo ridare Materia, Oculum speso non puo ridare
    // Oculum. I trigger _total invece sono soglie, non costi.
    if (isSpent && oculumBaseStatKeys.contains(source)) return {source};
    return const <String>{};
  }

  final source = oculumFormulaTriggerSourceKey(trimmed);
  if (source == 'hp' || source == 'hp_temp') return {'resilienza'};
  if (oculumBaseStatKeys.contains(source)) return {source};
  return const <String>{};
}

List<OculumFormulaCommand> oculumExpandGroupedFormulaCommand(
  OculumFormulaCommand command,
) {
  if (!command.valid || !oculumIsGroupedStatKey(command.key)) {
    return <OculumFormulaCommand>[command];
  }

  return [
    for (final key in oculumGroupedFormulaTargetKeys(
      command.key,
      triggerRaw: command.triggerRaw,
    ))
      OculumFormulaCommand(
        key: key,
        value: command.value,
        elementId: command.elementId,
        triggerRaw: command.triggerRaw,
        valid: command.valid,
        error: command.error,
      ),
  ];
}

const int oculumVcWillMultiplier = 3;
const int oculumCmMateriaMultiplier = 2;

OculumFormulaCommand oculumEffectiveFormulaCommand(
  OculumFormulaCommand command,
) {
  if (!command.valid) return command;

  switch (command.key) {
    case 'vc':
      return OculumFormulaCommand(
        key: 'volonta',
        value: command.value * oculumVcWillMultiplier,
        elementId: command.elementId,
        triggerRaw: command.triggerRaw,
        valid: command.valid,
        error: command.error,
      );
    case 'cm':
      return OculumFormulaCommand(
        key: 'materia',
        value: command.value * oculumCmMateriaMultiplier,
        elementId: command.elementId,
        triggerRaw: command.triggerRaw,
        valid: command.valid,
        error: command.error,
      );
    default:
      return command;
  }
}

List<OculumFormulaCommand> oculumParseEffectiveFormulaCommands(
  String text,
  Map<String, num> vars,
) {
  return oculumParseFormulaCommands(
    text,
    vars,
  ).map(oculumEffectiveFormulaCommand).toList();
}

class _OculumToken {
  const _OculumToken(this.type, this.text, this.number);
  final String type;
  final String text;
  final double number;
}

class _OculumFormulaParser {
  _OculumFormulaParser(this.tokens, this.vars);
  final List<_OculumToken> tokens;
  final Map<String, num> vars;
  int pos = 0;

  bool get atEnd => pos >= tokens.length;
  _OculumToken? get current => atEnd ? null : tokens[pos];

  double parse() {
    final value = parseExpression();
    if (!atEnd) throw const FormatException('Token non valido nella formula.');
    if (value.isNaN || value.isInfinite) {
      throw const FormatException('Risultato impossibile.');
    }
    return value;
  }

  double parseExpression() {
    var value = parseTerm();
    while (!atEnd && (current!.text == '+' || current!.text == '-')) {
      final op = current!.text;
      pos++;
      final rhs = parseTerm();
      value = op == '+' ? value + rhs : value - rhs;
    }
    return value;
  }

  double parseTerm() {
    var value = parseFactor();
    while (!atEnd && (current!.text == '*' || current!.text == '/')) {
      final op = current!.text;
      pos++;
      final rhs = parseFactor();
      if (op == '/' && rhs == 0) {
        throw const FormatException('Divisione per zero non permessa.');
      }
      value = op == '*' ? value * rhs : value / rhs;
    }
    return value;
  }

  double parseFactor() {
    if (atEnd) throw const FormatException('Formula incompleta.');
    final tok = current!;
    if (tok.text == '+') {
      pos++;
      return parseFactor();
    }
    if (tok.text == '-') {
      pos++;
      return -parseFactor();
    }
    if (tok.text == '(') {
      pos++;
      final value = parseExpression();
      if (atEnd || current!.text != ')') {
        throw const FormatException('Parentesi non chiusa.');
      }
      pos++;
      return value;
    }
    if (tok.type == 'number') {
      pos++;
      return tok.number;
    }
    if (tok.type == 'variable') {
      pos++;
      final key = oculumStatKey(tok.text);
      if (key.isEmpty || !vars.containsKey(key)) {
        throw FormatException('Variabile sconosciuta: ${tok.text}.');
      }
      return (vars[key] ?? 0).toDouble();
    }
    throw FormatException('Token non valido: ${tok.text}.');
  }
}

List<_OculumToken> _oculumTokenizeFormula(String input) {
  final tokens = <_OculumToken>[];
  var i = 0;
  bool prevCanMultiply = false;

  void addToken(_OculumToken token) {
    final nextCanStartValue =
        token.type == 'number' || token.type == 'variable' || token.text == '(';
    if (prevCanMultiply && nextCanStartValue) {
      tokens.add(const _OculumToken('op', '*', 0));
    }
    tokens.add(token);
    prevCanMultiply =
        token.type == 'number' || token.type == 'variable' || token.text == ')';
  }

  while (i < input.length) {
    final ch = input[i];
    if (ch.trim().isEmpty) {
      i++;
      continue;
    }
    if ('+-*/()'.contains(ch)) {
      addToken(_OculumToken('op', ch, 0));
      if (ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '(') {
        prevCanMultiply = ch == ')';
      }
      i++;
      continue;
    }
    final unicodeFraction = _oculumUnicodeFractionValue(ch);
    if (unicodeFraction != null) {
      addToken(_OculumToken('number', ch, unicodeFraction));
      i++;
      continue;
    }
    const unicodeFractions = <String, double>{
      '⅓': 1 / 3,
      '⅔': 2 / 3,
      '¼': 1 / 4,
      '½': 1 / 2,
      '¾': 3 / 4,
      '⅕': 1 / 5,
      '⅖': 2 / 5,
      '⅗': 3 / 5,
      '⅘': 4 / 5,
    };
    if (unicodeFractions.containsKey(ch)) {
      addToken(_OculumToken('number', ch, unicodeFractions[ch]!));
      i++;
      continue;
    }
    if (RegExp(r'[0-9.,]').hasMatch(ch)) {
      final start = i;
      while (i < input.length && RegExp(r'[0-9.,]').hasMatch(input[i])) {
        i++;
      }
      var raw = input.substring(start, i).replaceAll(',', '.');
      final number = double.tryParse(raw);
      if (number == null) throw FormatException('Numero non valido: $raw.');
      if (i < input.length && input[i] == '%') {
        i++;
        addToken(_OculumToken('number', '$raw%', number / 100));
      } else {
        addToken(_OculumToken('number', raw, number));
      }
      continue;
    }
    if (_oculumIsLatinLetter(ch)) {
      final start = i;
      while (i < input.length && _oculumIsLatinLetter(input[i])) {
        i++;
      }
      addToken(_OculumToken('variable', input.substring(start, i), 0));
      continue;
    }
    throw FormatException('Carattere non valido: $ch.');
  }
  return tokens;
}

double oculumEvaluateFormula(String raw, Map<String, num> vars) {
  final text = raw.trim();
  if (text.isEmpty) throw const FormatException('Formula vuota.');
  if (text.length > 80) throw const FormatException('Formula troppo lunga.');
  final tokens = _oculumTokenizeFormula(text);
  if (tokens.isEmpty) throw const FormatException('Formula vuota.');
  final result = _OculumFormulaParser(tokens, vars).parse();
  if (result.abs() > 999999) {
    throw const FormatException('Risultato troppo grande.');
  }
  return result;
}

int oculumRoundFormulaResult(double value) {
  if (value == 0) return 0;
  final rounded = value.round();
  if (rounded != 0) return rounded;
  return value > 0 ? 1 : -1;
}

double? oculumStandalonePercentage(String raw) {
  final match = RegExp(r'^([0-9]+(?:[,.][0-9]+)?)\s*%$').firstMatch(raw.trim());
  if (match == null) return null;
  final value = double.tryParse((match.group(1) ?? '').replaceAll(',', '.'));
  if (value == null) return null;
  return value / 100;
}

double oculumEvaluateCommandFormula(
  String raw, {
  required String targetKey,
  required Map<String, num> vars,
}) {
  final percentage = oculumStandalonePercentage(raw);
  if (percentage == null) return oculumEvaluateFormula(raw, vars);
  final base = vars[targetKey];
  if (base == null) {
    throw FormatException('Percentuale senza base disponibile per $targetKey.');
  }
  return base.toDouble() * percentage;
}

String? oculumSplitTrailingElement(
  String rawExpression,
  Map<String, num> vars,
) {
  final expression = rawExpression.trim();
  if (expression.isEmpty) return null;

  final parts = expression
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.length > 1) {
    for (var suffixStart = 1; suffixStart < parts.length; suffixStart++) {
      final suffix = parts.skip(suffixStart).join(' ').trim();
      if (!RegExp(
        r'^[^\s\d+\-*/().,;@%]+(?:\s+[^\s\d+\-*/().,;@%]+)*$',
      ).hasMatch(suffix)) {
        continue;
      }
      if (oculumStatKey(suffix).isNotEmpty) continue;

      final before = parts.take(suffixStart).join(' ');
      try {
        oculumEvaluateFormula(before, vars);
        return suffix;
      } catch (_) {
        final normalizedSuffix = oculumNormalizeText(
          suffix,
        ).replaceAll(' ', '');
        if (oculumElementAliases.containsKey(normalizedSuffix)) return suffix;
        // Prova un suffisso piu corto o il caso compatto, ad esempio Vol/2Fuoco.
      }
    }
  }

  final tailWordMatch = RegExp(r'[^\s\d+\-*/().,;@%]+$').firstMatch(expression);
  if (tailWordMatch == null) return null;

  final tailWord = tailWordMatch.group(0) ?? '';
  if (oculumStatKey(tailWord).isNotEmpty) return null;

  final aliases =
      oculumElementAliases.keys.where((alias) => alias.length >= 3).toList()
        ..sort((a, b) => b.length.compareTo(a.length));

  for (final alias in aliases) {
    for (var offset = 0; offset < tailWord.length; offset++) {
      final suffix = tailWord.substring(offset);
      if (oculumNormalizeText(suffix).replaceAll(' ', '') != alias) continue;

      final formula = expression.substring(0, tailWordMatch.start + offset);
      if (formula.trim().isEmpty) continue;

      try {
        oculumEvaluateFormula(formula, vars);
        return suffix;
      } catch (_) {
        if (oculumElementAliases.containsKey(alias)) return suffix;
        // Prova un suffisso piu corto o un altro alias conosciuto.
      }
    }
  }

  // Fallback per elementi sconosciuti nei casi compatti semplici:
  // 13TipoIgnoto resta un danno valido con tipo ripulito.
  final compact = RegExp(
    r'^([0-9]+(?:[,.][0-9]+)?|[¼½¾⅓⅔⅕⅖⅗⅘])\s*([^\s\d+\-*/().,;@%]+)$',
  ).firstMatch(expression);
  if (compact != null) {
    final word = compact.group(2) ?? '';
    if (oculumStatKey(word).isEmpty) return word;
  }

  return null;
}

List<OculumFormulaCommand> oculumParseFormulaCommands(
  String text,
  Map<String, num> vars,
) {
  final out = <OculumFormulaCommand>[];
  if (text.trim().isEmpty) return out;
  final decimalNormalizedText = text.replaceAllMapped(
    RegExp(r'([0-9]),(?=[0-9])'),
    (match) => '${match.group(1)}.',
  );
  final normalizedText = decimalNormalizedText.replaceAllMapped(
    RegExp(
      r'@([A-Za-zÀ-ÖØ-öø-ÿ_]+)\s*([+-])\s*([^@,;\n=]+?)\s*=\s*(Stats|AllStats|OtherStats|AltreStats|TiroStats|TiroAllStats|TiriStats|TiroStatistiche|TiriStatistiche|TiroOtherStats|TiroAltreStats|TiriAltreStats)\s*([+-])\s*([^@,;\n]+)',
      caseSensitive: false,
    ),
    (match) {
      final sourceKey = match.group(1) ?? '';
      final sourceSign = match.group(2) ?? '-';
      final sourceAmount = (match.group(3) ?? '').trim();
      final targetKey = match.group(4) ?? 'Stats';
      final targetSign = match.group(5) ?? '+';
      final targetAmount = (match.group(6) ?? '').trim();
      return '@$targetKey$targetSign$targetAmount=$sourceKey$sourceSign$sourceAmount';
    },
  );
  final regex = RegExp(
    r'@([^\s@,+\-*/();=]+)\s*([+-])\s*([^@,;\n]+?)(?=$|[@,;\n]|\s+[A-Za-zÀ-ÖØ-öø-ÿ_]+[+-])|\b([A-Za-zÀ-ÖØ-öø-ÿ_]+)([+-])([^@\s,;\n]+(?:\s+[^\s@,;\n]+)?)',
  );
  for (final match in regex.allMatches(normalizedText)) {
    final rawKeyText = match.group(1) ?? match.group(4) ?? '';
    var key = oculumStatKey(rawKeyText);
    var sign = (match.group(2) ?? match.group(5)) == '-' ? -1 : 1;
    var expression = (match.group(3) ?? match.group(6) ?? '').trim();
    var element = '';
    var triggerRaw = '';

    if (key.isEmpty) {
      final prefixTrigger = oculumEventTriggerCanonical(rawKeyText);
      final target = prefixTrigger.isEmpty
          ? null
          : oculumSplitTrailingStatTarget(expression);
      if (target == null) continue;
      key = target.key;
      expression = target.expression;
      triggerRaw = prefixTrigger;
    }

    final triggerIndex = expression.indexOf('=');
    if (triggerIndex >= 0) {
      triggerRaw = expression.substring(triggerIndex + 1).trim();
      expression = expression.substring(0, triggerIndex).trim();

      final groupedTarget = RegExp(
        r'^([A-Za-zÀ-ÖØ-öø-ÿ_]+)([+-])(.+)$',
      ).firstMatch(triggerRaw.replaceAll(RegExp(r'\s+'), ''));
      final groupedTargetKey = groupedTarget == null
          ? ''
          : oculumStatKey(groupedTarget.group(1) ?? '');
      if (oculumIsGroupedStatKey(groupedTargetKey)) {
        final leftSign = sign < 0 ? '-' : '+';
        triggerRaw = '$rawKeyText$leftSign$expression';
        key = groupedTargetKey;
        sign = (groupedTarget?.group(2) ?? '+') == '-' ? -1 : 1;
        expression = groupedTarget?.group(3) ?? '0';
      }
    }

    if (triggerRaw.isEmpty) {
      final eventTrigger = oculumExtractEventTrigger(expression);
      if (eventTrigger.triggerRaw.isNotEmpty) {
        triggerRaw = eventTrigger.triggerRaw;
        expression = eventTrigger.expression;
      }
    }

    if (triggerRaw.isEmpty) {
      final everyMatch = RegExp(
        r'(?:^|\s)(ogni|every)\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(expression);
      if (everyMatch != null) {
        final before = expression.substring(0, everyMatch.start).trim();
        var everyTrigger = expression.substring(everyMatch.start).trim();
        if (before.isNotEmpty &&
            oculumParseEveryTriggerSpec(everyTrigger) != null) {
          // Normalize trigger by adding space between number and word if missing
          everyTrigger = everyTrigger.replaceFirstMapped(
            RegExp(
              r'^((?:ogni|every)\s+\d+(?:[,.]\d+)?)([a-zA-Z_]+)',
              caseSensitive: false,
            ),
            (match) => '${match.group(1)} ${match.group(2)}',
          );
          triggerRaw = everyTrigger;
          expression = before;
        }
      }
    }

    if (key == 'danni' || key == 'difesa') {
      final trailing = oculumSplitTrailingElement(expression, vars);
      if (trailing != null && trailing.trim().isNotEmpty) {
        element = oculumNormalizeElementId(trailing);
        expression = expression
            .substring(0, expression.length - trailing.length)
            .trim();
      }
      final compact = RegExp(
        r'^([0-9]+(?:[,.][0-9]+)?|[¼½¾⅓⅔⅕⅖⅗⅘])\s*([^\s\d+\-*/().,;@%]+)$',
      ).firstMatch(expression);
      if (compact != null && oculumStatKey(compact.group(2) ?? '').isEmpty) {
        expression = compact.group(1) ?? expression;
        element = oculumNormalizeElementId(compact.group(2) ?? '');
      }
    }
    final standalonePercentage = oculumStandalonePercentage(expression);
    if (standalonePercentage != null && oculumIsGroupedStatKey(key)) {
      for (final targetKey in oculumGroupedFormulaTargetKeys(
        key,
        triggerRaw: triggerRaw,
      )) {
        final base = vars[targetKey];
        if (base == null) {
          out.add(
            OculumFormulaCommand(
              key: targetKey,
              value: 0,
              elementId: element,
              triggerRaw: triggerRaw,
              valid: false,
              error: 'Percentuale senza base disponibile per $targetKey.',
            ),
          );
          continue;
        }
        out.add(
          OculumFormulaCommand(
            key: targetKey,
            value: oculumRoundFormulaResult(
              base.toDouble() * standalonePercentage * sign,
            ),
            elementId: element,
            triggerRaw: triggerRaw,
            valid: true,
          ),
        );
      }
      continue;
    }

    try {
      final value =
          oculumEvaluateCommandFormula(expression, targetKey: key, vars: vars) *
          sign;
      if (value.isNaN || value.isInfinite) {
        out.addAll(
          oculumExpandGroupedFormulaCommand(
            OculumFormulaCommand(
              key: key,
              value: 0,
              elementId: element,
              triggerRaw: triggerRaw,
              valid: false,
              error: 'Risultato impossibile.',
            ),
          ),
        );
      } else {
        out.addAll(
          oculumExpandGroupedFormulaCommand(
            OculumFormulaCommand(
              key: key,
              value: oculumRoundFormulaResult(value),
              elementId: element,
              triggerRaw: triggerRaw,
              valid: true,
            ),
          ),
        );
      }
    } catch (error) {
      out.addAll(
        oculumExpandGroupedFormulaCommand(
          OculumFormulaCommand(
            key: key,
            value: 0,
            elementId: element,
            triggerRaw: triggerRaw,
            valid: false,
            error: '$error',
          ),
        ),
      );
    }
  }
  return out;
}
