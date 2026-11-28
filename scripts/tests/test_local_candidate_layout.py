from hashlib import sha256
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from zipfile import ZipFile

from scripts.audit_local_app_candidate import audit


class LocalCandidateLayoutTest(unittest.TestCase):
    def candidate(self, root, separated):
        log = b"player log\n"
        (root / "REGISTRO_AGGIORNAMENTI.md").write_bytes(log)
        desktop = root / "pc" if separated else root
        phone = root / "telefono" if separated else root
        desktop.mkdir(exist_ok=True)
        phone.mkdir(exist_ok=True)

        for folder, executable, archive in (
            ("windows", "oculum.exe", "Oculum-Windows.zip"),
            ("windows-test", "Oculum-Test.exe", "Oculum-Test-Windows.zip"),
        ):
            runtime = root / folder
            files = {
                executable: b"launch",
                "flutter_windows.dll": b"runtime",
                "data/app.so": folder.encode("ascii"),
                "data/icudtl.dat": b"data",
                "data/flutter_assets/assets/update/oculum_cumulative_log.md": log,
            }
            with ZipFile(desktop / archive, "w") as zipped:
                for name, data in files.items():
                    target = runtime / name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(data)
                    zipped.writestr(name, data)

        with ZipFile(phone / "Oculum-Android-release.apk", "w") as zipped:
            zipped.writestr("AndroidManifest.xml", b"manifest")
            zipped.writestr("classes.dex", b"classes")
            zipped.writestr(
                "assets/flutter_assets/assets/update/oculum_cumulative_log.md", log
            )

        files = []
        for path in root.rglob("*"):
            if path.is_file():
                data = path.read_bytes()
                files.append({
                    "path": path.relative_to(root).as_posix(),
                    "bytes": len(data),
                    "sha256": sha256(data).hexdigest(),
                })
        (root / "BUILD-VERIFICATE.json").write_text(
            json.dumps({"commit": "source", "files": files}), encoding="utf-8"
        )

    def test_checks_new_platform_directories_without_breaking_old_candidates(self):
        for separated in (False, True):
            with self.subTest(separated=separated), TemporaryDirectory() as folder:
                root = Path(folder)
                self.candidate(root, separated)
                report = audit(root, "source")
                self.assertEqual(report["pcAndPhonePackagesSeparated"], separated)
                self.assertTrue(report["windowsAndTestSeparated"])
                self.assertTrue(report["cumulativeLogMatchesEveryPackage"])
