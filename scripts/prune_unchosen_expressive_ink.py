"""Prune proposals omitted by a confirmed Expressive Ink choice after one hour."""

import argparse
from collections import defaultdict
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile

if __package__:
    from . import prune_rejected_expressive_ink as legacy
    from .prune_rotation_gallery import render_rotation_gallery
else:
    import prune_rejected_expressive_ink as legacy
    from prune_rotation_gallery import render_rotation_gallery

IMAGE_ID, SHA256, WAIT_TIME = legacy.IMAGE_ID, legacy.SHA256, legacy.WAIT_TIME
is_link, json_object, lock_batch = legacy.is_link, legacy.json_object, legacy.lock_batch
ordinary_file, same_identity = legacy.ordinary_file, legacy.same_identity


ROOT = Path(__file__).resolve().parents[1]
BATCH = re.compile(r"expressive_ink_lotto_\d{2}")
FAMILY = re.compile(r"expressive_ink_lotto_\d{2}_(?:esistenti|inediti)")
ROTATION = re.compile(r'expressive_ink_giro_(\d{8})_(\d{4})')
ROTATION_RECEIPT = 'CONFERMA-SCELTA.json'
LARGE_LOT_PACKAGES = frozenset({
    'expressive_ink_aberrazione_superiore_angelica_20261115',
    'expressive_ink_armaiolo_rituale_20261115',
    'expressive_ink_bambola_vapium_veterana_20261115',
    'expressive_ink_balena_mille_occhi_20261116',
    'expressive_ink_cervo_radure_miti_20261116',
    'expressive_ink_custode_chiusa_20261116',
    'expressive_ink_demone_glaciale_minore_20261115',
    'expressive_ink_falena_del_delirio_20261116',
    'expressive_ink_faldavela_20261116',
    'expressive_ink_golem_ghiaie_orbitanti_20261116',
    'expressive_ink_larva_vespro_errante_20261115',
    'expressive_ink_lupo_infernale_ghiaccio_20261115',
    'expressive_ink_mammuth_decomposizione_20261115',
    'expressive_ink_marionettista_boss_20261115',
    'expressive_ink_medusa_vetro_blu_20261116',
    'expressive_ink_palmatore_dei_nastri_ostile_20261116',
    'expressive_ink_pawn_guardiano_20261115',
    'expressive_ink_pesce_mutato_20261116',
    'expressive_ink_pinepine_20261115',
    'expressive_ink_piovra_succhiasangue_20261116',
    'expressive_ink_piranha_mortale_20261116',
    'expressive_ink_predone_delle_nasse_20261116',
    'expressive_ink_rospo_gronde_marce_20261116',
    'expressive_ink_scarabeo_sigillo_ardente_20261116',
    'expressive_ink_scheletro_bombarolo_20261115',
    'expressive_ink_sempre_verde_20261116',
    'expressive_ink_sentinella_di_basalto_20261116',
    'expressive_ink_serracapo_mosaici_20261116',
    'expressive_ink_snorlo_base_20261115',
    'expressive_ink_tessitore_della_corrente_ostile_20261116',
    'expressive_ink_vedetta_canali_20261116',
    'expressive_ink_vortice_delle_arcate_20261116',
})
LARGE_LOT_GALLERIES = LARGE_LOT_PACKAGES | {
    'expressive_ink_grande_lotto_20261115',
    'expressive_ink_quarto_lotto_20261116',
    'expressive_ink_secondo_grande_lotto_20261115',
    'expressive_ink_terzo_lotto_20261116',
}
STANDALONE_PACKAGES = frozenset({
    'expressive_ink_guardia_solare',
    'expressive_ink_guardia_solare_elite',
    'expressive_ink_guardiano_solare',
    'expressive_ink_predone_boomerang_20261116',
    'expressive_ink_predone_boomerang_equipaggiamento_20261116',
    'expressive_ink_senka_staging_next',
}) | LARGE_LOT_PACKAGES
LETTER_PACKAGES = {
    'expressive_ink_falena_del_sudario_veterana_20261116': (
        'habitat_morti_falena_del_sudario_variante_veterana', 'CONFERMA-FUNERWING.json',
    ),
    'expressive_ink_gigante_sabbia_20261116': ('gigante_sabbia', 'CONFERMA-GIGANTE-SABBIA.json'),
    'expressive_ink_graga_azzurra_corazzata_20261116': (
        'graga_rana_azzurra_variante_corazzata', 'CONFERMA-GRAGALORYX.json',
    ),
    'expressive_ink_lince_di_brina_verde_20261116': (
        'habitat_foresta_elementale_lince_di_brina_verde_variante_corazzata',
        'CONFERMA-VYRIDFROST.json',
    ),
    'expressive_ink_lumin_gommoso_corazzata_20261116': (
        'lumin_gommoso_variante_corazzata', 'CONFERMA-LUMIN.json',
    ),
    'expressive_ink_mantide_della_vampa_20261116': (
        'ciclo_mantide_vampa', 'CONFERMA-TAVOLA-C.json',
    ),
    'expressive_ink_medusa_di_confettura_20261116': (
        'habitat_caramella_medusa_di_confettura', 'CONFERMA-TAVOLA-B.json',
    ),
    'expressive_ink_mostricciattolo_carta_rituale_20261116': (
        'mostricciattolo_di_carta_variante_rituale', 'CONFERMA-MIRUSFOLD.json',
    ),
    'expressive_ink_regina_delle_miniere_mute_rituale_20261116': (
        'habitat_sotterraneo_regina_delle_miniere_mute_variante_rituale',
        'CONFERMA-TACYANTEL.json',
    ),
    'expressive_ink_ragno_putrido_20261116': ('ragno_putrido', 'CONFERMA-VENEMUK.json'),
    'expressive_ink_scarabeo_dei_contratti_ardenti_20261116': (
        'habitat_diabolico_scarabeo_dei_contratti_ardenti', 'CONFERMA-PACTYCARAPACE.json',
    ),
    'expressive_ink_spaccaporte_corazzata_20261116': (
        'hero_path_diverso_ascia_variante_corazzata', 'CONFERMA-FORISPLIT.json',
    ),
    'expressive_ink_strana_presenza_20261116': ('strana_presenza', 'CONFERMA-STRANA-PRESENZA.json'),
    'expressive_ink_tassello_cupole_20261116': ('eiva_tassello_cupole', 'CONFERMA-TESSYFIN.json'),
}
CLEANUP_MANIFEST = 'MANIFEST-PULIZIA.json'
STANDALONE_IMAGE_ID = re.compile(r'[a-z0-9]+(?:[-_][a-z0-9]+)*')
STANDALONE_FILE_STEMS = {
    ('expressive_ink_faldavela_20261116', 'affogato_faldavela'): 'faldavela',
    ('expressive_ink_palmatore_dei_nastri_ostile_20261116', 'affogato_palmatore_dei_nastri'): 'palmatore_dei_nastri',
    ('expressive_ink_piovra_succhiasangue_20261116', 'piovra_succhiasangue'): 'affogato_piovra_succhiasangue',
    ('expressive_ink_predone_boomerang_20261116', 'affogato_predone_delle_nasse'): 'predone_boomerang',
    ('expressive_ink_predone_boomerang_equipaggiamento_20261116', 'affogato_predone_delle_nasse'): 'predone_boomerang',
    ('expressive_ink_senka_staging_next', 'senka_ombra_mascherata'): 'senka-ombra',
    ('expressive_ink_sentinella_di_basalto_20261116', 'affogato_sentinella_di_basalto'): 'sentinella_di_basalto',
    ('expressive_ink_tessitore_della_corrente_ostile_20261116', 'affogato_tessitore_della_corrente'): 'tessitore_della_corrente',
    ('expressive_ink_vedetta_canali_20261116', 'affogato_vedetta_dei_canali'): 'vedetta_dei_canali',
}
PROPOSALS = {'new_ink', 'new_distant', 'alternate_palette'}
JOURNAL = 'PULIZIA-SCELTE.json'


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def safe_path(root, path):
    if not path.is_absolute() or '..' in path.parts or not path.is_relative_to(root):
        raise ValueError(f'Percorso fuori dal perimetro: {path}')
    current = root
    for part in path.relative_to(root).parts:
        current /= part
        if is_link(current.lstat()):
            raise ValueError(f'Collegamento nel percorso: {current}')
    return current


def ordinary_children(root):
    return sorted(path for path in root.iterdir() if not is_link(path.lstat()))


def rotation_source(directory):
    match = ROTATION.fullmatch(directory.name)
    return '-'.join(match.groups()) if match else None


def dated(value):
    if not isinstance(value, str):
        return None
    when = datetime.fromisoformat(value.replace('Z', '+00:00'))
    return when if when.utcoffset() is not None else None


def delivery_rows(root, directory):
    source = rotation_source(directory)
    path = directory / 'CONSEGNA.json'
    if source is None or not path.is_file():
        return {}
    delivery = json_object(safe_path(root, path))
    lots = delivery.get('lots')
    if delivery.get('id') != f'oculum-10-lotti-{source}' or not isinstance(lots, list):
        return {}
    rows = {}
    for row in lots:
        ident = row.get('id') if isinstance(row, dict) else None
        if not isinstance(ident, str) or not IMAGE_ID.fullmatch(ident) or ident in rows:
            raise ValueError(f'ID di consegna non valido: {path}')
        rows[ident] = row
    return rows


def generated_letter(document, variant, rotation):
    if variant.get('sourceKind') is not None:
        return variant['sourceKind'] == 'imagegen_proposal'
    if not rotation:
        return False
    generation = document.get('generation') or {}
    prompts = generation.get('variantPrompts') or {}
    return (generation.get('tool') == 'ImageGen integrato' and bool(prompts.get(variant['slot']))
            or document.get('engine') == 'ImageGen built-in' and bool(variant.get('prompt')))


def letter_manifest(directory, document, previous, *, rotation=False):
    monster, receipt_name = ((directory.name, ROTATION_RECEIPT) if rotation
                             else LETTER_PACKAGES[directory.name])
    variants = document.get('variants')
    versions = {None, 1} if rotation else {1}
    if document.get('id') != monster or document.get('schemaVersion') not in versions or not isinstance(variants, list):
        return None
    if len(variants) != 8 or any(not isinstance(variant, dict) for variant in variants):
        return None
    if sorted(str(variant.get('slot')) for variant in variants) != list('ABCDEFGH'):
        return None

    receipt_path = directory / receipt_name
    receipt = json_object(receipt_path) if receipt_path.is_file() else {}
    slots = []
    for variant in variants:
        letter = variant['slot']
        if variant.get('status') == 'rejected_deleted':
            slots.append({
                'slot': letter, 'status': 'rejected_deleted',
                'choiceCleanup': variant.get('choiceCleanup'),
            })
            continue
        leaf = f'{letter}.webp'
        sha = variant.get('sha256')
        if variant.get('file') != leaf or not isinstance(sha, str) or not SHA256.fullmatch(sha):
            return None
        path = directory / leaf
        try:
            size = ordinary_file(path).st_size
        except FileNotFoundError:
            size = previous.get(str(path), {}).get('bytes')
        except ValueError:
            size = None
        artwork = {'path': str(path), 'sha256': sha, 'bytes': size}
        if receipt.get('slot') == letter:
            artwork.update(approvedFor=monster, approvalReceipt=str(receipt_path))
            category = 'approved'
        elif (rotation or letter != 'H') and generated_letter(document, variant, rotation):
            category = 'new_ink'
        else:
            category = 'previous'
        slots.append({
            'slot': letter, 'category': category, 'artwork': artwork,
            'status': 'verified_new' if category == 'new_ink' else 'verified_existing',
        })
    return {'entries': [{'id': monster, 'slots': slots}], 'letterManifest': document,
            'rotation': rotation}


def manifests(artwork, previous):
    result = {}
    root = artwork.parent.parent
    for directory in ordinary_children(artwork):
        if not directory.is_dir():
            continue
        if rotation_source(directory):
            for ident, row in delivery_rows(root, directory).items():
                path = directory / ident / 'MANIFEST.json'
                if (not row.get('shownAtUtc') or row.get('manifest') != path.relative_to(root).as_posix()
                        or not path.is_file()):
                    continue
                manifest = letter_manifest(path.parent, json_object(safe_path(root, path)), previous,
                                           rotation=True)
                if manifest is not None:
                    result[path] = manifest
            continue
        if directory.name in LETTER_PACKAGES:
            path = directory / 'MANIFEST.json'
            if path.is_file():
                manifest = letter_manifest(directory, json_object(path), previous)
                if manifest is not None:
                    result[path] = manifest
            continue
        if directory.name in STANDALONE_PACKAGES:
            path = directory / CLEANUP_MANIFEST
            if path.is_file():
                ordinary_file(path)
                manifest = json_object(path)
                if manifest.get('schemaVersion') == 1 and manifest.get('batchId') == directory.name:
                    result[path] = manifest
            if directory.name not in LARGE_LOT_PACKAGES:
                continue
        if BATCH.fullmatch(directory.name) or directory.name in LARGE_LOT_GALLERIES:
            folders = [directory]
        elif FAMILY.fullmatch(directory.name):
            folders = [child for child in ordinary_children(directory) if child.is_dir()]
        else:
            continue
        for folder in folders:
            path = folder / 'MANIFEST.json'
            if path.is_file():
                manifest = json_object(path)
                if manifest.get('schemaVersion') == 1 and manifest.get('batchId'):
                    result[path] = manifest
    return result


def selected_at(root, monster, slot):
    art = slot.get('artwork', {})
    if slot.get('category') != 'approved' or art.get('approvedFor', monster) != monster:
        return None
    if not isinstance(art.get('approvalReceipt'), str):
        return None
    path = safe_path(root, Path(art['approvalReceipt']))
    receipt = json_object(path)
    return confirmed_at(root, monster, slot, receipt)


def confirmed_at(root, monster, slot, receipt):
    art = slot['artwork']
    if (
        receipt.get('approvedFor', receipt.get('id')) != monster
        or receipt.get('gallerySlot', receipt.get('slot')) != slot['slot']
        or receipt.get('sha256File', receipt.get('sha256')) != art.get('sha256')
        or receipt.get('status', 'selected') != 'selected'
    ):
        return None
    raw = receipt.get('atUtc') or receipt.get('acknowledgedAtUtc')
    if not isinstance(raw, str):
        return None
    when = dated(raw)
    if when is None:
        return None
    chosen = safe_path(root, Path(art['path']))
    ordinary_file(chosen)
    return when if digest(chosen) == art.get('sha256') else None


def is_webp(path):
    with path.open('rb') as stream:
        header = stream.read(12)
    return header.startswith(b'RIFF') and header[8:12] == b'WEBP'


def rotation_selected_at(root, directory, monster, slot, receipt_path, chosen, receipt):
    batch = directory.parent
    row = delivery_rows(root, batch).get(monster, {})
    art = slot['artwork']
    hashes = row.get('hashes') or {}
    if (directory.name != monster or receipt_path.name != ROTATION_RECEIPT
            or chosen.name != f'{slot["slot"]}.webp'
            or row.get('choiceStatus') != 'confermato' or row.get('slot') != slot['slot']
            or row.get('sha256') != art['sha256'] or hashes.get(slot['slot']) != art['sha256']
            or row.get('receipt') != receipt_path.relative_to(root).as_posix()
            or row.get('manifest') != (directory / 'MANIFEST.json').relative_to(root).as_posix()
            or receipt.get('source') != 'user_choice' or receipt.get('signedFrom') != 'chat'
            or receipt.get('confirmationSource') != f'galleria-lotti-{rotation_source(batch)}'
            or receipt.get('status') != 'selected'):
        return None
    shown = dated(row.get('shownAtUtc'))
    when = confirmed_at(root, monster, slot, receipt)
    if not shown or not when or when < shown or not is_webp(chosen):
        return None
    claims = receipt.get('artwork')
    if not isinstance(claims, list) or len(claims) != 1 or not isinstance(claims[0], dict):
        return None
    claim = claims[0]
    if (claim.get('surface') != 'desktop' or claim.get('slot') != slot['slot']
            or claim.get('sha256') != art['sha256'] or claim.get('file') != chosen.relative_to(root).as_posix()):
        return None
    runtime = Path(receipt.get('runtimeWebP') or '.')
    if (runtime.parent != Path('assets/oculum/home_art_authored')
            or not re.fullmatch(fr'theme_{re.escape(monster)}_canon_\d{{8}}(?:_[a-z0-9_]+)?\.webp', runtime.name)):
        return None
    runtime = safe_path(root, root / runtime)
    ordinary_file(runtime)
    return when if is_webp(runtime) and digest(runtime) == art['sha256'] else None


def standalone_selected_at(root, directory, monster, slot):
    art = slot.get('artwork') or {}
    if (slot.get('category') != 'approved' or art.get('approvedFor') != monster
            or not isinstance(art.get('approvalReceipt'), str) or not isinstance(art.get('path'), str)):
        return None
    receipt_path = Path(art['approvalReceipt'])
    chosen = Path(art['path'])
    if (receipt_path.parent != directory or receipt_path.suffix != '.json'
            or chosen.parent != directory or chosen.suffix != '.webp'):
        return None
    try:
        receipt_path = safe_path(root, receipt_path)
        chosen = safe_path(root, chosen)
        ordinary_file(receipt_path)
        ordinary_file(chosen)
        receipt = json_object(receipt_path)
        if rotation_source(directory.parent):
            return rotation_selected_at(root, directory, monster, slot, receipt_path, chosen, receipt)
        if directory.name in LETTER_PACKAGES:
            # Letter lots must have a verified copy in the runtime bundle.
            expected_id, expected_receipt = LETTER_PACKAGES[directory.name]
            runtime_relative = Path('assets', 'oculum', 'home_art_authored',
                                    f'theme_{expected_id}_canon_20261116.webp')
            confirmation = receipt.get('confirmationSource')
            if (
                monster != expected_id or receipt_path.name != expected_receipt
                or receipt.get('source') != 'user_choice' or receipt.get('signedFrom', 'chat') != 'chat'
                or receipt.get('status') != 'selected'
                or not isinstance(confirmation, str) or not re.fullmatch(r'call_[a-f0-9]+', confirmation)
                or Path(receipt.get('comparisonSource') or '.') != chosen
                or Path(receipt.get('runtimeWebP') or '.') != runtime_relative
            ):
                return None
            runtime = safe_path(root, root / runtime_relative)
            ordinary_file(runtime)
            if not is_webp(chosen) or not is_webp(runtime) or digest(runtime) != art.get('sha256'):
                return None
            return confirmed_at(root, monster, slot, receipt)
        if (receipt.get('source') != 'user_choice' or receipt.get('signedFrom') != 'chat'
                or receipt.get('status') != 'selected'
                or Path(receipt.get('canonicalWebP') or '.') != chosen or not is_webp(chosen)):
            return None
        return confirmed_at(root, monster, slot, receipt)
    except (OSError, ValueError, KeyError, TypeError):
        return None


def proposal(monster, slot, *, standalone_pack=None, letter_format=False):
    art = slot.get('artwork', {})
    sha = art.get('sha256')
    letter = slot.get('slot', '')
    path = Path(art.get('path') or '.')
    size = art.get('bytes')
    file_stem = STANDALONE_FILE_STEMS.get((standalone_pack, monster), monster)
    stem = re.escape(file_stem)
    hyphenated = file_stem.replace('_', '-')
    if standalone_pack and hyphenated != file_stem:
        stem = '(?:' + stem + '|' + re.escape(hyphenated) + ')'
    valid_letter = isinstance(letter, str) and re.fullmatch(
        r'[A-H](?:[1-9][0-9]*)?' if standalone_pack else r'[A-H]', letter
    )
    filename_matches = (
        path.name == f'{letter}.webp'
        if letter_format else
        re.fullmatch(fr'{stem}-{letter.lower()}(?:-v\d+)?\.webp', path.name) if valid_letter else False
    )
    if (
        slot.get('status') != 'verified_new' or slot.get('category') not in PROPOSALS
        or art.get('approvedFor') or art.get('approvalReceipt')
        or not valid_letter or not isinstance(sha, str)
        or not SHA256.fullmatch(sha) or type(size) is not int or size <= 0
        or not filename_matches
    ):
        return None
    return path, sha, size


def files_under(folder):
    if not folder.exists() or is_link(folder.lstat()):
        return
    for directory, dirs, files in os.walk(folder, followlinks=False):
        base = Path(directory)
        dirs[:] = [name for name in dirs if not is_link((base / name).lstat())]
        for name in files:
            path = base / name
            info = path.lstat()
            if stat.S_ISREG(info.st_mode) and not is_link(info):
                yield path, info


def rotation_external_references(root, artwork, eligible, rotation_paths):
    tokens = defaultdict(set)
    owned = {}
    for path in rotation_paths & eligible.keys():
        batch = path.parent.parent
        owned[path] = {
            path.parent / 'MANIFEST.json', path.parent / 'GALLERIA.html',
            batch / 'CONSEGNA.json', batch / 'GALLERIA.html', batch / 'SCELTE.json',
        }
        relative = path.relative_to(artwork).as_posix()
        for token in (relative, eligible[path]['sha256']):
            tokens[token.casefold().encode()].add(path)
    if not tokens:
        return set()
    pattern = re.compile(
        rb'[0-9a-f]{64}|expressive_ink_giro_\d{8}_\d{4}[\\/]+[a-z0-9_]+[\\/]+[a-h]\.webp',
        re.IGNORECASE,
    )
    protected = set()
    for base in (*(root / name for name in ('docs', 'design', 'assets', 'lib', 'scripts', '.github')), artwork):
        for path, _ in files_under(base):
            if path.suffix.lower() not in legacy.METADATA:
                continue
            for match in pattern.finditer(path.read_bytes()):
                token = re.sub(rb'[\\/]+', b'/', match.group().lower())
                protected.update(p for p in tokens.get(token, ()) if path not in owned[p])
    return protected


def build_plan(root, artwork, documents, now, previous):
    protected = set()
    references = defaultdict(set)
    decisions = {}
    pending = set()
    rotation_paths = set()
    manifest_directories = {path.parent for path in documents}
    standalone_directories = {
        path.parent for path, doc in documents.items()
        if path.name == CLEANUP_MANIFEST or 'letterManifest' in doc
    }
    for manifest_path, doc in documents.items():
        rotation_rows = delivery_rows(root, manifest_path.parent.parent) if doc.get('rotation') else {}
        standalone = manifest_path.parent in standalone_directories and (
            manifest_path.name == CLEANUP_MANIFEST or 'letterManifest' in doc
        )
        for entry in [*doc['entries'], *doc.get('referenceEntries', [])]:
            for slot in entry.get('slots', []):
                art = slot.get('artwork') or {}
                if art.get('path'):
                    path = Path(art['path'])
                    references[path].add(entry['id'])
                    if slot.get('category') not in PROPOSALS or art.get('approvedFor') or art.get('approvalReceipt'):
                        protected.add(art.get('sha256'))
        # Only signed per-creature sidecars authorize cleanup in these lots.
        # The visible galleries keep references in sync with actual removals.
        if not standalone and manifest_path.parent.name in LARGE_LOT_GALLERIES:
            continue
        for entry in [*doc['entries'], *doc.get('referenceEntries', [])]:
            monster = entry['id']
            image_id = STANDALONE_IMAGE_ID if standalone else IMAGE_ID
            if not image_id.fullmatch(monster) or (standalone and len(monster) > 160):
                continue
            votes = []
            for slot in entry['slots']:
                when = (standalone_selected_at(root, manifest_path.parent, monster, slot)
                        if standalone else selected_at(root, monster, slot))
                if when:
                    votes.append((when, slot))
            if not votes:
                continue
            when, chosen = max(votes, key=lambda vote: vote[0])
            for slot in entry['slots']:
                values = proposal(monster, slot, standalone_pack=manifest_path.parent.name if standalone else None,
                                  letter_format='letterManifest' in doc)
                if values is None:
                    continue
                path, sha, size = values
                if path in decisions or not path.is_relative_to(artwork) or path.parent not in manifest_directories:
                    continue
                if standalone and path.parent != manifest_path.parent:
                    continue
                if not standalone and path.parent in standalone_directories:
                    continue
                if doc.get('rotation'):
                    hashes = rotation_rows.get(monster, {}).get('hashes') or {}
                    if hashes.get(slot['slot']) != sha:
                        continue
                    rotation_paths.add(path)
                if now - when < WAIT_TIME:
                    pending.add(path)
                    continue
                row = {'id': monster, 'sha256': sha, 'bytes': size, 'selectedAtUtc': when.isoformat()}
                if standalone:
                    row['choiceProof'] = chosen
                try:
                    file = ordinary_file(safe_path(root, path))
                except (FileNotFoundError, ValueError):
                    if previous.get(str(path), {}).get('sha256') == sha and not path.exists():
                        decisions[path] = {**row, 'missing': True}
                    continue
                if datetime.fromtimestamp(file.st_mtime, timezone.utc) > when or file.st_size != size:
                    continue
                if (not standalone or is_webp(path)) and digest(path) == sha:
                    decisions[path] = row

    sizes = {row['bytes'] for row in decisions.values()}
    if sizes:
        for path, info in files_under(root / 'assets'):
            if info.st_size in sizes and path.suffix.lower() in {'.webp', '.png', '.jpg', '.jpeg'}:
                protected.add(digest(path))
        for path, info in files_under(artwork / 'expressive_ink_forest_errati'):
            if info.st_size in sizes and path.suffix.lower() == '.webp':
                protected.add(digest(path))
    git = subprocess.run(['git', '-C', str(root), 'ls-files', '-z', '--', 'output/artwork'],
                         capture_output=True, check=True)
    tracked = {os.fsdecode(name).casefold() for name in git.stdout.split(b'\0') if name}
    eligible = {path: row for path, row in decisions.items()
                if row['sha256'] not in protected and references[path] == {row['id']}
                and path.relative_to(root).as_posix().casefold() not in tracked}
    for path in rotation_external_references(root, artwork, eligible, rotation_paths):
        eligible.pop(path)
    by_signature = {(path.name, row['bytes'], row['sha256']): path for path, row in eligible.items()
                    if 'choiceProof' not in row}
    names = {key[:2] for key in by_signature}
    copies = defaultdict(list)
    for folder in ordinary_children(artwork):
        if (not folder.is_dir() or not folder.name.startswith('expressive_ink_')
                or 'staging' not in folder.name or folder.name in STANDALONE_PACKAGES):
            continue
        for path, info in files_under(folder):
            if (path.name, info.st_size) in names and info.st_nlink == 1 and path not in references:
                original = by_signature.get((path.name, info.st_size, digest(path)))
                if original and path.relative_to(root).as_posix().casefold() not in tracked:
                    copies[original].append(path)
    return eligible, copies, len(pending)


def atomic_text(path, content):
    with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=path.parent,
                                     prefix='.cleanup-', suffix='.tmp', delete=False) as file:
        temporary = Path(file.name)
        try:
            file.write(content)
        except BaseException:
            file.close()
            temporary.unlink()
            raise
    try:
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def atomic_json(path, data):
    atomic_text(path, json.dumps(data, indent=2, ensure_ascii=False) + '\n')


def letter_gallery_update(root, gallery, leaves, *, rotation):
    ordinary_file(safe_path(root, gallery))
    content = gallery.read_text(encoding='utf-8')
    tag = 'figure|article' if rotation else 'figure'
    plate_links = re.compile(r'''\b(?:href|src)=["']([A-H]\.webp)["']''')
    updated = re.sub(
        fr'<({tag})\b[^>]*>.*?</\1>',
        lambda card: '' if leaves.intersection(plate_links.findall(card[0])) else card[0],
        content, flags=re.DOTALL,
    )
    if rotation and leaves.intersection(plate_links.findall(updated)):
        raise ValueError(f'Schede delle tavole non riconosciute: {gallery}')
    return updated if updated != content else None


def refresh_letter_gallery(root, manifest, document):
    leaves = {f'{variant["slot"]}.webp' for variant in document['variants']
              if variant.get('status') == 'rejected_deleted'}
    gallery = manifest.with_name('GALLERIA.html')
    if leaves and gallery.exists():
        change = letter_gallery_update(root, gallery, leaves, rotation=bool(rotation_source(manifest.parent.parent)))
        if change is not None:
            atomic_text(gallery, change)


def rotation_gallery_updates(root, documents, planned):
    batches = defaultdict(dict)
    for path, doc in documents.items():
        if not doc.get('rotation'):
            continue
        rejected = {variant['slot'] for variant in doc['letterManifest']['variants']
                    if variant.get('status') == 'rejected_deleted' or path.with_name(f'{variant["slot"]}.webp') in planned}
        if rejected:
            gallery = path.with_name('GALLERIA.html')
            letter_gallery_update(root, gallery, {f'{slot}.webp' for slot in rejected}, rotation=True)
            batches[path.parent.parent][path.parent.name] = rejected
    updates = {}
    for batch, rejected in batches.items():
        for name in ('GALLERIA.html', 'SCELTE.json'):
            ordinary_file(safe_path(root, batch / name))
        updates.update(render_rotation_gallery(batch, rejected))
    return updates


def run(root, *, apply=False, now=None):
    root = root.resolve(strict=True)
    artwork = safe_path(root, root / 'output' / 'artwork')
    now = now or datetime.now(timezone.utc)
    journal = artwork / JOURNAL
    previous = json_object(journal) if journal.is_file() else {}
    documents = manifests(artwork, previous)
    snapshot = {path: ordinary_file(path) for path in documents}
    plan, copies, pending = build_plan(root, artwork, documents, now, previous)
    rotation_gallery_updates(root, documents, plan)
    if not apply or not (plan or previous):
        return [(path, row['bytes']) for path, row in plan.items() if not row.get('missing')] + [
            (copy, plan[original]['bytes']) for original, paths in copies.items() for copy in paths
        ], pending, []

    if any(not same_identity(before, ordinary_file(path)) for path, before in snapshot.items()):
        raise ValueError('Le gallerie sono cambiate durante la verifica')
    atomic_json(journal, {**previous, **{str(path): row for path, row in plan.items()}})
    done, removed, errors = {}, [], []
    for path, row in plan.items():
        if row.get('missing'):
            done[path] = row
        for candidate in [*([] if row.get('missing') else [path]), *copies[path]]:
            if candidate != path and path not in done:
                break
            try:
                before = ordinary_file(safe_path(root, candidate))
                if before.st_size != row['bytes'] or digest(candidate) != row['sha256']:
                    raise ValueError('Contenuto modificato')
                if not same_identity(before, ordinary_file(safe_path(root, candidate))):
                    raise ValueError('File modificato durante la verifica')
                if 'choiceProof' in row:
                    when = standalone_selected_at(root, path.parent, row['id'], row['choiceProof'])
                    if not when or when.isoformat() != row['selectedAtUtc']:
                        raise ValueError('Ricevuta di scelta modificata durante la verifica')
                candidate.unlink()
                removed.append((candidate, row['bytes']))
                if candidate == path:
                    done[path] = row
            except (OSError, ValueError) as error:
                errors.append(f'{candidate}: {error}')

    changed, refresh = set(), set()
    prior_hashes = {(row['id'], row['sha256']) for row in previous.values()}
    ordered = sorted(documents, key=lambda path: len(path.parts), reverse=True)
    for path in ordered:
        doc = documents[path]
        source_data = doc.get('source')
        sources = source_data.get('manifests', []) if isinstance(source_data, dict) else []
        count = 0
        primary_count = 0
        primary_ids = {entry['id'] for entry in doc['entries']}
        for entry in [*doc['entries'], *doc.get('referenceEntries', [])]:
            for slot in entry['slots']:
                if (entry['id'], (slot.get('choiceCleanup') or {}).get('sha256')) in prior_hashes:
                    refresh.add(path)
                art = slot.get('artwork') or {}
                row = done.get(Path(art.get('path', '.')))
                if row and art.get('sha256') == row['sha256'] and entry['id'] == row['id']:
                    slot['choiceCleanup'] = {**row, 'removedAtUtc': now.isoformat()}
                    slot['choiceCleanup'].pop('missing', None)
                    slot['choiceCleanup'].pop('choiceProof', None)
                    slot.pop('artwork')
                    slot['status'] = 'rejected_deleted'
                    count += 1
                    primary_count += entry['id'] in primary_ids
        if not count and not changed.intersection(Path(src['path']) for src in sources):
            continue
        if 'letterManifest' in doc:
            original = doc['letterManifest']
            slots = {slot['slot']: slot for slot in doc['entries'][0]['slots']}
            for variant in original['variants']:
                slot = slots[variant['slot']]
                if slot.get('status') == 'rejected_deleted' and 'file' in variant:
                    variant['status'] = slot['status']
                    variant['choiceCleanup'] = {**slot['choiceCleanup'], 'removedFile': variant.pop('file')}
            atomic_json(path, original)
            changed.add(path)
            continue
        doc['revision'] = doc.get('revision', 1) + 1
        counts = doc.get('counts', {})
        for key in ('ready', 'verified_new', 'verifiedNew', 'distinctArtworkFiles'):
            if key in counts:
                counts[key] = max(0, counts[key] - primary_count)
        if primary_count:
            counts['rejected_deleted'] = counts.get('rejected_deleted', 0) + primary_count
        for source in sources:
            source_path = Path(source['path'])
            if source_path in changed:
                source.update(sha256=digest(source_path), revision=documents[source_path]['revision'])
        atomic_json(path, doc)
        changed.add(path)

    # Keep the journal available until standalone galleries reflect their manifests.
    for path, doc in documents.items():
        if 'letterManifest' in doc:
            refresh_letter_gallery(root, path, doc['letterManifest'])
    for path, content in rotation_gallery_updates(root, documents, {}).items():
        atomic_text(path, content)

    # Trattiene le voci completate se un processo viene interrotto prima di salvare la galleria.
    if not errors:
        journal.unlink()
    galleries = [
        (path, 'gallery') for path in sorted(changed | refresh)
        if path.name != CLEANUP_MANIFEST and 'letterManifest' not in documents[path]
    ]
    return removed, pending, galleries + [(e, 'error') for e in errors]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--apply', action='store_true')
    mode.add_argument('--dry-run', action='store_true', help='Mostra il piano senza rimuovere file (predefinito)')
    args = parser.parse_args()
    try:
        artwork = safe_path(ROOT, ROOT / 'output' / 'artwork')
        if args.apply:
            with lock_batch(artwork):
                files, pending, actions = run(ROOT, apply=True)
        else:
            files, pending, actions = run(ROOT)
        for path, size in files:
            print(f'{path.relative_to(ROOT)}\t{size} byte')
        for target, action in actions:
            if action == 'gallery':
                subprocess.run([sys.executable, str(ROOT / 'scripts' / 'build_expressive_ink_gallery.py'),
                                str(target)], check=True)
            else:
                print(target, file=sys.stderr)
        state = 'rimossi' if args.apply else 'rimovibili in anteprima'
        print(f'{len(files)} file {state}, {sum(size for _, size in files)} byte. {pending} proposte in attesa.')
        return int(any(action == 'error' for _, action in actions))
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        parser.exit(2, f'{error}\n')


if __name__ == '__main__':
    sys.exit(main())
