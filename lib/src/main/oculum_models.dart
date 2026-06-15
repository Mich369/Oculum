part of '../../main.dart';

// MODELLI BASE
// =====================================================

class ColorOption {
  const ColorOption({
    required this.name,
    required this.category,
    required this.color,
  });

  final String name;
  final String category;
  final Color color;
}

class OculumColorPreset {
  const OculumColorPreset({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descriptionIt,
    required this.descriptionEn,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.utility,
    required this.oculumFormula,
    required this.backgroundTop,
    required this.backgroundMid,
    required this.backgroundBottom,
    required this.eyePupilGlow,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descriptionIt;
  final String descriptionEn;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color utility;
  final Color oculumFormula;
  final Color backgroundTop;
  final Color backgroundMid;
  final Color backgroundBottom;
  final Color eyePupilGlow;
}

class DamageModifierOption {
  const DamageModifierOption({
    required this.name,
    required this.multiplier,
    required this.descriptionIt,
    required this.descriptionEn,
  });

  final String name;

  /// 1.00 = danno normale
  /// 0.90 = -10%
  /// 0.00 = immunità
  /// -0.10 = rigenera 10%
  /// 1.50 = +50%
  final double multiplier;

  final String descriptionIt;
  final String descriptionEn;
}

class ManualSection {
  const ManualSection({
    required this.titleIt,
    required this.titleEn,
    required this.contentIt,
    required this.contentEn,
  });

  final String titleIt;
  final String titleEn;
  final String contentIt;
  final String contentEn;
}

class ConditionalBuffEntry {
  ConditionalBuffEntry({
    this.nome = '',
    this.descrizione = '',
    this.condizione = '',
    this.resilienza = 0,
    this.volonta = 0,
    this.materia = 0,
    this.oculum = 0,
    this.karma = 0,
    this.attivo = false,
  });

  String nome;
  String descrizione;
  String condizione;

  int resilienza;
  int volonta;
  int materia;
  int oculum;
  int karma;

  bool attivo;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descrizione': descrizione,
      'condizione': condizione,
      'resilienza': resilienza,
      'volonta': volonta,
      'materia': materia,
      'oculum': oculum,
      'karma': karma,
      'attivo': attivo,
    };
  }

  factory ConditionalBuffEntry.fromJson(Map<String, dynamic> json) {
    return ConditionalBuffEntry(
      nome: json['nome'] ?? '',
      descrizione: json['descrizione'] ?? '',
      condizione: json['condizione'] ?? '',
      resilienza: readIntValue(json['resilienza']),
      volonta: readIntValue(json['volonta']),
      materia: readIntValue(json['materia']),
      oculum: readIntValue(json['oculum']),
      karma: readIntValue(json['karma']),
      attivo: readBoolValue(json['attivo']),
    );
  }
}

class TitleOpenEntry {
  TitleOpenEntry({
    this.nome = '',
    this.descrizione = '',
    this.openBuff = '',
    this.openSkill = '',
    this.attiva = false,
    List<ConditionalBuffEntry>? conditionalBuffs,
  }) {
    this.conditionalBuffs = conditionalBuffs ?? [];
  }

  String nome;
  String descrizione;
  String openBuff;
  String openSkill;
  bool attiva;

  late List<ConditionalBuffEntry> conditionalBuffs;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descrizione': descrizione,
      'openBuff': openBuff,
      'openSkill': openSkill,
      'attiva': attiva,
      'conditionalBuffs': conditionalBuffs.map((x) => x.toJson()).toList(),
    };
  }

  factory TitleOpenEntry.fromJson(Map<String, dynamic> json) {
    return TitleOpenEntry(
      nome: json['nome'] ?? '',
      descrizione: json['descrizione'] ?? '',
      openBuff: json['openBuff'] ?? '',
      openSkill: json['openSkill'] ?? '',
      attiva: readBoolValue(json['attiva']),
      conditionalBuffs: ((json['conditionalBuffs'] ?? []) as List)
          .map(
            (x) => ConditionalBuffEntry.fromJson(Map<String, dynamic>.from(x)),
          )
          .toList(),
    );
  }
}

class TitleExtraSkillEntry {
  TitleExtraSkillEntry({this.nome = '', this.descrizione = ''});

  String nome;
  String descrizione;

  Map<String, dynamic> toJson() {
    return {'nome': nome, 'descrizione': descrizione};
  }

  factory TitleExtraSkillEntry.fromJson(Map<String, dynamic> json) {
    return TitleExtraSkillEntry(
      nome: json['nome'] ?? '',
      descrizione: json['descrizione'] ?? '',
    );
  }
}

class OculumTitle {
  OculumTitle({
    required this.nome,
    required this.tipo,
    required this.ottenimento,
    required this.buff,
    required this.puntoCieco,
    required this.skill,
    required this.richiede,
    this.resilienza = 0,
    this.volonta = 0,
    this.materia = 0,
    this.oculum = 0,
    this.karma = 0,
    this.equipaggiato = false,
    this.evoluto = false,
    this.openName = '',
    this.openDescription = '',
    this.openBuff = '',
    this.openSkill = '',
    this.openAttiva = false,
    this.chiaveSistema = '',
    List<TitleOpenEntry>? openExtra,
    List<TitleExtraSkillEntry>? skillExtra,
    List<ConditionalBuffEntry>? titleConditionalBuffs,
    List<ConditionalBuffEntry>? openConditionalBuffs,
  }) {
    this.openExtra = openExtra ?? [];
    this.skillExtra = skillExtra ?? [];
    this.titleConditionalBuffs = titleConditionalBuffs ?? [];
    this.openConditionalBuffs = openConditionalBuffs ?? [];
  }

  String nome;
  String tipo;
  String ottenimento;
  String buff;
  String puntoCieco;
  String skill;
  String richiede;

  int resilienza;
  int volonta;
  int materia;
  int oculum;
  int karma;

  bool equipaggiato;
  bool evoluto;

  String openName;
  String openDescription;
  String openBuff;
  String openSkill;
  bool openAttiva;
  String chiaveSistema;

  late List<TitleOpenEntry> openExtra;
  late List<TitleExtraSkillEntry> skillExtra;
  late List<ConditionalBuffEntry> titleConditionalBuffs;
  late List<ConditionalBuffEntry> openConditionalBuffs;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'tipo': tipo,
      'ottenimento': ottenimento,
      'buff': buff,
      'puntoCieco': puntoCieco,
      'skill': skill,
      'richiede': richiede,
      'resilienza': resilienza,
      'volonta': volonta,
      'materia': materia,
      'oculum': oculum,
      'karma': karma,
      'equipaggiato': equipaggiato,
      'evoluto': evoluto,
      'openName': openName,
      'openDescription': openDescription,
      'openBuff': openBuff,
      'openSkill': openSkill,
      'openAttiva': openAttiva,
      'chiaveSistema': chiaveSistema,
      'openExtra': openExtra.map((x) => x.toJson()).toList(),
      'skillExtra': skillExtra.map((x) => x.toJson()).toList(),
      'titleConditionalBuffs': titleConditionalBuffs
          .map((x) => x.toJson())
          .toList(),
      'openConditionalBuffs': openConditionalBuffs
          .map((x) => x.toJson())
          .toList(),
    };
  }

  factory OculumTitle.fromJson(Map<String, dynamic> json) {
    return OculumTitle(
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      ottenimento: json['ottenimento'] ?? '',
      buff: json['buff'] ?? '',
      puntoCieco: json['puntoCieco'] ?? '',
      skill: json['skill'] ?? '',
      richiede: json['richiede'] ?? '',
      resilienza: readIntValue(json['resilienza']),
      volonta: readIntValue(json['volonta']),
      materia: readIntValue(json['materia']),
      oculum: readIntValue(json['oculum']),
      karma: readIntValue(json['karma']),
      equipaggiato: readBoolValue(json['equipaggiato']),
      evoluto: readBoolValue(json['evoluto']),
      openName: json['openName'] ?? '',
      openDescription: json['openDescription'] ?? '',
      openBuff: json['openBuff'] ?? '',
      openSkill: json['openSkill'] ?? '',
      openAttiva: readBoolValue(json['openAttiva']),
      chiaveSistema: json['chiaveSistema'] ?? '',
      openExtra: ((json['openExtra'] ?? []) as List)
          .map((x) => TitleOpenEntry.fromJson(Map<String, dynamic>.from(x)))
          .toList(),
      skillExtra: ((json['skillExtra'] ?? []) as List)
          .map(
            (x) => TitleExtraSkillEntry.fromJson(Map<String, dynamic>.from(x)),
          )
          .toList(),
      titleConditionalBuffs: ((json['titleConditionalBuffs'] ?? []) as List)
          .map(
            (x) => ConditionalBuffEntry.fromJson(Map<String, dynamic>.from(x)),
          )
          .toList(),
      openConditionalBuffs: ((json['openConditionalBuffs'] ?? []) as List)
          .map(
            (x) => ConditionalBuffEntry.fromJson(Map<String, dynamic>.from(x)),
          )
          .toList(),
    );
  }
}

class InventoryItem {
  InventoryItem({
    required this.nome,
    required this.peso,
    required this.quantita,
    required this.note,
    this.buff = '',
    this.arma = false,
    this.protegge = false,
    this.equipaggiata = false,
    this.bonusDanno = 0,
    this.bonusDifesa = 0,
    this.bonusScudo = 0,
    this.elementoDanno = 'Fisico',
  });

  String nome;
  double peso;
  int quantita;
  String note;
  String buff;
  bool arma;
  bool protegge;
  bool equipaggiata;
  int bonusDanno;
  int bonusDifesa;
  int bonusScudo;
  String elementoDanno;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'peso': peso,
      'quantita': quantita,
      'note': note,
      'buff': buff,
      'arma': arma,
      'protegge': protegge,
      'equipaggiata': equipaggiata,
      'bonusDanno': bonusDanno,
      'bonusDifesa': bonusDifesa,
      'bonusScudo': bonusScudo,
      'elementoDanno': elementoDanno,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      nome: json['nome'] ?? '',
      peso: readDoubleValue(json['peso']),
      quantita: readIntValue(json['quantita'], fallback: 1),
      note: json['note'] ?? '',
      buff: json['buff'] ?? '',
      arma: readBoolValue(json['arma']),
      protegge: readBoolValue(json['protegge']),
      equipaggiata: readBoolValue(json['equipaggiata']),
      bonusDanno: readIntValue(json['bonusDanno']),
      bonusDifesa: readIntValue(json['bonusDifesa']),
      bonusScudo: readIntValue(json['bonusScudo']),
      elementoDanno:
          '${json['elementoDanno'] ?? json['tipoDanno'] ?? 'Fisico'}',
    );
  }
}

class CharacterSkillForm {
  CharacterSkillForm({
    this.nome = '',
    this.tipo = '',
    this.livello = '',
    this.costo = '',
    this.cooldown = '',
    this.descrizione = '',
    this.effetto = '',
    this.buff = '',
    this.danni = '',
    this.cura = '',
    this.difesa = '',
    this.note = '',
  });

  String nome;
  String tipo;
  String livello;
  String costo;
  String cooldown;
  String descrizione;
  String effetto;
  String buff;
  String danni;
  String cura;
  String difesa;
  String note;

  Iterable<String> quickCommandTexts() sync* {
    yield nome;
    yield tipo;
    yield livello;
    yield costo;
    yield cooldown;
    yield descrizione;
    yield effetto;
    yield buff;
    yield danni;
    yield cura;
    yield difesa;
    yield note;
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'tipo': tipo,
      'livello': livello,
      'costo': costo,
      'cooldown': cooldown,
      'descrizione': descrizione,
      'effetto': effetto,
      'buff': buff,
      'danni': danni,
      'cura': cura,
      'difesa': difesa,
      'note': note,
    };
  }

  factory CharacterSkillForm.fromLegacy({
    required String nome,
    required String tipo,
    required String costo,
    required String cooldown,
    required String descrizione,
  }) {
    return CharacterSkillForm(
      nome: nome,
      tipo: tipo,
      costo: costo,
      cooldown: cooldown,
      descrizione: descrizione,
    );
  }

  factory CharacterSkillForm.fromJson(Map<String, dynamic> json) {
    return CharacterSkillForm(
      nome: '${json['nome'] ?? json['name'] ?? ''}',
      tipo: '${json['tipo'] ?? json['type'] ?? ''}',
      livello: '${json['livello'] ?? json['level'] ?? ''}',
      costo: '${json['costo'] ?? json['cost'] ?? ''}',
      cooldown: '${json['cooldown'] ?? ''}',
      descrizione: '${json['descrizione'] ?? json['description'] ?? ''}',
      effetto: '${json['effetto'] ?? json['effect'] ?? ''}',
      buff: '${json['buff'] ?? json['comando'] ?? json['command'] ?? ''}',
      danni: '${json['danni'] ?? json['damage'] ?? ''}',
      cura: '${json['cura'] ?? json['heal'] ?? ''}',
      difesa: '${json['difesa'] ?? json['defense'] ?? ''}',
      note: '${json['note'] ?? json['notes'] ?? ''}',
    );
  }

  void fillMissingFromLegacy({
    required String nome,
    required String tipo,
    required String costo,
    required String cooldown,
    required String descrizione,
  }) {
    if (this.nome.trim().isEmpty) this.nome = nome;
    if (this.tipo.trim().isEmpty) this.tipo = tipo;
    if (this.costo.trim().isEmpty) this.costo = costo;
    if (this.cooldown.trim().isEmpty) this.cooldown = cooldown;
    if (this.descrizione.trim().isEmpty) this.descrizione = descrizione;
  }
}

class CharacterSkill {
  CharacterSkill({
    required this.nome,
    required this.tipo,
    required this.costo,
    required this.cooldown,
    required this.descrizione,
    this.resilienza = 0,
    this.volonta = 0,
    this.materia = 0,
    this.oculum = 0,
    this.danni = 0,
    this.difesa = 0,
    this.equipaggiata = false,
    List<CharacterSkillForm>? forme,
  }) : forme = (forme ?? <CharacterSkillForm>[]).toList() {
    ensureForms();
  }

  String nome;
  String tipo;
  String costo;
  String cooldown;
  String descrizione;
  int resilienza;
  int volonta;
  int materia;
  int oculum;
  int danni;
  int difesa;
  bool equipaggiata;
  List<CharacterSkillForm> forme;

  void ensureForms() {
    if (forme.isEmpty) {
      forme = [
        CharacterSkillForm.fromLegacy(
          nome: 'Forma 1',
          tipo: tipo,
          costo: costo,
          cooldown: cooldown,
          descrizione: descrizione,
        ),
      ];
    }

    if (forme.length > 12) {
      forme = forme.take(12).toList();
    }

    for (var i = 0; i < forme.length; i++) {
      if (forme[i].nome.trim().isEmpty) {
        forme[i].nome = 'Forma ${i + 1}';
      }
    }

    syncLegacyFromFirstForm();
  }

  void syncLegacyFromFirstForm() {
    if (forme.isEmpty) return;
    final first = forme.first;
    tipo = first.tipo;
    costo = first.costo;
    cooldown = first.cooldown;
    descrizione = first.descrizione;
  }

  Map<String, dynamic> toJson() {
    ensureForms();
    return {
      'nome': nome,
      'tipo': tipo,
      'costo': costo,
      'cooldown': cooldown,
      'descrizione': descrizione,
      'forme': forme.map((x) => x.toJson()).toList(),
      'resilienza': resilienza,
      'volonta': volonta,
      'materia': materia,
      'oculum': oculum,
      'danni': danni,
      'difesa': difesa,
      'equipaggiata': equipaggiata,
    };
  }

  factory CharacterSkill.fromJson(Map<String, dynamic> json) {
    final rawForms = json['forme'] ?? json['forms'];
    final forms = <CharacterSkillForm>[];
    if (rawForms is List) {
      for (final raw in rawForms) {
        if (raw is Map) {
          forms.add(
            CharacterSkillForm.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      }
    }
    if (forms.isEmpty) {
      forms.add(
        CharacterSkillForm.fromLegacy(
          nome: 'Forma 1',
          tipo: '${json['tipo'] ?? ''}',
          costo: '${json['costo'] ?? ''}',
          cooldown: '${json['cooldown'] ?? ''}',
          descrizione: '${json['descrizione'] ?? ''}',
        ),
      );
    } else {
      forms.first.fillMissingFromLegacy(
        nome: forms.first.nome,
        tipo: '${json['tipo'] ?? ''}',
        costo: '${json['costo'] ?? ''}',
        cooldown: '${json['cooldown'] ?? ''}',
        descrizione: '${json['descrizione'] ?? ''}',
      );
    }

    return CharacterSkill(
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      costo: json['costo'] ?? '',
      cooldown: json['cooldown'] ?? '',
      descrizione: json['descrizione'] ?? '',
      resilienza: readIntValue(json['resilienza']),
      volonta: readIntValue(json['volonta']),
      materia: readIntValue(json['materia']),
      oculum: readIntValue(json['oculum']),
      danni: readIntValue(json['danni']),
      difesa: readIntValue(json['difesa']),
      equipaggiata: readBoolValue(json['equipaggiata']),
      forme: forms,
    );
  }
}

class ArtSkill {
  ArtSkill({
    required this.nome,
    this.livello = 0,
    this.evo1 = '???',
    this.evo2 = '???',
    this.evo3 = '???',
    this.evo4 = '???',
    this.evo5 = '???',
    this.resilienza = 0,
    this.volonta = 0,
    this.materia = 0,
    this.oculum = 0,
    this.danni = 0,
    this.difesa = 0,
  });

  String nome;

  /// Livello della singola Skill dell’Art.
  /// Serve per i Titoli del Fato:
  /// prima Skill livello 1 = primo Titolo del Fato
  /// seconda Skill livello 2 = secondo Titolo del Fato
  /// terza Skill livello 3 = terzo Titolo del Fato
  int livello;

  String evo1;
  String evo2;
  String evo3;
  String evo4;
  String evo5;
  int resilienza;
  int volonta;
  int materia;
  int oculum;
  int danni;
  int difesa;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'livello': livello,
      'evo1': evo1,
      'evo2': evo2,
      'evo3': evo3,
      'evo4': evo4,
      'evo5': evo5,
      'resilienza': resilienza,
      'volonta': volonta,
      'materia': materia,
      'oculum': oculum,
      'danni': danni,
      'difesa': difesa,
    };
  }

  factory ArtSkill.fromJson(Map<String, dynamic> json) {
    return ArtSkill(
      nome: json['nome'] ?? '',
      livello: readIntValue(json['livello']),
      evo1: json['evo1'] ?? '???',
      evo2: json['evo2'] ?? '???',
      evo3: json['evo3'] ?? '???',
      evo4: json['evo4'] ?? '???',
      evo5: json['evo5'] ?? '???',
      resilienza: readIntValue(json['resilienza']),
      volonta: readIntValue(json['volonta']),
      materia: readIntValue(json['materia']),
      oculum: readIntValue(json['oculum']),
      danni: readIntValue(json['danni']),
      difesa: readIntValue(json['difesa']),
    );
  }
}

class CharacterArt {
  CharacterArt({
    required this.nome,
    required this.tipo,
    required this.descrizione,
    required this.skills,
    this.sbloccata = true,
    this.openName = '',
    this.openDescription = '',
    this.openBuff = '',
    this.openSkill = '',
    this.openAttiva = false,
  });

  String nome;
  String tipo;
  String descrizione;
  List<ArtSkill> skills;
  bool sbloccata;
  String openName;
  String openDescription;
  String openBuff;
  String openSkill;
  bool openAttiva;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'tipo': tipo,
      'descrizione': descrizione,
      'skills': skills.map((x) => x.toJson()).toList(),
      'sbloccata': sbloccata,
      'openName': openName,
      'openDescription': openDescription,
      'openBuff': openBuff,
      'openSkill': openSkill,
      'openAttiva': openAttiva,
    };
  }

  factory CharacterArt.fromJson(Map<String, dynamic> json) {
    return CharacterArt(
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      descrizione: json['descrizione'] ?? '',
      skills: ((json['skills'] ?? []) as List)
          .map((x) => ArtSkill.fromJson(Map<String, dynamic>.from(x)))
          .toList(),
      sbloccata: readBoolValue(json['sbloccata'], fallback: true),
      openName: json['openName'] ?? '',
      openDescription: json['openDescription'] ?? '',
      openBuff: json['openBuff'] ?? '',
      openSkill: json['openSkill'] ?? '',
      openAttiva: readBoolValue(json['openAttiva']),
    );
  }
}

// =====================================================
