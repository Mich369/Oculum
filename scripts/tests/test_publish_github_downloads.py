import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("publisher", Path(__file__).parents[1] / "publish_github_downloads.py")
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


class DownloadPublicationTests(unittest.TestCase):
    def test_only_successful_trusted_main_builds(self):
        run = dict(conclusion="success", status="completed", head_branch="main",
                   name="Build distribution", head_sha="a" * 40,
                   repository={"full_name": publisher.REPO},
                   head_repository={"full_name": publisher.REPO})
        publisher.validate_run(run)
        for key, value in [("conclusion", "failure"), ("head_branch", "other"),
                           ("head_repository", {"full_name": "outsider/fork"}),
                           ("name", "Untrusted job")]:
            with self.assertRaises(ValueError):
                publisher.validate_run({**run, key: value})

    def test_artifacts_cannot_escape_download_folder(self):
        artifact = dict(id=1, name="Oculum-Windows", expired=False, size_in_bytes=4)
        self.assertEqual(publisher.asset_name(artifact), "Oculum-Windows.zip")
        for patch in [dict(name="../secret"), dict(expired=True), dict(size_in_bytes=2 * 1024**3)]:
            with self.assertRaises(ValueError):
                publisher.asset_name({**artifact, **patch})

    def test_catalog_round_trip_keeps_other_platforms(self):
        catalog = {"one": dict(workflow="Build distribution", commit="a" * 40,
                               runUrl="https://github.com/Mich369/Oculum/actions/runs/1",
                               artifacts=[])}
        self.assertEqual(publisher.read_catalog(publisher.notes(catalog)), catalog)
        with self.assertRaises(ValueError):
            publisher.read_catalog("An unrelated release must never be overwritten")
