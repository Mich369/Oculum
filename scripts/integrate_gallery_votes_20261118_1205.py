"""Integrate only the ten received 1205 desktop votes; never delete artwork.

Default execution validates and prints a plan. --apply performs guarded atomic
replacements after every input and destination has passed the complete preflight.
No formatter, Flutter command, build, generation or cleanup is invoked.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import html
import json
import os
from pathlib import Path
import re
import stat
import uuid


ROOT = Path(__file__).resolve().parents[1]
BATCH = ROOT / 'output/artwork/expressive_ink_giro_20261117_1205'
SOURCE = ROOT / 'output/artwork/SCELTE-GIRO1205-20261118.json'
PREP = ROOT / 'output/artwork/PREPARAZIONE-20261117-1205.json'
EXPECTED = {
    'habitat_caramella_rospo_di_crema_variante_veterana': ('B', 'Dulcycrust'),
    'habitat_oblio_divoratore_degli_ultimi_nomi_variante_errante': ('B', 'Oblyravyn'),
    'mantide_sanguescatto': ('G', 'Vyridblade'),
    'teschio_quattro_lame': ('G', 'Quadrilame'),
    'habitat_caramella_falena_di_zucchero_filato_variante_errante': ('A', 'Vagafloss'),
    'habitat_isole_razza_del_cielo_basso_variante_corazzata': ('G', 'Ventyscute'),
    'base_postea_02': ('G', 'Runycrick'),
    'weak_horror_mastino': ('F', 'Cynyscarn'),
    'pellegrino_senza_volto_variante_errante': ('H', 'Senza Volto Errante'),
    'manichino_spada': ('C', 'Ensypuppet'),
}
PAYLOAD = re.compile(
    r'(<script type="application/json" id="galleria-data">)(.*?)(</script>)', re.S
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(content):
    return hashlib.sha256(content).hexdigest()


def raw(data):
    return (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode('utf-8')


def check_path(path):
    require(path.is_absolute() and path.is_relative_to(ROOT), f'Outside repository: {path}')
    current = ROOT
    for part in path.relative_to(ROOT).parts:
        current /= part
        if not current.exists():
            continue
        info = current.lstat()
        require(not stat.S_ISLNK(info.st_mode), f'Symlink: {current}')
        require(not getattr(info, 'st_file_attributes', 0) & 1024,
                f'Reparse point: {current}')


@dataclass(frozen=True)
class Snapshot:
    content: bytes | None
    identity: tuple | None


class Transaction:
    def __init__(self):
        self.before = {}
        self.updates = {}

    def snapshot(self, path):
        check_path(path)
        try:
            info = path.stat()
        except FileNotFoundError:
            return Snapshot(None, None)
        require(stat.S_ISREG(info.st_mode), f'Not a regular file: {path}')
        content = path.read_bytes()
        after = path.stat()
        identity = lambda s: (s.st_dev, s.st_ino, s.st_nlink, s.st_size, s.st_mtime_ns)
        require(identity(info) == identity(after), f'Changed while reading: {path}')
        return Snapshot(content, identity(after))

    def read(self, path):
        previous = self.before.setdefault(path, self.snapshot(path))
        require(previous.content is not None, f'Missing source: {path}')
        return previous.content

    def document(self, path):
        return json.loads(self.read(path).decode('utf-8-sig'))

    def plan(self, path, content):
        previous = self.before.setdefault(path, self.snapshot(path))
        require(previous.identity is None or previous.identity[2] == 1,
                f'Refusing shared hardlink destination: {path}')
        require(path not in self.updates, f'Duplicate write: {path}')
        self.updates[path] = content

    def unchanged(self, path):
        require(self.snapshot(path) == self.before[path], f'Concurrent change: {path}')

    def apply(self):
        for path in self.before:
            self.unchanged(path)
        for path, content in self.updates.items():
            self.unchanged(path)
            if self.before[path].content == content:
                continue
            pending = path.with_name(f'.{path.name}.1205-{uuid.uuid4().hex}.tmp')
            check_path(pending)
            try:
                with pending.open('xb') as stream:
                    stream.write(content)
                    stream.flush()
                    os.fsync(stream.fileno())
                require(pending.stat().st_nlink == 1, f'Shared temporary file: {pending}')
                self.unchanged(path)
                os.replace(pending, path)
                require(path.stat().st_nlink == 1 and path.read_bytes() == content,
                        f'Atomic write verification failed: {path}')
                self.before[path] = self.snapshot(path)
            finally:
                if pending.exists():
                    pending.unlink()  # Only this invocation's exclusively created temporary file.
        for path in self.before:
            self.unchanged(path)


def dart_string(value):
    return value.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')


def managed_block(text, tag, block, anchor):
    begin, end = f'// BEGIN {tag}', f'// END {tag}'
    pattern = re.compile(r'^[ \t]*' + re.escape(begin) + r'.*?^[ \t]*' + re.escape(end) + r'\n', re.M | re.S)
    if begin in text:
        require(len(pattern.findall(text)) == 1, f'Invalid managed block: {tag}')
        return pattern.sub(lambda _: block, text, count=1)
    require(text.count(anchor) == 1, f'Anchor missing or duplicated: {tag}')
    return text.replace(anchor, anchor + block, 1)


def prepare():
    tx = Transaction()
    source = tx.document(SOURCE)
    received = source['receivedAtUtc']
    require(datetime.fromisoformat(received).utcoffset() is not None, 'Missing received timezone')
    require(source['schemaVersion'] == 1 and source['source'] == 'galleria-lotti-20261117-1205',
            'Wrong source receipt')
    votes = source['votes']
    require(len(votes) == 10 and {v['id'] for v in votes} == set(EXPECTED), 'Wrong ten IDs')
    require(not source.get('pendingNames'), 'Names remain pending')
    source_sha = source.get('sourceReceiptSha256BeforeIntegration') or sha(tx.read(SOURCE))
    vote_sha = sha(raw(votes))
    choices = tx.document(BATCH / 'SCELTE.json')
    delivery = tx.document(BATCH / 'CONSEGNA.json')
    prep = tx.document(PREP)
    require(choices['source'] == source['source'], 'Gallery source mismatch')
    require(delivery['id'] == prep['preparationId'] == 'oculum-10-lotti-20261117-1205',
            'Preparation/delivery mismatch')
    cards = {row['id']: row for row in choices['lots']}
    states = {row['id']: row for row in delivery['lots']}
    prepared = {row['id']: row for row in prep['lots']}
    require(cards.keys() == states.keys() == prepared.keys() == EXPECTED.keys(), 'Batch ID mismatch')
    page = tx.read(BATCH / 'GALLERIA.html').decode('utf-8-sig')
    payloads = list(PAYLOAD.finditer(page))
    require(len(payloads) == 1 and json.loads(payloads[0][2]) == choices,
            'HTML payload and SCELTE.json differ')
    now = datetime.now(timezone.utc).isoformat()
    checked = []
    corrections = {}
    for vote in votes:
        ident = vote['id']
        card, state, lot = cards[ident], states[ident], prepared[ident]
        require(not lot['category'].startswith('ambiente_'), '1205 contains only creatures')
        require(len(vote['artwork']) == 1, f'Wrong surfaces: {ident}')
        art = vote['artwork'][0]
        require(art['surface'] == 'desktop', f'Not desktop: {ident}')
        require((art['slot'], vote['name']['value']) == EXPECTED[ident], f'Unexpected vote: {ident}')
        require(vote['name']['kind'] in {'current', 'alternate', 'custom'}, f'Invalid name kind: {ident}')
        if vote['name']['kind'] == 'alternate':
            require(vote['name']['value'] in {n['name'] for n in card['names']['alternatives']},
                    f'Unknown alternate name: {ident}')
        options = [o for o in card['choices'][0]['options'] if o['slot'] == art['slot']]
        require(len(options) == 1, f'Duplicate/missing option: {ident}')
        option = options[0]
        require(option['file'] == f'{ident}/{art["slot"]}.webp', f'Unexpected plate path: {ident}')
        content = tx.read(BATCH / option['file'])
        require(content[:4] == b'RIFF' and content[8:12] == b'WEBP', f'Not WebP: {ident}')
        require(sha(content) == art['sha256'] == option['sha256'] == state['hashes'][art['slot']],
                f'Plate hash mismatch: {ident}')
        require(state.get('shownAtUtc') and datetime.fromisoformat(received) >=
                datetime.fromisoformat(state['shownAtUtc']), f'Vote predates showing: {ident}')
        manifest_path = BATCH / ident / 'MANIFEST.json'
        manifest = tx.document(manifest_path)
        require(manifest['id'] == ident, f'Manifest ID mismatch: {ident}')
        variants = [v for v in manifest['variants'] if v['slot'] == art['slot']]
        require(len(variants) == 1 and variants[0]['sha256'] == art['sha256'],
                f'Manifest hash mismatch: {ident}')
        target = ROOT / f'assets/oculum/home_art_authored/theme_{ident}_canon_20261118.webp'
        if ident == 'manichino_spada':
            correction_path = BATCH / ident / 'CORREZIONE-OCCHIO-VIOLA.json'
            correction = tx.document(correction_path)
            require(correction['id'] == ident and correction['sourceChoice']['slot'] == art['slot']
                    and correction['sourceChoice']['sha256'] == art['sha256']
                    and correction['sourceChoice']['file'] == (BATCH / option['file']).relative_to(ROOT).as_posix(),
                    'Correction does not refer to the selected original C')
            corrected = correction['correctedArtwork']
            require(corrected['slot'] == 'C1' and corrected['file'] ==
                    'output/artwork/expressive_ink_giro_20261117_1205/manichino_spada/C1-occhio-viola.webp'
                    and corrected['sha256'] == '710886acfde3584d91c58f76acb00c8654ba1b6c52d54fbb5a32da039b3bc115'
                    and correction['visualReview']['violetEye'] is True
                    and correction['originalChoicePreserved'] is True,
                    'Unverified or unexpected derived artwork')
            content = tx.read(ROOT / corrected['file'])
            require(sha(content) == corrected['sha256'] and len(content) == corrected['bytes']
                    and content[:4] == b'RIFF' and content[8:12] == b'WEBP',
                    'Corrected artwork hash/format mismatch')
            target = ROOT / 'assets/oculum/home_art_authored/theme_manichino_spada_canon_20261118_v2.webp'
            corrections[ident] = {
                'slot': corrected['slot'], 'file': corrected['file'], 'sha256': corrected['sha256'],
                'sourceSlot': art['slot'], 'sourceSha256': art['sha256'],
                'correctionReceipt': correction_path.relative_to(ROOT).as_posix(),
                'scope': 'Solo occhio nella guardia riportato viola, secondo istruzione esplicita.',
                'status': 'integrato_in_attesa_verifiche',
            }
        prior = tx.snapshot(target)
        require(prior.content in (None, content), f'Existing new-date asset differs: {target}')
        checked.append((vote, card, state, lot, option, content, target, manifest_path, manifest))

    # All ten ID/slot/source hashes have passed before any update is planned.
    for _, _, _, _, _, content, target, _, _ in checked:
        tx.plan(target, content)

    alias_path = ROOT / 'lib/pages/oculum_dungeon/monster_name_aliases.dart'
    aliases = tx.read(alias_path).decode('utf-8-sig')
    alias_eol = '\r\n' if '\r\n' in aliases else '\n'
    aliases = aliases.replace('\r\n', '\n')
    alias_tag = 'APPROVED-GALLERY-1205-NAMES-20261118'
    existing_without_block = re.sub(
        r'^[ \t]*// BEGIN ' + alias_tag + r'.*?^[ \t]*// END ' + alias_tag + r'\n',
        '', aliases, flags=re.M | re.S)
    for ident in EXPECTED:
        require(f"'{ident}':" not in existing_without_block, f'Existing alias needs explicit merge: {ident}')
    alias_lines = ''.join(
        f"  '{v['id']}': (name: '{dart_string(v['name']['value'])}', spelling: '{dart_string(c['name'])}'),\n"
        for v, c, *_ in checked)
    alias_block = f'  // BEGIN {alias_tag}\n{alias_lines}  // END {alias_tag}\n'
    aliases = managed_block(aliases, alias_tag, alias_block,
                            'const _pronouncedMonsterNames = <String, ({String name, String spelling})>{\n')
    tx.plan(alias_path, aliases.replace('\n', alias_eol).encode('utf-8'))

    theme_path = ROOT / 'lib/widgets/oculum_monster_theme.dart'
    themes = tx.read(theme_path).decode('utf-8-sig')
    theme_eol = '\r\n' if '\r\n' in themes else '\n'
    themes = themes.replace('\r\n', '\n')
    theme_tag = 'APPROVED-GALLERY-1205-DESKTOPS-20261118'
    id_lines = ''.join(f"    '{ident}',\n" for ident in EXPECTED)
    theme_block = (f'  // BEGIN {theme_tag}\n'
                   '  static const _november18ApprovedDesktopIds = <String>{\n'
                   + id_lines + f'  }};\n  // END {theme_tag}\n')
    themes = managed_block(themes, theme_tag, theme_block,
                           '  const OculumMonsterTheme(this.monster, this.color);\n')
    old = '      _november17ApprovedDesktopIds.contains(monster.id) ||\n'
    new = '      _november18ApprovedDesktopIds.contains(monster.id) ||\n' + old
    if '_november18ApprovedDesktopIds.contains(monster.id)' not in themes:
        require(themes.count(old) == 1, 'Framing guard anchor mismatch')
        themes = themes.replace(old, new, 1)
    guard = ("    final id when _november18ApprovedDesktopIds.contains(id) =>\n"
             "      'assets/oculum/home_art_authored/theme_${id}_canon_20261118.webp',\n")
    anchor = "    'corrotti_di_sabbia' || 'resilium' || 'material' =>\n"
    if '_november18ApprovedDesktopIds.contains(id)' not in themes:
        require(themes.count(anchor) == 1, 'Desktop guard anchor mismatch')
        themes = themes.replace(anchor, guard + anchor, 1)
    corrected_guard = (
        "    final id when _november18ApprovedDesktopIds.contains(id) =>\n"
        "      id == 'manichino_spada'\n"
        "          ? 'assets/oculum/home_art_authored/theme_manichino_spada_canon_20261118_v2.webp'\n"
        "          : 'assets/oculum/home_art_authored/theme_${id}_canon_20261118.webp',\n"
    )
    if corrected_guard not in themes:
        require(themes.count(guard) == 1, 'Corrected desktop guard anchor mismatch')
        themes = themes.replace(guard, corrected_guard, 1)
    tx.plan(theme_path, themes.replace('\n', theme_eol).encode('utf-8'))

    for vote, card, state, lot, option, content, target, manifest_path, manifest in checked:
        ident, name = vote['id'], vote['name']['value']
        relative = target.relative_to(ROOT).as_posix()
        receipt_path = BATCH / ident / 'CONFERMA-SCELTA.json'
        received_vote = vote.get('receivedAtUtc', received)
        selected_sha = vote['artwork'][0]['sha256']
        detail = {'slot': option['slot'], 'sha256': selected_sha, 'choiceName': name,
                  'choiceStatus': 'confermato', 'receipt': receipt_path.relative_to(ROOT).as_posix(),
                  'runtimeWebP': relative, 'receivedAtUtc': received_vote,
                  'runtimeSha256': sha(content),
                  'integrationStatus': 'in_attesa_verifiche'}
        receipt = {'schemaVersion': 1, 'id': ident, 'previousName': card['name'],
                   'choiceName': name, 'nameStatus': 'confirmed', 'status': 'selected',
                   'source': 'user_choice', 'signedFrom': 'chat',
                   'confirmationSource': source['source'], 'sourceReceipt': SOURCE.relative_to(ROOT).as_posix(),
                   'sourceSha256': source_sha, 'votePayloadSha256': vote_sha,
                   'atUtc': received_vote, 'receivedAtUtc': received_vote, 'integratedAtUtc': now,
                   'originalVote': vote, 'slot': option['slot'], 'sha256': selected_sha,
                   'runtimeSha256': sha(content), 'runtimeWebP': relative,
                   'artwork': [{**vote['artwork'][0], 'label': option['label'],
                       'file': (BATCH / option['file']).relative_to(ROOT).as_posix(), 'runtimeWebP': relative}],
                   'scope': 'Nome del catalogo e sfondo desktop; nessuna modifica meccanica.',
                   'phoneApproval': None, 'relicApproval': None, 'frameApproval': None,
                   'integrationStatus': 'in_attesa_verifiche', 'appModified': True,
                   'cleanupDeferredByGlobalCoordination': True, 'cleanupNotBeforeMinutes': 60}
        if ident in corrections:
            transformed = {**corrections[ident], 'runtimeWebP': relative}
            receipt.update(transformedArtwork=transformed,
                           correctionReceipt=transformed['correctionReceipt'])
            detail.update(transformedArtwork=transformed,
                          correctionReceipt=transformed['correctionReceipt'])
        tx.plan(receipt_path, raw(receipt))
        manifest.update(status='confermato', confirmation=detail['receipt'], selectedArtwork=detail,
                        integrationStatus='in_attesa_verifiche')
        manifest.pop('pendingArtworkCorrection', None)
        if ident in corrections:
            manifest['transformedArtwork'] = receipt['transformedArtwork']
        tx.plan(manifest_path, raw(manifest))
        card.update(confirmation=detail, confirmed=detail, choiceStatus='confermato')
        card['names'].update(status='confermato', selected=name)
        state.pop('pendingArtworkCorrection', None)
        state.update(detail, status='confermato')
        lot.update(status='confermato')
        lot.setdefault('delivery', {}).pop('pendingArtworkCorrection', None)
        lot.setdefault('delivery', {}).update(detail)
        local_gallery = BATCH / ident / 'GALLERIA.html'
        local_html = tx.read(local_gallery).decode('utf-8-sig')
        tag = '1205-' + ident
        local_html = re.sub(r'<p data-confirmed-artwork="' + re.escape(tag) + r'">.*?</p>', '', local_html)
        note = f'<p data-confirmed-artwork="{tag}">Confermato: {html.escape(name)} · {option["slot"]}. Solo desktop; telefono, reliquia e cornici restano separati.</p>'
        if ident in corrections:
            local_html = re.sub(r'<figure data-correction-1205="manichino_spada">.*?</figure>', '', local_html, flags=re.S)
            note += ('<figure data-correction-1205="manichino_spada">'
                     '<a href="C1-occhio-viola.webp"><img src="C1-occhio-viola.webp" alt="C1 · Occhio viola corretto"></a>'
                     '<figcaption>C1 · Versione corretta in uso: occhio viola. '
                     '<a href="C.webp">C storica con occhio ambra, conservata</a>.</figcaption></figure>')
        local_html, count = re.subn(r'(<h1>.*?</h1>)', lambda m: m[1] + note, local_html, count=1)
        require(count == 1, f'Gallery heading missing: {ident}')
        tx.plan(local_gallery, local_html.encode('utf-8'))
        article = f'<article data-id="{ident}">'
        require(page.count(article) == 1, f'Gallery article missing: {ident}')
        page = re.sub(r'<p data-confirmed-1205="' + re.escape(ident) + r'">.*?</p>', '', page)
        displayed_slot = 'C1 · correzione della C votata' if ident in corrections else option['slot']
        page = page.replace(article, article +
            f'<p data-confirmed-1205="{ident}">Confermato: {html.escape(name)} · {displayed_slot}</p>', 1)
        if ident in corrections:
            page = re.sub(r'<figure data-corrected-1205="manichino_spada">.*?</figure>', '', page, flags=re.S)
            page = page.replace(article, article +
                '<figure data-corrected-1205="manichino_spada">'
                '<a href="manichino_spada/C1-occhio-viola.webp"><img src="manichino_spada/C1-occhio-viola.webp" '
                'alt="Ensypuppet C1 · Occhio viola corretto" loading="lazy"></a>'
                '<figcaption>C1 corretta in uso · <a href="manichino_spada/C.webp">C storica con occhio ambra</a>.</figcaption></figure>', 1)

    choices.update(status='confermato', integrationStatus='in_attesa_verifiche')
    delivery.update(status='confermato', integrationStatus='in_attesa_verifiche', integratedAtUtc=now)
    prep.update(status='confermato', integrationStatus='in_attesa_verifiche')
    tx.plan(BATCH / 'SCELTE.json', raw(choices))
    tx.plan(BATCH / 'CONSEGNA.json', raw(delivery))
    tx.plan(PREP, raw(prep))
    serialized = json.dumps(choices, ensure_ascii=False).replace('<', '\\u003c')
    page, count = PAYLOAD.subn(lambda m: m[1] + serialized + m[3], page, count=1)
    require(count == 1, 'Gallery payload replacement failed')
    tx.plan(BATCH / 'GALLERIA.html', page.encode('utf-8'))
    summary = {'schemaVersion': 1, 'sourceReceipt': SOURCE.relative_to(ROOT).as_posix(),
               'sourceSha256': source_sha, 'votePayloadSha256': vote_sha,
               'receivedAtUtc': received, 'integratedAtUtc': now,
               'status': 'in_attesa_verifiche', 'appModified': True,
               'verifiedSelections': len(checked), 'desktopCopies': len(checked), 'catalogueNames': len(checked),
               'stableIdsPreserved': True, 'savedCustomizationModified': False,
               'anatomyOrRulesChanged': False, 'phoneRelicFramesApproved': False,
               'derivedArtworkCorrections': corrections,
               'flutterTestsExecuted': False, 'buildExecuted': False, 'cleanupExecuted': False,
               'assets': [{'id': v['id'], 'name': v['name']['value'], 'slot': o['slot'],
                           'sha256': sha(content), 'selectedSha256': v['artwork'][0]['sha256'],
                           'runtimeSlot': corrections.get(v['id'], {}).get('slot', o['slot']),
                           'file': target.relative_to(ROOT).as_posix()}
                          for v, _, _, _, o, content, target, _, _ in checked]}
    tx.plan(BATCH / 'INTEGRAZIONE-SORGENTI-20261118.json', raw(summary))
    # This is deliberately LAST: the received source is marked modified only
    # after all runtime copies, source hooks and their metadata are integrated.
    source.update(appModified=True, status='in_attesa_verifiche', integratedAtUtc=now,
                  sourceReceiptSha256BeforeIntegration=source_sha, votePayloadSha256=vote_sha,
                  integrationReceipt=(BATCH / 'INTEGRAZIONE-SORGENTI-20261118.json').relative_to(ROOT).as_posix())
    source['derivedArtworkCorrections'] = corrections
    require(source['receivedAtUtc'] == received, 'Received timestamp was altered')
    tx.plan(SOURCE, raw(source))
    return tx, summary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    tx, summary = prepare()
    if args.apply:
        tx.apply()
    print(json.dumps({'mode': 'applied' if args.apply else 'preview',
                      'verifiedSelections': summary['verifiedSelections'],
                      'plannedFiles': len(tx.updates), 'runtimeCopies': summary['desktopCopies'],
                      'status': summary['status']}, ensure_ascii=False))


if __name__ == '__main__':
    main()
