"""Exercise the shipped Windows updater only inside isolated build fixtures."""
import ctypes
from ctypes import wintypes
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "build"
COMPILER = Path(os.environ.get("WINDIR", "C:/Windows")) / "Microsoft.NET/Framework64/v4.0.30319/csc.exe"
COMMIT = "a" * 40
REQUIRED = ("WebView2Loader.dll", "data/app.so", "data/icudtl.dat", "data/flutter_assets/AssetManifest.bin")


@unittest.skipUnless(sys.platform == "win32" and COMPILER.exists(), "Windows .NET fixture compiler required")
class WindowsUpdateTests(unittest.TestCase):
    def compile_app(self, folder, name, edition, mode="ready"):
        token = 'System.Environment.GetEnvironmentVariable("OCULUM_UPDATE_ACK_TOKEN")'
        ack_json = '{"token":"TOKEN","commit":"' + ("b" * 40 if mode == "wrong-ack" else COMMIT) + '","edition":"' + edition + '"}'
        ack_literal = json.dumps(ack_json).replace("TOKEN", '" + token + "')
        ready = f'''
            string path = System.Environment.GetEnvironmentVariable("OCULUM_UPDATE_ACK_PATH");
            string token = {token};
            if (!System.String.IsNullOrEmpty(path)) {{
                System.IO.File.WriteAllText(path, {ack_literal});
                System.Threading.Thread.Sleep(1500);
            }}
        '''
        if mode == "crash":
            ready = ""
        if mode == "old":
            ready = '''
                if (System.IO.File.Exists("hold-open.flag")) {
                    System.IO.File.WriteAllText("held-instance-ready", "ready");
                    var deadline = System.DateTime.UtcNow.AddSeconds(60);
                    while (System.IO.File.Exists("hold-open.flag") && System.DateTime.UtcNow < deadline)
                        System.Threading.Thread.Sleep(50);
                }
            '''
        code = folder / ("app-" + mode + ".cs")
        code.write_text("public class FakeOculum { public static void Main() {" + ready + "} }")
        subprocess.run([str(COMPILER), "/nologo", "/target:winexe", f"/out:{folder/name}", str(code)], check=True, capture_output=True)

    def exercise(self, edition="normal", unsafe=False, missing=None, crash=False,
                 retry=False, held_instance=False, locked_dll=False, wrong_ack=False):
        BUILD.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="update-fixture-", dir=BUILD) as name:
            root = Path(name).resolve()
            self.assertEqual(root.parent, BUILD.resolve())
            target = root / "installed"; target.mkdir()
            work = root / "staged"; work.mkdir()
            source = root / "runtime"; source.mkdir()
            exe = "Oculum-Test.exe" if edition == "test" else "oculum.exe"
            self.compile_app(target, exe, edition, "old")
            self.compile_app(source, exe, edition, "crash" if crash else "wrong-ack" if wrong_ack else "ready")
            for relative in ("flutter_windows.dll", *REQUIRED):
                for directory, value in ((source, "new-runtime"), (target, "previous-runtime")):
                    file = directory / relative
                    file.parent.mkdir(parents=True, exist_ok=True)
                    file.write_text(value)
            (source / "data/approved-scene.png").write_bytes(b"new-approved-scene")
            (target / "data/old-scene.png").write_bytes(b"old-scene")
            sentinel = target / "user-save.json"; sentinel.write_text('{"keep":"all saves"}')
            if missing:
                (source / missing).unlink()
            inner = root / "platform.zip"
            archive = work / "release.zip"

            def make_archive():
                with zipfile.ZipFile(inner, "w") as z:
                    for file in source.rglob("*"):
                        if file.is_file() and file.suffix != ".cs":
                            z.write(file, file.relative_to(source).as_posix())
                with zipfile.ZipFile(archive, "w") as z:
                    if unsafe:
                        z.writestr("../escape.txt", "invalid")
                    else:
                        z.write(inner, "Oculum-Windows.zip")

            make_archive()
            # Legacy failed attempts must not poison the next extraction.
            (work / "unpacked").mkdir(); (work / "runtime").mkdir()
            config = work / "update.json"
            config.write_text(json.dumps(dict(work=str(work), archive=str(archive), executable=str(target/exe),
                                             pid=2147483646, edition=edition, commit=COMMIT,
                                             waitTimeoutSeconds=0 if held_instance else 2,
                                             startupTimeoutSeconds=1 if wrong_ack else 4)))
            process = None
            handle = None
            if held_instance:
                (target / "hold-open.flag").write_text("test fixture")
                process = subprocess.Popen([str(target/exe)], cwd=target, creationflags=subprocess.CREATE_NO_WINDOW)
                ready_deadline = time.monotonic() + 10
                while not (target / "held-instance-ready").exists() and time.monotonic() < ready_deadline:
                    self.assertIsNone(process.poll(), "Held fixture exited before signalling readiness")
                    time.sleep(0.05)
                self.assertTrue((target / "held-instance-ready").exists(), "Held fixture never signalled readiness")
            if locked_dll:
                create_file = ctypes.windll.kernel32.CreateFileW
                create_file.argtypes = (wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
                                        wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE)
                create_file.restype = wintypes.HANDLE
                handle = create_file(str(target/"flutter_windows.dll"), 0x80000000, 1, None, 3, 0x80, None)
                self.assertNotEqual(handle, wintypes.HANDLE(-1).value)

            def run_helper():
                return subprocess.run(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                                       str(ROOT/"assets/update/update.ps1"), str(config)],
                                      capture_output=True, text=True, timeout=30,
                                      creationflags=subprocess.CREATE_NO_WINDOW)

            try:
                result = run_helper()
                if process:
                    self.assertIsNone(process.poll(), "Updater must not terminate another Oculum instance")
            finally:
                if handle is not None:
                    close_handle = ctypes.windll.kernel32.CloseHandle
                    close_handle.argtypes = (wintypes.HANDLE,)
                    close_handle(handle)
                if process:
                    (target / "hold-open.flag").unlink(missing_ok=True)
                    process.wait(timeout=10)
                # Acknowledged fixtures exit themselves; never terminate an app.
                time.sleep(1.6)
            self.assertEqual(sentinel.read_text(), '{"keep":"all saves"}')
            status = json.loads((work/"update-status.json").read_text(encoding="utf-8-sig"))
            if unsafe or missing or crash or held_instance or locked_dll:
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual((target/"flutter_windows.dll").read_text(), "previous-runtime")
                self.assertEqual((target/"data/old-scene.png").read_bytes(), b"old-scene")
                self.assertFalse((root/"escape.txt").exists())
                self.assertFalse((work/"result.txt").exists())
                self.assertEqual(status["state"], "error")
                if held_instance:
                    self.assertIn("still open", (work/"error.txt").read_text())
            elif wrong_ack:
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(status["state"], "unconfirmed")
                self.assertFalse((work/"result.txt").exists())
                self.assertEqual((target/"flutter_windows.dll").read_text(), "new-runtime")
                self.assertEqual((Path(status["backup"])/"flutter_windows.dll").read_text(), "previous-runtime")
            else:
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual((target/"flutter_windows.dll").read_text(), "new-runtime")
                self.assertEqual((target/"data/approved-scene.png").read_bytes(), b"new-approved-scene")
                self.assertFalse((target/"data/old-scene.png").exists())
                self.assertEqual((Path(status["backup"])/"flutter_windows.dll").read_text(), "previous-runtime")
                self.assertEqual((work/"result.txt").read_text().strip(), "success")
                self.assertEqual(status["state"], "success")
            if retry:
                self.compile_app(source, exe, edition, "ready")
                make_archive()
                retried = run_helper()
                time.sleep(1.6)
                self.assertEqual(retried.returncode, 0, retried.stdout + retried.stderr)
                self.assertEqual((work/"result.txt").read_text().strip(), "success")
                self.assertEqual(len(list(work.glob("unpacked-*"))), 2)
                self.assertEqual(sentinel.read_text(), '{"keep":"all saves"}')

    def test_normal_replaces_entire_runtime_and_requires_startup_ack(self): self.exercise()
    def test_test_edition_keeps_its_executable_and_saves(self): self.exercise("test")
    def test_path_traversal_cannot_replace_runtime(self): self.exercise(unsafe=True)
    def test_incomplete_runtime_never_replaces_installed_files(self):
        for path in REQUIRED:
            with self.subTest(path=path): self.exercise(missing=path)
    def test_crashed_candidate_restores_old_runtime(self): self.exercise(crash=True)
    def test_retry_after_failed_startup_uses_fresh_extraction(self): self.exercise(crash=True, retry=True)
    def test_another_instance_prevents_replacement_without_being_killed(self): self.exercise(held_instance=True)
    def test_locked_dll_rolls_back_previously_moved_data_directory(self): self.exercise(locked_dll=True)
    def test_wrong_source_ack_is_not_success_and_running_candidate_is_left_open(self): self.exercise(wrong_ack=True)
