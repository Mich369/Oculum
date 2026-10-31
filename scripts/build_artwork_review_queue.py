"""Build a review queue, never images or automatic canonical approvals."""
import json
import html
import re
import hashlib
import os
import struct
import zlib
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/artwork/proposte_prossima_patch_2026-10-29'
INVENTORY = ROOT / 'docs/creature-art-inventory.json'
FIVE_OUT = ROOT / 'output/artwork/proposte_cinque_2026-10-30'
ARMADILLO_OUT = ROOT / 'output/artwork/ridisegni_2026-10-30/armadilli_base'
VARIANTS = ('A', 'B', 'C', 'D', 'E')
_PNG_CACHE = {}
APPROVED_DRAFTS = {
    'funghetto_cappuccio_rosso': ('funghetto_cappuccio_rosso_background_draft_v1.png', True),
    'costrutto_minore': ('costrutto_minore_background_draft_v1.png', True),
    'shadow_devil': ('shadow_devil_background_draft_v1.png', True),
    'mostro_sabbia': ('mostro_sabbia_background_draft_v2.png', True),
    'sharp': ('sharp_background_draft_v3.png', False),
    'topino_avventuroso': ('topino_avventuroso_background_draft_v2.png', False),
    'mosca_campana': ('mosca_campana_background_draft_v3.png', False),
    'gigante_sabbia': ('gigante_sabbia_background_draft_v6.png', True),
}


def artwork_path(value, manifest=None):
    """Resolve repository paths, absolute paths and manifest-local filenames."""
    if not isinstance(value, str) or not value.strip():
        return None
    path = Path(value.replace('\\', '/'))
    if path.is_absolute():
        return path
    root_path = ROOT / path
    if root_path.is_file() or manifest is None:
        return root_path
    local_path = manifest.parent / path
    return local_path if local_path.is_file() else root_path


def public_path(path):
    try:
        return path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def png_evidence(path):
    """Validate PNG chunks/CRC and scanlines using only the Python stdlib."""
    if path is None:
        return {'exists': False, 'pngVerified': False}
    key = str(path.resolve())
    if key in _PNG_CACHE:
        return _PNG_CACHE[key]
    result = {'exists': path.is_file(), 'pngVerified': False}
    if result['exists']:
        try:
            data = path.read_bytes()
            result['sha256'] = hashlib.sha256(data).hexdigest()
            if data[:8] != b'\x89PNG\r\n\x1a\n':
                raise ValueError('not a PNG')
            position, idat, header, ended = 8, [], None, False
            while position < len(data):
                if position + 12 > len(data):
                    raise ValueError('truncated PNG chunk')
                length = struct.unpack('>I', data[position:position + 4])[0]
                kind = data[position + 4:position + 8]
                payload = data[position + 8:position + 8 + length]
                stop = position + 12 + length
                if stop > len(data):
                    raise ValueError('truncated PNG payload')
                expected_crc = struct.unpack('>I', data[stop - 4:stop])[0]
                if zlib.crc32(kind + payload) & 0xffffffff != expected_crc:
                    raise ValueError('PNG CRC mismatch')
                if kind == b'IHDR':
                    header = struct.unpack('>IIBBBBB', payload)
                elif kind == b'IDAT':
                    idat.append(payload)
                elif kind == b'IEND':
                    ended = True
                    break
                position = stop
            if not header or not ended or not idat:
                raise ValueError('incomplete PNG')
            width, height, depth, colour, compression, filtering, interlace = header
            channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(colour)
            if not channels or not width or not height or compression or filtering:
                raise ValueError('unsupported PNG header')
            result.update(width=width, height=height)
            if interlace:
                # Presence is evidence, but do not claim a full decode we did not do.
                raise ValueError('interlaced PNG needs separate decoder validation')
            pixels = zlib.decompress(b''.join(idat))
            row_size = (width * channels * depth + 7) // 8 + 1
            if len(pixels) != row_size * height or any(
                    pixels[offset] > 4 for offset in range(0, len(pixels), row_size)):
                raise ValueError('invalid PNG scanlines')
            result['pngVerified'] = True
        except (OSError, ValueError, struct.error, zlib.error) as error:
            result['error'] = str(error)
    _PNG_CACHE[key] = result
    return result


def manifest_creatures(batch):
    """Normalise nested entries or flat files/proposals, retaining their IDs."""
    collections = []
    for collection in ('entries', 'files', 'proposals'):
        rows = batch.get(collection, [])
        if isinstance(rows, dict):
            rows = [dict(value, variant=letter) for letter, value in rows.items()
                    if isinstance(value, dict)]
        collections.append(rows if isinstance(rows, list) else [])
    flat_rows = [row for rows in collections for row in rows
                 if isinstance(row, dict) and row.get('proposals') is None]
    top_id = batch.get('creature_id') or batch.get('monster_id')
    top_species = batch.get('species')
    # Some single-species files put the creature ID/display name at the top,
    # while each flat row's name describes that particular A-E design.
    # Do not apply the top-level identity to a genuinely mixed-species batch.
    explicit_ids = {row.get('creature_id') or row.get('monster_id') or row.get('artwork_key')
                    for row in flat_rows}
    species_values = {row.get('species') for row in flat_rows}
    single_id = (top_id if top_id and explicit_ids <= {None, top_id} and
                 species_values <= {None, top_id, top_species} else None)
    groups = {}
    for rows in collections:
        for row in rows:
            if not isinstance(row, dict):
                continue
            nested = row.get('proposals')
            if nested is not None:
                key = (row.get('id') or row.get('artwork_key') or row.get('creature_id') or
                       row.get('monster_id') or row.get('species'))
                name = row.get('name') or batch.get('name') or key
                proposals = nested
                if isinstance(proposals, dict):
                    proposals = [dict(value, variant=letter) for letter, value in proposals.items()
                                 if isinstance(value, dict)]
            else:
                key = (row.get('creature_id') or row.get('monster_id') or row.get('artwork_key') or
                       single_id or row.get('species') or batch.get('species') or row.get('id'))
                name = ((top_species if top_species != single_id else None) or batch.get('name') or
                        row.get('name') or key) if single_id and key == single_id else (
                            row.get('name') or batch.get('name') or key)
                proposals = [row]
            if not key:
                continue
            group = groups.setdefault(key, {**row, 'id': key,
                                            'name': name,
                                            'proposals': []})
            for proposal in proposals if isinstance(proposals, list) else []:
                if not isinstance(proposal, dict):
                    continue
                variant = str(proposal.get('variant') or proposal.get('letter') or '').upper()
                if variant in VARIANTS:
                    normalised = {**proposal, 'variant': variant}
                    if (nested is None and single_id and key == single_id and
                            not normalised.get('title') and proposal.get('name') != name):
                        normalised['title'] = proposal.get('name')
                    group['proposals'].append(normalised)
    for group in groups.values():
        # Multiple collection aliases must not count the same output twice.
        unique = {}
        for proposal in group['proposals']:
            unique[(proposal['variant'], proposal.get('output_path') or proposal.get('file'))] = proposal
        group['proposals'] = list(unique.values())
    return [group for group in groups.values() if group['proposals']]


def five_manifests():
    manifests = set(FIVE_OUT.rglob('*manifest*.json')) if FIVE_OUT.exists() else set()
    if ARMADILLO_OUT.exists():
        manifests.update(ARMADILLO_OUT.glob('*manifest*.json'))
    return sorted(path for path in manifests if path.parent != FIVE_OUT)


def proposal_path(proposal, manifest):
    return artwork_path(proposal.get('output_path') or proposal.get('file'), manifest)


def exact_approved_proposal(choice, path):
    if not choice or path is None:
        return False
    selected = artwork_path(choice.get('output_path'))
    if selected and selected.resolve() == path.resolve():
        return True
    evidence = png_evidence(path)
    return bool(evidence.get('pngVerified') and choice.get('sha256') and
                evidence.get('sha256') == choice['sha256'])


def write_questions_index():
    """Link source questions without rewriting them or implying approval."""
    target = FIVE_OUT / 'DOMANDE_AL_RISVEGLIO.md'
    sources = sorted(path for path in FIVE_OUT.rglob('DOMANDE*.md')
                     if path.parent != FIVE_OUT)
    lines = [
        '# Domande artwork al risveglio', '',
        'Indice dei documenti di domande dei nuovi lotti. Le domande rimangono '
        'nei rispettivi file originali: nessuna risposta o approvazione è dedotta '
        'dalla presenza in questo elenco.', '',
        '[Galleria unica delle cinque proposte](GALLERIA.html)', '',
    ]
    for path in sources:
        relative = path.relative_to(FIVE_OUT).as_posix()
        label = path.parent.relative_to(FIVE_OUT).as_posix().replace('_', ' ')
        lines.append(f'- [{label} — {path.name}]({relative})')
    lines.extend(['', f'Documenti collegati: {len(sources)}. '
                  'Ogni rigenerazione aggiunge automaticamente i nuovi file '
                  'DOMANDE delle sottocartelle, senza modificarne il contenuto.', ''])
    target.write_text('\n'.join(lines), encoding='utf-8')
    return target


def derivatives_explicitly_approved(manifest, expected_species_count=1):
    """Check selected derivative receipts; historical rejected files do not count."""
    if not manifest.is_file():
        return False
    payload = json.loads(manifest.read_text(encoding='utf-8-sig'))
    selected = [item for item in payload.get('files', [])
                if item.get('selected', True)]
    by_species = defaultdict(list)
    for item in selected:
        by_species[item.get('species') or item.get('creature_id')].append(item)
    if len(by_species) != expected_species_count or any(
            species is None or len(items) != 2 or
            {item.get('kind') for item in items} != {'phone', 'relic'}
            for species, items in by_species.items()):
        return False
    for item in selected:
        if item.get('user_approved') is not True:
            return False
        evidence = png_evidence(artwork_path(item.get('output_path'), manifest))
        if not evidence.get('pngVerified'):
            return False
        expected = item.get('sha256') or (item.get('metadata') or {}).get('sha256')
        if expected and evidence.get('sha256') != expected:
            return False
    return True


def write_five_gallery(batches, canonical):
    """Unified review page; missing proposals stay visible as pending slots."""
    FIVE_OUT.mkdir(parents=True, exist_ok=True)
    links, sections, groups, verified_files = [], [], [], set()
    known_lots = [
        (FIVE_OUT / 'lotto_campana_mammuth/GALLERIA_CINQUE.html', 'Custode e Mammuth'),
        (FIVE_OUT / 'sciamano_malizioso/GALLERIA.html', 'Sciamano Malizioso'),
        (ARMADILLO_OUT / 'GALLERIA_ARMADILLO_BASE.html', 'Armadillo Corazzato'),
    ]
    for target, name in known_lots:
        if not target.is_file() and name == 'Sciamano Malizioso':
            alternatives = sorted(target.parent.glob('GALLERIA*.html'))
            target = alternatives[0] if alternatives else target
        if not target.is_file():
            manifests = sorted(target.parent.glob('manifest*.json'))
            target = manifests[0] if manifests else target
        if target.is_file():
            href = html.escape(Path(os.path.relpath(target, FIVE_OUT)).as_posix(), quote=True)
            links.append(f'<a href="{href}">{html.escape(name)} — lotto completo</a>')
        else:
            links.append(f'<span>{html.escape(name)} — galleria locale in preparazione</span>')
    shaman_derivatives = FIVE_OUT / 'sciamano_malizioso/GALLERIA_DERIVATI.html'
    if shaman_derivatives.is_file():
        href = html.escape(Path(os.path.relpath(shaman_derivatives, FIVE_OUT)).as_posix(), quote=True)
        approved = derivatives_explicitly_approved(shaman_derivatives.parent / 'manifest_derivati.json')
        state = 'approvati separatamente' if approved else 'da valutare separatamente'
        links.append(f'<a href="{href}">Sciamano B — telefono e reliquia {state}</a>')
    trio_derivatives = FIVE_OUT / 'derivati_custode_mammuth_armadillo/GALLERIA_DERIVATI.html'
    if trio_derivatives.is_file():
        href = html.escape(Path(os.path.relpath(trio_derivatives, FIVE_OUT)).as_posix(), quote=True)
        approved = derivatives_explicitly_approved(
            trio_derivatives.parent / 'manifest_derivati.json', expected_species_count=3)
        state = 'approvati separatamente' if approved else 'ancora da valutare'
        links.append(f'<a href="{href}">Custode, Mammuth e Armadillo — sei derivati {state}</a>')
    questions = write_questions_index()
    href = html.escape(questions.name, quote=True)
    links.append(f'<a href="{href}">Domande accumulate al risveglio</a>')
    for manifest, batch in batches:
        if manifest not in five_manifests():
            continue
        for creature in batch['entries']:
            key = creature['id']
            by_variant = {proposal['variant']: proposal for proposal in creature['proposals']}
            cards, records = [], []
            for letter in VARIANTS:
                proposal = by_variant.get(letter, {})
                path = proposal_path(proposal, manifest)
                evidence = png_evidence(path)
                expected = proposal.get('sha256') or (proposal.get('metadata') or {}).get('sha256')
                verified = bool(evidence.get('pngVerified') and
                                (not expected or evidence.get('sha256') == expected))
                approved = exact_approved_proposal(canonical.get(key), path)
                status = ('approved_selected' if approved and verified else
                          'generated_pending_human_review' if verified else
                          'file_invalid_or_hash_mismatch' if evidence.get('exists') else 'pending')
                record = {'variant': letter, 'status': status, 'userApproved': approved,
                          'file': public_path(path) if path else None, 'evidence': evidence}
                records.append(record)
                if verified:
                    verified_files.add(str(path.resolve()))
                    href = html.escape(Path(os.path.relpath(path, FIVE_OUT)).as_posix(), quote=True)
                    label = html.escape(str(proposal.get('title') or proposal.get('design_direction') or letter))
                    state = 'CANONICO — scelta esplicita' if approved else 'Da scegliere'
                    warnings = proposal.get('qa_warnings') or []
                    warnings = [warnings] if isinstance(warnings, str) else warnings
                    warning_note = ('<p>Da verificare: ' + '; '.join(
                        html.escape(str(item)) for item in warnings) + '</p>') if warnings else ''
                    cards.append(f'<figure><a href="{href}" target="_blank"><img loading="lazy" src="{href}" alt="{html.escape(creature["name"])} {letter}"></a><figcaption><strong>{letter} — {label}</strong><br>{state}{warning_note}</figcaption></figure>')
                else:
                    detail = 'File da verificare' if evidence.get('exists') else 'Ancora da produrre'
                    cards.append(f'<figure class="pending"><strong>{letter}</strong><p>{detail}</p></figure>')
            groups.append({'id': key, 'name': creature['name'], 'manifest': public_path(manifest),
                           'requestedSlots': 5, 'verifiedProposals': sum(
                               record['status'] in ('approved_selected', 'generated_pending_human_review')
                               for record in records), 'proposals': records})
            sections.append(f'<section><h2>{html.escape(creature["name"])}</h2><div class="choices">'+''.join(cards)+'</div></section>')
    page = '''<!doctype html><html lang="it"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Oculum — cinque proposte per mostro</title><style>body{background:#15141a;color:#e4d4b0;font:17px system-ui;margin:24px auto;max-width:1800px;padding:0 16px}h1,h2{font-family:Georgia,serif}p{max-width:90ch;line-height:1.6}.choices{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}figure{margin:0;background:#242129;border:1px solid #645337;border-radius:8px;overflow:hidden}img{display:block;width:100%;height:auto}figcaption{padding:12px}section{margin:42px 0}a{color:#dec18c}nav{display:flex;gap:18px;flex-wrap:wrap}.pending{min-height:180px;padding:24px;box-sizing:border-box;color:#b3a995}@media(max-width:800px){.choices{grid-template-columns:1fr}}</style><h1>Cinque proposte per mostro</h1><p>Cinque design A–E della stessa creatura: sagoma, posa, colori e ambiente possono cambiare mantenendo i dettagli fissati. Non sono nuove specie o evoluzioni. Le immagini non marcate CANONICO restano da scegliere; gli slot senza PNG verificato restano in lavorazione. Le precedenti serie A/B/C sono conservate nello storico.</p><nav>'''+''.join(links)+'</nav><p><a href="../proposte_prossima_patch_2026-10-29/GALLERIA.html">Storico A/B/C</a> · <a href="../derivati_canonici_2026-10-30_lotto2/GALLERIA_LOTTO2.html">Ventidue derivati approvati</a></p>'+''.join(sections)+'</html>\n'
    (FIVE_OUT / 'GALLERIA.html').write_text(page, encoding='utf-8')
    report = {'schemaVersion': 1, 'policy': 'Explicit approval only; planned slots are not PNG evidence.',
              'plannedProposalSlots': 5 * len(groups), 'verifiedUniquePNGFiles': len(verified_files),
              'pendingSlots': sum(record['status'] == 'pending' for group in groups for record in group['proposals']),
              'groups': groups}
    (FIVE_OUT / 'manifest_galleria.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return report


def main():
    inventory = json.loads(INVENTORY.read_text(encoding='utf-8-sig'))
    entries = inventory['entries']
    selection_file = OUT / 'selezione_canonica_cinque_2026-10-29.json'
    selections = (json.loads(selection_file.read_text(encoding='utf-8')).get('files', [])
                  if selection_file.exists() else [])
    canonical = {entry['id']: entry for entry in selections}
    recent_selections = ROOT / 'output/artwork/approvazioni_2026-10-30/manifest_approvazioni.json'
    if recent_selections.exists():
        for entry in json.loads(recent_selections.read_text(encoding='utf-8'))['files']:
            if entry.get('user_approved') is True:
                canonical[entry['id']] = entry
    derivatives_file = OUT / 'derivati_canonici_cinque/manifest_derivati_cinque.json'
    derivative_data = (json.loads(derivatives_file.read_text(encoding='utf-8'))
                       if derivatives_file.exists() else {})
    complete_selected = {entry['id'] for entry in derivative_data.get('entries', [])
                         if len(entry['derivatives']) == 2 and
                         all(item.get('user_approved') is True for item in entry['derivatives'])}
    approved_derivatives = {
        (entry['id'], item.get('kind'), str(artwork_path(item.get('output_path'))))
        for entry in derivative_data.get('entries', []) for item in entry.get('derivatives', [])
        if item.get('user_approved') is True
    }
    lotto2_file = ROOT / 'output/artwork/derivati_canonici_2026-10-30_lotto2/manifest_derivati.json'
    lotto2_approved = []
    if lotto2_file.exists():
        lotto2 = json.loads(lotto2_file.read_text(encoding='utf-8-sig'))
        lotto2_approved = [item for item in lotto2.get('files', [])
                          if item.get('user_approved') is True]
        species_kinds = defaultdict(set)
        for item in lotto2_approved:
            species = item.get('species') or item.get('creature_id')
            if species:
                species_kinds[species].add(item.get('kind'))
                approved_derivatives.add((species, item.get('kind'),
                                          str(artwork_path(item.get('output_path'), lotto2_file))))
        complete_selected.update(species for species, kinds in species_kinds.items()
                                 if {'phone', 'relic'} <= kinds)
    five_kinds = defaultdict(set)
    for path in sorted((ROOT / 'output/artwork/proposte_cinque_2026-10-30').rglob('manifest_derivati.json')):
        payload = json.loads(path.read_text(encoding='utf-8-sig'))
        for item in payload.get('files', []):
            if item.get('user_approved') is True and item.get('selected', True):
                candidate = artwork_path(item.get('output_path'))
                if candidate and candidate.is_file():
                    approved_derivatives.add((item.get('species'), item.get('kind'), str(candidate)))
                    five_kinds[item.get('species')].add(item.get('kind'))
    complete_selected.update(species for species, kinds in five_kinds.items()
                             if {'phone', 'relic'} <= kinds)
    copy_report = ROOT / 'output/artwork/APPROVED_NEXT_PATCH_ASSETS_2026-10-29.json'
    copied_ids = ({entry['monsterId'] for entry in json.loads(copy_report.read_text(encoding='utf-8'))['selections']}
                  if copy_report.exists() else set())
    rows = []
    batches = []
    produced = {}
    history = defaultdict(list)
    proposal_evidence = {}
    historical_manifests = sorted(path for path in OUT.rglob('manifest_lotto_*.json')
                                  if re.fullmatch(r'manifest_lotto_\d+\.json', path.name))
    for manifest in historical_manifests + five_manifests():
        batch = json.loads(manifest.read_text(encoding='utf-8-sig'))
        if batch.get('status') == 'SUPERSEDED_DESIGN':
            continue
        batch = {**batch, 'entries': manifest_creatures(batch)}
        batches.append((manifest, batch))
        for creature in batch.get('entries', []):
            for proposal in creature.get('proposals', []):
                path = proposal_path(proposal, manifest)
                variant = proposal.get('variant')
                if path and variant in VARIANTS:
                    key = creature.get('id') or creature.get('artwork_key')
                    if key:
                        evidence = png_evidence(path)
                        expected = proposal.get('sha256') or (proposal.get('metadata') or {}).get('sha256')
                        evidence = {**evidence, 'expectedSha256Matches':
                                    evidence.get('sha256') == expected if expected else None}
                        candidate = public_path(path)
                        history[(key, variant)].append({'file': candidate, 'manifest': public_path(manifest),
                                                        'evidence': evidence})
                        if evidence.get('pngVerified') and evidence.get('expectedSha256Matches') is not False:
                            produced[(key, variant)] = candidate
                            proposal_evidence[(key, variant)] = evidence
                        if proposal.get('user_approved') is True:
                            canonical[key] = {**proposal, 'id': key, 'output_path': candidate}
    for index, entry in enumerate(entries):
        approved = APPROVED_DRAFTS.get(entry['id'])
        choice = canonical.get(entry['id'])
        has_desktop = bool(entry.get('themeAssetExists')) or approved is not None or choice is not None
        # Existing mapped artwork is preserved; mapping alone is not approval.
        review_required = not has_desktop
        rows.append({
            'id': entry['id'], 'name': choice.get('name', entry['name']) if choice else entry['name'],
            'sourceInventory': 'docs/creature-art-inventory.json',
            'sourceInventoryIndex': index,
            'sourceLocation': entry.get('sourceLocation'),
            'isGeneratedVariant': entry.get('isGeneratedVariant', False),
            'baseId': entry.get('baseId'),
            'approvedDesktop': (choice['output_path'] if choice else
                                'output/artwork/drafts_2026-10-29/' + approved[0]
                                if approved else None),
            'mappedDesktopToPreserve': entry.get('themeAsset'),
            'existingMappingDoesNotImplyApproval': True,
            'physicalDescriptionExcerpt': entry.get('physicalDescription', '')[:220],
            'anatomyReviewRequiredBeforeGeneration': True,
            'proposals': {key: {'status': ('approved_selected' if choice and choice.get('variant') == key
                                          else 'historical_alternative_not_selected' if choice
                                          else 'generated_pending_human_review'
                                          if (entry['id'], key) in produced
                                          else 'pending' if review_required
                                          else 'preserve_existing_desktop'),
                                'file': (choice['output_path'] if choice and choice.get('variant') == key
                                         else produced.get((entry['id'], key))),
                                'canonical': bool(choice and choice.get('variant') == key),
                                'evidence': (png_evidence(artwork_path(choice['output_path']))
                                    if choice and choice.get('variant') == key else
                                    proposal_evidence.get((entry['id'], key)))}
                          for key in VARIANTS},
            'proposalHistory': {key: history[(entry['id'], key)] for key in VARIANTS
                                if history[(entry['id'], key)]},
            'phoneAndRelicAfterSelection': True,
            'completeDraftPackSeparatelyApproved': bool(approved and approved[1]) or entry['id'] in complete_selected,
            'runtimeAssetCopiesHashVerified': entry['id'] in copied_ids,
            'runtimeIntegrationVerified': False,
        })
    # A newly requested creature may not exist in the last exported catalogue.
    # Keep it explicitly outside the export count until the next SDK export.
    ids = {e['id'] for e in entries}
    additional = [
        {'id': key, 'canonicalDesktop': 'output/artwork/drafts_2026-10-29/' + value[0],
         'fullDraftPackApproved': value[1], 'catalogueRefreshPending': True}
        for key, value in APPROVED_DRAFTS.items() if key not in ids
    ]
    OUT.mkdir(parents=True, exist_ok=True)
    report = {
        'schemaVersion': 1,
        'scope': 'All entries and variants in the exported catalogue; preserve existing canon and historical A/B/C series. New missing designs have five A-E proposal slots. Phone/relic follow explicit selection.',
        'inventoryExportedAtUtc': inventory.get('exportedAtUtc'),
        'sourceCatalogueRefreshPending': (not inventory.get('catalogueSourceHashes') or any(
            not (ROOT / path).is_file() or hashlib.sha256((ROOT / path).read_bytes()).hexdigest() != digest
            for path, digest in inventory.get('catalogueSourceHashes', {}).items())),
        'exportedEntries': len(entries),
        'newDesktopProposalSlots': sum(v['status'] == 'pending' for r in rows for v in r['proposals'].values()),
        'generatedImagesClaimedByThisQueue': 0,
        'generatedSelectionsWithManifestAndFile': len(produced),
        'generatedUniquePNGFilesVerified': len({item['file'] for items in history.values()
            for item in items if item['evidence'].get('pngVerified') and
            item['evidence'].get('expectedSha256Matches') is not False}),
        'newDesktopSelectionsExplicitlyApproved': len(canonical),
        'newDerivativeSelectionsExplicitlyApproved': len(approved_derivatives),
        'lotto2DerivativeSelectionsExplicitlyApproved': len(lotto2_approved),
        'approvalPolicy': 'Human selection only. Generated proposals never change anatomy, weak points or runtime automatically.',
        'productionEvidence': 'Separate per-batch manifests and INDICE.md; queue counts are plans, not generated or approved artwork.',
        'additionalConfirmedCreaturesOutsideLastExport': additional,
        'requestedDesignsNotYetInRuntimeCatalogue': [
            {'name': creature['name'], 'artworkKey': creature.get('artwork_key') or creature['id'],
             'runtimeId': None, 'canonical': (creature.get('artwork_key') or creature['id']) in canonical,
             'manifest': manifest.relative_to(ROOT).as_posix()}
            for manifest, batch in batches for creature in batch.get('entries', [])
            if creature.get('catalogue_entry_present') is False
        ],
        'entries': rows,
    }
    target = OUT / 'coda_artwork.json'
    target.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    sections = []
    for manifest, batch in batches:
        for creature in batch.get('entries', []):
            cards = []
            for proposal in creature.get('proposals', []):
                path = proposal_path(proposal, manifest)
                choice = canonical.get(creature.get('id') or creature.get('artwork_key'))
                # A later redesign may use the same letter for a different image.
                # The selected design is shown in the separate redesign gallery;
                # never relabel the historical image as newly approved.
                approved_choice = exact_approved_proposal(choice, path)
                if not path or not png_evidence(path).get('pngVerified'):
                    continue
                filename = html.escape(Path(os.path.relpath(path, OUT)).as_posix(), quote=True)
                label = html.escape(str(proposal.get('variant', '')))
                if approved_choice:
                    label += ' · CANONICO'
                caption = html.escape(str(proposal.get('title') or proposal.get('design_direction') or ''))
                cards.append(f'<figure><a href="{filename}"><img loading="lazy" src="{filename}" alt="Proposta {label}"></a><figcaption><strong>Proposta {label}</strong><br>{caption}</figcaption></figure>')
            if cards:
                title = html.escape(creature.get('name') or creature.get('id') or creature['artwork_key'])
                if creature.get('catalogue_entry_present') is False:
                    title += ' — creatura richiesta, ancora da integrare'
                sections.append(f'<section><h2>{title}</h2><div class="choices">{"".join(cards)}</div></section>')
    page = '''<!doctype html><html lang="it"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Oculum — proposte artwork</title>
<style>body{background:#15141a;color:#e4d4b0;font:17px system-ui;margin:24px auto;max-width:1600px;padding:0 16px}h1,h2{font-family:Georgia,serif}p{max-width:80ch;line-height:1.6}.choices{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px}figure{margin:0;background:#242129;border:1px solid #645337;border-radius:8px;overflow:hidden}img{display:block;width:100%;height:auto}figcaption{padding:12px}section{margin:42px 0}a{color:inherit}@media(max-width:800px){.choices{grid-template-columns:1fr}}</style>
<h1>Proposte artwork — Oculum</h1><p>Serie storiche A/B/C conservate; nuove serie con cinque proposte A–E. Soltanto le immagini segnate CANONICO hanno la tua approvazione esplicita; le altre restano proposte. Premi un’immagine per aprirla intera; per la valutazione indica il nome del mostro e la lettera, con eventuali correzioni.</p><p><a href="../proposte_cinque_2026-10-30/GALLERIA.html">NUOVE CINQUE PROPOSTE PER MOSTRO</a></p><p><a href="../ridisegni_2026-10-30/GALLERIA.html">RIDISEGNI E SCELTE DEL 30 OTTOBRE</a></p><p><a href="GALLERIA_DERIVATI.html">Telefono e reliquie delle cinque creature scelte</a></p>'''+''.join(sections)+'</html>\n'
    (OUT / 'GALLERIA.html').write_text(page, encoding='utf-8')
    five_report = write_five_gallery(batches, canonical)
    summary = {key: report[key] for key in ['exportedEntries', 'newDesktopProposalSlots',
               'generatedUniquePNGFilesVerified', 'sourceCatalogueRefreshPending',
               'newDerivativeSelectionsExplicitlyApproved', 'lotto2DerivativeSelectionsExplicitlyApproved']}
    summary['fiveProposalGallery'] = {key: five_report[key] for key in
                                    ['plannedProposalSlots', 'verifiedUniquePNGFiles', 'pendingSlots']}
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == '__main__':
    main()
