"""Exercise the incremental swap with compiled fixtures and no network requests."""

import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
import zipfile


HERE = Path(__file__).resolve().parent
ROOT = next(parent for parent in HERE.parents if (parent / "AGENTS.md").is_file())
sys.path.insert(0, str(ROOT / "scripts/tests"))
import test_windows_update as windows_fixture
del sys.path[0]

CORE = ROOT / "assets/update/oculum_incremental_windows.ps1"
INSTALLER = ROOT / "assets/update/update.ps1"
if not INSTALLER.is_file():
    INSTALLER = ROOT / "assets/update/update.ps1"

SOURCE_COMMIT = "b" * 40
COMMIT = windows_fixture.COMMIT
RUN_ID = 123
REQUIRED_RUNTIME = ("flutter_windows.dll", *windows_fixture.REQUIRED)
OLD_PLUGIN = "old-plugin.dll"
OLD_ASSET = "data/old-managed.bin"
PRIVATE_PATH = "data/profile/custom-sheets.json"
LOCAL_EXTENSION = "custom-plugin.dll"


def digest_bytes(data):
    return hashlib.sha256(data).hexdigest()


def quote_ps(value):
    return "'" + str(value).replace("'", "''") + "'"


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)


class UpdateFixture:
    def __init__(self, test, root, edition="normal", *, no_op=False, crash=False, shared_objects=False):
        self.test = test
        self.work = root / "cache"
        self.target = root / "installed"
        self.candidate = root / "candidate"
        self.work.mkdir()
        self.target.mkdir()
        self.candidate.mkdir()
        self.edition = edition
        self.exe = "Oculum-Test.exe" if edition == "test" else "oculum.exe"
        self.installed_exe = self.target / self.exe
        windows_fixture.WindowsUpdateTests.compile_app(test, self.target, self.exe, edition, "old")
        self.old_exe = self.installed_exe.read_bytes()
        if no_op:
            shutil.copyfile(self.installed_exe, self.candidate / self.exe)
        else:
            mode = "crash" if crash else "ready"
            windows_fixture.WindowsUpdateTests.compile_app(test, self.candidate, self.exe, edition, mode)
        managed = (self.exe, *REQUIRED_RUNTIME)
        for relative in REQUIRED_RUNTIME:
            write(self.target / relative, b"unchanged runtime")
            write(self.candidate / relative, b"unchanged runtime")
        if not no_op:
            write(self.target / OLD_PLUGIN, b"superseded original plugin")
            write(self.target / OLD_ASSET, b"superseded original asset")
            write(self.candidate / "data/approved-scene.webp", b"new verified asset")
        write(self.target / PRIVATE_PATH, b"player's private saved sheet")
        write(self.target / LOCAL_EXTENSION, b"private root extension")
        write(self.target / "user-save.json", b"player's save")
        prior_paths = managed if no_op else (*managed, OLD_ASSET, OLD_PLUGIN)
        target_paths = managed if no_op else (*managed, "data/approved-scene.webp")
        self.source_manifest = self.work / "incremental-source.json"
        self.target_manifest = self.work / "incremental-target.json"
        self.package, self.target_hash = self.manifest(
            self.candidate, target_paths, RUN_ID, COMMIT, self.target_manifest
        )
        _, self.source_hash = self.manifest(
            self.target, prior_paths, RUN_ID - 1, SOURCE_COMMIT, self.source_manifest
        )
        self.objects = root / ("oculum-update-objects-" + "a" * 64) if shared_objects else self.work / "objects"
        for path in target_paths:
            content = (self.candidate / path).read_bytes()
            write(self.objects / f"{digest_bytes(content)}.bin", content)
        self.core = self.work / "oculum_incremental_windows.ps1"
        shutil.copyfile(CORE, self.core)
        self.receipt = self.work / "incremental-stage.json"
        self.config_path = self.work / "update.json"

    def manifest(self, tree, paths, run_id, commit, destination):
        package_prefix = "Oculum-Test-Windows" if self.edition == "test" else "Oculum-Windows"
        offset = 1
        records = []
        for relative in paths:
            data = (tree / relative).read_bytes()
            records.append({
                "path": relative, "sha256": digest_bytes(data), "bytes": len(data),
                "offset": offset, "compressedBytes": len(data), "method": 0,
            })
            offset += len(data)
        package = {
            "url": f"https://github.com/Mich369/Oculum/releases/download/oculum-build-{run_id}/{package_prefix}-Folder.zip",
            "sha256": "1" * 64, "bytes": offset + 1,
        }
        content = json.dumps({
            "schemaVersion": 1, "platform": "windows", "edition": self.edition,
            "commit": commit, "runId": run_id, "package": package, "files": records,
        }).encode()
        destination.write_bytes(content)
        return package, digest_bytes(content)

    def prepare(self):
        prepare = self.work / "prepare-fixture.ps1"
        cached = self.objects.parent != self.work
        option = f"-CachedObjectsRoot {quote_ps(self.objects)}" if cached else ""
        prepare.write_text(f"""
$ErrorActionPreference = 'Stop'
. {quote_ps(self.core)}
$plan = Get-OculumIncrementalPlan -InstalledRoot {quote_ps(self.target)} `
  -WorkRoot {quote_ps(self.work)} -Edition {quote_ps(self.edition)} `
  -TargetManifestPath {quote_ps(self.target_manifest)} -TargetManifestSha256 {self.target_hash} `
  -SourceManifestPath {quote_ps(self.source_manifest)} -SourceManifestSha256 {self.source_hash} {option}
$stage = New-OculumIncrementalStage -Plan $plan -ReadRange {{ throw 'Fixture must never access the network' }}
[ordered]@{{
    schemaVersion = 1; commit = '{COMMIT}'; edition = '{self.edition}'; runId = {RUN_ID}
    manifestSha256 = '{self.target_hash}'; sourceManifestSha256 = '{self.source_hash}'
    isNoOp = $stage.IsNoOp; changedPaths = @($plan.ChangedPaths)
    removedPaths = @($plan.Removed | ForEach-Object path); runtime = $stage.RuntimeRoot
}} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath {quote_ps(self.receipt)} -Encoding UTF8
""", encoding="ascii")
        prepared = subprocess.run(self.command(prepare), capture_output=True, text=True, timeout=45)
        self.test.assertEqual(prepared.returncode, 0, prepared.stdout + prepared.stderr)
        receipt = self.read_json(self.receipt)
        self.config = {
            "work": str(self.work), "executable": str(self.installed_exe),
            "pid": 2147483646, "platform": "windows", "commit": COMMIT,
            "edition": self.edition, "waitTimeoutSeconds": 10, "startupTimeoutSeconds": 4,
            "incrementalManifest": str(self.target_manifest), "incrementalManifestSha256": self.target_hash,
            "incrementalSourceManifest": str(self.source_manifest), "incrementalSourceManifestSha256": self.source_hash,
            "incrementalSourceCommit": SOURCE_COMMIT, "incrementalRuntime": receipt["runtime"],
            "incrementalPlan": str(self.receipt), "incrementalHelper": str(self.core),
            "incrementalHelperSha256": digest_bytes(self.core.read_bytes()), "incrementalRunId": RUN_ID,
            "incrementalPackageUrl": self.package["url"], "incrementalPackageBytes": self.package["bytes"],
            "incrementalPackageSha256": self.package["sha256"],
        }
        if cached:
            self.config["incrementalCachedObjectsRoot"] = str(self.objects)
        return receipt

    def run(self):
        self.config_path.write_text(json.dumps(self.config), encoding="utf-8")
        return subprocess.Popen(self.command(INSTALLER, self.config_path), text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                creationflags=subprocess.CREATE_NO_WINDOW)

    def complete(self, process=None):
        process = process or self.run()
        with process:
            output, _ = process.communicate(timeout=45)
        status = self.read_json(self.work / "update-status.json")
        if status["state"] in ("success", "unconfirmed") and status["candidatePid"]:
            # The compiled fixture quits itself shortly after writing the ack.
            time.sleep(1.6)
        return process.returncode, status, output

    @staticmethod
    def command(script, *args):
        return ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(script), *map(str, args)]

    @staticmethod
    def read_json(path):
        return json.loads(path.read_text(encoding="utf-8-sig"))

    def assert_local_data(self, private=b"player's private saved sheet"):
        self.test.assertEqual((self.target / PRIVATE_PATH).read_bytes(), private)
        self.test.assertEqual((self.target / LOCAL_EXTENSION).read_bytes(), b"private root extension")
        self.test.assertEqual((self.target / "user-save.json").read_bytes(), b"player's save")

    def assert_original_runtime(self):
        self.test.assertEqual(self.installed_exe.read_bytes(), self.old_exe)
        self.test.assertEqual((self.target / OLD_PLUGIN).read_bytes(), b"superseded original plugin")
        self.test.assertEqual((self.target / OLD_ASSET).read_bytes(), b"superseded original asset")
        self.test.assertFalse((self.target / "data/approved-scene.webp").exists())


@unittest.skipUnless(sys.platform == "win32" and windows_fixture.COMPILER.exists(), "Windows .NET fixture compiler required")
class WindowsIncrementalTests(unittest.TestCase):
    def fixture(self, *args, **kwargs):
        temporary = tempfile.TemporaryDirectory(prefix="incremental-install-", dir=ROOT / "build")
        self.addCleanup(temporary.cleanup)
        return UpdateFixture(self, Path(temporary.name), *args, **kwargs)

    def test_zero_changes_do_not_replace_or_backup(self):
        fixture = self.fixture(no_op=True)
        self.assertTrue(fixture.prepare()["isNoOp"])
        code, status, output = fixture.complete()
        self.assertEqual(code, 0, output)
        self.assertEqual(status["state"], "success")
        self.assertIsNone(status["candidatePid"])
        self.assertFalse(Path(status["backup"]).exists())
        self.assertEqual(fixture.installed_exe.read_bytes(), fixture.old_exe)
        fixture.assert_local_data()

    def test_test_edition_replaces_verified_files_and_backs_up_only_managed_removals(self):
        fixture = self.fixture("test", shared_objects=True)
        receipt = fixture.prepare()
        self.assertEqual(set(receipt["removedPaths"]), {OLD_ASSET, OLD_PLUGIN})
        code, status, output = fixture.complete()
        self.assertEqual(code, 0, output)
        self.assertEqual(status["state"], "success")
        self.assertEqual(fixture.installed_exe.read_bytes(), (fixture.candidate / fixture.exe).read_bytes())
        self.assertFalse((fixture.target / "oculum.exe").exists())
        self.assertFalse((fixture.target / OLD_PLUGIN).exists())
        self.assertFalse((fixture.target / OLD_ASSET).exists())
        self.assertEqual((Path(status["backup"]) / OLD_PLUGIN).read_bytes(), b"superseded original plugin")
        self.assertEqual((fixture.target / "data/approved-scene.webp").read_bytes(), b"new verified asset")
        self.assertFalse((fixture.work / "objects").exists())
        self.assertTrue(list(fixture.objects.glob("*.bin")))
        fixture.assert_local_data()

    def test_candidate_crash_restores_root_removals_and_all_original_runtime(self):
        fixture = self.fixture(crash=True)
        fixture.prepare()
        code, status, output = fixture.complete()
        self.assertNotEqual(code, 0, output)
        self.assertEqual(status["state"], "error")
        self.assertIn("closed before confirming", status["message"])
        self.assertFalse(list(fixture.target.glob(".oculum-update-staged-*")))
        fixture.assert_original_runtime()
        fixture.assert_local_data()

    def test_private_data_changed_while_waiting_is_never_replaced(self):
        fixture = self.fixture()
        fixture.prepare()
        flag = fixture.target / "hold-open.flag"
        flag.touch()
        original = subprocess.Popen([str(fixture.installed_exe)], cwd=fixture.target,
                                    creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            deadline = time.monotonic() + 8
            while not (fixture.target / "held-instance-ready").exists() and time.monotonic() < deadline:
                time.sleep(0.05)
            self.assertTrue((fixture.target / "held-instance-ready").exists())
            process = fixture.run()
            status_path = fixture.work / "update-status.json"
            deadline = time.monotonic() + 8
            while time.monotonic() < deadline:
                try:
                    if fixture.read_json(status_path)["state"] == "waiting":
                        break
                except (OSError, json.JSONDecodeError):
                    pass
                time.sleep(0.05)
            else:
                self.fail("the helper never waited for the original process")
            write(fixture.target / PRIVATE_PATH, b"save written while waiting for Oculum to close")
        finally:
            flag.unlink(missing_ok=True)
            original.wait(timeout=10)
        code, status, output = fixture.complete(process)
        self.assertNotEqual(code, 0, output)
        self.assertIn("Local data changed after staging", status["message"])
        self.assertFalse(Path(status["backup"]).exists())
        fixture.assert_original_runtime()
        fixture.assert_local_data(b"save written while waiting for Oculum to close")

    def test_helper_digest_is_rechecked_before_loading_staged_code(self):
        fixture = self.fixture()
        fixture.prepare()
        fixture.core.write_text("throw 'This unverified staged script must not run'", encoding="ascii")
        code, status, output = fixture.complete()
        self.assertNotEqual(code, 0, output)
        self.assertIn("Incremental helper SHA-256 verification failed", status["message"])
        fixture.assert_original_runtime()
        fixture.assert_local_data()

    def test_normal_and_test_must_not_share_a_runtime(self):
        fixture = self.fixture("test")
        fixture.prepare()
        shutil.copyfile(fixture.installed_exe, fixture.target / "oculum.exe")
        code, status, output = fixture.complete()
        self.assertNotEqual(code, 0, output)
        self.assertIn("separate runtime folders", status["message"])
        self.assertFalse(Path(status["backup"]).exists())
        fixture.assert_original_runtime()
        fixture.assert_local_data()

    def test_source_manifest_must_match_the_approved_source_commit(self):
        fixture = self.fixture()
        fixture.prepare()
        fixture.config["incrementalSourceCommit"] = "c" * 40
        code, status, output = fixture.complete()
        self.assertNotEqual(code, 0, output)
        self.assertIn("does not match the approved package", status["message"])
        self.assertFalse(Path(status["backup"]).exists())
        fixture.assert_original_runtime()
        fixture.assert_local_data()

    def test_existing_full_zip_path_can_still_install(self):
        fixture = self.fixture()
        archive = fixture.work / "release.zip"
        with zipfile.ZipFile(archive, "w") as package:
            for path in fixture.candidate.rglob("*"):
                if path.is_file() and path.suffix != ".cs":
                    package.write(path, path.relative_to(fixture.candidate).as_posix())
        fixture.config = {
            "work": str(fixture.work), "archive": str(archive), "executable": str(fixture.installed_exe),
            "pid": 2147483646, "edition": fixture.edition, "commit": COMMIT,
            "waitTimeoutSeconds": 3, "startupTimeoutSeconds": 4,
        }
        code, status, output = fixture.complete()
        self.assertEqual(code, 0, output)
        self.assertEqual(status["state"], "success")
        self.assertEqual(fixture.installed_exe.read_bytes(), (fixture.candidate / fixture.exe).read_bytes())
        self.assertFalse(archive.exists())
        self.assertEqual((fixture.target / "user-save.json").read_bytes(), b"player's save")


if __name__ == "__main__":
    unittest.main()
