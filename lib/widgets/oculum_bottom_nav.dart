import 'package:flutter/material.dart';

class OculumBottomNavItem {
  const OculumBottomNavItem({
    required this.label,
    required this.icon,
    required this.pageIndex,
  });

  final String label;
  final IconData icon;
  final int pageIndex;
}

class OculumBottomNav extends StatelessWidget {
  const OculumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    this.showOnline = false,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final bool showOnline;

  static const List<OculumBottomNavItem> items = [
    OculumBottomNavItem(
      label: 'Scheda',
      icon: Icons.visibility_outlined,
      pageIndex: 0,
    ),
    OculumBottomNavItem(
      label: 'Riposo',
      icon: Icons.nightlight_round,
      pageIndex: 1,
    ),
    OculumBottomNavItem(
      label: 'Titoli',
      icon: Icons.auto_awesome_outlined,
      pageIndex: 2,
    ),
    OculumBottomNavItem(
      label: 'Art',
      icon: Icons.auto_fix_high_outlined,
      pageIndex: 3,
    ),
    OculumBottomNavItem(
      label: 'Skill',
      icon: Icons.blur_circular_outlined,
      pageIndex: 4,
    ),
    OculumBottomNavItem(
      label: 'Storia',
      icon: Icons.menu_book_outlined,
      pageIndex: 5,
    ),
    OculumBottomNavItem(
      label: 'Borsa',
      icon: Icons.backpack_outlined,
      pageIndex: 6,
    ),
    OculumBottomNavItem(
      label: 'Risorse',
      icon: Icons.diamond_outlined,
      pageIndex: 7,
    ),
    OculumBottomNavItem(
      label: 'Regole',
      icon: Icons.rule_outlined,
      pageIndex: 8,
    ),
    OculumBottomNavItem(
      label: 'Master',
      icon: Icons.admin_panel_settings_outlined,
      pageIndex: 9,
    ),
    OculumBottomNavItem(
      label: 'Mappa',
      icon: Icons.map_outlined,
      pageIndex: 10,
    ),
    OculumBottomNavItem(
      label: 'Ricette',
      icon: Icons.menu_book_outlined,
      pageIndex: 14,
    ),
  ];

  static const OculumBottomNavItem onlineItem = OculumBottomNavItem(
    label: 'Online',
    icon: Icons.public,
    pageIndex: 12,
  );

  /// Le quattro destinazioni che meritano spazio permanente sul telefono.
  /// Tutto il resto vive una volta sola nel Codice, senza una seconda barra
  /// piena di icone troppo piccole.
  static const List<OculumBottomNavItem> mobilePrimaryItems = [
    OculumBottomNavItem(
      label: 'Scheda',
      icon: Icons.visibility_outlined,
      pageIndex: 0,
    ),
    OculumBottomNavItem(
      label: 'Riposo',
      icon: Icons.nightlight_round,
      pageIndex: 1,
    ),
    OculumBottomNavItem(
      label: 'Storia',
      icon: Icons.menu_book_outlined,
      pageIndex: 5,
    ),
    OculumBottomNavItem(
      label: 'Borsa',
      icon: Icons.backpack_outlined,
      pageIndex: 6,
    ),
  ];

  Future<void> _openMobileCodex(
    BuildContext context,
    List<OculumBottomNavItem> destinations,
  ) async {
    final primaryIndexes = mobilePrimaryItems
        .map((item) => item.pageIndex)
        .toSet();
    final codexItems = destinations
        .where((item) => !primaryIndexes.contains(item.pageIndex))
        .toList(growable: false);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: const BoxDecoration(
            color: Color(0xFF0D0C13),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0xFF9E6B2F))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6D8BD).withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'CODICE DI OCULUM',
                style: TextStyle(
                  color: Color(0xFFE6D8BD),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ogni pagina è qui una sola volta.',
                style: TextStyle(
                  color: const Color(0xFFE6D8BD).withValues(alpha: .72),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: codexItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.08,
                ),
                itemBuilder: (context, index) {
                  final item = codexItems[index];
                  final selected = item.pageIndex == currentIndex;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onChanged(item.pageIndex);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF9E6B2F).withValues(alpha: .26)
                              : Colors.black.withValues(alpha: .22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF9E6B2F)
                                : Colors.white.withValues(alpha: .08),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFFE6D8BD),
                              size: 23,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFE6D8BD),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = [...items, if (showOnline) onlineItem];
    final size = MediaQuery.of(context).size;
    final compactPhone = size.shortestSide < 600;
    if (compactPhone) {
      final primaryIndexes = mobilePrimaryItems
          .map((item) => item.pageIndex)
          .toSet();
      return SafeArea(
        top: false,
        child: Container(
          height: 76,
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF050408),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFE6D8BD).withValues(alpha: .14),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .68),
                blurRadius: 22,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (final item in mobilePrimaryItems)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _BottomNavButton(
                      label: item.label,
                      icon: item.icon,
                      selected: item.pageIndex == currentIndex,
                      compact: true,
                      onTap: () => onChanged(item.pageIndex),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _BottomNavButton(
                    label: 'Codice',
                    icon: Icons.grid_view_rounded,
                    selected: !primaryIndexes.contains(currentIndex),
                    compact: true,
                    onTap: () => _openMobileCodex(context, visibleItems),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final selectedIndex = visibleItems.indexWhere(
      (item) => item.pageIndex == currentIndex,
    );
    final firstRowCount = visibleItems.length <= 5 ? visibleItems.length : 5;
    final secondRowCount = visibleItems.length - firstRowCount;
    // Keep both navigation rows reachable on short phones.  The former fixed
    // 108 px bar could leave too little scroll viewport at the bottom.
    final shortPhone = compactPhone && size.height < 600;
    final barHeight = shortPhone
        ? 92.0
        : compactPhone
        ? 108.0
        : 132.0;
    final gap = shortPhone
        ? 2.0
        : compactPhone
        ? 4.0
        : 6.0;
    final outerPadding = shortPhone
        ? const EdgeInsets.fromLTRB(5, 4, 5, 4)
        : compactPhone
        ? const EdgeInsets.fromLTRB(6, 5, 6, 6)
        : const EdgeInsets.fromLTRB(8, 7, 8, 8);

    return SafeArea(
      top: false,
      child: Container(
        height: barHeight,
        padding: outerPadding,
        decoration: BoxDecoration(
          color: const Color(0xFF050408),
          border: Border(
            top: BorderSide(
              color: const Color(0xFFE6D8BD).withValues(alpha: 0.14),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.68),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: List.generate(firstRowCount, (index) {
                  final item = visibleItems[index];

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compactPhone ? 2 : 3,
                      ),
                      child: _BottomNavButton(
                        label: item.label,
                        icon: item.icon,
                        selected: index == selectedIndex,
                        compact: compactPhone,
                        onTap: () => onChanged(item.pageIndex),
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (secondRowCount > 0) ...[
              SizedBox(height: gap),
              Expanded(
                child: Row(
                  children: List.generate(secondRowCount, (localIndex) {
                    final index = localIndex + firstRowCount;
                    final item = visibleItems[index];

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compactPhone ? 2 : 3,
                        ),
                        child: _BottomNavButton(
                          label: item.label,
                          icon: item.icon,
                          selected: index == selectedIndex,
                          compact: compactPhone,
                          onTap: () => onChanged(item.pageIndex),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF9E6B2F);
    final normalColor = const Color(0xFFE6D8BD).withValues(alpha: 0.80);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: selectedColor.withValues(alpha: 0.24),
        highlightColor: selectedColor.withValues(alpha: 0.14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 3 : 4,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: 0.24)
                : Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? selectedColor.withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.045),
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.16),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                  ]
                : [],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final verySmall = constraints.maxWidth < 58;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: selected ? Colors.white : normalColor,
                    size: compact ? (selected ? 19 : 18) : (selected ? 22 : 20),
                  ),
                  SizedBox(height: compact ? 2 : 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : normalColor,
                        fontSize: compact
                            ? (verySmall ? 8.4 : 9.1)
                            : (verySmall ? 9.5 : 10.5),
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
