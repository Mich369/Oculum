"""Verify installer and builder preflights without downloading or compiling."""

import base64
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
GATE_MESSAGE = "Verified rollback retention requires PowerShell 7.2"
RUN_ID = 123456789
COMMIT = "a" * 40


def ps_quote(value):
    return "'" + str(value).replace("'", "''") + "'"


@unittest.skipUnless(sys.platform == "win32", "Windows PowerShell 5.1 and pwsh required")
class DistributionEntrypointPreflightTests(unittest.TestCase):
    def setUp(self):
        build = ROOT / "build"
        build.mkdir(exist_ok=True)
        fixture = tempfile.TemporaryDirectory(prefix="distribution-preflight-fixture-", dir=build)
        self.addCleanup(fixture.cleanup)
        self.root = Path(fixture.name).resolve()
        self.assertEqual(self.root.parent, build.resolve())
        self.scripts = self.root / "scripts"
        self.scripts.mkdir()
        for file in ("install_github_distribution.ps1", "build_combat_distribution.ps1",
                     "oculum_distribution_swap.ps1"):
            shutil.copyfile(ROOT / "scripts" / file, self.scripts / file)
        (self.scripts / "verify_distribution.ps1").write_text("throw 'Unexpected verification'\n")
        (self.scripts / "build_process.ps1").write_text(
            "function Invoke-OculumBuildProcess { throw 'Fixture build boundary' }\n"
        )
        self.flutter = self.root / "stub flutter"
        for file in ("bin/cache/dart-sdk/bin/dart.exe", "bin/cache/flutter_tools.snapshot",
                     "packages/flutter_tools/.dart_tool/package_config.json"):
            path = self.flutter / file
            path.parent.mkdir(parents=True, exist_ok=True)
            path.touch()
        self.build = self.root / "build"
        self.live = self.build / "distribution" / "previous.txt"
        self.live.parent.mkdir(parents=True)
        self.live.write_text("previous verified package\n")

    def invoke(self, command, shell="powershell.exe"):
        stubs = """
        function git {
          $global:LASTEXITCODE = 0
          if ($args -contains 'rev-parse') { return '%s' }
          if ($args -contains 'status' -or $args -contains 'ls-files') { return }
          throw 'Unexpected Git fixture invocation'
        }
        function gh {
          $global:LASTEXITCODE = 0
          if ($args[0] -eq 'api') { return '{"head_sha":"%s","conclusion":"success"}' }
          if ($args[0] -eq 'run' -and $args[1] -eq 'download') { throw 'Fixture download boundary' }
          throw 'Unexpected GitHub fixture invocation'
        }
        """ % (COMMIT, COMMIT)
        encoded = base64.b64encode((stubs + command).encode("utf-16-le")).decode("ascii")
        return subprocess.run(
            [shell, "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-EncodedCommand", encoded],
            capture_output=True,
            text=True,
            timeout=45,
        )

    def assert_failure(self, result, message):
        output = result.stdout + result.stderr
        self.assertNotEqual(result.returncode, 0, output)
        self.assertIn(message, output)
        self.assertEqual(self.live.read_text(), "previous verified package\n")
        return output

    def installer_command(self):
        return "& " + ps_quote(self.scripts / "install_github_distribution.ps1") + f" -RunId {RUN_ID}"

    def builder_command(self):
        return (
            "& " + ps_quote(self.scripts / "build_combat_distribution.ps1")
            + " -FlutterRoot " + ps_quote(self.flutter)
        )

    def test_legacy_installer_stops_before_any_staging_or_download(self):
        result = self.invoke(self.installer_command())
        self.assertNotIn("Fixture download boundary", self.assert_failure(result, GATE_MESSAGE))
        self.assertEqual(list(self.build.iterdir()), [self.live.parent])

    @unittest.skipUnless(shutil.which("pwsh.exe"), "PowerShell 7 required for the positive control")
    def test_pwsh_installer_reaches_download_boundary(self):
        result = self.invoke(self.installer_command(), shell="pwsh.exe")
        self.assert_failure(result, "Fixture download boundary")
        for kind in ("fresh", "download"):
            self.assertTrue((self.build / f"distribution-{kind}-{RUN_ID}").is_dir())

    def test_legacy_builder_stops_before_staging_and_lock_for_install(self):
        result = self.invoke(self.builder_command())
        self.assertNotIn("Fixture build boundary", self.assert_failure(result, GATE_MESSAGE))
        self.assertEqual(list(self.build.iterdir()), [self.live.parent])

    def test_legacy_builder_allows_stage_only(self):
        result = self.invoke(self.builder_command() + " -StageOnly")
        self.assert_failure(result, "Fixture build boundary")
        self.assertFalse(list(self.build.glob("distribution-combat-*")))
