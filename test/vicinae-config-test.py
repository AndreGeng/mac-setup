#!/usr/bin/env python3
"""Vicinae settings tests use temporary directories only."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('vicinae_config', ROOT / 'scripts/configure-vicinae.py')
config = importlib.util.module_from_spec(spec)
spec.loader.exec_module(config)


class ConfigTests(unittest.TestCase):
    def test_new_config_and_idempotence(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'vicinae/settings.json'
            config.configure(path, ROOT / 'config/vicinae/settings.json')
            first = path.read_bytes()
            self.assertEqual(json.loads(first)['global_shortcuts']['toggle'], 'control+[')
            config.configure(path, ROOT / 'config/vicinae/settings.json')
            self.assertEqual(path.read_bytes(), first)

    def test_jsonc_preserves_other_settings(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'settings.json'
            path.write_text('''// upstream header
            {"imports": ["personal.json",], /* keep values */
             "url": "https://example.org/a//b", "theme": {"name": "custom"},
             "global_shortcuts": {"toggle": "alt+space", "other": "alt+x"},}''')
            config.configure(path, ROOT / 'config/vicinae/settings.json')
            result = json.loads(path.read_text())
            self.assertEqual(result['imports'], ['personal.json'])
            self.assertEqual(result['url'], 'https://example.org/a//b')
            self.assertEqual(result['theme']['name'], 'custom')
            self.assertEqual(result['global_shortcuts']['other'], 'alt+x')
            self.assertEqual(result['global_shortcuts']['toggle'], 'control+[')

    def test_unchanged_jsonc_not_reformatted(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'settings.json'
            original = '// keep comment\n{"global_shortcuts":{"toggle":"control+["}}\n'
            path.write_text(original)
            config.configure(path, ROOT / 'config/vicinae/settings.json')
            self.assertEqual(path.read_text(), original)

    def test_bad_settings_leave_original_untouched(self):
        for original in ('broken', '[]', '{"global_shortcuts":null}'):
            with self.subTest(original=original), tempfile.TemporaryDirectory() as temp:
                path = Path(temp) / 'settings.json'
                path.write_text(original)
                with self.assertRaises(ValueError):
                    config.configure(path, ROOT / 'config/vicinae/settings.json')
                self.assertEqual(path.read_text(), original)


if __name__ == '__main__':
    unittest.main()
