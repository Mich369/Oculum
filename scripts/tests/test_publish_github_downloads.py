import importlib.util
from pathlib import Path
import unittest
import hashlib
import base64
from unittest.mock import patch
from io import BytesIO

spec = importlib.util.spec_from_file_location("publisher", Path(__file__).parents[1] / "publish_github_downloads.py")
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


class DownloadPublicationTests(unittest.TestCase):
    def test_update_log_uses_the_exact_built_commit(self):
        content = base64.b64encode("# Log\n\n- Bug fix\n- Nuovi mostri\n".encode()).decode()
        with patch.object(publisher, "api", return_value={"content": content}) as fetch:
            self.assertEqual(publisher.read_update_notes("a" * 40), ["Bug fix", "Nuovi mostri"])
            self.assertIn("ref=" + "a" * 40, fetch.call_args.args[0])

    def test_cumulative_log_links_to_built_commit_and_fixed_player_baseline(self):
        commit = "b" * 40
        text = publisher.notes({"one": dict(workflow="Build distribution", commit=commit,
            runUrl="https://github.com/Mich369/Oculum/actions/runs/42", artifacts=[],
            changelogPath="docs/REGISTRO_AGGIORNAMENTI.md")})
        self.assertIn("/blob/" + commit + "/docs/REGISTRO_AGGIORNAMENTI.md", text)
        self.assertIn("/actions/runs/40242640717", text)

    def test_update_log_is_short_and_ignores_non_list_content(self):
        result = publisher.parse_update_notes("# Title\nprivate prose\n" + "\n".join("- Item " + str(i) for i in range(12)))
        self.assertEqual(len(result), 8)
        self.assertNotIn("private prose", result)

    def test_published_catalog_preserves_updater_identity_with_dynamic_run_name(self):
        run = dict(id=42, workflow_id=7, name="Build distribution main @ " + "a" * 40,
                   conclusion="success", status="completed", head_branch="main",
                   head_sha="a" * 40, html_url="https://github.com/Mich369/Oculum/actions/runs/42",
                   repository={"full_name": publisher.REPO},
                   head_repository={"full_name": publisher.REPO})
        workflow = dict(name="Build distribution", path=".github/workflows/build_distribution.yml")
        payload = b"PK\x03\x04"
        artifacts = [dict(name=name, id=index, expired=False, size_in_bytes=len(payload),
                          digest="sha256:" + hashlib.sha256(payload).hexdigest())
                     for index, name in enumerate(publisher.PUBLIC_ARTIFACTS, start=1)]
        published = []

        def api(path):
            if path == "actions/runs/42":
                return run
            if path == "actions/workflows/7":
                return workflow
            if path.startswith("actions/workflows/7/runs?"):
                return {"workflow_runs": [run]}
            if path.startswith("actions/runs/42/artifacts?"):
                return {"artifacts": artifacts}
            self.fail("Unexpected API request: " + path)

        def gh(*args, **kwargs):
            if args[0] == "api":
                kwargs["stdout"].write(payload)
            if "--notes-file" in args:
                published.append(Path(args[args.index("--notes-file") + 1]).read_text(encoding="utf-8"))

        with patch.object(publisher, "api", side_effect=api), \
                patch.object(publisher, "gh", side_effect=gh), \
                patch.object(publisher, "release", return_value=None), \
                patch.object(publisher, "read_update_notes", return_value=["Bug fix", "Nuovi mostri"]), \
                patch.object(publisher, "verify_anonymous_download"):
            publisher.publish("42")
        self.assertEqual(len(published), 1)
        entry = publisher.read_catalog(published[0])["7"]
        self.assertEqual(entry["workflow"], "Build distribution")
        self.assertEqual(entry["runName"], run["name"])
        self.assertIn("## " + run["name"], published[0])
        self.assertIn("Oculum — download pubblici", published[0])
        self.assertIn("Log aggiornamento:",published[0])
        self.assertEqual(entry["changes"],["Bug fix","Nuovi mostri"])
        self.assertNotIn("â€", published[0])
        self.assertNotIn("Â", published[0])

    def test_only_successful_trusted_repository_builds(self):
        run = dict(conclusion="success", status="completed", head_branch="main",
                   name="Build distribution main @ abc123", head_sha="a" * 40,
                   repository={"full_name": publisher.REPO},
                   head_repository={"full_name": publisher.REPO})
        workflow = dict(name="Build distribution",
                        path=".github/workflows/build_distribution.yml")
        publisher.validate_run(run, workflow)
        publisher.validate_run({**run, "head_branch": "codex/new-version", "event": "push"}, workflow)
        for key, value in [("conclusion", "failure"), ("head_branch", ""), ("event", "pull_request"),
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
        self.assertEqual(len(publisher.select_release_archives(artifacts)), len(names))
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
    def test_resolve_latest_successful_trusted_distribution_from_any_branch(self):
        builds = {"workflow_runs": [
            {"id": 25, "status": "completed", "conclusion": "success",
             "head_branch": "main", "head_repository": {"full_name": "other/fork"}},
            {"id": 24, "status": "completed", "conclusion": "success",
             "head_branch": "codex/new-version", "head_repository": {"full_name": publisher.REPO}},
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
