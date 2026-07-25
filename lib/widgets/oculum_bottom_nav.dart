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

  @override
  Widget build(BuildContext context) {
    final visibleItems = [...items, if (showOnline) onlineItem];
    final selectedIndex = visibleItems.indexWhere(
      (item) => item.pageIndex == currentIndex,
    );
    final firstRowCount = visibleItems.length <= 5 ? visibleItems.length : 5;
    final secondRowCount = visibleItems.length - firstRowCount;
    final compactPhone = MediaQuery.of(context).size.shortestSide < 600;
    final barHeight = compactPhone ? 108.0 : 132.0;
    final gap = compactPhone ? 4.0 : 6.0;
    final outerPadding = compactPhone
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
