"""Apply Erik's authored personal data overlay without rebuilding generic Elites.

This reads the existing authored sheet, preserves unrelated custom data, and
exports the same OC3 format as Oculum. It does not infer new character rules.
Run with --check to validate the saved JSON/code without changing any files.
The Flutter fixture measures effective PT; this script only applies data.
"""

import argparse
import base64
import copy
import gzip
import json
from pathlib import Path


FOLDER = Path(__file__).resolve().parents[1] / 'output/characters/erik_i'


def encode(sheet):
    raw = json.dumps(sheet, ensure_ascii=False, separators=(',', ':')).encode()
    compressed = gzip.compress(raw, compresslevel=9, mtime=0)
    checksum = 0x811C9DC5
    for byte in compressed:
        checksum = ((checksum ^ byte) * 0x01000193) & 0xFFFFFFFF
    payload = base64.urlsafe_b64encode(compressed).decode().rstrip('=')
    return f'OC3:{checksum:08x}:{payload}'


def decode(code):
    prefix, expected, payload = code.strip().split(':', 2)
    if prefix != 'OC3':
        raise ValueError('Expected OC3')
    compressed = base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4))
    checksum = 0x811C9DC5
    for byte in compressed:
        checksum = ((checksum ^ byte) * 0x01000193) & 0xFFFFFFFF
    if f'{checksum:08x}' != expected:
        raise ValueError('OC3 checksum mismatch')
    return json.loads(gzip.decompress(compressed))


def apply_overlay(source, overlay):
    if overlay['targetCharacter'] != 'erik_i':
        raise ValueError('This overlay belongs to a different character')
    sheet = copy.deepcopy(source)
    runtime = sheet.setdefault('planarRuntime', {})
    if runtime.get('canonicalNpc') != 'erik_i':
        raise ValueError('Preserve the explicit canonical NPC identity')
    if int(sheet['livello']) != 8 or int(sheet['grado']) != 0:
        raise ValueError('The personal override is authored for level 8/grade 0')
    for key, value in overlay['baseStats'].items():
        sheet[key] = str(value)
        sheet['current' + key[0].upper() + key[1:]] = str(value)
    sheet['maxOculum'] = overlay['baseStats']['oculum']
    sheet['normalCurrentOculum'] = overlay['baseStats']['oculum']
    # Authored initial reserve only; effective statistics are measured in Flutter.
    sheet['currentHp'] = str(overlay['expectedEffectiveCoreStats']['resilienza'] * 10)
    personal = next(s for s in sheet['skills'] if s['nome'] == 'Custodia del Girone')
    values = overlay['custodiaDelGirone']
    for index, form in enumerate(personal['forme']):
        for effect in form['effettiStrutturati']:
            if effect['type'] == 'scudo':
                effect['valueExpression'] = str(values['shieldByForm'][index])
            elif effect['type'] == 'difesa':
                effect['valueExpression'] = str(values['defenseByForm'][index])
        # Costs/CD are intentionally preserved, not regenerated from prose.
        if form['costoStrutturato']['amountExpression'] != str(values['costsUnchanged'][index]):
            raise ValueError('Unexpected authored Custodia cost; resolve before exporting')
        if form['cooldownStrutturato']['amount'] != values['cooldownPersonalTurnsUnchanged']:
            raise ValueError('Unexpected authored Custodia cooldown; resolve before exporting')
    runtime['personalBalanceOverride'] = {
        'id': 'erik_i_130', 'targetTotalPower': overlay['expectedTotalPower'],
        'level': 8, 'grade': 0,
    }
    return sheet


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    json_file = FOLDER / 'Erik_I.json'
    code_file = FOLDER / 'Erik_I.codice.txt'
    source = json.loads(json_file.read_text(encoding='utf-8-sig'))
    overlay = json.loads((FOLDER / 'Erik_I.overlay_personale.json').read_text(encoding='utf-8-sig'))
    sheet = apply_overlay(source, overlay)
    if args.check:
        if sheet != source or decode(code_file.read_text(encoding='utf-8-sig')) != source:
            raise ValueError('Saved Erik JSON/OC3 does not match the authored personal overlay')
        print('Erik personal overlay and OC3/JSON agree. Effective PT needs the Flutter test.')
        return
    code = encode(sheet)
    if decode(code) != sheet:
        raise ValueError('Export failed its OC3 roundtrip')
    json_file.write_text(json.dumps(sheet, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    code_file.write_text(code + '\n', encoding='utf-8')
    print('Exported Erik personal data; generic Elite builder and other character sheets untouched.')


if __name__ == '__main__':
    main()
