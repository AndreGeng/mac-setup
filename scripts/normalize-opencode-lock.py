#!/usr/bin/env python3
"""Use the selected registry for versioned npm tarballs while retaining integrity pins."""

import pathlib
import re
import sys
import urllib.parse

path = pathlib.Path(sys.argv[1])
if path.is_symlink():
    raise SystemExit("Refusing to modify a symlinked Bun lockfile")
if path.exists():
    text = path.read_text()
    pattern = re.compile(
        r'(\["((?:@[^/"\s]+/)?[^@"\s]+)@'
        r'([0-9]+\.[0-9]+\.[0-9]+(?:-[^"\s]+)?)", )"(https?://[^"\s]+)"'
    )

    def normalize(match):
        name = match[2].rsplit("/", 1)[-1]
        tarball = urllib.parse.urlsplit(match[4])
        if tarball.path.endswith(f"/-/{name}-{match[3]}.tgz"):
            # Empty registry URLs tell Bun to use --registry. All original SHA-512
            # integrity values and exact versions remain in the lockfile.
            return match[1] + '""'
        return match[0]

    updated = pattern.sub(normalize, text)
    if updated != text:
        path.write_text(updated)
