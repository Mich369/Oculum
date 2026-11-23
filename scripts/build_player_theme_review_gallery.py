"""Validate player-theme comparisons and retain explicitly confirmed choices."""

import hashlib
import html
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'output/artwork/expressive_ink_player_20261117'
SHOWN = set(sys.argv[1:])


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def resolve_file(folder, value):
    path = ROOT / value if value.startswith('assets/') else folder / value
    resolved = path.resolve(strict=True)
    assert resolved.is_relative_to(BASE) or resolved.is_relative_to(ROOT / 'assets')
    return resolved


def href(path):
    return html.escape(os.path.relpath(path, BASE).replace('\\', '/'), quote=True)


def atomic_json(path, value):
    pending = path.with_suffix(path.suffix + '.new')
    pending.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    os.replace(pending, path)


stamp = datetime.now(timezone.utc).isoformat()
cards, delivered = [], []
for folder in sorted(BASE.iterdir()):
    if not folder.is_dir() or not (folder / 'MANIFEST.json').exists():
        continue
    manifest_path = folder / 'MANIFEST.json'
    manifest = read(manifest_path)
    ident = manifest['id']
    assert ident == folder.name
    rows = {v['slot']: v for v in manifest['variants']}
    assert set(rows) >= set('ABCDEF')
    chosen = [rows[slot] for slot in 'ABCDEF']
    assert len({v['sha256'] for v in chosen}) == 6
    original = manifest.get('original', rows.get('O'))
    assert original
    original_path = resolve_file(folder, original['file'])
    assert digest(original_path) == original['sha256']
    confirmation = manifest.get('selectedArtwork')
    confirmed = manifest.get('choiceStatus') == 'confermato' and bool(confirmation)
    if confirmed:
        selected = rows[confirmation['slot']]
        assert selected['sha256'] == confirmation['sha256']
    retired = manifest.get('choiceStatus') == 'ritirato'
    original_label = 'Originale precedente' if confirmed or retired else 'Originale in uso'
    image_cards = [f'<a href="{href(original_path)}"><img loading="lazy" src="{href(original_path)}"><span>{original_label}</span></a>']
    for variant in chosen:
        path = resolve_file(folder, variant['file'])
        assert digest(path) == variant['sha256']
        with Image.open(path) as image:
            image.load()
            assert image.format == 'WEBP'
            assert image.width >= 1500 and image.height >= 900
        label = html.escape(variant.get('label', variant['slot']))
        slot = variant['slot']
        selected_attribute = ' checked' if confirmed and confirmation['slot'] == slot else ''
        image_cards.append(f'<label><input type="radio" name="{ident}" value="{slot}" data-sha="{variant["sha256"]}"{selected_attribute}><a href="{href(path)}" target="_blank"><img loading="lazy" src="{href(path)}"></a><span>{slot} · {label}</span></label>')
    panorama = folder / 'PANORAMICA.webp'
    with Image.open(panorama) as image:
        image.load()
        assert image.format == 'WEBP'
    if ident in SHOWN:
        manifest.setdefault('presentedAtUtc', stamp)
        if not confirmed and not retired:
            manifest['choiceStatus'] = 'in_attesa'
        atomic_json(manifest_path, manifest)
    title = html.escape(manifest['name'])
    status_note = ''
    if confirmed:
        status_note = f'<p class="confirmed">Scelta confermata: {html.escape(confirmation["slot"])}. Integrata nei sorgenti; verifica della nuova build in attesa.</p>'
    elif retired:
        status_note = '<p class="confirmed">Tema ritirato dal catalogo su richiesta. Il confronto resta nello storico.</p>'
    elif manifest.get('choiceStatus') == 'revisione_richiesta':
        status_note = '<p class="confirmed">Revisione richiesta: nuovo confronto ancora da preparare.</p>'
    cards.append(f'<section data-id="{ident}"><h2>{title}</h2>{status_note}<a href="{href(panorama)}">Apri la panoramica completa</a><div class="grid">{"".join(image_cards)}</div><label class="notes">Indicazioni per questa tavola<textarea data-note="{ident}" rows="2"></textarea></label></section>')
    delivered.append({'id': ident, 'name': manifest['name'], 'manifest': manifest_path.relative_to(ROOT).as_posix(),
                      'panorama': panorama.relative_to(ROOT).as_posix(), 'panoramaSha256': digest(panorama),
                      'shownAtUtc': manifest.get('presentedAtUtc'), 'choiceStatus': manifest.get('choiceStatus', 'da_mostrare'),
                      'confirmation': confirmation,
                      'variants': [{'slot': v['slot'], 'sha256': v['sha256']} for v in chosen]})

javascript = r"""
const key='oculum-temi-player-20261117';
const sections=[...document.querySelectorAll('section[data-id]')];
function values(){return sections.flatMap(s=>{const r=s.querySelector('input:checked');const note=s.querySelector('textarea').value;if(!r&&!note.trim())return [];const row={id:s.dataset.id,note};if(r)row.artwork=[{surface:'desktop',slot:r.value,sha256:r.dataset.sha}];return [row];});}
function save(){try{localStorage.setItem(key,JSON.stringify(values()));}catch{}document.querySelector('#count').textContent=values().filter(v=>v.artwork?.length).length+' scelte su '+sections.length;}
try{for(const v of JSON.parse(localStorage.getItem(key)||'[]')){const s=sections.find(s=>s.dataset.id===v.id);if(!s)continue;const a=v.artwork?.[0];const r=[...s.querySelectorAll('input')].find(r=>r.value===a?.slot&&r.dataset.sha===a?.sha256);if(r)r.checked=true;s.querySelector('textarea').value=v.note||'';}}catch{}
document.addEventListener('change',save);document.addEventListener('input',save);
document.querySelector('#export').onclick=()=>{const data={schemaVersion:1,source:'galleria-temi-player-20261117',votes:values()};const blob=new Blob([JSON.stringify(data,null,2)],{type:'application/json'});const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download='scelte-temi-player-20261117.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};save();
"""
page = '<!doctype html><html lang="it"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Oculum · Temi dei giocatori</title><style>body{margin:0;background:#19161c;color:#eee5d9;font:16px system-ui;padding:22px}header{position:sticky;top:0;background:#19161cf5;z-index:2;padding:12px;border-bottom:1px solid #69523e}h1{font-size:25px;margin:0 0 8px}h2{font-size:22px}section{padding:22px 0;border-bottom:1px solid #69523e}a{color:#d8b887}button,textarea{background:#302731;color:#eee5d9;border:1px solid #8b7059;border-radius:5px;padding:9px}button{cursor:pointer}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:12px;margin:16px 0}.grid>a,.grid>label{display:block;background:#251f29;border:1px solid #5d4c55;border-radius:6px;padding:8px}.grid label:has(input:checked){outline:3px solid #c6a366}.grid img{width:100%;aspect-ratio:16/9;object-fit:contain;background:#100f12}.grid span{display:block;margin-top:6px}.notes{display:block}textarea{display:block;box-sizing:border-box;width:100%;margin-top:8px}small{color:#c4b4a7}</style><header><h1>Oculum · Temi dei giocatori</h1><p>Confronta l’originale con le sei proposte. Puoi scegliere una tavola e aggiungere indicazioni.</p><button id="export">Esporta le scelte</button> <span id="count"></span><p><small>Le scelte esportate vanno inviate in chat per applicarle.</small></p></header>' + ''.join(cards) + '<script>' + javascript + '</script></html>'
(BASE / 'GALLERIA.html').write_text(page, encoding='utf-8')
atomic_json(BASE / 'CONSEGNA.json', {'schemaVersion': 1, 'id': 'galleria-temi-player-20261117',
                                   'updatedAtUtc': stamp,
                                   'appModified': any(v['choiceStatus'] == 'confermato' for v in delivered),
                                   'runtimeBuildVerified': False, 'lots': delivered})
print(json.dumps({'themes': len(delivered), 'proposals': len(delivered) * 6,
                  'shown': sum(bool(v['shownAtUtc']) for v in delivered)}, ensure_ascii=False))
