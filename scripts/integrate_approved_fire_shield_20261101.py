"""Copy the approved C2 FireShield and its head-only relic unchanged."""
import json
from integrate_approved_meccanio_packs_20261101 import ROOT, copy_exact

base = ROOT / 'output/artwork/derivati_scelte_2026-11-01/fire_shield'
ledger_path = ROOT / 'output/artwork/approvazioni_2026-11-01/manifest.json'
ledger = json.loads(ledger_path.read_text(encoding='utf-8'))
manifest_path = base / 'manifest_derivati.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
desktop = next(r for r in ledger['approvals'] if r['species'] == 'fire_shield' and r['kind'] == 'desktop')
assert desktop['approved'] is True and desktop['letter'] == 'C' and desktop['version'] == 2
records = [('desktop', ROOT / desktop['canonical_copy'], desktop['sha256'], 2, desktop['user_quote'])]
selected = [r for r in manifest['files'] if r.get('selected') is True]
assert {(r['kind'], r['version']) for r in selected} == {('phone', 1), ('relic', 2)}
for r in selected:
    source = base / r['image']
    target = ledger_path.parent / f'fire_shield_{r["kind"]}_canonico.png'
    copy_exact(source, target, r['sha256'])
    quote = 'Sì, entrambi canonici'
    r.update(user_approved=True, approval_quote=quote, runtime_integrated=True)
    record = dict(species='fire_shield', kind=r['kind'], approved=True,
                  version=r['version'], sha256=r['sha256'], user_quote=quote,
                  source=source.relative_to(ROOT).as_posix(),
                  canonical_copy=target.relative_to(ROOT).as_posix(), runtime_integrated=True)
    ledger['approvals'] = [a for a in ledger['approvals']
                          if (a['species'], a['kind']) != ('fire_shield', r['kind'])] + [record]
    records.append((r['kind'], target, r['sha256'], r['version'], quote))
files = []
for kind, source, digest, revision, quote in records:
    prefix = 'relic' if kind == 'relic' else 'theme'
    suffix = '_mobile' if kind == 'phone' else ''
    asset = f'assets/oculum/home_art/{prefix}_fire_shield{suffix}_canon_20261101.png'
    size = copy_exact(source, ROOT / asset, digest)
    files.append(dict(species='fire_shield', kind=kind, asset=asset, sha256=digest,
                      bytes=size, source=source.relative_to(ROOT).as_posix(), revision=revision,
                      user_approved=True, approval_quote=quote, decorative_only=True))
desktop['runtime_integrated'] = True
desktop['phone_relic_approval'] = 'Sì, entrambi canonici'
manifest['status'] = 'USER_APPROVED_RUNTIME_INTEGRATED_WITH_ALPHA_DIAGNOSTIC_PRESERVED'
manifest['counts'].update(approved_derivatives=2, runtime_integrated=2)
receipt = dict(date='2026-11-01', provider='builtin image_gen.imagegen', files=files,
               scope='FireShield C2 desktop, phone v1, head-only relic v2.',
               relicAlphaNote='Visible subject margin at least16.9%; alpha1 residuals retained unchanged. Raw13%margin not claimed.')
for path, value in [(ledger_path, ledger), (manifest_path, manifest),
                    (ROOT / 'design/approved-fire-shield-pack-2026-11-01.json', receipt)]:
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
print('Three exact approved FireShield PNGs copied and SHA-verified; no pixel edits.')
