import 'package:flutter/material.dart';

class OculumDesktopTopMenu extends StatelessWidget {
  const OculumDesktopTopMenu({
    super.key,
    required this.currentIndex,
    required this.labels,
    required this.onChanged,
    required this.primaryColor,
    required this.tertiaryColor,
    required this.searchLabel,
    required this.pageLabel,
  });

  final int currentIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;
  final Color primaryColor;
  final Color tertiaryColor;
  final String searchLabel;
  final String pageLabel;

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, labels.length - 1).toInt();

    return SizedBox(
      width: 260,
      child: OutlinedButton.icon(
        onPressed: () => _openDesktopPageSearch(context),
        icon: Icon(Icons.manage_search, color: tertiaryColor, size: 20),
        label: Row(
          children: [
            Expanded(
              child: Text(
                '${safeIndex + 1}. ${labels[safeIndex]}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: tertiaryColor),
          ],
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: tertiaryColor.withValues(alpha: 0.55)),
          backgroundColor: const Color(0xFF0D0F16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  void _openDesktopPageSearch(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocalState) {
            final query = controller.text.trim().toLowerCase();

            final results = <int>[];
            for (int i = 0; i < labels.length; i++) {
              if (query.isEmpty || labels[i].toLowerCase().contains(query)) {
                results.add(i);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF10121A),
              title: Text(
                pageLabel,
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SizedBox(
                width: 420,
                height: 460,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: searchLabel,
                        labelStyle: TextStyle(color: primaryColor),
                        prefixIcon: Icon(Icons.search, color: tertiaryColor),
                        filled: true,
                        fillColor: const Color(0xFF080911),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: primaryColor.withValues(alpha: 0.45),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: tertiaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) => setLocalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final pageIndex = results[index];
                          final selected = pageIndex == currentIndex;

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: Icon(
                                selected
                                    ? Icons.visibility
                                    : Icons.radio_button_unchecked,
                                color: selected ? tertiaryColor : primaryColor,
                              ),
                              title: Text(
                                '${pageIndex + 1}. ${labels[pageIndex]}',
                                style: TextStyle(
                                  color: selected
                                      ? tertiaryColor
                                      : Colors.white,
                                  fontWeight: selected
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                ),
                              ),
                              onTap: () {
                                onChanged(pageIndex);
                                Navigator.pop(dialogContext);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Chiudi', style: TextStyle(color: primaryColor)),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }
}
