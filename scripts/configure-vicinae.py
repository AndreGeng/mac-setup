#!/usr/bin/env python3
"""Merge the launcher hotkey into a mutable Vicinae JSONC configuration."""
import json
import os
from pathlib import Path
import re
import sys


def read_jsonc(text):
    # Match strings first so comment syntax inside a string remains untouched.
    strings = r'"(?:\\.|[^"\\])*"'
    text = re.sub(strings + r'|//[^\n]*|/\*[\s\S]*?\*/',
                  lambda match: match[0] if match[0].startswith('"') else ' ', text)
    text = re.sub(strings + r'|,(?=\s*[}\]])',
                  lambda match: match[0] if match[0].startswith('"') else '', text)
    return json.loads(text)


def configure(path, template):
    original = path.read_text() if path.exists() else None
    data = read_jsonc(original) if original is not None else {}
    if not isinstance(data, dict):
        raise ValueError('Expected a settings object')
    shortcuts = data.setdefault('global_shortcuts', {})
    if not isinstance(shortcuts, dict):
        raise ValueError('Expected a global_shortcuts object')
    toggle = json.loads(template.read_text())['global_shortcuts']['toggle']
    if shortcuts.get('toggle') == toggle:
        return
    shortcuts['toggle'] = toggle
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')


def main():
    try:
        configure(Path(os.environ['HOME']) / '.config/vicinae/settings.json',
                  Path(__file__).resolve().parents[1] / 'config/vicinae/settings.json')
    except (OSError, ValueError):
        # Do not expose existing settings or credentials in parse error messages.
        print('Vicinae configuration failed; check settings.json before retrying.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
