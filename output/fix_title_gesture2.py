from pathlib import Path
p=Path('lib/src/main/oculum_reference_sheet.dart');s=p.read_text();start=s.index('  Widget visibleTitleIdentitySelector');end=s.index('  Future<void> openVisibleTitleIdentity',start);b=s[start:end];b=b.replace('''        child: GestureDetector(
          onSecondaryTap: openVisibleTitleIdentity,
          onLongPress: openVisibleTitleIdentity,
          child: Text(''','''        child: Text(''',1);idx=b.index('        child: Text(\n          \'${includeName');b=b[:idx]+b[idx:].replace('        child: Text(','        child: GestureDetector(\n          onSecondaryTap: openVisibleTitleIdentity,\n          onLongPress: openVisibleTitleIdentity,\n          child: Text(',1);s=s[:start]+b+s[end:];p.write_text(s)
