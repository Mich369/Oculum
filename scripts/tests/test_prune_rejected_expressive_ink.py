from datetime import datetime, timedelta, timezone
import hashlib
import json
from pathlib import Path
from types import SimpleNamespace
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from scripts import prune_rejected_expressive_ink as cleanup
from scripts.build_expressive_ink_gallery import hide_deleted_proposals


class ExpressiveInkCleanupTests(unittest.TestCase):
    now = datetime(2026, 11, 14, 12, tzinfo=timezone.utc)

    def setUp(self):
        build = (cleanup.ROOT / "build").resolve()
        build.mkdir(exist_ok=True)
        fixture = tempfile.TemporaryDirectory(prefix="expressive-cleanup-", dir=build)
        self.root = Path(fixture.name).resolve()
        self.assertTrue(self.root.is_relative_to(build))
        self.addCleanup(fixture.cleanup)
        self.batch = self.root / cleanup.BATCH_PATH
        self.batch.mkdir(parents=True)
        self.image = self.batch / "test_creature-a.webp"
        self.image.write_bytes(b"synthetic image A")
        self.digest = hashlib.sha256(self.image.read_bytes()).hexdigest()
        self.confirmation = self.batch / cleanup.RECEIPT
        self.input = self.root / "current-votes.json"
        self.rejected = {
            "slot": "A", "sha256": self.digest, "rejectedAt": "2026-11-14T09:00:00.000Z",
        }
        self.slots = [{
            "slot": "A", "category": "new_ink", "status": "verified_new",
            "artwork": {"path": str(self.image), "sha256": self.digest, "bytes": self.image.stat().st_size},
        }]
        self.write_manifest()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)

    def write_manifest(self, revision=4, references=None):
        (self.batch / "MANIFEST.json").write_text(json.dumps({
            "schemaVersion": 1, "batchId": cleanup.BATCH_ID, "revision": revision,
            "entries": [{"id": "test_creature", "slots": self.slots}],
            "referenceEntries": references or [],
        }), encoding="utf-8")

    def write_votes(self, votes, *, exported_at=None, revision=4):
        header = {"batchId": cleanup.BATCH_ID, "revision": revision}
        payload = {
            **header,
            "votes": [{**header, "id": "test_creature", **vote} for vote in votes],
        }
        if exported_at is not None:
            payload["exportedAtUtc"] = cleanup.utc_string(exported_at)
        self.input.write_text(json.dumps(payload), encoding="utf-8")

    def record_rejection(self, now=None):
        self.write_votes([{"rejections": [self.rejected]}])
        cleanup.run(self.root, record=self.input, now=now or self.now)

    def add_slot(self, letter, category, status="verified_new"):
        image = self.batch / f"test_creature-{letter.lower()}.webp"
        content = f"synthetic image {letter}".encode()
        image.write_bytes(content)
        digest = hashlib.sha256(content).hexdigest()
        slot = {
            "slot": letter,
            "category": category,
            "status": status,
            "artwork": {"path": str(image), "sha256": digest, "bytes": len(content)},
        }
        self.slots.append(slot)
        return image, {**self.rejected, "slot": letter, "sha256": digest}, slot

    def test_local_receipt_waits_an_hour_and_dry_run_does_not_write(self):
        self.assertEqual(cleanup.run(self.root, now=self.now), [])
        self.assertFalse(self.confirmation.exists())
        self.record_rejection()
        receipt_bytes = self.confirmation.read_bytes()
        self.assertEqual(cleanup.run(self.root, apply=True, now=self.now + timedelta(minutes=59)), [])
        due = self.now + timedelta(hours=1)
        self.assertEqual(cleanup.run(self.root, now=due), [(self.image, 17)])
        self.assertEqual(self.confirmation.read_bytes(), receipt_bytes)
        self.assertTrue(self.image.exists())
        self.assertEqual(cleanup.run(self.root, apply=True, now=due), [(self.image, 17)])
        self.assertFalse(self.image.exists())
        self.assertEqual(cleanup.read_receipt(self.batch)["decisions"][0]["state"], "deleted")
        self.assertEqual(cleanup.run(self.root, apply=True, now=due), [])

    def test_gallery_preserves_deleted_history_when_another_slot_changes(self):
        self.record_rejection()
        cleanup.run(self.root, apply=True, now=self.now + timedelta(hours=1))
        self.add_slot("B", "new_ink")
        self.write_manifest(revision=5)

        def load_gallery():
            manifest = json.loads((self.batch / "MANIFEST.json").read_text(encoding="utf-8"))
            hide_deleted_proposals(manifest, self.batch)
            return manifest["entries"][0]["slots"]

        self.assertEqual([slot["status"] for slot in load_gallery()], ["rejected_deleted", "verified_new"])
        self.image.write_bytes(b"synthetic image A")
        self.assertEqual(load_gallery()[0]["status"], "verified_new")

    def test_repeating_a_snapshot_does_not_reset_wait(self):
        self.record_rejection()
        self.record_rejection(self.now + timedelta(minutes=30))
        self.assertEqual(len(cleanup.read_receipt(self.batch)["decisions"]), 1)
        self.assertEqual(len(cleanup.run(self.root, now=self.now + timedelta(hours=1))), 1)

    def test_second_writer_waits_for_current_lock_to_close(self):
        self.write_votes([{"rejections": [self.rejected]}])
        with cleanup.lock_batch(self.batch):
            with self.assertRaises(OSError):
                cleanup.run(self.root, record=self.input, now=self.now)
        cleanup.run(self.root, record=self.input, now=self.now)
        self.assertTrue(self.confirmation.exists())

    def test_new_export_revokes_rifiuto_and_stale_export_cannot_restore_it(self):
        self.write_votes([{"rejections": [self.rejected]}], exported_at=self.now)
        cleanup.run(self.root, record=self.input, now=self.now)
        revocation_time = self.now + timedelta(minutes=5)
        self.write_votes([], exported_at=revocation_time)
        cleanup.run(self.root, record=self.input, now=revocation_time)
        self.write_votes([{"rejections": [self.rejected]}], exported_at=self.now)
        with self.assertRaisesRegex(ValueError, "più recente"):
            cleanup.run(self.root, record=self.input, now=revocation_time)
        self.assertEqual(cleanup.run(self.root, apply=True, now=self.now + timedelta(hours=2)), [])
        self.assertTrue(self.image.exists())
        self.assertEqual(cleanup.read_receipt(self.batch)["decisions"][0]["state"], "revoked")

    def test_previously_chosen_image_stays_protected(self):
        self.write_votes([{"slot": "A", "sha256": self.digest}])
        cleanup.run(self.root, record=self.input, now=self.now)
        self.record_rejection()
        self.assertEqual(cleanup.run(self.root, apply=True, now=self.now + timedelta(hours=2)), [])
        self.assertTrue(self.image.exists())

    def test_revised_bytes_or_manifest_do_not_match_receipt(self):
        self.record_rejection()
        self.image.write_bytes(b"synthetic image B")
        due = self.now + timedelta(hours=1)
        self.assertEqual(cleanup.run(self.root, apply=True, now=due), [])
        self.assertEqual(self.image.read_bytes(), b"synthetic image B")
        self.image.write_bytes(b"synthetic image A")
        self.write_manifest(revision=5)
        self.assertEqual(cleanup.run(self.root, apply=True, now=due), [])

    def test_a_canonical_reference_or_selection_conflict_cannot_be_recorded(self):
        self.slots.append({
            "slot": "G", "category": "approved", "status": "verified_existing",
            "artwork": self.slots[0]["artwork"],
        })
        self.write_manifest()
        protected = {**self.rejected, "slot": "G"}
        self.write_votes([{"rejections": [protected]}])
        with self.assertRaisesRegex(ValueError, "Rifiuto"):
            cleanup.run(self.root, record=self.input, now=self.now)
        self.write_votes([{"slot": "A", "sha256": self.digest, "rejections": [self.rejected]}])
        with self.assertRaisesRegex(ValueError, "Rifiuto"):
            cleanup.run(self.root, record=self.input, now=self.now)
        self.record_rejection()
        self.assertEqual(cleanup.run(self.root, apply=True, now=self.now + timedelta(hours=1)), [])

    def test_distinct_batch_reference_and_staged_asset_block_removal(self):
        self.record_rejection()
        other_batch = self.batch.parent / "other_lotto"
        other_batch.mkdir()
        other_manifest = other_batch / "MANIFEST.json"
        other_manifest.write_text(json.dumps({"image": str(self.image)}))
        due = self.now + timedelta(hours=1)
        self.assertEqual(cleanup.run(self.root, apply=True, now=due), [])
        other_manifest.unlink()
        subprocess.run(["git", "-C", str(self.root), "add", "--", str(self.image)], check=True)
        self.assertEqual(cleanup.run(self.root, apply=True, now=due), [])
        self.assertTrue(self.image.exists())

    def test_closed_reference_blocks_matching_candidate_bytes(self):
        self.record_rejection()
        self.write_manifest(references=[{
            "id": "reviewed_monster", "artworkReviewClosed": True, "slots": self.slots,
        }])
        due = self.now + timedelta(hours=1)
        self.assertEqual(cleanup.run(self.root, apply=True, now=due), [])
        self.assertTrue(self.image.exists())

    def test_hard_link_and_outside_manifest_path_are_rejected(self):
        self.record_rejection()
        other_file = self.root / "protected.webp"
        other_file.write_bytes(self.image.read_bytes())
        lstat = Path.lstat

        def simulated_link(path):
            info = lstat(path)
            return SimpleNamespace(st_mode=info.st_mode, st_nlink=2) if path == self.image else info

        with patch.object(Path, "lstat", simulated_link):
            self.assertEqual(cleanup.run(self.root, apply=True, now=self.now + timedelta(hours=1)), [])
        self.slots[0]["artwork"]["path"] = str(other_file)
        self.write_manifest()
        with self.assertRaisesRegex(ValueError, "Rifiuto"):
            self.record_rejection()
        self.assertTrue(other_file.exists())

    def test_recovers_after_unlink_before_final_receipt(self):
        self.record_rejection()
        due = self.now + timedelta(hours=1)
        save = cleanup.write_receipt

        def interrupt_after_unlink(batch, receipt):
            if receipt["decisions"][0]["state"] == "deleted":
                raise OSError("interrupted")
            save(batch, receipt)

        with patch.object(cleanup, "write_receipt", side_effect=interrupt_after_unlink):
            with self.assertRaisesRegex(OSError, "interrupted"):
                cleanup.run(self.root, apply=True, now=due)
        self.assertFalse(self.image.exists())
        self.assertEqual(cleanup.read_receipt(self.batch)["decisions"][0]["state"], "deleting")
        self.assertEqual(cleanup.run(self.root, apply=True, now=due), [])
        self.assertEqual(cleanup.read_receipt(self.batch)["decisions"][0]["state"], "deleted")

    def test_new_g_and_h_wait_a_full_hour_and_leave_undecided_a(self):
        g_image, g_rejection, _ = self.add_slot("G", "new_distant")
        h_image, h_rejection, _ = self.add_slot("H", "alternate_palette")
        self.write_manifest()
        self.write_votes([{"rejections": [g_rejection, h_rejection]}])
        cleanup.run(self.root, record=self.input, now=self.now)
        self.assertEqual(cleanup.run(self.root, apply=True, now=self.now + timedelta(minutes=59)), [])
        due = self.now + timedelta(hours=1)
        expected = [(g_image, 17), (h_image, 17)]
        self.assertEqual(cleanup.run(self.root, now=due), expected)
        self.assertTrue(g_image.exists())
        self.assertTrue(h_image.exists())
        self.assertEqual(cleanup.run(self.root, apply=True, now=due), expected)
        self.assertTrue(self.image.exists())
        self.assertFalse(g_image.exists())
        self.assertFalse(h_image.exists())

    def test_g_h_reject_reserved_categories_archives_and_canon_receipts(self):
        for letter, category, status, receipt in [
            ("G", "approved", "verified_new", ""),
            ("H", "previous", "verified_existing", ""),
            ("G", "new_distant", "verified_existing", ""),
            ("H", "alternate_palette", "pending_generation", ""),
            ("G", "alternate_palette", "verified_new", ""),
            ("H", "new_ink", "verified_new", ""),
            ("G", "new_distant", "verified_new", "CANON.json"),
        ]:
            with self.subTest(letter=letter, category=category, status=status, receipt=receipt):
                image, rejected, slot = self.add_slot(letter, category, status)
                if receipt:
                    slot["artwork"]["receipt"] = receipt
                self.write_manifest()
                self.write_votes([{"rejections": [rejected]}])
                with self.assertRaisesRegex(ValueError, "Rifiuto"):
                    cleanup.run(self.root, record=self.input, now=self.now)
                self.assertTrue(image.exists())
                self.slots.remove(slot)

    def test_new_h_honors_external_qa_hash_without_touching_staging_copy(self):
        image, rejected, _ = self.add_slot("H", "alternate_palette")
        self.write_manifest()
        self.write_votes([{"rejections": [rejected]}])
        cleanup.run(self.root, record=self.input, now=self.now)
        staging = self.batch.with_name(f"{cleanup.BATCH_ID}_ingresso")
        staging.mkdir()
        copy = staging / image.name
        copy.write_bytes(image.read_bytes())
        (staging / "qa.json").write_text(json.dumps({"sha256": rejected["sha256"]}))
        due = self.now + timedelta(hours=1)
        self.assertEqual(cleanup.run(self.root, apply=True, now=due), [])
        self.assertTrue(image.exists())
        self.assertTrue(copy.exists())

    def test_recovers_interrupted_h_deletion(self):
        image, rejected, _ = self.add_slot("H", "alternate_palette")
        self.write_manifest()
        self.write_votes([{"rejections": [rejected]}])
        cleanup.run(self.root, record=self.input, now=self.now)
        due = self.now + timedelta(hours=1)
        receipt = cleanup.read_receipt(self.batch)
        receipt["decisions"][0].update(state="deleting", verifiedAt=cleanup.utc_string(due))
        cleanup.write_receipt(self.batch, receipt)
        image.unlink()
        self.assertEqual(cleanup.run(self.root, apply=True, now=due), [])
        self.assertEqual(cleanup.read_receipt(self.batch)["decisions"][0]["state"], "deleted")


if __name__ == "__main__":
    unittest.main()
