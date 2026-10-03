import 'package:flutter/material.dart';

/// Browsing a participant never changes initiative or advances the turn.
class OculumEncounterStage extends StatefulWidget {
  const OculumEncounterStage({
    super.key,
    required this.tokens,
    required this.activeIndex,
    required this.portraitBuilder,
    required this.accent,
    this.onNextTurn,
    this.onIdentify,
    this.onReveal,
    this.events = const [],
  });
  final List<Map<String, dynamic>> tokens;
  final int activeIndex;
  final Widget Function(Map<String, dynamic>) portraitBuilder;
  final Color accent;
  final VoidCallback? onNextTurn;
  final void Function(Map<String, dynamic>)? onIdentify;
  final void Function(Map<String, dynamic>)? onReveal;
  final List<String> events;
  @override
  State<OculumEncounterStage> createState() => _OculumEncounterStageState();
}

class _OculumEncounterStageState extends State<OculumEncounterStage> {
  late final PageController _pages;
  int _selected = 0;
  @override
  void initState() {
    super.initState();
    _selected = widget.tokens.isEmpty
        ? 0
        : widget.activeIndex.clamp(0, widget.tokens.length - 1);
    _pages = PageController(initialPage: _selected);
  }

  @override
  void didUpdateWidget(OculumEncounterStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected >= widget.tokens.length && widget.tokens.isNotEmpty) {
      _selected = widget.tokens.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(_selected);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _browse(int index) => _pages.animateToPage(
    index,
    duration: const Duration(milliseconds: 160),
    curve: Curves.easeOut,
  );
  @override
  Widget build(BuildContext context) {
    if (widget.tokens.isEmpty) return const SizedBox.shrink();
    final active =
        widget.tokens[widget.activeIndex.clamp(0, widget.tokens.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Turno: ${active['name'] ?? '???'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (widget.onNextTurn != null)
              FilledButton.icon(
                onPressed: widget.onNextTurn,
                icon: const Icon(Icons.skip_next),
                label: const Text('Turno successivo'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 62,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.tokens.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(right: 9),
              child: Tooltip(
                message: '${widget.tokens[i]['name'] ?? '???'}',
                child: InkWell(
                  onTap: () => _browse(i),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 54,
                    height: 54,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == _selected
                            ? widget.accent
                            : widget.tokens[i]['side'] == 'enemy'
                            ? const Color(0xff8a3539)
                            : const Color(0xff657a9c),
                        width: i == _selected ? 2 : 1,
                      ),
                    ),
                    child: ClipOval(
                      child: widget.portraitBuilder(widget.tokens[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pages,
            itemCount: widget.tokens.length,
            onPageChanged: (i) => setState(() => _selected = i),
            itemBuilder: (context, i) {
              final token = widget.tokens[i];
              final blindSpot = '${token['discoveredBlindSpot'] ?? ''}'.trim();
              return Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff0b0b0e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: .5),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 74,
                      height: 94,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: widget.portraitBuilder(token),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${token['name'] ?? '???'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Lv. ${token['level'] ?? 0} · ${token['status'] == 'dead' ? 'Morto' : 'In combattimento'}',
                            ),
                            if (blindSpot.isNotEmpty)
                              Text(
                                'Punto Cieco: $blindSpot',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: widget.accent),
                              ),
                            if (widget.onIdentify != null)
                              TextButton(
                                onPressed: () => widget.onIdentify!(token),
                                child: const Text('Assegna nome e immagine'),
                              ),
                            if (widget.onReveal != null)
                              TextButton(
                                onPressed: () => widget.onReveal!(token),
                                child: const Text('Informazioni per i Player'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${_selected + 1}/${widget.tokens.length} · Scorri per vedere gli altri partecipanti',
          style: TextStyle(fontSize: 11, color: widget.accent),
        ),
        if (widget.events.isNotEmpty) ...[
          const Divider(),
          const Text('Log · dadi e morti'),
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: widget.events.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  widget.events[i],
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
