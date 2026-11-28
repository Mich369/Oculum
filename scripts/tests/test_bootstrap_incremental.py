"""Exercise the Windows bootstrap against a synthetic public release and runtime."""

import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile


PROJECT = Path(__file__).resolve().parents[2]
WORK = PROJECT / 'assets/update'
FIXTURES = PROJECT / "build"
RUN = 44_141_046_738
COMMIT = "b" * 40
PREVIOUS_COMMIT = "a" * 40


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def quote(value):
    return "'" + str(value).replace("'", "''") + "'"


@unittest.skipUnless(sys.platform == "win32", "Windows bootstrap required")
class BootstrapIncrementalWindowsTests(unittest.TestCase):
    def exercise(self, edition, mode, invalid_package=False, previous=None, unstable_channel=False):
        artifact = "Oculum-Test-Windows" if edition == "test" else "Oculum-Windows"
        exe = "Oculum-Test.exe" if edition == "test" else "oculum.exe"
        runtime = {
            exe: b"synthetic Windows runtime",
            "flutter_windows.dll": b"synthetic flutter",
            "WebView2Loader.dll": b"synthetic loader",
            "data/app.so": b"new synthetic application",
            "data/icudtl.dat": b"synthetic locales",
            "data/flutter_assets/AssetManifest.bin": b"synthetic assets",
        }
        FIXTURES.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="bootstrap-test-", dir=FIXTURES) as name:
            root = Path(name).resolve()
            self.assertEqual(root.parent, FIXTURES.resolve())
            installed = root / "my Oculum installation"
            work_bundle = root / "packaged helpers"
            work_bundle.mkdir()
            cache = root / "Local AppData" / "com.example" / "oculum"
            for script in ("Oculum-Aggiornamento-Incrementale.ps1", "incremental_driver.ps1", "update.ps1"):
                shutil.copyfile(WORK / script, work_bundle / script)
            shutil.copyfile(PROJECT / "assets/update/oculum_incremental_windows.ps1",
                            work_bundle / "oculum_incremental_windows.ps1")
            zip_name = f"{artifact}-Folder.zip"
            manifest_name = f"{artifact}-Incrementale.json"
            archive = root / zip_name
            manifest = root / manifest_name
            base = f"https://github.com/Mich369/Oculum/releases/download/oculum-build-{RUN}"
            with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as z:
                for relative, data in runtime.items():
                    z.writestr(relative, data)
                    old = installed / relative
                    old.parent.mkdir(parents=True, exist_ok=True)
                    old.write_bytes(data if relative != "data/app.so" else b"previous")
            result = subprocess.run(
                [sys.executable, str(PROJECT / "scripts/oculum_incremental_publish.py"), str(archive),
                 "--edition", edition, "--commit", COMMIT, "--run-id", str(RUN),
                 "--url", f"{base}/{zip_name}", "--bytes", str(archive.stat().st_size),
                 "--sha256", digest(archive), "--output", str(manifest)],
                capture_output=True, text=True, timeout=30,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            package_entry = dict(name=f"{artifact}-Folder", url=f"{base}/{zip_name}",
                                 bytes=archive.stat().st_size, sha256="sha256:" + digest(archive))
            manifest_entry = dict(artifact=artifact, edition=edition,
                                  url=f"{base}/{manifest_name}", bytes=manifest.stat().st_size,
                                  sha256="sha256:" + digest(manifest))
            release = dict(tag_name=f"oculum-build-{RUN}", draft=False, prerelease=True,
                           target_commitish=COMMIT, assets=[
                               dict(name=title, state="uploaded", browser_download_url=entry["url"],
                                    size=entry["bytes"], digest=entry["sha256"])
                               for title, entry in [(zip_name, package_entry), (manifest_name, manifest_entry)]
                           ])
            if invalid_package:
                release["assets"][0]["digest"] = "sha256:" + "0" * 64
            catalog = {"10": dict(workflow="Build distribution", runId=RUN, commit=COMMIT,
                                  artifacts=[package_entry], incremental=[manifest_entry])}
            responses = {
                "releases/tags/oculum-downloads": dict(tag_name="oculum-downloads", draft=False,
                    prerelease=unstable_channel, body="<!-- OCULUM_DOWNLOADS:" + json.dumps(catalog) + " -->"),
                f"releases/tags/oculum-build-{RUN}": release,
            }
            previous_manifest = root / "previous-manifest.json"
            if previous:
                (installed / "data/obsolete.dat").write_bytes(b"old file")
                responses[f"compare/{PREVIOUS_COMMIT}...{COMMIT}"] = {"status": "ahead"}
            if previous == "indexed":
                old_run = RUN - 50
                old_tag = f"oculum-build-{old_run}"
                old_base = f"https://github.com/Mich369/Oculum/releases/download/{old_tag}"
                old_files = runtime | {"data/app.so": b"previous", "data/obsolete.dat": b"old file"}
                previous_archive = root / "previous.zip"
                with zipfile.ZipFile(previous_archive, "w") as z:
                    for relative, data in old_files.items():
                        z.writestr(relative, data)
                result = subprocess.run(
                    [sys.executable, str(PROJECT / "scripts/oculum_incremental_publish.py"), str(previous_archive),
                     "--edition", edition, "--commit", PREVIOUS_COMMIT, "--run-id", str(old_run),
                     "--url", f"{old_base}/{zip_name}", "--bytes", str(previous_archive.stat().st_size),
                     "--sha256", digest(previous_archive), "--output", str(previous_manifest)],
                    capture_output=True, text=True, timeout=30,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                previous_query = (
                    "actions/workflows/build_distribution.yml/runs"
                    f"?head_sha={PREVIOUS_COMMIT}&branch=main&status=success&per_page=5"
                )
                responses[previous_query] = dict(workflow_runs=[
                    dict(id=old_run, head_sha=PREVIOUS_COMMIT, head_branch="main", conclusion="success")
                ])
                responses[f"releases/tags/{old_tag}"] = dict(
                    tag_name=old_tag, draft=False, prerelease=True, target_commitish=PREVIOUS_COMMIT,
                    assets=[dict(name=manifest_name, state="uploaded",
                                 browser_download_url=f"{old_base}/{manifest_name}",
                                 size=previous_manifest.stat().st_size, digest="sha256:" + digest(previous_manifest))],
                )
            response_path = root / "public-api-fixture.json"
            response_path.write_text(json.dumps(responses), encoding="utf-8")
            command = """
                $ErrorActionPreference = 'Stop'
                . BOOTSTRAP
                $fakeApi = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText(API))
                function Read-OculumBootstrapApi([string]$Endpoint) {
                  $input = $fakeApi.PSObject.Properties[$Endpoint]
                  if (!$input) { throw "Unexpected endpoint $Endpoint" }
                  return $input.Value
                }
                function Get-OculumBootstrapCache { return CACHE }
                function Save-OculumBootstrapManifest($asset, [string]$destination) {
                  $source = if ([IO.Path]::GetFileName($destination) -eq 'incremental-source.json') { PREVIOUS } else { MANIFEST }
                  [IO.File]::Copy($source, $destination, $true)
                  if (!(Test-OculumIncrementalFile $destination $asset)) { throw 'Snapshot failed fixture verification' }
                  SEED
                }
                function Read-Host($Prompt) {
                  if ($Prompt -like 'Scaricare*') { ON_CONSENT; return 'SI' }
                  AFTER_STAGE
                }
                Push-Location -LiteralPath INSTALL
                try { Invoke-OculumIncrementalBootstrap -Executable EXE DRYRUN CURRENT | ConvertTo-Json -Compress }
                finally { Pop-Location }
            """
            replacements = {
                "BOOTSTRAP": quote(work_bundle / "Oculum-Aggiornamento-Incrementale.ps1"),
                "API": quote(response_path), "CACHE": quote(cache), "MANIFEST": quote(manifest),
                "PREVIOUS": quote(previous_manifest),
                "INSTALL": quote(installed), "EXE": quote(f"./{exe}"),
                "DRYRUN": "-DryRun" if mode == "dry" else "",
                "CURRENT": ("-CurrentCommit " + quote(PREVIOUS_COMMIT)) if previous else "",
                "ON_CONSENT": "throw 'Unexpected consent request'" if mode == "dry" else "",
                "AFTER_STAGE": "throw 'Unexpected confirmation after increasing bytes'" if mode == "grow" else "return 'ANNULLA'",
                "SEED": "",
            }
            if mode != "dry":
                content = runtime["data/app.so"]
                content_digest = hashlib.sha256(content).hexdigest()
                seed = (
                    "[void][IO.Directory]::CreateDirectory($objectsDir);"
                    f"[IO.File]::WriteAllBytes((Join-Path $objectsDir '{content_digest}.bin'),"
                    f"[Text.Encoding]::UTF8.GetBytes({quote(content.decode())}));"
                )
                if mode in ("stage", "grow"):
                    replacements["SEED"] = (
                        "$objectsDir = Join-Path ([IO.Path]::GetDirectoryName($destination)) 'objects';" + seed
                    )
                if mode == "shrink":
                    replacements["ON_CONSENT"] = "$objectsDir = Join-Path $work 'objects';" + seed
                elif mode == "grow":
                    replacements["ON_CONSENT"] = f"[IO.File]::Delete((Join-Path $work 'objects/{content_digest}.bin'))"
            template = re.compile(r"\b(" + "|".join(replacements) + r")\b")
            command = template.sub(lambda match: replacements[match[0]], command)
            result = subprocess.run(
                ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
                 "-Command", command],
                capture_output=True, text=True, timeout=45,
            )
            self.assertEqual((installed / "data/app.so").read_bytes(), b"previous")
            if invalid_package or unstable_channel:
                self.assertNotEqual(result.returncode, 0, result.stdout)
                expected = (
                    "Canale pubblico Oculum non disponibile" if unstable_channel
                    else "non corrispondono al catalogo"
                )
                self.assertIn(expected, result.stderr)
                self.assertFalse(cache.exists())
                return
            if mode == "grow":
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn("download grew since the preview", result.stderr)
                local_work = next(cache.glob(f"oculum-update-{RUN}-{edition}-*"))
                self.assertFalse((local_work / "incremental-stage.json").exists())
                return
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            local_work = next(cache.glob(f"oculum-update-{RUN}-{edition}-*"))
            preview = json.loads((local_work / "incremental-preview.json").read_text(encoding="utf-8-sig"))
            self.assertEqual(preview["edition"], edition)
            self.assertEqual(preview["commit"], COMMIT)
            self.assertEqual(preview["changedPaths"], ["data/app.so"])
            self.assertEqual(preview["removedPaths"], ["data/obsolete.dat"] if previous == "indexed" else [])
            if previous:
                self.assertEqual((installed / "data/obsolete.dat").read_bytes(), b"old file")
            if mode == "dry":
                self.assertEqual(preview["downloadCount"], 1)
                self.assertGreater(preview["downloadBytes"], 0)
                self.assertFalse((local_work / "objects").exists())
                self.assertFalse((local_work / "incremental-stage.json").exists())
            else:
                self.assertEqual(preview["downloadCount"], 1 if mode == "shrink" else 0)
                receipt = json.loads((local_work / "incremental-stage.json").read_text(encoding="utf-8-sig"))
                stage = local_work / receipt["runtimeDirectoryName"]
                self.assertEqual((stage / "data/app.so").read_bytes(), runtime["data/app.so"])
                self.assertEqual(receipt["changedPaths"], ["data/app.so"])
                self.assertEqual(receipt["removedPaths"], [])
                self.assertEqual((receipt["downloadCount"], receipt["downloadBytes"]), (0, 0))
                self.assertFalse((local_work / "startup-ack.json").exists())

    def test_normal_dry_run_previews_without_downloading_the_runtime(self):
        self.exercise("normal", "dry")

    def test_test_edition_has_separate_preview(self):
        self.exercise("test", "dry")

    def test_disagreeing_release_is_rejected_before_staging(self):
        with self.subTest("versioned archive disagrees"):
            self.exercise("normal", "dry", invalid_package=True)
        with self.subTest("catalog must remain stable"):
            self.exercise("normal", "dry", unstable_channel=True)

    def test_consent_stages_cached_files_and_cancel_prevents_install(self):
        for mode in ("stage", "shrink", "grow"):
            with self.subTest(mode=mode):
                self.exercise("normal", mode)

    def test_previous_official_commit_allows_previewing_obsolete_runtime(self):
        self.exercise("normal", "dry", previous="indexed")

    def test_unindexed_old_build_leaves_obsolete_file_alone(self):
        self.exercise("normal", "dry", previous="unavailable")


if __name__ == "__main__":
    unittest.main()
