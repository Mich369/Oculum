"""Exercise the shipped Windows updater only inside isolated build fixtures."""
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

@unittest.skipUnless(sys.platform == "win32" and COMPILER.exists(), "Windows .NET fixture compiler required")
class WindowsUpdateTests(unittest.TestCase):
    def exercise(self, edition, unsafe=False):
        BUILD.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="update-fixture-",dir=BUILD) as name:
            root=Path(name).resolve()
            self.assertEqual(root.parent,BUILD.resolve())
            target=root/"installed";target.mkdir()
            work=root/"staged";work.mkdir()
            source=root/"runtime";source.mkdir()
            exe="Oculum-Test.exe" if edition=="test" else "oculum.exe"
            code=root/"app.cs"
            code.write_text("public class FakeOculum {public static void Main() {}}")
            subprocess.run([str(COMPILER),"/nologo","/target:exe",f"/out:{source/exe}",str(code)],check=True,capture_output=True)
            shutil.copy2(source/exe,target/exe)
            (source/"flutter_windows.dll").write_text("new-runtime")
            (target/"flutter_windows.dll").write_text("previous-runtime")
            (source/"data").mkdir();(source/"data/assets.txt").write_text("new-assets")
            (target/"data").mkdir();(target/"data/assets.txt").write_text("previous-assets")
            sentinel=target/"user-save.json";sentinel.write_text('{"keep":"all saves"}')
            inner=root/"platform.zip"
            with zipfile.ZipFile(inner,"w") as z:
                for file in source.rglob("*"):
                    if file.is_file(): z.write(file,file.relative_to(source).as_posix())
            archive=work/"release.zip"
            with zipfile.ZipFile(archive,"w") as z:
                if unsafe: z.writestr("../escape.txt","invalid")
                else: z.write(inner,"Oculum-Windows.zip")
            config=work/"update.json"
            config.write_text(json.dumps(dict(work=str(work),archive=str(archive),executable=str(target/exe),pid=2147483646,edition=edition)))
            result=subprocess.run(["powershell.exe","-NoProfile","-ExecutionPolicy","Bypass","-File",str(ROOT/"assets/update/update.ps1"),str(config)],capture_output=True,text=True,timeout=30)
            time.sleep(1)  # Let the tiny restarted fixture release its executable.
            self.assertEqual(sentinel.read_text(),'{"keep":"all saves"}')
            if unsafe:
                self.assertNotEqual(result.returncode,0)
                self.assertEqual((target/"flutter_windows.dll").read_text(),"previous-runtime")
                self.assertFalse((root/"escape.txt").exists())
            else:
                self.assertEqual(result.returncode,0,result.stdout+result.stderr)
                self.assertEqual((target/"flutter_windows.dll").read_text(),"new-runtime")
                self.assertEqual((target/"data/assets.txt").read_text(),"new-assets")
                self.assertEqual((work/"previous-runtime/flutter_windows.dll").read_text(),"previous-runtime")
                self.assertEqual((work/"result.txt").read_text().strip(),"success")
    def test_normal_replaces_runtime_and_preserves_saves(self): self.exercise("normal")
    def test_test_edition_keeps_its_executable_and_saves(self): self.exercise("test")
    def test_path_traversal_cannot_replace_runtime(self): self.exercise("normal",unsafe=True)
