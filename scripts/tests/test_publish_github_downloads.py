import importlib.util
from pathlib import Path
import unittest
import hashlib
import base64
from unittest.mock import patch
from io import BytesIO
from urllib.error import HTTPError

spec = importlib.util.spec_from_file_location("publisher", Path(__file__).parents[1] / "publish_github_downloads.py")
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


def mirror_asset(entry):
    return dict(name=entry["name"] + ".zip", state="uploaded", size=entry["bytes"],
                digest=entry["sha256"], browser_download_url=entry["url"])


class DownloadPublicationTests(unittest.TestCase):
    def test_android_builds_finish_before_packaging_and_keep_signature_checks(self):
        workflow = (Path(__file__).parents[2] / ".github/workflows/build_distribution.yml").read_text(encoding="utf-8")
        apk = workflow.index("flutter build apk --release")
        bundle = workflow.index("flutter build appbundle --release")
        verify_bundle = workflow.index("jarsigner -verify build/app/outputs/bundle/release/app-release.aab")
        package = workflow.index("name: Package Android release")
        upload = workflow.index("name: Upload Android APK artifact")
        self.assertLess(apk, bundle)
        self.assertLess(bundle, verify_bundle)
        self.assertLess(verify_bundle, package)
        self.assertLess(package, upload)
        self.assertNotIn("cp build/app/outputs/flutter-apk", workflow[apk:verify_bundle])
        self.assertIn("scripts/verify_android_signing.py", workflow[package:upload])
        self.assertIn('--min-version-code "$OCULUM_ANDROID_BUILD_NUMBER"', workflow[package:upload])
        # A diagnostic Gradle retry must never turn the original failure green.
        self.assertIn('exit "$bundle_status"', workflow[bundle:verify_bundle])

    def test_android_aab_stays_in_ci_while_the_apk_is_public(self):
        # This real growth boundary broke publication when the two packages
        # were combined. Keep APK identity stable for older app updaters.
        apk = dict(name="Oculum-Android", id=1, expired=False, size_in_bytes=1_140_000_000)
        aab = dict(name="Oculum-Android-AAB", id=2, expired=False, size_in_bytes=1_020_000_000)
        with self.assertRaisesRegex(ValueError, "size limit"):
            publisher.asset_name({**apk, "size_in_bytes": apk["size_in_bytes"] + aab["size_in_bytes"]})
        self.assertEqual(publisher.asset_name(apk), "Oculum-Android.zip")
        self.assertEqual(publisher.asset_name(aab), "Oculum-Android-AAB.zip")
        required = [dict(name=name, id=index+10, expired=False, size_in_bytes=4)
                    for index,name in enumerate(publisher.PUBLIC_ARTIFACTS) if name != "Oculum-Android"]
        selected = publisher.select_release_archives([aab, *required, apk])
        self.assertNotIn(aab, selected)
        self.assertIn(apk, selected)
        self.assertEqual(len(selected), 9)
        workflow = (Path(__file__).parents[2] / ".github/workflows/build_distribution.yml").read_text(encoding="utf-8")
        apk_upload = workflow.split("name: Upload Android APK artifact",1)[1].split("name: Upload Android App Bundle artifact",1)[0]
        self.assertIn("name: Oculum-Android\n", apk_upload)
        self.assertIn("Oculum-Android-release.apk", apk_upload)
        self.assertNotIn("Oculum-Android-release.aab", apk_upload)
        self.assertIn("name: Oculum-Android-AAB\n", workflow)

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
        self.assert_publish_with_listed_runs([42], promotes=True)

    def test_verified_run_is_published_when_the_success_list_lags(self):
        for listed_ids in ([], [41]):
            with self.subTest(listed_ids=listed_ids):
                self.assert_publish_with_listed_runs(listed_ids, promotes=True)

    def test_older_verified_run_is_archived_without_changing_the_channel(self):
        self.assert_publish_with_listed_runs([100], promotes=False)
        self.assert_publish_with_listed_runs([], promotes=False, channel_id=100)

    def assert_publish_with_listed_runs(self, listed_ids, *, promotes, channel_id=None):
        run = dict(id=42, workflow_id=7, name="Build distribution main @ " + "a" * 40,
                   conclusion="success", status="completed", head_branch="main",
                   head_sha="a" * 40, html_url="https://github.com/Mich369/Oculum/actions/runs/42",
                   repository={"full_name": publisher.REPO},
                   head_repository={"full_name": publisher.REPO})
        workflow = dict(name="Build distribution", path=".github/workflows/build_distribution.yml")
        payload = b"PK\x03\x04"
        names = publisher.PUBLIC_ARTIFACTS + tuple(sorted(publisher.LEGACY_ARCHIVES))
        artifacts = [dict(name=name, id=index, expired=False, size_in_bytes=len(payload),
                          digest="sha256:" + hashlib.sha256(payload).hexdigest())
                     for index, name in enumerate(names, start=1)]
        published = []
        assets = []
        downloads = []
        created_tags = []
        tag = "oculum-build-42"

        def api(path):
            if path == "actions/runs/42":
                return run
            if path == "actions/workflows/7":
                return workflow
            if path.startswith("actions/workflows/7/runs?"):
                return {"workflow_runs": [dict(run, id=run_id) for run_id in listed_ids]}
            if path.startswith("actions/runs/42/artifacts?"):
                return {"artifacts": artifacts}
            self.fail("Unexpected API request: " + path)

        def gh(*args, **kwargs):
            if args[0] == "api":
                downloads.append(int(args[1].split("/")[-2]))
                kwargs["stdout"].write(payload)
            if args[:2] == ("release", "create"):
                created_tags.append(args[2])
            if args[:2] == ("release", "upload"):
                self.assertNotIn("--clobber", args)
                filename = Path(args[3]).name
                artifact = next(a for a in artifacts if a["name"] + ".zip" == filename)
                assets.append(mirror_asset(publisher.archive_entry(artifact, tag)))
            if "--notes-file" in args:
                published.append(Path(args[args.index("--notes-file") + 1]).read_text(encoding="utf-8"))

        def release(name):
            if name == tag and assets:
                return dict(tag_name=tag, draft=False, target_commitish=run["head_sha"], assets=assets)
            if name == publisher.CHANNEL and channel_id is not None:
                return {"body": publisher.notes({"7": dict(workflow=workflow["name"],
                    commit="b" * 40, runId=channel_id, artifacts=[],
                    runUrl=f"https://github.com/{publisher.REPO}/actions/runs/{channel_id}")})}
            return None

        with patch.object(publisher, "api", side_effect=api), \
                patch.object(publisher, "gh", side_effect=gh), \
                patch.object(publisher, "release", side_effect=release), \
                patch.object(publisher, "read_update_notes", return_value=["Bug fix", "Nuovi mostri"]), \
                patch.object(publisher, "verify_anonymous_download") as check_anonymous:
            publisher.publish("42")
        self.assertEqual(downloads, list(range(1, 10)))
        self.assertEqual(len(assets), 9)
        self.assertEqual(check_anonymous.call_count, 9)
        self.assertIn(tag, created_tags)
        if not promotes:
            self.assertEqual(created_tags, [tag])
            self.assertEqual(published, [])
            return
        self.assertEqual(len(published), 1)
        entry = publisher.read_catalog(published[0])["7"]
        self.assertEqual(entry["workflow"], "Build distribution")
        self.assertEqual(entry["runName"], run["name"])
        self.assertIn("## " + run["name"], published[0])
        self.assertIn("Oculum — download pubblici", published[0])
        self.assertIn("Log aggiornamento:",published[0])
        self.assertEqual(entry["changes"],["Bug fix","Nuovi mostri"])
        self.assertEqual([a["name"] for a in entry["artifacts"]], list(publisher.PUBLIC_ARTIFACTS))
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

    def test_only_publishes_the_complete_platform_set(self):
        artifacts = [
            {"name": name, "id": index, "expired": False, "size_in_bytes": 4}
            for index, name in enumerate(publisher.PUBLIC_ARTIFACTS, start=1)
        ]
        artifacts += [{"name": "Oculum-UI-Catture", "id": 99}]
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

    def test_full_ci_build_excludes_internal_archives_from_new_public_mirrors(self):
        names = publisher.PUBLIC_ARTIFACTS + tuple(sorted(publisher.LEGACY_ARCHIVES))
        artifacts = [dict(name=name, id=index, expired=False, size_in_bytes=4)
                     for index, name in enumerate(names, start=1)]
        self.assertEqual([a["name"] for a in publisher.select_release_archives(artifacts)],
                         list(publisher.PUBLIC_ARTIFACTS))
        with self.assertRaisesRegex(ValueError, "Unreviewed"):
            publisher.select_release_archives(artifacts + [dict(name="private-saves")])
        with self.assertRaisesRegex(ValueError, "duplicate"):
            publisher.select_release_archives(artifacts + [artifacts[-1]])
        catalog = {"one": dict(workflow="Build distribution", commit="a" * 40,
                               runId=42, runUrl="https://github.com/Mich369/Oculum/actions/runs/42",
                               artifacts=[])}
        notes = publisher.notes(catalog)
        self.assertNotIn("releases/tag/oculum-build-42", notes)
        self.assertEqual(publisher.read_catalog(notes), catalog)

    def test_reindexing_existing_release_preserves_its_historical_archives(self):
        commit = "a" * 40
        tag = "oculum-build-42"
        run = dict(id=42, workflow_id=7, name="Build distribution", conclusion="success",
                   status="completed", head_branch="main", head_sha=commit,
                   html_url=f"https://github.com/{publisher.REPO}/actions/runs/42",
                   repository={"full_name": publisher.REPO}, head_repository={"full_name": publisher.REPO})
        workflow = dict(name="Build distribution", path=".github/workflows/build_distribution.yml")
        extras = ("Oculum-UI-Catture", "Oculum-Verifica-Mostri", "Oculum-Android-AAB")
        artifacts = [dict(name=name, id=index, expired=False, size_in_bytes=4,
                          digest="sha256:" + "a" * 64)
                     for index, name in enumerate(publisher.PUBLIC_ARTIFACTS + extras, start=1)]
        old_entries = [publisher.archive_entry(a, tag) for a in artifacts]
        assets = [mirror_asset(entry) for entry in old_entries]
        released = dict(tag_name=tag, draft=False, target_commitish=commit, assets=assets)
        old_item = dict(workflow=workflow["name"], commit=commit, runId=42,
                        runUrl=run["html_url"], artifacts=old_entries)
        channel = dict(body=publisher.notes({"7": old_item, "6": {**old_item, "runId": 41}}))
        updated = []

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
            self.assertEqual(args[:3], ("release", "edit", publisher.CHANNEL))
            updated.append(Path(args[args.index("--notes-file") + 1]).read_text(encoding="utf-8"))

        with patch.object(publisher, "api", side_effect=api), \
                patch.object(publisher, "gh", side_effect=gh), \
                patch.object(publisher, "release", side_effect=lambda name: released if name == tag else channel), \
                patch.object(publisher, "read_update_notes", return_value=[]), \
                patch.object(publisher, "verify_anonymous_download") as check_anonymous:
            publisher.publish("42")
        self.assertEqual(len(assets), 12)
        self.assertEqual(check_anonymous.call_count, 9)
        self.assertEqual(len(updated), 1)
        catalog = publisher.read_catalog(updated[0])
        self.assertEqual(list(catalog), ["7"])
        self.assertEqual([a["name"] for a in catalog["7"]["artifacts"]], list(publisher.PUBLIC_ARTIFACTS))
        for name in extras:
            self.assertNotIn(name, updated[0])

    def test_release_asset_digest_and_exact_allowed_names_are_checked(self):
        tag = "oculum-build-42"
        commit = "a" * 40
        entry = publisher.archive_entry(dict(name="Oculum-Windows", id=1,
            expired=False, size_in_bytes=4, digest="sha256:" + "b" * 64), tag)
        asset = mirror_asset(entry)
        release = dict(tag_name=tag, draft=False, target_commitish=commit, assets=[asset])
        expected = {asset["name"]: entry}
        self.assertEqual(publisher.verified_release_assets(release, tag, commit, expected), set(expected))
        for change in ({"digest": "sha256:" + "a" * 64}, {"name": "Oculum-UI-Catture.zip"},
                       {"size": 5}, {"state": "starter"}):
            with self.assertRaisesRegex(ValueError, "Release asset"):
                publisher.verified_release_assets({**release, "assets": [{**asset, **change}]},
                                                  tag, commit, expected)


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
        wrong_range = Response(b"PK\x03\x04")
        wrong_range.headers = {"Content-Range": "bytes 1-4/100"}
        with patch.object(publisher, "urlopen", return_value=wrong_range):
            with self.assertRaisesRegex(ValueError, "size mismatch"):
                publisher.verify_anonymous_download(dict(name="Oculum-Windows",url="https://github.com/package.zip",bytes=100))

    def test_anonymous_archive_check_retries_gateway_error_with_fresh_redirect(self):
        class Response(BytesIO):
            status = 206
            headers = {"Content-Range": "bytes 0-3/100"}

        url = "https://github.com/package.zip"
        entry = dict(name="Oculum-Windows", url=url, bytes=100)
        failure = HTTPError(url, 504, "Gateway Timeout", {}, None)
        with patch.object(publisher, "urlopen", side_effect=[failure, Response(b"PK\x03\x04")]) as opening, \
                patch.object(publisher, "time_ns", return_value=123), patch.object(publisher, "sleep") as waiting:
            publisher.verify_anonymous_download(entry)

        first, second = [call.args[0] for call in opening.call_args_list]
        self.assertEqual(first.full_url, url)
        self.assertEqual(second.full_url, url + "?oculum_check=123")
        self.assertEqual(second.get_header("Range"), "bytes=0-3")
        self.assertFalse(second.has_header("Authorization"))
        self.assertEqual(entry["url"], url)
        waiting.assert_called_once_with(2)

    def test_anonymous_archive_check_does_not_retry_a_missing_file(self):
        url = "https://github.com/package.zip"
        failure = HTTPError(url, 404, "Not Found", {}, None)
        with patch.object(publisher, "urlopen", side_effect=failure) as opening:
            with self.assertRaisesRegex(RuntimeError, "Oculum-Windows.*404"):
                publisher.verify_anonymous_download(dict(name="Oculum-Windows", url=url, bytes=100))
        opening.assert_called_once()

    def test_anonymous_archive_check_uses_release_asset_after_gateway_errors(self):
        class Response(BytesIO):
            status = 206
            headers = {"Content-Range": "bytes 0-3/100"}

        url = "https://github.com/package.zip"
        entry = dict(name="Oculum-Windows", url=url, bytes=100)
        failure = HTTPError(url, 504, "Gateway Timeout", {}, None)
        with patch.object(publisher, "urlopen", side_effect=[failure, failure, Response(b"PK\x03\x04")]) as opening, \
                patch.object(publisher, "time_ns", return_value=123), patch.object(publisher, "sleep"):
            publisher.verify_anonymous_download(entry, asset_id=42)

        request = opening.call_args.args[0]
        self.assertEqual(request.full_url,
                         f"https://api.github.com/repos/{publisher.REPO}/releases/assets/42?oculum_check=123")
        self.assertEqual(request.get_header("Accept"), "application/octet-stream")
        self.assertFalse(request.has_header("Authorization"))
        self.assertEqual(entry["url"], url)
