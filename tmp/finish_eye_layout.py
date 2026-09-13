from pathlib import Path
p=Path('lib/src/main/oculum_fallen_eyes.dart')
s=p.read_text(encoding='utf-8')
a=s.index('  Widget _fallenEyeCard(')
b=s.index('  void _showFallenEyeMenu',a)
part=s[a:b]
part=part.replace('          child: Column(\n            mainAxisSize: MainAxisSize.min,','          child: SingleChildScrollView(child: Column(\n            mainAxisSize: MainAxisSize.min,',1)
end=part.rfind('          ),\n        ),\n      ),\n    );')
assert end>=0
part=part[:end]+part[end:].replace('          ),','          )),',1)
s=s[:a]+part+s[b:]
p.write_text(s,encoding='utf-8')
