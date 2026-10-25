part of '../../main.dart';

extension _OculumMobileSheet on _OculumHomePageState {
  Widget responsiveBattleActions(List<Widget> actions) {
    actions = [
      for (final action in actions)
        OculumSurfaceButton(key: action.key, child: action),
    ];
    if (!phoneCompactUi) {
      return Wrap(spacing: 10, runSpacing: 10, children: actions);
    }
    const order = [
      'mobile-attack',
      'mobile-defense',
      'mobile-dodge',
      'mobile-support',
    ];
    final primary = [
      for (final id in order) ...actions.where((w) => w.key == ValueKey(id)),
    ];
    final secondary = actions.where((w) => !primary.contains(w)).toList();
    if (primary.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actions,
      );
    }
    Widget grid(List<Widget> children) => LayoutBuilder(
      builder: (context, box) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final child in children)
            SizedBox(width: (box.maxWidth - 8) / 2, height: 48, child: child),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        grid(primary),
        if (secondary.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: const Text(
              'Altri tiri e risorse',
              style: TextStyle(fontSize: 13),
            ),
            children: [grid(secondary)],
          ),
      ],
    );
  }
}
