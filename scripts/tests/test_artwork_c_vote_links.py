"""A canonical C links to the verified review folder, without widening A/B."""
import ast
from collections import defaultdict
from hashlib import sha256
from html import escape
import json
from os.path import relpath
from pathlib import Path
import tempfile
import unittest

from scripts.oculum_artwork_paths import artwork_paths
from scripts.artwork_catalogue_visibility import is_retired


REPOSITORY = Path(__file__).resolve().parents[2]
HELPER = REPOSITORY / 'output/artwork/alternative_mostri_2026-11-05/aggiorna_alternative.py'


@unittest.skipUnless(HELPER.is_file(), 'Local artwork review helper is not present in this checkout')
class ArtworkCVoteLinksTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='artwork-c-vote-', dir=REPOSITORY / 'build')
        self.root = Path(self.temp.name)
        assert self.root.resolve().is_relative_to((REPOSITORY / 'build').resolve())
        for name in ('lib', 'docs', 'scripts'):
            (self.root / name).mkdir()
        self.folder = self.root / 'output/artwork/alternative_mostri_2026-11-05'
        self.folder.mkdir(parents=True)
        self.baseline = self.root / 'output/artwork/baseline.png'
        self.baseline.write_bytes(b'baseline image checksum fixture')
        self.a = self.folder / 'a.png'
        self.a.write_bytes(b'previous A checksum fixture')
        self.c = self.root / 'output/artwork/terze_C_2026-11-06/c.png'
        self.c.parent.mkdir()
        self.c.write_bytes(b'third C checksum fixture')
        node = next(n for n in ast.parse(HELPER.read_text(encoding='utf-8')).body
                    if isinstance(n, ast.FunctionDef) and n.name == 'choice_banner')
        self.env = dict(ROOT=self.root, FOLDER=self.folder, CHOICES={},
                        LABELS={'A': 'Maestosa', 'B': 'Compatta'}, Path=Path,
                        sha256=sha256, escape=escape, relpath=relpath,
                        _PATHS=artwork_paths(self.folder / 'helper.py', repo_root=self.root))
        exec(compile(ast.Module(body=[node], type_ignores=[]), str(HELPER), 'exec'), self.env)
        self.banner = self.env['choice_banner']

    def tearDown(self):
        self.temp.cleanup()

    def choose(self, letter='C', selected=None):
        selected = selected or self.c
        value = {'decision': 'choose_alternative', 'letter': letter,
                 'baseline': {'file': str(self.baseline.relative_to(self.root)),
                              'sha256': sha256(self.baseline.read_bytes()).hexdigest()},
                 'artwork': {'file': str(selected.relative_to(self.root)),
                             'sha256': sha256(selected.read_bytes()).hexdigest()},
                 'integration': {'frozenBuild': '641ec7ed'}}
        self.env['CHOICES']['example'] = value
        return value

    def test_valid_c_uses_local_relative_link(self):
        self.choose()
        result = self.banner('example', self.baseline)
        self.assertIn('../terze_C_2026-11-06/c.png', result)
        self.assertIn('C — scelta artistica canonica', result)
        self.assertNotIn('file://', result)

    def test_valid_a_remains_in_original_folder(self):
        self.choose('A', self.a)
        self.assertIn('href="a.png"', self.banner('example', self.baseline))

    def test_c_cannot_point_at_an_unverified_folder(self):
        self.choose('C', self.a)
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_a_cannot_point_at_the_c_folder(self):
        self.choose('A', self.c)
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_unknown_letter_is_rejected(self):
        self.choose('D')
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_changed_c_payload_is_rejected(self):
        self.choose()
        self.c.write_bytes(b'changed after selection')
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_no_choice_does_not_invent_a_canon(self):
        self.assertEqual('', self.banner('example', self.baseline))


@unittest.skipUnless(HELPER.is_file(), 'Local artwork review helper is not present in this checkout')
class CachedArtworkRetirementsTest(unittest.TestCase):
    """A later retirement must apply even when historic image hashes are cached."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='artwork-cache-', dir=REPOSITORY / 'build')
        self.root = Path(self.temp.name)
        self.folder = self.root / 'output/artwork/alternative_mostri_2026-11-05'
        self.folder.mkdir(parents=True)
        (self.root / 'build').mkdir()
        self.assets = []
        for identifier in ('retired_base', 'retired_base_variante_errante', 'still_active'):
            for letter in ('A', 'B'):
                version = 1 if letter == 'A' else 2
                image = self.folder / f'{identifier}_desktop_v{version}.jpg'
                image.write_bytes(b'cached checksum test fixture')
                source = self.folder / f'{identifier}_desktop_v{version}.png'
                source.write_bytes(b'native checksum test fixture')
                asset = {'id': identifier, 'letter': letter,
                         'file': image.relative_to(self.root).as_posix(),
                         'source': str(source), 'retired': False, 'selectedForReview': True}
                self.assets.append(asset)
                image.with_suffix('.json').write_text(json.dumps(asset), encoding='utf-8')
        self.manifest = self.folder / 'manifest.json'
        self.manifest.write_text(json.dumps({'assets': self.assets}), encoding='utf-8')
        self.manifest_before = self.manifest.read_bytes()
        self.proof = self.root / 'build/AUDIT_MANIFEST_ARTWORK_FINALE_20261105.json'
        self.proof.write_text(json.dumps({'passed': True,
            'manifestSha256After': sha256(self.manifest_before).hexdigest()}), encoding='utf-8')
        node = next(n for n in ast.parse(HELPER.read_text(encoding='utf-8')).body
                    if isinstance(n, ast.FunctionDef) and n.name == 'read_verified_manifest')
        self.env = dict(ROOT=self.root, FOLDER=self.folder, Path=Path, json=json,
                        sha256=sha256, defaultdict=defaultdict,
                        VISIBILITY={'is_retired': is_retired}, RETIRED={'retired_base'})
        exec(compile(ast.Module(body=[node], type_ignores=[]), str(HELPER), 'exec'), self.env)
        self.load = self.env['read_verified_manifest']

    def tearDown(self):
        self.temp.cleanup()

    def test_later_retirement_removes_base_and_variant_from_cached_gallery(self):
        groups, assets = self.load()
        self.assertEqual({'still_active'}, set(groups))
        self.assertEqual({'A', 'B'}, set(groups['still_active']))
        self.assertEqual(4, sum(a['retired'] for a in assets))
        self.assertEqual(2, sum(a['selectedForReview'] for a in assets))
        self.assertEqual(self.manifest_before, self.manifest.read_bytes())

    def test_active_images_and_historical_receipts_are_unchanged(self):
        groups, _ = self.load()
        self.assertEqual(self.assets[-2:], list(groups['still_active'].values()))
        for asset in self.assets:
            self.assertEqual(asset, json.loads((self.root / asset['file']).with_suffix('.json').read_text(encoding='utf-8')))

    def test_changed_manifest_still_requires_full_audit(self):
        self.manifest.write_bytes(self.manifest_before + b' ')
        with self.assertRaises(AssertionError):
            self.load()

    def test_changed_receipt_is_rejected_before_gallery_refresh(self):
        image = self.root / self.assets[0]['file']
        receipt = dict(self.assets[0], source='unexpected different source')
        image.with_suffix('.json').write_text(json.dumps(receipt), encoding='utf-8')
        with self.assertRaises(AssertionError):
            self.load()


if __name__ == '__main__':
    unittest.main()
