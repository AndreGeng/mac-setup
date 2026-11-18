#!/usr/bin/env python3
"""Exercise Yazi's real `.` and `z` bindings with a recording fzf executable."""

import fcntl
import json
import os
from pathlib import Path
import pty
import select
import signal
import struct
import tempfile
import termios
import time


ROOT = Path(__file__).resolve().parent.parent


def check(inherited_command):
    with tempfile.TemporaryDirectory(prefix="yazi-fzf-") as temp:
        root = Path(temp)
        files = root / "files"
        files.mkdir()
        for name in ("visible.txt", ".hidden.txt"):
            (files / name).touch()
        (files / ".git").mkdir()
        (files / ".git" / "excluded.txt").touch()
        tools = root / "bin"
        tools.mkdir()
        trace = root / "trace.jsonl"
        # Run the configured source with real fd, but return no fzf selection.
        recorder = tools / "fzf"
        recorder.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, subprocess\n"
            "source = os.environ['FZF_DEFAULT_COMMAND']\n"
            "result = subprocess.run(source, shell=True, check=True, capture_output=True, text=True)\n"
            "with open(os.environ['TEST_TRACE'], 'a') as log:\n"
            "    log.write(json.dumps({'source': source, 'files': result.stdout.splitlines()}) + '\\n')\n"
        )
        recorder.chmod(0o755)
        env = dict(
            os.environ,
            PATH=str(tools) + os.pathsep + os.environ["PATH"],
            TEST_TRACE=str(trace),
            FZF_DEFAULT_COMMAND=inherited_command,
            YAZI_CONFIG_HOME=str(ROOT / "config/yazi"),
            XDG_STATE_HOME=str(root / "state"),
            XDG_CACHE_HOME=str(root / "cache"),
            TERM="xterm-256color",
        )
        pid, terminal = pty.fork()
        if pid == 0:
            os.execvpe("yazi", ["yazi", str(files)], env)
        fcntl.ioctl(terminal, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 110, 0, 0))

        def drain(seconds):
            end = time.monotonic() + seconds
            while time.monotonic() < end:
                if select.select([terminal], [], [], 0.05)[0]:
                    try:
                        os.read(terminal, 65536)
                    except OSError:
                        return

        try:
            drain(2)
            os.write(terminal, b"\x1b[1;1R\x1b[?1;2c")
            drain(1)
            for toggle in (False, True, True):
                if toggle:
                    os.write(terminal, b".")
                    drain(0.3)
                os.write(terminal, b"z")
                # Allow Yazi's terminal capability probes when resuming from fzf.
                drain(2.5)
            records = [json.loads(line) for line in trace.read_text().splitlines()]
            assert len(records) == 3, "fzf was not invoked for each keypress"
            for record, hidden in zip(records, (False, True, False)):
                names = {Path(name).name for name in record["files"]}
                assert "visible.txt" in names
                assert (".hidden.txt" in names) == hidden
                assert "excluded.txt" not in names, ".git must stay excluded"
                assert ("--hidden" in record["source"]) == hidden
        finally:
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)
            os.close(terminal)


# Cover environments inherited from `y` and from Neovim/ordinary shell startup.
check("fd --hidden --type f --exclude .git")
check("fd --type f")
print("PASS Yazi fzf follows hidden visibility in both launcher environments")
