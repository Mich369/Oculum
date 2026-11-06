"""Exercise the exporter with both formatter layouts instead of copying its regex."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
EXPORTER = ROOT / 'scripts/export_manual_reference.dart'
flutter_root = os.environ.get('FLUTTER_ROOT')
dart_candidates = [
    Path(flutter_root) / 'bin/cache/dart-sdk/bin/dart.exe' if flutter_root else None,
    Path(r'C:\Users\michy\flutter\bin\cache\dart-sdk\bin\dart.exe'),
    Path(shutil.which('dart') or '__missing_dart__'),
]
DART = next((path for path in dart_candidates if path and path.is_file()), None)


@unittest.skipUnless(DART, 'Dart SDK is required for the real standalone exporter')
class ExportManualReferenceTest(unittest.TestCase):
    def export(self, source):
        with tempfile.TemporaryDirectory(prefix='manual-export-', dir=ROOT / 'build') as folder:
            temp = Path(folder)
            target = temp / 'lib/src/main/oculum_manual_sections.dart'
            target.parent.mkdir(parents=True)
            (temp / 'docs').mkdir()
            target.write_text(source, encoding='utf-8')
            result = subprocess.run([str(DART), str(EXPORTER)], cwd=temp,
                                    capture_output=True, text=True, encoding='utf-8', timeout=60)
            output = temp / 'docs/manuale-consultazione.md'
            return result, output.read_text(encoding='utf-8') if output.exists() else None

    def test_formatter_wrapped_titles_keep_every_section_and_accent(self):
        source = """
ManualSection(titleIt: 'Titolo breve', titleEn: 'Short', contentIt: r'''Prima sezione.''', contentEn: r'''First.'''),
ManualSection(
  titleIt:
      'Titolo molto lungo — capacità e più dettagli',
  titleEn: 'Long',
  contentIt: r'''Seconda sezione con Vita, Open e difesa.''',
  contentEn: r'''Second.''',
),
"""
        result, output = self.export(source)
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertIn('Exported 2 complete manual sections.', result.stdout)
        self.assertIn('## Titolo breve', output)
        self.assertIn('## Titolo molto lungo — capacità e più dettagli', output)
        self.assertIn('Seconda sezione con Vita, Open e difesa.', output)

    def test_incomplete_parse_fails_instead_of_silently_truncating_manual(self):
        result, output = self.export("ManualSection(titleIt: 'Incomplete', contentEn: r'''Only English''')")
        self.assertNotEqual(0, result.returncode)
        self.assertIn('Manual export incomplete', result.stderr)
        self.assertIsNone(output)


if __name__ == '__main__':
    unittest.main()
