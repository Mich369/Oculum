"""Exercise distribution renames only in isolated children of build/."""

import ctypes
from ctypes import wintypes
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "build"
HELPER = ROOT / "scripts/oculum_distribution_swap.ps1"


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

    def invoke(self, before="", verify=""):
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
        return subprocess.run(
            ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command", command],
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


if __name__ == "__main__":
    unittest.main()
