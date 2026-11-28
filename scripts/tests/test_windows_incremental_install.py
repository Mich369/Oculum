"""Exercise the shipped incremental installer with compiled local fixtures."""

import ctypes
from ctypes import wintypes
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
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

SOURCE_COMMIT = "b" * 40
COMMIT = windows_fixture.COMMIT
RUN_ID = 123
REQUIRED_RUNTIME = ("flutter_windows.dll", *windows_fixture.REQUIRED)
OLD_PLUGIN = "old-plugin.dll"
OLD_ASSET = "data/retired/old-managed.bin"
UPDATED_ASSET = "data/flutter_assets/updated.bin"
NEW_ASSET = "data/new/maps/approved-scene.webp"
LOCAL_NEIGHBOR = "data/retired/local-annotation.json"
PRIVATE_PATH = "data/profile/custom-sheets.json"
LOCAL_EXTENSION = "custom-plugin.dll"


def digest_bytes(data):
    return hashlib.sha256(data).hexdigest()


def quote_ps(value):
    return "'" + str(value).replace("'", "''") + "'"


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)


def file_identity(path):
    stats = path.stat()
    return (stats.st_dev, stats.st_ino, stats.st_mtime_ns)


class UpdateFixture:
    def __init__(self, test, root, edition="normal", *, no_op=False, crash=False,
                 shared_objects=False, wrong_ack=False):
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
            mode = "crash" if crash else "wrong-ack" if wrong_ack else "ready"
            windows_fixture.WindowsUpdateTests.compile_app(test, self.candidate, self.exe, edition, mode)
        managed = (self.exe, *REQUIRED_RUNTIME)
        for relative in REQUIRED_RUNTIME:
            write(self.target / relative, b"unchanged runtime")
            write(self.candidate / relative, b"unchanged runtime")
        if not no_op:
            write(self.target / OLD_PLUGIN, b"superseded original plugin")
            write(self.target / OLD_ASSET, b"superseded original asset")
            write(self.target / UPDATED_ASSET, b"original changed asset")
            write(self.candidate / UPDATED_ASSET, b"verified revised asset")
            write(self.candidate / NEW_ASSET, b"new verified asset")
        write(self.target / LOCAL_NEIGHBOR, b"local notes alongside retired asset")
        write(self.target / PRIVATE_PATH, b"player's private saved sheet")
        write(self.target / LOCAL_EXTENSION, b"private root extension")
        write(self.target / "user-save.json", b"player's save")
        prior_paths = managed if no_op else (*managed, UPDATED_ASSET, OLD_ASSET, OLD_PLUGIN)
        target_paths = managed if no_op else (*managed, UPDATED_ASSET, NEW_ASSET)
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
        self.test.assertEqual((self.target / LOCAL_NEIGHBOR).read_bytes(), b"local notes alongside retired asset")

    def assert_original_runtime(self):
        self.test.assertEqual(self.installed_exe.read_bytes(), self.old_exe)
        self.test.assertEqual((self.target / OLD_PLUGIN).read_bytes(), b"superseded original plugin")
        self.test.assertEqual((self.target / OLD_ASSET).read_bytes(), b"superseded original asset")
        self.test.assertEqual((self.target / UPDATED_ASSET).read_bytes(), b"original changed asset")
        self.test.assertFalse((self.target / "data/new").exists())


@unittest.skipUnless(sys.platform == "win32" and windows_fixture.COMPILER.exists(), "Windows .NET fixture compiler required")
class WindowsIncrementalTests(unittest.TestCase):
    def fixture(self, *args, **kwargs):
        temporary = tempfile.TemporaryDirectory(prefix="incremental-install-", dir=ROOT / "build")
        self.addCleanup(temporary.cleanup)
        return UpdateFixture(self, Path(temporary.name), *args, **kwargs)

    def test_zero_changes_do_not_replace_or_backup(self):
        fixture = self.fixture(no_op=True)
        executable_identity = file_identity(fixture.installed_exe)
        self.assertTrue(fixture.prepare()["isNoOp"])
        code, status, output = fixture.complete()
        self.assertEqual(code, 0, output)
        self.assertEqual(status["state"], "success")
        self.assertIsNone(status["candidatePid"])
        self.assertFalse(Path(status["backup"]).exists())
        self.assertEqual(fixture.installed_exe.read_bytes(), fixture.old_exe)
        self.assertEqual(file_identity(fixture.installed_exe), executable_identity)
        fixture.assert_local_data()

    def test_test_edition_replaces_verified_files_and_backs_up_only_managed_removals(self):
        fixture = self.fixture("test", shared_objects=True)
        preserved = (*REQUIRED_RUNTIME, PRIVATE_PATH, LOCAL_EXTENSION, LOCAL_NEIGHBOR, "user-save.json")
        identity_before = {path: file_identity(fixture.target / path) for path in preserved}
        data_directory_id = (fixture.target / "data").stat().st_ino
        external_link = fixture.work / "same-unchanged-dll.bin"
        os.link(fixture.target / "flutter_windows.dll", external_link)
        receipt = fixture.prepare()
        self.assertEqual(set(receipt["removedPaths"]), {OLD_ASSET, OLD_PLUGIN})
        self.assertEqual(set(receipt["changedPaths"]), {fixture.exe, UPDATED_ASSET, NEW_ASSET})
        staged = Path(receipt["runtime"])
        self.assertEqual({entry.relative_to(staged).as_posix() for entry in staged.rglob("*") if entry.is_file()},
                         set(receipt["changedPaths"]))
        code, status, output = fixture.complete()
        self.assertEqual(code, 0, output)
        self.assertEqual(status["state"], "success")
        self.assertEqual(fixture.installed_exe.read_bytes(), (fixture.candidate / fixture.exe).read_bytes())
        self.assertFalse((fixture.target / "oculum.exe").exists())
        self.assertFalse((fixture.target / OLD_PLUGIN).exists())
        self.assertFalse((fixture.target / OLD_ASSET).exists())
        backup = Path(status["backup"])
        self.assertEqual((backup / OLD_PLUGIN).read_bytes(), b"superseded original plugin")
        self.assertEqual((backup / OLD_ASSET).read_bytes(), b"superseded original asset")
        self.assertEqual((backup / UPDATED_ASSET).read_bytes(), b"original changed asset")
        self.assertEqual({entry.relative_to(backup).as_posix() for entry in backup.rglob("*") if entry.is_file()},
                         {OLD_ASSET, OLD_PLUGIN, UPDATED_ASSET, fixture.exe})
        self.assertEqual((fixture.target / NEW_ASSET).read_bytes(), b"new verified asset")
        self.assertEqual((fixture.target / UPDATED_ASSET).read_bytes(), b"verified revised asset")
        self.assertTrue(external_link.samefile(fixture.target / "flutter_windows.dll"))
        self.assertEqual((fixture.target / "data").stat().st_ino, data_directory_id)
        self.assertEqual({path: file_identity(fixture.target / path) for path in preserved}, identity_before)
        self.assertFalse((fixture.work / "objects").exists())
        self.assertTrue(list(fixture.objects.glob("*.bin")))
        fixture.assert_local_data()

    def test_candidate_crash_restores_root_removals_and_all_original_runtime(self):
        fixture = self.fixture(crash=True)
        originals = (fixture.exe, OLD_ASSET, OLD_PLUGIN, UPDATED_ASSET, *REQUIRED_RUNTIME, PRIVATE_PATH)
        originals_before = {path: file_identity(fixture.target / path) for path in originals}
        fixture.prepare()
        code, status, output = fixture.complete()
        self.assertNotEqual(code, 0, output)
        self.assertEqual(status["state"], "error")
        self.assertIn("closed before confirming", status["message"])
        self.assertFalse(list(fixture.target.glob(".oculum-update-staged-*")))
        self.assertEqual({path: file_identity(fixture.target / path) for path in originals}, originals_before)
        fixture.assert_original_runtime()
        fixture.assert_local_data()

    def test_locked_changed_file_rolls_back_prior_removals(self):
        fixture = self.fixture()
        fixture.prepare()
        before = {path: file_identity(fixture.target / path) for path in (OLD_PLUGIN, OLD_ASSET, UPDATED_ASSET)}
        create_file = ctypes.windll.kernel32.CreateFileW
        create_file.argtypes = (wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
                                wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE)
        create_file.restype = wintypes.HANDLE
        handle = create_file(str(fixture.target / UPDATED_ASSET), 0x80000000, 1, None, 3, 0x80, None)
        self.assertNotEqual(handle, ctypes.c_void_p(-1).value)
        try:
            code, status, output = fixture.complete()
        finally:
            ctypes.windll.kernel32.CloseHandle(wintypes.HANDLE(handle))
        self.assertNotEqual(code, 0, output)
        self.assertEqual(status["state"], "error")
        self.assertIn('"Replace"', status["message"])
        self.assertTrue(Path(status["backup"]).is_dir())
        self.assertFalse(any(entry.is_file() for entry in Path(status["backup"]).rglob("*")))
        self.assertEqual({path: file_identity(fixture.target / path) for path in before}, before)
        fixture.assert_original_runtime()
        fixture.assert_local_data()
        fixture.prepare()
        retry_code, retry_status, retry_output = fixture.complete()
        self.assertEqual(retry_code, 0, retry_output)
        self.assertEqual(retry_status["state"], "success")
        self.assertEqual((fixture.target / NEW_ASSET).read_bytes(), b"new verified asset")

    def test_refuses_nested_destination_junction(self):
        fixture = self.fixture()
        fixture.prepare()
        outside = fixture.work / "outside-installation"
        outside_asset = outside / "maps/approved-scene.webp"
        write(outside_asset, b"outside file belongs to the user")
        junction = fixture.target / "data/new"
        create = fixture.work / "create-junction.ps1"
        create.write_text(f"$ErrorActionPreference = 'Stop'\n"
                          f"New-Item -ItemType Junction -Path {quote_ps(junction)} -Target {quote_ps(outside)}",
                          encoding="utf-8-sig")
        linked = subprocess.run(fixture.command(create), capture_output=True, text=True, timeout=10)
        self.assertEqual(linked.returncode, 0, linked.stdout + linked.stderr)
        self.assertTrue(junction.lstat().st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT)
        try:
            code, status, output = fixture.complete()
            self.assertNotEqual(code, 0, output)
            self.assertIn("linked", status["message"].lower())
            self.assertFalse(Path(status["backup"]).exists())
            self.assertEqual(outside_asset.read_bytes(), b"outside file belongs to the user")
        finally:
            junction.rmdir()
        fixture.assert_original_runtime()
        fixture.assert_local_data()

    def test_refuses_directory_occupying_a_managed_file_path(self):
        fixture = self.fixture()
        fixture.prepare()
        collision = fixture.target / NEW_ASSET / "my-campaign.json"
        write(collision, b"personal data")
        code, status, output = fixture.complete()
        self.assertNotEqual(code, 0, output)
        self.assertIn("managed file path", status["message"].lower())
        self.assertFalse(Path(status["backup"]).exists())
        self.assertEqual(collision.read_bytes(), b"personal data")
        self.assertEqual(fixture.installed_exe.read_bytes(), fixture.old_exe)
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
            save_identity = file_identity(fixture.target / PRIVATE_PATH)
        finally:
            flag.unlink(missing_ok=True)
            original.wait(timeout=10)
        code, status, output = fixture.complete(process)
        self.assertEqual(code, 0, output)
        self.assertEqual(status["state"], "success")
        self.assertEqual(file_identity(fixture.target / PRIVATE_PATH), save_identity)
        self.assertFalse((Path(status["backup"]) / PRIVATE_PATH).exists())
        fixture.assert_local_data(b"save written while waiting for Oculum to close")

    def test_wrong_startup_ack_leaves_candidate_running_and_keeps_backup(self):
        fixture = self.fixture(wrong_ack=True)
        fixture.prepare()
        fixture.config["startupTimeoutSeconds"] = 1
        code, status, output = fixture.complete()
        self.assertNotEqual(code, 0, output)
        self.assertEqual(status["state"], "unconfirmed")
        self.assertTrue(status["candidatePid"])
        self.assertFalse((fixture.work / "result.txt").exists())
        self.assertEqual((Path(status["backup"]) / fixture.exe).read_bytes(), fixture.old_exe)
        self.assertEqual((fixture.target / NEW_ASSET).read_bytes(), b"new verified asset")
        fixture.assert_local_data()

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
