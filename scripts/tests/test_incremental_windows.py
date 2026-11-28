"""Verify the Windows byte-range planner and staging without contacting GitHub."""

import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "build"
HELPER = ROOT / "assets/update/oculum_incremental_windows.ps1"
RUNTIME = {
    "oculum.exe": b"application",
    "flutter_windows.dll": b"flutter",
    "WebView2Loader.dll": b"loader",
    "native_assets.json": b"{\"native-assets\":{}}",
    "data/app.so": b"old compiled code",
    "data/icudtl.dat": b"locale data",
    "data/flutter_assets/AssetManifest.bin": b"asset manifest",
}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def quote(string):
    return "'" + str(string).replace("'", "''") + "'"


@unittest.skipUnless(sys.platform == "win32", "Windows and PowerShell required")
class IncrementalWindowsTests(unittest.TestCase):
    def setUp(self):
        BUILD.mkdir(exist_ok=True)
        self.folder = tempfile.TemporaryDirectory(
            prefix="incremental-windows-fixture-", dir=BUILD
        )
        self.root = Path(self.folder.name).resolve()
        self.assertEqual(self.root.parent, BUILD.resolve())
        self.addCleanup(self.folder.cleanup)
        self.work = self.root / "work"
        self.work.mkdir()
        self.installed = self.root / "installed"
        self.installed.mkdir()
        self.write_files(self.installed, RUNTIME)

    def write_files(self, root, files):
        for relative, data in files.items():
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)

    def create_manifest(self, run, files, edition="normal"):
        archive = self.root / f"package-{run}.zip"
        with zipfile.ZipFile(archive, "w") as zip_file:
            for relative, data in files.items():
                method = zipfile.ZIP_STORED if not data or relative.endswith(".dat") else zipfile.ZIP_DEFLATED
                zip_file.writestr(relative, data, compress_type=method)
        raw = archive.read_bytes()
        rows = []
        with zipfile.ZipFile(archive) as zip_file:
            for item in zip_file.infolist():
                name_length, extra_length = struct.unpack_from("<HH", raw, item.header_offset + 26)
                rows.append(dict(
                    path=item.filename,
                    bytes=item.file_size,
                    sha256=digest(files[item.filename]),
                    offset=item.header_offset + 30 + name_length + extra_length,
                    compressedBytes=item.compress_size,
                    method=item.compress_type,
                ))
        suffix = "Oculum-Test" if edition == "test" else "Oculum"
        manifest = dict(
            schemaVersion=1,
            platform="windows",
            edition=edition,
            commit=f"{run:040x}",
            runId=run,
            package=dict(
                url=f"https://github.com/Mich369/Oculum/releases/download/oculum-build-{run}/{suffix}-Windows-Folder.zip",
                bytes=len(raw),
                sha256=digest(raw),
            ),
            files=rows,
        )
        path = self.root / f"manifest-{run}.json"
        self.write_manifest(path, manifest)
        return path, archive, manifest

    def write_manifest(self, path, value):
        path.write_text(json.dumps(value), encoding="utf-8")

    def invoke(self, target, body, source=None, expected=None, edition="normal", cached_objects=None):
        path, archive, _ = target
        command = (
            "$ErrorActionPreference='Stop'; . " + quote(HELPER) + "; "
            "$zipPath = " + quote(archive) + "; "
            "$plan = Get-OculumIncrementalPlan -InstalledRoot " + quote(self.installed) +
            " -WorkRoot " + quote(self.work) + " -Edition " + quote(edition) + " -TargetManifestPath " +
            quote(path) + " -TargetManifestSha256 " + quote(expected or digest(path.read_bytes()))
        )
        if source:
            command += (
                " -SourceManifestPath " + quote(source[0]) +
                " -SourceManifestSha256 " + quote(digest(source[0].read_bytes()))
            )
        if cached_objects:
            command += " -CachedObjectsRoot " + quote(cached_objects)
        command += "; " + body
        return subprocess.run(
            ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
             "-Command", command],
            capture_output=True, text=True, timeout=45,
        )

    stage = """
        $fetch = {
          param($package, $file, $destination)
          $bytes = [IO.File]::ReadAllBytes($zipPath)
          $range = [byte[]]::new($file.compressedBytes)
          [Array]::Copy($bytes, $file.offset, $range, 0, $file.compressedBytes)
          [IO.File]::WriteAllBytes($destination, $range)
        }
        $stage = New-OculumIncrementalStage -Plan $plan -ReadRange $fetch
        $stage | Add-Member -NotePropertyName count -NotePropertyValue $plan.DownloadCount
        $stage | Add-Member -NotePropertyName bytes -NotePropertyValue $plan.DownloadBytes
        $stage | Add-Member -NotePropertyName remove -NotePropertyValue $plan.RemoveCount
        $stage | ConvertTo-Json -Compress
    """

    def test_skips_versions_reuses_bytes_and_preserves_local_data(self):
        old_files = RUNTIME | {
            "unused.dll": b"old plugin",
            "data/obsolete.dat": b"old catalog",
            "data/customized.dat": b"original",
        }
        self.write_files(self.installed, old_files | {
            "data/customized.dat": b"user-modified",
            "data/saves/my-save.json": b"local saves",
            "notes.txt": b"local notes",
        })
        (self.installed / "data/empty-folder").mkdir()
        content = b"new compiled code " * 300
        current = RUNTIME | {
            "data/app.so": content,
            "data/same-code.dat": content,
            "data/new-locale.dat": b"new locale",
            "data/empty.dat": b"",
        }
        old = self.create_manifest(6, old_files)
        target = self.create_manifest(501, current)
        result = self.invoke(target, self.stage, source=old)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        report = json.loads(result.stdout)
        downloaded = [
            row for row in target[2]["files"]
            if row["path"] in ("data/app.so", "data/new-locale.dat")
        ]
        self.assertEqual(report["count"], 2)
        self.assertEqual(report["bytes"], sum(row["compressedBytes"] for row in downloaded))
        self.assertEqual(report["remove"], 2)
        self.assertEqual(report["RemoveRootEntries"], ["unused.dll"])
        staged = Path(report["RuntimeRoot"])
        changed = {relative for relative, data in current.items() if RUNTIME.get(relative) != data}
        self.assertEqual({file.relative_to(staged).as_posix() for file in staged.rglob("*") if file.is_file()}, changed)
        for relative in changed:
            self.assertEqual((staged / relative).read_bytes(), current[relative])
        self.assertEqual((self.installed / "data/customized.dat").read_bytes(), b"user-modified")
        self.assertEqual((self.installed / "data/saves/my-save.json").read_bytes(), b"local saves")
        self.assertTrue((self.installed / "data/empty-folder").is_dir())
        self.assertEqual((self.installed / "notes.txt").read_bytes(), b"local notes")
        self.assertEqual((self.installed / "unused.dll").read_bytes(), b"old plugin")
        self.assertEqual((self.installed / "data/obsolete.dat").read_bytes(), b"old catalog")

    def test_no_difference_does_not_create_a_cache_or_stage(self):
        target = self.create_manifest(10, RUNTIME)
        result = self.invoke(target, self.stage)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        report = json.loads(result.stdout)
        self.assertEqual(report["count"], 0)
        self.assertEqual(report["bytes"], 0)
        self.assertTrue(report["IsNoOp"])
        self.assertIsNone(report["RuntimeRoot"])
        self.assertEqual(list(self.work.iterdir()), [])

    def test_removal_only_prepares_an_empty_stage_and_needs_no_cache(self):
        original = RUNTIME | {"legacy.dll": b"old release file", "data/legacy.dat": b"old data"}
        self.write_files(self.installed, original)
        source = self.create_manifest(10, original)
        target = self.create_manifest(11, RUNTIME)
        result = self.invoke(target, self.stage, source=source)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        report = json.loads(result.stdout)
        self.assertEqual((report["count"], report["bytes"], report["remove"]), (0, 0, 2))
        self.assertFalse(report["IsNoOp"])
        staged = Path(report["RuntimeRoot"])
        self.assertTrue(staged.is_dir())
        self.assertEqual(list(staged.iterdir()), [])
        self.assertEqual(list(self.work.iterdir()), [staged])
        self.assertEqual((self.installed / "data/legacy.dat").read_bytes(), b"old data")

    def test_refuses_bad_manifest_content_before_writes(self):
        target = self.create_manifest(27, RUNTIME | {"data/change.dat": b"new"})
        path, _, raw = target
        for case in ("digest", "traversal", "case alias", "device", "ads", "protected",
                     "other edition", "overlap", "out of bounds", "another host"):
            with self.subTest(case=case):
                manifest = json.loads(json.dumps(raw))
                row = manifest["files"][-1]
                if case == "traversal":
                    row["path"] = "data/../outside.dat"
                elif case == "case alias":
                    row["path"] = "data/APP.SO"
                elif case == "device":
                    row["path"] = "data/con.bin"
                elif case == "ads":
                    row["path"] = "data/main.dat:another"
                elif case == "protected":
                    row["path"] = "data/saves/all.dat"
                elif case == "other edition":
                    manifest["edition"] = "test"
                elif case == "overlap":
                    row["offset"] = manifest["files"][0]["offset"]
                elif case == "out of bounds":
                    row["offset"] = manifest["package"]["bytes"] - 1
                elif case == "another host":
                    manifest["package"]["url"] = manifest["package"]["url"].replace("github.com", "github.com.example")
                self.write_manifest(path, manifest)
                result = self.invoke(target, self.stage, expected="0" * 64 if case == "digest" else None)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertEqual(list(self.work.iterdir()), [])
                self.assertEqual((self.installed / "data/app.so").read_bytes(), RUNTIME["data/app.so"])

    def test_corrupt_download_leaves_install_intact_and_verified_cache_restarts(self):
        current = RUNTIME | {"data/app.so": b"new app", "data/addition.dat": b"new addition"}
        target = self.create_manifest(76, current)
        cached_content = current["data/app.so"]
        self.write_files(self.work, {f"objects/{digest(cached_content)}.bin": cached_content})
        bad = self.invoke(target, """
            $fetch = {
              param($package, $file, $destination)
              [IO.File]::WriteAllBytes($destination, [byte[]]::new($file.compressedBytes))
            }
            New-OculumIncrementalStage -Plan $plan -ReadRange $fetch
        """)
        self.assertNotEqual(bad.returncode, 0, bad.stdout)
        self.assertIn("SHA-256", bad.stderr)
        self.assertEqual((self.installed / "data/app.so").read_bytes(), RUNTIME["data/app.so"])
        self.assertEqual([path.name for path in (self.work / "objects").glob("*.bin")], [f"{digest(cached_content)}.bin"])
        self.assertFalse(list((self.work / "objects").glob("*.partial")))
        self.assertFalse(list((self.work / "objects").glob("*.range")))
        recovered = self.invoke(target, self.stage)
        self.assertEqual(recovered.returncode, 0, recovered.stderr + recovered.stdout)
        report = json.loads(recovered.stdout)
        self.assertEqual(report["count"], 1)
        self.assertEqual(report["bytes"], len(current["data/addition.dat"]))
        self.assertEqual((Path(report["RuntimeRoot"]) / "data/app.so").read_bytes(), cached_content)

    def test_interruption_retries_only_the_object_that_did_not_finish(self):
        current = RUNTIME | {"data/first.dat": b"new", "data/second.dat": b"second addition"}
        target = self.create_manifest(77, current)
        body = """
            $fetch = {
                param($package, $file, $destination)
                $raw = [IO.File]::ReadAllBytes($zipPath)
                $range = [byte[]]::new($file.compressedBytes)
                [Array]::Copy($raw, $file.offset, $range, 0, $file.compressedBytes)
                [IO.File]::WriteAllBytes($destination, $range)
                if ($file.path -eq 'data/second.dat') { throw 'Simulated interrupted request' }
            }
            New-OculumIncrementalStage -Plan $plan -ReadRange $fetch
        """
        failed = self.invoke(target, body)
        self.assertNotEqual(failed.returncode, 0, failed.stdout)
        self.assertIn("Simulated interrupted request", failed.stderr)
        self.assertEqual(len(list((self.work / "objects").glob("*.bin"))), 1)
        self.assertFalse((self.installed / "data/first.dat").exists())
        retry = self.invoke(target, self.stage)
        self.assertEqual(retry.returncode, 0, retry.stderr + retry.stdout)
        report = json.loads(retry.stdout)
        self.assertEqual(report["count"], 1)
        self.assertEqual(report["bytes"], len(current["data/second.dat"]))
        self.assertEqual((Path(report["RuntimeRoot"]) / "data/first.dat").read_bytes(), b"new")

    def test_shared_cache_reuses_verified_objects_across_separate_attempts(self):
        content = b"resume candidate"
        target = self.create_manifest(83, RUNTIME | {"data/addition.dat": content})
        cache = self.root / ("oculum-update-objects-" + "a" * 64)
        result = self.invoke(target, self.stage, cached_objects=cache)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        first = json.loads(result.stdout)
        self.assertEqual((first["DownloadCount"], first["DownloadBytes"]), (1, len(content)))
        self.assertEqual((cache / f"{digest(content)}.bin").read_bytes(), content)
        self.assertFalse((self.work / "objects").exists())

        self.work = self.root / "new-attempt"
        self.work.mkdir()
        result = self.invoke(target, """
            $stage = New-OculumIncrementalStage -Plan $plan -ReadRange { throw 'Unexpected re-download' }
            $stage | ConvertTo-Json -Compress
        """, cached_objects=cache)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        second = json.loads(result.stdout)
        self.assertEqual((second["DownloadCount"], second["DownloadBytes"]), (0, 0))
        self.assertNotEqual(first["RuntimeRoot"], second["RuntimeRoot"])
        self.assertEqual((Path(second["RuntimeRoot"]) / "data/addition.dat").read_bytes(), content)

    def test_cache_hits_after_the_plan_reduce_actual_download_and_share_a_lock(self):
        content = b"verified bytes"
        target = self.create_manifest(87, RUNTIME | {"data/read.dat": content})
        cache = self.root / ("oculum-update-objects-" + "b" * 64)
        body = f"""
            if ($plan.DownloadCount -ne 1) {{ throw 'Expected an uncached object' }}
            [void][IO.Directory]::CreateDirectory($plan.ObjectsRoot)
            [IO.File]::WriteAllText((Join-Path $plan.ObjectsRoot '{digest(content)}.bin'), '{content.decode()}')
            $lock = [IO.File]::Open((Join-Path $plan.ObjectsRoot 'incremental.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
            try {{
              $refused = $false
              try {{ New-OculumIncrementalStage -Plan $plan }} catch [IO.IOException] {{ $refused = $true }}
              if (!$refused) {{ throw 'The shared cache permitted a second writer' }}
            }} finally {{ $lock.Dispose() }}
            $stage = New-OculumIncrementalStage -Plan $plan -ReadRange {{ throw 'Unexpected re-download' }}
            $stage | ConvertTo-Json -Compress
        """
        result = self.invoke(target, body, cached_objects=cache)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        report = json.loads(result.stdout)
        self.assertEqual((report["DownloadCount"], report["DownloadBytes"]), (0, 0))
        self.assertEqual((Path(report["RuntimeRoot"]) / "data/read.dat").read_bytes(), content)

    def test_only_the_named_cache_sibling_is_allowed(self):
        target = self.create_manifest(89, RUNTIME | {"data/new.dat": b"new"})
        wrong = self.work / ("oculum-update-objects-" + "c" * 64)
        result = self.invoke(target, self.stage, cached_objects=wrong)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("separate Oculum folder beside", result.stderr)
        self.assertFalse(wrong.exists())

    def test_test_edition_can_validate_copy_on_installed_volume(self):
        test_files = {key: value for key, value in RUNTIME.items() if key != "oculum.exe"}
        test_files["Oculum-Test.exe"] = b"test application"
        (self.installed / "oculum.exe").unlink()
        self.write_files(self.installed, test_files)
        changed = test_files | {"data/app.so": b"new test code"}
        target = self.create_manifest(40_330_467_933, changed, edition="test")
        body = """
            $sameVolume = Join-Path $plan.InstalledRoot ('.oculum-update-staged-' + [Guid]::NewGuid().ToString('N'))
            [void][IO.Directory]::CreateDirectory($sameVolume)
            $newStage = Join-Path $sameVolume ([IO.Path]::GetFileName($stage.RuntimeRoot))
            Copy-Item -LiteralPath $stage.RuntimeRoot -Destination $newStage -Recurse
            $stage.RuntimeRoot = $newStage
            Assert-OculumIncrementalStageReady $plan $stage -ExpectedStagingParent $sameVolume
        """
        result = self.invoke(target, self.stage + body, edition="test")
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        staged = Path(json.loads(result.stdout)["RuntimeRoot"])
        self.assertEqual((self.installed / "Oculum-Test.exe").read_bytes(), b"test application")
        self.assertEqual((staged / "data/app.so").read_bytes(), b"new test code")
        self.assertFalse((staged / "Oculum-Test.exe").exists())
        self.assertFalse((staged / "oculum.exe").exists())

    def test_accepts_manifest_emitted_by_release_publisher(self):
        target_files = RUNTIME | {"data/app.so": b"publisher and consumer agree"}
        target = self.create_manifest(40_330_467_934, target_files)
        fixture_manifest, archive, fixture = target
        published = self.root / "published.json"
        package = fixture["package"]
        result = subprocess.run(
            [sys.executable, str(ROOT / "scripts/oculum_incremental_publish.py"), str(archive),
             "--edition", fixture["edition"], "--commit", fixture["commit"],
             "--run-id", str(fixture["runId"]), "--url", package["url"],
             "--bytes", str(package["bytes"]), "--sha256", package["sha256"],
             "--output", str(published)],
            capture_output=True, text=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        # The manifest tested below comes from the release encoder, not from
        # the independently generated fixture metadata used in other tests.
        self.assertNotEqual(published, fixture_manifest)
        result = self.invoke((published, archive, json.loads(published.read_text())), self.stage)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        report = json.loads(result.stdout)
        self.assertEqual(report["count"], 1)
        self.assertEqual((Path(report["RuntimeRoot"]) / "data/app.so").read_bytes(), target_files["data/app.so"])

    def test_local_edits_remain_in_place_when_sparse_stage_is_revalidated(self):
        self.write_files(self.installed, {"data/user-settings.txt": b"before"})
        target = self.create_manifest(18, RUNTIME | {"data/app.so": b"updated"})
        check = """
            [IO.File]::WriteAllText((Join-Path $plan.InstalledRoot 'data/user-settings.txt'), 'changed')
            Assert-OculumIncrementalStageReady $plan $stage
        """
        result = self.invoke(target, self.stage + check)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        staged = Path(json.loads(result.stdout)["RuntimeRoot"])
        self.assertFalse((staged / "data/user-settings.txt").exists())
        self.assertEqual((self.installed / "data/user-settings.txt").read_bytes(), b"changed")

    def test_revalidation_rejects_injected_and_modified_managed_entries(self):
        original = RUNTIME | {"data/legacy.dat": b"old data"}
        source = self.create_manifest(17, original)
        target = self.create_manifest(18, RUNTIME | {"data/app.so": b"updated", "data/upcoming.dat": b"new"})
        cases = (
            ("stage file", "$stage.RuntimeRoot", "unlisted.dll", "Unexpected staged runtime entry"),
            ("unchanged staged copy", "$stage.RuntimeRoot", "data/icudtl.dat", "Unexpected staged runtime entry"),
            ("unexpected staged folder", "$stage.RuntimeRoot", "data/extra", "Unexpected staged runtime entry"),
            ("corrupt managed payload", "$stage.RuntimeRoot", "data/app.so", "Staged runtime file failed verification"),
            ("changed installed runtime", "$plan.InstalledRoot", "data/icudtl.dat", "Unchanged runtime file changed after preview"),
            ("changed obsolete file", "$plan.InstalledRoot", "data/legacy.dat", "Obsolete file changed after preview"),
            ("installed folder collision", "$plan.InstalledRoot", "data/upcoming.dat", "A local folder occupies a managed file path"),
        )
        for case, root, relative, reason in cases:
            with self.subTest(case=case):
                self.write_files(self.installed, original)
                path = f"(Join-Path {root} {quote(relative)})"
                if "folder" in case:
                    mutate = f"[void][IO.Directory]::CreateDirectory({path})"
                else:
                    mutate = f"[IO.File]::WriteAllText({path}, 'foreign')"
                result = self.invoke(
                    target,
                    self.stage + mutate + "; Assert-OculumIncrementalStageReady $plan $stage",
                    source=source,
                )
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn(reason, result.stderr)

    def test_revalidation_rejects_a_staged_junction_without_following_it(self):
        target = self.create_manifest(18, RUNTIME | {"data/app.so": b"updated"})
        check = """
            $junction = Join-Path $stage.RuntimeRoot 'data/link'
            $unrelated = Join-Path $plan.InstalledRoot 'data'
            New-Item -ItemType Junction -Path $junction -Target $unrelated | Out-Null
            Assert-OculumIncrementalStageReady $plan $stage
        """
        result = self.invoke(target, self.stage + check)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("Linked staged runtime entry", result.stderr)
        self.assertEqual((self.installed / "data/app.so").read_bytes(), RUNTIME["data/app.so"])

    def test_http_range_must_not_accept_full_response_wrong_bounds_or_encoding(self):
        target = self.create_manifest(51, RUNTIME)
        body = """
            $record = $plan.Target.Value.files[0]
            $package = $plan.Target.Value.package
            $end = $record.offset + $record.compressedBytes - 1
            $valid = "bytes $($record.offset)-${end}/$($package.bytes)"
            Assert-OculumIncrementalRangeResponse 206 $valid $record.compressedBytes 'identity' $package $record
            $invalid = @(
              { Assert-OculumIncrementalRangeResponse 200 $valid $record.compressedBytes '' $package $record },
              { Assert-OculumIncrementalRangeResponse 206 "bytes 0-1/9" $record.compressedBytes '' $package $record },
              { Assert-OculumIncrementalRangeResponse 206 $valid ($record.compressedBytes + 1) '' $package $record },
              { Assert-OculumIncrementalRangeResponse 206 $valid $record.compressedBytes 'gzip' $package $record }
            )
            foreach ($action in $invalid) {
              $refused = $false
              try { & $action } catch { $refused = $true }
              if (!$refused) { throw 'Invalid response passed' }
            }
        """
        result = self.invoke(target, body)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)


if __name__ == "__main__":
    unittest.main()
