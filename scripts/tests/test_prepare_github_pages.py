import importlib.util
from pathlib import Path
import tempfile
import unittest
import warnings
import zipfile


spec = importlib.util.spec_from_file_location(
    "prepare_pages", Path(__file__).parents[1] / "prepare_github_pages.py"
)
prepare_pages = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare_pages)


class PreparePagesTests(unittest.TestCase):
    def setUp(self):
        temp_parent = Path(__file__).parents[2] / "build" / "pages-test-tmp"
        temp_parent.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=temp_parent)
        self.root = Path(self.temp.name)
        self.commit = "a" * 40
        self.archive = self.root / "Oculum-Web.zip"

    def tearDown(self):
        self.temp.cleanup()

    def write_archive(self, extra=None, *, base="/Oculum/", stamp=None):
        stamp = stamp if stamp is not None else self.commit
        with zipfile.ZipFile(self.archive, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
            bundle.writestr("index.html", f'<base href="{base}"> {stamp}')
            bundle.writestr("flutter_bootstrap.js", f"?v={stamp}")
            bundle.writestr("main.dart.js", "compiled")
            bundle.writestr("assets/AssetManifest.bin", b"assets")
            for name, data in (extra or {}).items():
                bundle.writestr(name, data)

    def test_extracts_only_a_committed_pages_bundle(self):
        self.write_archive()
        target = self.root / "pages"

        count = prepare_pages.prepare(self.archive, target, self.commit)

        self.assertEqual(count, 4)
        self.assertEqual((target / "main.dart.js").read_text(), "compiled")
        self.assertEqual((target / "assets/AssetManifest.bin").read_bytes(), b"assets")

    def test_rejects_a_bundle_for_another_commit_or_pages_path(self):
        self.write_archive(stamp="b" * 40)
        with self.assertRaisesRegex(ValueError, "commit stamp"):
            prepare_pages.prepare(self.archive, self.root / "wrong-commit", self.commit)

        self.write_archive(base="/")
        with self.assertRaisesRegex(ValueError, "Pages path"):
            prepare_pages.prepare(self.archive, self.root / "wrong-path", self.commit)

    def test_rejects_path_traversal_duplicate_and_symlink_entries(self):
        for name, message in [("../outside", "Unsafe ZIP entry"),
                              ("index.html", "Duplicate ZIP entry"),
                              ("escape", "Symbolic links")]:
            with self.subTest(name=name):
                self.write_archive()
                with zipfile.ZipFile(self.archive, "a") as bundle:
                    if name == "escape":
                        info = zipfile.ZipInfo(name)
                        info.create_system = 3
                        info.external_attr = (0o120777 << 16)
                        bundle.writestr(info, "../outside")
                    else:
                        with warnings.catch_warnings():
                            warnings.simplefilter("ignore", UserWarning)
                            bundle.writestr(name, "bad")
                with self.assertRaisesRegex(ValueError, message):
                    prepare_pages.prepare(self.archive, self.root / f"bad-{name.replace('/', '-')}", self.commit)

    def test_requires_empty_destination(self):
        self.write_archive()
        target = self.root / "pages"
        target.mkdir()
        (target / "old.txt").write_text("preserve")

        with self.assertRaisesRegex(ValueError, "must be empty"):
            prepare_pages.prepare(self.archive, target, self.commit)
        self.assertEqual((target / "old.txt").read_text(), "preserve")


if __name__ == "__main__":
    unittest.main()
