import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch
from io import BytesIO

spec = importlib.util.spec_from_file_location("publisher", Path(__file__).parents[1] / "publish_github_downloads.py")
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


class DownloadPublicationTests(unittest.TestCase):
    def test_only_successful_trusted_repository_builds(self):
        run = dict(conclusion="success", status="completed", head_branch="main",
                   name="Build distribution main @ abc123", head_sha="a" * 40,
                   repository={"full_name": publisher.REPO},
                   head_repository={"full_name": publisher.REPO})
        workflow = dict(name="Build distribution",
                        path=".github/workflows/build_distribution.yml")
        publisher.validate_run(run, workflow)
        for key, value in [("conclusion", "failure"), ("head_branch", ""), ("head_branch", "feature"),
                           ("head_repository", {"full_name": "outsider/fork"})]:
            with self.assertRaises(ValueError):
                publisher.validate_run({**run, key: value}, workflow)
        for key, value in [("name", "Untrusted job"),
                           ("path", ".github/workflows/other.yml")]:
            with self.assertRaises(ValueError):
                publisher.validate_run(run, {**workflow, key: value})

    def test_artifacts_cannot_escape_download_folder(self):
        artifact = dict(id=1, name="Oculum-Windows", expired=False, size_in_bytes=4)
        self.assertEqual(publisher.asset_name(artifact), "Oculum-Windows.zip")
        for patch in [dict(name="../secret"), dict(expired=True), dict(size_in_bytes=2 * 1024**3)]:
            with self.assertRaises(ValueError):
                publisher.asset_name({**artifact, **patch})

    def test_only_publishes_the_complete_five_platform_set(self):
        artifacts = [
            {"name": name, "id": index, "expired": False, "size_in_bytes": 4}
            for index, name in enumerate(publisher.PUBLIC_ARTIFACTS, start=1)
        ]
        artifacts += [{"name": "Oculum-iOS-unsigned", "id": 99}]
        self.assertEqual(
            [item["name"] for item in publisher.select_public_artifacts(artifacts)],
            list(publisher.PUBLIC_ARTIFACTS),
        )
        with self.assertRaisesRegex(ValueError, "Waiting for the complete"):
            publisher.select_public_artifacts(artifacts[:-2])

    def test_catalog_round_trip_keeps_other_platforms(self):
        catalog = {"one": dict(workflow="Build distribution", commit="a" * 40,
                               runUrl="https://github.com/Mich369/Oculum/actions/runs/1",
                               artifacts=[])}
        self.assertEqual(publisher.read_catalog(publisher.notes(catalog)), catalog)
        with self.assertRaises(ValueError):
            publisher.read_catalog("An unrelated release must never be overwritten")

    def test_full_release_keeps_extra_archives_without_exposing_unknown_files(self):
        names = publisher.PUBLIC_ARTIFACTS + publisher.EXTRA_ARCHIVES
        artifacts = [dict(name=name, id=index, expired=False, size_in_bytes=4)
                     for index, name in enumerate(names, start=1)]
        self.assertEqual(len(publisher.select_release_archives(artifacts)), 9)
        self.assertEqual(len(publisher.select_public_artifacts(artifacts)), 5)
        with self.assertRaisesRegex(ValueError, "Unreviewed"):
            publisher.select_release_archives(artifacts + [dict(name="private-saves")])
        with self.assertRaisesRegex(ValueError, "duplicate"):
            publisher.select_release_archives(artifacts + [artifacts[-1]])
        catalog = {"one": dict(workflow="Build distribution", commit="a" * 40,
                               runId=42, runUrl="https://github.com/Mich369/Oculum/actions/runs/42",
                               artifacts=[])}
        notes = publisher.notes(catalog)
        self.assertIn("releases/tag/oculum-build-42", notes)
        self.assertEqual(publisher.read_catalog(notes), catalog)


class DownloadRecoveryTests(unittest.TestCase):
    def test_resolve_latest_successful_main_distribution(self):
        builds = {"workflow_runs": [
            {"id": 25, "status": "completed", "conclusion": "success",
             "head_branch": "main", "head_repository": {"full_name": "other/fork"}},
            {"id": 24, "status": "completed", "conclusion": "success",
             "head_branch": "main", "head_repository": {"full_name": publisher.REPO}},
        ]}
        with patch.object(publisher, "api", return_value=builds):
            self.assertEqual(publisher.resolve_run_id(""), "24")
        with patch.object(publisher, "api") as mocked:
            self.assertEqual(publisher.resolve_run_id("123"), "123")
            mocked.assert_not_called()
        with self.assertRaisesRegex(ValueError, "Invalid run id"):
            publisher.resolve_run_id("invalid")
        with patch.object(publisher, "api", return_value={"workflow_runs": []}):
            with self.assertRaisesRegex(ValueError, "No successful"):
                publisher.resolve_run_id("")

    def test_channel_does_not_regress_across_branches(self):
        catalog = {"one": dict(workflow="Build distribution", runId=200)}
        self.assertFalse(publisher.can_promote_channel(catalog, "100"))
        self.assertTrue(publisher.can_promote_channel(catalog, "201"))

    def test_anonymous_archive_check_has_no_authorization(self):
        class Response(BytesIO):
            status = 206
            headers = {"Content-Range": "bytes 0-3/100"}
        with patch.object(publisher, "urlopen", return_value=Response(b"PK\x03\x04")) as opening:
            publisher.verify_anonymous_download(dict(name="Oculum-Windows",url="https://github.com/package.zip",bytes=100))
            self.assertFalse(opening.call_args.args[0].has_header("Authorization"))
        with patch.object(publisher, "urlopen", return_value=Response(b"HTML")):
            with self.assertRaises(ValueError):
                publisher.verify_anonymous_download(dict(name="Oculum-Windows",url="https://github.com/package.zip",bytes=100))
