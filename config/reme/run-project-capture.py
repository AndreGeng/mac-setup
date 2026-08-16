#!/usr/bin/env python3
"""Run one ReMe project capture with messages supplied over stdin."""

import json
import sys

from reme.reme import main

MAX_STDIN_BYTES = 256_000


def load_messages() -> list[dict]:
    raw = sys.stdin.buffer.read(MAX_STDIN_BYTES + 1)
    if len(raw) > MAX_STDIN_BYTES:
        raise SystemExit("Project capture input exceeds the byte limit")
    value = json.loads(raw)
    if not isinstance(value, list):
        raise SystemExit("Project capture input must be a message list")
    return value


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("Usage: run-project-capture.py CONFIG WORKSPACE SESSION_ID")

    config_path, workspace_path, session_id = sys.argv[1:]
    messages = load_messages()
    sys.argv = [
        "reme",
        "start",
        "job=auto_memory",
        f"config={config_path}",
        f"workspace_dir={workspace_path}",
        f"session_id={session_id}",
        f"messages={json.dumps(messages, separators=(',', ':'))}",
    ]
    raise SystemExit(main())
