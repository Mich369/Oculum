"""A canonical C links to the verified review folder, without widening A/B."""
import ast
from collections import defaultdict
from hashlib import sha256
from html import escape
import json
import re
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
        self.edited = self.root / 'output/artwork/correzioni_canoniche_2026-11-06/approved_edit.png'
        self.edited.parent.mkdir()
        self.edited.write_bytes(b'accepted native revision checksum fixture')
        node = next(n for n in ast.parse(HELPER.read_text(encoding='utf-8')).body
                    if isinstance(n, ast.FunctionDef) and n.name == 'choice_banner')
        self.env = dict(ROOT=self.root, FOLDER=self.folder, CHOICES={},
                        LABELS={'A': 'Maestosa', 'B': 'Compatta'}, Path=Path,
                        sha256=sha256, escape=escape, relpath=relpath,
                        json=json,
                        _PATHS=artwork_paths(self.folder / 'helper.py', repo_root=self.root))
        exec(compile(ast.Module(body=[node], type_ignores=[]), str(HELPER), 'exec'), self.env)
        self.banner = self.env['choice_banner']

    def tearDown(self):
        self.temp.cleanup()

    def choose(self, letter='C', selected=None):
        selected = selected or self.c
        value = {'decision': 'choose_alternative', 'letter': letter,
                 'artisticStatus': 'canonical_user_vote',
                 'baseline': {'file': str(self.baseline.relative_to(self.root)),
                              'sha256': sha256(self.baseline.read_bytes()).hexdigest()},
                 'artwork': {'file': str(selected.relative_to(self.root)),
                             'sha256': sha256(selected.read_bytes()).hexdigest()},
                 'integration': {'frozenBuild': '641ec7ed'}}
        self.env['CHOICES']['example'] = value
        return value

    def choose_approved_edit(self, selected=None):
        value = self.choose('A', selected or self.edited)
        value.update(revision='user_requested_light_leather_armor_v1', userChoice='accetto',
                     userEvidence={'kind': 'explicit_acceptance_of_shown_revision',
                                   'userAnswer': 'accetto',
                                   'receipt': 'docs/CONFERME_UTENTE_ARTWORK_2026-11-06_03.json'})
        value['artwork']['sourceKind'] = 'native_imagegen_edit_verified'
        value['artwork']['nativeSha256'] = value['artwork']['sha256']
        value['integration'] = {'status': 'pending_next_revision', 'frozenBuild': '5f89ea2b',
                                'newAlternativesIntegrated': False}
        return value

    def choose_guardian_revision(self, selected=None):
        value = self.choose('A', self.a)
        selected = selected or self.edited
        value['integration'] = {'status': 'held_for_user_rule_clarification',
                                'compiledCommitContainingUnusedAsset': '5f89ea2b',
                                'newAlternativesIntegrated': False}
        value['approvedRevision'] = {
            'status': 'pending_next_revision',
            'approvalStatus': 'canonical_user_approved_revision',
            'userAnswer': 'accetto', 'originalAlternative': 'A', 'version': 3,
            'artwork': {'file': selected.relative_to(self.root).as_posix(),
                        'sha256': sha256(selected.read_bytes()).hexdigest(),
                        'nativeSha256': sha256(selected.read_bytes()).hexdigest(),
                        'sourceKind': 'native_imagegen_edit_verified'},
            'userEvidence': {'kind': 'explicit_acceptance_of_shown_revision',
                             'userAnswer': 'accetto',
                             'receipt': 'docs/CONFERME_UTENTE_ARTWORK_2026-11-06_03.json'},
            'newAlternativesIntegrated': False,
        }
        return value

    def approve_reference_redesign(self):
        selected = self.root / 'output/artwork/revisioni_voti_2026-11-06/reference_v4.png'
        selected.parent.mkdir(exist_ok=True)
        selected.write_bytes(b'explicitly approved reference redesign version4')
        value = self.choose_guardian_revision(selected)
        value.update(decision='approve_reference_redesign',
                     userChoice='Sì, canonico',
                     userEvidence={'kind': 'explicit_acceptance_of_shown_revision',
                                   'receipt': 'docs/approval_v4.json'})
        value.pop('letter')
        artwork = value['approvedRevision']['artwork']
        provenance = selected.with_suffix('.provenance.json')
        provenance.write_text(json.dumps({'id': 'example', 'tool': 'image_gen.imagegen',
                                          'sha256': artwork['sha256']}), encoding='utf-8')
        artwork.update(source=str(selected), provenanceFile=str(provenance),
                       provenanceSha256=sha256(provenance.read_bytes()).hexdigest())
        value['artwork'] = dict(artwork)
        return value

    def test_reference_redesign_approval_links_exact_revision_without_a_letter(self):
        value = self.approve_reference_redesign()
        before = json.loads(json.dumps(value))
        result = self.banner('example', self.baseline)
        self.assertIn('../revisioni_voti_2026-11-06/reference_v4.png', result)
        self.assertIn('Redesign da riferimento — scelta artistica canonica', result)
        self.assertIn('Nessuna lettera A/B/C assegnata', result)
        self.assertNotIn('A — scelta', result)
        self.assertNotIn('B — scelta', result)
        self.assertNotIn('C — scelta', result)
        self.assertEqual(before, value)

    def test_reference_redesign_cannot_invent_an_alternative_vote(self):
        value = self.approve_reference_redesign()
        value['letter'] = 'A'
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_reference_redesign_requires_an_explicit_approved_revision(self):
        value = self.approve_reference_redesign()
        value.pop('approvedRevision')
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_reference_redesign_checks_provenance_even_with_native_marker(self):
        value = self.approve_reference_redesign()
        provenance = Path(value['approvedRevision']['artwork']['provenanceFile'])
        provenance.write_bytes(b'changed immutable provenance')
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_reference_redesign_checks_the_native_original(self):
        value = self.approve_reference_redesign()
        native = self.root / 'raw_reference.png'
        native.write_bytes(b'different native original')
        value['approvedRevision']['artwork']['source'] = str(native)
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

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

    def test_pending_c_without_frozen_build_does_not_invent_a_compiled_version(self):
        value = self.choose()
        value['integration'] = {'status': 'pending_next_revision',
                                'newAlternativesIntegrated': False}
        result = self.banner('example', self.baseline)
        self.assertIn('../terze_C_2026-11-06/c.png', result)
        self.assertIn('prossima revisione', result)
        self.assertNotIn('641ec7ed', result)
        self.assertNotIn('None', result)
        self.assertNotIn('la build  mantiene', result)

    def test_distributed_a_without_frozen_build_does_not_claim_pending_integration(self):
        value = self.choose('A', self.a)
        value['integration'] = {'status': 'distributed_verified_5f89ea2b',
                                'compiledCommit': '5f89ea2b6f48cd4d17eb5da3d87fc62db87747d0',
                                'newAlternativesIntegrated': True}
        before = json.loads(json.dumps(value))
        result = self.banner('example', self.baseline)
        self.assertIn('href="a.png"', result)
        self.assertIn('distribuzione', result.lower())
        self.assertIn('separatamente', result)
        self.assertNotIn('prossima revisione', result)
        self.assertNotIn('641ec7ed', result)
        self.assertNotIn('None', result)
        self.assertEqual(before, value)

    def test_explicitly_accepted_a_edit_links_to_the_verified_corrections_folder(self):
        self.choose_approved_edit()
        result = self.banner('example', self.baseline)
        self.assertIn('../correzioni_canoniche_2026-11-06/approved_edit.png', result)
        self.assertIn('A — scelta artistica canonica', result)
        self.assertIn('prossima revisione', result)
        self.assertNotIn('file://', result)

    def test_corrections_folder_requires_an_attested_edit(self):
        self.choose('A', self.edited)
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_accepted_edit_cannot_widen_the_allowed_folder(self):
        unexpected = self.edited.parent.with_name('correzioni_canoniche_2026-11-06_extra')
        unexpected.mkdir()
        selected = unexpected / self.edited.name
        selected.write_bytes(self.edited.read_bytes())
        self.choose_approved_edit(selected)
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_changed_accepted_edit_payload_is_rejected(self):
        self.choose_approved_edit()
        self.edited.write_bytes(b'changed after explicit acceptance')
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_guardian_approved_revision_takes_precedence_and_preserves_history(self):
        value = self.choose_guardian_revision()
        before = json.loads(json.dumps(value))
        result = self.banner('example', self.baseline)
        self.assertIn('../correzioni_canoniche_2026-11-06/approved_edit.png', result)
        self.assertNotIn('href="a.png"', result)
        self.assertIn('prossima revisione', result)
        self.assertEqual(before, value)

    def test_corrupt_guardian_revision_does_not_fall_back_to_old_a(self):
        self.choose_guardian_revision()
        self.edited.write_bytes(b'corrupt accepted guardian revision')
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_guardian_revision_cannot_point_at_an_unexpected_folder(self):
        self.choose_guardian_revision(self.a)
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_guardian_revision_requires_explicit_canonical_approval(self):
        value = self.choose_guardian_revision()
        value['approvedRevision']['approvalStatus'] = 'pending_user_review'
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_new_approved_batch_revision_links_to_its_exact_verified_folder(self):
        revised = self.root / 'output/artwork/revisioni_voti_2026-11-06/approved_v2.png'
        revised.parent.mkdir()
        revised.write_bytes(b'explicitly accepted latest batch revision')
        self.choose_guardian_revision(revised)
        result = self.banner('example', self.baseline)
        self.assertIn('../revisioni_voti_2026-11-06/approved_v2.png', result)
        self.assertIn('scelta artistica canonica', result)

    def test_new_approved_batch_revision_cannot_widen_the_folder_allowlist(self):
        revised = self.root / 'output/artwork/revisioni_voti_2026-11-06_extra/approved_v2.png'
        revised.parent.mkdir()
        revised.write_bytes(b'payload in unverified sibling folder')
        self.choose_guardian_revision(revised)
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_approved_revision_without_legacy_marker_requires_native_provenance(self):
        value = self.choose_guardian_revision()
        artwork = value['approvedRevision']['artwork']
        artwork.pop('sourceKind')
        provenance = self.edited.with_suffix('.provenance.json')
        provenance.write_text(json.dumps({'id': 'example', 'tool': 'image_gen.imagegen',
                                           'sha256': artwork['sha256']}), encoding='utf-8')
        artwork.update(source=str(self.edited), provenanceFile=str(provenance),
                       provenanceSha256=sha256(provenance.read_bytes()).hexdigest())
        self.assertIn('scelta artistica canonica', self.banner('example', self.baseline))

    def test_corrupt_provenance_cannot_attest_a_markerless_approved_revision(self):
        value = self.choose_guardian_revision()
        artwork = value['approvedRevision']['artwork']
        artwork.pop('sourceKind')
        provenance = self.edited.with_suffix('.provenance.json')
        provenance.write_bytes(b'original native receipt')
        artwork.update(source=str(self.edited), provenanceFile=str(provenance),
                       provenanceSha256=sha256(provenance.read_bytes()).hexdigest())
        provenance.write_bytes(b'changed native receipt')
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_no_choice_does_not_invent_a_canon(self):
        self.assertEqual('', self.banner('example', self.baseline))

    def test_selected_base_is_not_presented_as_an_approved_unchanged_image(self):
        value = self.choose('A', self.a)
        value.update(artisticStatus='user_selected_base_revision_requested',
                     requiresApprovedRevisionBeforeIntegration=True,
                     unchangedBaseIsApprovedForRuntime=False)
        value['integration']['status'] = 'held_for_requested_artwork_revision'
        before = json.loads(json.dumps(value))
        result = self.banner('example', self.baseline)
        self.assertIn('base scelta, revisione richiesta', result)
        self.assertIn('non è approvato per integrazione', result)
        self.assertIn('href="a.png"', result)
        self.assertNotIn('scelta artistica canonica', result)
        self.assertEqual(before, value)

    def test_selected_base_still_requires_the_recorded_image_hash(self):
        value = self.choose('A', self.a)
        value['artisticStatus'] = 'user_selected_base_revision_requested'
        self.a.write_bytes(b'changed requested base')
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_anatomy_hold_preserves_the_vote_without_reopening_old_alternatives(self):
        value = self.choose('B', self.a)
        self.env['ANATOMY_BLOCKED'] = {'example'}
        before = json.loads(json.dumps(value))
        result = self.banner('example', self.baseline)
        self.assertIn('scelta mantenuta, correzione anatomica richiesta', result)
        self.assertIn('nessun nuovo voto', result)
        self.assertNotIn('scelta artistica canonica', result)
        self.assertEqual(before, value)

    def test_redesign_reference_is_not_an_exact_existing_artwork_vote(self):
        self.env['REDESIGN_IDS'] = {'example'}
        result = self.banner('example', self.baseline)
        self.assertIn('Nuova proposta richiesta', result)
        self.assertNotIn('scelta artistica canonica', result)
        self.assertNotIn('href=', result)
        self.assertEqual({}, self.env['CHOICES'])

    def test_unapproved_status_cannot_create_a_canonical_badge(self):
        self.choose()['artisticStatus'] = 'pending_user_review'
        with self.assertRaises(AssertionError):
            self.banner('example', self.baseline)

    def test_explicit_approved_revision_supersedes_base_and_old_anatomy_hold(self):
        value = self.choose_guardian_revision()
        value.update(artisticStatus='user_selected_base_revision_requested',
                     requiresApprovedRevisionBeforeIntegration=True)
        self.env['ANATOMY_BLOCKED'] = {'example'}
        result = self.banner('example', self.baseline)
        self.assertIn('scelta artistica canonica', result)
        self.assertIn('../correzioni_canoniche_2026-11-06/approved_edit.png', result)
        self.assertNotIn('base scelta', result)
        self.assertNotIn('correzione anatomica richiesta', result)


@unittest.skipUnless(HELPER.is_file(), 'Local artwork review helper is not present in this checkout')
class ArtworkScopedRetirementTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='artwork-retirement-scope-', dir=REPOSITORY / 'build')
        self.root = Path(self.temp.name)
        source = self.root / 'lib/pages/oculum_dungeon/monster_book.dart'
        source.parent.mkdir(parents=True)
        source.write_text("bool oculumIsRetiredMonsterId(String id) => "
                          "id.trim() == 'duellante_variante_errante' || const {"
                          "'sagrestano', 'old_family'"
                          "}.contains(id.trim().split('_variante_').first);", encoding='utf-8')
        nodes = [node for node in ast.parse(HELPER.read_text(encoding='utf-8')).body
                 if isinstance(node, ast.FunctionDef)
                 and node.name in ('gallery_retirement_rules', 'gallery_is_retired')]
        self.assertEqual(2, len(nodes))
        self.env = dict(Path=Path, re=re)
        exec(compile(ast.Module(body=nodes, type_ignores=[]), str(HELPER), 'exec'), self.env)

    def tearDown(self):
        self.temp.cleanup()

    def test_exact_variant_does_not_retire_its_base_or_siblings(self):
        families, exact = self.env['gallery_retirement_rules'](self.root)
        retired = self.env['gallery_is_retired']
        self.assertEqual({'duellante_variante_errante'}, exact)
        self.assertTrue(retired(' duellante_variante_errante ', families, exact))
        self.assertFalse(retired('duellante', families, exact))
        self.assertFalse(retired('duellante_variante_veterana', families, exact))

    def test_family_retirement_includes_variants_without_prefix_lookalikes(self):
        families, exact = self.env['gallery_retirement_rules'](self.root)
        retired = self.env['gallery_is_retired']
        self.assertTrue(retired('sagrestano', families, exact))
        self.assertTrue(retired('sagrestano_variante_veterana', families, exact))
        self.assertFalse(retired('sagrestano_personale', families, exact))
        self.assertFalse(retired('duellante_variante_errante_personale', families, exact))


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
