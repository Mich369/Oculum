import importlib.util
import json
from pathlib import Path
import stat
import tempfile
import unittest
from zipfile import ZipFile, ZipInfo


SCRIPT = Path(__file__).resolve().parents[1] / "audit_release_payload.py"
SPEC = importlib.util.spec_from_file_location("audit_release_payload", SCRIPT)
audit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(audit)


class ReleasePayloadTests(unittest.TestCase):
    def archive(self, root, platform, extra=()):
        path = root / audit.PACKAGES[platform]
        with ZipFile(path, "w") as archive:
            for member in audit.required_members(platform):
                archive.writestr(member, b"runtime")
            archive.writestr("data/flutter_assets/art.webp", b"art")
            if platform == "android":
                archive.writestr("lib/arm64-v8a/libapp.so", b"native")
            for member in extra:
                archive.writestr(member, b"payload")
        return path

    def test_review_categories_leave_required_assets_and_archives_alone(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = self.archive(
                root,
                "android",
                [
                    "okhttp3/internal/publicsuffix/publicsuffixes.gz",
                    "data/older-build.zip",
                    "symbol.pdb",
                    "backup/runtime.tmp",
                    ".git/config",
                ],
            )
            report = audit.audit_archive(path, "android")
            self.assertEqual(report["files"], 9)
            self.assertEqual(report["categories"]["native/arm64-v8a"]["bytes"], 6)
            self.assertEqual(report["categories"]["runtime_archive"]["files"], 1)
            self.assertEqual(
                {row["category"] for row in report["candidatesForReview"]},
                {"debug_symbol", "development", "embedded_archive", "temporary"},
            )

    def test_rejects_traversal_symlink_collisions_and_wrong_edition(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            link = ZipInfo("link")
            link.create_system = 3
            link.external_attr = (stat.S_IFLNK | 0o777) << 16
            for members, message in [
                (["../outside.txt"], "Unsafe"),
                ([r"C:\outside.txt"], "Unsafe"),
                (["CON.txt"], "Unsafe Windows"),
                ([link], "Special"),
                (["a", "A"], "Duplicate"),
                (["path", "Path/file.txt"], "file as directory"),
                (["Oculum-Test.exe"], "other edition"),
                (["old/Oculum-Test.exe"], "other edition"),
            ]:
                with self.subTest(members=members):
                    path = self.archive(root, "windows", members)
                    with self.assertRaisesRegex(ValueError, message):
                        audit.audit_archive(path, "windows")
            test_path = self.archive(root, "windows-test")
            self.assertEqual(audit.audit_archive(test_path, "windows-test")["platform"], "windows-test")

    def test_android_receipt_is_bound_to_the_exact_apk(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = self.archive(root, "android")
            report = audit.audit_archive(path, "android")
            metadata = {
                "package": "com.mich.oculum",
                "versionCode": 100293,
                "apkBytes": report["archiveBytes"],
                "apkSha256": report["archiveSha256"],
                "signingCertificateSha256": "a" * 64,
                "signatureVerified": True,
            }
            receipt = root / "android-update-compatibility.json"
            receipt.write_text(json.dumps(metadata), encoding="utf-8")
            self.assertTrue(audit.verify_android_receipt(report, receipt)["receiptMatchesArchive"])
            metadata["apkSha256"] = "0" * 64
            receipt.write_text(json.dumps(metadata), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "these APK bytes"):
                audit.verify_android_receipt(report, receipt)


if __name__ == "__main__":
    unittest.main()
