part of '../../main.dart';

class _CombatLogImpact {
  const _CombatLogImpact({
    this.oculumShieldLost = 0,
    this.oculumShieldBroken = false,
    this.shieldLost = 0,
    this.shieldBroken = false,
    this.hpLost = 0,
    this.hpGained = 0,
  });

  factory _CombatLogImpact.fromReceipt(Map receipt, {Map? display}) {
    final source = display ?? receipt;
    int amount(String key) => readIntValue(source[key]).clamp(0, 100000000);
    return _CombatLogImpact(
      oculumShieldLost: amount('oculumShieldLost'),
      oculumShieldBroken:
          display != null && source['oculumShieldBroken'] == true,
      shieldLost: amount('shieldLost'),
      shieldBroken: display != null && source['shieldBroken'] == true,
      hpLost: amount('hpLost'),
      hpGained: display != null ? amount('hpGained') : 0,
    );
  }

  final int oculumShieldLost;
  final bool oculumShieldBroken;
  final int shieldLost;
  final bool shieldBroken;
  final int hpLost;
  final int hpGained;

  _CombatLogImpact merge(_CombatLogImpact other) => _CombatLogImpact(
    oculumShieldLost: oculumShieldLost + other.oculumShieldLost,
    oculumShieldBroken: oculumShieldBroken || other.oculumShieldBroken,
    shieldLost: shieldLost + other.shieldLost,
    shieldBroken: shieldBroken || other.shieldBroken,
    hpLost: hpLost + other.hpLost,
    hpGained: hpGained + other.hpGained,
  );

  Map<String, Object> toJson() => {
    'oculumShieldLost': oculumShieldLost,
    'oculumShieldBroken': oculumShieldBroken,
    'shieldLost': shieldLost,
    'shieldBroken': shieldBroken,
    'hpLost': hpLost,
    'hpGained': hpGained,
  };
}

extension _OculumCombatLog on _OculumHomePageState {
  String combatImpactLog(
    String heading,
    _CombatLogImpact impact, {
    String? empty,
  }) {
    final parts = <String>[
      if (impact.oculumShieldBroken)
        t('Scudo Oculum rotto', 'Oculum Shield broken')
      else if (impact.oculumShieldLost > 0)
        t(
          'Scudo Oculum −${impact.oculumShieldLost}',
          'Oculum Shield −${impact.oculumShieldLost}',
        ),
      if (impact.shieldBroken)
        t('Scudo rotto', 'Shield broken')
      else if (impact.shieldLost > 0)
        t('Scudo −${impact.shieldLost}', 'Shield −${impact.shieldLost}'),
      if (impact.hpLost > 0)
        t('Vita −${impact.hpLost}', 'Life −${impact.hpLost}'),
      if (impact.hpGained > 0)
        t('Vita +${impact.hpGained}', 'Life +${impact.hpGained}'),
    ];
    if (parts.isEmpty) {
      parts.add(
        empty ?? t('Vita e scudi invariati', 'Life and shields unchanged'),
      );
    }
    return '$heading · ${parts.join(' · ')}';
  }

  void reportIncomingCombatImpact(
    _CombatLogImpact impact,
    ValueChanged<_CombatLogImpact>? onImpact, {
    String? empty,
  }) {
    risultato = combatImpactLog('[DANNO SUBITO]', impact, empty: empty);
    if (onImpact == null) {
      aggiungiLog(risultato);
    } else {
      onImpact(impact);
    }
  }

  Widget combatLogText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final segments = text.split(' · ');
    if (segments.length < 2 ||
        !const [
          '[DANNO SUBITO]',
          '[DANNO RISOLTO]',
          '[CURA]',
        ].any(segments.first.contains)) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    return Text.rich(
      TextSpan(
        text: segments.first,
        children: [
          for (final segment in segments.skip(1))
            TextSpan(
              children: [
                const TextSpan(text: ' · '),
                TextSpan(
                  text: segment,
                  style: TextStyle(color: combatLogResourceColor(segment)),
                ),
              ],
            ),
        ],
      ),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  Color? combatLogResourceColor(String segment) {
    if (segment.startsWith('Scudo Oculum ') ||
        segment.startsWith('Oculum Shield ')) {
      return oculumStatFormulaColor;
    }
    if (segment.startsWith('Scudo ') || segment.startsWith('Shield ')) {
      return const Color(0xFF61C5FF);
    }
    if (segment.startsWith('Vita −') || segment.startsWith('Life −')) {
      return const Color(0xFFD7344C);
    }
    if (segment.startsWith('Vita +') || segment.startsWith('Life +')) {
      return const Color(0xFF58DFA5);
    }
    return null;
  }
}
