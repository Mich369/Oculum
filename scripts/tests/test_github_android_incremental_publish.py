from base64 import b64encode
from io import BytesIO
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch
from zipfile import ZipFile

from test_oculum_android_incremental_publish import add_block, apk_block, digest, make_zip

try:
    from scripts import publish_github_downloads as publisher
    # The tracked publisher stays frozen while the isolated draft is tested.
    if not hasattr(publisher, "prepare_android_incremental"):
        raise ImportError
except ImportError:
    import publish_github_downloads as publisher


REVISION = "a" * 40
TAG = "oculum-build-42"
RUN = {
    "id": 42, "run_number": 361, "workflow_id": 7, "head_branch": "main", "head_sha": REVISION,
    "name": "Build distribution", "status": "completed", "conclusion": "success",
    "repository": {"full_name": publisher.REPO}, "head_repository": {"full_name": publisher.REPO},
    "html_url": f"https://github.com/{publisher.REPO}/actions/runs/42",
}
WORKFLOW = {"name": "Build distribution", "path": ".github/workflows/build_distribution.yml"}
VERSION = 100361
PIN = "1" * 64


def uploaded(name, entry):
    return {"name": name, "state": "uploaded", "size": entry["bytes"],
            "digest": entry["sha256"], "browser_download_url": entry["url"]}


def web_response(body, status=200, headers=None):
    response = BytesIO(body)
    response.status = status
    response.headers = headers or {}
    return response


class AndroidReleaseTests(unittest.TestCase):
    def setUp(self):
        work = tempfile.TemporaryDirectory()
        self.addCleanup(work.cleanup)
        self.root = Path(work.name)
        self.data, _ = add_block(make_zip(), apk_block())
        self.wrapper = self.root / "Oculum-Android.zip"
        self.apk_member = "distribution/Oculum-Android-release.apk"
        with ZipFile(self.wrapper, "w") as artifact:
            artifact.writestr(self.apk_member, self.data)
            artifact.writestr("android-update-compatibility.json", "synthetic report")

    def prepare(self, **overrides):
        proof = {"signatureVerified": True, "versionCode": VERSION, "apkBytes": len(self.data),
                 "apkSha256": digest(self.data), **overrides}
        with patch.dict(publisher.os.environ, {"ANDROID_HOME": "fixture-sdk"}), \
                patch.object(publisher.shutil, "which", return_value="fixture-java"), \
                patch.object(publisher, "api", return_value={"content": b64encode(PIN.encode())}) as api, \
                patch.object(publisher.verify_android_signing, "verify_apk", return_value=proof) as verifier:
            result = publisher.prepare_android_incremental(self.wrapper, self.root, RUN)
        apk = self.root / publisher.ANDROID_APK_ASSET
        self.assertEqual(verifier.call_args.args[-2:], (PIN, VERSION))
        self.assertEqual(verifier.call_args.args[0], apk)
        self.assertIn(REVISION, api.call_args.args[0])
        self.assertEqual(apk.read_bytes(), self.data)
        return result

    def test_preparation_verifies_pinned_signature_and_exact_build_code(self):
        manifest, raw, entry = self.prepare()
        self.assertEqual(manifest["commit"], REVISION)
        self.assertEqual(manifest["runId"], RUN["id"])
        self.assertEqual(manifest["androidVersionCode"], VERSION)
        self.assertEqual(entry, {"artifact": "Oculum-Android", "edition": "android",
            "url": f"https://github.com/{publisher.REPO}/releases/download/{TAG}/{publisher.ANDROID_MANIFEST_ASSET}",
            "bytes": len(raw), "sha256": "sha256:" + digest(raw),
            "package": {**manifest["apk"], "sha256": "sha256:" + digest(self.data)},
        })
        self.assertEqual((self.root / publisher.ANDROID_MANIFEST_ASSET).read_bytes(), raw)

    def test_newer_signed_version_cannot_be_relabelled_for_run(self):
        with self.assertRaisesRegex(ValueError, "version does not match"):
            self.prepare(versionCode=VERSION+1)
        self.assertFalse((self.root / publisher.ANDROID_MANIFEST_ASSET).exists())

    def test_duplicate_expected_member_is_refused(self):
        with ZipFile(self.wrapper, "a") as artifact:
            artifact.writestr("Oculum-Android-release.apk", self.data)
        with self.assertRaisesRegex(ValueError, "exactly one release APK"):
            publisher.prepare_android_incremental(self.wrapper, self.root, RUN)

    def test_public_manifest_and_three_exact_ranges_are_downloaded_anonymously(self):
        manifest, raw, entry = self.prepare()
        requests = []

        def response_for(request, *, timeout):
            requests.append(request)
            self.assertFalse(request.has_header("Authorization"))
            self.assertGreater(timeout, 0)
            if request.full_url == entry["url"]:
                return web_response(raw)
            self.assertEqual(request.full_url, entry["package"]["url"])
            head = request.get_header("Range")
            start, end = map(int, head.removeprefix("bytes=").split("-"))
            return web_response(self.data[start:end+1], 206,
                                {"Content-Range": f"bytes {start}-{end}/{len(self.data)}"})

        with patch.object(publisher, "build_opener") as open_opener:
            open_opener.return_value.open.side_effect = response_for
            publisher.verify_public_android_incremental(manifest, raw, entry)
        self.assertEqual(len(requests), 4)
        self.assertEqual(len(set(request.get_header("Range") for request in requests[1:])), 3)

    def test_http_200_in_response_to_range_does_not_read_or_retry_full_apk(self):
        response = web_response(b"unexpected full APK")
        response.read = Mock(side_effect=AssertionError("must not read a full APK"))
        opener = Mock()
        opener.open.return_value = response
        with self.assertRaisesRegex(ValueError, "exact partial range"):
            publisher._android_public_asset(opener, "https://github.com/example", 1, "a"*64,
                                            position=0, apk_size=100)
        self.assertEqual(opener.open.call_count, 1)
        response.read.assert_not_called()

    def test_historical_android_opt_in_refuses_before_any_write(self):
        with patch.object(publisher, "resolve_run_id", side_effect=("42", "43")), \
                patch.object(publisher, "api", side_effect=(RUN, WORKFLOW)), \
                patch.object(publisher, "gh") as gh:
            with self.assertRaisesRegex(ValueError, "latest verified main build"):
                publisher.publish("42", android_incremental_updates=True)
        gh.assert_not_called()

    def test_disabled_keeps_full_artifacts_and_enabled_publishes_verified_pair(self):
        artifacts = [{"name": name, "id": identity, "size_in_bytes": 9, "expired": False,
                      "digest": "sha256:" + "1"*64}
                     for identity, name in enumerate(publisher.PUBLIC_ARTIFACTS, 1)]
        entries = [publisher.archive_entry(artifact, TAG) for artifact in artifacts]
        manifest, raw, android_entry = self.prepare()
        for enabled in (False, True):
            with self.subTest(enabled=enabled):
                self.assert_channel(entries, artifacts, (manifest, raw, android_entry), enabled)

    def assert_channel(self, entries, artifacts, android, enabled):
        downloaded = []
        written = []
        assets = [uploaded(item["name"] + ".zip", item) for item in entries]

        def api(location):
            if location.startswith("actions/runs/42/artifacts?"):
                return {"artifacts": artifacts}
            if location == "actions/runs/42":
                return RUN
            if location.startswith("actions/workflows/7/runs?"):
                return {"workflow_runs": [RUN]}
            if location == "actions/workflows/7":
                return WORKFLOW
            raise AssertionError(location)

        def release(tag):
            if tag == TAG:
                return dict(tag_name=TAG, draft=False, target_commitish=REVISION, assets=assets)
            self.assertEqual(tag, publisher.CHANNEL)
            return None

        def gh(command, action, tag, *args, **_kwargs):
            self.assertEqual(command, "release")
            if action == "upload":
                name = Path(args[0]).name
                self.assertEqual(tag, TAG)
                entry = android[2]["package"] if name == publisher.ANDROID_APK_ASSET else android[2]
                assets.append(uploaded(name, entry))
            else:
                self.assertEqual((action, tag), ("create", publisher.CHANNEL))
                note = Path(args[args.index("--notes-file")+1]).read_text(encoding="utf-8")
                written.append(publisher.read_catalog(note)["7"])

        def download(artifact, entry, path):
            self.assertEqual(artifact["name"], "Oculum-Android")
            self.assertEqual(entry["name"], artifact["name"])
            path.write_bytes(b"fixture")
            downloaded.append(path.name)

        with patch.object(publisher, "resolve_run_id", return_value="42"), \
                patch.object(publisher, "api", side_effect=api), \
                patch.object(publisher, "gh", side_effect=gh), \
                patch.object(publisher, "release", side_effect=release), \
                patch.object(publisher, "download_verified_archive", side_effect=download), \
                patch.object(publisher, "read_update_notes", return_value=[]), \
                patch.object(publisher, "prepare_android_incremental", return_value=android) as prepare, \
                patch.object(publisher, "verify_public_android_incremental") as checked, \
                patch.object(publisher, "verify_anonymous_download") as checked_full:
            publisher.publish("42", android_incremental_updates=enabled)
        self.assertEqual(checked_full.call_count, len(publisher.PUBLIC_ARTIFACTS))
        self.assertEqual(prepare.call_count, int(enabled))
        self.assertEqual(checked.call_count, int(enabled))
        self.assertEqual(downloaded, ["Oculum-Android.zip"] if enabled else [])
        self.assertEqual(written[0]["incremental"], [android[2]] if enabled else [])
        self.assertEqual(written[0]["artifacts"], entries)


if __name__ == "__main__":
    unittest.main()
