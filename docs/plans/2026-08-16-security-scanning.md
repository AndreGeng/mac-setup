# Security Scanning Specification

## Objective

Prevent secrets and private workstation or company information from entering this public
repository. The same checks must run locally and in GitHub Actions without printing matched
secret values.

## Commands

- Full local scan: `./scripts/security-scan.sh` (Git history and current working tree)
- Staged privacy scan: `./scripts/privacy-scan.sh --staged`
- Tests: `./test/security-scan-test.sh`

## Project Structure

- `.gitleaks.toml`: default Gitleaks rules plus repository-specific secret patterns.
- `.gitleaksignore`: exact fingerprints for rotated historical findings only.
- `scripts/privacy-scan.sh`: dependency-free privacy and forbidden-file checks.
- `scripts/security-scan.sh`: common local/CI entry point for Gitleaks and privacy checks.
- `.github/workflows/security.yml`: pull request and push enforcement.
- `test/security-scan-test.sh`: isolated regression tests in temporary Git repositories.

## Code Style

Shell scripts use Bash, `set -euo pipefail`, two-space indentation, quoted variables, and
messages that identify a rule and path without echoing the matched line.

## Testing Strategy

Tests create temporary Git repositories and prove that safe content passes while MCP tokens,
personal absolute paths, internal domains, enterprise email addresses, and forbidden files
fail. Tests also assert that scanner output does not contain the matched token.

## Boundaries

- Always: redact scanner output, scan tracked content and new commit ranges, pin downloaded
  scanner versions and verify checksums.
- Ask first: rewrite Git history, rotate credentials, or broaden an allowlist.
- Never: commit real findings to fixtures, print secret values, or ignore an entire source
  directory to silence a failure.

## Success Criteria

- A secret-like token causes local tests and CI to fail without appearing in logs.
- Personal paths, internal domains, enterprise emails, and forbidden sensitive files fail.
- The current repository passes after documented legacy findings are precisely baselined.
- CI runs on pull requests, pushes to `master`, manual dispatch, and a weekly full scan.

## Sources

- Gitleaks usage and configuration: https://github.com/gitleaks/gitleaks/blob/master/README.md
- Gitleaks v8.28.0 checksums:
  https://github.com/gitleaks/gitleaks/releases/download/v8.28.0/gitleaks_8.28.0_checksums.txt
