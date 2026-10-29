#!/usr/bin/env python3
"""Replay keys offline through xwaykeyz; never connect to input devices or the desktop."""
from pathlib import Path
from collections import Counter
from types import SimpleNamespace
import unittest
from unittest.mock import patch

try:
    from evdev import InputEvent, ecodes
    from xwaykeyz.lib.window_context import WindowContextProviderInterface
    with patch.object(WindowContextProviderInterface, 'make_provider'):
        from xwaykeyz import config_api, output, transform
    from xwaykeyz.models.key import Key
except ImportError:
    Key = None

ROOT = Path(__file__).resolve().parents[1]


class Sink:
    def __init__(self):
        self.events = []

    def write(self, event_type, code, value):
        if event_type == ecodes.EV_KEY:
            self.events.append((Key(code), int(value)))

    def syn(self):
        pass

    def write_event(self, event):
        self.write(event.type, event.code, event.value)


@unittest.skipIf(Key is None, 'Run with the Toshy Python runtime for event replay')
class EventTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        config_api.reset_configuration()
        namespace = dict(vars(config_api), cnfg=SimpleNamespace(screen_has_focus=True),
                         ctx_app_is_remote=False)
        for region in ('user_custom_modmaps', 'user_apps'):
            exec((ROOT / 'config/toshy' / f'{region}.py').read_text(), namespace)
        transform.boot_config()

    def setUp(self):
        transform.reset_transform()
        self.sink = Sink()
        output.setup_uinput(self.sink)
        self.device = SimpleNamespace(name='test', leds=lambda: [])
        self.set_app('ghostty')

    def set_app(self, name):
        self.app = name
        transform.window_context = SimpleNamespace(get_window_context=lambda: {
            'wm_class': name, 'wm_name': 'test', 'wndw_ctxt_error': False,
        })

    def tearDown(self):
        transform.resume_keys()
        transform.reset_transform()

    def replay(self, events):
        for name, action in events:
            transform.on_event(InputEvent(0, 0, ecodes.EV_KEY, Key[name], action), self.device)
        transform.resume_keys()
        # XKB sees evdev codes up to 247; higher virtual carriers have no keysym.
        visible = [(key, action) for key, action in self.sink.events if key <= 247]
        if 'ghostty' in self.app.casefold():
            self.assertIn('keybind = f24=ignore',
                          (ROOT / 'config/ghostty/config.linux.ghostty').read_text())
            visible = [(key, action) for key, action in visible if key != Key.F24]
        self.assertEqual(Counter(key for key, action in visible if action == 1),
                         Counter(key for key, action in visible if action == 0))
        return [key for key, action in visible if action == 1]

    def test_cd_space_with_overlapping_keys(self):
        for releases in (
            [('C', 0), ('SPACE', 1), ('D', 0), ('SPACE', 0)],
            [('SPACE', 1), ('C', 0), ('D', 0), ('SPACE', 0)],
            [('C', 0), ('D', 0), ('SPACE', 1), ('SPACE', 0)],
        ):
            with self.subTest(releases=releases):
                self.sink.events.clear()
                self.assertEqual(self.replay([('C', 1), ('D', 1)] + releases),
                                 [Key.C, Key.D, Key.SPACE])

    def test_d_tap_emits_letter(self):
        self.assertEqual(self.replay([('D', 1), ('D', 0)]), [Key.D])

    def test_d_after_overlapping_h_emits_letter(self):
        self.assertEqual(self.replay([
            ('D', 1), ('H', 1), ('H', 0), ('D', 0), ('D', 1), ('D', 0),
        ]), [Key.D, Key.H, Key.D])

    def test_d_hjkl_emit_letters(self):
        for letter in 'HJKL':
            with self.subTest(letter=letter):
                self.sink.events.clear()
                self.assertEqual(self.replay([
                    ('D', 1), (letter, 1), (letter, 0), ('D', 0),
                ]), [Key.D, Key[letter]])

    def test_ghostty_d_h_emit_letters_for_all_app_names(self):
        for app in ('ghostty', 'com.mitchellh.ghostty', 'Ghostty-debug'):
            with self.subTest(app=app):
                self.set_app(app)
                self.sink.events.clear()
                self.assertEqual(self.replay([
                    ('D', 1), ('H', 1), ('H', 0), ('D', 0),
                ]), [Key.D, Key.H])


if __name__ == '__main__':
    unittest.main()
