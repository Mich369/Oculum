"""Exercise opt-in Windows package deduplication in an isolated staging tree."""

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "build"
INSTALLER = ROOT / "scripts/install_github_distribution.ps1"
POWERSHELL = os.environ.get("OculumTestPowerShell", "powershell.exe")


@unittest.skipUnless(sys.platform == "win32", "Windows hard links required")
class DistributionRuntimeDedupTests(unittest.TestCase):
    def setUp(self):
        BUILD.mkdir(exist_ok=True)
        self.fixture = tempfile.TemporaryDirectory(prefix="oculum-dedup-", dir=BUILD)
        self.addCleanup(self.fixture.cleanup)
        self.root = Path(self.fixture.name)
        self.stage = self.root / "new stage"
        self.previous = self.root / "previous"
        for directory in (self.stage, self.previous):
            for edition in ("", "windows", "windows-test"):
                assets = directory / edition / "data/flutter_assets"
                assets.mkdir(parents=True)
                (assets / "art.webp").write_bytes(b"identical artwork" * 512)
                (directory / edition / "data/app.so").write_bytes(
                    b"test profile" if edition == "windows-test" else b"normal profile"
                )
                (directory / edition / "preferences.json").write_bytes(b"editable")
            (directory / "Oculum-Windows.zip").write_bytes(b"ordinary archive")

    def invoke(self, setup=""):
        manifest = self.root / "records.json"
        manifest.write_text(json.dumps([
            {"path": str(path.relative_to(self.stage)), "bytes": path.stat().st_size,
             "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
            for path in self.stage.rglob("*") if path.is_file()
        ]))
        quote = lambda path: "'" + str(path).replace("'", "''") + "'"
        command = (
            "$ErrorActionPreference='Stop'; "
            "$tokens=$null; $errors=$null; "
            "$script = [System.Management.Automation.Language.Parser]::ParseFile(" +
            quote(INSTALLER) + ",[ref]$tokens,[ref]$errors); "
            "if ($errors) { throw ($errors | Out-String) }; "
            "$script.FindAll({ param($n) "
            "$n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and "
            "$n.Name -in @('Join-VerifiedRuntimeFile', 'Optimize-VerifiedWindowsRuntime') }, "
            "$false) | ForEach-Object { Invoke-Expression $_.Extent.Text }; "
            "$records = @(Get-Content -LiteralPath " + quote(manifest) +
            " -Raw | ConvertFrom-Json); "
            + setup + " Optimize-VerifiedWindowsRuntime " + quote(self.stage) +
            " $records | ConvertTo-Json -Compress"
        )
        return subprocess.run(
            [POWERSHELL, "-NoProfile", "-NonInteractive", "-Command", command],
            capture_output=True, text=True, timeout=30,
        )

    def test_identical_runtime_files_share_storage_only_within_staging(self):
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        linked = json.loads(result.stdout)
        art = Path("data/flutter_assets/art.webp")
        app = Path("data/app.so")
        self.assertEqual(linked["files"], 3)
        self.assertEqual(linked["bytes"], 2 * (self.stage / art).stat().st_size +
                         (self.stage / app).stat().st_size)
        self.assertTrue(os.path.samefile(self.stage / art, self.stage / "windows" / art))
        self.assertTrue(os.path.samefile(self.stage / art, self.stage / "windows-test" / art))
        self.assertFalse(os.path.samefile(self.stage / art, self.previous / art))
        self.assertFalse(os.path.samefile(self.stage / app, self.stage / "windows-test" / app))
        for relative in ("preferences.json", "Oculum-Windows.zip"):
            self.assertEqual((self.stage / relative).stat().st_nlink, 1)
        self.assertFalse(any(self.stage.rglob(".oculum-link-*")))

    def test_unsupported_hardlinks_keep_independent_copies(self):
        result = self.invoke("function New-Item { throw 'HardLink unsupported in fixture' };")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout),
                         {"files": 0, "bytes": 0, "copiesRetained": 3})
        self.assertEqual((self.stage / "data/app.so").stat().st_nlink, 1)
        self.assertFalse(any(self.stage.rglob(".oculum-link-*")))

    def test_modified_file_is_never_replaced_using_an_old_digest(self):
        target = self.stage / "data/app.so"
        result = self.invoke(f"[IO.File]::WriteAllText('{target}', 'altered binary');")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Runtime destination changed before deduplication", result.stderr)
        self.assertEqual(target.read_bytes(), b"altered binary")
        self.assertEqual((self.stage / "windows/data/app.so").read_bytes(), b"normal profile")

    def test_reparse_directory_is_rejected(self):
        path = self.stage / "windows-test/data/flutter_assets"
        for child in path.iterdir():
            child.unlink()
        path.rmdir()
        target = self.previous / "data/flutter_assets"
        subprocess.run(
            [POWERSHELL, "-NoProfile", "-NonInteractive", "-Command",
             f"New-Item -ItemType Junction -Path '{path}' -Value '{target}'"],
            capture_output=True, check=True, timeout=30,
        )
        self.addCleanup(lambda: os.rmdir(path) if path.exists() else None)
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Runtime path passes through a reparse point", result.stderr)
        self.assertEqual((target / "art.webp").stat().st_nlink, 1)


if __name__ == "__main__":
    unittest.main()
