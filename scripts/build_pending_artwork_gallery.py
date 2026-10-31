"""Read-only artwork review: show generated pending files, never grant approval."""
from collections import Counter
from pathlib import Path
import hashlib,html,importlib.util,json,os,re

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'output/artwork'
DEST=ART/'da_approvare'
spec=importlib.util.spec_from_file_location('artwork_queue',ROOT/'scripts/build_artwork_review_queue.py')
queue=importlib.util.module_from_spec(spec);spec.loader.exec_module(queue)

def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def walk(value):
    if isinstance(value,dict):
        yield value
        for child in value.values(): yield from walk(child)
    elif isinstance(value,list):
        for child in value: yield from walk(child)
def resolve(value,manifest=None):
    path=queue.artwork_path(value,manifest)
    return path if path and path.is_file() and path.suffix.lower()=='.png' and path.resolve().is_relative_to(ROOT.resolve()) else None
def evidence(path,expected=None):
    data=queue.png_evidence(path)
    if not data.get('pngVerified') or (expected and data['sha256'].lower()!=expected.lower()):
        raise ValueError('Invalid image or SHA: '+str(path))
    return data

def main():
    DEST.mkdir(exist_ok=True)
    approved=set()
    for manifest in ART.rglob('*manifest*.json'):
        for node in walk(read(manifest)):
            if node.get('user_approved') is not True: continue
            path=resolve(node.get('output_path') or node.get('file') or node.get('path'),manifest)
            if path: approved.add(evidence(path)['sha256'])
    selections=ART/'proposte_prossima_patch_2026-10-29/selezione_canonica_cinque_2026-10-29.json'
    for item in read(selections)['files']:
        path=resolve(item['output_path'],selections)
        if path: approved.add(evidence(path,item.get('sha256'))['sha256'])
    for filename,_ in queue.APPROVED_DRAFTS.values():
        path=resolve('output/artwork/drafts_2026-10-29/'+filename)
        if path: approved.add(evidence(path)['sha256'])
    rows=[]; history=[]; seen={}; excluded=[]
    def add(name,letter,path,kind,source,expected=None,notes=None,historical=False):
        if path is None: raise ValueError('Missing selected PNG: '+source)
        proof=evidence(path,expected)
        if proof['sha256'] in approved:
            excluded.append({'file':queue.public_path(path),'reason':'exact image already explicitly approved'}); return
        key=(proof['sha256'],historical)
        if key in seen:
            seen[key]['aliases'].append(queue.public_path(path)); return
        item={'name':name,'variant':letter,'file':queue.public_path(path),'kind':kind,'source':source,
              'sha256':proof['sha256'],'width':proof['width'],'height':proof['height'],
              'userApproved':False,'aliases':[],'notes':notes or []}
        seen[key]=item
        (history if historical else rows).append(item)
    old=read(ART/'proposte_prossima_patch_2026-10-29/coda_artwork.json')
    for creature in old['entries']:
        for letter,item in creature['proposals'].items():
            if not item.get('file'): continue
            state=item.get('status')
            if state not in ('generated_pending_human_review','historical_alternative_not_selected'): continue
            add(creature['name'],letter,resolve(item['file']),'desktop',item['file'],
                (item.get('evidence') or {}).get('sha256'),historical=state=='historical_alternative_not_selected')
    five=read(ART/'proposte_cinque_2026-10-30/manifest_galleria.json')
    for group in five['groups']:
        selected=any(p.get('userApproved') for p in group['proposals'])
        for item in group['proposals']:
            if item.get('userApproved') or item.get('status')!='generated_pending_human_review': continue
            add(group['name'],item['variant'],resolve(item['file']),'desktop',group['manifest'],
                item.get('evidence',{}).get('sha256'),item.get('qaWarnings'),historical=selected)
    curated=[
      ART/'proposte_cinque_2026-10-30/derivati_custode_mammuth_armadillo/manifest_derivati.json',
      ART/'drafts_2026-10-29/manifest_sharp_topino_mosca_derivatives.json',
      ART/'derivati_desktop_canonici_2026-10-30/manifest.json',
    ]
    names={'sharp':'Sharp','topino_avventuroso':'Topino Avventuroso','mosca_campana':'Mosca Campana'}
    for manifest in curated:
        payload=read(manifest)
        def derivative(item,name):
            if item.get('selected') is False or item.get('selected_for_review') is False or item.get('user_approved') is True: return
            path=resolve(item.get('output_path'),manifest)
            if not path: return
            kind=item.get('kind') or ('relic' if 'relic' in item.get('role','') else 'phone')
            expected=item.get('sha256') or item.get('metadata',{}).get('sha256')
            add(name,'Telefono' if kind=='phone' else 'Reliquia',path,kind,queue.public_path(manifest),expected)
        for item in payload.get('files',[]): derivative(item,item.get('name') or item.get('species','Mostro'))
        for entry in payload.get('entries',[]):
            if 'derivatives' in entry:
                for item in entry['derivatives']: derivative(item,entry['name'])
            else:
                key=re.sub(r'_(phone|relic)$','',entry.get('key',''))
                derivative(entry,names.get(key,key.replace('_',' ').title()))
    rows.sort(key=lambda item:(0 if item['kind']!='desktop' else 1,item['name'].casefold(),item['variant']))
    counts=Counter(row['kind'] for row in rows)
    assert not any(row['sha256'] in approved for row in rows)
    def render(items):
        sections=[]
        grouped={}
        for row in items: grouped.setdefault((row['name'],row['kind']),[]).append(row)
        for (name,kind),items in grouped.items():
            cards=[]
            for item in items:
                path=ROOT/item['file']; href=Path(os.path.relpath(path,DEST)).as_posix()
                notes=' '.join(str(x) for x in item['notes'])
                cards.append('<figure><a href="'+html.escape(href,quote=True)+'" target="_blank"><img loading="lazy" src="'+html.escape(href,quote=True)+'" alt="'+html.escape(name+' '+item['variant'],quote=True)+'"></a><figcaption><b>'+html.escape(item['variant'])+'</b>'+(('<p>'+html.escape(notes)+'</p>') if notes else '')+'</figcaption></figure>')
            label={'desktop':'Sfondo desktop','phone':'Sfondo telefono','relic':'Reliquia decorativa'}.get(kind,kind)
            sections.append('<section data-name="'+html.escape(name.casefold(),quote=True)+'" data-kind="'+kind+'"><h2>'+html.escape(name)+' <small>· '+label+'</small></h2><div class="grid">'+''.join(cards)+'</div></section>')
        return ''.join(sections)
    page='''<!doctype html><html lang="it"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Oculum — immagini ancora da approvare</title><style>body{background:#15151b;color:#e7dbbf;font:17px system-ui;margin:24px auto;max-width:1700px;padding:0 18px}h1,h2{font-family:Georgia,serif}p{line-height:1.6;max-width:95ch}small{font:15px system-ui;color:#bcae98}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px}figure{margin:0;border:1px solid #625436;border-radius:8px;overflow:hidden;background:#25232b}img{display:block;width:100%;height:300px;object-fit:contain;background:repeating-conic-gradient(#25232b 0% 25%,#302c34 0% 50%) 50%/24px 24px}figcaption{padding:13px}section{margin:32px 0}a{color:#e0c58d}nav{position:sticky;top:0;background:#18171fee;z-index:2;padding:12px;display:flex;gap:12px;flex-wrap:wrap}input,select{font:inherit;padding:9px;color:inherit;background:#242129;border:1px solid #86704d;border-radius:5px}input{flex:1;min-width:200px}details{margin:40px 0;padding:16px;border:1px solid #625436}summary{cursor:pointer}section[hidden]{display:none}@media(max-width:1100px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:650px){.grid{grid-template-columns:1fr}img{height:auto;max-height:480px}}</style><h1>Immagini ancora da approvare</h1>'''
    page+=f'<p><b>{len(rows)} immagini uniche da valutare</b>: {counts["desktop"]} sfondi desktop, {counts["phone"]} sfondi telefono, {counts["relic"]} reliquie. Sono soltanto file già prodotti e verificati, non slot da generare. Cerca un mostro e rispondi con nome, lettera e tipo; premi l’immagine per vederla intera.</p>'
    page+='<p>Le immagini già approvate sono escluse per file e SHA. Le alternative delle specie per cui hai già scelto un disegno sono raccolte nello storico in fondo: non chiedono una nuova approvazione del canone esistente. Le tue scelte saranno registrate solo dopo una risposta esplicita.</p><nav><input id="search" type="search" placeholder="Cerca mostro…" aria-label="Cerca mostro"><select id="kind" aria-label="Tipo"><option value="all">Tutti i tipi</option><option value="desktop">Desktop</option><option value="phone">Telefono</option><option value="relic">Reliquie</option></select><a href="../proposte_cinque_2026-10-30/GALLERIA.html">Lotti A–E</a></nav><main>'+render(rows)+'</main>'
    page+=f'<details><summary>Storico: {len(history)} alternative non selezionate di specie già scelte</summary><p>Conservate per confronto, separate dalle nuove conferme richieste.</p>'+render(history)+'</details>'
    page+='''<script>const search=document.querySelector('#search'),kind=document.querySelector('#kind');function filter(){const q=search.value.toLocaleLowerCase('it');document.querySelectorAll('section[data-name]').forEach(s=>{s.hidden=!(s.dataset.name.includes(q)&&(kind.value==='all'||kind.value===s.dataset.kind));});}search.addEventListener('input',filter);kind.addEventListener('change',filter);</script></html>'''
    (DEST/'GALLERIA_DA_APPROVARE.html').write_text(page,encoding='utf-8')
    report={'schemaVersion':1,'counts':dict(counts),'pendingUniqueImages':len(rows),'historicalAlternatives':len(history),
      'approvedHashesExcluded':len(approved),'rows':rows,'history':history,'excludedApproved':excluded,
      'approvalPolicy':'Explicit human reply only; never inferred from opening the gallery.'}
    (DEST/'manifest_da_approvare.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({key:report[key] for key in ('counts','pendingUniqueImages','historicalAlternatives','approvedHashesExcluded')},ensure_ascii=False))

if __name__=='__main__': main()
