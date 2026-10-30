"""Build a review queue, never images or automatic canonical approvals."""
import json
import html
import re
import hashlib
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/artwork/proposte_prossima_patch_2026-10-29'
INVENTORY = ROOT / 'docs/creature-art-inventory.json'
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
    copy_report = ROOT / 'output/artwork/APPROVED_NEXT_PATCH_ASSETS_2026-10-29.json'
    copied_ids = ({entry['monsterId'] for entry in json.loads(copy_report.read_text(encoding='utf-8'))['selections']}
                  if copy_report.exists() else set())
    rows = []
    batches = []
    produced = {}
    for manifest in sorted(OUT.rglob('manifest_lotto_*.json')):
        if not re.fullmatch(r'manifest_lotto_\d+\.json', manifest.name):
            continue
        batch = json.loads(manifest.read_text(encoding='utf-8-sig'))
        batches.append((manifest, batch))
        for creature in batch.get('entries', []):
            for proposal in creature.get('proposals', []):
                path = proposal.get('output_path')
                variant = proposal.get('variant')
                if path and variant in ['A', 'B', 'C'] and (ROOT / path).is_file():
                    key = creature.get('id') or creature.get('artwork_key')
                    if key:
                        produced[(key, variant)] = path
    for index, entry in enumerate(entries):
        approved = APPROVED_DRAFTS.get(entry['id'])
        choice = canonical.get(entry['id'])
        has_desktop = bool(entry.get('themeAssetExists')) or approved is not None or choice is not None
        # Existing mapped artwork is preserved; mapping alone is not approval.
        review_required = not has_desktop
        rows.append({
            'id': entry['id'], 'name': entry['name'],
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
            'proposals': {key: {'status': ('approved_selected' if choice and choice['variant'] == key
                                          else 'historical_alternative_not_selected' if choice
                                          else 'generated_pending_human_review'
                                          if (entry['id'], key) in produced
                                          else 'pending' if review_required
                                          else 'preserve_existing_desktop'),
                                'file': (choice['output_path'] if choice and choice['variant'] == key
                                         else produced.get((entry['id'], key))),
                                'canonical': bool(choice and choice['variant'] == key)}
                          for key in ['A', 'B', 'C']},
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
        'scope': 'All entries and variants in the exported catalogue; preserve existing canon. Three distinct desktop proposals for each new missing desktop. Phone/relic follow selection.',
        'inventoryExportedAtUtc': inventory.get('exportedAtUtc'),
        'sourceCatalogueRefreshPending': (not inventory.get('catalogueSourceHashes') or any(
            not (ROOT / path).is_file() or hashlib.sha256((ROOT / path).read_bytes()).hexdigest() != digest
            for path, digest in inventory.get('catalogueSourceHashes', {}).items())),
        'exportedEntries': len(entries),
        'newDesktopProposalSlots': sum(v['status'] == 'pending' for r in rows for v in r['proposals'].values()),
        'generatedImagesClaimedByThisQueue': 0,
        'generatedSelectionsWithManifestAndFile': len(produced),
        'newDesktopSelectionsExplicitlyApproved': len(canonical),
        'newDerivativeSelectionsExplicitlyApproved': sum(len(entry['derivatives'])
            for entry in derivative_data.get('entries', []) if entry['id'] in complete_selected),
        'approvalPolicy': 'Human selection only. Generated proposals never change anatomy, weak points or runtime automatically.',
        'productionEvidence': 'Separate per-batch manifests and INDICE.md; queue counts are plans, not generated or approved artwork.',
        'additionalConfirmedCreaturesOutsideLastExport': additional,
        'requestedDesignsNotYetInRuntimeCatalogue': [
            {'name': creature['name'], 'artworkKey': creature['artwork_key'],
             'runtimeId': None, 'canonical': creature['artwork_key'] in canonical,
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
                path = proposal.get('output_path', '')
                choice = canonical.get(creature.get('id') or creature.get('artwork_key'))
                # A later redesign may use the same letter for a different image.
                # The selected design is shown in the separate redesign gallery;
                # never relabel the historical image as newly approved.
                approved_choice = bool(choice and choice['variant'] == proposal.get('variant')
                                       and 'ridisegni_2026-10-30' not in choice.get('source_path', '')
                                       and '_origine_' not in choice.get('source_path', ''))
                if approved_choice:
                    path = choice['output_path']
                if not path or not (ROOT / path).is_file():
                    continue
                filename = html.escape(Path(os.path.relpath(ROOT / path, OUT)).as_posix(), quote=True)
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
<h1>Proposte artwork — Oculum</h1><p>Tre interpretazioni A/B/C per ciascuna creatura. Soltanto le immagini segnate CANONICO hanno la tua approvazione esplicita; le altre restano proposte. Premi un’immagine per aprirla intera; per la valutazione basta indicare il nome del mostro e A, B o C, con eventuali correzioni.</p><p><a href="../ridisegni_2026-10-30/GALLERIA.html">NUOVI RIDISEGNI E SCELTE DEL 30 OTTOBRE</a></p><p><a href="GALLERIA_DERIVATI.html">Telefono e reliquie delle cinque creature scelte</a></p>'''+''.join(sections)+'</html>\n'
    (OUT / 'GALLERIA.html').write_text(page, encoding='utf-8')
    print(json.dumps({key: report[key] for key in ['exportedEntries', 'newDesktopProposalSlots', 'sourceCatalogueRefreshPending']}, ensure_ascii=False))


if __name__ == '__main__':
    main()
