"""Read-only path/alias regression tests; no historical artwork is rewritten."""
import ast
from contextlib import ExitStack
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).absolute().parents[2]
SPEC = importlib.util.spec_from_file_location('oculum_artwork_paths', ROOT / 'scripts/oculum_artwork_paths.py')
PATHS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PATHS)
HELPERS = (
    'output/artwork/alternative_mostri_2026-11-05/aggiorna_alternative.py',
    'output/artwork/mostri_2026-11-04/aggiorna_galleria.py',
    'output/artwork/audit_approved_runtime_copies.py',
    'output/artwork/refresh_creature_art_backlog.py',
)


@unittest.skipUnless(os.name == 'nt', 'Windows artwork-junction path tests')
class ArtworkPathTests(unittest.TestCase):
    def test_repository_root_rejects_missing_markers(self):
        (ROOT / 'build').mkdir(exist_ok=True)
        fixture = tempfile.TemporaryDirectory(prefix='art-paths-', dir=ROOT / 'build')
        fixture_path = Path(fixture.name).resolve()
        self.assertTrue(fixture_path.is_relative_to((ROOT / 'build').resolve()))
        try:
            (fixture_path / 'lib').mkdir()
            (fixture_path / 'docs').mkdir()
            with self.assertRaisesRegex(ValueError, 'scripts'):
                PATHS.repository_root(fixture_path)
        finally:
            # The generated fixture is confined to build before recursive cleanup.
            fixture.cleanup()

    @unittest.skipUnless(all((ROOT / p).is_file() for p in HELPERS), 'Local artwork helpers are not present in this checkout')
    def test_c_and_physical_aliases_keep_the_same_project_and_folder(self):
        for relative in HELPERS:
            logical = ROOT / relative
            for alias in (logical, logical.resolve()):
                with self.subTest(helper=relative, alias=alias):
                    paths = PATHS.artwork_paths(alias)
                    self.assertEqual(paths.root, ROOT)
                    self.assertEqual(paths.script, logical)
                    self.assertEqual(paths.folder, logical.parent)
                    self.assertTrue(os.path.samefile(paths.script, alias))

    def test_external_native_original_is_not_remapped(self):
        external = Path(r'G:\Oculum-Artwork\proposte_C_2026-11-06\original.png')
        paths = PATHS.artwork_paths(ROOT / HELPERS[0])
        self.assertEqual(paths.logical(external), external)
        self.assertEqual(paths.reference(external), str(external))

    def test_physical_parent_comparison_accepts_alias_and_rejects_sibling(self):
        paths = PATHS.artwork_paths(ROOT / HELPERS[0])
        image = paths.folder / 'alato_carne_desktop_v1.jpg'
        self.assertTrue(paths.same_folder(image))
        self.assertTrue(paths.same_folder(image.resolve()))
        self.assertFalse(paths.same_folder(paths.artwork / 'another-folder/image.png'))

    def test_relative_url_and_manifest_reference_match_on_both_aliases(self):
        paths = PATHS.artwork_paths(ROOT / HELPERS[0])
        image = paths.folder / 'alato_carne_desktop_v1.jpg'
        for alias in (image, image.resolve()):
            with self.subTest(alias=alias):
                self.assertEqual(paths.relative_url(alias), image.name)
                self.assertEqual(paths.reference(alias), image.relative_to(ROOT).as_posix())

    def test_dot_segments_are_normalized_without_changing_logical_drive(self):
        value = ROOT / 'output/artwork/alternative_mostri_2026-11-05/../alternative_mostri_2026-11-05'
        self.assertEqual(PATHS.logical_path(value), ROOT / 'output/artwork/alternative_mostri_2026-11-05')

    def test_helper_outside_artwork_tree_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'outside'):
            PATHS.artwork_paths(ROOT / 'scripts/build_artwork_review_queue.py')

    @unittest.skipUnless(all((ROOT / p).is_file() for p in HELPERS), 'Local artwork helpers are not present in this checkout')
    def test_all_helper_bootstraps_are_read_only_and_alias_independent(self):
        # Execute only imports, the resolver bootstrap and path assignments.
        # The runtime-copy/backlog entrypoints have broad top-level writes and
        # must not be imported in full merely to test their root discovery.
        def reject_write(*args, **kwargs):
            raise AssertionError('Path bootstrap attempted a filesystem mutation')

        for relative in HELPERS:
            source = ROOT / relative
            tree = ast.parse(source.read_text(encoding='utf-8'))
            prefix = []
            for node in tree.body:
                if isinstance(node, ast.ImportFrom) and node.module == 'pathlib':
                    prefix.append(node)
                elif isinstance(node, ast.Import) and all(a.name in {'os', 'runpy'} for a in node.names):
                    prefix.append(node)
                elif isinstance(node, ast.For) and isinstance(node.target, ast.Name) and node.target.id == '_bootstrap_root':
                    prefix.append(node)
                elif isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id in {'ROOT', 'FOLDER', 'ART'} for t in node.targets):
                    prefix.append(node)
            for alias in (source, source.resolve()):
                with self.subTest(helper=relative, alias=alias), ExitStack() as guard:
                    for name in ('write_text', 'write_bytes', 'mkdir', 'unlink', 'rename', 'replace'):
                        guard.enter_context(patch.object(Path, name, side_effect=reject_write))
                    guard.enter_context(patch.object(Path, 'cwd', return_value=(ROOT / 'output/artwork').resolve().parents[1]))
                    guard.enter_context(patch.dict(os.environ, {}, clear=False))
                    os.environ.pop('OCULUM_PROJECT_ROOT', None)
                    namespace = {'Path': Path, '__file__': str(alias)}
                    exec(compile(ast.Module(body=prefix, type_ignores=[]), str(alias), 'exec'), namespace)
                    self.assertEqual(namespace['ROOT'], ROOT)
                    if 'FOLDER' in namespace:
                        self.assertEqual(namespace['FOLDER'], source.parent)
                    if 'ART' in namespace:
                        self.assertEqual(namespace['ART'], ROOT / 'output/artwork')


if __name__ == '__main__':
    unittest.main()
