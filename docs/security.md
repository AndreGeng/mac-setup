# Security and Sensitive Data

This repository is public. Do not commit credentials, private workstation paths, internal
company information, authentication state, or session history.

## Local checks

Install the open-source Gitleaks CLI:

```bash
brew install gitleaks
```

Run the same checks as CI:

```bash
./scripts/security-scan.sh
```

The command scans the complete Git history plus tracked, staged, and untracked working-tree
files. Pull requests and pushes also scan only the lines added by their revision range without
applying legacy privacy baselines.

For fast feedback before a commit, run the dependency-free staged privacy scan:

```bash
./scripts/privacy-scan.sh --staged
```

## What is blocked

- API keys, access tokens, private keys, MCP bearer URLs, and connection credentials.
- Personal absolute paths such as `/Users/<name>/...`.
- Internal `.srv` domains and URL-form `.internal` or `.corp` hosts.
- Enterprise email addresses configured in `scripts/privacy-scan.sh`.
- `.env`, authentication files, databases, certificates, sessions, and transcripts.
- Newly added dependency or generated environments such as `node_modules` and
  `site-packages`.

Scanner output reports only a rule name and file path. It never prints the matched value.

## Historical findings

`.gitleaksignore` contains exact fingerprints for credentials that were rotated before being
baselined. Never add a raw secret or a broad path exception. A new ignore entry must include
the rotation date and reason.

`.privacyignore` is limited to legacy content during a full scan. Staged and revision-range
scans deliberately ignore this baseline so new private data cannot be hidden under a legacy
directory.

## Responding to a finding

1. Treat the credential as compromised and rotate or revoke it first.
2. Remove it from the current files.
3. Determine whether Git history must be rewritten.
4. Add a fingerprint exception only after rotation and only for an immutable historical
   finding.
5. Re-run `./scripts/security-scan.sh` before pushing.

## GitHub settings

Enable GitHub Secret Scanning and Push Protection in the repository security settings. Make
the `Sensitive data scan` workflow a required status check for the `master` branch.
