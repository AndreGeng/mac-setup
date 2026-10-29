#!/usr/bin/env python3
"""Merge repository-owned shortcuts into upstream-owned Toshy user slices."""
import ast
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

REGIONS = ('user_custom_modmaps', 'user_apps')
BEGIN = '# BEGIN mac-setup shortcuts'
END = '# END mac-setup shortcuts'


def identity(node):
    if isinstance(node, ast.FunctionDef):
        return ('function', node.name)
    if isinstance(node, ast.Expr) and isinstance(node.value, ast.Call):
        call = node.value
        if (isinstance(call.func, ast.Name) and call.args
                and isinstance(call.args[0], ast.Constant)):
            return (call.func.id, call.args[0].value)
    return None


def migrate_legacy(body, template):
    """Adopt only exact, known manual versions of our named shortcuts."""
    accepted = {}
    legacy = '''keymap("User Cmd Space input method", {
        C("RC-Space"): [bind, C("LC-Space")],
    }, when=lambda ctx: cnfg.screen_has_focus and not ctx_app_is_remote)
    '''
    # Adopt the previously published navigation map, before the Wubi fallback.
    previous = template.replace('    C("DNav-Space"): [C("d"), C("Space")],\n', '')
    # Adopt the earlier virtual carrier and the temporary Ghostty exclusion.
    old_navigation = template.replace('Key.F24', 'Key.V_FAKEY')
    old_carrier = old_navigation.replace(
        '}, when=lambda ctx: cnfg.screen_has_focus)',
        '}, when=lambda ctx: cnfg.screen_has_focus and "ghostty" not in ctx.wm_class.casefold())',
        1)
    for node in ast.parse(template + '\n' + legacy + '\n' + previous
                          + '\n' + old_navigation + '\n' + old_carrier).body:
        accepted.setdefault(identity(node), set()).add(ast.dump(node))
    lines = body.splitlines(keepends=True)
    for node in reversed(ast.parse(body).body):
        name = identity(node)
        if name is not None and name in accepted:
            if ast.dump(node) not in accepted[name]:
                raise ValueError('A personal mapping conflicts with a managed shortcut')
            del lines[node.lineno - 1:node.end_lineno]
    return ''.join(lines)


def merge_toshy(original, templates):
    result = original
    for region in REGIONS:
        pattern = (rf'(^###  SLICE_MARK_START: {region}  ###[^\n]*\n)'
                   rf'(.*?)(^###  SLICE_MARK_END: {region}  ###[^\n]*$)')
        matches = list(re.finditer(pattern, result, re.MULTILINE | re.DOTALL))
        # Check marker counts separately: duplicate/malformed slices must fail closed.
        if (len(matches) != 1
                or result.count(f'SLICE_MARK_START: {region} ') != 1
                or result.count(f'SLICE_MARK_END: {region} ') != 1):
            raise ValueError('Missing or duplicate Toshy user slice')
        match = matches[0]
        body = match.group(2)
        if body.count(BEGIN) != body.count(END) or body.count(BEGIN) > 1:
            raise ValueError('Malformed mac-setup block')
        body = re.sub(rf'^{re.escape(BEGIN)}\n.*?^{re.escape(END)}\n?', '',
                      body, flags=re.MULTILINE | re.DOTALL)
        template = (templates / f'{region}.py').read_text()
        body = migrate_legacy(body, template)
        replacement = (match.group(1) + '\n' + BEGIN + '\n' + template.rstrip()
                       + '\n' + END + '\n\n' + body.lstrip('\n') + match.group(3))
        result = result[:match.start()] + replacement + result[match.end():]
    ast.parse(result)
    return result


def remove_ctrl_space(original):
    lines = original.splitlines(keepends=True)
    start = next((i for i, line in enumerate(lines)
                  if line.strip() == '[Hotkey/TriggerKeys]'), None)
    if start is None:
        return original + ('\n' if original and not original.endswith('\n') else '') + '[Hotkey/TriggerKeys]\n'
    end = next((i for i in range(start + 1, len(lines))
                if lines[i].lstrip().startswith('[')), len(lines))
    entries = []
    index = 0
    for line in lines[start + 1:end]:
        entry = re.match(r'^\s*\d+\s*=\s*(.*?)\s*$', line)
        if entry:
            if entry.group(1).lower() in ('control+space', 'ctrl+space'):
                continue
            entries.append(f'{index}={entry.group(1)}\n')
            index += 1
        else:
            entries.append(line)
    return ''.join(lines[:start + 1] + entries + lines[end:])


def validate(path):
    # Use the same interpreter/environment as Toshy's runtime, without a shell.
    check = subprocess.run([sys.executable, '-c',
        'from xwaykeyz.cli import main; main()', '--check', '-c', str(path)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if check.returncode:
        raise RuntimeError('Toshy config validation failed; original files restored')


def configure(home, templates):
    toshy = home / '.config/toshy/toshy_config.py'
    fcitx = home / '.config/fcitx5/config'
    old_toshy = toshy.read_bytes()
    old_fcitx = fcitx.read_bytes() if fcitx.exists() else None
    updated = merge_toshy(old_toshy.decode(), templates).encode()
    input_config = remove_ctrl_space((old_fcitx or b'').decode()).encode()
    if updated == old_toshy and input_config == old_fcitx:
        return False
    try:
        toshy.write_bytes(updated)
        fcitx.parent.mkdir(parents=True, exist_ok=True)
        fcitx.write_bytes(input_config)
        validate(toshy)
    except BaseException:
        toshy.write_bytes(old_toshy)
        if old_fcitx is None:
            fcitx.unlink(missing_ok=True)
        else:
            fcitx.write_bytes(old_fcitx)
        raise
    return True


def reload_services():
    if shutil.which('fcitx5-remote'):
        if subprocess.run(['fcitx5-remote', '--check'], stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL).returncode == 0:
            subprocess.run(['fcitx5-remote', '-r'], check=True)
    if shutil.which('systemctl'):
        if subprocess.run(['systemctl', '--user', 'is-active', '--quiet', 'toshy-config.service'],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            subprocess.run(['systemctl', '--user', 'restart', 'toshy-config.service'], check=True)
            subprocess.run(['systemctl', '--user', 'is-active', '--quiet',
                            'toshy-config.service'], check=True)


def main():
    try:
        changed = configure(Path(os.environ['HOME']),
                            Path(__file__).resolve().parents[1] / 'config/toshy')
        if changed:
            reload_services()
        print('Toshy shortcuts configured.' if changed else 'Toshy shortcuts already current.')
    except (OSError, ValueError, SyntaxError, RuntimeError, subprocess.CalledProcessError):
        # Configuration contents, subprocess output and exception text can contain secrets.
        print('Toshy shortcut configuration failed; review the user slices/runtime and retry.',
              file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
