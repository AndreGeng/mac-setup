#!/usr/bin/env python3
"""Offline configuration tests; never read or write the real HOME."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('toshy_config', ROOT / 'scripts/configure-toshy.py')
config = importlib.util.module_from_spec(spec)
spec.loader.exec_module(config)


def fixture():
    return '\n'.join(
        f'###  SLICE_MARK_START: {region}  ###  EDITS OUTSIDE THESE MARKS WILL BE LOST ON UPGRADE\n'
        '# personal settings\npersonal = True\n'
        f'###  SLICE_MARK_END: {region}  ###  EDITS OUTSIDE THESE MARKS WILL BE LOST ON UPGRADE'
        for region in config.REGIONS
    ) + '\n'


class ConfigurationTests(unittest.TestCase):
    def test_migrates_old_virtual_navigation_carrier(self):
        template = (ROOT / 'config/toshy/legacy/user_custom_modmaps.py').read_text()
        old = template.replace('Key.F24', 'Key.V_FAKEY').replace(
            '}, when=lambda ctx: cnfg.screen_has_focus)',
            '}, when=lambda ctx: cnfg.screen_has_focus and "ghostty" not in ctx.wm_class.casefold())',
            1)
        original = fixture().replace('###  SLICE_MARK_END: user_custom_modmaps',
                                     old + '\n###  SLICE_MARK_END: user_custom_modmaps')
        updated = config.merge_toshy(original, ROOT / 'config/toshy')
        self.assertNotIn('Key.V_FAKEY', updated)
        self.assertNotIn('add_modifier(', updated)
        self.assertNotIn('Key.D:', updated)
        self.assertNotIn('"ghostty" not in ctx.wm_class', updated)

    def test_migrates_navigation_without_space_fallback(self):
        template = (ROOT / 'config/toshy/legacy/user_apps.py').read_text()
        old = template.replace('    C("DNav-Space"): [C("d"), C("Space")],\n', '')
        original = fixture().replace('###  SLICE_MARK_END: user_apps',
                                     old + '\n###  SLICE_MARK_END: user_apps')
        updated = config.merge_toshy(original, ROOT / 'config/toshy')
        self.assertNotIn('DNav', updated)

    def test_d_is_not_a_modifier(self):
        template = (ROOT / 'config/toshy/user_custom_modmaps.py').read_text()
        self.assertNotIn('Key.D:', template)
        self.assertNotIn('DNav', (ROOT / 'config/toshy/user_apps.py').read_text())

    def test_preserves_personal_config_and_is_idempotent(self):
        updated = config.merge_toshy(fixture(), ROOT / 'config/toshy')
        self.assertEqual(updated, config.merge_toshy(updated, ROOT / 'config/toshy'))
        self.assertEqual(updated.count('personal = True'), 2)
        self.assertNotIn('DNav', updated)
        self.assertIn('Key.CAPSLOCK: [Key.ESC, Key.LEFT_CTRL]', updated)
        self.assertIn('fcitx5-remote', updated)
        self.assertEqual(updated.count('keymap("User Vicinae Ctrl bracket launcher"'), 1)
        self.assertIn('C("Super-Left_Brace"): C("LC-Left_Brace")', updated)
        self.assertNotIn('C("LC-Space")', updated)

    def test_migrates_previous_manual_settings(self):
        original = fixture()
        for region in config.REGIONS:
            template = (ROOT / 'config/toshy' / f'{region}.py').read_text()
            marker = f'###  SLICE_MARK_END: {region}'
            original = original.replace(marker, template + '\n' + marker)
        updated = config.merge_toshy(original, ROOT / 'config/toshy')
        self.assertNotIn('add_modifier(', updated)
        self.assertEqual(updated.count('def user_toggle_fcitx('), 1)

    def test_migrates_old_cmd_space_mapping(self):
        original = fixture().replace('# personal settings',
            'keymap("User Cmd Space input method", {\n'
            ' C("RC-Space"): [bind, C("LC-Space")],\n'
            '}, when=lambda ctx: cnfg.screen_has_focus and not ctx_app_is_remote)\n', 1)
        updated = config.merge_toshy(original, ROOT / 'config/toshy')
        self.assertEqual(updated.count('keymap("User Cmd Space input method"'), 1)
        self.assertNotIn('C("LC-Space")', updated)

    def test_unknown_config_refused(self):
        with self.assertRaises(ValueError):
            config.merge_toshy('unrelated = True\n', ROOT / 'config/toshy')
        with self.assertRaises(ValueError):
            config.merge_toshy(fixture() + fixture(), ROOT / 'config/toshy')

    def test_conflicting_personal_mapping_refused(self):
        original = fixture().replace('# personal settings',
            'add_modifier("USER_D_NAV", aliases=["Other"], key=Key.F23)')
        with self.assertRaises(ValueError):
            config.merge_toshy(original, ROOT / 'config/toshy')

    def test_fcitx_preserves_other_bindings_and_settings(self):
        original = '[Behavior]\nActiveByDefault=True\n[Hotkey/TriggerKeys]\n0=Control+space\n1=Zenkaku_Hankaku\n[Other]\nValue=1\n'
        updated = config.remove_ctrl_space(original)
        self.assertNotIn('Control+space', updated)
        self.assertIn('0=Zenkaku_Hankaku', updated)
        self.assertIn('[Other]\nValue=1', updated)
        self.assertEqual(updated, config.remove_ctrl_space(updated))
        self.assertEqual(config.remove_ctrl_space(''), '[Hotkey/TriggerKeys]\n')

    def test_failed_validation_restores_both_files(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            toshy = home / '.config/toshy/toshy_config.py'
            toshy.parent.mkdir(parents=True)
            toshy.write_text(fixture())
            with patch.object(config, 'validate', side_effect=RuntimeError('check failed')):
                with self.assertRaises(RuntimeError):
                    config.configure(home, ROOT / 'config/toshy')
            self.assertEqual(toshy.read_text(), fixture())
            self.assertFalse((home / '.config/fcitx5/config').exists())

    def test_failed_validation_preserves_existing_fcitx(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            toshy = home / '.config/toshy/toshy_config.py'
            fcitx = home / '.config/fcitx5/config'
            toshy.parent.mkdir(parents=True)
            fcitx.parent.mkdir(parents=True)
            toshy.write_text(fixture())
            original = '[Hotkey/TriggerKeys]\n0=Control+space\n'
            fcitx.write_text(original)
            with patch.object(config, 'validate', side_effect=RuntimeError('check failed')):
                with self.assertRaises(RuntimeError):
                    config.configure(home, ROOT / 'config/toshy')
            self.assertEqual(fcitx.read_text(), original)

    def test_success_and_unchanged_run(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            toshy = home / '.config/toshy/toshy_config.py'
            toshy.parent.mkdir(parents=True)
            toshy.write_text(fixture())
            with patch.object(config, 'validate') as check:
                self.assertTrue(config.configure(home, ROOT / 'config/toshy'))
                check.assert_called_once()
                self.assertFalse(config.configure(home, ROOT / 'config/toshy'))
            self.assertEqual((home / '.config/fcitx5/config').read_text(), '[Hotkey/TriggerKeys]\n')


if __name__ == '__main__':
    unittest.main()
