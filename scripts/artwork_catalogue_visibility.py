"""Use the game's retirement list for review galleries without deleting art."""
from pathlib import Path
import re

def retirement_rules(root):
    source = (Path(root) / 'lib/pages/oculum_dungeon/monster_book.dart').read_text(encoding='utf-8')
    predicate = re.search(r'bool oculumIsRetiredMonsterId\(String id\)\s*=>\s*(.*?);', source, re.S)
    if not predicate:
        raise ValueError('Cannot read the game retirement list')
    family_match = re.search(r'const\s*\{(.*?)\}\.contains', predicate[1], re.S)
    if not family_match:
        raise ValueError('Cannot read the game retirement families')
    families = set(re.findall(r"'([a-z0-9_]+)'", family_match[1]))
    if not families:
        raise ValueError('Unexpected empty retirement list')
    exact = set(re.findall(r"id\.trim\(\)\s*==\s*'([a-z0-9_]+)'", predicate[1]))
    if '_retiredExactMonsterIds.contains' in predicate[1]:
        exact_match = re.search(r'const _retiredExactMonsterIds\s*=\s*<String>\s*\{(.*?)\};', source, re.S)
        if not exact_match:
            raise ValueError('Cannot read the exact game retirement list')
        exact.update(re.findall(r"'([a-z0-9_]+)'", exact_match[1]))
    return families, exact


def retired_bases(root):
    return retirement_rules(root)[0]


def is_retired(identifier, bases, exact=()):
    identifier = identifier.strip()
    return identifier in exact or identifier.split('_variante_', 1)[0] in bases
