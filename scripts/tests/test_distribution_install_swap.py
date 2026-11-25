"""Exercise distribution renames only in isolated children of build/."""

import ctypes
from ctypes import wintypes
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "build"
HELPER = ROOT / "scripts/oculum_distribution_swap.ps1"
INSTALLERS = (
    ROOT / "scripts/build_combat_distribution.ps1",
    ROOT / "scripts/install_github_distribution.ps1",
)


def ps_quote(value):
    return "'" + str(value).replace("'", "''") + "'"


@unittest.skipUnless(sys.platform == "win32", "Windows directory-lock semantics required")
class DistributionInstallSwapTests(unittest.TestCase):
    def setUp(self):
        BUILD.mkdir(exist_ok=True)
        self.fixture = tempfile.TemporaryDirectory(prefix="distribution-swap-fixture-", dir=BUILD)
        self.root = Path(self.fixture.name).resolve()
        self.assertEqual(self.root.parent, BUILD.resolve())
        self.target = self.root / "installed"
        self.staging = self.root / "verified-new"
        self.backup = self.root / "previous"
        for directory, content in ((self.target, "previous"), (self.staging, "new")):
            (directory / "windows/data").mkdir(parents=True)
            (directory / "BUILD-VERIFICATE.json").write_text(content)
            (directory / "windows/oculum.exe").write_text(content)
            (directory / "windows/data/app.so").write_text(content)
        self.addCleanup(self.fixture.cleanup)

    def invoke(self, before="", verify="", *, retention=False):
        command = (
            "$ErrorActionPreference='Stop'; . " + ps_quote(HELPER) + "; "
            "Invoke-OculumDistributionSwap "
            "-BuildRoot " + ps_quote(self.root) + " "
            "-DistributionRoot " + ps_quote(self.target) + " "
            "-StagingRoot " + ps_quote(self.staging) + " "
            "-BackupRoot " + ps_quote(self.backup) + " "
            "-BeforeSwap { " + before + " } "
            "-VerifyInstalled { " + verify + " }"
        )
        if retention:
            command += " -RetainSingleVerifiedBackup -VerifyRollback " + self.verify_rollback
        return self.run_powershell(command, retention=retention)

    def run_powershell(self, command, *, retention=False):
        return subprocess.run(
            ["pwsh.exe" if retention else "powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command", command],
            capture_output=True,
            text=True,
            timeout=30,
        )

    def assert_tree(self, directory, expected):
        self.assertEqual((directory / "BUILD-VERIFICATE.json").read_text(), expected)
        self.assertEqual((directory / "windows/oculum.exe").read_text(), expected)
        self.assertEqual((directory / "windows/data/app.so").read_text(), expected)

    def test_success_preserves_complete_previous_runtime(self):
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assert_tree(self.target, "new")
        self.assert_tree(self.backup, "previous")
        self.assertFalse(self.staging.exists())

    def test_locked_child_cannot_partially_move_live_distribution(self):
        create_file = ctypes.windll.kernel32.CreateFileW
        create_file.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
                                wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE]
        create_file.restype = wintypes.HANDLE
        # A loaded runtime can share reads/writes while refusing deletion/rename.
        handle = create_file(str(self.target / "windows/oculum.exe"), 0x80000000,
                             0x00000001 | 0x00000002, None, 3, 0x80, None)
        self.assertNotEqual(handle, wintypes.HANDLE(-1).value)
        try:
            result = self.invoke()
        finally:
            ctypes.windll.kernel32.CloseHandle.argtypes = [wintypes.HANDLE]
            ctypes.windll.kernel32.CloseHandle(handle)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assert_tree(self.target, "previous")
        self.assert_tree(self.staging, "new")
        self.assertFalse(self.backup.exists())

    def test_verification_failure_restores_old_and_returns_new_to_staging(self):
        result = self.invoke(verify="throw 'post-install verification failed'")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("post-install verification failed", result.stderr)
        self.assert_tree(self.target, "previous")
        self.assert_tree(self.staging, "new")
        self.assertFalse(self.backup.exists())

    def test_commit_change_before_swap_preserves_both_trees(self):
        result = self.invoke(before="throw 'repository commit changed'")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("repository commit changed", result.stderr)
        self.assert_tree(self.target, "previous")
        self.assert_tree(self.staging, "new")
        self.assertFalse(self.backup.exists())

    verify_rollback = """{
        param($path)
        $receipt = Get-Content -LiteralPath (Join-Path $path 'BUILD-VERIFICATE.json') -Raw | ConvertFrom-Json
        foreach ($file in $receipt.files) {
          if ((Get-FileHash -LiteralPath (Join-Path $path $file.path)).Hash -ne $file.sha256) {
            throw 'Content failed verification'
          }
        }
    }"""

    def write_release(self, directory, commit):
        file = directory / "windows/oculum.exe"
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(commit)
        (directory / "BUILD-VERIFICATE.json").write_text(json.dumps({
            "commit": commit,
            "files": [{"path": "windows/oculum.exe", "sha256": hashlib.sha256(file.read_bytes()).hexdigest()}],
        }))

    def seed_retention(self):
        # The public installer also supports the base swap by itself. Run the
        # retention cases when the helper provides it or an installer uses it.
        retention_available = "function Set-OculumVerifiedRollbackReceipt" in HELPER.read_text(encoding="utf-8-sig")
        retention_used = any(
            "-RetainSingleVerifiedBackup" in installer.read_text(encoding="utf-8-sig")
            for installer in INSTALLERS
        )
        if not (retention_available or retention_used):
            self.skipTest("This checkout does not include optional rollback retention")

        self.target = self.root / "distribution"
        self.staging = self.root / "stage-3"
        self.backup = self.root / "distribution-backup-2"
        self.old = self.root / "distribution-backup-1"
        self.unknown = self.root / "distribution-backup-unknown"
        self.marker = self.root / ".distribution.verified-rollback.json"
        for path, content in ((self.target, "two"), (self.staging, "three"),
                              (self.old, "one"), (self.unknown, "unknown")):
            self.write_release(path, content)
        result = self.run_powershell(
            "$ErrorActionPreference='Stop'; . " + ps_quote(HELPER) + "; "
            "Set-OculumVerifiedRollbackReceipt -BuildRoot " + ps_quote(self.root) +
            " -DistributionRoot " + ps_quote(self.target) + " -RollbackRoot " + ps_quote(self.old) +
            " -VerifyRollback " + self.verify_rollback,
            retention=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads(self.marker.read_text())["backupName"], self.old.name)

    def test_retention_prunes_only_previous_managed_verified_backup(self):
        self.seed_retention()
        result = self.invoke(retention=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.old.exists())
        self.assertTrue(self.unknown.exists())
        self.assertEqual((self.target / "windows/oculum.exe").read_text(), "three")
        self.assertEqual((self.backup / "windows/oculum.exe").read_text(), "two")
        receipt = json.loads(self.marker.read_text())
        self.assertEqual(receipt["backupName"], self.backup.name)
        self.assertIsNone(receipt["retired"])

    def test_retention_leaves_old_receipt_and_both_releases_on_failed_install(self):
        self.seed_retention()
        before = self.marker.read_bytes()
        result = self.invoke(verify="throw 'installed verification failed'", retention=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("installed verification failed", result.stderr)
        self.assertEqual(before, self.marker.read_bytes())
        self.assertTrue(self.old.exists())
        self.assertTrue(self.staging.exists())
        self.assertFalse(self.backup.exists())
        self.assertEqual((self.target / "windows/oculum.exe").read_text(), "two")

    def test_retention_rejects_unknown_files_and_directory_alternate_streams(self):
        self.seed_retention()
        extra = self.old / ".user-save.json"
        extra.write_text("personal")
        result = self.invoke(retention=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("untracked files", result.stderr)
        self.assertTrue(extra.exists())
        extra.unlink()
        stream = str(self.old) + ":user-save"
        with open(stream, "w") as output:
            output.write("personal")
        result = self.invoke(retention=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("alternate data streams", result.stderr)
        with open(stream) as data:
            self.assertEqual(data.read(), "personal")
        self.assertTrue(self.staging.exists())

    def test_retention_rejects_user_data_even_when_manifested(self):
        self.seed_retention()
        relative = "windows/data/oculum_save_blobs_test/backup.json"
        personal = self.target / relative
        personal.parent.mkdir(parents=True)
        personal.write_text("personal")
        manifest = self.target / "BUILD-VERIFICATE.json"
        receipt = json.loads(manifest.read_text())
        receipt["files"].append({
            "path": relative,
            "sha256": hashlib.sha256(personal.read_bytes()).hexdigest(),
        })
        manifest.write_text(json.dumps(receipt))
        result = self.invoke(retention=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("user data path", result.stderr)
        self.assertEqual(personal.read_text(), "personal")
        self.assertTrue(self.staging.exists())
        self.assertTrue(self.old.exists())

    def test_retention_preserves_new_release_if_retired_cleanup_is_refused(self):
        self.seed_retention()
        action = "Set-Content -LiteralPath " + ps_quote(self.old / "manual.txt") + " -Value personal"
        result = self.invoke(verify=action, retention=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Inspect the retired rollback", result.stdout)
        self.assertEqual((self.target / "windows/oculum.exe").read_text(), "three")
        self.assertEqual((self.backup / "windows/oculum.exe").read_text(), "two")
        self.assertTrue((self.old / "manual.txt").exists())
        self.assertEqual(json.loads(self.marker.read_text())["retired"]["backupName"], self.old.name)


if __name__ == "__main__":
    unittest.main()
