"""Use the game's retirement list for review galleries without deleting art."""
from pathlib import Path
import re

def retired_bases(root):
    source = (Path(root) / 'lib/pages/oculum_dungeon/monster_book.dart').read_text(encoding='utf-8')
    match = re.search(r'bool oculumIsRetiredMonsterId\(String id\)\s*=>\s*const\s*\{(.*?)\}\.contains', source, re.S)
    if not match:
        raise ValueError('Cannot read the game retirement list')
    result = set(re.findall(r"'([a-z0-9_]+)'", match[1]))
    if not result:
        raise ValueError('Unexpected empty retirement list')
    return result

def is_retired(identifier, bases):
    return identifier.strip().split('_variante_', 1)[0] in bases
