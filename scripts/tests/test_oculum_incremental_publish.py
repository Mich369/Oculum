"""Exercise the Windows ZIP-range publisher without touching installed files."""

import hashlib
import importlib.util
from io import BytesIO
from pathlib import Path
import stat
import struct
import tempfile
import unittest
from unittest.mock import MagicMock, patch
import warnings
import zipfile
import zlib


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "oculum_incremental_publish", ROOT / "scripts/oculum_incremental_publish.py",
)
PUBLISH = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PUBLISH)
COMMIT = "a" * 40
RUN_ID = 10001
ASSETS = {
    "flutter_windows.dll": b"flutter runtime",
    "WebView2Loader.dll": b"webview loader",
    "data/app.so": b"app" * 500,
    "data/icudtl.dat": b"international data",
    "data/flutter_assets/AssetManifest.bin": b"flutter manifest",
    "data/flutter_assets/mappa-à.webp": bytes(range(100)),
    "data/flutter_assets/empty.marker": b"",
}


class NonSeekableZip(BytesIO):
    def seek(self, *args):
        raise OSError("ZIP writer must use data descriptors")


class WindowsIncrementalPublishTests(unittest.TestCase):
    def setUp(self):
        build = ROOT / "build"
        build.mkdir(exist_ok=True)
        fixture = self.enterContext(tempfile.TemporaryDirectory(prefix="range-index-", dir=build))
        self.archive = Path(fixture) / "windows.zip"

    def package(self, edition="normal"):
        name = "Oculum-Windows" if edition == "normal" else "Oculum-Test-Windows"
        return {
            "name": name + "-Folder",
            "url": f"https://github.com/Mich369/Oculum/releases/download/oculum-build-{RUN_ID}/{name}-Folder.zip",
            "bytes": self.archive.stat().st_size,
            "sha256": "sha256:" + hashlib.sha256(self.archive.read_bytes()).hexdigest(),
        }

    def index(self, edition="normal", package=None, commit=COMMIT):
        return PUBLISH.build_windows_range_manifest(
            self.archive, edition=edition, commit=commit, run_id=RUN_ID,
            package=self.package(edition) if package is None else package,
        )

    def make_archive(self, edition="normal", prefix="", extra=(), assets=None, stream=None):
        exe = "oculum.exe" if edition == "normal" else "Oculum-Test.exe"
        files = {exe: b"test Windows executable", **(ASSETS if assets is None else assets)}
        with zipfile.ZipFile(self.archive if stream is None else stream, "w") as archive:
            if prefix:
                archive.writestr(prefix, b"")
            for path, raw in files.items():
                member = zipfile.ZipInfo(prefix + path)
                if path == "data/app.so":
                    member.compress_type = zipfile.ZIP_DEFLATED
                    member.extra = struct.pack("<HH4s", 0xCAFE, 4, b"maps")
                    with archive.open(member, "w", force_zip64=True) as output:
                        output.write(raw)
                else:
                    archive.writestr(member, raw)
            for path, raw in extra:
                archive.writestr(path, raw)
        if stream is not None:
            self.archive.write_bytes(stream.getvalue())
        return files

    def assert_disjoint_payload_bytes(self, manifest, files):
        source = self.archive.read_bytes()
        self.assertEqual(sorted(files), [member["path"] for member in manifest["files"]])
        span_end = 0
        for member in sorted(manifest["files"], key=lambda entry: entry["offset"]):
            start = member["offset"]
            offset_end = start + member["compressedBytes"]
            self.assertGreater(start, span_end)
            payload = source[start:offset_end]
            raw = zlib.decompress(payload, -15) if member["method"] == 8 else payload
            self.assertEqual(raw, files[member["path"]])
            self.assertEqual(member["bytes"], len(raw))
            self.assertEqual(member["sha256"], hashlib.sha256(raw).hexdigest())
            span_end = offset_end

    def test_indexes_windows_paths_and_real_store_deflate_and_zip64_ranges(self):
        with patch.object(zipfile, "ZIP64_LIMIT", 256):
            files = self.make_archive()
        manifest = self.index()
        self.assertIn(b"PK\x06\x06", self.archive.read_bytes())
        self.assertEqual(manifest["schemaVersion"], 1)
        self.assertEqual(manifest["platform"], "windows")
        self.assertEqual(manifest["edition"], "normal")
        self.assertEqual(manifest["commit"], COMMIT)
        self.assertEqual(manifest["runId"], RUN_ID)
        self.assertEqual(manifest["package"]["sha256"], self.package()["sha256"][7:])
        self.assertEqual(PUBLISH.windows_manifest_asset_name("normal"), "Oculum-Windows-Incrementale.json")
        self.assert_disjoint_payload_bytes(manifest, files)
        expected = PUBLISH.serialize_windows_range_manifest(manifest)
        self.assertEqual(expected, PUBLISH.serialize_windows_range_manifest(self.index()))
        self.assertEqual(expected.count(b"\n"), 1)

    def test_prefixed_test_edition_preserves_data_descriptor_ranges(self):
        files = self.make_archive("test", "Windows Test/", stream=NonSeekableZip())
        manifest = self.index("test")
        self.assertEqual(manifest["edition"], "test")
        self.assertEqual(PUBLISH.windows_manifest_asset_name("test"), "Oculum-Test-Windows-Incrementale.json")
        with zipfile.ZipFile(self.archive) as archive:
            self.assertTrue(archive.getinfo("Windows Test/Oculum-Test.exe").flag_bits & 8)
        self.assert_disjoint_payload_bytes(manifest, files)
        with self.assertRaisesRegex(ValueError, "Missing normal Windows runtime"):
            self.index("normal")

    def test_skips_intermediate_builds_and_only_requests_changed_or_missing_files(self):
        old_files = dict(ASSETS)
        old_files["data/app.so"] = b"old" * 500  # Includes a same-size content change.
        old_files.pop("data/flutter_assets/mappa-à.webp")
        old_files["data/flutter_assets/obsolete.webp"] = b"removed from new build"
        previous = {name: (len(raw), hashlib.sha256(raw).hexdigest())
                    for name, raw in self.make_archive(assets=old_files).items()}
        self.make_archive()
        manifest = self.index()
        mismatches = [entry["path"] for entry in manifest["files"]
                      if (entry["bytes"], entry["sha256"]) != previous.get(entry["path"])]
        self.assertEqual(mismatches, ["data/app.so", "data/flutter_assets/mappa-à.webp"])
        self.assertFalse(any(entry["path"].endswith("obsolete.webp") for entry in manifest["files"]))

    def test_rejects_archive_mismatch_and_untrusted_public_identity(self):
        self.make_archive()
        package = self.package()
        for key, value in {
            "bytes": package["bytes"] - 1,
            "sha256": "0" * 64,
            "url": package["url"].replace("github.com", "download.example"),
        }.items():
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.index(package={**package, key: value})
        with self.assertRaisesRegex(ValueError, "build commit"):
            self.index(commit="a" * 7)

    def test_rejects_paths_windows_cannot_copy_safely(self):
        for path in ("../outside", "data/../escape", "/rooted", "data/stream:alternate", "C:/rooted",
                     "data/AUX.txt", "data/COM¹.txt", "data/name ", "data/name.", "data//part", "data\\entry"):
            with self.subTest(path=path):
                # ZipInfo normalizes backslashes on Windows. Replace the same-length name
                # in both ZIP headers to exercise what a cross-platform producer can send.
                if "\\" in path:
                    self.make_archive(extra=[(path.replace("\\", "_"), b"unsafe")])
                    self.archive.write_bytes(self.archive.read_bytes().replace(b"data_entry", b"data\\entry"))
                else:
                    self.make_archive(extra=[(path, b"unsafe")])
                with self.assertRaisesRegex(ValueError, "Unsafe Windows ZIP path"):
                    self.index()

    def test_rejects_case_aliases_duplicate_files_and_edition_mixing(self):
        for path, error in (
            ("data/app.so", "Duplicate"), ("DATA/APP.SO", "Duplicate"),
            ("DATA/added.bin", "Conflicting"), ("data", "Conflicting"),
            ("Oculum-Test.exe", "another edition"), ("Windows Test/Oculum-Test.exe", "another edition"),
        ):
            with self.subTest(path=path), warnings.catch_warnings():
                warnings.simplefilter("ignore", UserWarning)
                self.make_archive(extra=[(path, b"different")])
                with self.assertRaisesRegex(ValueError, error):
                    self.index()
        self.make_archive(prefix="Windows/", extra=[("other/path", b"outside")])
        with self.assertRaisesRegex(ValueError, "outside the selected Windows folder"):
            self.index()

    def test_rejects_symlinks_bad_local_headers_and_corrupted_stored_data(self):
        link = zipfile.ZipInfo("data/local-link")
        link.create_system = 3
        link.external_attr = (stat.S_IFLNK | 0o777) << 16
        self.make_archive(extra=[(link, b"existing")])
        with self.assertRaisesRegex(ValueError, "member type"):
            self.index()
        self.make_archive()
        payload = bytearray(self.archive.read_bytes())
        payload[8] = 8  # Stored method in the central directory, deflated locally.
        self.archive.write_bytes(payload)
        with self.assertRaisesRegex(ValueError, "local header disagrees"):
            self.index()
        self.make_archive()
        self.archive.write_bytes(self.archive.read_bytes().replace(b"flutter runtime", b"FLTTER runtime!"))
        with self.assertRaisesRegex(zipfile.BadZipFile, "CRC"):
            self.index()

    def test_compressed_archive_inside_archive_remains_only_a_complete_download(self):
        self.make_archive()
        inner_zip = self.archive.read_bytes()
        with zipfile.ZipFile(self.archive, "w", compression=zipfile.ZIP_DEFLATED) as outer:
            outer.writestr("Oculum-Windows.zip", inner_zip)
        with self.assertRaisesRegex(ValueError, "direct folder ZIP"):
            self.index()

    def test_anonymous_remote_probes_check_member_body_status_and_content_range(self):
        self.make_archive()
        manifest = self.index()
        archive = self.archive.read_bytes()

        def sample(request, timeout):
            self.assertNotIn("Authorization", request.headers)
            self.assertEqual(request.full_url, self.package()["url"])
            start, end = map(int, request.headers["Range"].removeprefix("bytes=").split("-"))
            self.assertGreater(start, 30)
            self.assertLessEqual(end - start + 1, 16)
            reply = BytesIO(archive[start:end+1])
            reply.status = 206
            reply.headers = {"Content-Range": f"bytes {start}-{end}/{len(archive)}"}
            return reply

        opener = MagicMock()
        opener.open.side_effect = sample
        with patch.object(PUBLISH, "build_opener", return_value=opener):
            PUBLISH.verify_public_archive_ranges(manifest, self.archive)
            self.assertEqual(opener.open.call_count, 2)
            for status, headers, raw in (
                (200, {}, b"any bytes"), (206, {"Content-Range": "bytes 0-15/0"}, b"partial"),
                (206, None, b"unexpected"),
            ):
                with self.subTest(status=status, headers=headers):
                    def invalid(request, timeout):
                        response = sample(request, timeout)
                        modified = BytesIO(raw)
                        modified.status = status
                        modified.headers = response.headers if headers is None else headers
                        return modified
                    opener.open.side_effect = invalid
                    with self.assertRaisesRegex(ValueError, "Public Windows member range differs"):
                        PUBLISH.verify_public_archive_ranges(manifest, self.archive)


if __name__ == "__main__":
    unittest.main()
