"""Preserve the nine exact PNG revisions explicitly approved in chat."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'output/artwork/derivati_scelte_2026-11-01/meccanio_family'
LEDGER = ROOT / 'output/artwork/approvazioni_2026-11-01/manifest.json'
RECEIPT = ROOT / 'design/approved-meccanio-packs-2026-11-01.json'
QUOTE = 'Sì, tutti e sei canonici'


def copy_exact(source, target, expected):
    data = source.read_bytes()
    assert hashlib.sha256(data).hexdigest() == expected, source
    if target.exists():
        assert target.read_bytes() == data, f'Refusing to replace different canon: {target}'
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    assert hashlib.sha256(target.read_bytes()).hexdigest() == expected
    return len(data)


def main():
    manifest = json.loads((BASE / 'manifest.json').read_text(encoding='utf-8'))
    ledger = json.loads(LEDGER.read_text(encoding='utf-8'))
    assert {c['id'] for c in manifest['creatures']} == {
        'meccanio', 'meccanio_ammaccato', 'meccanio_primordiale'}
    files = []
    for creature in manifest['creatures']:
        species = creature['id']
        desktop = next(r for r in ledger['approvals']
                       if r['species'] == species and r['kind'] == 'desktop')
        assert desktop['approved'] is True
        records = [('desktop', ROOT / desktop['canonical_copy'], desktop['sha256'],
                    desktop['version'], desktop['user_quote'])]
        assert {d['kind'] for d in creature['derivatives']} == {'phone', 'relic'}
        for derivative in creature['derivatives']:
            kind = derivative['kind']
            source = BASE / derivative['image']
            digest = derivative['sha256']
            canonical = LEDGER.parent / f'{species}_{kind}_canonico.png'
            copy_exact(source, canonical, digest)
            derivative.update(approved=True, canonical=True, status='user_approved',
                              approvalQuote=QUOTE, approvalDate='2026-11-01')
            record = dict(species=species, kind=kind,
                          source=source.relative_to(ROOT).as_posix(),
                          canonical_copy=canonical.relative_to(ROOT).as_posix(),
                          sha256=digest, version=derivative['version'],
                          user_quote=QUOTE, approved=True, runtime_integrated=True)
            ledger['approvals'] = [r for r in ledger['approvals']
                                  if (r['species'], r['kind']) != (species, kind)] + [record]
            records.append((kind, canonical, digest, derivative['version'], QUOTE))
        for kind, source, digest, revision, quote in records:
            prefix = 'relic' if kind == 'relic' else 'theme'
            suffix = '_mobile' if kind == 'phone' else ''
            asset = f'assets/oculum/home_art/{prefix}_{species}{suffix}_canon_20261101.png'
            size = copy_exact(source, ROOT / asset, digest)
            files.append(dict(species=species, kind=kind, asset=asset, sha256=digest,
                              bytes=size, source=source.relative_to(ROOT).as_posix(),
                              revision=revision, user_approved=True,
                              approval_quote=quote, decorative_only=True))
        desktop['runtime_integrated'] = True
        desktop['phone_relic_approval'] = QUOTE
    manifest.update(approved=True, status='user_approved_runtime_integrated',
                    runtimeIntegrated=True, approvalQuote=QUOTE)
    receipt = dict(date='2026-11-01', provider='builtin image_gen.imagegen',
                   scope='Three approved Meccanio packs; cosmetic only.', files=files)
    for path, value in [(BASE / 'manifest.json', manifest), (LEDGER, ledger), (RECEIPT, receipt)]:
        path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print('Nine approved PNGs copied and SHA-verified; previous assets preserved.')


if __name__ == '__main__':
    main()
