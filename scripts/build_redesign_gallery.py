"""Copy original ImageGen outputs and build a review gallery, never approve art."""
from pathlib import Path
import hashlib
import html
import json
import os
import shutil
from urllib.parse import quote

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/artwork/ridisegni_2026-10-30'


def main():
    groups = []
    files = []
    names = {'firerose': 'FireRose', 'maledizione_chaos': 'Maledizione Chaos',
             'weak_horror_mastino': 'Mastino della Cripta', 'forest_demon': 'Forest Demon',
             'ciclo_forest_demon_blu': 'Forest Demon Blu dalle Corna Rosa',
             'ciclope_del_tempo': 'Il Ciclope del Tempo'}
    approvals = json.loads((ROOT / 'output/artwork/approvazioni_2026-10-30/manifest_approvazioni.json').read_text(encoding='utf-8'))
    approved = {r['id']: r for r in approvals['files'] if r.get('user_approved') is True}
    for batch in sorted((OUT / 'gruppo_root').glob('batch_*.json')):
        rows = json.loads(batch.read_text(encoding='utf-8'))
        rows = [{**r, 'id': r.get('id') or r['artwork_key']} for r in rows]
        proposals = []
        colors = batch.stem.endswith('_colori')
        for row in rows:
            source = Path(row['resultPath'])
            dest = batch.parent / (row['id'] + ('_colori_' if colors else '_redesign_') + row['variant'] + '_v1.png')
            digest = hashlib.sha256(source.read_bytes()).hexdigest()
            if dest.exists() and hashlib.sha256(dest.read_bytes()).hexdigest() != digest:
                raise ValueError('Refusing to overwrite different artwork: ' + str(dest))
            if not dest.exists():
                shutil.copy2(source, dest)
            proposal = {**row, 'output_path': dest.relative_to(ROOT).as_posix(), 'sha256': digest}
            proposals.append(proposal)
            files.append(proposal)
        groups.append({'id': rows[0]['id'], 'name': names.get(rows[0]['id'], rows[0]['id']) + (' — nuove palette' if colors else ''), 'proposals': proposals})
    agent_manifest = OUT / 'gruppo_agente/manifest_redesign_agente.json'
    if agent_manifest.exists():
        for entry in json.loads(agent_manifest.read_text(encoding='utf-8'))['entries']:
            proposals = []
            for proposal in entry['proposals']:
                source = Path(proposal['output_path'])
                source = source if source.is_absolute() else ROOT / source
                normalized = {**proposal, 'output_path': source.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(source.read_bytes()).hexdigest()}
                proposals.append(normalized)
                files.append(normalized)
            groups.append({'id': entry['artwork_key'], 'name': entry['name'], 'proposals': proposals})
    sections = []
    def url(path):
        return quote(Path(os.path.relpath(ROOT / path, OUT)).as_posix(), safe='/')
    def card(path, caption):
        link = html.escape(url(path), quote=True)
        return f'<figure><a href="{link}"><img loading="lazy" src="{link}" alt="{html.escape(caption, quote=True)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
    for group in groups:
        cards = []
        choice = approved.get(group['id'])
        for p in group['proposals']:
            same = choice and p['sha256'] == choice['sha256']
            label = p['variant'] + ' — ' + p.get('title', '') + (' · CANONICO DESKTOP' if same else ' · da valutare')
            cards.append(card(p['output_path'], label))
        sections.append('<section><h2>' + html.escape(group['name']) + '</h2><div class="choices">' + ''.join(cards) + '</div></section>')
    selection_cards = [card(p['output_path'], p['id'].replace('_', ' ').title() + ' · CANONICO DESKTOP') for p in approvals['files']]
    page = '''<!doctype html><html lang="it"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Oculum — nuovi ridisegni</title><style>
body{margin:24px auto;padding:0 20px;max-width:1650px;background:#17151b;color:#e5d7b7;font:17px system-ui}h1,h2{font-family:Georgia,serif}p{line-height:1.65;max-width:85ch}a{color:inherit}.choices{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px}figure{margin:0;border:1px solid #73603d;border-radius:8px;overflow:hidden;background:#26222c}img{width:100%;height:auto;display:block}figcaption{padding:12px}section{margin:40px 0}@media(max-width:800px){.choices{grid-template-columns:1fr}}</style>
<h1>Nuovi ridisegni — 30 ottobre</h1><p>Le approvazioni riguardano solo l'immagine desktop selezionata. Telefono, reliquie e funzionamento nel gioco sono verifiche distinte. Le alternative storiche restano conservate. Per scegliere indica nome, lettera ed eventuali correzioni.</p><p><a href="../proposte_prossima_patch_2026-10-29/GALLERIA.html">Galleria precedente</a></p>'''
    page += '<section><h2>Scelte confermate</h2><div class="choices">' + ''.join(selection_cards) + '</div></section>'
    page += ''.join(sections) + '</html>\n'
    (OUT / 'GALLERIA.html').write_text(page, encoding='utf-8')
    (OUT / 'manifest_galleria.json').write_text(json.dumps({'groups': groups, 'copied_original_files': files, 'automatic_approvals': False}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'groups': len(groups), 'files': len(files), 'explicit_approvals': len(approved)}))


if __name__ == '__main__':
    main()
