import 'package:flutter/material.dart';

int _quickEditImageCacheDimension(
  BuildContext context,
  double logicalPixels, {
  int min = 24,
  int max = 160,
}) {
  final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
  return (logicalPixels * dpr).clamp(min.toDouble(), max.toDouble()).round();
}

class OculumQuickEditEntry {
  const OculumQuickEditEntry({
    required this.label,
    required this.controller,
    this.isNumber = true,
    this.maxLines = 1,
    this.assetIconPath,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool isNumber;
  final int maxLines;
  final String? assetIconPath;
  final ValueChanged<String>? onChanged;
}

class OculumQuickEditSection {
  const OculumQuickEditSection({required this.title, required this.entries});

  final String title;
  final List<OculumQuickEditEntry> entries;
}

class OculumQuickEditEyeButton extends StatelessWidget {
  const OculumQuickEditEyeButton({
    super.key,
    required this.sectionsBuilder,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  final List<OculumQuickEditSection> Function() sectionsBuilder;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final VoidCallback onChanged;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.shortestSide < 600;
    return IconButton(
      tooltip: title,
      onPressed: () => _openQuickEdit(context),
      icon: Icon(
        Icons.visibility,
        color: tertiaryColor,
        size: compact ? 20 : 24,
      ),
    );
  }

  void _openQuickEdit(BuildContext context) {
    final sections = sectionsBuilder();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final compact = MediaQuery.of(dialogContext).size.shortestSide < 600;
        return Dialog(
          backgroundColor: const Color(0xFF090A12),
          insetPadding: EdgeInsets.all(compact ? 10 : 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: tertiaryColor.withValues(alpha: 0.75),
              width: 1.2,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 760),
            child: Padding(
              padding: EdgeInsets.all(compact ? 12 : 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: tertiaryColor,
                        size: compact ? 20 : 24,
                      ),
                      SizedBox(width: compact ? 7 : 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: tertiaryColor,
                            fontSize: compact ? 18 : 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          onChanged();
                          Navigator.pop(dialogContext);
                        },
                        icon: Icon(Icons.close, color: primaryColor),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 5 : 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: compact ? 11.5 : 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 9 : 14),
                  Expanded(
                    child: ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: sections.length,
                      itemBuilder: (context, index) => _QuickEditSectionWidget(
                        section: sections[index],
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        tertiaryColor: tertiaryColor,
                        onChanged: onChanged,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      onChanged();
                      Navigator.pop(dialogContext);
                    },
                    icon: const Icon(Icons.check),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tertiaryColor,
                      foregroundColor: tertiaryColor.computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white,
                      minimumSize: Size.fromHeight(compact ? 40 : 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    label: const Text(
                      'Conferma modifiche',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickEditSectionWidget extends StatelessWidget {
  const _QuickEditSectionWidget({
    required this.section,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.onChanged,
  });

  final OculumQuickEditSection section;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.shortestSide < 600;
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171A24), Color(0xFF0D0F16), Color(0xFF080910)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tertiaryColor.withValues(alpha: 0.55),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              color: tertiaryColor,
              fontSize: compact ? 15 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              final gap = compact ? 8.0 : 12.0;
              final width = isWide
                  ? (constraints.maxWidth - gap) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final entry in section.entries)
                    SizedBox(
                      width: width,
                      child: TextField(
                        controller: entry.controller,
                        keyboardType: entry.isNumber
                            ? const TextInputType.numberWithOptions(
                                signed: true,
                              )
                            : TextInputType.text,
                        maxLines: entry.maxLines,
                        onChanged: (value) {
                          entry.onChanged?.call(value);
                        },
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 13 : null,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: entry.label,
                          prefixIcon: entry.assetIconPath == null
                              ? null
                              : Padding(
                                  padding: EdgeInsets.all(compact ? 8 : 10),
                                  child: Image.asset(
                                    entry.assetIconPath!,
                                    width: compact ? 18 : 20,
                                    height: compact ? 18 : 20,
                                    cacheWidth: _quickEditImageCacheDimension(
                                      context,
                                      compact ? 18 : 20,
                                    ),
                                    cacheHeight: _quickEditImageCacheDimension(
                                      context,
                                      compact ? 18 : 20,
                                    ),
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.monetization_on,
                                          color: tertiaryColor,
                                          size: 20,
                                        ),
                                  ),
                                ),
                          labelStyle: TextStyle(
                            color: primaryColor.withValues(alpha: 0.90),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0E1016),
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
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
