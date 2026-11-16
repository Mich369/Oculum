import hashlib
import json
from datetime import datetime, timedelta, timezone
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from scripts import prune_unchosen_expressive_ink as cleanup


class ChoiceCleanupTest(unittest.TestCase):
    def setUp(self):
        build = cleanup.ROOT / 'build'
        build.mkdir(exist_ok=True)
        workspace = tempfile.TemporaryDirectory(prefix='choice-cleanup-', dir=build)
        self.addCleanup(workspace.cleanup)
        self.root = Path(workspace.name).resolve()
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        self.art = self.root / 'output' / 'artwork'
        self.batch = self.art / 'expressive_ink_lotto_03_esistenti' / 'monster'
        self.batch.mkdir(parents=True)
        self.choice = datetime(2026, 11, 15, 7, tzinfo=timezone.utc)

    def image(self, letter, *, content=None, late=False):
        data = content or letter.encode()
        path = self.batch / f'monster-{letter.lower()}.webp'
        path.write_bytes(data)
        date = self.choice + timedelta(seconds=1 if late else -1)
        os.utime(path, (date.timestamp(), date.timestamp()))
        return {
            'slot': letter, 'status': 'verified_new', 'category': 'new_ink',
            'artwork': {'path': str(path), 'bytes': len(data),
                        'sha256': hashlib.sha256(data).hexdigest()},
        }

    def write(self, path, value):
        path.write_text(json.dumps(value), encoding='utf-8')

    def set_choice(self, slot):
        slot.update(category='approved', status='verified_existing')
        art = slot['artwork']
        receipt = self.batch / 'SCELTA.json'
        art.update(approvedFor='monster', approvalReceipt=str(receipt))
        self.write(receipt, {'id': 'monster', 'slot': slot['slot'], 'sha256': art['sha256'],
                             'atUtc': self.choice.isoformat()})

    def manifest(self, path, slots):
        path.parent.mkdir(exist_ok=True)
        self.write(path, {'schemaVersion': 1, 'batchId': path.parent.name, 'revision': 1,
                          'source': 'legacy fixture',
                          'entries': [{'id': 'monster', 'slots': slots}]})

    def test_mature_choice_removes_only_prior_unprotected_proposals_and_copies(self):
        chosen, sibling, reused, tracked, late, legacy = [self.image(x) for x in 'ABCDEF']
        late = self.image('E', late=True)
        legacy.update(category='previous', status='verified_existing')
        self.set_choice(chosen)
        digest_copy = self.root / 'assets' / 'canon.webp'
        digest_copy.parent.mkdir()
        digest_copy.write_bytes(Path(reused['artwork']['path']).read_bytes())
        subprocess.run(['git', '-C', str(self.root), 'add', '--', tracked['artwork']['path']], check=True)
        stage = self.art / 'expressive_ink_lotto_03_staging_monster'
        stage.mkdir()
        draft = Path(sibling['artwork']['path'])
        duplicate = stage / draft.name
        duplicate.write_bytes(draft.read_bytes())
        local = self.batch / 'MANIFEST.json'
        view = self.art / 'expressive_ink_lotto_03' / 'MANIFEST.json'
        for manifest in (local, view):
            self.manifest(manifest, [chosen, sibling, reused, tracked, late, legacy])
        preview, pending, _ = cleanup.run(self.root, now=self.choice + timedelta(minutes=59))
        self.assertEqual(preview, [])
        self.assertEqual(pending, 4)
        removed, _, _ = cleanup.run(self.root, apply=True, now=self.choice + timedelta(hours=1))
        self.assertEqual({p for p, _ in removed}, {draft, duplicate})
        for art in (chosen, reused, tracked, late, legacy):
            self.assertTrue(Path(art['artwork']['path']).is_file())
        for manifest in (local, view):
            deleted = json.loads(manifest.read_text())['entries'][0]['slots'][1]
            self.assertEqual(deleted['status'], 'rejected_deleted')
            self.assertNotIn('artwork', deleted)
            self.assertEqual(deleted['choiceCleanup']['sha256'], sibling['artwork']['sha256'])
        self.assertFalse(cleanup.run(self.root, apply=True, now=self.choice + timedelta(hours=2))[0])

    def test_no_choice_in_current_lot_and_changed_content_are_preserved(self):
        chosen, draft = self.image('A'), self.image('B')
        local = self.batch / 'MANIFEST.json'
        chosen.update(category='approved', status='verified_existing')
        self.manifest(local, [chosen, draft])
        now = self.choice + timedelta(hours=1)
        self.assertFalse(cleanup.run(self.root, apply=True, now=now)[0])
        self.set_choice(chosen)
        self.manifest(local, [chosen, draft])
        file = Path(draft['artwork']['path'])
        stamp = file.stat().st_mtime
        file.write_bytes(b'X')
        os.utime(file, (stamp, stamp))
        self.assertFalse(cleanup.run(self.root, apply=True, now=now)[0])
        self.assertTrue(file.is_file())

    def test_voted_appendix_proposals_follow_the_same_wait(self):
        chosen, draft = self.image('A'), self.image('B')
        self.set_choice(chosen)
        local = self.batch / 'MANIFEST.json'
        self.write(local, {'schemaVersion': 1, 'batchId': self.batch.name,
                           'revision': 1, 'counts': {'verified_new': 2},
                           'entries': [], 'referenceEntries': [{'id': 'monster', 'slots': [chosen, draft]}]})
        self.assertFalse(cleanup.run(self.root, now=self.choice + timedelta(minutes=59))[0])
        self.assertEqual(len(cleanup.run(self.root, apply=True, now=self.choice + timedelta(hours=1))[0]), 1)
        manifest = json.loads(local.read_text(encoding='utf-8'))
        self.assertEqual(manifest['referenceEntries'][0]['slots'][1]['status'], 'rejected_deleted')
        self.assertEqual(manifest['counts']['verified_new'], 2)

    def standalone_image(self, folder, leaf, slot, *, webp=True):
        # The cleanup checks the RIFF/WebP container marker in addition to SHA.
        data = b'RIFF\x14\x00\x00\x00WEBPVP8L' if webp else b'\x89PNG'
        data += leaf.encode()
        path = folder / leaf
        path.write_bytes(data)
        stamp = (self.choice - timedelta(seconds=1)).timestamp()
        os.utime(path, (stamp, stamp))
        return {
            'slot': slot, 'status': 'verified_new', 'category': 'new_ink',
            'artwork': {'path': str(path), 'bytes': len(data),
                        'sha256': hashlib.sha256(data).hexdigest()},
        }

    def standalone_choice(self, pack, monster, chosen, drafts):
        folder = self.art / pack
        receipt = folder / 'SCELTA.json'
        art = chosen['artwork']
        chosen.update(category='approved', status='verified_existing')
        art.update(approvedFor=monster, approvalReceipt=str(receipt))
        self.write(receipt, {
            'id': monster, 'slot': 'C1', 'gallerySlot': 'C', 'sha256': art['sha256'],
            'status': 'selected', 'source': 'user_choice', 'signedFrom': 'chat',
            'canonicalWebP': art['path'], 'atUtc': self.choice.isoformat(),
        })
        sidecar = folder / cleanup.CLEANUP_MANIFEST
        self.write(sidecar, {'schemaVersion': 1, 'batchId': pack, 'revision': 1,
                             'entries': [{'id': monster, 'slots': [chosen, *drafts]}]})
        return receipt, sidecar

    def test_standalone_waits_and_prunes_only_signed_pack_proposals(self):
        pack = 'expressive_ink_guardia_solare_elite'
        folder = self.art / pack
        folder.mkdir()
        chosen = self.standalone_image(folder, 'guardia-solare-elite-c1.webp', 'C')
        draft = self.standalone_image(folder, 'guardia-solare-elite-a.webp', 'A')
        fake = self.standalone_image(folder, 'guardia-solare-elite-b.webp', 'B', webp=False)
        unrelated = self.standalone_image(folder, 'unrelated-d.webp', 'D')
        previous = self.standalone_image(folder, 'guardia-solare-elite-g.webp', 'G')
        previous.update(category='previous', status='verified_existing')
        self.standalone_choice(pack, 'guardia_solare_elite', chosen, [draft, fake, unrelated, previous])
        non_reviewed = self.art / 'expressive_ink_senka_staging_next'
        non_reviewed.mkdir()
        draft_path = Path(draft['artwork']['path'])
        duplicate = non_reviewed / draft_path.name
        duplicate.write_bytes(draft_path.read_bytes())
        gallery = folder / 'GALLERIA.html'
        gallery.write_text('custom gallery', encoding='utf-8')

        early, _, _ = cleanup.run(self.root, now=self.choice + timedelta(minutes=59))
        self.assertEqual(early, [])
        now = self.choice + timedelta(hours=1)
        planned, _, _ = cleanup.run(self.root, now=now)
        self.assertEqual([p for p, _ in planned], [draft_path])
        self.assertTrue(draft_path.exists())
        removed, _, actions = cleanup.run(self.root, apply=True, now=now)
        self.assertEqual(removed, planned)
        self.assertEqual(actions, [])
        for s in (chosen, fake, unrelated, previous):
            self.assertTrue(Path(s['artwork']['path']).is_file())
        self.assertTrue(duplicate.is_file())
        self.assertEqual(gallery.read_text(encoding='utf-8'), 'custom gallery')
        slots = json.loads((folder / cleanup.CLEANUP_MANIFEST).read_text())['entries'][0]['slots']
        self.assertEqual(slots[1]['status'], 'rejected_deleted')

    def test_large_lot_requires_sidecar_and_updates_both_visible_galleries(self):
        pack = 'expressive_ink_bambola_vapium_veterana_20261115'
        monster = 'bambola_vapium_variante_veterana'
        folder = self.art / pack
        folder.mkdir()
        chosen = self.standalone_image(folder, f'{monster}-c.webp', 'C')
        historical = self.standalone_image(folder, f'{monster}-g.webp', 'G')
        historical.update(category='approved', status='verified_existing')
        draft = self.standalone_image(folder, f'{monster}-h.webp', 'H')
        draft['category'] = 'alternate_palette'
        draft_path = Path(draft['artwork']['path'])
        receipt, sidecar = self.standalone_choice(pack, monster, chosen, [historical, draft])
        recorded = self.choice + timedelta(minutes=10)
        proof = json.loads(receipt.read_text(encoding='utf-8'))
        proof['atUtc'] = recorded.isoformat()
        self.write(receipt, proof)
        sidecar_contents = json.loads(sidecar.read_text(encoding='utf-8'))
        sidecar.unlink()

        aggregate = self.art / 'expressive_ink_secondo_grande_lotto_20261115'
        aggregate.mkdir()
        galleries = [folder / 'MANIFEST.json', aggregate / 'MANIFEST.json']
        for manifest in galleries:
            document = {**sidecar_contents, 'batchId': manifest.parent.name,
                        'counts': {'verifiedNew': 1}}
            self.write(manifest, document)

        mature = recorded + timedelta(hours=1)
        self.assertEqual(cleanup.run(self.root, now=mature)[:2], ([], 0))
        self.write(sidecar, {key: value for key, value in sidecar_contents.items()
                             if key != 'revision'})
        early = mature - timedelta(seconds=1)
        self.assertEqual(cleanup.run(self.root, now=early)[:2], ([], 1))
        planned, _, _ = cleanup.run(self.root, now=mature)
        self.assertEqual([path for path, _ in planned], [draft_path])

        removed, _, actions = cleanup.run(self.root, apply=True, now=mature)
        self.assertEqual(removed, planned)
        self.assertEqual(set(actions), {(manifest, 'gallery') for manifest in galleries})
        self.assertTrue(Path(chosen['artwork']['path']).exists())
        self.assertTrue(Path(historical['artwork']['path']).exists())
        for manifest in [sidecar, *galleries]:
            parsed = json.loads(manifest.read_text(encoding='utf-8'))
            self.assertEqual(parsed['revision'], 2)
            rejected = parsed['entries'][0]['slots'][2]
            self.assertEqual(rejected['status'], 'rejected_deleted')
            self.assertEqual(rejected['choiceCleanup']['selectedAtUtc'], recorded.isoformat())
            self.assertEqual(parsed.get('counts', {}).get('verifiedNew', 0), 0)

    def test_standalone_unlisted_pack_and_changed_receipt_are_preserved(self):
        case = 'senka-telefono'
        for pack in ('expressive_ink_senka_staging_next', 'expressive_ink_unlisted'):
            folder = self.art / pack
            folder.mkdir()
            chosen = self.standalone_image(folder, f'{case}-a.webp', 'C')
            draft = self.standalone_image(folder, f'{case}-b.webp', 'B')
            receipt, _ = self.standalone_choice(pack, case, chosen, [draft])
            if pack == 'expressive_ink_senka_staging_next':
                selected_receipt = receipt
        original_plan = cleanup.build_plan

        def withdraw_after_planning(*args):
            result = original_plan(*args)
            selected_receipt.unlink()
            return result

        now = self.choice + timedelta(hours=1)
        with patch.object(cleanup, 'build_plan', side_effect=withdraw_after_planning):
            removed, _, actions = cleanup.run(self.root, apply=True, now=now)
        self.assertEqual(removed, [])
        self.assertEqual([kind for _, kind in actions], ['error'])
        self.assertEqual(len(list(self.art.glob(f'*/{case}-b.webp'))), 2)

    def letter_lot(self, pack='expressive_ink_ragno_putrido_20261116'):
        folder = self.art / pack
        folder.mkdir()
        monster, receipt_name = cleanup.LETTER_PACKAGES.get(pack, ('ragno_putrido', 'CONFERMA-VENEMUK.json'))
        artworks = [self.standalone_image(folder, f'{letter}.webp', letter) for letter in 'ABCDEFGH']
        selected = artworks[5]['artwork']
        receipt = folder / receipt_name
        runtime = self.root / 'assets' / 'oculum' / 'home_art_authored' / f'theme_{monster}_canon_20261116.webp'
        runtime.parent.mkdir(parents=True, exist_ok=True)
        runtime.write_bytes(Path(selected['path']).read_bytes())
        self.write(receipt, {
            'id': monster, 'slot': 'F', 'source': 'user_choice', 'status': 'selected',
            'comparisonSource': selected['path'], 'confirmationSource': 'call_000aaa',
            'atUtc': self.choice.isoformat(), 'sha256': selected['sha256'],
            'runtimeWebP': runtime.relative_to(self.root).as_posix(),
        })
        manifest = folder / 'MANIFEST.json'
        self.write(manifest, {
            'schemaVersion': 1, 'id': monster,
            'preview': {'file': 'PANORAMICA.webp'},
            'variants': [{
                'slot': a['slot'], 'file': Path(a['artwork']['path']).name,
                'sha256': a['artwork']['sha256'],
                'sourceKind': 'historical_alternative' if a['slot'] == 'H' else 'imagegen_proposal',
            } for a in artworks],
        })
        (folder / 'PANORAMICA.webp').write_bytes(b'comparison')
        return folder, runtime, receipt, manifest

    def test_letter_lot_waits_and_keeps_runtime_chosen_archive_panorama_and_other_proofs(self):
        folder, runtime, _, manifest = self.letter_lot()
        approved_copy = runtime.parent / 'other_theme.webp'
        approved_copy.write_bytes((folder / 'D.webp').read_bytes())
        subprocess.run(['git', '-C', str(self.root), 'add', '--', str(folder / 'E.webp')], check=True)
        date = (self.choice + timedelta(seconds=1)).timestamp()
        os.utime(folder / 'C.webp', (date, date))
        stamp = (folder / 'G.webp').stat().st_mtime
        (folder / 'G.webp').write_bytes(b'Changed outside the manifest')
        os.utime(folder / 'G.webp', (stamp, stamp))
        early = self.choice + timedelta(hours=1) - timedelta(seconds=1)
        self.assertEqual(cleanup.run(self.root, now=early)[:2], ([], 6))

        mature = self.choice + timedelta(hours=1)
        planned, _, _ = cleanup.run(self.root, now=mature)
        self.assertEqual({path for path, _ in planned}, {folder / 'A.webp', folder / 'B.webp'})
        self.assertEqual(cleanup.run(self.root, apply=True, now=mature), (planned, 0, []))
        for letter in 'CDEFGH':
            self.assertTrue((folder / f'{letter}.webp').exists())
        self.assertTrue(runtime.exists())
        self.assertEqual((folder / 'PANORAMICA.webp').read_bytes(), b'comparison')
        actual = json.loads(manifest.read_text(encoding='utf-8'))
        self.assertEqual(actual['preview']['file'], 'PANORAMICA.webp')
        self.assertEqual(actual['variants'][0]['status'], 'rejected_deleted')
        self.assertEqual(actual['variants'][0]['choiceCleanup']['removedFile'], 'A.webp')
        self.assertNotIn('file', actual['variants'][0])
        self.assertEqual(cleanup.run(self.root, now=mature), ([], 0, []))

    def test_letter_lot_blocks_pending_unlinked_and_unlisted_choices(self):
        folder, runtime, receipt, _ = self.letter_lot()
        self.letter_lot('expressive_ink_riallineamento_20261116')
        proof = json.loads(receipt.read_text(encoding='utf-8'))
        now = self.choice + timedelta(hours=1)
        self.write(receipt, {**proof, 'status': 'selected_pending_runtime'})
        self.assertEqual(cleanup.run(self.root, now=now), ([], 0, []))
        self.write(receipt, proof)
        original = runtime.read_bytes()
        runtime.unlink()
        self.assertEqual(cleanup.run(self.root, now=now), ([], 0, []))
        runtime.write_bytes(b'RIFF\x14\x00\x00\x00WEBPVP8L' + b'different')
        self.assertEqual(cleanup.run(self.root, now=now), ([], 0, []))
        runtime.write_bytes(original)
        self.write(receipt, {**proof, 'sha256': '0' * 64})
        self.assertEqual(cleanup.run(self.root, now=now), ([], 0, []))
        self.assertTrue((folder / 'B.webp').is_file())

    def test_letter_lot_rechecks_runtime_after_planning_and_recovers_deleted_file(self):
        folder, runtime, _, manifest = self.letter_lot()
        now = self.choice + timedelta(hours=1)
        planner = cleanup.build_plan

        def withdraw_runtime(*args):
            result = planner(*args)
            runtime.unlink()
            return result

        data = runtime.read_bytes()
        with patch.object(cleanup, 'build_plan', side_effect=withdraw_runtime):
            removed, _, actions = cleanup.run(self.root, apply=True, now=now)
        self.assertFalse(removed)
        self.assertTrue(actions and all(action == 'error' for _, action in actions))
        runtime.write_bytes(data)
        (folder / 'A.webp').unlink()
        removed, _, _ = cleanup.run(self.root, apply=True, now=now)
        self.assertEqual({path.name for path, _ in removed}, {'B.webp', 'C.webp', 'D.webp', 'E.webp', 'G.webp'})
        self.assertFalse((self.art / cleanup.JOURNAL).exists())
        variant = json.loads(manifest.read_text(encoding='utf-8'))['variants'][0]
        self.assertEqual(variant['status'], 'rejected_deleted')
        self.assertEqual(variant['choiceCleanup']['removedFile'], 'A.webp')
