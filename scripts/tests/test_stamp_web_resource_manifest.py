from pathlib import Path
from tempfile import TemporaryDirectory
import hashlib
import json
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from stamp_oculum_web import MAX_CACHE_FILE_BYTES, stamp_web_version


class WebResourceManifestTests(unittest.TestCase):
    def test_stamped_build_records_only_versioned_public_runtime_files(self):
        commit = "a" * 40
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            for filename in ["index.html", "flutter_bootstrap.js"]:
                (root / filename).write_text("__OCULUM_BUILD__", encoding="utf-8")
            for name, data in {
                "main.dart.js": b"code",
                "main.dart.js_1.part.js": b"deferred",
                "main.dart.wasm": b"wasm",
                "assets/oculum/Re Goblin.webp": b"art",
                "canvaskit/chromium/canvaskit.wasm": b"engine",
                "oculum_resource_worker.js": b"worker",
                "oculum_passkeys.js": b"access",
                "oculum-data.json": b"other",
                "private/campaign.json": b"excluded example",
            }.items():
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
            with (root / "assets/oversized.bin").open("wb") as oversized:
                oversized.truncate(MAX_CACHE_FILE_BYTES + 1)
            stamp_web_version(root, commit)
            marker = json.loads((root / "oculum-build.json").read_text(encoding="utf-8"))
            result = json.loads((root / "oculum-resources.json").read_text(encoding="utf-8"))
            self.assertEqual(result["commit"], marker["commit"])
            self.assertEqual(set(result["files"]), {
                "main.dart.js", "main.dart.js_1.part.js", "main.dart.wasm",
                "assets/oculum/Re%20Goblin.webp", "canvaskit/chromium/canvaskit.wasm",
            })
            self.assertEqual(result["files"]["assets/oculum/Re%20Goblin.webp"], [
                hashlib.sha256(b"art").hexdigest(), 3,
            ])


if __name__ == "__main__":
    unittest.main()
